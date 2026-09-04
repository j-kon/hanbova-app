import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/features/auth/models/user_profile.dart';
import 'package:hanbova_app/features/profile/providers/profile_provider.dart';

Future<void> _settleStorage() => Future<void>.delayed(Duration.zero);

UserProfile _user({
  required String id,
  required String username,
  required String email,
  required String firstName,
}) =>
    UserProfile(
      id: id,
      username: username,
      handle: '@$username',
      email: email,
      firstName: firstName,
      lastName: 'Example',
      displayName: '$firstName Example',
      emailVerified: true,
      createdAt: DateTime.utc(2026),
    );

final _alice = _user(
  id: 'account-alice',
  username: 'alice',
  email: 'alice@example.com',
  firstName: 'Alice',
);

final _bob = _user(
  id: 'account-bob',
  username: 'bob',
  email: 'bob@example.com',
  firstName: 'Bob',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('switching accounts never loads the previous account profile', () async {
    final firstAccount = ProfileNotifier(user: _alice);
    await _settleStorage();
    await firstAccount.updateProfile(
      firstName: 'Alice Saved',
      email: 'alice@example.com',
    );
    await firstAccount.setAvatar('/avatars/alice.png');

    final secondAccount = ProfileNotifier(user: _bob);
    await _settleStorage();

    expect(secondAccount.state.firstName, 'Bob');
    expect(secondAccount.state.email, 'bob@example.com');
    expect(secondAccount.state.avatarPath, isNull);

    final reloadedFirstAccount = ProfileNotifier(user: _alice);
    await _settleStorage();
    expect(reloadedFirstAccount.state.firstName, 'Alice Saved');
    expect(reloadedFirstAccount.state.avatarPath, '/avatars/alice.png');
  });

  test('legacy profile data is ignored unless it identifies the active user',
      () async {
    FlutterSecureStorage.setMockInitialValues({
      'user_profile_first_name': 'Alice Saved',
      'user_profile_username': 'alice',
      'user_profile_email': 'alice@example.com',
      'user_profile_avatar': '/avatars/alice.png',
    });

    final activeAccount = ProfileNotifier(user: _bob);
    await _settleStorage();

    expect(activeAccount.state.firstName, 'Bob');
    expect(activeAccount.state.email, 'bob@example.com');
    expect(activeAccount.state.avatarPath, isNull);
  });

  test('matching legacy profile data migrates into the active account scope',
      () async {
    FlutterSecureStorage.setMockInitialValues({
      'user_profile_first_name': 'Alice Saved',
      'user_profile_last_name': 'Example',
      'user_profile_username': 'alice',
      'user_profile_email': 'alice@example.com',
      'user_profile_avatar': '/avatars/alice.png',
    });

    final activeAccount = ProfileNotifier(user: _alice);
    await _settleStorage();

    expect(activeAccount.state.firstName, 'Alice Saved');
    expect(activeAccount.state.avatarPath, '/avatars/alice.png');

    final reloadedAccount = ProfileNotifier(user: _alice);
    await _settleStorage();
    expect(reloadedAccount.state.firstName, 'Alice Saved');
    expect(
      await const FlutterSecureStorage().read(key: 'user_profile_first_name'),
      isNull,
    );
  });
}
