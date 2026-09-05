import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/features/protected/data/protected_message_service.dart';
import 'package:hanbova_app/features/protected_send/domain/protected_payment_intent.dart';
import 'package:hanbova_app/features/transactions/domain/transaction_model.dart';
import 'support/memory_transaction_ledger.dart';

RemoteProtectedMessage message(
        {String? paymentId = 'payment', String status = 'delivered'}) =>
    RemoteProtectedMessage(
      id: 'message',
      paymentIntentId: paymentId,
      senderUsername: 'alice',
      recipientUsername: 'bob',
      encryptedPayload: 'opaque-test-envelope',
      payloadVersion: 1,
      status: status,
      createdAt: DateTime(2026, 9, 1),
    );

ProtectedPaymentIntent intent(
        {String status = 'protected', int amount = 100}) =>
    ProtectedPaymentIntent(
      id: 'payment',
      paymentType: 'protected',
      status: status,
      amountSats: amount,
      senderId: 'alice',
      recipientIdentifier: 'bob',
      createdAt: DateTime(2026, 9, 1),
      expiresAt: DateTime(2026, 9, 2),
    );

void main() {
  test(
      'settlement arriving during intent lookup is not overwritten by inbox sync',
      () async {
    final notifier = await createMemoryTransactionsNotifier();
    addTearDown(notifier.dispose);
    final lookup = Completer<ProtectedPaymentIntent>();
    final sync = notifier.syncIncomingMessages(
        inbox: [message()], getIntentDetails: (_) => lookup.future);
    final settled = TransactionModel(
        id: 'payment',
        type: TransactionType.protectedClaim,
        status: TransactionStatus.completed,
        amountSats: 99,
        recipientOrSender: '@alice',
        createdAt: DateTime(2026, 9, 1));
    await notifier.addTransaction(settled);
    lookup.complete(intent());
    expect(await sync, isEmpty);
    expect(notifier.state.single.toJson(), settled.toJson());
  });
  test('unlinked messages do not break processing of the remaining inbox',
      () async {
    final notifier = await createMemoryTransactionsNotifier();
    addTearDown(notifier.dispose);
    final incoming = await notifier.syncIncomingMessages(
        inbox: [message(paymentId: null), message()],
        getIntentDetails: (_) async => intent());
    expect(incoming.map((tx) => tx.id), ['payment']);
    expect(notifier.state.single.amountSats, 100);
  });

  test('expired protection window does not discard a still-claimable envelope',
      () async {
    final notifier = await createMemoryTransactionsNotifier();
    addTearDown(notifier.dispose);
    await notifier.syncIncomingMessages(
        inbox: [message()],
        getIntentDetails: (_) async => intent(status: 'expired'));
    expect(notifier.state.single.type, TransactionType.protectedClaim);
    expect(notifier.state.single.status, TransactionStatus.waitingForRecipient);
  });

  test(
      'failed intent lookup leaves activity stale without inventing a zero payment',
      () async {
    final notifier = await createMemoryTransactionsNotifier();
    addTearDown(notifier.dispose);
    await notifier.reconcile(sync: () async {
      await notifier.syncIncomingMessages(
          inbox: [message()],
          getIntentDetails: (_) async => throw StateError('offline'));
    });
    expect(notifier.isStale, isTrue);
    expect(notifier.state, isEmpty);
    await notifier.reconcile(sync: () async {
      await notifier.syncIncomingMessages(
          inbox: [message()], getIntentDetails: (_) async => intent());
    });
    expect(notifier.isStale, isFalse);
    expect(notifier.state.single.amountSats, 100);
  });

  test(
      'redelivered message preserves local pending settlement and recovery data',
      () async {
    final local = TransactionModel(
        id: 'payment',
        type: TransactionType.protectedClaim,
        status: TransactionStatus.uncertain,
        amountSats: 100,
        recipientOrSender: '@alice',
        createdAt: DateTime(2026, 9, 1),
        coordinationSyncPending: true,
        syncPendingStatus: 'claimed',
        metadata: const {'receipt': 'local-mint-receipt'});
    final notifier = await createMemoryTransactionsNotifier(initial: [local]);
    addTearDown(notifier.dispose);
    await notifier.syncIncomingMessages(
        inbox: [message()], getIntentDetails: (_) async => intent());
    expect(notifier.state.single.toJson(), local.toJson());
    expect(notifier.state.single.metadata, local.metadata);
  });

  test(
      'backend intent sync preserves locally settled amounts and receipt metadata',
      () async {
    final local = TransactionModel(
        id: 'payment',
        type: TransactionType.protectedClaim,
        status: TransactionStatus.completed,
        amountSats: 99,
        recipientOrSender: '@alice',
        createdAt: DateTime(2026, 9, 1),
        feeSats: 1,
        metadata: const {'receipt': 'local-mint-receipt'});
    final notifier = await createMemoryTransactionsNotifier(initial: [local]);
    addTearDown(notifier.dispose);
    await notifier.syncPaymentIntents(
        intents: [intent(amount: 100)],
        currentUserId: 'bob',
        currentUsername: 'bob');
    expect(notifier.state.single.toJson(), local.toJson());
    expect(notifier.state.single.metadata, local.metadata);
    expect(notifier.state.single.feeSats, 1);
  });
}
