import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';
import '../crypto/secp256k1_service.dart';
import '../network/network_environment.dart';
import 'cashu_wallet_models.dart';
import 'cashu_wallet_storage.dart';
import 'cdk_ffi_bindings.dart';

abstract class CashuWalletService {
  Future<CashuWalletBalance> getBalance();
  Future<int> mintTestTokens(int amountSats);
  Future<String> createProtectedSend({
    required int amountSats,
    required String recipientPubkey,
    required DateTime locktime,
    required String paymentId,
  });
  Future<int> claimProtectedPayment({
    required String token,
    required String paymentId,
  });
  Future<int> refundProtectedPayment({
    required String paymentId,
  });
  Future<TokenState> checkTokenState(String token);
  void dispose();
}

/// Genuine client-side Cashu wallet implementation powered by official CDK via C-FFI.
class CdkCashuWalletServiceImpl implements CashuWalletService {
  final String userId;
  final HanbovaNetwork network;
  final String _walletSeedHex;
  final String _p2pkPrivateKeyHex;
  final String _p2pkPublicKeyHex;
  final String _mintUrl;
  final String? _dbPath;
  final CashuWalletStorage _storage;
  final CdkFfiBindings _ffi;

  Pointer<Void>? _handle;

  CdkCashuWalletServiceImpl({
    required this.userId,
    required this.network,
    required String walletSeedHex,
    required String p2pkPrivateKeyHex,
    required String p2pkPublicKeyHex,
    String? mintUrl,
    String? dbPath,
    CashuWalletStorage? storage,
    CdkFfiBindings? ffi,
  })  : _walletSeedHex = walletSeedHex,
        _p2pkPrivateKeyHex = p2pkPrivateKeyHex,
        _p2pkPublicKeyHex = p2pkPublicKeyHex,
        _mintUrl = mintUrl ?? NetworkConfig.fromNetwork(network).defaultMintUrl,
        _dbPath = dbPath,
        _storage = storage ?? CashuWalletStorage(),
        _ffi = ffi ?? CdkFfiBindings.instance;

  String get p2pkPrivateKeyHex => _p2pkPrivateKeyHex;
  String get p2pkPublicKeyHex => _p2pkPublicKeyHex;

  Future<String> _getDefaultDbPath() async {
    try {
      final dir = await getApplicationSupportDirectory();
      return '${dir.path}/hanbova_cdk_${userId}_${network.name}';
    } catch (_) {
      return '${Directory.systemTemp.path}/hanbova_cdk_${userId}_${network.name}';
    }
  }

  Future<Pointer<Void>> _ensureHandle() async {
    if (_handle != null && _handle!.address != 0) {
      return _handle!;
    }
    final dbDir = _dbPath ?? await _getDefaultDbPath();
    final mintUrlPtr = _mintUrl.toNativeUtf8();
    final dbPathPtr = dbDir.toNativeUtf8();
    final seedHexPtr = _walletSeedHex.toNativeUtf8();
    final outHandle = calloc<Pointer<Void>>();

    try {
      final rc = _ffi.walletCreate(mintUrlPtr, dbPathPtr, seedHexPtr, outHandle);
      if (rc != 0) {
        final err = _ffi.retrieveLastError() ?? 'Unknown error (code $rc)';
        throw StateError('Failed to initialize CDK wallet: $err');
      }
      _handle = outHandle.value;
      return _handle!;
    } finally {
      calloc.free(mintUrlPtr);
      calloc.free(dbPathPtr);
      calloc.free(seedHexPtr);
      calloc.free(outHandle);
    }
  }

  @override
  Future<CashuWalletBalance> getBalance() async {
    final handle = await _ensureHandle();
    final outSpendable = calloc<Uint64>();
    final outPending = calloc<Uint64>();

    try {
      final rc = _ffi.walletGetBalance(handle, outSpendable, outPending);
      if (rc != 0) {
        final err = _ffi.retrieveLastError() ?? 'Unknown error (code $rc)';
        throw StateError('Failed to retrieve CDK wallet balance: $err');
      }

      final spendable = outSpendable.value;
      final pending = outPending.value;

      return CashuWalletBalance(
        spendableSats: spendable,
        lockedEscrowSats: pending,
      );
    } finally {
      calloc.free(outSpendable);
      calloc.free(outPending);
    }
  }

