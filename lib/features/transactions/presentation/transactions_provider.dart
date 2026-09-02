import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../protected_send/domain/protected_payment_intent.dart';
import '../domain/transaction_model.dart';

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<TransactionModel>>((ref) {
  return TransactionsNotifier();
});

class TransactionsNotifier extends StateNotifier<List<TransactionModel>> {
  TransactionsNotifier([List<TransactionModel>? initial])
      : super(initial ?? defaultSampleActivity());

  static List<TransactionModel> defaultSampleActivity() {
    final now = DateTime.now();
    return [
      TransactionModel(
        id: 'tx_bill_elec',
        type: TransactionType.electricity,
        status: TransactionStatus.completed,
        amountSats: 3000,
        recipientOrSender: 'Kenya Power (KPLC Prepaid)',
        billerName: 'Kenya Power (KPLC Prepaid)',
        accountReference: '3718291049',
        tokenOrPin: '4819-2049-1829-4019-3918',
        fiatAmount: 1200.0,
        fiatCurrency: 'KES',
        feeSats: 25,
        receiptReference: 'REC-KPLC-99120',
        spendCountry: 'KE',
        createdAt: now.subtract(const Duration(minutes: 15)),
        description: 'Prepaid Electricity Token Purchase',
      ),
      TransactionModel(
        id: 'tx_esim_buy',
        type: TransactionType.esimPurchase,
        status: TransactionStatus.completed,
        amountSats: 6000,
        recipientOrSender: 'East Africa 5GB eSIM',
        planName: 'East Africa 5GB eSIM',
        receiptReference: '8901260000000000123',
        fiatAmount: 4.50,
        fiatCurrency: 'USD',
        spendCountry: 'KE',
        createdAt: now.subtract(const Duration(hours: 2)),
        description: 'Purchased East Africa 5GB Roaming eSIM',
      ),
      TransactionModel(
        id: 'tx_prot_pay',
        type: TransactionType.protectedPayment,
        status: TransactionStatus.waitingForRecipient,
        amountSats: 15000,
        recipientOrSender: '@kofi',
        claimReference: 'hnbv_claim_98213894',
        createdAt: now.subtract(const Duration(hours: 5)),
        expiresAt: now.add(const Duration(hours: 19)),
        description: 'Protected Payment for camera equipment',
      ),
      TransactionModel(
        id: 'tx_payout_momo',
        type: TransactionType.mobileMoneyPayout,
        status: TransactionStatus.completed,
        amountSats: 15000,
        recipientOrSender: '+254722000111',
        paymentMethod: 'M-Pesa / Mobile Money',
        fiatAmount: 2000.0,
        fiatCurrency: 'KES',
        feeSats: 250,
        spendCountry: 'KE',
        createdAt: now.subtract(const Duration(days: 1)),
        description: 'Cash payout of KES 2000 to +254722000111',
      ),
      TransactionModel(
        id: 'tx_card_pay',
        type: TransactionType.cardPayment,
        status: TransactionStatus.completed,
        amountSats: 14000,
        recipientOrSender: 'Amazon Web Services',
        paymentMethod: 'Virtual USD Card',
        fiatAmount: 9.99,
        fiatCurrency: 'USD',
        createdAt: now.subtract(const Duration(days: 1, hours: 4)),
        description: 'Online card payment for AWS cloud subscription',
      ),
      TransactionModel(
        id: 'tx_bill_airtime',
        type: TransactionType.airtime,
        status: TransactionStatus.completed,
        amountSats: 1200,
        recipientOrSender: 'Safaricom Airtime',
        billerName: 'Safaricom',
        accountReference: '+254712345678',
        fiatAmount: 500.0,
        fiatCurrency: 'KES',
        feeSats: 10,
        receiptReference: 'REC-SAF-88219',
        spendCountry: 'KE',
        createdAt: now.subtract(const Duration(days: 2)),
        description: 'Airtime top-up for +254712345678',
      ),
      TransactionModel(
        id: 'tx_bill_data',
        type: TransactionType.data,
        status: TransactionStatus.completed,
        amountSats: 2500,
        recipientOrSender: 'MTN Data Bundles',
        billerName: 'MTN',
        accountReference: '+234801234567',
        fiatAmount: 2000.0,
        fiatCurrency: 'NGN',
        spendCountry: 'NG',
        createdAt: now.subtract(const Duration(days: 3)),
        description: 'Purchased 2.5GB Monthly Bundle',
      ),
      TransactionModel(
        id: 'tx_btc_rec',
        type: TransactionType.bitcoinReceived,
        status: TransactionStatus.completed,
        amountSats: 50000,
        recipientOrSender: 'Lightning Deposit',
        createdAt: now.subtract(const Duration(days: 4)),
        description: 'Deposit received via Lightning invoice',
      ),
      TransactionModel(
        id: 'tx_btc_sent',
        type: TransactionType.bitcoinSent,
        status: TransactionStatus.completed,
        amountSats: 20000,
        recipientOrSender: 'lnbc200u1p...',
        feeSats: 5,
        createdAt: now.subtract(const Duration(days: 5)),
        description: 'Bitcoin payment via Lightning',
      ),
      TransactionModel(
        id: 'tx_prot_ref',
        type: TransactionType.protectedRefund,
        status: TransactionStatus.refunded,
        amountSats: 10000,
        recipientOrSender: '@chidi',
        createdAt: now.subtract(const Duration(days: 6)),
        description: 'Refund claimed after protection expiry',
      ),
    ];
  }

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
