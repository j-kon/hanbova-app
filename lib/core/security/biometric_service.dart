import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

abstract interface class LocalAuthGateway {
  Future<bool> canCheckBiometrics();

  Future<bool> isDeviceSupported();

  Future<bool> authenticate(String reason);
}

final class PluginLocalAuthGateway implements LocalAuthGateway {
  final LocalAuthentication _auth;

  PluginLocalAuthGateway({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  @override
  Future<bool> canCheckBiometrics() => _auth.canCheckBiometrics;

  @override
  Future<bool> isDeviceSupported() => _auth.isDeviceSupported();

  @override
  Future<bool> authenticate(String reason) {
    return _auth.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: false,
      ),
    );
  }
}

class BiometricService {
  final LocalAuthGateway _gateway;

  BiometricService({LocalAuthGateway? gateway})
      : _gateway = gateway ?? PluginLocalAuthGateway();

  /// Check if device supports biometrics or device passcode.
  Future<bool> isBiometricsAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _gateway.canCheckBiometrics();
      final isDeviceSupported = await _gateway.isDeviceSupported();
      return canAuthenticateWithBiometrics || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Request biometric or passcode authentication from user.
  Future<bool> authenticate({
    required String reason,
  }) async {
    try {
      final isAvailable = await isBiometricsAvailable();
      if (!isAvailable) {
        return false;
      }

      return await _gateway.authenticate(reason);
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
