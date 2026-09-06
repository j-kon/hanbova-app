import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/cashu/wallet_policy.dart';
import 'package:hanbova_app/core/errors/app_failure.dart';
import 'package:hanbova_app/core/errors/user_facing_error.dart';
import 'package:hanbova_app/core/networking/api_client.dart';
import 'package:http/testing.dart';

void main() {
  test('socket exception maps to retryable offline message', () {
    final error = UserFacingErrorMapper.from(
      const SocketException('Connection refused: token=cashuBsecret'),
    );

    expect(error.code, UserErrorCode.offline);
    expect(error.retryable, isTrue);
    expect(
      error.message,
      'You appear to be offline. Check your connection and try again.',
    );
    expect(error.message, isNot(contains('cashuBsecret')));
  });

  test('unknown wallet exception never exposes raw details', () {
    final error = UserFacingErrorMapper.from(
      StateError('ffi error token=cashuBsecret'),
    );

    expect(error.code, UserErrorCode.unexpected);
    expect(
      error.message,
      'Something went wrong. Your wallet state was not discarded.',
    );
    expect(error.message, isNot(contains('ffi')));
  });

  test('stable failure and policy codes map without inspecting secrets', () {
    expect(
      UserFacingErrorMapper.from(
        const AppFailure(message: 'jwt=cashuBsecret', code: '401'),
      ).code,
      UserErrorCode.authenticationRequired,
    );
    expect(
      UserFacingErrorMapper.from(
        const WalletPolicyViolation('send_limit', 'secret limit detail'),
      ).code,
      UserErrorCode.policyLimit,
    );
  });

  test('API client keeps transport details out of its public failure',
      () async {
    final client = ApiClient(
      baseUrl: 'https://example.invalid',
      httpClient: MockClient((_) async {
        throw const SocketException('token=cashuBsecret');
      }),
    );

    try {
      await client.get('/wallet');
      fail('request should fail');
    } on AppFailure catch (failure) {
      expect(failure.code, 'network_error');
      expect(failure.message, 'Network request failed');
      expect(failure.message, isNot(contains('cashuBsecret')));
      expect(failure.originalError, isNotNull);
    }
  });
}
