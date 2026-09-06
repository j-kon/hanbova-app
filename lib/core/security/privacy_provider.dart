import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PrivacySettings {
  final bool isBalanceHidden;
  final bool hideInAppSwitcher;
  final bool hideNotificationAmounts;
  final bool requireBiometricForSensitive;

  const PrivacySettings({
    this.isBalanceHidden = false,
    this.hideInAppSwitcher = true,
    this.hideNotificationAmounts = false,
    this.requireBiometricForSensitive = true,
  });

  PrivacySettings copyWith({
    bool? isBalanceHidden,
    bool? hideInAppSwitcher,
    bool? hideNotificationAmounts,
    bool? requireBiometricForSensitive,
  }) {
    return PrivacySettings(
      isBalanceHidden: isBalanceHidden ?? this.isBalanceHidden,
      hideInAppSwitcher: hideInAppSwitcher ?? this.hideInAppSwitcher,
      hideNotificationAmounts:
          hideNotificationAmounts ?? this.hideNotificationAmounts,
      requireBiometricForSensitive:
          requireBiometricForSensitive ?? this.requireBiometricForSensitive,
    );
  }
}

final privacyProvider =
    StateNotifierProvider<PrivacyNotifier, PrivacySettings>((ref) {
  return PrivacyNotifier();
});

class PrivacyNotifier extends StateNotifier<PrivacySettings> {
  static const _storage = FlutterSecureStorage();
  static const _keyBalanceHidden = 'privacy_balance_hidden';
  static const _keyAppSwitcher = 'privacy_hide_app_switcher';
  static const _keyNotifAmounts = 'privacy_hide_notif_amounts';
  static const _keyBiometric = 'privacy_biometric_sensitive';
  bool _balanceChanged = false;

  PrivacyNotifier() : super(const PrivacySettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final bal = await _storage.read(key: _keyBalanceHidden);
      final legacyVisible = bal == null
          ? await _storage.read(key: 'hanbova_balance_visible')
          : null;
      final switcher = await _storage.read(key: _keyAppSwitcher);
      final notif = await _storage.read(key: _keyNotifAmounts);
      final bio = await _storage.read(key: _keyBiometric);

      if (!mounted) return;
      state = state.copyWith(
        isBalanceHidden: _balanceChanged
            ? state.isBalanceHidden
            : bal == 'true' || (bal == null && legacyVisible == 'false'),
        hideInAppSwitcher: switcher != 'false',
        hideNotificationAmounts: notif == 'true',
        requireBiometricForSensitive: bio != 'false',
      );
    } catch (_) {}
  }

  Future<void> toggleBalanceHidden() async {
    _balanceChanged = true;
    final next = !state.isBalanceHidden;
    state = state.copyWith(isBalanceHidden: next);
    await _storage.write(key: _keyBalanceHidden, value: next.toString());
  }

  Future<void> setBalanceHidden(bool hidden) async {
    _balanceChanged = true;
    state = state.copyWith(isBalanceHidden: hidden);
    await _storage.write(key: _keyBalanceHidden, value: hidden.toString());
  }

  Future<void> setHideInAppSwitcher(bool value) async {
    state = state.copyWith(hideInAppSwitcher: value);
    await _storage.write(key: _keyAppSwitcher, value: value.toString());
  }

  Future<void> setHideNotificationAmounts(bool value) async {
    state = state.copyWith(hideNotificationAmounts: value);
    await _storage.write(key: _keyNotifAmounts, value: value.toString());
  }

  Future<void> setRequireBiometricForSensitive(bool value) async {
    state = state.copyWith(requireBiometricForSensitive: value);
    await _storage.write(key: _keyBiometric, value: value.toString());
  }
}
