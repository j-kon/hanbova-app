import '../../../core/network/network_environment.dart';

final class InvalidLightningRequest implements Exception {
  final String message;

  const InvalidLightningRequest(this.message);

  @override
  String toString() => message;
}

abstract final class LightningRequestParser {
  static String parse(String raw, HanbovaNetwork network) {
    var value = raw.trim().toLowerCase();
    if (value.startsWith('lightning:')) {
      value = value.substring('lightning:'.length);
    }
    if (value.isEmpty || value.contains(RegExp(r'\s'))) {
      throw const InvalidLightningRequest('Enter a valid Lightning invoice.');
    }

    final expectedPrefix = switch (network) {
      HanbovaNetwork.local => 'lnbcrt1',
      HanbovaNetwork.cashuTest => 'lntb1',
      HanbovaNetwork.mainnet => 'lnbc1',
    };
    if (!value.startsWith(expectedPrefix)) {
      throw const InvalidLightningRequest(
        'This invoice belongs to a different Bitcoin network.',
      );
    }
    return value;
  }
}
