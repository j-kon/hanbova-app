import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/wallet_model.dart';

final walletStateProvider =
    StateNotifierProvider<WalletStateNotifier, WalletModel>((ref) {
  return WalletStateNotifier();
});

class WalletStateNotifier extends StateNotifier<WalletModel> {
  WalletStateNotifier()
      : super(
          const WalletModel(
            spendableSats: 250000,
            protectedOutgoingSats: 0,
            protectedIncomingSats: 0,
            nodeAlias: 'hanbova-cashu-dev',
          ),
        );

  void lockProtectedOutgoing(int sats) {
    if (state.spendableSats >= sats) {
      state = state.copyWith(
        spendableSats: state.spendableSats - sats,
        protectedOutgoingSats: state.protectedOutgoingSats + sats,
      );
    }
  }

  void unlockRefundToSpendable(int sats) {
    state = state.copyWith(
      spendableSats: state.spendableSats + sats,
      protectedOutgoingSats: (state.protectedOutgoingSats - sats).clamp(0, 100000000),
    );
  }

  void confirmClaimedByRecipient(int sats) {
    state = state.copyWith(
      protectedOutgoingSats: (state.protectedOutgoingSats - sats).clamp(0, 100000000),
    );
  }

  void creditBalance(int sats) {
    state = state.copyWith(
      spendableSats: state.spendableSats + sats,
      protectedIncomingSats: (state.protectedIncomingSats - sats).clamp(0, 100000000),
    );
  }

  void deductBalance(int sats) {
    if (state.spendableSats >= sats) {
      state = state.copyWith(
        spendableSats: state.spendableSats - sats,
      );
    }
  }

  void setProtectedIncoming(int sats) {
    state = state.copyWith(protectedIncomingSats: sats);
  }
}
