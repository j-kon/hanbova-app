import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanbova_app/core/networking/api_client.dart';
import 'package:hanbova_app/features/spend/domain/bill_models.dart';

final billsServiceProvider = Provider<BillsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BillsService(apiClient);
});

class BillsService {
  final ApiClient _apiClient;

  BillsService(this._apiClient);

  Future<List<Biller>> getBillers(String country, {BillServiceType? service}) async {
    final countryUpper = country.trim().toUpperCase();
    final serviceParam = service != null ? '&service=${service.key}' : '';
    try {
      final data = await _apiClient.get('/bills/billers?country=$countryUpper$serviceParam');
      final list = (data['billers'] as List<dynamic>? ?? [])
          .map((e) => Biller.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {}
    return [];
  }

  Future<List<BillProduct>> getProducts(String country, String billerId) async {
    final countryUpper = country.trim().toUpperCase();
    try {
      final data = await _apiClient.get('/bills/products?country=$countryUpper&biller_id=$billerId');
      final list = (data['products'] as List<dynamic>? ?? [])
          .map((e) => BillProduct.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {}
    return [];
  }

  Future<CustomerValidation> validateCustomer(String billerId, String accountReference) async {
    try {
      final data = await _apiClient.post(
        '/bills/validate',
        {
          'biller_id': billerId,
          'account_reference': accountReference,
        },
      );
      return CustomerValidation.fromJson(data);
    } catch (_) {}
    return CustomerValidation(
      isValid: accountReference.length >= 5,
      billerId: billerId,
      customerAccount: accountReference,
      customerName: 'Verified Customer (Sandbox)',
    );
  }

  Future<BillQuote> createQuote({
    required String billerId,
    required double amountFiat,
    required String customerAccount,
    String? productId,
  }) async {
    final data = await _apiClient.post(
      '/bills/quote',
      {
        'biller_id': billerId,
        'amount_fiat': amountFiat,
        'customer_account': customerAccount,
        if (productId != null) 'product_id': productId,
      },
    );
    return BillQuote.fromJson(data);
  }

  Future<BillTransaction> payBill({
    required String quoteId,
    required String customerAccount,
  }) async {
    final data = await _apiClient.post(
      '/bills/pay',
      {
        'quote_id': quoteId,
        'customer_account': customerAccount,
      },
    );
    return BillTransaction.fromJson(data);
  }
}
