import '../../../core/wallet/wallet_context.dart';
import '../../protected/data/protected_message_service.dart';

final class ProtectedSendDraft {
  final WalletContextKey walletContext;
  final UserPaymentProfile recipient;
  final int amountSats;
  final String description;
  final int expirationSeconds;
  final String networkLabel;

  const ProtectedSendDraft({
    required this.walletContext,
    required this.recipient,
    required this.amountSats,
    required this.description,
    required this.expirationSeconds,
    required this.networkLabel,
  });
}
