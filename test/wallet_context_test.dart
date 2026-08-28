import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/network/network_environment.dart';
import 'package:hanbova_app/core/wallet/wallet_context.dart';
import 'package:hanbova_app/features/auth/models/user_profile.dart';
import 'package:hanbova_app/features/auth/providers/auth_provider.dart';

void main() {
  final alice = UserProfile(
    id: 'alice/id',
    username: 'alice',
    handle: '@alice',
    email: 'alice@example.test',
    firstName: 'Alice',
    lastName: 'Test',
    displayName: 'Alice Test',
    emailVerified: true,
    createdAt: DateTime.utc(2026),
  );

  group('WalletContextKey', () {
    test('requires an authenticated non-empty user and enabled config', () {
      expect(
        WalletContextKey.fromSession(
          AuthState.unauthenticated(),
          NetworkConfig.local,
        ),
        isNull,
      );
      expect(
        WalletContextKey.fromSession(
          AuthState.authenticated(alice, 'token'),
          NetworkConfig.mainnetLocked,
        ),
        isNull,
      );

      final emptyUser = UserProfile(
        id: '   ',
        username: alice.username,
        handle: alice.handle,
        email: alice.email,
        firstName: alice.firstName,
        lastName: alice.lastName,
        displayName: alice.displayName,
        emailVerified: alice.emailVerified,
        createdAt: alice.createdAt,
      );
      expect(
        WalletContextKey.fromSession(
          AuthState.authenticated(emptyUser, 'token'),
          NetworkConfig.local,
        ),
        isNull,
      );
    });

    test('distinguishes locked mainnet from the mainnet pilot', () {
      final pilot = WalletContextKey(
        userId: alice.id,
        network: HanbovaNetwork.mainnet,
        storagePrefix: NetworkConfig.mainnetPilot.storagePrefix,
      );
      final locked = WalletContextKey(
        userId: alice.id,
        network: HanbovaNetwork.mainnet,
        storagePrefix: NetworkConfig.mainnetLocked.storagePrefix,
      );

      expect(pilot, isNot(locked));
      expect(pilot.storageId, isNot(locked.storageId));
      expect(pilot.identityStoragePrefix, isNot(locked.identityStoragePrefix));
    });

    test('uses delimiter-safe storage IDs for arbitrary backend user IDs', () {
      const key = WalletContextKey(
        userId: 'alice/user:one',
        network: HanbovaNetwork.cashuTest,
        storagePrefix: 'wallet_cashu_test',
      );

      expect(key.storageId, isNot(contains('alice/user:one')));
      expect(key.storageId, startsWith('v1_'));
      expect(
        key.legacyIdentityStoragePrefix,
        'hanbova_wallet_cashu_test_alice/user:one',
      );
    });

    test('derives an enabled context from an authenticated session', () {
      final context = WalletContextKey.fromSession(
        AuthState.authenticated(alice, 'token'),
        NetworkConfig.cashuTest,
      );

      expect(context, isNotNull);
      expect(context!.userId, alice.id);
      expect(context.network, HanbovaNetwork.cashuTest);
      expect(context.storagePrefix, 'wallet_cashu_test');
    });
  });
}