  @override
  Future<int> mintTestTokens(int amountSats) async {
    if (amountSats <= 0) {
      throw ArgumentError('Amount must be greater than zero');
    }
    final handle = await _ensureHandle();

    final outQuoteId = calloc<Pointer<Utf8>>();
    final outInvoice = calloc<Pointer<Utf8>>();

    String quoteId;
    try {
      final rcQuote = _ffi.walletMintQuote(handle, amountSats, outQuoteId, outInvoice);
      if (rcQuote != 0) {
        final err = _ffi.retrieveLastError() ?? 'Unknown error (code $rcQuote)';
        throw StateError('Failed to request mint quote from mint: $err');
      }
      quoteId = outQuoteId.value.toDartString();
      _ffi.freeString(outQuoteId.value);
      if (outInvoice.value.address != 0) {
        _ffi.freeString(outInvoice.value);
      }
    } finally {
      calloc.free(outQuoteId);
      calloc.free(outInvoice);
    }

    final quoteIdPtr = quoteId.toNativeUtf8();
    final outMinted = calloc<Uint64>();

    try {
      final rcMint = _ffi.walletMint(handle, quoteIdPtr, outMinted);
      if (rcMint != 0) {
        final err = _ffi.retrieveLastError() ?? 'Unknown error (code $rcMint)';
        throw StateError('Failed to execute mint swap with mint: $err');
      }
      return outMinted.value;
    } finally {
      calloc.free(quoteIdPtr);
      calloc.free(outMinted);
    }
  }

  @override
  Future<String> createProtectedSend({
    required int amountSats,
    required String recipientPubkey,
    required DateTime locktime,
    required String paymentId,
  }) async {
    if (amountSats <= 0) {
      throw ArgumentError('Amount must be greater than zero');
    }
    if (!Secp256k1Service.isValidCompressedPublicKeyHex(recipientPubkey)) {
      throw ArgumentError('Invalid recipient secp256k1 compressed public key');
    }

    // Verify balance strictly without magical auto-funding
    final balance = await getBalance();
    if (balance.spendableSats < amountSats) {
      throw StateError(
        'Insufficient balance (${balance.spendableSats} sats available, $amountSats sats required). Please fund your test wallet.',
      );
    }

    // Client-side sender refund keypair
    final refundPrivHex = Secp256k1Service.generatePrivateKeyHex();
    final refundPubHex = Secp256k1Service.getCompressedPublicKeyHex(refundPrivHex);

    final handle = await _ensureHandle();
    final recPubPtr = recipientPubkey.toNativeUtf8();
    final refPubPtr = refundPubHex.toNativeUtf8();
    final locktimeUnix = locktime.millisecondsSinceEpoch ~/ 1000;
    final outToken = calloc<Pointer<Utf8>>();

    String tokenStr;
    try {
      final rc = _ffi.walletSendLocked(
        handle,
        amountSats,
        recPubPtr,
        refPubPtr,
        locktimeUnix,
        outToken,
      );
      if (rc != 0) {
        final err = _ffi.retrieveLastError() ?? 'Unknown error (code $rc)';
        throw StateError('Failed to prepare locked send token: $err');
      }
      tokenStr = outToken.value.toDartString();
      _ffi.freeString(outToken.value);
    } finally {
      calloc.free(recPubPtr);
      calloc.free(refPubPtr);
      calloc.free(outToken);
    }

    // Save escrow record locally (retaining Alice's refund key strictly on Alice's device)
    final escrow = ProtectedEscrowRecord(
      paymentId: paymentId,
      token: tokenStr,
      amountSats: amountSats,
      recipientPubkey: recipientPubkey,
      refundPubkey: refundPubHex,
      refundPrivkeyHex: refundPrivHex,
      locktime: locktime,
      isOutgoing: true,
      status: 'locked',
      createdAt: DateTime.now(),
    );
    await _storage.saveEscrowRecord(userId, network, escrow);

    return tokenStr;
  }

