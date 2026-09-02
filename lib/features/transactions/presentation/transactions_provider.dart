import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../protected_send/domain/protected_payment_intent.dart';
import '../domain/transaction_model.dart';

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<TransactionModel>>((ref) {
  return TransactionsNotifier();
});

class TransactionsNotifier extends StateNotifier<List<TransactionModel>> {
  TransactionsNotifier() : super(const []);

  void addTransaction(TransactionModel tx) {
    final idx = state.indexWhere((t) => t.id == tx.id);
    if (idx >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == idx) tx else state[i],
      ];
    } else {
      state = [tx, ...state];
    }
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
          clearSyncPendingStatus: true,
        );
      }
      return tx;
    }).toList();
  }

  void recordBillPayment({
    required String id,
    required TransactionType type,
    required String billerName,
    required String accountReference,
    required int amountSats,
    required double fiatAmount,
    required String fiatCurrency,
    required int feeSats,
    String? tokenOrPin,
    String? receiptReference,
    String? spendCountry,
    TransactionStatus status = TransactionStatus.completed,
  }) {
    final tx = TransactionModel(
      id: id,
      type: type,
      status: status,
      amountSats: amountSats,
      recipientOrSender: billerName,
      billerName: billerName,
      accountReference: accountReference,
      fiatAmount: fiatAmount,
      fiatCurrency: fiatCurrency,
      feeSats: feeSats,
      tokenOrPin: tokenOrPin,
      receiptReference: receiptReference,
      spendCountry: spendCountry,
      paymentMethod: 'Bitcoin Balance',
      createdAt: DateTime.now(),
      description:
          'Paid $fiatCurrency $fiatAmount to $billerName ($accountReference)',
    );
    addTransaction(tx);
  }

  void recordEsimPurchase({
    required String id,
    required String planName,
    required int amountSats,
    required double fiatAmount,
    required String fiatCurrency,
    String? iccid,
    String? qrCode,
    String? spendCountry,
    bool isTopup = false,
  }) {
    final tx = TransactionModel(
      id: id,
      type: isTopup ? TransactionType.esimTopup : TransactionType.esimPurchase,
      status: TransactionStatus.completed,
      amountSats: amountSats,
      recipientOrSender: 'Hanbova Roaming eSIM',
      planName: planName,
      fiatAmount: fiatAmount,
      fiatCurrency: fiatCurrency,
      spendCountry: spendCountry,
      receiptReference: iccid,
      paymentMethod: 'Bitcoin Balance',
      createdAt: DateTime.now(),
      description:
          isTopup ? 'Top-up for $planName' : 'Purchased $planName plan',
      metadata: {
        if (iccid != null) 'iccid': iccid,
        if (qrCode != null) 'qr_code': qrCode,
      },
    );
    addTransaction(tx);
  }

  void recordPayout({
    required String id,
    required String destination,
    required String corridorName,
    required int amountSats,
    required double fiatAmount,
    required String fiatCurrency,
    required int feeSats,
    bool isMobileMoney = true,
  }) {
    final tx = TransactionModel(
      id: id,
      type: isMobileMoney
          ? TransactionType.mobileMoneyPayout
          : TransactionType.bankPayout,
      status: TransactionStatus.completed,
      amountSats: amountSats,
      recipientOrSender: destination,
      fiatAmount: fiatAmount,
      fiatCurrency: fiatCurrency,
      feeSats: feeSats,
      paymentMethod: isMobileMoney ? 'M-Pesa / Mobile Money' : 'Bank Transfer',
      createdAt: DateTime.now(),
      description: 'Cash payout of $fiatCurrency $fiatAmount to $destination',
    );
    addTransaction(tx);
  }

  Future<List<TransactionModel>> syncIncomingMessages({
    required List<dynamic> inbox,
    Future<dynamic> Function(String intentId)? getIntentDetails,
  }) async {
    final List<TransactionModel> newIncoming = [];
    for (final rawMsg in inbox) {
      final msg = rawMsg as dynamic;
      final paymentIntentId = msg.paymentIntentId as String;
      final senderUsername = msg.senderUsername as String;
      final createdAt = msg.createdAt as DateTime;
      final status = (msg.status as String?)?.toLowerCase() ?? '';

      if (status == 'claimed') {
        final idx = state.indexWhere((t) => t.id == paymentIntentId);
        if (idx >= 0 &&
            (state[idx].status == TransactionStatus.waitingForRecipient ||
                state[idx].status == TransactionStatus.claimable)) {
          updateTransactionStatus(paymentIntentId, TransactionStatus.completed);
        }
        continue;
      }
      if (status == 'refunded') {
        final idx = state.indexWhere((t) => t.id == paymentIntentId);
        if (idx >= 0 &&
            (state[idx].status == TransactionStatus.waitingForRecipient ||
                state[idx].status == TransactionStatus.claimable)) {
          updateTransactionStatus(paymentIntentId, TransactionStatus.refunded);
        }
        continue;
      }

      final existingIndex = state.indexWhere((t) => t.id == paymentIntentId);
      if (existingIndex >= 0) {
        final existing = state[existingIndex];
        if (existing.status == TransactionStatus.claimed ||
            existing.status == TransactionStatus.completed ||
            existing.status == TransactionStatus.refunded) {
          continue;
        }
      }

      int amountSats = 0;
      DateTime expiresAt = createdAt.add(const Duration(hours: 24));
      String? description;
      String claimRef = paymentIntentId;

      if (getIntentDetails != null) {
        try {
          final dynamic intent = await getIntentDetails(paymentIntentId);
          if (intent != null) {
            final intentStatus = (intent.status as String).toLowerCase();
            if (intentStatus == 'claimed' ||
                intentStatus == 'refunded' ||
                intentStatus == 'expired') {
              continue;
            }
            amountSats = intent.amountSats as int;
            expiresAt = intent.expiresAt as DateTime;
            description = intent.description as String?;
            claimRef = (intent.claimReference as String?) ?? paymentIntentId;
          }
        } catch (_) {}
      }

      final incomingTx = TransactionModel(
        id: paymentIntentId,
        type: TransactionType.protectedClaim,
        status: TransactionStatus.waitingForRecipient,
        amountSats: amountSats,
        recipientOrSender: '@$senderUsername',
        description: description ?? 'Incoming Protected Payment',
        createdAt: createdAt,
        expiresAt: expiresAt,
        claimReference: claimRef,
      );

      if (existingIndex >= 0) {
        updateTransaction(incomingTx);
      } else {
        addTransaction(incomingTx);
        newIncoming.add(incomingTx);
      }
    }
    return newIncoming;
  }

  void syncPaymentIntents({
    required List<ProtectedPaymentIntent> intents,
    required String currentUserId,
    required String currentUsername,
  }) {
    final cleanCurrentUsername =
        currentUsername.replaceAll('@', '').toLowerCase();
    final cleanCurrentUserId = currentUserId.toLowerCase();

    final List<TransactionModel> updatedList = List.from(state);

    for (final intent in intents) {
      final senderId = intent.senderId?.toLowerCase() ?? '';
      final cleanSender = senderId.replaceAll('@', '');

      final isSender = cleanSender == cleanCurrentUsername ||
          cleanSender == cleanCurrentUserId ||
          senderId == cleanCurrentUserId;

      final TransactionType txType;
      final String counterparty;

      if (isSender) {
        txType = TransactionType.protectedPayment;
        counterparty = intent.recipientIdentifier.startsWith('@')
            ? intent.recipientIdentifier
            : '@${intent.recipientIdentifier}';
      } else {
        txType = TransactionType.protectedClaim;
        counterparty = intent.senderId != null && intent.senderId!.isNotEmpty
            ? (intent.senderId!.startsWith('@')
                ? intent.senderId!
                : '@${intent.senderId}')
            : 'Sender';
      }

      final isExpired =
          intent.expiresAt != null && DateTime.now().isAfter(intent.expiresAt!);
      final TransactionStatus txStatus;
      switch (intent.status.toLowerCase()) {
        case 'claimed':
          txStatus = TransactionStatus.claimed;
          break;
        case 'refunded':
          txStatus = TransactionStatus.refunded;
          break;
        case 'expired':
          txStatus = TransactionStatus.refundAvailable;
          break;
        case 'claimable':
        case 'protected':
        default:
          txStatus = isExpired
              ? TransactionStatus.refundAvailable
              : TransactionStatus.waitingForRecipient;
          break;
      }

      final model = TransactionModel(
        id: intent.id,
        type: txType,
        status: txStatus,
        amountSats: intent.amountSats,
        recipientOrSender: counterparty,
        description: intent.description ??
            (isSender
                ? 'Protected Payment to $counterparty'
                : 'Incoming Protected Payment'),
        createdAt: intent.createdAt,
        expiresAt: intent.expiresAt,
        claimReference: intent.claimReference ?? intent.id,
      );

      final idx = updatedList.indexWhere((t) => t.id == intent.id);
      if (idx >= 0) {
        final local = updatedList[idx];
        final finalStatus = (local.status == TransactionStatus.claimed ||
                local.status == TransactionStatus.completed ||
                local.status == TransactionStatus.refunded)
            ? local.status
            : txStatus;
        updatedList[idx] = model.copyWith(
          status: finalStatus,
          coordinationSyncPending: local.coordinationSyncPending,
          syncPendingStatus: local.syncPendingStatus,
        );
      } else {
        updatedList.add(model);
      }
    }

    updatedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = updatedList;
  }
}
