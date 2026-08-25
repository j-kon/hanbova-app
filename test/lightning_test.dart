import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/lightning/lightning_service.dart';
import 'package:hanbova_app/core/networking/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Lightning Service Tests', () {
    test('createInvoice parses BOLT11 details from backend response', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/lightning/invoice') {
          return http.Response(
            jsonEncode({
              'bolt11': 'lnbc25000n1pjhnbvareceive1234567890',
              'payment_hash': 'abcdef1234567890',
              'amount_sats': 2500,
              'description': 'Test Receive Invoice',
              'expiry_seconds': 3600,
              'created_at': '2026-08-23T19:30:00Z',
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
          baseUrl: 'http://127.0.0.1:8080/api/v1', httpClient: mockClient);
      final lightningService = LightningService(apiClient: apiClient);

      final result = await lightningService.createInvoice(
        amountSats: 2500,
        description: 'Test Receive Invoice',
      );

      expect(result.bolt11, 'lnbc25000n1pjhnbvareceive1234567890');
      expect(result.amountSats, 2500);
      expect(result.paymentHash, 'abcdef1234567890');
    });

    test('payInvoice parses payment result and fees', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/lightning/pay') {
          return http.Response(
            jsonEncode({
              'payment_hash': 'fedcba0987654321',
              'preimage': '1122334455667788',
              'amount_sats': 5000,
              'fee_sats': 4,
              'status': 'succeeded',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
          baseUrl: 'http://127.0.0.1:8080/api/v1', httpClient: mockClient);
      final lightningService = LightningService(apiClient: apiClient);

      final result = await lightningService.payInvoice(
        bolt11: 'lnbc50000n1p...',
      );

      expect(result.status, 'succeeded');
      expect(result.amountSats, 5000);
      expect(result.feeSats, 4);
      expect(result.preimage, '1122334455667788');
    });
  });
}
