import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanbova_app/features/transactions/domain/transaction_model.dart';

/// Beneficiary model for People / Beneficiaries management
class BeneficiaryItem {
  final String id;
  final String name;
  final String handleOrAccount;
  final String type; // 'bitcoin', 'lightning', 'bank', 'mobile_money'
  final String? bankOrOperator;
  final String countryCode;
  final DateTime lastUsedAt;

  const BeneficiaryItem({
    required this.id,
    required this.name,
    required this.handleOrAccount,
    required this.type,
    this.bankOrOperator,
    required this.countryCode,
    required this.lastUsedAt,
  });
}

/// Notification item model
class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final String
      category; // 'transaction', 'protected', 'bill', 'esim', 'security', 'travel'
  final DateTime createdAt;
  final bool isRead;
  final String? amountFormatted;
  final String? actionRoute;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    this.isRead = false,
    this.amountFormatted,
    this.actionRoute,
  });

  AppNotificationItem copyWith({bool? isRead}) {
    return AppNotificationItem(
      id: id,
      title: title,
      body: body,
      category: category,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      amountFormatted: amountFormatted,
      actionRoute: actionRoute,
    );
  }
}

/// Monthly statement model
class MonthlyStatement {
  final String id;
  final String monthLabel; // e.g. "August 2026"
  final DateTime startDate;
  final DateTime endDate;
  final int openingBalanceSats;
  final int moneyInSats;
  final int moneyOutSats;
  final int feesSats;
  final int closingBalanceSats;
  final int transactionCount;

  const MonthlyStatement({
    required this.id,
    required this.monthLabel,
    required this.startDate,
    required this.endDate,
    required this.openingBalanceSats,
    required this.moneyInSats,
    required this.moneyOutSats,
    required this.feesSats,
    required this.closingBalanceSats,
    required this.transactionCount,
  });
}

/// Virtual Card model (Sandbox/Demo)
class VirtualCardModel {
  final String id;
  final String cardholderName;
  final String cardNumber; // e.g. "4111 2233 4455 9821"
  final String expiry; // "08/28"
  final String cvv; // "419"
  final String cardType; // "Visa Virtual"
  final double balanceUsd;
  final bool isFrozen;
  final String status;

  const VirtualCardModel({
    required this.id,
    required this.cardholderName,
    required this.cardNumber,
    required this.expiry,
    required this.cvv,
    required this.cardType,
    required this.balanceUsd,
    required this.isFrozen,
    required this.status,
  });

  VirtualCardModel copyWith({
    bool? isFrozen,
    double? balanceUsd,
  }) {
    return VirtualCardModel(
      id: id,
      cardholderName: cardholderName,
      cardNumber: cardNumber,
      expiry: expiry,
      cvv: cvv,
      cardType: cardType,
      balanceUsd: balanceUsd ?? this.balanceUsd,
      isFrozen: isFrozen ?? this.isFrozen,
      status: status,
    );
  }
}

/// Isolated Demo State Holder
class DemoModeState {
  final bool isEnabled;
  final int totalBalanceSats;
  final int availableBalanceSats;
  final int protectedWaitingSats;
  final int protectedRefundableSats;
  final int pendingBalanceSats;

  final List<TransactionModel> demoTransactions;
  final List<BeneficiaryItem> demoBeneficiaries;
  final List<AppNotificationItem> demoNotifications;
  final List<MonthlyStatement> demoStatements;
  final VirtualCardModel? demoCard;

  const DemoModeState({
    this.isEnabled = false,
    this.totalBalanceSats = 2450000,
    this.availableBalanceSats = 1800000,
    this.protectedWaitingSats = 300000,
    this.protectedRefundableSats = 150000,
    this.pendingBalanceSats = 200000,
    this.demoTransactions = const [],
    this.demoBeneficiaries = const [],
    this.demoNotifications = const [],
    this.demoStatements = const [],
    this.demoCard,
  });

  int get protectedTotalSats => protectedWaitingSats + protectedRefundableSats;

  DemoModeState copyWith({
    bool? isEnabled,
    List<TransactionModel>? demoTransactions,
    List<BeneficiaryItem>? demoBeneficiaries,
    List<AppNotificationItem>? demoNotifications,
    VirtualCardModel? demoCard,
  }) {
    return DemoModeState(
      isEnabled: isEnabled ?? this.isEnabled,
      totalBalanceSats: totalBalanceSats,
      availableBalanceSats: availableBalanceSats,
      protectedWaitingSats: protectedWaitingSats,
      protectedRefundableSats: protectedRefundableSats,
      pendingBalanceSats: pendingBalanceSats,
      demoTransactions: demoTransactions ?? this.demoTransactions,
      demoBeneficiaries: demoBeneficiaries ?? this.demoBeneficiaries,
      demoNotifications: demoNotifications ?? this.demoNotifications,
      demoStatements: demoStatements,
      demoCard: demoCard ?? this.demoCard,
    );
  }
}