  @override
  Future<int> claimProtectedPayment({
    required String token,
    required String paymentId,
  }) async {
    if (token.trim().isEmpty) {
      throw ArgumentError('Token cannot be empty');
    }
    final handle = await _ensureHandle();

    final tokenPtr = token.toNativeUtf8();
    final p2pkPrivPtr = _p2pkPrivateKeyHex.toNativeUtf8();
    final outReceived = calloc<Uint64>();

    int receivedSats;
    try {
      final rc = _ffi.walletReceive(handle, tokenPtr, p2pkPrivPtr, outReceived);
      if (rc != 0) {
        final err = _ffi.retrieveLastError() ?? 'Unknown error (code $rc)';
        throw StateError('Failed to claim NUT-11 locked token: $err');
      }
      receivedSats = outReceived.value;
    } finally {
      calloc.free(tokenPtr);
      calloc.free(p2pkPrivPtr);
      calloc.free(outReceived);
    }

    final escrow = ProtectedEscrowRecord(
      paymentId: paymentId,
      token: token,
      amountSats: receivedSats,
      recipientPubkey: _p2pkPublicKeyHex,
      locktime: DateTime.now(),
      isOutgoing: false,
      status: 'claimed',
      createdAt: DateTime.now(),
    );
    await _storage.saveEscrowRecord(userId, network, escrow);

    return receivedSats;
  }

  @override
  Future<int> refundProtectedPayment({
    required String paymentId,
  }) async {
    final escrows = await _storage.loadEscrowRecords(userId, network);
    final escrow = escrows.firstWhere(
      (e) => e.paymentId == paymentId && e.isOutgoing,
      orElse: () => throw StateError('Escrow record for payment $paymentId not found'),
    );

    if (DateTime.now().isBefore(escrow.locktime)) {
      throw StateError(
        'Cannot refund: Locktime has not expired yet (${escrow.locktime.toIso8601String()})',
      );
    }

    if (escrow.refundPrivkeyHex == null) {
      throw StateError('Cannot refund: Refund private key not found on this device');
    }

    final handle = await _ensureHandle();
    final tokenPtr = escrow.token.toNativeUtf8();
    final refundPrivPtr = escrow.refundPrivkeyHex!.toNativeUtf8();
    final outReceived = calloc<Uint64>();

    int receivedSats;
    try {
      final rc = _ffi.walletReceive(handle, tokenPtr, refundPrivPtr, outReceived);
      if (rc != 0) {
        final err = _ffi.retrieveLastError() ?? 'Unknown error (code $rc)';
        throw StateError('Failed to execute post-locktime refund: $err');
      }
      receivedSats = outReceived.value;
    } finally {
      calloc.free(tokenPtr);
      calloc.free(refundPrivPtr);
      calloc.free(outReceived);
    }

    await _storage.saveEscrowRecord(userId, network, escrow.copyWith(status: 'refunded'));
    return receivedSats;
  }

  @override
  Future<TokenState> checkTokenState(String token) async {
    if (token.trim().isEmpty) return TokenState.unknown;
    final handle = await _ensureHandle();
    final tokenPtr = token.toNativeUtf8();
    final outState = calloc<Int32>();

    try {
      final rc = _ffi.checkTokenState(handle, tokenPtr, outState);
      if (rc != 0) {
        return TokenState.unknown;
      }
      switch (outState.value) {
        case 0:
          return TokenState.unspent;
        case 1:
          return TokenState.pending;
        case 2:
          return TokenState.spent;
        default:
          return TokenState.unknown;
      }
    } finally {
      calloc.free(tokenPtr);
      calloc.free(outState);
    }
  }

  @override
  void dispose() {
    if (_handle != null && _handle!.address != 0) {
      _ffi.walletFree(_handle!);
      _handle = null;
    }
  }
}
