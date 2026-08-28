import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/security/biometric_service.dart';

final class FakeLocalAuthGateway implements LocalAuthGateway {
  final bool canCheck;
  final bool supported;
  final bool authResult;
  final bool throwsAvailabilityError;
  final bool throwsPlatformError;
  int authenticateCalls = 0;
  String? lastReason;

  FakeLocalAuthGateway({
    this.canCheck = true,
    this.supported = true,
    this.authResult = false,
    this.throwsAvailabilityError = false,
    this.throwsPlatformError = false,
  });

  @override
  Future<bool> canCheckBiometrics() async {
    if (throwsAvailabilityError) {
      throw PlatformException(code: 'availability_error');
    }
    return canCheck;
  }

  @override
  Future<bool> isDeviceSupported() async => supported;

  @override
  Future<bool> authenticate(String reason) async {
    authenticateCalls += 1;
    lastReason = reason;
    if (throwsPlatformError) {
      throw PlatformException(code: 'auth_error');
    }
    return authResult;
  }
}

void main() {
  test('unsupported device is denied without opening a prompt', () async {
    final gateway = FakeLocalAuthGateway(
      canCheck: false,
      supported: false,
    );
    final service = BiometricService(gateway: gateway);

    expect(
      await service.authenticate(reason: 'Reveal recovery phrase'),
      isFalse,
    );
    expect(gateway.authenticateCalls, 0);
  });

  test('cancelled or rejected prompt is denied', () async {
    final gateway = FakeLocalAuthGateway(authResult: false);
    final service = BiometricService(gateway: gateway);

    expect(
      await service.authenticate(reason: 'Replace wallet identity'),
      isFalse,
    );
    expect(gateway.authenticateCalls, 1);
    expect(gateway.lastReason, 'Replace wallet identity');
  });

  test('platform errors during prompt are denied', () async {
    final gateway = FakeLocalAuthGateway(throwsPlatformError: true);
    final service = BiometricService(gateway: gateway);

    expect(
      await service.authenticate(reason: 'Reveal recovery phrase'),
      isFalse,
    );
  });

  test('availability errors are denied without opening a prompt', () async {
    final gateway = FakeLocalAuthGateway(throwsAvailabilityError: true);
    final service = BiometricService(gateway: gateway);

    expect(
      await service.authenticate(reason: 'Reveal recovery phrase'),
      isFalse,
    );
    expect(gateway.authenticateCalls, 0);
  });

  test('device passcode support can authorize without biometric hardware',
      () async {
    final gateway = FakeLocalAuthGateway(
      canCheck: false,
      supported: true,
      authResult: true,
    );
    final service = BiometricService(gateway: gateway);

    expect(
      await service.authenticate(reason: 'Reveal recovery phrase'),
      isTrue,
    );
    expect(gateway.authenticateCalls, 1);
  });

  test('only explicit operating-system success authorizes access', () async {
    final gateway = FakeLocalAuthGateway(authResult: true);
    final service = BiometricService(gateway: gateway);

    expect(
      await service.authenticate(reason: 'Reveal recovery phrase'),
      isTrue,
    );
  });
}
