import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_models.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_provider.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_service.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_storage.dart';
import 'package:hanbova_app/features/auth/models/user_profile.dart';
import 'package:hanbova_app/features/auth/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:hanbova_app/core/networking/api_client.dart';
import 'package:hanbova_app/features/protected/data/protected_message_service.dart';
import 'package:hanbova_app/features/protected_send/data/payment_intent_repository.dart';
import 'package:hanbova_app/features/protected_send/domain/protected_payment_intent.dart';
import 'package:hanbova_app/features/protected_send/presentation/protected_send_provider.dart';
import 'package:hanbova_app/core/network/network_environment.dart';
import 'package:hanbova_app/features/transactions/domain/transaction_model.dart';
import 'package:hanbova_app/features/transactions/presentation/transactions_provider.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hanbova_app/core/security/secure_storage_service.dart';

class InMemorySecureStorageService extends SecureStorageService {
  final Map<String, String> _data = {};

  InMemorySecureStorageService() : super(const FlutterSecureStorage());

  @override
  Future<void> writeSecret(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<String?> readSecret(String key) async {
    return _data[key];
  }

  @override
  Future<void> deleteSecret(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> saveWalletSeed(String seedHex) async {
    _data['hanbova_wallet_seed'] = seedHex;
  }

  @override
  Future<String?> getWalletSeed() async {
    return _data['hanbova_wallet_seed'];
  }

  @override
  Future<void> clearAllSecrets() async {
    _data.clear();
  }
}

final testUser = UserProfile(
  id: 'usr_alice_123',
  username: 'alice',
  handle: '@alice',
  email: 'alice@hanbova.africa',
  firstName: 'Alice',
  lastName: 'Doe',
  displayName: 'Alice Doe',
  emailVerified: true,
  createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
);

class MockAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockPaymentIntentRepository extends PaymentIntentRepository {
  final Map<String, ProtectedPaymentIntent> intents = {};
  final List<String> statusTransitions = [];

  MockPaymentIntentRepository()
      : super(
            ApiClient(baseUrl: 'http://localhost', httpClient: http.Client()));

  @override
  Future<ProtectedPaymentIntent> createPaymentIntent({
    required String paymentType,
    required int amountSats,
    required String recipientIdentifier,
    String? senderId,
    String? description,
    int? expiresInSeconds,
  }) async {
    final id =
        'intent_canonical_${intents.length + 1}_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final expiry = expiresInSeconds != null
        ? now.add(Duration(seconds: expiresInSeconds))
        : now.add(const Duration(hours: 24));

    final intent = ProtectedPaymentIntent(
      id: id,
      paymentType: paymentType,
      status: 'created',
      amountSats: amountSats,
      senderId: senderId ?? 'usr_alice_123',
      recipientIdentifier: recipientIdentifier,
      description: description,
      expiresAt: expiry,
      claimReference: 'hnbv_claim_${id.substring(0, 8)}',
      createdAt: now,
    );
    intents[id] = intent;
    statusTransitions.add('${intent.id}:created');
    return intent;
  }

  @override
  Future<ProtectedPaymentIntent> getPaymentIntent(String id) async {
    final intent = intents[id];
    if (intent == null) throw StateError('Payment intent $id not found');
    return intent;
  }

  @override
  Future<ProtectedPaymentIntent> getPaymentIntentByReference(
      String reference) async {
    for (final intent in intents.values) {
      if (intent.claimReference == reference || intent.id == reference) {
        return intent;
      }
    }
    return getPaymentIntent(reference);
  }

  @override
  Future<ProtectedPaymentIntent> updatePaymentStatus(
      String id, String status) async {
    final intent = intents[id];
    if (intent == null) throw StateError('Payment intent $id not found');
    final updated = ProtectedPaymentIntent(
      id: intent.id,
      paymentType: intent.paymentType,
      status: status,
      amountSats: intent.amountSats,
      senderId: intent.senderId,
      recipientIdentifier: intent.recipientIdentifier,
      description: intent.description,
      expiresAt: intent.expiresAt,
      claimReference: intent.claimReference,
      createdAt: intent.createdAt,
    );
    intents[id] = updated;
    statusTransitions.add('$id:$status');
    return updated;
  }

  @override
  Future<ProtectedPaymentIntent> claimPaymentIntent(String id,
      {String? claimerIdentifier}) async {
    return updatePaymentStatus(id, 'claimed');
  }

  @override
  Future<ProtectedPaymentIntent> refundPaymentIntent(
      {required String id, required String senderId}) async {
    return updatePaymentStatus(id, 'refunded');
  }
}

class MockFailingMessageService extends ProtectedMessageService {
  MockFailingMessageService()
      : super(
            ApiClient(baseUrl: 'http://localhost', httpClient: http.Client()));

  @override
  Future<UserPaymentProfile> resolveUserPaymentProfile(String username) async {
    throw StateError('User not found');
  }

  @override
  Future<RemoteProtectedMessage> sendProtectedMessage({
    required String recipientUsername,
    required String encryptedPayload,
    int payloadVersion = 1,
    String? paymentIntentId,
  }) async {
    throw StateError('Relay network unreachable');
  }
}

class MockSuccessMessageService extends ProtectedMessageService {
  bool deliveryFailed = false;
  String? lastPaymentIntentId;
  String? lastRecipientUsername;
  String? lastEncryptedPayload;
  final List<RemoteProtectedMessage> inboxMessages = [];

  MockSuccessMessageService({this.deliveryFailed = false})
      : super(
            ApiClient(baseUrl: 'http://localhost', httpClient: http.Client()));

  @override
  Future<UserPaymentProfile> resolveUserPaymentProfile(String username) async {
    final clean = username.trim().replaceAll('@', '').toLowerCase();
    if (clean == 'carol') {
      return const UserPaymentProfile(
        username: 'carol',
        handle: '@carol',
        protectedPaymentPubkey:
            '03c1633cafcc01ebfb6d78e39f687a1f0995c62fc95f51ead10a02ee0be551b5cc',
        transportEncryptionPubkey:
            '7e9b4b9b9c9f0b83e3c09f8e434f0e9d7e9b4b9b9c9f0b83e3c09f8e434f0e9e',
      );
    }
    return UserPaymentProfile(
      username: clean,
      handle: '@$clean',
      protectedPaymentPubkey:
          '02a1633cafcc01ebfb6d78e39f687a1f0995c62fc95f51ead10a02ee0be551b5af',
      transportEncryptionPubkey:
          '6d9b4b9b9c9f0b83e3c09f8e434f0e9d6d9b4b9b9c9f0b83e3c09f8e434f0e9d',
    );
  }

  @override
  Future<RemoteProtectedMessage> sendProtectedMessage({
    required String recipientUsername,
    required String encryptedPayload,
    int payloadVersion = 1,
    String? paymentIntentId,
  }) async {
    lastPaymentIntentId = paymentIntentId;
    lastRecipientUsername = recipientUsername;
    lastEncryptedPayload = encryptedPayload;
    if (deliveryFailed) {
      throw StateError('Failed to relay encrypted message');
    }
    final msg = RemoteProtectedMessage(
      id: 'msg_${inboxMessages.length + 1}',
      paymentIntentId: paymentIntentId,
      senderUsername: 'alice',
      recipientUsername: recipientUsername,
      encryptedPayload: encryptedPayload,
      payloadVersion: payloadVersion,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    inboxMessages.add(msg);
    return msg;
  }

  @override
  Future<List<RemoteProtectedMessage>> getInbox() async {
    return inboxMessages;
  }
}

class MockSuccessfulCashuWalletService implements CashuWalletService {
  final Map<String, ProtectedEscrowRecord> recordedEscrows = {};
  CashuWalletBalance currentBalance;

  MockSuccessfulCashuWalletService({
    this.currentBalance =
        const CashuWalletBalance(spendableSats: 50000, lockedEscrowSats: 0),
  });

  @override
  Future<CashuWalletBalance> getBalance() async {
    return currentBalance;
  }

  @override
  Future<MintQuoteResult> createMintQuote(int amountSats) async {
    return MintQuoteResult(
      quoteId: 'quote_mock_123',
      bolt11Invoice: 'lnbc100u1p...',
      amountSats: amountSats,
    );
  }

  @override
  Future<int> mintQuote(String quoteId) async {
    currentBalance = CashuWalletBalance(
      spendableSats: currentBalance.spendableSats + 10000,
      lockedEscrowSats: currentBalance.lockedEscrowSats,
    );
    return 10000;
  }

  @override
  Future<int> mintTestTokens(int amountSats) async {
    currentBalance = CashuWalletBalance(
      spendableSats: currentBalance.spendableSats + amountSats,
      lockedEscrowSats: currentBalance.lockedEscrowSats,
    );
    return amountSats;
  }

  @override
  Future<String> createProtectedSend({
    required int amountSats,
    required String recipientPubkey,
    required DateTime locktime,
    required String paymentId,
  }) async {
    final token = 'cashuA_nut11_real_token_for_$paymentId';
    final escrow = ProtectedEscrowRecord(
      paymentId: paymentId,
      token: token,
      amountSats: amountSats,
      recipientPubkey: recipientPubkey,
      refundPubkey: '02refund_pub',
      refundPrivkeyHex:
          'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
      locktime: locktime,
      isOutgoing: true,
      status: 'locked',
      createdAt: DateTime.now(),
    );
    recordedEscrows[paymentId] = escrow;
    await CashuWalletStorage()
        .saveEscrowRecord(testUser.id, HanbovaNetwork.local, escrow);

    currentBalance = CashuWalletBalance(
      spendableSats: currentBalance.spendableSats - amountSats,
      lockedEscrowSats: currentBalance.lockedEscrowSats + amountSats,
    );
    return token;
  }

  @override
  Future<int> claimProtectedPayment({
    required String token,
    required String paymentId,
  }) async {
    currentBalance = CashuWalletBalance(
      spendableSats: currentBalance.spendableSats + 5000,
      lockedEscrowSats: currentBalance.lockedEscrowSats,
    );
    return 5000;
  }

  @override
  Future<int> refundProtectedPayment({
    required String paymentId,
  }) async {
    final escrow = recordedEscrows[paymentId];
    if (escrow == null) {
      throw StateError('Escrow record for payment $paymentId not found');
    }
    currentBalance = CashuWalletBalance(
      spendableSats: currentBalance.spendableSats + escrow.amountSats,
      lockedEscrowSats: currentBalance.lockedEscrowSats - escrow.amountSats,
    );
    return escrow.amountSats;
  }

  @override
  Future<MeltQuoteResult> createMeltQuote(String bolt11Invoice) async {
    return const MeltQuoteResult(
        quoteId: 'melt_1', amountSats: 1000, feeReserveSats: 10);
  }

  @override
  Future<MeltExecutionResult> payMeltQuote(String quoteId) async {
    return const MeltExecutionResult(isPaid: true, preimage: 'preimage_123');
  }

  @override
  Future<TokenState> checkTokenState(String token) async {
    return TokenState.unspent;
  }

  @override
  void dispose() {}
}

class MockFailingCashuWalletService implements CashuWalletService {
  @override
  Future<CashuWalletBalance> getBalance() async {
    return const CashuWalletBalance(spendableSats: 0, lockedEscrowSats: 0);
  }

  @override
  Future<MintQuoteResult> createMintQuote(int amountSats) async {
    throw StateError('Mint unavailable');
  }

  @override
  Future<int> mintQuote(String quoteId) async {
    throw StateError('Mint quote payment failed');
  }

  @override
  Future<int> mintTestTokens(int amountSats) async {
    throw StateError('Test minting disabled');
  }

  @override
  Future<String> createProtectedSend({
    required int amountSats,
    required String recipientPubkey,
    required DateTime locktime,
    required String paymentId,
  }) async {
    throw StateError('Insufficient funds or mint offline');
  }

  @override
  Future<int> claimProtectedPayment({
    required String token,
    required String paymentId,
  }) async {
    throw StateError('Invalid claim token or condition not met');
  }

  @override
  Future<int> refundProtectedPayment({
    required String paymentId,
  }) async {
    throw StateError('Locktime not yet expired');
  }

  @override
  Future<MeltQuoteResult> createMeltQuote(String bolt11Invoice) async {
    throw StateError('Melt quote failed');
  }

  @override
  Future<MeltExecutionResult> payMeltQuote(String quoteId) async {
    throw StateError('Melt pay failed');
  }

  @override
  Future<TokenState> checkTokenState(String token) async {
    return TokenState.unknown;
  }

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Map<String, String> memoryStorage = {};
  const MethodChannel storageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel,
            (MethodCall methodCall) async {
      if (methodCall.method == 'read') {
        return memoryStorage[methodCall.arguments['key']];
      } else if (methodCall.method == 'write') {
        memoryStorage[methodCall.arguments['key']] =
            methodCall.arguments['value'];
        return true;
      } else if (methodCall.method == 'delete') {
        memoryStorage.remove(methodCall.arguments['key']);
        return true;
      } else if (methodCall.method == 'deleteAll') {
        memoryStorage.clear();
        return true;
      } else if (methodCall.method == 'containsKey') {
        return memoryStorage.containsKey(methodCall.arguments['key']);
      }
      return null;
    });
  });

