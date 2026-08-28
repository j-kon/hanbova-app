import 'package:hanbova_app/features/transactions/data/transaction_ledger.dart';
import 'package:hanbova_app/features/transactions/domain/transaction_model.dart';
import 'package:hanbova_app/features/transactions/presentation/transactions_provider.dart';

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

Future<TransactionsNotifier> createMemoryTransactionsNotifier({
  String walletKey = 'test_wallet_cashu_test',
  List<TransactionModel> initial = const [],
}) async {
  final ledger = MemoryTransactionLedger();
  await ledger.replace(walletKey, initial);
  final notifier = TransactionsNotifier(
    ledger: ledger,
    walletKey: walletKey,
  );
  await notifier.load();
  return notifier;
}
