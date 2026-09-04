import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_models.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_provider.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_service.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_storage.dart';
import 'package:hanbova_app/core/network/network_environment.dart';
import 'package:hanbova_app/core/networking/api_client.dart';
import 'package:hanbova_app/core/wallet/wallet_context.dart';
import 'package:hanbova_app/features/auth/models/user_profile.dart';
import 'package:hanbova_app/features/auth/providers/auth_provider.dart';
import 'package:hanbova_app/features/protected/data/protected_message_service.dart';
import 'package:hanbova_app/features/protected_send/data/payment_intent_repository.dart';
import 'package:hanbova_app/features/protected_send/domain/protected_payment_intent.dart';
import 'package:hanbova_app/features/protected_send/presentation/protected_send_provider.dart';
import 'package:hanbova_app/features/transactions/domain/transaction_model.dart';
import 'package:hanbova_app/features/transactions/presentation/transactions_provider.dart';
import 'package:http/http.dart' as http;

import 'support/memory_transaction_ledger.dart';

final _user = UserProfile(
  id: 'usr_alice',
  username: 'alice',
  handle: '@alice',
  email: 'alice@example.com',
  firstName: 'Alice',
  lastName: 'Example',
  displayName: 'Alice Example',
  emailVerified: true,
  createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
);

final class _AuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _AuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _UnusedWallet implements CashuWalletService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _RecordingStorage extends CashuWalletStorage {
  String? requestedPrefix;

  _RecordingStorage(this.escrow);

  final ProtectedEscrowRecord escrow;

  @override
  Future<ProtectedEscrowRecord?> getEscrowRecord(
    String userId,
    HanbovaNetwork network,
    String paymentId, {
    String? storagePrefix,
  }) async {
    requestedPrefix = storagePrefix;
    return escrow;
  }
}

final class _MessageService extends ProtectedMessageService {
  _MessageService()
      : super(
            ApiClient(baseUrl: 'http://localhost', httpClient: http.Client()));

  @override
  Future<UserPaymentProfile> resolveUserPaymentProfile(
    String username, {
    String? environment,
  }) async {
    return UserPaymentProfile(
      username: 'bob',
      handle: '@bob',
      walletEnvironment: environment ?? '',
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
    String? recipientTransportKeyFingerprint,
    String? recipientP2pkKeyFingerprint,
    String? walletEnvironment,
  }) async {
    return RemoteProtectedMessage(
      id: 'message_1',
      paymentIntentId: paymentIntentId,
      senderUsername: 'alice',
      recipientUsername: recipientUsername,
      encryptedPayload: encryptedPayload,
      payloadVersion: payloadVersion,
      status: 'pending',
      walletEnvironment: walletEnvironment,
      createdAt: DateTime.now(),
    );
  }
}

final class _IntentRepository extends PaymentIntentRepository {
  _IntentRepository()
      : super(
            ApiClient(baseUrl: 'http://localhost', httpClient: http.Client()));

  @override
  Future<ProtectedPaymentIntent> updatePaymentStatus(
    String id,
    String status,
  ) async {
    return ProtectedPaymentIntent(
      id: id,
      paymentType: 'protected',
      status: status,
      amountSats: 300,
      senderId: _user.id,
      recipientIdentifier: '@bob',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  test('pilot retry reads escrow from the active wallet storage prefix',
      () async {
    const context = WalletContextKey(
      userId: 'usr_alice',
      network: HanbovaNetwork.mainnet,
      storagePrefix: 'wallet_mainnet_pilot',
    );
    final storage = _RecordingStorage(
      ProtectedEscrowRecord(
        paymentId: 'payment_1',
        token: 'cashuA_existing_token',
        amountSats: 300,
        recipientPubkey:
            '02a1633cafcc01ebfb6d78e39f687a1f0995c62fc95f51ead10a02ee0be551b5af',
        refundPubkey:
            '03b2744dbfdd02fc0c7e89f40a798b201aa6d73ad06062fbe21b13ff1cf662c6ba',
        refundPrivkeyHex:
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        locktime: DateTime.now().add(const Duration(hours: 1)),
        isOutgoing: true,
        status: 'locked',
        createdAt: DateTime.now(),
      ),
    );
    final ledger = MemoryTransactionLedger();
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(
          (ref) => _AuthNotifier(AuthState.authenticated(_user, 'jwt')),
        ),
        activeWalletContextKeyProvider.overrideWithValue(context),
        activeNetworkConfigProvider
            .overrideWithValue(NetworkConfig.mainnetPilot),
        cashuWalletServiceProvider.overrideWithValue(_UnusedWallet()),
        cashuWalletStorageProvider.overrideWithValue(storage),
        protectedMessageServiceProvider.overrideWithValue(_MessageService()),
        paymentIntentRepositoryProvider.overrideWithValue(_IntentRepository()),
        transactionLedgerProvider.overrideWithValue(ledger),
      ],
    );
    addTearDown(container.dispose);

    await container.read(transactionsProvider.notifier).addTransaction(
          TransactionModel(
            id: 'payment_1',
            type: TransactionType.protectedSend,
            status: TransactionStatus.pending,
            amountSats: 300,
            recipientOrSender: '@bob',
            createdAt: DateTime.now(),
          ),
        );

    final success = await container
        .read(protectedSendProvider.notifier)
        .retryDelivery('payment_1');

    expect(success, isTrue);
    expect(storage.requestedPrefix, 'wallet_mainnet_pilot');
  });
}
