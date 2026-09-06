import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pointycastle/digests/sha256.dart';

import '../../../core/cashu/cashu_wallet_models.dart';
import '../../../core/cashu/cashu_wallet_provider.dart';
import '../../../core/cashu/cashu_wallet_service.dart';
import '../../../core/cashu/wallet_policy.dart';
import '../../../core/errors/user_facing_error.dart';
import '../../../core/network/network_environment.dart';
import '../../../core/wallet/wallet_context.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transactions_provider.dart';
import 'lightning_request_parser.dart';

enum InstantSendPhase { idle, preparing, ready, paying, paid, failed }

@immutable
final class InstantSendQuote {
  final WalletContextKey walletContext;
  final String invoice;
  final String invoiceFingerprint;
  final MeltQuoteResult quote;
  final String networkLabel;

  const InstantSendQuote({
    required this.walletContext,
    required this.invoice,
    required this.invoiceFingerprint,
    required this.quote,
    required this.networkLabel,
  });

  int get amountSats => quote.amountSats;
  int get feeReserveSats => quote.feeReserveSats;
  int get totalSats => quote.totalRequiredSats;
}

@immutable
final class InstantSendState {
  final InstantSendPhase phase;
  final InstantSendQuote? review;
  final String? message;

  const InstantSendState({
    this.phase = InstantSendPhase.idle,
    this.review,
    this.message,
  });
}

final class InstantSendController extends ChangeNotifier {
  InstantSendController({
    required CashuWalletService? wallet,
    required WalletPolicy policy,
    required WalletContextKey? Function() activeContext,
    required Future<void> Function(TransactionModel transaction) persist,
    String? networkLabel,
  })  : _wallet = wallet,
        _policy = policy,
        _activeContext = activeContext,
        _persist = persist,
        _networkLabel = networkLabel;

  final CashuWalletService? _wallet;
  final WalletPolicy _policy;
  final WalletContextKey? Function() _activeContext;
  final Future<void> Function(TransactionModel transaction) _persist;
  final String? _networkLabel;

  InstantSendState _state = const InstantSendState();
  InstantSendState get state => _state;
  Future<MeltExecutionResult>? _confirmInFlight;
  final Map<String, MeltExecutionResult> _completed = {};

  Future<InstantSendQuote> prepare(String rawRequest) async {
    final wallet = _wallet;
    final context = _activeContext();
    if (wallet == null || context == null) {
      throw StateError('Wallet unavailable. Sign in again and retry.');
    }
    _setState(const InstantSendState(phase: InstantSendPhase.preparing));

    try {
      final invoice = LightningRequestParser.parse(rawRequest, context.network);
      final quote = await wallet.createMeltQuote(invoice);
      if (_activeContext() != context) {
        throw StateError('The active wallet context changed.');
      }
      if (quote.amountSats <= 0) {
        throw StateError('Amountless Lightning invoices are not supported.');
      }
      _policy.validateSend(amountSats: quote.amountSats);
      final review = InstantSendQuote(
        walletContext: context,
        invoice: invoice,
        invoiceFingerprint: _fingerprint(invoice),
        quote: quote,
        networkLabel: _networkLabel ?? context.network.name,
      );
      _setState(InstantSendState(
        phase: InstantSendPhase.ready,
        review: review,
      ));
      return review;
    } catch (error) {
      _setState(InstantSendState(
        phase: InstantSendPhase.failed,
        message: UserFacingErrorMapper.from(error).message,
      ));
      rethrow;
    }
  }

  Future<MeltExecutionResult> confirm(InstantSendQuote review) {
    final inFlight = _confirmInFlight;
    if (inFlight != null) return inFlight;
    final operation = _confirm(review);
    _confirmInFlight = operation;
    return operation;
  }

  Future<MeltExecutionResult> _confirm(InstantSendQuote review) async {
    try {
      final wallet = _wallet;
      if (wallet == null || _activeContext() != review.walletContext) {
        throw StateError('The active wallet context changed.');
      }
      if (!identical(_state.review, review)) {
        throw StateError('Prepare this invoice again before confirming.');
      }
      _policy.validateSend(amountSats: review.amountSats);
      _setState(InstantSendState(
        phase: InstantSendPhase.paying,
        review: review,
      ));

      final existing = _completed[review.quote.quoteId];
      final result =
          existing ?? await wallet.payMeltQuote(review.quote.quoteId);
      if (!result.isPaid) {
        throw StateError('The Lightning payment was not completed.');
      }
      _completed[review.quote.quoteId] = result;
      await _persist(
        TransactionModel(
          id: 'ln_pay_${review.quote.quoteId}',
          type: TransactionType.instantSend,
          status: TransactionStatus.completed,
          amountSats: review.amountSats,
          feeSats: review.feeReserveSats,
          recipientOrSender: review.invoiceFingerprint,
          description:
              'Lightning payment (maximum fee ${review.feeReserveSats} sats)',
          createdAt: DateTime.now(),
        ),
      );
      _setState(InstantSendState(
        phase: InstantSendPhase.paid,
        review: review,
      ));
      return result;
    } catch (error) {
      _setState(InstantSendState(
        phase: InstantSendPhase.failed,
        review: review,
        message: UserFacingErrorMapper.from(error).message,
      ));
      rethrow;
    } finally {
      _confirmInFlight = null;
    }
  }

  void reset() => _setState(const InstantSendState());

  static String _fingerprint(String invoice) {
    final digest = SHA256Digest().process(
      Uint8List.fromList(utf8.encode(invoice)),
    );
    return digest
        .take(8)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  void _setState(InstantSendState value) {
    _state = value;
    notifyListeners();
  }
}

final instantSendControllerProvider =
    ChangeNotifierProvider.autoDispose<InstantSendController>((ref) {
  final config = ref.watch(activeNetworkConfigProvider);
  return InstantSendController(
    wallet: ref.watch(cashuWalletServiceProvider),
    policy: WalletPolicy(config),
    activeContext: () => ref.read(activeWalletContextKeyProvider),
    persist: ref.read(transactionsProvider.notifier).addTransaction,
    networkLabel: config.displayName,
  );
});
