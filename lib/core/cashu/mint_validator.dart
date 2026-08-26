import 'dart:convert';
import 'package:http/http.dart' as http;

class MintValidationResult {
  final bool isValid;
  final bool nut11Supported;
  final bool nut04Supported;
  final bool nut07Supported;
  final bool nut10Supported;
  final String? mintName;
  final String? description;
  final String? motd;
  final String? errorMessage;

  const MintValidationResult({
    required this.isValid,
    required this.nut11Supported,
    this.nut04Supported = true,
    this.nut07Supported = true,
    this.nut10Supported = true,
    this.mintName,
    this.description,
    this.motd,
    this.errorMessage,
  });

  bool get isFullySupported =>
      isValid &&
      nut11Supported &&
      nut04Supported &&
      nut07Supported &&
      nut10Supported;
}

class MintValidator {
  final http.Client _client;

  MintValidator({http.Client? client}) : _client = client ?? http.Client();

  /// Validates a Cashu mint URL and ensures NUT-04, NUT-07, NUT-10, NUT-11 are supported.
  Future<MintValidationResult> validateMint(String mintUrl) async {
    final cleanUrl = mintUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (cleanUrl.isEmpty || !cleanUrl.startsWith('http')) {
      return const MintValidationResult(
        isValid: false,
        nut11Supported: false,
        nut04Supported: false,
        nut07Supported: false,
        nut10Supported: false,
        errorMessage: 'Invalid mint URL format',
      );
    }

    try {
      final infoUri = Uri.parse('$cleanUrl/v1/info');
      final response =
          await _client.get(infoUri).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        return MintValidationResult(
          isValid: false,
          nut11Supported: false,
          nut04Supported: false,
          nut07Supported: false,
          nut10Supported: false,
          errorMessage: 'Mint returned HTTP ${response.statusCode}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final name = json['name'] as String? ?? 'Cashu Mint';
      final description = json['description'] as String?;
      final motd = json['motd'] as String?;
      final nuts = json['nuts'] as Map<String, dynamic>? ?? {};

      Map<String, dynamic>? getNutMap(dynamic key) {
        final val = nuts[key.toString()];
        if (val is Map<String, dynamic>) {
          return val;
        } else if (val is Map) {
          return val.cast<String, dynamic>();
        }
        return null;
      }

      // Check NUT-04 (bolt11 sat minting required)
      final nut04 = getNutMap('4') ?? getNutMap('04');
      bool nut04Supported = false;
      if (nut04 != null && nut04['disabled'] != true) {
        final methods = nut04['methods'];
        if (methods is List) {
          nut04Supported = methods.any((m) {
            if (m is Map) {
              final method = m['method']?.toString().toLowerCase();
              final unit = m['unit']?.toString().toLowerCase();
              return method == 'bolt11' && unit == 'sat';
            }
            return false;
          });
        }
      }

      // Check NUT-07 (state check required)
      final nut07 = getNutMap('7') ?? getNutMap('07');
      final nut07Supported = nut07 != null &&
          nut07['disabled'] != true &&
          (nut07['supported'] == true || !nut07.containsKey('supported'));

      // Check NUT-10 (spending conditions required)
      final nut10 = getNutMap('10');
      final nut10Supported = nut10 != null &&
          nut10['disabled'] != true &&
          (nut10['supported'] == true || !nut10.containsKey('supported'));

      // Check NUT-11 (P2PK / timelock spending conditions required)
      final nut11 = getNutMap('11');
      final nut11Supported = nut11 != null &&
          nut11['disabled'] != true &&
          (nut11['supported'] == true || !nut11.containsKey('supported'));

      String? errorMessage;
      if (!nut11Supported) {
        errorMessage =
            'This Cashu mint does not support Hanbova Protected Payments (NUT-11).';
      } else if (!nut04Supported) {
        errorMessage =
            'This Cashu mint does not support Lightning sat deposits (NUT-04 bolt11/sat).';
      } else if (!nut07Supported) {
        errorMessage =
            'This Cashu mint does not support ecash proof state checks (NUT-07).';
      } else if (!nut10Supported) {
        errorMessage =
            'This Cashu mint does not support spending condition rules (NUT-10).';
      }

      return MintValidationResult(
        isValid: true,
        nut11Supported: nut11Supported,
        nut04Supported: nut04Supported,
        nut07Supported: nut07Supported,
        nut10Supported: nut10Supported,
        mintName: name,
        description: description,
        motd: motd,
        errorMessage: errorMessage,
      );
    } catch (e) {
      return MintValidationResult(
        isValid: false,
        nut11Supported: false,
        nut04Supported: false,
        nut07Supported: false,
        nut10Supported: false,
        errorMessage: 'Could not connect to mint: $e',
      );
    }
  }
}
