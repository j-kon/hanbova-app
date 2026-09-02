import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/features/spend/domain/bill_models.dart';

void main() {
  group('M3B.1 Spend & Bill Payment Domain Models', () {
    test('BillServiceType key parsing', () {
      expect(BillServiceType.fromKey('airtime'), BillServiceType.airtime);
      expect(BillServiceType.fromKey('data'), BillServiceType.data);
      expect(
          BillServiceType.fromKey('electricity'), BillServiceType.electricity);
      expect(BillServiceType.fromKey('water'), BillServiceType.water);
      expect(BillServiceType.fromKey('tv'), BillServiceType.tv);
      expect(BillServiceType.fromKey('internet'), BillServiceType.internet);
      expect(BillServiceType.fromKey('unknown'), BillServiceType.airtime);
    });

    test('Biller and BillProduct JSON deserialization', () {
      final billerJson = {
        'id': 'ke_kplc_prepaid',
        'country': 'KE',
        'service_type': 'electricity',
        'name': 'KPLC Prepaid Electricity',
        'account_reference_label': 'Meter Number',
        'account_reference_example': '14123456789',
        'is_active': true,
      };

      final biller = Biller.fromJson(billerJson);
      expect(biller.id, 'ke_kplc_prepaid');
      expect(biller.serviceType, BillServiceType.electricity);
      expect(biller.accountReferenceLabel, 'Meter Number');
      expect(biller.isActive, isTrue);

      final productJson = {
        'id': 'ke_data_10gb',
        'biller_id': 'ke_safaricom_data',
        'name': '10 GB Monthly Bundle',
        'description': 'Valid 30 days',
        'amount_fiat': 1000.0,
        'is_variable_amount': false,
      };

      final product = BillProduct.fromJson(productJson);
      expect(product.id, 'ke_data_10gb');
      expect(product.amountFiat, 1000.0);
      expect(product.isVariableAmount, isFalse);
    });

    test('CustomerValidation and BillQuote models', () {
      final validJson = {
        'is_valid': true,
        'biller_id': 'ke_kplc_prepaid',
        'customer_account': '14123456789',
        'customer_name': 'Jane Doe',
      };

      final validation = CustomerValidation.fromJson(validJson);
      expect(validation.isValid, isTrue);
      expect(validation.customerName, 'Jane Doe');

      final quoteJson = {
        'quote_id': 'quote_123',
        'biller_id': 'ke_kplc_prepaid',
        'service_type': 'electricity',
        'amount_sats': 1280,
        'amount_fiat': 100.0,
        'fee_sats': 50,
        'exchange_rate': 7800000.0,
        'customer_account': '14123456789',
        'expires_at': DateTime.now().toIso8601String(),
      };

      final quote = BillQuote.fromJson(quoteJson);
      expect(quote.quoteId, 'quote_123');
      expect(quote.amountSats, 1280);
      expect(quote.amountFiat, 100.0);
      expect(quote.serviceType, BillServiceType.electricity);
    });

    test('BillTransaction receipt and token parsing', () {
      final txJson = {
        'id': 'tx_999',
        'quote_id': 'quote_123',
        'biller_id': 'ke_kplc_prepaid',
        'biller_name': 'KPLC Prepaid',
        'service_type': 'electricity',
        'customer_account': '14123456789',
        'amount_sats': 1280,
        'amount_fiat': 100.0,
        'fee_sats': 50,
        'status': 'completed',
        'receipt_number': 'REC-889900',
        'token_code': '5821-9920-1123-8874-0019',
        'provider': 'dtone',
        'created_at': DateTime.now().toIso8601String(),
      };

      final tx = BillTransaction.fromJson(txJson);
      expect(tx.status, 'completed');
      expect(tx.receiptNumber, 'REC-889900');
      expect(tx.tokenCode, '5821-9920-1123-8874-0019');
      expect(tx.provider, 'dtone');
    });
  });
}
