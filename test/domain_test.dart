import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/utils/formatters.dart';
import 'package:hanbova_app/features/protected_send/domain/protected_payment_intent.dart';
import 'package:hanbova_app/features/wallet/presentation/wallet_provider.dart';

void main() {
  group('Formatters tests', () {
    test('formats satoshis with commas', () {
      expect(Formatters.formatSats(1000), '1,000 sats');
      expect(Formatters.formatSats(21000000), '21,000,000 sats');
    });

    test('formats sats to usd conversion', () {
      final usd = Formatters.satsToUsd(100000000, btcUsdRate: 100000.0);
      expect(usd, '\$100,000.00');
    });

    test('formats expiration time remaining', () {
      final future = DateTime.now().add(const Duration(hours: 5, minutes: 30));
      expect(Formatters.formatExpiresIn(future), contains('5h'));

      final expired = DateTime.now().subtract(const Duration(minutes: 10));
      expect(Formatters.formatExpiresIn(expired), 'Expired');
    });
  });

  group('ProtectedPaymentIntent model tests', () {
    test('serializes and deserializes JSON correctly', () {
      final json = {
        'id': 'test-uuid-1234',
        'payment_type': 'protected',
        'status': 'claimable',
        'amount_sats': 50000,
        'sender_id': 'sender_alice',
        'recipient_identifier': 'bob@hanbova.africa',
        'description': 'Freelance project delivery',
        'expires_at': '2026-12-31T23:59:59.000Z',
        'claim_reference': 'hnbv_claim_test1',
        'created_at': '2026-08-23T12:00:00.000Z',
      };

      final intent = ProtectedPaymentIntent.fromJson(json);
      expect(intent.id, 'test-uuid-1234');
      expect(intent.amountSats, 50000);
      expect(intent.status, 'claimable');
      expect(intent.recipientIdentifier, 'bob@hanbova.africa');

      final serialized = intent.toJson();
      expect(serialized['id'], 'test-uuid-1234');
      expect(serialized['amount_sats'], 50000);
    });
  });

  group('WalletStateNotifier state tests', () {
    test('deducts, locks and credits balance properly', () {
      final notifier = WalletStateNotifier();
      expect(notifier.state.spendableSats, 250000);
      expect(notifier.state.protectedOutgoingSats, 0);

      notifier.lockProtectedOutgoing(50000);
      expect(notifier.state.spendableSats, 200000);
      expect(notifier.state.protectedOutgoingSats, 50000);

      notifier.unlockRefundToSpendable(50000);
      expect(notifier.state.spendableSats, 250000);
      expect(notifier.state.protectedOutgoingSats, 0);

      notifier.creditBalance(10000);
      expect(notifier.state.spendableSats, 260000);
    });
  });
}
