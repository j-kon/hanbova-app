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

      // Check NUT-04 (bolt11 minting)
      final nut04 = nuts['4'] as Map<String, dynamic>?;
      final nut04Supported = nut04 == null ||
          (nut04['disabled'] != true && nut04['supported'] != false);

      // Check NUT-07 (state check)
      final nut07 = nuts['7'] as Map<String, dynamic>?;
      final nut07Supported = nut07 == null ||
          (nut07['disabled'] != true && nut07['supported'] != false);

      // Check NUT-10 (spending conditions)
      final nut10 = nuts['10'] as Map<String, dynamic>?;
      final nut10Supported = nut10 == null ||
          (nut10['disabled'] != true && nut10['supported'] != false);

      // Check NUT-11 support
      final nut11 = nuts['11'] as Map<String, dynamic>?;
      final nut11Supported = nut11 != null &&
          (nut11['supported'] == true || nut11['disabled'] != true);

      if (!nut11Supported) {
        return MintValidationResult(
          isValid: true,
          nut11Supported: false,
          nut04Supported: nut04Supported,
          nut07Supported: nut07Supported,
          nut10Supported: nut10Supported,
          mintName: name,
          description: description,
          motd: motd,
          errorMessage:
              'This Cashu mint does not support Hanbova Protected Payments (NUT-11).',
        );
      }

      return MintValidationResult(
        isValid: true,
        nut11Supported: true,
        nut04Supported: nut04Supported,
        nut07Supported: nut07Supported,
        nut10Supported: nut10Supported,
        mintName: name,
        description: description,
        motd: motd,
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
