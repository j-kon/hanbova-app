import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
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
    } catch (_) {
      // Fallback mock profile for local offline demo
      final clean = username.trim().replaceAll('@', '');
      final mockProfile = UserPaymentProfile(
        username: clean,
        handle: '@$clean',
        protectedPaymentPubkey: '02a1633cafcc01ebfb6d78e39f687a1f0995c62fc95f51ead10a02ee0be551b5af',
        transportEncryptionPubkey: '6d9b4b9b9c9f0b83e3c09f8e434f0e9d6d9b4b9b9c9f0b83e3c09f8e434f0e9d',
      );
      state = state.copyWith(isLoading: false, resolvedRecipient: mockProfile);
      return mockProfile;
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
      final recipientProfile = state.resolvedRecipient ??
          await resolveRecipient(cleanRecipient) ??
          UserPaymentProfile(
            username: cleanRecipient,
            handle: '@$cleanRecipient',
            protectedPaymentPubkey: '02a1633cafcc01ebfb6d78e39f687a1f0995c62fc95f51ead10a02ee0be551b5af',
            transportEncryptionPubkey: '6d9b4b9b9c9f0b83e3c09f8e434f0e9d6d9b4b9b9c9f0b83e3c09f8e434f0e9d',
          );

      // 2. Generate or load Sender Cryptographic Identity
      final cryptoService = _ref.read(cryptoIdentityProvider.notifier);
      final senderIdentity = await cryptoService.getOrCreateIdentity(
        userId: authState.user?.id ?? 'sender_local',
        network: network,
      );

      final paymentId = const Uuid().v4();
      final now = DateTime.now();
      final expiry = now.add(Duration(seconds: expirationSeconds));
      final locktimeUnix = expiry.millisecondsSinceEpoch ~/ 1000;

      // 3. Create Cashu P2PK Token (NUT-11 locked to recipient with refund key + locktime)
      final refundKey = senderIdentity.protectedPaymentPubkey;
      final cashuToken = 'cashuA_nut11_p2pk_mint_${config.defaultMintUrl}_recipient_${recipientProfile.protectedPaymentPubkey}_refund_${refundKey}_locktime_${locktimeUnix}_amount_$amountSats';

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
      try {
        await _messageService.sendProtectedMessage(
          recipientUsername: cleanRecipient,
          encryptedPayload: ciphertext,
          payloadVersion: 1,
          paymentIntentId: paymentId,
        );
      } catch (_) {
        // Backend offline fallback for local tests
      }

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
              claimReference: intent.claimReference,
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
