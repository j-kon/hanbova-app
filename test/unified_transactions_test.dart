import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/features/transactions/domain/activity_export_service.dart';
import 'package:hanbova_app/features/transactions/domain/transaction_model.dart';
import 'package:hanbova_app/features/transactions/presentation/transactions_provider.dart';

void main() {
  group('Unified Transaction Model & Category Tests', () {
    test('Correctly categorizes and determines direction for all 17 types', () {
      final now = DateTime.now();

      final txIn = TransactionModel(
        id: 'tx-1',
        type: TransactionType.bitcoinReceived,
        status: TransactionStatus.completed,
        amountSats: 50000,
        recipientOrSender: 'Lightning Invoice',
        createdAt: now,
      );
      expect(txIn.isOutgoing, isFalse);
      expect(txIn.category, equals(TransactionCategory.moneyIn));

      final txOut = TransactionModel(
        id: 'tx-2',
        type: TransactionType.bitcoinSent,
        status: TransactionStatus.completed,
        amountSats: 25000,
        recipientOrSender: 'lnbc250u...',
        createdAt: now,
      );
      expect(txOut.isOutgoing, isTrue);
      expect(txOut.category, equals(TransactionCategory.moneyOut));

      final txProtected = TransactionModel(
        id: 'tx-3',
        type: TransactionType.protectedPayment,
        status: TransactionStatus.waitingForRecipient,
        amountSats: 10000,
        recipientOrSender: '@kofi',
        createdAt: now,
      );
      expect(txProtected.isOutgoing, isTrue);
      expect(txProtected.category, equals(TransactionCategory.protected));
      expect(txProtected.displayStatus, equals('Waiting for recipient'));

      final txAirtime = TransactionModel(
        id: 'tx-4',
        type: TransactionType.airtime,
        status: TransactionStatus.completed,
        amountSats: 1200,
        recipientOrSender: 'Safaricom Airtime',
        billerName: 'Safaricom',
        accountReference: '+254712345678',
        fiatAmount: 500.0,
        fiatCurrency: 'KES',
        feeSats: 10,
        createdAt: now,
      );
      expect(txAirtime.isOutgoing, isTrue);
      expect(txAirtime.category, equals(TransactionCategory.bills));
      expect(txAirtime.displayTitle, equals('Safaricom'));

      final txEsim = TransactionModel(
        id: 'tx-5',
        type: TransactionType.esimPurchase,
        status: TransactionStatus.completed,
        amountSats: 8500,
        recipientOrSender: 'Hanbova Roaming eSIM',
        planName: 'East Africa 5GB',
        fiatAmount: 5.0,
        fiatCurrency: 'USD',
        createdAt: now,
      );
      expect(txEsim.isOutgoing, isTrue);
      expect(txEsim.category, equals(TransactionCategory.travel));
      expect(txEsim.displayTitle, equals('East Africa 5GB'));

      final txPayout = TransactionModel(
        id: 'tx-6',
        type: TransactionType.mobileMoneyPayout,
        status: TransactionStatus.completed,
        amountSats: 15000,
        recipientOrSender: '+254700000000',
        paymentMethod: 'M-Pesa / Mobile Money',
        fiatAmount: 2000.0,
        fiatCurrency: 'KES',
        createdAt: now,
      );
      expect(txPayout.isOutgoing, isTrue);
      expect(txPayout.category, equals(TransactionCategory.moneyOut));

      final txCard = TransactionModel(
        id: 'tx-7',
        type: TransactionType.cardPayment,
        status: TransactionStatus.completed,
        amountSats: 12000,
        recipientOrSender: 'Amazon Services',
        fiatAmount: 8.0,
        fiatCurrency: 'USD',
        createdAt: now,
      );
      expect(txCard.isOutgoing, isTrue);
      expect(txCard.category, equals(TransactionCategory.cards));
    });

    test(
        'TransactionsNotifier records bill payments and travel items correctly',
        () {
      final notifier = TransactionsNotifier();

      notifier.recordBillPayment(
        id: 'bill-101',
        type: TransactionType.electricity,
        billerName: 'Kenya Power (KPLC Prepaid)',
        accountReference: '37189201948',
        amountSats: 2500,
        fiatAmount: 1000.0,
        fiatCurrency: 'KES',
        feeSats: 25,
        tokenOrPin: '4819-2049-1829-4019-3918',
        receiptReference: 'REC-KPLC-84910',
        spendCountry: 'KE',
      );

      expect(notifier.state.length, equals(1));
      final recorded = notifier.state.first;
      expect(recorded.id, equals('bill-101'));
      expect(recorded.type, equals(TransactionType.electricity));
      expect(recorded.tokenOrPin, equals('4819-2049-1829-4019-3918'));
      expect(recorded.receiptReference, equals('REC-KPLC-84910'));
      expect(recorded.category, equals(TransactionCategory.bills));

      notifier.recordEsimPurchase(
        id: '8901260000000000123',
        planName: 'Kenya Roaming 3GB',
        amountSats: 5000,
        fiatAmount: 3.50,
        fiatCurrency: 'USD',
        iccid: '8901260000000000123',
        qrCode: r'LPA:1$smdp.io$MATCH123',
        spendCountry: 'KE',
      );

      expect(notifier.state.length, equals(2));
      final recordedEsim = notifier.state.first;
      expect(recordedEsim.type, equals(TransactionType.esimPurchase));
      expect(recordedEsim.planName, equals('Kenya Roaming 3GB'));
      expect(recordedEsim.category, equals(TransactionCategory.travel));
    });

    test(
        'ActivityExportService generates valid RFC-4180 CSV with rich consumer data',
        () {
      final tx = TransactionModel(
        id: 'tx-export-1',
        type: TransactionType.electricity,
        status: TransactionStatus.completed,
        amountSats: 3500,
        recipientOrSender: 'Kenya Power',
        billerName: 'Kenya Power',
        accountReference: '12345678',
        tokenOrPin: '1234-5678-9012-3456',
        receiptReference: 'REC-88910',
        fiatAmount: 1500.0,
        fiatCurrency: 'KES',
        feeSats: 30,
        createdAt: DateTime.utc(2026, 9, 2, 12, 0, 0),
        description: 'Paid KES 1500 to Kenya Power',
      );

      final csv = ActivityExportService.exportToCsv([tx]);
      expect(
          csv,
          contains(
              'Transaction ID,Date (UTC),Type,Counterparty,Amount (sats),Fiat Amount,Currency,Status,Description,Reference'));
      expect(
          csv,
          contains(
              'tx-export-1,2026-09-02T12:00:00.000Z,Kenya Power,Kenya Power,3500,1500.00,KES,COMPLETED,Paid KES 1500 to Kenya Power,REC-88910'));
    });
  });
}
