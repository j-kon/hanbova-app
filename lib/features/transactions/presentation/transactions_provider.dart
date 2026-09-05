import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/wallet/wallet_context.dart';
import '../../protected/data/protected_message_service.dart';
import '../../protected_send/domain/protected_payment_intent.dart';
import '../data/secure_transaction_ledger.dart';
import '../data/transaction_ledger.dart';
import '../domain/transaction_model.dart';

final transactionLedgerProvider = Provider<TransactionLedger>((ref) {
  return SecureTransactionLedger(storage: const FlutterSecureStorage());
});

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  final context = ref.watch(activeWalletContextKeyProvider);
  final notifier = TransactionsNotifier(
    ledger: ref.watch(transactionLedgerProvider),
    walletKey: context?.storageId,
  );
  notifier.load();
  return notifier;
});

@immutable
final class TransactionsState extends ListBase<TransactionModel> {
  final List<TransactionModel> items;
  final bool isSyncing;
  final bool isStale;
  final String? syncMessage;

  TransactionsState({
    List<TransactionModel> items = const [],
    this.isSyncing = false,
    this.isStale = false,
    this.syncMessage,
  }) : items = List.unmodifiable(items);

  static const Object _sentinel = Object();

  TransactionsState copyWith({
    List<TransactionModel>? items,
    bool? isSyncing,
    bool? isStale,
    Object? syncMessage = _sentinel,
  }) {
    return TransactionsState(
      items: items ?? this.items,
      isSyncing: isSyncing ?? this.isSyncing,
      isStale: isStale ?? this.isStale,
      syncMessage: identical(syncMessage, _sentinel)
          ? this.syncMessage
          : syncMessage as String?,
    );
  }

  @override
  int get length => items.length;

  @override
  set length(int value) =>
      throw UnsupportedError('TransactionsState is immutable.');

  @override
  TransactionModel operator [](int index) => items[index];

  @override
  void operator []=(int index, TransactionModel value) =>
      throw UnsupportedError('TransactionsState is immutable.');
}

