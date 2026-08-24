import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// Native C function typedefs
typedef HanbovaCdkWalletCreateC = Int32 Function(
  Pointer<Utf8> mintUrl,
  Pointer<Utf8> dbPath,
  Pointer<Utf8> seedHex,
  Pointer<Pointer<Void>> outHandle,
);
typedef HanbovaCdkWalletCreateDart = int Function(
  Pointer<Utf8> mintUrl,
  Pointer<Utf8> dbPath,
  Pointer<Utf8> seedHex,
  Pointer<Pointer<Void>> outHandle,
);

typedef HanbovaCdkWalletGetBalanceC = Int32 Function(
  Pointer<Void> handle,
  Pointer<Uint64> outSpendable,
  Pointer<Uint64> outPending,
);
typedef HanbovaCdkWalletGetBalanceDart = int Function(
  Pointer<Void> handle,
  Pointer<Uint64> outSpendable,
  Pointer<Uint64> outPending,
);

typedef HanbovaCdkWalletMintQuoteC = Int32 Function(
  Pointer<Void> handle,
  Uint64 amountSats,
  Pointer<Pointer<Utf8>> outQuoteId,
  Pointer<Pointer<Utf8>> outInvoice,
);
typedef HanbovaCdkWalletMintQuoteDart = int Function(
  Pointer<Void> handle,
  int amountSats,
  Pointer<Pointer<Utf8>> outQuoteId,
  Pointer<Pointer<Utf8>> outInvoice,
);

typedef HanbovaCdkWalletMintC = Int32 Function(
  Pointer<Void> handle,
  Pointer<Utf8> quoteId,
  Pointer<Uint64> outMintedSats,
);
typedef HanbovaCdkWalletMintDart = int Function(
  Pointer<Void> handle,
  Pointer<Utf8> quoteId,
  Pointer<Uint64> outMintedSats,
);

typedef HanbovaCdkWalletSendLockedC = Int32 Function(
  Pointer<Void> handle,
  Uint64 amountSats,
  Pointer<Utf8> recipientPubkeyHex,
  Pointer<Utf8> refundPubkeyHex,
  Uint64 locktimeUnix,
  Pointer<Pointer<Utf8>> outToken,
);
typedef HanbovaCdkWalletSendLockedDart = int Function(
  Pointer<Void> handle,
  int amountSats,
  Pointer<Utf8> recipientPubkeyHex,
  Pointer<Utf8> refundPubkeyHex,
  int locktimeUnix,
  Pointer<Pointer<Utf8>> outToken,
);

typedef HanbovaCdkWalletReceiveC = Int32 Function(
  Pointer<Void> handle,
  Pointer<Utf8> tokenStr,
  Pointer<Utf8> p2pkPrivkeyHex,
  Pointer<Uint64> outReceivedSats,
);
typedef HanbovaCdkWalletReceiveDart = int Function(
  Pointer<Void> handle,
  Pointer<Utf8> tokenStr,
  Pointer<Utf8> p2pkPrivkeyHex,
  Pointer<Uint64> outReceivedSats,
);

typedef HanbovaCdkCheckTokenStateC = Int32 Function(
  Pointer<Void> handle,
  Pointer<Utf8> tokenStr,
  Pointer<Int32> outState,
);
typedef HanbovaCdkCheckTokenStateDart = int Function(
  Pointer<Void> handle,
  Pointer<Utf8> tokenStr,
  Pointer<Int32> outState,
);

typedef HanbovaCdkWalletFreeC = Void Function(Pointer<Void> handle);
typedef HanbovaCdkWalletFreeDart = void Function(Pointer<Void> handle);

typedef HanbovaCdkGetLastErrorC = Pointer<Utf8> Function();
typedef HanbovaCdkGetLastErrorDart = Pointer<Utf8> Function();

typedef HanbovaCdkFreeStringC = Void Function(Pointer<Utf8> s);
typedef HanbovaCdkFreeStringDart = void Function(Pointer<Utf8> s);

/// Thin FFI bridge over official CDK library (`crates/hanbova-cdk-ffi`).
class CdkFfiBindings {
  static CdkFfiBindings? _instance;
  late final DynamicLibrary? _dylib;

