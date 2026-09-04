import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/market/country_model.dart';
import '../../auth/models/user_profile.dart';
import '../../auth/providers/auth_provider.dart';

class UserProfileData {
  final String firstName;
  final String lastName;
  final String username;
  final String phone;
  final String email;
  final String residenceCountry;
  final String? avatarPath;

  const UserProfileData({
    this.firstName = 'Jeremiah',
    this.lastName = 'Jacob',
    this.username = 'jaykon',
    this.phone = '+234 803 123 4567',
    this.email = 'jeremiah@hanbova.org',
    this.residenceCountry = 'NG',
    this.avatarPath,
  });

  factory UserProfileData.fromAuthenticatedUser(UserProfile? user) {
    if (user == null) return const UserProfileData();

    final username = user.username.replaceAll('@', '').trim();
    return UserProfileData(
      firstName:
          user.firstName.trim().isNotEmpty ? user.firstName.trim() : username,
      lastName: user.lastName.trim(),
      username: username,
      phone: user.phone?.trim() ?? '',
      email: user.email.trim(),
    );
  }

  String get fullName {
    final combined = '$firstName $lastName'.trim();
    return combined.isNotEmpty ? combined : username;
  }

  String get displayName => fullName;

  String get handle => username.startsWith('@') ? username : '@$username';