final demoModeProvider =
    StateNotifierProvider<DemoModeNotifier, DemoModeState>((ref) {
  return DemoModeNotifier();
});

class DemoModeNotifier extends StateNotifier<DemoModeState> {
  DemoModeNotifier() : super(_buildInitialDemoState());

  static DemoModeState _buildInitialDemoState() {
    final now = DateTime.now();

    final txs = [
      TransactionModel(
        id: 'demo-tx-1',
        type: TransactionType.bitcoinReceived,
        status: TransactionStatus.completed,
        amountSats: 250000,
        createdAt: now.subtract(const Duration(hours: 2)),
        recipientOrSender: 'bc1qj4...998x (Nodeless Deposit)',
        feeSats: 150,
      ),
      TransactionModel(
        id: 'demo-tx-2',
        type: TransactionType.electricity,
        status: TransactionStatus.completed,
        amountSats: 12800,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        recipientOrSender: 'KPLC Electricity Tokens (#14123456789)',
        feeSats: 50,
      ),
      TransactionModel(
        id: 'demo-tx-3',
        type: TransactionType.protectedSend,
        status: TransactionStatus.waitingForRecipient,
        amountSats: 300000,
        createdAt: now.subtract(const Duration(days: 1, hours: 8)),
        recipientOrSender: 'Protected Escrow -> Amara Obi',
        feeSats: 200,
      ),
      TransactionModel(
        id: 'demo-tx-4',
        type: TransactionType.esimPurchase,
        status: TransactionStatus.completed,
        amountSats: 12000,
        createdAt: now.subtract(const Duration(days: 3)),
        recipientOrSender: 'Kenya Traveler 3 GB eSIM',
        feeSats: 50,
      ),
      TransactionModel(
        id: 'demo-tx-5',
        type: TransactionType.data,
        status: TransactionStatus.completed,
        amountSats: 8500,
        createdAt: now.subtract(const Duration(days: 5)),
        recipientOrSender: 'MTN Data Bundles 10 GB (#08031234567)',
        feeSats: 50,
      ),
      TransactionModel(
        id: 'demo-tx-6',
        type: TransactionType.cardFunding,
        status: TransactionStatus.completed,
        amountSats: 45000,
        createdAt: now.subtract(const Duration(days: 7)),
        recipientOrSender: 'Virtual Visa Funding (\$30.00)',
        feeSats: 100,
      ),
      TransactionModel(
        id: 'demo-tx-7',
        type: TransactionType.internet,
        status: TransactionStatus.uncertain,
        amountSats: 15000,
        createdAt: now.subtract(const Duration(days: 8)),
        recipientOrSender: 'Spectranet LTE Internet (#SPEC-55443)',
        feeSats: 50,
      ),
      TransactionModel(
        id: 'demo-tx-8',
        type: TransactionType.protectedRefund,
        status: TransactionStatus.completed,
        amountSats: 150000,
        createdAt: now.subtract(const Duration(days: 12)),
        recipientOrSender: 'Protected Refund Claimed (Expired Locktime)',
        feeSats: 100,
      ),
    ];

    final beneficiaries = [
      BeneficiaryItem(
        id: 'ben-1',
        name: 'Amara Obi',
        handleOrAccount: 'amara@getalby.com',
        type: 'lightning',
        bankOrOperator: 'Alby Lightning',
        countryCode: 'NG',
        lastUsedAt: now.subtract(const Duration(days: 1)),
      ),
      BeneficiaryItem(
        id: 'ben-2',
        name: 'Kofi Mensah',
        handleOrAccount: '+233 24 123 4567',
        type: 'mobile_money',
        bankOrOperator: 'MTN Mobile Money',
        countryCode: 'GH',
        lastUsedAt: now.subtract(const Duration(days: 4)),
      ),
      BeneficiaryItem(
        id: 'ben-3',
        name: 'Wanjiku Mwangi',
        handleOrAccount: '+254 712 345 678',
        type: 'mobile_money',
        bankOrOperator: 'Safaricom M-Pesa',
        countryCode: 'KE',
        lastUsedAt: now.subtract(const Duration(days: 6)),
      ),
      BeneficiaryItem(
        id: 'ben-4',
        name: 'Chinedu Eze',
        handleOrAccount: '0123456789 (Access Bank)',
        type: 'bank',
        bankOrOperator: 'Access Bank Nigeria',
        countryCode: 'NG',
        lastUsedAt: now.subtract(const Duration(days: 10)),
      ),
    ];

    final notifications = [
      AppNotificationItem(
        id: 'notif-1',
        title: 'Bitcoin Received',
        body: 'You received 250,000 sats from Lightning node.',
        category: 'transaction',
        createdAt: now.subtract(const Duration(hours: 2)),
        amountFormatted: '+250,000 sats',
        actionRoute: '/activity',
      ),
      AppNotificationItem(
        id: 'notif-2',
        title: 'Protected Refund Ready',
        body:
            'Locktime expired for 150,000 sats. You can now claim your refund.',
        category: 'protected',
        createdAt: now.subtract(const Duration(days: 1)),
        amountFormatted: '150,000 sats',
        actionRoute: '/pending',
      ),
      AppNotificationItem(
        id: 'notif-3',
        title: 'Electricity Token Generated',
        body: 'Token 4819-2049-1829-4019-3918 for Meter #14123456789.',
        category: 'bill',
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        actionRoute: '/activity',
      ),
      AppNotificationItem(
        id: 'notif-4',
        title: 'eSIM Low Data Alert',
        body: 'Your Kenya 3 GB eSIM has 580 MB remaining. Tap to top up.',
        category: 'esim',
        createdAt: now.subtract(const Duration(days: 2)),
        actionRoute: '/travel',
      ),
      AppNotificationItem(
        id: 'notif-5',
        title: 'Travel Mode Activated',
        body: 'Welcome to Kenya! Spend Market switched to Kenya (KSh).',
        category: 'travel',
        createdAt: now.subtract(const Duration(days: 3)),
        actionRoute: '/travel',
      ),
    ];

    final statements = [
      MonthlyStatement(
        id: 'stmt-2026-08',
        monthLabel: 'August 2026',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 31),
        openingBalanceSats: 1800000,
        moneyInSats: 950000,
        moneyOutSats: 300000,
        feesSats: 1200,
        closingBalanceSats: 2448800,
        transactionCount: 14,
      ),
      MonthlyStatement(
        id: 'stmt-2026-07',
        monthLabel: 'July 2026',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
        openingBalanceSats: 1200000,
        moneyInSats: 800000,
        moneyOutSats: 200000,
        feesSats: 950,
        closingBalanceSats: 1799050,
        transactionCount: 11,
      ),
      MonthlyStatement(
        id: 'stmt-2026-06',
        monthLabel: 'June 2026',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 30),
        openingBalanceSats: 600000,
        moneyInSats: 750000,
        moneyOutSats: 150000,
        feesSats: 800,
        closingBalanceSats: 1199200,
        transactionCount: 9,
      ),
    ];

    const card = VirtualCardModel(
      id: 'card-demo-1',
      cardholderName: 'HANBOVA TRAVELER',
      cardNumber: '4111 2233 4455 9821',
      expiry: '08/28',
      cvv: '419',
      cardType: 'Virtual Visa',
      balanceUsd: 145.50,
      isFrozen: false,
      status: 'active',
    );

    return DemoModeState(
      isEnabled: true, // Enabled by default for public product demos
      totalBalanceSats: 2450000,
      availableBalanceSats: 1800000,
      protectedWaitingSats: 300000,
      protectedRefundableSats: 150000,
      pendingBalanceSats: 200000,
      demoTransactions: txs,
      demoBeneficiaries: beneficiaries,
      demoNotifications: notifications,
      demoStatements: statements,
      demoCard: card,
    );
  }

  void toggleDemoMode() {
    state = state.copyWith(isEnabled: !state.isEnabled);
  }

  void toggleCardFreeze() {
    if (state.demoCard != null) {
      final updated = state.demoCard!.copyWith(
        isFrozen: !state.demoCard!.isFrozen,
      );
      state = state.copyWith(demoCard: updated);
    }
  }

  void fundCard(double usdAmount) {
    if (state.demoCard != null) {
      final updated = state.demoCard!.copyWith(
        balanceUsd: state.demoCard!.balanceUsd + usdAmount,
      );
      state = state.copyWith(demoCard: updated);
    }
  }

  void addBeneficiary(BeneficiaryItem item) {
    state = state.copyWith(
      demoBeneficiaries: [item, ...state.demoBeneficiaries],
    );
  }

  void removeBeneficiary(String id) {
    state = state.copyWith(
      demoBeneficiaries:
          state.demoBeneficiaries.where((b) => b.id != id).toList(),
    );
  }

  void markNotificationRead(String id) {
    state = state.copyWith(
      demoNotifications: state.demoNotifications
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList(),
    );
  }

  void markAllNotificationsRead() {
    state = state.copyWith(
      demoNotifications:
          state.demoNotifications.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }
}
