import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/features/transactions/data/secure_transaction_ledger.dart';
import 'package:hanbova_app/features/transactions/data/transaction_ledger.dart';
import 'package:hanbova_app/features/transactions/domain/transaction_model.dart';
import 'package:hanbova_app/features/transactions/presentation/transactions_provider.dart';

TransactionModel transaction({
  required String id,
  int minute = 0,
  TransactionStatus status = TransactionStatus.pending,
}) {
  return TransactionModel(
    id: id,
    type: TransactionType.protectedSend,
    status: status,
    amountSats: 2500,
    recipientOrSender: '@amina',
    description: 'Order 42',
    createdAt: DateTime.utc(2026, 8, 28, 12, minute),
    expiresAt: DateTime.utc(2026, 8, 29, 12, minute),
    claimReference: 'claim_$id',
    coordinationSyncPending: true,
    syncPendingStatus: 'delivery_pending',
  );
}

final class MemoryTransactionLedger implements TransactionLedger {
  final Map<String, List<TransactionModel>> records = {};

  @override
  Future<List<TransactionModel>> load(String walletKey) async =>
      List.of(records[walletKey] ?? const []);

  @override
  Future<void> replace(
    String walletKey,
    List<TransactionModel> transactions,
  ) async {
    records[walletKey] = List.of(transactions);
  }

  @override
  Future<void> upsert(
    String walletKey,
    TransactionModel transaction,
  ) async {
    final current = await load(walletKey);
    current.removeWhere((item) => item.id == transaction.id);
    current.add(transaction);
    current.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    records[walletKey] = current;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('transaction round-trips every recovery field', () {
    final original = transaction(id: 'tx_1');

    final decoded = TransactionModel.fromJson(original.toJson());

    expect(decoded.id, 'tx_1');
    expect(decoded.type, TransactionType.protectedSend);
    expect(decoded.status, TransactionStatus.pending);
    expect(decoded.amountSats, 2500);
    expect(decoded.recipientOrSender, '@amina');
    expect(decoded.description, 'Order 42');
    expect(decoded.createdAt, DateTime.utc(2026, 8, 28, 12));
    expect(decoded.expiresAt, DateTime.utc(2026, 8, 29, 12));
    expect(decoded.claimReference, 'claim_tx_1');
    expect(decoded.coordinationSyncPending, isTrue);
    expect(decoded.syncPendingStatus, 'delivery_pending');
  });

  test('ledger upserts IDs, keeps newest first, and caps at 500', () async {
    final ledger = SecureTransactionLedger(
      storage: const FlutterSecureStorage(),
    );
    for (var i = 0; i < 501; i++) {
      await ledger.upsert(
        'alice_wallet_cashu_test',
        transaction(id: 'tx_$i', minute: i),
      );
    }
    await ledger.upsert(
      'alice_wallet_cashu_test',
      transaction(
        id: 'tx_500',
        minute: 500,
        status: TransactionStatus.completed,
      ),
    );

    final records = await ledger.load('alice_wallet_cashu_test');

    expect(records, hasLength(500));
    expect(records.first.id, 'tx_500');
    expect(records.first.status, TransactionStatus.completed);
    expect(records.where((item) => item.id == 'tx_500'), hasLength(1));
    expect(records.any((item) => item.id == 'tx_0'), isFalse);
  });

  test('ledger isolates records by complete wallet key', () async {
    final ledger = SecureTransactionLedger(
      storage: const FlutterSecureStorage(),
    );
    await ledger.upsert('alice_wallet_cashu_test', transaction(id: 'alice'));
    await ledger.upsert('bob_wallet_cashu_test', transaction(id: 'bob'));

    expect(
      (await ledger.load('alice_wallet_cashu_test')).map((item) => item.id),
      ['alice'],
    );
    expect(
      (await ledger.load('bob_wallet_cashu_test')).map((item) => item.id),
      ['bob'],
    );
  });

  test('reconcile marks stale on sync failure without deleting activity',
      () async {
    final ledger = MemoryTransactionLedger();
    await ledger.upsert(
      'alice_wallet_cashu_test',
      transaction(id: 'persisted'),
    );
    final notifier = TransactionsNotifier(
      ledger: ledger,
      walletKey: 'alice_wallet_cashu_test',
    );
    await notifier.load();

    await notifier.reconcile(
      sync: () async => throw const SocketException('offline'),
    );

    expect(notifier.state.items.map((item) => item.id), ['persisted']);
    expect(notifier.state.isStale, isTrue);
    expect(notifier.state.isSyncing, isFalse);
    expect(notifier.state.syncMessage, isNotEmpty);
  });
}
