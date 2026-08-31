import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/cashu/cashu_wallet_provider.dart';
import '../../../core/cashu/cashu_wallet_storage.dart';
import '../../../core/crypto/crypto_identity_service.dart';
import '../../../core/crypto/encrypted_envelope_service.dart';
import '../../../core/network/network_environment.dart';
import '../../../core/notifications/in_app_notification.dart';
import '../../../core/utils/consumer_error_translator.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../../protected/data/protected_message_service.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transactions_provider.dart';
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
    bool clearResolvedRecipient = false,
  }) {
    return ProtectedSendState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      createdIntent: createdIntent ?? this.createdIntent,
      resolvedRecipient: clearResolvedRecipient
          ? null
          : (resolvedRecipient ?? this.resolvedRecipient),
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
    final clean = username.trim().startsWith('@')
        ? username.trim().substring(1).toLowerCase()
        : username.trim().toLowerCase();
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      clearResolvedRecipient: true,
    );
    try {
      final config = _ref.read(activeNetworkConfigProvider);
      final profile = await _messageService.resolveUserPaymentProfile(
        clean,
        environment: config.storagePrefix,
      );
      state = state.copyWith(isLoading: false, resolvedRecipient: profile);
      return profile;
    } catch (e) {
      final displayHandle =
          username.trim().startsWith('@') || username.contains('@')
              ? username.trim()
              : '@${username.trim()}';
      state = state.copyWith(
        isLoading: false,
        clearResolvedRecipient: true,
        errorMessage:
            'Recipient $displayHandle could not be found or has not registered payment keys for this environment.',
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
      if (authState.user == null) {
        throw StateError(
            'User must be authenticated to send protected payments.');
      }

      final config = _ref.read(activeNetworkConfigProvider);
      if (amountSats > config.maxSendSats) {
        throw StateError(
            'Amount of $amountSats sats exceeds maximum send limit of ${config.maxSendSats} sats for ${config.displayName}.');
      }

      final senderUsername = authState.user!.username;
      final senderId = authState.user!.id;
      final cleanRecipient = recipientIdentifier.trim().startsWith('@')
          ? recipientIdentifier.trim().substring(1).toLowerCase()
          : recipientIdentifier.trim().toLowerCase();

      // 1. Resolve recipient keys strictly matching current entered recipient
      UserPaymentProfile? recipientProfile;
      if (state.resolvedRecipient != null &&
          (state.resolvedRecipient!.username.toLowerCase() == cleanRecipient ||
              state.resolvedRecipient!.handle.toLowerCase() == cleanRecipient ||
              state.resolvedRecipient!.handle.toLowerCase() ==
                  '@$cleanRecipient') &&
          state.resolvedRecipient!.walletEnvironment == config.storagePrefix) {
        recipientProfile = state.resolvedRecipient;
      } else {
        recipientProfile = await resolveRecipient(cleanRecipient);
      }

      if (recipientProfile == null) {
        final display = recipientIdentifier.trim().startsWith('@') ||
                recipientIdentifier.contains('@')
            ? recipientIdentifier.trim()
            : '@${recipientIdentifier.trim()}';
        throw StateError(
            'Recipient $display could not be found or has not registered payment keys.');
      }

      // 2. Generate or load Sender Cryptographic Identity
      final cryptoService = _ref.read(cryptoIdentityProvider.notifier);
      await cryptoService.requireIdentity();

      final now = DateTime.now();
      final expiry = now.add(Duration(seconds: expirationSeconds));
      final locktimeUnix = expiry.millisecondsSinceEpoch ~/ 1000;

      // 3. Create backend PaymentIntent FIRST (Lifecycle status: Created)
      final intent = await _repository.createPaymentIntent(
        paymentType: 'protected',
        amountSats: amountSats,
        recipientIdentifier: recipientProfile.handle,
        senderId: senderId,
        description: description.isEmpty ? null : description,
        expiresInSeconds: expirationSeconds,
      );
      final canonicalPaymentId = intent.id;

      // 4. Create Cashu P2PK Token via official CDK using canonical intent.id
      final cashuWallet = _ref.read(cashuWalletServiceProvider);
      if (cashuWallet == null) {
        throw StateError(
            'Cashu wallet is not initialized. Please ensure your wallet seed is configured.');
      }

      String cashuToken;
      try {
        cashuToken = await cashuWallet.createProtectedSend(
          amountSats: amountSats,
          recipientPubkey: recipientProfile.protectedPaymentPubkey,
          locktime: expiry,
          paymentId: canonicalPaymentId,
        );
        _ref.invalidate(cashuBalanceProvider);
      } catch (cdkError) {
        throw StateError('Failed to lock ecash in CDK: $cdkError');
      }

      // CRITICAL: Once createProtectedSend succeeds, immediately persist a local
      // Active/Pending transaction using canonical PaymentIntent ID BEFORE envelope encryption.
      final activeTx = TransactionModel(
        id: canonicalPaymentId,
        type: TransactionType.protectedSend,
        status: TransactionStatus.pending,
        amountSats: amountSats,
        recipientOrSender: recipientProfile.handle,
        description: description,
        createdAt: intent.createdAt,
        expiresAt: intent.expiresAt,
        claimReference: intent.claimReference ?? intent.id,
      );
      _ref.read(transactionsProvider.notifier).addTransaction(activeTx);

      // Lifecycle: funds successfully locked in CDK -> update backend to Protected
      try {
        await _repository.updatePaymentStatus(canonicalPaymentId, 'protected');
      } catch (_) {
        _ref
            .read(transactionsProvider.notifier)
            .markCoordinationSyncPending(canonicalPaymentId, 'protected');
      }

      // 5. Encrypt Protected Payment Envelope for Recipient's Transport Key
      String ciphertext;
      try {
        final envelope = ProtectedPaymentEnvelope(
          version: 1,
          paymentId: canonicalPaymentId,
          cashuToken: cashuToken,
          mintUrl: config.defaultMintUrl,
          amountSats: amountSats,
          senderUsername: senderUsername,
          recipientUsername: cleanRecipient,
          locktime: locktimeUnix,
        );

        ciphertext = await _envelopeService.encryptEnvelope(
          envelope: envelope,
          recipientTransportPubkeyHex:
              recipientProfile.transportEncryptionPubkey,
        );
      } catch (encError) {
        _ref.read(transactionsProvider.notifier).updateTransaction(
              activeTx.copyWith(
                description: 'Encryption pending: $encError',
              ),
            );
        throw StateError('Failed to encrypt transport envelope: $encError');
      }

      // 6. Send Encrypted Envelope to Hanbova Backend Relay referencing intent.id
      try {
        await _messageService.sendProtectedMessage(
          recipientUsername: cleanRecipient,
          encryptedPayload: ciphertext,
          payloadVersion: 1,
          paymentIntentId: canonicalPaymentId,
          recipientTransportKeyFingerprint:
              recipientProfile.transportKeyFingerprint,
          recipientP2pkKeyFingerprint:
              recipientProfile.protectedPaymentFingerprint,
          walletEnvironment: config.storagePrefix,
        );

        // Lifecycle: encrypted message accepted by relay -> update local to Claimable
        _ref.read(transactionsProvider.notifier).updateTransaction(
              activeTx.copyWith(
                status: TransactionStatus.claimable,
                description: description,
              ),
            );

        try {
          await _repository.updatePaymentStatus(
              canonicalPaymentId, 'claimable');
          _ref
              .read(transactionsProvider.notifier)
              .clearCoordinationSyncPending(canonicalPaymentId);
        } catch (_) {
          _ref
              .read(transactionsProvider.notifier)
              .markCoordinationSyncPending(canonicalPaymentId, 'claimable');
        }
      } catch (deliveryError) {
        // Backend delivery failed, but CDK value is locked in redb!
        // Local transaction is preserved with pending status.
        _ref.read(transactionsProvider.notifier).updateTransaction(
              activeTx.copyWith(
                status: TransactionStatus.pending,
                description: 'Delivery pending: $deliveryError',
              ),
            );
        throw StateError('Payment delivery to relay failed: $deliveryError');
      }

      state = state.copyWith(isLoading: false, createdIntent: intent);
      _ref.read(inAppNotificationProvider.notifier).show(
            title: 'Protected Payment Sent',
            message:
                'Locked ${Formatters.formatSats(amountSats)} in escrow for $recipientIdentifier',
            icon: Icons.shield_outlined,
            type: InAppNotificationType.protected,
          );
      return true;
    } catch (e) {
      final cleanMsg = ConsumerErrorTranslator.translate(e);
      state = state.copyWith(isLoading: false, errorMessage: cleanMsg);
      return false;
    }
  }

  /// Retries delivery of an existing locked escrow without creating another CDK token.
  Future<bool> retryDelivery(String canonicalPaymentId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final authState = _ref.read(authProvider);
      if (authState.user == null) {
        throw StateError('User must be authenticated to retry delivery.');
      }

      final cashuWallet = _ref.read(cashuWalletServiceProvider);
      if (cashuWallet == null) {
        throw StateError('Cashu wallet is not initialized.');
      }

      final transactions = _ref.read(transactionsProvider);
      final tx = transactions.firstWhere(
        (t) => t.id == canonicalPaymentId,
        orElse: () =>
            throw StateError('Transaction $canonicalPaymentId not found'),
      );

      final cleanRecipient = tx.recipientOrSender.trim().startsWith('@')
          ? tx.recipientOrSender.trim().substring(1).toLowerCase()
          : tx.recipientOrSender.trim().toLowerCase();
      final recipientProfile = await resolveRecipient(cleanRecipient);
      if (recipientProfile == null) {
        final display = tx.recipientOrSender.trim().startsWith('@') ||
                tx.recipientOrSender.contains('@')
            ? tx.recipientOrSender.trim()
            : '@${tx.recipientOrSender.trim()}';
        throw StateError('Recipient $display could not be found');
      }

      final config = _ref.read(activeNetworkConfigProvider);

      // Load the existing escrow record from client storage (no new token minted or locked)
      final storage = CashuWalletStorage();
      final escrow = await storage.getEscrowRecord(
        authState.user!.id,
        config.network,
        canonicalPaymentId,
        storagePrefix: config.storagePrefix,
      );
      if (escrow == null) {
        throw StateError(
            'Escrow record for payment $canonicalPaymentId not found in local storage');
      }

      final envelope = ProtectedPaymentEnvelope(
        version: 1,
        paymentId: canonicalPaymentId,
        cashuToken: escrow.token,
        mintUrl: config.defaultMintUrl,
        amountSats: escrow.amountSats,
        senderUsername: authState.user!.username,
        recipientUsername: recipientProfile.username,
        locktime: escrow.locktime.millisecondsSinceEpoch ~/ 1000,
      );

      final ciphertext = await _envelopeService.encryptEnvelope(
        envelope: envelope,
        recipientTransportPubkeyHex: recipientProfile.transportEncryptionPubkey,
      );

      await _messageService.sendProtectedMessage(
        recipientUsername: recipientProfile.username,
        encryptedPayload: ciphertext,
        payloadVersion: 1,
        paymentIntentId: canonicalPaymentId,
        recipientTransportKeyFingerprint:
            recipientProfile.transportKeyFingerprint,
        recipientP2pkKeyFingerprint:
            recipientProfile.protectedPaymentFingerprint,
        walletEnvironment: config.storagePrefix,
      );

      _ref.read(transactionsProvider.notifier).updateTransactionStatus(
            canonicalPaymentId,
            TransactionStatus.claimable,
          );

      try {
        await _repository.updatePaymentStatus(canonicalPaymentId, 'claimable');
        _ref
            .read(transactionsProvider.notifier)
            .clearCoordinationSyncPending(canonicalPaymentId);
      } catch (_) {
        _ref
            .read(transactionsProvider.notifier)
            .markCoordinationSyncPending(canonicalPaymentId, 'claimable');
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final cleanMsg = ConsumerErrorTranslator.translate(e);
      state = state.copyWith(isLoading: false, errorMessage: cleanMsg);
      return false;
    }
  }

  void reset() {
    state = const ProtectedSendState();
  }
}
