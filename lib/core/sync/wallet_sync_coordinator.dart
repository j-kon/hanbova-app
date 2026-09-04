import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/protected/data/protected_message_service.dart';
import '../../features/protected_send/data/payment_intent_repository.dart';
import '../../features/transactions/presentation/transactions_provider.dart';
import '../crypto/crypto_identity_service.dart';
import '../network/network_environment.dart';
import '../networking/api_client.dart';
import '../notifications/in_app_notification.dart';
import '../utils/formatters.dart';
import '../wallet/wallet_context.dart';

@immutable
final class WalletSyncState {
  final bool isSyncing;
  final bool hasFailure;
  final DateTime? lastSuccessfulSyncAt;

  const WalletSyncState({
    this.isSyncing = false,
    this.hasFailure = false,
    this.lastSuccessfulSyncAt,
  });

  WalletSyncState copyWith({
    bool? isSyncing,
    bool? hasFailure,
    DateTime? lastSuccessfulSyncAt,
  }) {
    return WalletSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      hasFailure: hasFailure ?? this.hasFailure,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
    );
  }
}

final class WalletSyncCoordinator extends ChangeNotifier
    with WidgetsBindingObserver {
  WalletSyncCoordinator({
    required Future<void> Function() runSync,
    this.successInterval = const Duration(seconds: 15),
    this.failureInterval = const Duration(seconds: 60),
  }) : _runSync = runSync;

  final Future<void> Function() _runSync;
  final Duration successInterval;
  final Duration failureInterval;

  WalletSyncState _state = const WalletSyncState();
  WalletSyncState get state => _state;

  Future<void>? _inFlight;
  Timer? _timer;
  bool _started = false;
  bool _isResumed = true;
  Duration _currentInterval = const Duration(seconds: 15);

  Duration get currentInterval => _currentInterval;

  Future<void> syncNow() {
    final active = _inFlight;
    if (active != null) return active;

    final operation = _performSync();
    _inFlight = operation;
    return operation;
  }

  Future<void> _performSync() async {
    _timer?.cancel();
    _state = _state.copyWith(isSyncing: true);
    notifyListeners();
    try {
      await _runSync();
      _currentInterval = successInterval;
      _state = WalletSyncState(
        isSyncing: false,
        lastSuccessfulSyncAt: DateTime.now(),
      );
    } catch (_) {
      _currentInterval = failureInterval;
      _state = _state.copyWith(isSyncing: false, hasFailure: true);
      rethrow;
    } finally {
      _inFlight = null;
      if (_started && _isResumed) _scheduleNext();
      notifyListeners();
    }
  }

  void start() {
    if (_started) return;
    _started = true;
    unawaited(syncNow().catchError((_) {}));
  }

  void _scheduleNext() {
    _timer?.cancel();
    _timer = Timer(_currentInterval, () {
      unawaited(syncNow().catchError((_) {}));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isResumed = true;
        if (_started) unawaited(syncNow().catchError((_) {}));
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _isResumed = false;
        _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _started = false;
    _timer?.cancel();
    super.dispose();
  }
}

final class WalletSyncContextChanged implements Exception {
  const WalletSyncContextChanged();
}

final class WalletSyncFailed implements Exception {
  const WalletSyncFailed();
}

final walletSyncCoordinatorProvider = Provider<WalletSyncCoordinator?>((ref) {
  final context = ref.watch(activeWalletContextKeyProvider);
  if (context == null) return null;

  final auth = ref.read(authProvider);
  final config = ref.read(activeNetworkConfigProvider);
  final cryptoIdentity = ref.read(cryptoIdentityProvider.notifier);
  final apiClient = ref.read(apiClientProvider);
  final messageService = ref.read(protectedMessageServiceProvider);
  final intentRepository = ref.read(paymentIntentRepositoryProvider);
  final transactions = ref.read(transactionsProvider.notifier);
  final notifications = ref.read(inAppNotificationProvider.notifier);
  var isActive = true;
  var keysPublished = false;

  bool contextIsCurrent() {
    if (!isActive) return false;
    return ref.read(activeWalletContextKeyProvider) == context;
  }

  Future<void> runWalletSync() async {
    if (!contextIsCurrent() ||
        auth.user?.id != context.userId ||
        config.network != context.network ||
        config.storagePrefix != context.storagePrefix) {
      throw const WalletSyncContextChanged();
    }

    await transactions.reconcile(sync: () async {
      if (!keysPublished) {
        final identity = await cryptoIdentity.requireIdentity();
        if (!contextIsCurrent() || identity.context != context) {
          throw const WalletSyncContextChanged();
        }
        await cryptoIdentity.publishPublicKeys(
          apiClient: apiClient,
          identity: identity,
          walletEnvironment: context.storagePrefix,
        );
        keysPublished = true;
      }

      final inbox = await messageService.getInbox();
      if (!contextIsCurrent()) throw const WalletSyncContextChanged();
      final newTransactions = await transactions.syncIncomingMessages(
        inbox: inbox,
        getIntentDetails: intentRepository.getPaymentIntent,
      );
      if (newTransactions.isNotEmpty) {
        final newest = newTransactions.first;
        notifications.show(
          title: 'Protected Payment Received!',
          message:
              '${Formatters.formatSats(newest.amountSats)} waiting from ${newest.recipientOrSender}',
          icon: Icons.shield_outlined,
          type: InAppNotificationType.incoming,
        );
      }

      final intents = await intentRepository.getPaymentIntents();
      if (!contextIsCurrent()) throw const WalletSyncContextChanged();
      await transactions.syncPaymentIntents(
        intents: intents,
        currentUserId: context.userId,
        currentUsername: auth.user!.username,
      );
    });

    if (transactions.isStale) throw const WalletSyncFailed();
  }

  final coordinator = WalletSyncCoordinator(runSync: runWalletSync);
  WidgetsBinding.instance.addObserver(coordinator);
  ref.onDispose(() {
    isActive = false;
    WidgetsBinding.instance.removeObserver(coordinator);
    coordinator.dispose();
  });
  coordinator.start();
  return coordinator;
});
