import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cashu/cashu_wallet_models.dart';
import '../../../core/cashu/cashu_wallet_provider.dart';
import '../../../core/cashu/cashu_wallet_service.dart';
import '../../../core/cashu/wallet_policy.dart';
import '../../../core/errors/user_facing_error.dart';
import '../../../core/network/network_environment.dart';

enum DepositPhase {
  idle,
  loading,
  ready,
  checking,
  unpaid,
  expired,
  issued,
  minted,
  failed,
}

@immutable
final class DepositState {
  final DepositPhase phase;
  final int? amountSats;
  final MintQuoteResult? quote;
  final int? mintedSats;
  final String? message;

  const DepositState({
    this.phase = DepositPhase.idle,
    this.amountSats,
    this.quote,
    this.mintedSats,
    this.message,
  });
}

final class DepositController extends ChangeNotifier {
  DepositController({
    required CashuWalletService? wallet,
    required WalletPolicy policy,
    required Future<CashuWalletBalance> Function() balance,
  })  : _wallet = wallet,
        _policy = policy,
        _balance = balance;

  final CashuWalletService? _wallet;
  final WalletPolicy _policy;
  final Future<CashuWalletBalance> Function() _balance;

  DepositState _state = const DepositState();
  DepositState get state => _state;
  bool get isAvailable => _wallet != null;

  int _generation = 0;

  Future<void> initialize() async {}

  Future<void> createQuote(int amountSats) async {
    final generation = ++_generation;
    final wallet = _wallet;
    if (wallet == null) {
      _setState(const DepositState(
        phase: DepositPhase.failed,
        message: 'Wallet unavailable. Sign in again and retry.',
      ));
      throw StateError('Wallet unavailable.');
    }

    try {
      final currentBalance = await _balance();
      _policy.validateDeposit(
        amountSats: amountSats,
        currentBalanceSats: currentBalance.totalSats,
      );
      if (generation == _generation) {
        _setState(DepositState(
          phase: DepositPhase.loading,
          amountSats: amountSats,
        ));
      }

      final quote = await wallet.createMintQuote(amountSats);
      if (generation != _generation) return;
      if (quote.amountSats != amountSats) {
        throw StateError('Mint quote amount does not match the request.');
      }
      _setState(DepositState(
        phase: DepositPhase.ready,
        amountSats: amountSats,
        quote: quote,
      ));
    } catch (error) {
      if (generation == _generation) {
        _setState(DepositState(
          phase: DepositPhase.failed,
          amountSats: amountSats,
          message: UserFacingErrorMapper.from(error).message,
        ));
      }
      rethrow;
    }
  }

  Future<int?> checkAndMint() async {
    if (_state.phase == DepositPhase.minted) return _state.mintedSats;
    if (_state.phase == DepositPhase.issued) return null;

    final wallet = _wallet;
    final quote = _state.quote;
    final amountSats = _state.amountSats;
    if (wallet == null || quote == null || amountSats == null) {
      throw StateError('No active mint quote to check.');
    }
    final generation = _generation;
    _setState(DepositState(
      phase: DepositPhase.checking,
      amountSats: amountSats,
      quote: quote,
    ));

    try {
      final status = await wallet.checkMintQuoteStatus(quote.quoteId);
      if (generation != _generation) return null;
      switch (status.status) {
        case MintQuoteStatus.unpaid:
        case MintQuoteStatus.unknown:
          _setState(DepositState(
            phase: DepositPhase.unpaid,
            amountSats: amountSats,
            quote: quote,
            message: 'Invoice is still unpaid.',
          ));
          return null;
        case MintQuoteStatus.expired:
          _setState(DepositState(
            phase: DepositPhase.expired,
            amountSats: amountSats,
            quote: quote,
            message: 'This invoice has expired. Create a new one.',
          ));
          return null;
        case MintQuoteStatus.issued:
          _setState(DepositState(
            phase: DepositPhase.issued,
            amountSats: amountSats,
            quote: quote,
            message: 'This invoice has already been added to your wallet.',
          ));
          return null;
        case MintQuoteStatus.paid:
          final currentBalance = await _balance();
          _policy.validateMint(
            amountSats: amountSats,
            currentBalance: currentBalance,
          );
          if (generation != _generation) return null;
          final minted = await wallet.mintQuote(quote.quoteId);
          if (generation != _generation) return null;
          _setState(DepositState(
            phase: DepositPhase.minted,
            amountSats: amountSats,
            quote: quote,
            mintedSats: minted,
            message: 'Payment confirmed and added to your wallet.',
          ));
          return minted;
      }
    } catch (error) {
      if (generation == _generation) {
        _setState(DepositState(
          phase: DepositPhase.failed,
          amountSats: amountSats,
          quote: quote,
          message: UserFacingErrorMapper.from(error).message,
        ));
      }
      rethrow;
    }
  }

  void reset() {
    _generation++;
    _setState(const DepositState());
  }

  void _setState(DepositState value) {
    _state = value;
    notifyListeners();
  }
}

final depositControllerProvider =
    ChangeNotifierProvider.autoDispose<DepositController>((ref) {
  final config = ref.watch(activeNetworkConfigProvider);
  return DepositController(
    wallet: ref.watch(cashuWalletServiceProvider),
    policy: WalletPolicy(config),
    balance: () => ref.read(cashuBalanceProvider.future),
  );
});
