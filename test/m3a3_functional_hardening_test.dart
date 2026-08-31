import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/utils/consumer_error_translator.dart';
import 'package:hanbova_app/features/protected_send/domain/protected_payment_intent.dart';
import 'package:hanbova_app/features/security/presentation/restore_seed_screen.dart';
import 'package:hanbova_app/features/transactions/domain/transaction_model.dart';
import 'package:hanbova_app/features/transactions/presentation/transactions_provider.dart';

void main() {
  group('Milestone 3A.3 - Consumer Error Translator Tests', () {
    test('Translates network connectivity exceptions', () {
      final msg = ConsumerErrorTranslator.translate(
          'SocketException: Failed host lookup: mint.hanbova.africa');
      expect(msg,
          'Network connection unavailable. Please check your connection and try again.');
    });

    test('Translates mint unreachable errors', () {
      final msg = ConsumerErrorTranslator.translate(
          'Exception: Mint 503 unavailable at http://127.0.0.1:3338');
      expect(msg, 'Mint unreachable. Please try again in a few moments.');
    });

    test('Translates already spent token error', () {
      final msg = ConsumerErrorTranslator.translate(
          'Bad state: Cashu token inputs already spent at mint');
      expect(msg, 'Payment has already been claimed or refunded.');
    });

    test('Translates locktime not expired error', () {
      final msg = ConsumerErrorTranslator.translate(
          'Bad state: Locktime has not expired; refund unavailable');
      expect(msg,
          'Refund not available yet. The protection locktime has not expired.');
    });

    test('Translates key/fingerprint mismatch', () {
      final msg = ConsumerErrorTranslator.translate(
          'Bad state: Recipient transport key fingerprint mismatch');
      expect(msg,
          'Recipient wallet identity changed. Please verify recipient handle.');
    });

    test('Translates delivery/relay errors', () {
      final msg = ConsumerErrorTranslator.translate(
          'Bad state: Payment delivery to relay failed');
      expect(msg,
          'Payment locked in wallet. Delivery pending — tap Retry Delivery.');
    });

    test('Redacts long hex sequences and file paths from errors', () {
      final msg = ConsumerErrorTranslator.translate(
          'Bad state: secret key 0123456789abcdef0123456789abcdef0123456789abcdef in /Users/jaykon/app/wallet.redb');
      expect(msg.contains('0123456789abcdef0123456789abcdef0123456789abcdef'),
          isFalse);
      expect(msg.contains('/Users/jaykon/app/wallet.redb'), isFalse);
      expect(msg.contains('[redacted]'), isTrue);
      expect(msg.contains('[local path]'), isTrue);
    });
  });

  group('Milestone 3A.3 - Single Financial Source of Truth & Reconciliation',
      () {
    test(
        'TransactionsNotifier preserves client financial authority on backend sync',
        () {
      final notifier = TransactionsNotifier();

      // 1. Add locally completed claim
      final localTx = TransactionModel(
        id: 'intent_123',
        type: TransactionType.protectedClaim,
        status: TransactionStatus.completed,
        amountSats: 5000,
        recipientOrSender: '@alice',
        description: 'Test Claim',
        createdAt: DateTime.now(),
      );
      notifier.addTransaction(localTx);

      // 2. Backend still reports 'claimable' (e.g. sync lag or pending backend coordination)
      final backendIntent = ProtectedPaymentIntent(
        id: 'intent_123',
        amountSats: 5000,
        recipientIdentifier: 'bob',
        senderId: 'alice',
        status: 'claimable',
        paymentType: 'protected',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      notifier.syncPaymentIntents(
        intents: [backendIntent],
        currentUserId: 'bob',
        currentUsername: 'bob',
      );

      // 3. Financial truth must remain completed
      final updated = notifier.state.firstWhere((t) => t.id == 'intent_123');
      expect(updated.status, TransactionStatus.completed);
    });

    test(
        'TransactionsNotifier preserves refunded status against stale intent status',
        () {
      final notifier = TransactionsNotifier();

      final localTx = TransactionModel(
        id: 'intent_456',
        type: TransactionType.protectedSend,
        status: TransactionStatus.refunded,
        amountSats: 10000,
        recipientOrSender: '@bob',
        description: 'Test Send',
        createdAt: DateTime.now(),
      );
      notifier.addTransaction(localTx);

      final backendIntent = ProtectedPaymentIntent(
        id: 'intent_456',
        amountSats: 10000,
        recipientIdentifier: 'bob',
        senderId: 'alice',
        status: 'claimable',
        paymentType: 'protected',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      notifier.syncPaymentIntents(
        intents: [backendIntent],
        currentUserId: 'alice',
        currentUsername: 'alice',
      );

      final updated = notifier.state.firstWhere((t) => t.id == 'intent_456');
      expect(updated.status, TransactionStatus.refunded);
    });
  });

  group('Milestone 3A.3 - Recovery Scope Truthfulness', () {
    test('restoredMessage explicitly separates identity from proof restoration',
        () {
      expect(
          restoredMessage,
          contains(
              'Your signing keys and account identity have been restored.'));
      expect(
          restoredMessage,
          contains(
              'Ecash proofs stored locally on another device require local database transfer'));
      expect(restoredMessage, contains('NUT-13'));
    });
  });
}