  String get initials {
    final f = firstName.trim();
    final l = lastName.trim();
    if (f.isNotEmpty && l.isNotEmpty) {
      return '${f[0]}${l[0]}'.toUpperCase();
    } else if (f.isNotEmpty) {
      return f.substring(0, f.length >= 2 ? 2 : 1).toUpperCase();
    } else if (username.isNotEmpty) {
      final clean = username.replaceAll('@', '').trim();
      return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'H';
  }

  CountryInfo get residenceCountryInfo =>
      CountryInfo.findByCode(residenceCountry);

  bool get hasCustomAvatar => avatarPath != null && avatarPath!.isNotEmpty;

  UserProfileData copyWith({
    String? firstName,
    String? lastName,
    String? username,
    String? phone,
    String? email,
    String? residenceCountry,
    String? avatarPath,
    bool clearAvatar = false,
  }) {
    return UserProfileData(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      residenceCountry: residenceCountry ?? this.residenceCountry,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
    );
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, UserProfileData>((ref) {
  return ProfileNotifier(user: ref.watch(currentUserProvider));
});

class ProfileNotifier extends StateNotifier<UserProfileData> {
  static const _keyPrefix = 'hanbova_profile_v1';
  static const _keyFirstName = 'user_profile_first_name';
  static const _keyLastName = 'user_profile_last_name';
  static const _keyUsername = 'user_profile_username';
  static const _keyPhone = 'user_profile_phone';
  static const _keyEmail = 'user_profile_email';
  static const _keyResidence = 'user_profile_residence';
  static const _keyAvatar = 'user_profile_avatar';

  final UserProfile? _user;
  final FlutterSecureStorage _storage;

  ProfileNotifier({
    UserProfile? user,
    FlutterSecureStorage? storage,
  })  : _user = user,
        _storage = storage ?? const FlutterSecureStorage(),
        super(UserProfileData.fromAuthenticatedUser(user)) {
    unawaited(_loadPersisted());
  }

  String? get _userId {
    final id = _user?.id.trim() ?? '';
    return id.isEmpty ? null : id;
  }

  String _scopedKey(String legacyKey) {
    final encodedUserId =
        base64Url.encode(utf8.encode(_userId!)).replaceAll('=', '');
    return '${_keyPrefix}_${encodedUserId}_$legacyKey';
  }

  Future<String?> _readScoped(String legacyKey) {
    if (_userId == null) return Future<String?>.value(null);
    return _storage.read(key: _scopedKey(legacyKey));
  }

  Future<void> _writeScoped(String legacyKey, String value) async {
    if (_userId == null) return;
    await _storage.write(key: _scopedKey(legacyKey), value: value);
  }

  Future<void> _deleteScoped(String legacyKey) async {
    if (_userId == null) return;
    await _storage.delete(key: _scopedKey(legacyKey));
  }

  Future<void> _loadPersisted() async {
    try {
      if (_userId == null) return;

      var values = await _readValues(_readScoped);
      if (values.values.every((value) => value == null)) {
        final legacy = await _readValues(
          (key) => _storage.read(key: key),
        );
        if (_legacyProfileBelongsToAuthenticatedUser(legacy)) {
          values = legacy;
          await _writeValues(values);
          for (final key in _allKeys) {
            await _storage.delete(key: key);
          }
        }
      }

      final fName = values[_keyFirstName];
      final lName = values[_keyLastName];
      final uName = values[_keyUsername];
      final ph = values[_keyPhone];
      final em = values[_keyEmail];
      final res = values[_keyResidence];
      final av = values[_keyAvatar];

      state = state.copyWith(
        firstName: fName ?? state.firstName,
        lastName: lName ?? state.lastName,
        username: uName ?? state.username,
        phone: ph ?? state.phone,
        email: em ?? state.email,
        residenceCountry: res ?? state.residenceCountry,
        avatarPath: av,
      );
    } catch (_) {}
  }

  static const _allKeys = <String>[
    _keyFirstName,
    _keyLastName,
    _keyUsername,
    _keyPhone,
    _keyEmail,
    _keyResidence,
    _keyAvatar,
  ];

  Future<Map<String, String?>> _readValues(
    Future<String?> Function(String key) read,
  ) async {
    final values = <String, String?>{};
    for (final key in _allKeys) {
      values[key] = await read(key);
    }
    return values;
  }

  bool _legacyProfileBelongsToAuthenticatedUser(
    Map<String, String?> legacy,
  ) {
    final legacyUsername = legacy[_keyUsername]?.replaceAll('@', '').trim();
    final legacyEmail = legacy[_keyEmail]?.trim();
    final currentUsername = _user?.username.replaceAll('@', '').trim();
    final currentEmail = _user?.email.trim();

    return legacyUsername != null &&
        legacyUsername.isNotEmpty &&
        currentUsername != null &&
        currentUsername.isNotEmpty &&
        legacyUsername.toLowerCase() == currentUsername.toLowerCase() &&
        legacyEmail != null &&
        legacyEmail.isNotEmpty &&
        currentEmail != null &&
        currentEmail.isNotEmpty &&
        legacyEmail.toLowerCase() == currentEmail.toLowerCase();
  }

  Future<void> _writeValues(Map<String, String?> values) async {
    for (final entry in values.entries) {
      final value = entry.value;
      if (value != null) await _writeScoped(entry.key, value);
    }
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? phone,
    String? email,
    String? residenceCountry,
  }) async {
    final cleanUsername =
        (username ?? state.username).replaceAll('@', '').trim();
    state = state.copyWith(
      firstName: firstName?.trim() ?? state.firstName,
      lastName: lastName?.trim() ?? state.lastName,
      username: cleanUsername.isNotEmpty ? cleanUsername : state.username,
      phone: phone?.trim() ?? state.phone,
      email: email?.trim() ?? state.email,
      residenceCountry: residenceCountry?.trim() ?? state.residenceCountry,
    );

    if (firstName != null) {
      await _writeScoped(_keyFirstName, state.firstName);
    }
    if (lastName != null) {
      await _writeScoped(_keyLastName, state.lastName);
    }
    if (username != null) {
      await _writeScoped(_keyUsername, state.username);
    }
    if (phone != null) {
      await _writeScoped(_keyPhone, state.phone);
    }
    if (email != null) {
      await _writeScoped(_keyEmail, state.email);
    }
    if (residenceCountry != null) {
      await _writeScoped(_keyResidence, state.residenceCountry);
    }
  }

  Future<void> setAvatar(String path) async {
    state = state.copyWith(avatarPath: path);
    await _writeScoped(_keyAvatar, path);
  }

  Future<void> removeAvatar() async {
    state = state.copyWith(clearAvatar: true);
    await _deleteScoped(_keyAvatar);
  }
}