  final HanbovaCdkWalletCreateDart walletCreate;
  final HanbovaCdkWalletGetBalanceDart walletGetBalance;
  final HanbovaCdkWalletMintQuoteDart walletMintQuote;
  final HanbovaCdkWalletMintDart walletMint;
  final HanbovaCdkWalletSendLockedDart walletSendLocked;
  final HanbovaCdkWalletReceiveDart walletReceive;
  final HanbovaCdkCheckTokenStateDart checkTokenState;
  final HanbovaCdkWalletFreeDart walletFree;
  final HanbovaCdkGetLastErrorDart getLastError;
  final HanbovaCdkFreeStringDart freeString;

  DynamicLibrary? get dylib => _dylib;

  CdkFfiBindings.custom({
    required this.walletCreate,
    required this.walletGetBalance,
    required this.walletMintQuote,
    required this.walletMint,
    required this.walletSendLocked,
    required this.walletReceive,
    required this.checkTokenState,
    required this.walletFree,
    required this.getLastError,
    required this.freeString,
    DynamicLibrary? dylib,
  }) : _dylib = dylib;

  CdkFfiBindings._(DynamicLibrary dylib)
      : _dylib = dylib,
        walletCreate = dylib
            .lookup<NativeFunction<HanbovaCdkWalletCreateC>>('hanbova_cdk_wallet_create')
            .asFunction(),
        walletGetBalance = dylib
            .lookup<NativeFunction<HanbovaCdkWalletGetBalanceC>>('hanbova_cdk_wallet_get_balance')
            .asFunction(),
        walletMintQuote = dylib
            .lookup<NativeFunction<HanbovaCdkWalletMintQuoteC>>('hanbova_cdk_mint_quote')
            .asFunction(),
        walletMint = dylib
            .lookup<NativeFunction<HanbovaCdkWalletMintC>>('hanbova_cdk_mint')
            .asFunction(),
        walletSendLocked = dylib
            .lookup<NativeFunction<HanbovaCdkWalletSendLockedC>>('hanbova_cdk_prepare_p2pk_send')
            .asFunction(),
        walletReceive = dylib
            .lookup<NativeFunction<HanbovaCdkWalletReceiveC>>('hanbova_cdk_receive_p2pk')
            .asFunction(),
        checkTokenState = dylib
            .lookup<NativeFunction<HanbovaCdkCheckTokenStateC>>('hanbova_cdk_check_token_state')
            .asFunction(),
        walletFree = dylib
            .lookup<NativeFunction<HanbovaCdkWalletFreeC>>('hanbova_cdk_wallet_free')
            .asFunction(),
        getLastError = dylib
            .lookup<NativeFunction<HanbovaCdkGetLastErrorC>>('hanbova_cdk_get_last_error')
            .asFunction(),
        freeString = dylib
            .lookup<NativeFunction<HanbovaCdkFreeStringC>>('hanbova_cdk_free_string')
            .asFunction();

  static CdkFfiBindings get instance {
    _instance ??= CdkFfiBindings._(_openLibrary());
    return _instance!;
  }

  static DynamicLibrary _openLibrary() {
    if (Platform.isMacOS) {
      final possiblePaths = [
        '../hanbova-backend/target/release/libhanbova_cdk_ffi.dylib',
        '../hanbova-backend/target/debug/libhanbova_cdk_ffi.dylib',
        '../../hanbova-backend/target/release/libhanbova_cdk_ffi.dylib',
        'libhanbova_cdk_ffi.dylib',
      ];
      for (final p in possiblePaths) {
        if (File(p).existsSync()) {
          return DynamicLibrary.open(File(p).absolute.path);
        }
      }
      try {
        return DynamicLibrary.process();
      } catch (_) {
        return DynamicLibrary.open('libhanbova_cdk_ffi.dylib');
      }
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    } else if (Platform.isAndroid) {
      return DynamicLibrary.open('libhanbova_cdk_ffi.so');
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libhanbova_cdk_ffi.so');
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('hanbova_cdk_ffi.dll');
    }
    return DynamicLibrary.process();
  }

  String? retrieveLastError() {
    final ptr = getLastError();
    if (ptr.address == 0) return null;
    final msg = ptr.toDartString();
    freeString(ptr);
    return msg;
  }
}
