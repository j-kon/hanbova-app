import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Declares integrations that are genuinely available in this app build.
///
/// Keep a capability false until its end-to-end implementation, permissions,
/// and operational support are ready for customers.
final class AppCapabilities {
  final bool cameraQrScanning;
  final bool pushNotifications;
  final bool biometricLogin;
  final bool liveExchangeRates;

  const AppCapabilities.release()
      : cameraQrScanning = false,
        pushNotifications = false,
        biometricLogin = false,
        liveExchangeRates = false;
}

final appCapabilitiesProvider = Provider<AppCapabilities>(
  (_) => const AppCapabilities.release(),
);
