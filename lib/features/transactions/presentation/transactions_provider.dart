import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/transaction_model.dart';

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<TransactionModel>>((ref) {
  return TransactionsNotifier();
});

class TransactionsNotifier extends StateNotifier<List<TransactionModel>> {
  TransactionsNotifier()
      : super([
          TransactionModel(
            id: 'tx_demo_1',
            type: TransactionType.protectedSend,
            status: TransactionStatus.claimable,
            amountSats: 25000,
            recipientOrSender: 'amina@hanbova.africa',
            description: 'Design mockups milestone',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            expiresAt: DateTime.now().add(const Duration(hours: 22)),
            claimReference: 'hnbv_claim_9281a',
          ),
          TransactionModel(
            id: 'tx_demo_2',
            type: TransactionType.instantReceive,
            status: TransactionStatus.completed,
            amountSats: 50000,
            recipientOrSender: 'kofi@hanbova.me',
            description: 'Settlement for equipment',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ]);

  void addTransaction(TransactionModel tx) {
    state = [tx, ...state];
  }

  void updateTransactionStatus(String id, TransactionStatus newStatus) {
    state = state.map((tx) {
      if (tx.id == id) {
        return TransactionModel(
          id: tx.id,
          type: tx.type,
          status: newStatus,
          amountSats: tx.amountSats,
          recipientOrSender: tx.recipientOrSender,
          description: tx.description,
          createdAt: tx.createdAt,
          expiresAt: tx.expiresAt,
          claimReference: tx.claimReference,
        );
      }
      return tx;
    }).toList();
  }
}
