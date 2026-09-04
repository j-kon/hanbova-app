import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Native protection used only while a recovery phrase can be displayed or
/// entered. Android prevents screenshots and task-switcher previews; iOS
/// covers the app when it becomes inactive or screen recording is detected.
abstract interface class SensitiveScreenGateway {
  Future<void> setEnabled(bool enabled);
}

final class MethodChannelSensitiveScreenGateway
    implements SensitiveScreenGateway {
  const MethodChannelSensitiveScreenGateway({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'org.hanbova.hanbova/sensitive_screen';
  final MethodChannel _channel;

  @override
  Future<void> setEnabled(bool enabled) {
    return _channel.invokeMethod<void>(
      'setSensitiveScreen',
      <String, bool>{'enabled': enabled},
    );
  }
}

final sensitiveScreenGatewayProvider = Provider<SensitiveScreenGateway>((ref) {
  return const MethodChannelSensitiveScreenGateway();
});

/// Enables the platform privacy shield for the lifetime of [child].
class SensitiveScreenProtection extends ConsumerStatefulWidget {
  const SensitiveScreenProtection({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<SensitiveScreenProtection> createState() =>
      _SensitiveScreenProtectionState();
}

class _SensitiveScreenProtectionState
    extends ConsumerState<SensitiveScreenProtection> {
  late final SensitiveScreenGateway _gateway;

  @override
  void initState() {
    super.initState();
    _gateway = ref.read(sensitiveScreenGatewayProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _setProtection(true);
    });
  }

  @override
  void dispose() {
    unawaited(_setProtection(false));
    super.dispose();
  }

  Future<void> _setProtection(bool enabled) async {
    try {
      await _gateway.setEnabled(enabled);
    } on PlatformException {
      // A missing native handler must not block recovery. The screen itself
      // still avoids storing or logging the phrase.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
