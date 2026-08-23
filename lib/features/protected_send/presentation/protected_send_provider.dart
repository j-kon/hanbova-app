import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/payment_intent_repository.dart';
import '../domain/protected_payment_intent.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transactions_provider.dart';
import '../../wallet/presentation/wallet_provider.dart';

class ProtectedSendState {
  final bool isLoading;
  final String? errorMessage;
  final ProtectedPaymentIntent? createdIntent;

  const ProtectedSendState({
    this.isLoading = false,
    this.errorMessage,
    this.createdIntent,
  });

  ProtectedSendState copyWith({
    bool? isLoading,
    String? errorMessage,
    ProtectedPaymentIntent? createdIntent,
  }) {
    return ProtectedSendState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      createdIntent: createdIntent ?? this.createdIntent,
    );
  }
}

final protectedSendProvider =
    StateNotifierProvider<ProtectedSendNotifier, ProtectedSendState>((ref) {
  final repository = ref.watch(paymentIntentRepositoryProvider);
  return ProtectedSendNotifier(repository, ref);
});

class ProtectedSendNotifier extends StateNotifier<ProtectedSendState> {
  final PaymentIntentRepository _repository;
  final Ref _ref;

  ProtectedSendNotifier(this._repository, this._ref)
      : super(const ProtectedSendState());

  Future<bool> createProtectedPayment({
    required int amountSats,
    required String recipientIdentifier,
    required String description,
    required int expirationSeconds,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final intent = await _repository.createPaymentIntent(
        paymentType: 'protected',
        amountSats: amountSats,
        recipientIdentifier: recipientIdentifier,
        description: description.isEmpty ? null : description,
        expiresInSeconds: expirationSeconds,
      );

      // Lock balance in protected outgoing pool
      _ref.read(walletStateProvider.notifier).lockProtectedOutgoing(amountSats);

      _ref.read(transactionsProvider.notifier).addTransaction(
            TransactionModel(
              id: intent.id,
              type: TransactionType.protectedSend,
              status: TransactionStatus.claimable,
              amountSats: amountSats,
              recipientOrSender: recipientIdentifier,
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
