import '../network/network_environment.dart';
import 'cashu_wallet_models.dart';

final class WalletPolicyViolation implements Exception {
  final String code;
  final String message;

  const WalletPolicyViolation(this.code, this.message);

  @override
  String toString() => message;
}

final class WalletPolicy {
  final NetworkConfig config;

  const WalletPolicy(this.config);

  void validateDeposit({
    required int amountSats,
    required int currentBalanceSats,
  }) {
    if (amountSats <= 0) {
      throw const WalletPolicyViolation(
        'invalid_amount',
        'Amount must be greater than zero.',
      );
    }
    if (amountSats > config.maxDepositSats) {
      throw WalletPolicyViolation(
        'deposit_limit',
        'Maximum deposit is ${config.maxDepositSats} sats.',
      );
    }
    if (currentBalanceSats + amountSats > config.maxWalletBalanceSats) {
      throw WalletPolicyViolation(
        'wallet_limit',
        'This deposit would exceed the ${config.maxWalletBalanceSats} sat wallet limit.',
      );
    }
  }

  void validateMint({
    required int amountSats,
    required CashuWalletBalance currentBalance,
  }) {
    validateDeposit(
      amountSats: amountSats,
      currentBalanceSats: currentBalance.totalSats,
    );
  }

  void validateSend({required int amountSats}) {
    if (amountSats <= 0) {
      throw const WalletPolicyViolation(
        'invalid_amount',
        'Amount must be greater than zero.',
      );
    }
    if (amountSats > config.maxSendSats) {
      throw WalletPolicyViolation(
        'send_limit',
        'Maximum send is ${config.maxSendSats} sats.',
      );
    }
  }
}
