import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final balanceVisibilityProvider =
    StateNotifierProvider<BalanceVisibilityNotifier, bool>((ref) {
  return BalanceVisibilityNotifier();
});

class BalanceVisibilityNotifier extends StateNotifier<bool> {
  static const _storageKey = 'hanbova_balance_visible';
  final FlutterSecureStorage _storage;

  BalanceVisibilityNotifier({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(true) {
    _loadVisibility();
  }

  Future<void> _loadVisibility() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved != null) {
        state = saved == 'true';
      }
    } catch (_) {}
  }

  Future<void> toggle() async {
    state = !state;
    try {
      await _storage.write(key: _storageKey, value: state.toString());
    } catch (_) {}
  }
}
