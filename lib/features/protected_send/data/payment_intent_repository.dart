import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/networking/api_client.dart';
import '../domain/protected_payment_intent.dart';

final paymentIntentRepositoryProvider =
    Provider<PaymentIntentRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PaymentIntentRepository(apiClient);
});

class PaymentIntentRepository {
  final ApiClient _apiClient;

  PaymentIntentRepository(this._apiClient);

  Future<ProtectedPaymentIntent> createPaymentIntent({
    required String paymentType,
    required int amountSats,
    required String recipientIdentifier,
    String? senderId,
    String? description,
    int? expiresInSeconds,
  }) async {
    final payload = {
      'payment_type': paymentType,
      'amount_sats': amountSats,
      'recipient_identifier': recipientIdentifier,
      'sender_id': senderId,
      'description': description,
      'expires_in_seconds': expiresInSeconds,
    };

    final response = await _apiClient.post('/payment-intents', payload);
    return ProtectedPaymentIntent.fromJson(response);
  }

  Future<ProtectedPaymentIntent> getPaymentIntent(String id) async {
    final response = await _apiClient.get('/payment-intents/$id');
    return ProtectedPaymentIntent.fromJson(response);
  }

  Future<ProtectedPaymentIntent> getPaymentIntentByReference(
      String reference) async {
    final cleanRef = Uri.encodeComponent(reference.trim());
    final response =
        await _apiClient.get('/payment-intents/by-reference/$cleanRef');
    return ProtectedPaymentIntent.fromJson(response);
  }

  Future<ProtectedPaymentIntent> claimPaymentIntent(
    String id, {
    String? claimerIdentifier,
  }) async {
    final payload = {
      'status': 'claimed',
    };

    final response =
        await _apiClient.post('/payment-intents/$id/status', payload);
    return ProtectedPaymentIntent.fromJson(response);
  }

  Future<ProtectedPaymentIntent> refundPaymentIntent({
    required String id,
    required String senderId,
  }) async {
    final payload = {
      'status': 'refunded',
    };

    final response =
        await _apiClient.post('/payment-intents/$id/status', payload);
    return ProtectedPaymentIntent.fromJson(response);
  }

  Future<ProtectedPaymentIntent> updatePaymentStatus(
    String id,
    String status,
  ) async {
    final payload = {
      'status': status,
    };

    final response =
        await _apiClient.post('/payment-intents/$id/status', payload);
    return ProtectedPaymentIntent.fromJson(response);
  }

  Future<List<ProtectedPaymentIntent>> getPaymentIntents() async {
    final response = await _apiClient.get('/payment-intents');
    if (response['data'] is List) {
      final list = response['data'] as List;
      return list
          .map((item) =>
              ProtectedPaymentIntent.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
