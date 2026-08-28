import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/crypto/crypto_identity_service.dart';
import 'package:hanbova_app/core/crypto/wallet_identity_store.dart';
import 'package:hanbova_app/core/network/network_environment.dart';
import 'package:hanbova_app/core/wallet/wallet_context.dart';

const validMnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

const aliceContext = WalletContextKey(
  userId: 'alice',
  network: HanbovaNetwork.cashuTest,
  storagePrefix: 'wallet_cashu_test',
);

const bobContext = WalletContextKey(
  userId: 'bob',
  network: HanbovaNetwork.cashuTest,
  storagePrefix: 'wallet_cashu_test',
);

final testActiveContextProvider =
    StateProvider<WalletContextKey?>((ref) => aliceContext);

final class FakeWalletIdentityStore implements WalletIdentityStore {
  final Map<WalletContextKey, StoredMnemonic> values;
  final Map<WalletContextKey, String> writes = {};
  final List<WalletContextKey> deletes = [];
  Future<void> Function()? beforeRead;
  Future<void> Function(WalletContextKey context)? beforeWrite;

  FakeWalletIdentityStore({
    Map<WalletContextKey, StoredMnemonic>? values,
    this.beforeRead,
    this.beforeWrite,
  }) : values = Map.of(values ?? const {});

  @override
  Future<StoredMnemonic?> read(WalletContextKey context) async {
    await beforeRead?.call();
    return values[context];
  }

  @override
  Future<void> write(WalletContextKey context, String mnemonic) async {
    writes[context] = mnemonic;
    await beforeWrite?.call(context);
    values[context] = StoredMnemonic(
      mnemonic,
      StoredMnemonicSource.canonical,
    );
  }

  @override
  Future<void> delete(WalletContextKey context) async {
    deletes.add(context);
    values.remove(context);
  }
}

ProviderContainer identityContainer(FakeWalletIdentityStore store) {
  return ProviderContainer(
    overrides: [
      activeWalletContextKeyProvider.overrideWith(
        (ref) => ref.watch(testActiveContextProvider),
      ),
      walletIdentityStoreProvider.overrideWithValue(store),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('requireIdentity refuses a missing wallet without creating one',
      () async {
    final store = FakeWalletIdentityStore();
    final container = identityContainer(store);
    addTearDown(container.dispose);

    await expectLater(
      container.read(cryptoIdentityProvider.notifier).requireIdentity(),
      throwsA(isA<WalletIdentityUnavailableException>()),
    );
    expect(store.writes, isEmpty);
  });

  test('getOrCreateIdentity creates only inside the active context', () async {
    final store = FakeWalletIdentityStore();
    final container = identityContainer(store);
    addTearDown(container.dispose);

    final identity = await container
        .read(cryptoIdentityProvider.notifier)
        .getOrCreateIdentity();

    expect(identity.context, aliceContext);
    expect(identity.mnemonic.split(' '), hasLength(12));
    expect(store.writes.keys, [aliceContext]);
    expect(store.writes.containsKey(bobContext), isFalse);
  });

  test('legacy mnemonic migrates only after validation and derivation',
      () async {
    final store = FakeWalletIdentityStore(
      values: {
        aliceContext: const StoredMnemonic(
          validMnemonic,
          StoredMnemonicSource.legacy,
        ),
      },
    );
    final container = identityContainer(store);
    addTearDown(container.dispose);

    final identity =
        await container.read(cryptoIdentityProvider.notifier).requireIdentity();

    expect(identity.context, aliceContext);
    expect(store.writes[aliceContext], validMnemonic);
    expect(store.deletes, isEmpty);
  });

  test('invalid legacy mnemonic is rejected without canonical migration',
      () async {
    final store = FakeWalletIdentityStore(
      values: {
        aliceContext: const StoredMnemonic(
          'not a valid mnemonic',
          StoredMnemonicSource.legacy,
        ),
      },
    );
    final container = identityContainer(store);
    addTearDown(container.dispose);

    await expectLater(
      container.read(cryptoIdentityProvider.notifier).requireIdentity(),
      throwsArgumentError,
    );
    expect(store.writes, isEmpty);
  });

  test('late identity result cannot reactivate a previous account', () async {
    final gate = Completer<void>();
    final store = FakeWalletIdentityStore(
      values: {
        aliceContext: const StoredMnemonic(
          validMnemonic,
          StoredMnemonicSource.canonical,
        ),
      },
      beforeRead: () => gate.future,
    );
    final container = identityContainer(store);
    addTearDown(container.dispose);

    final operation =
        container.read(cryptoIdentityProvider.notifier).requireIdentity();
    container.read(testActiveContextProvider.notifier).state = bobContext;
    gate.complete();

    await expectLater(
      operation,
      throwsA(isA<StaleWalletContextException>()),
    );
    expect(container.read(cryptoIdentityProvider).valueOrNull, isNull);
    expect(store.writes.containsKey(bobContext), isFalse);
  });

  test('context change clears an already loaded in-memory identity', () async {
    final store = FakeWalletIdentityStore(
      values: {
        aliceContext: const StoredMnemonic(
          validMnemonic,
          StoredMnemonicSource.canonical,
        ),
      },
    );
    final container = identityContainer(store);
    addTearDown(container.dispose);

    await container.read(cryptoIdentityProvider.notifier).requireIdentity();
    expect(container.read(cryptoIdentityProvider).valueOrNull, isNotNull);

    container.read(testActiveContextProvider.notifier).state = bobContext;
    await container.pump();

    expect(container.read(cryptoIdentityProvider).valueOrNull, isNull);
  });

  test('restore writes only to its captured context and rejects stale success',
      () async {
    final writeStarted = Completer<void>();
    final releaseWrite = Completer<void>();
    final store = FakeWalletIdentityStore(
      beforeWrite: (context) async {
        writeStarted.complete();
        await releaseWrite.future;
      },
    );
    final container = identityContainer(store);
    addTearDown(container.dispose);

    final operation = container
        .read(cryptoIdentityProvider.notifier)
        .restoreFromMnemonic(mnemonic: validMnemonic);
    await writeStarted.future;
    container.read(testActiveContextProvider.notifier).state = bobContext;
    await container.pump();
    releaseWrite.complete();

    await expectLater(
      operation,
      throwsA(isA<StaleWalletContextException>()),
    );
    expect(store.writes.keys, [aliceContext]);
    expect(store.writes.containsKey(bobContext), isFalse);
  });

  test('deleteWalletKeys deletes only the active context', () async {
    final store = FakeWalletIdentityStore(
      values: {
        aliceContext: const StoredMnemonic(
          validMnemonic,
          StoredMnemonicSource.canonical,
        ),
        bobContext: const StoredMnemonic(
          validMnemonic,
          StoredMnemonicSource.canonical,
        ),
      },
    );
    final container = identityContainer(store);
    addTearDown(container.dispose);

    await container.read(cryptoIdentityProvider.notifier).deleteWalletKeys();

    expect(store.deletes, [aliceContext]);
    expect(store.values.containsKey(bobContext), isTrue);
  });
}
