import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/transaction_model.dart';

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<TransactionModel>>((ref) {
  return TransactionsNotifier();
});

class TransactionsNotifier extends StateNotifier<List<TransactionModel>> {
  TransactionsNotifier() : super(const []);

  void addTransaction(TransactionModel tx) {
    state = [tx, ...state];
  }

  void seedDemoTransactions() {
    if (!kDebugMode) return;
    final now = DateTime.now();
    state = [
      TransactionModel(
        id: 'tx_demo_1',
        type: TransactionType.protectedSend,
        status: TransactionStatus.claimable,
        amountSats: 25000,
        recipientOrSender: 'amina@hanbova.africa',
        description: 'Design mockups milestone (Escrow)',
        createdAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.add(const Duration(hours: 22)),
        claimReference: 'hnbv_claim_9281a',
      ),
      TransactionModel(
        id: 'tx_demo_2',
        type: TransactionType.instantReceive,
        status: TransactionStatus.completed,
        amountSats: 50000,
        recipientOrSender: 'kofi@hanbova.me',
        description: 'Instant settlement for solar equipment',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      TransactionModel(
        id: 'tx_demo_3',
        type: TransactionType.protectedClaim,
        status: TransactionStatus.completed,
        amountSats: 15000,
        recipientOrSender: 'tarik@hanbova.africa',
        description: 'Agricultural produce delivery claim',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      TransactionModel(
        id: 'tx_demo_4',
        type: TransactionType.instantSend,
        status: TransactionStatus.completed,
        amountSats: 8500,
        recipientOrSender: 'zara@hanbova.me',
        description: 'Mobile data topup via Lightning',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      TransactionModel(
        id: 'tx_demo_5',
        type: TransactionType.protectedRefund,
        status: TransactionStatus.refunded,
        amountSats: 30000,
        recipientOrSender: 'seller_dispute@market.ng',
        description: 'Refund after unfulfilled delivery window',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  void updateTransactionStatus(String id, TransactionStatus newStatus) {
    state = state.map((tx) {
      if (tx.id == id) {
        return tx.copyWith(status: newStatus);
      }
      return tx;
    }).toList();
  }

  void updateTransaction(TransactionModel updatedTx) {
    state = state.map((tx) => tx.id == updatedTx.id ? updatedTx : tx).toList();
  }

  void markCoordinationSyncPending(String id, String pendingStatus) {
    state = state.map((tx) {
      if (tx.id == id) {
        return tx.copyWith(
          coordinationSyncPending: true,
          syncPendingStatus: pendingStatus,
        );
      }
      return tx;
    }).toList();
  }

  void clearCoordinationSyncPending(String id) {
    state = state.map((tx) {
      if (tx.id == id) {
        return tx.copyWith(
          coordinationSyncPending: false,
          syncPendingStatus: null,
        );
      }
      return tx;
    }).toList();
  }
}
