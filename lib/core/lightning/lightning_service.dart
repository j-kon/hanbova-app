import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../networking/api_client.dart';

final lightningServiceProvider = Provider<LightningService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LightningService(apiClient: apiClient);
});

class LightningInvoiceDetails {
  final String bolt11;
  final String paymentHash;
  final int amountSats;
  final String description;
  final int expirySeconds;
  final DateTime createdAt;

  const LightningInvoiceDetails({
    required this.bolt11,
    required this.paymentHash,
    required this.amountSats,
    required this.description,
    required this.expirySeconds,
    required this.createdAt,
  });

  factory LightningInvoiceDetails.fromJson(Map<String, dynamic> json) {
    return LightningInvoiceDetails(
      bolt11: json['bolt11'] as String? ?? '',
      paymentHash: json['payment_hash'] as String? ?? '',
      amountSats: json['amount_sats'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      expirySeconds: json['expiry_seconds'] as int? ?? 3600,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

class LightningPaymentResult {
  final String paymentHash;
  final String preimage;
  final int amountSats;
  final int feeSats;
  final String status;

  const LightningPaymentResult({
    required this.paymentHash,
    required this.preimage,
    required this.amountSats,
    required this.feeSats,
    required this.status,
  });

  factory LightningPaymentResult.fromJson(Map<String, dynamic> json) {
    return LightningPaymentResult(
      paymentHash: json['payment_hash'] as String? ?? '',
      preimage: json['preimage'] as String? ?? '',
      amountSats: json['amount_sats'] as int? ?? 0,
      feeSats: json['fee_sats'] as int? ?? 0,
      status: json['status'] as String? ?? 'succeeded',
    );
  }
}

class LightningService {
  final ApiClient _apiClient;

  LightningService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Creates a BOLT11 Lightning Invoice to receive sats.
  Future<LightningInvoiceDetails> createInvoice({
    required int amountSats,
    String? description,
    int? expirySeconds,
  }) async {
    final response = await _apiClient.post('/lightning/invoice', {
      'amount_sats': amountSats,
      'description': description ?? 'Hanbova Lightning Receive',
      'expiry_seconds': expirySeconds ?? 3600,
    });
    return LightningInvoiceDetails.fromJson(response);
  }

  /// Pays a BOLT11 Lightning Invoice.
  Future<LightningPaymentResult> payInvoice({
    required String bolt11,
    int? maxFeeSats,
  }) async {
    final response = await _apiClient.post('/lightning/pay', {
      'bolt11': bolt11,
      'max_fee_sats': maxFeeSats ?? 20,
    });
    return LightningPaymentResult.fromJson(response);
  }

  /// Request a NUT-04 mint quote from Cashu mint via Lightning.
  Future<Map<String, dynamic>> createMintQuote(int amountSats) async {
    return await _apiClient.post('/lightning/mint-quote', {
      'amount_sats': amountSats,
    });
  }

  /// Check payment state of a NUT-04 mint quote.
  Future<Map<String, dynamic>> checkMintQuote(String quoteId) async {
    return await _apiClient.get('/lightning/mint-quote/$quoteId');
  }

  /// Request a NUT-05 melt quote to pay a BOLT11 invoice from ecash proofs.
  Future<Map<String, dynamic>> createMeltQuote(String bolt11) async {
    return await _apiClient.post('/lightning/melt-quote', {
      'bolt11': bolt11,
    });
  }
}
