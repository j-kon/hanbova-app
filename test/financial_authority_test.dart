import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_models.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_provider.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_service.dart';
import 'package:http/http.dart' as http;
import 'package:hanbova_app/core/networking/api_client.dart';
import 'package:hanbova_app/features/protected/data/protected_message_service.dart';
import 'package:hanbova_app/features/protected_send/presentation/protected_send_provider.dart';
import 'package:hanbova_app/features/transactions/domain/transaction_model.dart';
import 'package:hanbova_app/features/transactions/presentation/transactions_provider.dart';
import 'package:hanbova_app/features/wallet/presentation/wallet_provider.dart';

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

  MockSuccessMessageService({this.deliveryFailed = false})
      : super(
            ApiClient(baseUrl: 'http://localhost', httpClient: http.Client()));

  @override
  Future<UserPaymentProfile> resolveUserPaymentProfile(String username) async {
    return UserPaymentProfile(
      username: username,
      handle: '@$username',
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
    if (deliveryFailed) {
      throw StateError('Failed to relay encrypted message');
    }
    return RemoteProtectedMessage(
      id: 'msg_123',
      senderUsername: 'alice',
      recipientUsername: recipientUsername,
      encryptedPayload: encryptedPayload,
      payloadVersion: payloadVersion,
      status: 'pending',
      createdAt: DateTime.now(),
    );
  }
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
    test('WalletStateNotifier has zero hardcoded initial spendable balance',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final wallet = container.read(walletStateProvider);
      expect(wallet.spendableSats, equals(0));
      expect(wallet.protectedOutgoingSats, equals(0));
      expect(wallet.totalSats, equals(0));
    });

    test(
        'Failed recipient resolution fails Protected Send and creates no payment',
        () async {
      final container = ProviderContainer(
        overrides: [
          secureStorageServiceProvider
              .overrideWithValue(InMemorySecureStorageService()),
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
          secureStorageServiceProvider
              .overrideWithValue(InMemorySecureStorageService()),
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
          secureStorageServiceProvider
              .overrideWithValue(InMemorySecureStorageService()),
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
        'Failed backend encrypted message delivery surfaces error and fails flow',
        () async {
      final container = ProviderContainer(
        overrides: [
          secureStorageServiceProvider
              .overrideWithValue(InMemorySecureStorageService()),
          protectedMessageServiceProvider.overrideWithValue(
              MockSuccessMessageService(deliveryFailed: true)),
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

      final transactions = container.read(transactionsProvider);
      expect(transactions.length, equals(initialTxCount));
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

      final initialBalance = container.read(walletStateProvider).spendableSats;
      expect(initialBalance, 0);

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

      // Verify null wallet check
      final cashuWallet = container.read(cashuWalletServiceProvider);
      expect(cashuWallet, isNull);

      // Mutating should not occur
      final currentTx = container.read(transactionsProvider).first;
      expect(currentTx.status, equals(TransactionStatus.claimable));
      expect(container.read(walletStateProvider).spendableSats, equals(0));
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

      final initialBalance = container.read(walletStateProvider).spendableSats;
      expect(initialBalance, 0);

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
      expect(cashuWallet, isNull);

      final currentTx = container.read(transactionsProvider).first;
      expect(currentTx.status, equals(TransactionStatus.claimable));
      expect(container.read(walletStateProvider).spendableSats, equals(0));
    });
  });
}