  group('Financial Authority & Fail-Closed Integrity Tests', () {
    test('production transaction list starts empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final transactions = container.read(transactionsProvider);
      expect(transactions, isEmpty);
    });

    test('unauthenticated Protected Send fails', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
              (ref) => MockAuthNotifier(AuthState.unauthenticated())),
          paymentIntentRepositoryProvider
              .overrideWithValue(MockPaymentIntentRepository()),
          protectedMessageServiceProvider
              .overrideWithValue(MockSuccessMessageService()),
          cashuWalletServiceProvider
              .overrideWithValue(MockSuccessfulCashuWalletService()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(protectedSendProvider.notifier);
      final success = await notifier.createProtectedPayment(
        amountSats: 5000,
        recipientIdentifier: '@bob',
        description: 'Unauthenticated test',
        expirationSeconds: 3600,
      );

      expect(success, isFalse);
      final state = container.read(protectedSendProvider);
      expect(state.errorMessage, contains('User must be authenticated'));
    });

    test(
        'Failed recipient resolution fails Protected Send and creates no payment',
        () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) =>
              MockAuthNotifier(AuthState.authenticated(testUser, 'jwt'))),
          secureStorageServiceProvider
              .overrideWithValue(InMemorySecureStorageService()),
          paymentIntentRepositoryProvider
              .overrideWithValue(MockPaymentIntentRepository()),
          protectedMessageServiceProvider
              .overrideWithValue(MockFailingMessageService()),
          cashuWalletServiceProvider
              .overrideWithValue(MockFailingCashuWalletService()),
        ],
      );
      addTearDown(container.dispose);

      final initialTxCount = container.read(transactionsProvider).length;
      final notifier = container.read(protectedSendProvider.notifier);
      final success = await notifier.createProtectedPayment(
        amountSats: 5000,
        recipientIdentifier: '@nonexistent_user',
        description: 'Test payment',
        expirationSeconds: 3600,
      );

      expect(success, isFalse);
      final state = container.read(protectedSendProvider);
      expect(state.createdIntent, isNull);
      expect(state.errorMessage, contains('could not be found'));

      final transactions = container.read(transactionsProvider);
      expect(transactions.length, equals(initialTxCount));
    });

    test(
        'Null CDK wallet fails Protected Send and generates no synthetic token',
        () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) =>
              MockAuthNotifier(AuthState.authenticated(testUser, 'jwt'))),
          secureStorageServiceProvider
              .overrideWithValue(InMemorySecureStorageService()),
          paymentIntentRepositoryProvider
              .overrideWithValue(MockPaymentIntentRepository()),
          protectedMessageServiceProvider
              .overrideWithValue(MockSuccessMessageService()),
          cashuWalletServiceProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final initialTxCount = container.read(transactionsProvider).length;
      final notifier = container.read(protectedSendProvider.notifier);
      final success = await notifier.createProtectedPayment(
        amountSats: 5000,
        recipientIdentifier: '@valid_bob',
        description: 'Test payment',
        expirationSeconds: 3600,
      );

      expect(success, isFalse);
      final state = container.read(protectedSendProvider);
      expect(state.createdIntent, isNull);
      expect(state.errorMessage, contains('Cashu wallet is not initialized'));

      final transactions = container.read(transactionsProvider);
      expect(transactions.length, equals(initialTxCount));
    });

    test(
        'Failed CDK createProtectedSend surfaces error and creates no synthetic token',
        () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) =>
              MockAuthNotifier(AuthState.authenticated(testUser, 'jwt'))),
          secureStorageServiceProvider
              .overrideWithValue(InMemorySecureStorageService()),
          paymentIntentRepositoryProvider
              .overrideWithValue(MockPaymentIntentRepository()),
          protectedMessageServiceProvider
              .overrideWithValue(MockSuccessMessageService()),
          cashuWalletServiceProvider
              .overrideWithValue(MockFailingCashuWalletService()),
        ],
      );
      addTearDown(container.dispose);

      final initialTxCount = container.read(transactionsProvider).length;
      final notifier = container.read(protectedSendProvider.notifier);
      final success = await notifier.createProtectedPayment(
        amountSats: 5000,
        recipientIdentifier: '@valid_bob',
        description: 'Test payment',
        expirationSeconds: 3600,
      );

      expect(success, isFalse);
      final state = container.read(protectedSendProvider);
      expect(state.createdIntent, isNull);
      expect(
          state.errorMessage, contains('Insufficient funds or mint offline'));

      final transactions = container.read(transactionsProvider);
      expect(transactions.length, equals(initialTxCount));
    });

    test(
        'delivery failure after CDK lock remains visible and refundable, and retry delivery does not create second token',
        () async {
      final mockWallet = MockSuccessfulCashuWalletService();
      final mockMessageService =
          MockSuccessMessageService(deliveryFailed: true);
      final mockRepo = MockPaymentIntentRepository();

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) =>
              MockAuthNotifier(AuthState.authenticated(testUser, 'jwt'))),
          secureStorageServiceProvider
              .overrideWithValue(InMemorySecureStorageService()),
          paymentIntentRepositoryProvider.overrideWithValue(mockRepo),
          protectedMessageServiceProvider.overrideWithValue(mockMessageService),
          cashuWalletServiceProvider.overrideWithValue(mockWallet),
        ],
      );
      addTearDown(container.dispose);

      final initialTxCount = container.read(transactionsProvider).length;
      final notifier = container.read(protectedSendProvider.notifier);
      final success = await notifier.createProtectedPayment(
        amountSats: 5000,
        recipientIdentifier: '@valid_bob',
        description: 'Delivery failure test',
        expirationSeconds: 3600,
      );

      // Flow reports failure to UI
      expect(success, isFalse);
      final state = container.read(protectedSendProvider);
      expect(state.createdIntent, isNull);
      expect(state.errorMessage, contains('Failed to relay encrypted message'));

      // BUT CDK escrow is preserved
      expect(mockWallet.recordedEscrows.length, equals(1));
      final lockedPaymentId = mockWallet.recordedEscrows.keys.first;

      // Local transaction is recorded with status pending delivery
      final transactions = container.read(transactionsProvider);
      expect(transactions.length, equals(initialTxCount + 1));
      final pendingTx = transactions.first;
      expect(pendingTx.id, equals(lockedPaymentId));
      expect(pendingTx.status, equals(TransactionStatus.pending));

      // Retry Delivery without creating a second CDK locked token
      mockMessageService.deliveryFailed = false;
      final retrySuccess = await notifier.retryDelivery(lockedPaymentId);
      expect(retrySuccess, isTrue);

      // Verify no second token was created
      expect(mockWallet.recordedEscrows.length, equals(1));
      expect(mockMessageService.lastPaymentIntentId, equals(lockedPaymentId));

      // Local transaction transitions to claimable
      final updatedTx = container.read(transactionsProvider).first;
      expect(updatedTx.status, equals(TransactionStatus.claimable));
    });

    test(
        'raw Cashu token is not stored in TransactionModel presentation metadata',
        () async {
      final mockWallet = MockSuccessfulCashuWalletService();
      final mockMessageService = MockSuccessMessageService();
      final mockRepo = MockPaymentIntentRepository();

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) =>
              MockAuthNotifier(AuthState.authenticated(testUser, 'jwt'))),
          secureStorageServiceProvider
              .overrideWithValue(InMemorySecureStorageService()),
          paymentIntentRepositoryProvider.overrideWithValue(mockRepo),
          protectedMessageServiceProvider.overrideWithValue(mockMessageService),
          cashuWalletServiceProvider.overrideWithValue(mockWallet),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(protectedSendProvider.notifier);
      final success = await notifier.createProtectedPayment(
        amountSats: 8000,
        recipientIdentifier: '@valid_bob',
        description: 'Payment ref test',
        expirationSeconds: 3600,
      );

      expect(success, isTrue);
      final tx = container.read(transactionsProvider).first;
      expect(tx.claimReference, isNotNull);
      expect(tx.claimReference!.startsWith('cashuA'), isFalse);
      expect(tx.claimReference!.startsWith('hnbv_claim_'), isTrue);
    });

    test('Bob -> failure -> edit Carol uses Carol keys (recipient binding)',
        () async {
      final mockWallet = MockSuccessfulCashuWalletService();
      final mockMessageService = MockSuccessMessageService();
      final mockRepo = MockPaymentIntentRepository();

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) =>
              MockAuthNotifier(AuthState.authenticated(testUser, 'jwt'))),
          secureStorageServiceProvider
              .overrideWithValue(InMemorySecureStorageService()),
          paymentIntentRepositoryProvider.overrideWithValue(mockRepo),
          protectedMessageServiceProvider.overrideWithValue(mockMessageService),
          cashuWalletServiceProvider.overrideWithValue(mockWallet),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(protectedSendProvider.notifier);

      // 1. Resolve Bob first
      await notifier.resolveRecipient('bob');
      expect(container.read(protectedSendProvider).resolvedRecipient?.username,
          equals('bob'));

      // 2. User edits field to Carol and sends
      final success = await notifier.createProtectedPayment(
        amountSats: 15000,
        recipientIdentifier: '@carol',
        description: 'Carol milestone',
        expirationSeconds: 3600,
      );

      expect(success, isTrue);

      // 3. Verify Carol's P2PK public key was used for CDK escrow, NOT Bob's
      final escrow = mockWallet.recordedEscrows.values.first;
      expect(
        escrow.recipientPubkey,
        equals(
            '03c1633cafcc01ebfb6d78e39f687a1f0995c62fc95f51ead10a02ee0be551b5cc'),
      );
    });

    test(
        'backend status follows Created -> Protected -> Claimable, Bob claims, Alice refunds',
        () async {
      final mockWallet = MockSuccessfulCashuWalletService();
      final mockMessageService = MockSuccessMessageService();
      final mockRepo = MockPaymentIntentRepository();

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) =>
              MockAuthNotifier(AuthState.authenticated(testUser, 'jwt'))),
          secureStorageServiceProvider
              .overrideWithValue(InMemorySecureStorageService()),
          paymentIntentRepositoryProvider.overrideWithValue(mockRepo),
          protectedMessageServiceProvider.overrideWithValue(mockMessageService),
          cashuWalletServiceProvider.overrideWithValue(mockWallet),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(protectedSendProvider.notifier);
      final success = await notifier.createProtectedPayment(
        amountSats: 20000,
        recipientIdentifier: '@valid_bob',
        description: 'Lifecycle test',
        expirationSeconds: 3600,
      );

      expect(success, isTrue);
      final canonicalId =
          container.read(protectedSendProvider).createdIntent!.id;

      // Backend status progression
      expect(mockRepo.statusTransitions, contains('$canonicalId:created'));
      expect(mockRepo.statusTransitions, contains('$canonicalId:protected'));
      expect(mockRepo.statusTransitions, contains('$canonicalId:claimable'));

      // Bob claims -> coordinates Claimed
      await mockWallet.claimProtectedPayment(
          token: 'cashuA_nut11', paymentId: canonicalId);
      await mockRepo.claimPaymentIntent(canonicalId);
      expect(mockRepo.statusTransitions, contains('$canonicalId:claimed'));

      // Alice refunds -> coordinates RefundAvailable -> Refunded
      await mockWallet.refundProtectedPayment(paymentId: canonicalId);
      await mockRepo.updatePaymentStatus(canonicalId, 'refund_available');
      await mockRepo.refundPaymentIntent(
          id: canonicalId, senderId: testUser.id);
      expect(mockRepo.statusTransitions,
          contains('$canonicalId:refund_available'));
      expect(mockRepo.statusTransitions, contains('$canonicalId:refunded'));
    });

    test('Canonical Payment ID Regression Test: ID consistency across layers',
        () async {
      final mockWallet = MockSuccessfulCashuWalletService();
      final mockMessageService = MockSuccessMessageService();
      final mockRepo = MockPaymentIntentRepository();

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) =>
              MockAuthNotifier(AuthState.authenticated(testUser, 'jwt'))),
          secureStorageServiceProvider
              .overrideWithValue(InMemorySecureStorageService()),
          paymentIntentRepositoryProvider.overrideWithValue(mockRepo),
          protectedMessageServiceProvider.overrideWithValue(mockMessageService),
          cashuWalletServiceProvider.overrideWithValue(mockWallet),
        ],
      );
      addTearDown(container.dispose);

      final initialBalance = await mockWallet.getBalance();
      expect(initialBalance.spendableSats, equals(50000));

      final notifier = container.read(protectedSendProvider.notifier);
      final success = await notifier.createProtectedPayment(
        amountSats: 12000,
        recipientIdentifier: '@valid_bob',
        description: 'Design mockups milestone',
        expirationSeconds: 3600,
      );

      expect(success, isTrue);
      final state = container.read(protectedSendProvider);
      expect(state.createdIntent, isNotNull);

      final canonicalId = state.createdIntent!.id;

      // 1. Backend PaymentIntent ID == Canonical ID
      expect(mockRepo.intents.containsKey(canonicalId), isTrue);

      // 2. CDK Escrow record paymentId == Canonical ID
      expect(mockWallet.recordedEscrows.containsKey(canonicalId), isTrue);

      // 3. ProtectedMessage paymentIntentId == Canonical ID
      expect(mockMessageService.lastPaymentIntentId, equals(canonicalId));

      // 4. Local TransactionModel.id == Canonical ID
      final transactions = container.read(transactionsProvider);
      final createdTx = transactions.first;
      expect(createdTx.id, equals(canonicalId));
      expect(createdTx.status, equals(TransactionStatus.claimable));
      expect(createdTx.amountSats, equals(12000));

      // 5. Refund locates the exact same escrow record using canonicalId and restores balance
      final refundedSats =
          await mockWallet.refundProtectedPayment(paymentId: createdTx.id);
      expect(refundedSats, equals(12000));

      final balanceAfterRefund = await mockWallet.getBalance();
      expect(balanceAfterRefund.spendableSats, equals(50000));
    });

    test(
        'Null wallet during claim throws StateError and never mutates balance or transaction',
        () async {
      final container = ProviderContainer(
        overrides: [
          cashuWalletServiceProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final tx = TransactionModel(
        id: 'incoming_tx_1',
        type: TransactionType.protectedSend,
        status: TransactionStatus.claimable,
        amountSats: 10000,
        recipientOrSender: 'alice',
        description: 'Pending claim',
        createdAt: DateTime.now(),
        claimReference: 'cashuBmock_token',
      );
      container.read(transactionsProvider.notifier).addTransaction(tx);

      final cashuWallet = container.read(cashuWalletServiceProvider);

      // Action logic execution
      expect(
        () async {
          if (cashuWallet == null) {
            throw StateError('Cashu wallet not initialized');
          }
          await cashuWallet.claimProtectedPayment(
            token: tx.claimReference!,
            paymentId: tx.id,
          );
        },
        throwsA(isA<StateError>().having((e) => e.message, 'message',
            contains('Cashu wallet not initialized'))),
      );

      final currentTx = container.read(transactionsProvider).first;
      expect(currentTx.status, equals(TransactionStatus.claimable));
    });

    test(
        'CDK claim failure throws StateError and never mutates balance or transaction',
        () async {
      final mockWallet = MockFailingCashuWalletService();
      final container = ProviderContainer(
        overrides: [
          cashuWalletServiceProvider.overrideWithValue(mockWallet),
        ],
      );
      addTearDown(container.dispose);

      final tx = TransactionModel(
        id: 'incoming_tx_2',
        type: TransactionType.protectedSend,
        status: TransactionStatus.claimable,
        amountSats: 10000,
        recipientOrSender: 'alice',
        description: 'Pending claim',
        createdAt: DateTime.now(),
        claimReference: 'cashuBmock_token',
      );
      container.read(transactionsProvider.notifier).addTransaction(tx);

      final cashuWallet = container.read(cashuWalletServiceProvider)!;

      // Action logic execution
      expect(
        () async {
          await cashuWallet.claimProtectedPayment(
            token: tx.claimReference!,
            paymentId: tx.id,
          );
        },
        throwsA(isA<StateError>().having(
            (e) => e.message, 'message', contains('Invalid claim token'))),
      );

      final currentTx = container.read(transactionsProvider).first;
      expect(currentTx.status, equals(TransactionStatus.claimable));
    });

    test(
        'Null wallet during refund throws StateError and never mutates balance or transaction',
        () async {
      final container = ProviderContainer(
        overrides: [
          cashuWalletServiceProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final tx = TransactionModel(
        id: 'outgoing_tx_1',
        type: TransactionType.protectedSend,
        status: TransactionStatus.claimable,
        amountSats: 10000,
        recipientOrSender: 'bob',
        description: 'Expired escrow',
        createdAt: DateTime.now().subtract(const Duration(hours: 48)),
        expiresAt: DateTime.now().subtract(const Duration(hours: 24)),
      );
      container.read(transactionsProvider.notifier).addTransaction(tx);

      final cashuWallet = container.read(cashuWalletServiceProvider);

      // Action logic execution
      expect(
        () async {
          if (cashuWallet == null) {
            throw StateError('Cashu wallet not initialized');
          }
          await cashuWallet.refundProtectedPayment(paymentId: tx.id);
        },
        throwsA(isA<StateError>().having((e) => e.message, 'message',
            contains('Cashu wallet not initialized'))),
      );

      final currentTx = container.read(transactionsProvider).first;
      expect(currentTx.status, equals(TransactionStatus.claimable));
    });

    test(
        'CDK refund failure throws StateError and never mutates balance or transaction',
        () async {
      final mockWallet = MockFailingCashuWalletService();
      final container = ProviderContainer(
        overrides: [
          cashuWalletServiceProvider.overrideWithValue(mockWallet),
        ],
      );
      addTearDown(container.dispose);

      final tx = TransactionModel(
        id: 'outgoing_tx_2',
        type: TransactionType.protectedSend,
        status: TransactionStatus.claimable,
        amountSats: 10000,
        recipientOrSender: 'bob',
        description: 'Unexpired escrow',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );
      container.read(transactionsProvider.notifier).addTransaction(tx);

      final cashuWallet = container.read(cashuWalletServiceProvider)!;

      // Action logic execution
      expect(
        () async {
          await cashuWallet.refundProtectedPayment(paymentId: tx.id);
        },
        throwsA(isA<StateError>().having(
            (e) => e.message, 'message', contains('Locktime not yet expired'))),
      );

      final currentTx = container.read(transactionsProvider).first;
      expect(currentTx.status, equals(TransactionStatus.claimable));
    });
  });
}
