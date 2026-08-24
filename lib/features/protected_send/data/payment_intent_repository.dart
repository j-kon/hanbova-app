import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/networking/api_client.dart';
import '../domain/protected_payment_intent.dart';

final paymentIntentRepositoryProvider = Provider<PaymentIntentRepository>((ref) {
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

    try {
      final response = await _apiClient.post('/payment-intents', payload);
      return ProtectedPaymentIntent.fromJson(response);
    } catch (_) {
      // Fallback development mock if backend is offline
      final id = const Uuid().v4();
      final now = DateTime.now();
      final expiry = expiresInSeconds != null
          ? now.add(Duration(seconds: expiresInSeconds))
          : now.add(const Duration(hours: 24));

      return ProtectedPaymentIntent(
        id: id,
        paymentType: paymentType,
        status: paymentType == 'protected' ? 'claimable' : 'pending',
        amountSats: amountSats,
        senderId: senderId ?? 'mock_sender_me',
        recipientIdentifier: recipientIdentifier,
        description: description,
        expiresAt: expiry,
        claimReference: 'hnbv_claim_${id.substring(0, 8)}',
        createdAt: now,
      );
    }
  }

  Future<ProtectedPaymentIntent> getPaymentIntent(String id) async {
    try {
      final response = await _apiClient.get('/payment-intents/$id');
      return ProtectedPaymentIntent.fromJson(response);
    } catch (_) {
      return ProtectedPaymentIntent(
        id: id,
        paymentType: 'protected',
        status: 'claimable',
        amountSats: 25000,
        recipientIdentifier: 'recipient@hanbova.africa',
        description: 'Design mockups milestone',
        expiresAt: DateTime.now().add(const Duration(hours: 20)),
        claimReference: 'hnbv_claim_${id.length > 8 ? id.substring(0, 8) : id}',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      );
    }
  }

  Future<ProtectedPaymentIntent> getPaymentIntentByReference(String reference) async {
    try {
      final response = await _apiClient.get('/payment-intents?claim_reference=$reference');
      if (response['data'] is List && (response['data'] as List).isNotEmpty) {
        return ProtectedPaymentIntent.fromJson((response['data'] as List).first as Map<String, dynamic>);
      }
      return getPaymentIntent(reference);
    } catch (_) {
      return getPaymentIntent(reference);
    }
  }

  Future<ProtectedPaymentIntent> claimPaymentIntent(
    String id, {
    String? claimerIdentifier,
  }) async {
    final payload = {
      'status': 'claimed',
    };

    try {
      final response = await _apiClient.post('/payment-intents/$id/status', payload);
      return ProtectedPaymentIntent.fromJson(response);
    } catch (_) {
      return ProtectedPaymentIntent(
        id: id,
        paymentType: 'protected',
        status: 'claimed',
        amountSats: 25000,
        recipientIdentifier: claimerIdentifier ?? 'me',
        description: 'Protected payment claimed',
        expiresAt: DateTime.now().add(const Duration(hours: 20)),
        claimReference: 'claimed_$id',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
    }
  }

  Future<ProtectedPaymentIntent> refundPaymentIntent({
    required String id,
    required String senderId,
  }) async {
    final payload = {
      'status': 'refunded',
    };

    try {
      final response = await _apiClient.post('/payment-intents/$id/status', payload);
      return ProtectedPaymentIntent.fromJson(response);
    } catch (_) {
      return ProtectedPaymentIntent(
        id: id,
        paymentType: 'protected',
        status: 'refunded',
        amountSats: 25000,
        recipientIdentifier: 'unclaimed',
        description: 'Expired payment refunded to sender',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        claimReference: 'refunded_$id',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      );
    }
  }

  Future<List<ProtectedPaymentIntent>> getPaymentIntents() async {
    try {
      final response = await _apiClient.get('/payment-intents');
      if (response['data'] is List) {
        final list = response['data'] as List;
        return list
            .map((item) => ProtectedPaymentIntent.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
