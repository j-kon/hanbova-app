import '../domain/transaction_model.dart';

abstract interface class TransactionLedger {
  Future<List<TransactionModel>> load(String walletKey);

  Future<void> upsert(
    String walletKey,
    TransactionModel transaction,
  );

  Future<void> replace(
    String walletKey,
    List<TransactionModel> transactions,
  );
}
