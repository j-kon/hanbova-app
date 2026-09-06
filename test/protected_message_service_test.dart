import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hanbova_app/core/networking/api_client.dart';
import 'package:hanbova_app/features/protected/data/protected_message_service.dart';

void main() {
  for (final box in ['inbox', 'outbox']) {
    test('$box failure is not reported as an empty successful sync', () async {
      final client = MockClient(
          (request) async => http.Response('{"message":"Unavailable"}', 503));
      addTearDown(client.close);
      final service = ProtectedMessageService(
          ApiClient(baseUrl: 'http://test.invalid', httpClient: client));
      await expectLater(
          box == 'inbox' ? service.getInbox() : service.getOutbox(),
          throwsA(anything));
    });
    test('$box distinguishes valid empty data from malformed data', () async {
      var body = '[]';
      final client = MockClient((request) async => http.Response(body, 200));
      addTearDown(client.close);
      final service = ProtectedMessageService(
          ApiClient(baseUrl: 'http://test.invalid', httpClient: client));
      expect(await (box == 'inbox' ? service.getInbox() : service.getOutbox()),
          isEmpty);
      body = '{"unexpected":true}';
      await expectLater(
          box == 'inbox' ? service.getInbox() : service.getOutbox(),
          throwsFormatException);
    });
  }
}
