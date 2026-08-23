import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final themeControllerProvider = StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController();
});

class ThemeController extends StateNotifier<ThemeMode> {
  static const _storageKey = 'hanbova_appearance_mode';
  final FlutterSecureStorage? _storage;

  ThemeController({FlutterSecureStorage? storage})
      : _storage = storage,
        super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final storage = _storage ?? const FlutterSecureStorage();
      final saved = await storage.read(key: _storageKey);
      if (saved != null) {
        switch (saved) {
          case 'light':
            state = ThemeMode.light;
            break;
          case 'dark':
            state = ThemeMode.dark;
            break;
          default:
            state = ThemeMode.system;
        }
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      String value;
      switch (mode) {
        case ThemeMode.light:
          value = 'light';
          break;
        case ThemeMode.dark:
          value = 'dark';
          break;
        case ThemeMode.system:
          value = 'system';
          break;
      }
      final storage = _storage ?? const FlutterSecureStorage();
      await storage.write(key: _storageKey, value: value);
    } catch (_) {}
  }
}
