import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/networking/api_client.dart';

class UserPaymentProfile {
  final String username;
  final String handle;
  final String protectedPaymentPubkey;
  final String transportEncryptionPubkey;

  const UserPaymentProfile({
    required this.username,
    required this.handle,
    required this.protectedPaymentPubkey,
    required this.transportEncryptionPubkey,
  });

  factory UserPaymentProfile.fromJson(Map<String, dynamic> json) {
    return UserPaymentProfile(
      username: json['username'] as String,
      handle: json['handle'] as String,
      protectedPaymentPubkey: json['protected_payment_pubkey'] as String,
      transportEncryptionPubkey: json['transport_encryption_pubkey'] as String,
    );
  }
}

class RemoteProtectedMessage {
  final String id;
  final String? paymentIntentId;
  final String senderUsername;
  final String recipientUsername;
  final String encryptedPayload;
  final int payloadVersion;
  final String status;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;

  const RemoteProtectedMessage({
    required this.id,
    this.paymentIntentId,
    required this.senderUsername,
    required this.recipientUsername,
    required this.encryptedPayload,
    required this.payloadVersion,
    required this.status,
    required this.createdAt,
    this.acknowledgedAt,
  });

  factory RemoteProtectedMessage.fromJson(Map<String, dynamic> json) {
    return RemoteProtectedMessage(
      id: json['id'] as String,
      paymentIntentId: json['payment_intent_id'] as String?,
      senderUsername: json['sender_username'] as String,
      recipientUsername: json['recipient_username'] as String,
      encryptedPayload: json['encrypted_payload'] as String,
      payloadVersion: json['payload_version'] as int? ?? 1,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.parse(json['acknowledged_at'] as String)
          : null,
    );
  }
}

final protectedMessageServiceProvider = Provider<ProtectedMessageService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProtectedMessageService(apiClient);
});

class ProtectedMessageService {
  final ApiClient _apiClient;

  ProtectedMessageService(this._apiClient);

  /// Resolves recipient payment profile and public keys.
  Future<UserPaymentProfile> resolveUserPaymentProfile(String username) async {
    final clean = username.trim().replaceAll('@', '');
    final response = await _apiClient.get('/users/$clean/payment-profile');
    return UserPaymentProfile.fromJson(response);
  }

  /// Sends an encrypted protected envelope to a recipient.
  Future<RemoteProtectedMessage> sendProtectedMessage({
    required String recipientUsername,
    required String encryptedPayload,
    int payloadVersion = 1,
    String? paymentIntentId,
  }) async {
    final response = await _apiClient.post(
      '/protected-messages',
      {
        'recipient_username': recipientUsername,
        'encrypted_payload': encryptedPayload,
        'payload_version': payloadVersion,
        'payment_intent_id': paymentIntentId,
      },
    );
    return RemoteProtectedMessage.fromJson(response);
  }

  /// Fetches incoming encrypted messages for the logged-in recipient.
  Future<List<RemoteProtectedMessage>> getInbox() async {
    try {
      final response = await _apiClient.get('/protected-messages/inbox');
      final list = response['data'] is List ? response['data'] as List : (response is List ? response as List : []);
      return list
          .map((item) => RemoteProtectedMessage.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetches sent encrypted messages for the logged-in sender.
  Future<List<RemoteProtectedMessage>> getOutbox() async {
    try {
      final response = await _apiClient.get('/protected-messages/outbox');
      final list = response['data'] is List ? response['data'] as List : (response is List ? response as List : []);
      return list
          .map((item) => RemoteProtectedMessage.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Acknowledges or updates delivery status of a message.
  Future<void> acknowledgeMessage(String id, {String? status}) async {
    await _apiClient.post(
      '/protected-messages/$id/ack',
      {
        'status': status ?? 'acknowledged',
      },
    );
  }
}