class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final TransactionLedger ledger;
  final String? walletKey;

  TransactionsNotifier({
    required this.ledger,
    required this.walletKey,
  }) : super(TransactionsState());

  bool get isStale => state.isStale;

  String _requireWalletKey() {
    final key = walletKey;
    if (key == null || key.isEmpty) {
      throw StateError('An authenticated wallet context is required.');
    }
    return key;
  }

  Future<void> load() async {
    final key = walletKey;
    if (key == null || key.isEmpty) {
      state = TransactionsState();
      return;
    }
    try {
      final items = await ledger.load(key);
      if (!mounted) return;
      state = TransactionsState(items: items);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isSyncing: false,
        isStale: true,
        syncMessage: 'Activity could not be refreshed.',
      );
    }
  }

  Future<void> addTransaction(TransactionModel tx) async {
    final key = _requireWalletKey();
    await ledger.upsert(key, tx);
    if (!mounted) return;
    final items = await ledger.load(key);
    if (!mounted) return;
    state = state.copyWith(items: items);
  }

  Future<void> seedDemoTransactions() async {
    if (!kDebugMode) return;
    final key = _requireWalletKey();
    final now = DateTime.now();
    final items = [
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
    await ledger.replace(key, items);
    if (!mounted) return;
    state = state.copyWith(items: items);
  }

  Future<void> updateTransactionStatus(
    String id,
    TransactionStatus newStatus,
  ) async {
    final existing = state.items.where((item) => item.id == id).firstOrNull;
    if (existing == null) return;
    await addTransaction(existing.copyWith(status: newStatus));
  }

  Future<void> updateTransaction(TransactionModel updatedTx) =>
      addTransaction(updatedTx);

  Future<void> markCoordinationSyncPending(
    String id,
    String pendingStatus,
  ) async {
    final existing = state.items.where((item) => item.id == id).firstOrNull;
    if (existing == null) return;
    await addTransaction(
      existing.copyWith(
        coordinationSyncPending: true,
        syncPendingStatus: pendingStatus,
      ),
    );
  }

  Future<void> clearCoordinationSyncPending(String id) async {
    final existing = state.items.where((item) => item.id == id).firstOrNull;
    if (existing == null) return;
    await addTransaction(
      existing.copyWith(
        coordinationSyncPending: false,
        clearSyncPendingStatus: true,
      ),
    );
  }

  Future<void> reconcile({required Future<void> Function() sync}) async {
    state = state.copyWith(isSyncing: true, syncMessage: null);
    try {
      await sync();
      if (!mounted) return;
      state = state.copyWith(
        isSyncing: false,
        isStale: false,
        syncMessage: null,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isSyncing: false,
        isStale: true,
        syncMessage: 'Showing saved activity while your wallet is offline.',
      );
    }
  }

  Future<void> recordBillPayment({
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
    return addTransaction(tx);
  }

  Future<void> recordEsimPurchase({
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
    return addTransaction(tx);
  }

  Future<void> recordPayout({
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
    return addTransaction(tx);
  }

  Future<List<TransactionModel>> syncIncomingMessages({
    required List<RemoteProtectedMessage> inbox,
    Future<ProtectedPaymentIntent?> Function(String intentId)? getIntentDetails,
  }) async {
    final List<TransactionModel> newIncoming = [];
    for (final msg in inbox) {
      if (!mounted) return newIncoming;
      final paymentIntentId = msg.paymentIntentId;
      // Unlinked envelopes are supported by the relay, but cannot create a
      // financial ledger entry until they have a payment intent.
      if (paymentIntentId == null || paymentIntentId.isEmpty) continue;
      final senderUsername = msg.senderUsername;
      final createdAt = msg.createdAt;
      final status = msg.status.toLowerCase();

      if (status == 'claimed') {
        final idx = state.items.indexWhere((t) => t.id == paymentIntentId);
        if (idx >= 0 &&
            (state.items[idx].status == TransactionStatus.waitingForRecipient ||
                state.items[idx].status == TransactionStatus.claimable)) {
          await updateTransactionStatus(
            paymentIntentId,
            TransactionStatus.completed,
          );
        }
        continue;
      }
      if (status == 'refunded') {
        final idx = state.items.indexWhere((t) => t.id == paymentIntentId);
        if (idx >= 0 &&
            (state.items[idx].status == TransactionStatus.waitingForRecipient ||
                state.items[idx].status == TransactionStatus.claimable)) {
          await updateTransactionStatus(
            paymentIntentId,
            TransactionStatus.refunded,
          );
        }
        continue;
      }

      final existingIndex =
          state.items.indexWhere((t) => t.id == paymentIntentId);
      if (existingIndex >= 0) {
        // Re-delivery must not reset local settlement/recovery progress.
        continue;
      }

      final intent = await getIntentDetails?.call(paymentIntentId);
      if (!mounted) return newIncoming;
      // A local settlement may have arrived while the lookup was in flight.
      // Never replace that record with this older inbox snapshot.
      if (state.items.any((item) => item.id == paymentIntentId)) continue;
      if (intent == null ||
          intent.id != paymentIntentId ||
          intent.paymentType != 'protected' ||
          intent.amountSats <= 0) {
        throw StateError('Protected payment details are unavailable.');
      }
      final intentStatus = intent.status.toLowerCase();
      if (intentStatus == 'claimed' || intentStatus == 'refunded') continue;
      // Locktime enables the refund path; it does not revoke recipient claims.

      final incomingTx = TransactionModel(
        id: paymentIntentId,
        type: TransactionType.protectedClaim,
        status: TransactionStatus.waitingForRecipient,
        amountSats: intent.amountSats,
        recipientOrSender: '@$senderUsername',
        description: intent.description ?? 'Incoming Protected Payment',
        createdAt: createdAt,
        expiresAt: intent.expiresAt,
        claimReference: intent.claimReference ?? paymentIntentId,
      );

      await updateTransaction(incomingTx);
      if (existingIndex < 0) newIncoming.add(incomingTx);
    }
    return newIncoming;
  }

  Future<void> syncPaymentIntents({
    required List<ProtectedPaymentIntent> intents,
    required String currentUserId,
    required String currentUsername,
  }) async {
    final cleanCurrentUsername =
        currentUsername.replaceAll('@', '').toLowerCase();
    final cleanCurrentUserId = currentUserId.toLowerCase();
    final updatedList = List<TransactionModel>.from(state.items);

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
        if (local.status == TransactionStatus.claimed ||
            local.status == TransactionStatus.completed ||
            local.status == TransactionStatus.refunded) {
          // Preserve mint-settled net amounts, fees and local receipt data.
          continue;
        }
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
    final key = _requireWalletKey();
    await ledger.replace(key, updatedList);
    if (!mounted) return;
    state = state.copyWith(items: updatedList);
  }
}
