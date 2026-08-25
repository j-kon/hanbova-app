import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/cashu/cashu_wallet_provider.dart';
import '../../../core/crypto/crypto_identity_service.dart';
import '../../../core/crypto/encrypted_envelope_service.dart';
import '../../../core/network/network_environment.dart';
import '../../auth/providers/auth_provider.dart';
import '../../protected/data/protected_message_service.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transactions_provider.dart';
import '../../wallet/presentation/wallet_provider.dart';
import '../data/payment_intent_repository.dart';
import '../domain/protected_payment_intent.dart';

class ProtectedSendState {
  final bool isLoading;
  final String? errorMessage;
  final ProtectedPaymentIntent? createdIntent;
  final UserPaymentProfile? resolvedRecipient;

  const ProtectedSendState({
    this.isLoading = false,
    this.errorMessage,
    this.createdIntent,
    this.resolvedRecipient,
  });

  ProtectedSendState copyWith({
    bool? isLoading,
    String? errorMessage,
    ProtectedPaymentIntent? createdIntent,
    UserPaymentProfile? resolvedRecipient,
  }) {
    return ProtectedSendState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      createdIntent: createdIntent ?? this.createdIntent,
      resolvedRecipient: resolvedRecipient ?? this.resolvedRecipient,
    );
  }
}

final protectedSendProvider =
    StateNotifierProvider<ProtectedSendNotifier, ProtectedSendState>((ref) {
  final repository = ref.watch(paymentIntentRepositoryProvider);
  final messageService = ref.watch(protectedMessageServiceProvider);
  return ProtectedSendNotifier(repository, messageService, ref);
});

class ProtectedSendNotifier extends StateNotifier<ProtectedSendState> {
  final PaymentIntentRepository _repository;
  final ProtectedMessageService _messageService;
  final EncryptedEnvelopeService _envelopeService = EncryptedEnvelopeService();
  final Ref _ref;

  ProtectedSendNotifier(this._repository, this._messageService, this._ref)
      : super(const ProtectedSendState());

  /// Resolves the recipient payment profile before confirmation.
  Future<UserPaymentProfile?> resolveRecipient(String username) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final clean = username.trim().replaceAll('@', '');
      final profile = await _messageService.resolveUserPaymentProfile(clean);
      state = state.copyWith(isLoading: false, resolvedRecipient: profile);
      return profile;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        resolvedRecipient: null,
        errorMessage:
            'Recipient @$username could not be found or has not registered payment keys.',
      );
      return null;
    }
  }

  Future<bool> createProtectedPayment({
    required int amountSats,
    required String recipientIdentifier,
    required String description,
    required int expirationSeconds,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authState = _ref.read(authProvider);
      final network = _ref.read(networkEnvironmentProvider);
      final config = NetworkConfig.fromNetwork(network);

      final senderUsername = authState.user?.username ?? 'alice';
      final cleanRecipient = recipientIdentifier.trim().replaceAll('@', '');

      // 1. Resolve recipient keys if not already resolved
      final recipientProfile =
          state.resolvedRecipient ?? await resolveRecipient(cleanRecipient);
      if (recipientProfile == null) {
        throw StateError(
            'Recipient @$cleanRecipient could not be found or has not registered payment keys.');
      }

      // 2. Generate or load Sender Cryptographic Identity
      final cryptoService = _ref.read(cryptoIdentityProvider.notifier);
      await cryptoService.getOrCreateIdentity(
        userId: authState.user?.id ?? 'sender_local',
        network: network,
      );

      final paymentId = const Uuid().v4();
      final now = DateTime.now();
      final expiry = now.add(Duration(seconds: expirationSeconds));
      final locktimeUnix = expiry.millisecondsSinceEpoch ~/ 1000;

      // 3. Create Cashu P2PK Token via official CDK
      final cashuWallet = _ref.read(cashuWalletServiceProvider);
      if (cashuWallet == null) {
        throw StateError(
            'Cashu wallet is not initialized. Please ensure your wallet seed is configured.');
      }

      final cashuToken = await cashuWallet.createProtectedSend(
        amountSats: amountSats,
        recipientPubkey: recipientProfile.protectedPaymentPubkey,
        locktime: expiry,
        paymentId: paymentId,
      );
      _ref.invalidate(cashuBalanceProvider);

      // 4. Encrypt Protected Payment Envelope for Recipient's Transport Key
      final envelope = ProtectedPaymentEnvelope(
        version: 1,
        paymentId: paymentId,
        cashuToken: cashuToken,
        mintUrl: config.defaultMintUrl,
        amountSats: amountSats,
        senderUsername: senderUsername,
        recipientUsername: cleanRecipient,
        locktime: locktimeUnix,
      );

      final ciphertext = await _envelopeService.encryptEnvelope(
        envelope: envelope,
        recipientTransportPubkeyHex: recipientProfile.transportEncryptionPubkey,
      );

      // 5. Send Encrypted Envelope to Hanbova Backend Relay
      await _messageService.sendProtectedMessage(
        recipientUsername: cleanRecipient,
        encryptedPayload: ciphertext,
        payloadVersion: 1,
        paymentIntentId: paymentId,
      );

      // 6. Record Payment Intent locally
      final intent = await _repository.createPaymentIntent(
        paymentType: 'protected',
        amountSats: amountSats,
        recipientIdentifier: recipientProfile.handle,
        description: description.isEmpty ? null : description,
        expiresInSeconds: expirationSeconds,
      );

      // 7. Lock balance in protected outgoing pool
      _ref.read(walletStateProvider.notifier).lockProtectedOutgoing(amountSats);

      _ref.read(transactionsProvider.notifier).addTransaction(
            TransactionModel(
              id: intent.id,
              type: TransactionType.protectedSend,
              status: TransactionStatus.claimable,
              amountSats: amountSats,
              recipientOrSender: recipientProfile.handle,
              description: description,
              createdAt: intent.createdAt,
              expiresAt: intent.expiresAt,
              claimReference: cashuToken,
            ),
          );

      state = state.copyWith(isLoading: false, createdIntent: intent);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void reset() {
    state = const ProtectedSendState();
  }
}
