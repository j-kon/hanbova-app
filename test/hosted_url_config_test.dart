import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/config/app_config.dart';

void main() {
  for (final create in [AppConfig.createPilot, AppConfig.createProduction]) {
    test(
        'hosted configuration rejects malformed and private endpoint URLs ($create)',
        () {
      for (final url in [
        'https://',
        'https:///api/v1',
        'https://192.168.1.5',
        'https://10.1.2.3',
        'https://172.20.0.1',
        'https://127.1.2.3',
        'https://169.254.169.254',
        'https://0.0.0.0',
        'https://[::1]',
        'https://[fc00::1]',
        'https://[fe80::1]',
        'https://[::ffff:192.168.1.5]',
        'https://LOCALHOST.',
        'https://mint.local',
        'https://user:secret@api.example.com',
        'https://api.example.com?token=secret',
        'https://api.example.com#fragment',
      ]) {
        expect(
            () => create(apiBaseUrl: url, mintUrl: 'https://mint.example.com'),
            throwsA(isA<StateError>()),
            reason: 'API: $url');
        expect(
            () => create(
                apiBaseUrl: 'https://api.example.com/api/v1', mintUrl: url),
            throwsA(isA<StateError>()),
            reason: 'Mint: $url');
      }
    });

    test('hosted validation examines the host, not path substrings ($create)',
        () {
      final config = create(
          apiBaseUrl: 'https://api.example.com/localhost/api/v1',
          mintUrl: 'https://mint.example.com/127.0.0.1');
      expect(config.apiBaseUrl, 'https://api.example.com/localhost/api/v1');
    });

    test('hosted configuration errors do not repeat endpoint secrets ($create)',
        () {
      expect(
          () => create(
              apiBaseUrl: 'http://user:secret@api.example.com',
              mintUrl: 'https://mint.example.com'),
          throwsA(isA<StateError>().having(
              (e) => e.toString(), 'safe error', isNot(contains('secret')))));
    });
  }
}
