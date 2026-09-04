import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/sync/wallet_sync_coordinator.dart';

void main() {
  test('coordinator never overlaps sync requests', () async {
    final gate = Completer<void>();
    var calls = 0;
    final coordinator = WalletSyncCoordinator(
      runSync: () async {
        calls++;
        await gate.future;
      },
    );

    final first = coordinator.syncNow();
    final second = coordinator.syncNow();

    expect(calls, 1);
    expect(identical(first, second), isTrue);

    gate.complete();
    await Future.wait([first, second]);
    coordinator.dispose();
  });

  test('start defers the initial sync until provider construction completes',
      () async {
    var calls = 0;
    final coordinator = WalletSyncCoordinator(
      runSync: () async {
        calls++;
      },
    );

    coordinator.start();
    expect(calls, 0);

    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
    coordinator.dispose();
  });

  test('failed sync backs off and a later success restores the interval',
      () async {
    var shouldFail = true;
    final coordinator = WalletSyncCoordinator(
      runSync: () async {
        if (shouldFail) throw StateError('offline');
      },
    );

    await expectLater(coordinator.syncNow(), throwsStateError);
    expect(coordinator.state.hasFailure, isTrue);
    expect(coordinator.currentInterval, const Duration(seconds: 60));

    shouldFail = false;
    await coordinator.syncNow();
    expect(coordinator.state.hasFailure, isFalse);
    expect(coordinator.currentInterval, const Duration(seconds: 15));
    coordinator.dispose();
  });
}
