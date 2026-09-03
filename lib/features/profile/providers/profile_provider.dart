import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/market/country_model.dart';

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
  return ProfileNotifier();
});

class ProfileNotifier extends StateNotifier<UserProfileData> {
  static const _storage = FlutterSecureStorage();
  static const _keyFirstName = 'user_profile_first_name';
  static const _keyLastName = 'user_profile_last_name';
  static const _keyUsername = 'user_profile_username';
  static const _keyPhone = 'user_profile_phone';
  static const _keyEmail = 'user_profile_email';
  static const _keyResidence = 'user_profile_residence';
  static const _keyAvatar = 'user_profile_avatar';

  ProfileNotifier() : super(const UserProfileData()) {
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    try {
      final fName = await _storage.read(key: _keyFirstName);
      final lName = await _storage.read(key: _keyLastName);
      final uName = await _storage.read(key: _keyUsername);
      final ph = await _storage.read(key: _keyPhone);
      final em = await _storage.read(key: _keyEmail);
      final res = await _storage.read(key: _keyResidence);
      final av = await _storage.read(key: _keyAvatar);

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

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? phone,
    String? email,
  }) async {
    final cleanUsername =
        (username ?? state.username).replaceAll('@', '').trim();
    state = state.copyWith(
      firstName: firstName?.trim() ?? state.firstName,
      lastName: lastName?.trim() ?? state.lastName,
      username: cleanUsername.isNotEmpty ? cleanUsername : state.username,
      phone: phone?.trim() ?? state.phone,
      email: email?.trim() ?? state.email,
    );

    if (firstName != null) {
      await _storage.write(key: _keyFirstName, value: state.firstName);
    }
    if (lastName != null) {
      await _storage.write(key: _keyLastName, value: state.lastName);
    }
    if (username != null) {
      await _storage.write(key: _keyUsername, value: state.username);
    }
    if (phone != null) {
      await _storage.write(key: _keyPhone, value: state.phone);
    }
    if (email != null) {
      await _storage.write(key: _keyEmail, value: state.email);
    }
  }

  Future<void> setAvatar(String path) async {
    state = state.copyWith(avatarPath: path);
    await _storage.write(key: _keyAvatar, value: path);
  }

  Future<void> removeAvatar() async {
    state = state.copyWith(clearAvatar: true);
    await _storage.delete(key: _keyAvatar);
  }
}
