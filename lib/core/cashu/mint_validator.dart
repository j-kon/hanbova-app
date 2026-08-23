import 'dart:convert';
import 'package:http/http.dart' as http;

class MintValidationResult {
  final bool isValid;
  final bool nut11Supported;
  final String? mintName;
  final String? errorMessage;

  const MintValidationResult({
    required this.isValid,
    required this.nut11Supported,
    this.mintName,
    this.errorMessage,
  });
}

class MintValidator {
  final http.Client _client;

  MintValidator({http.Client? client}) : _client = client ?? http.Client();

  /// Validates a Cashu mint URL and ensures NUT-11 (P2PK) is supported.
  Future<MintValidationResult> validateMint(String mintUrl) async {
    final cleanUrl = mintUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (cleanUrl.isEmpty || !cleanUrl.startsWith('http')) {
      return const MintValidationResult(
        isValid: false,
        nut11Supported: false,
        errorMessage: 'Invalid mint URL format',
      );
    }

    try {
      final infoUri = Uri.parse('$cleanUrl/v1/info');
      final response = await _client.get(infoUri).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        return MintValidationResult(
          isValid: false,
          nut11Supported: false,
          errorMessage: 'Mint returned HTTP ${response.statusCode}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final name = json['name'] as String? ?? 'Cashu Mint';
      final nuts = json['nuts'] as Map<String, dynamic>? ?? {};

      // Check NUT-11 support
      final nut11 = nuts['11'] as Map<String, dynamic>?;
      final nut11Supported = nut11 != null && (nut11['supported'] == true || nut11['disabled'] != true);

      if (!nut11Supported) {
        return MintValidationResult(
          isValid: true,
          nut11Supported: false,
          mintName: name,
          errorMessage: 'This Cashu mint does not support Hanbova Protected Payments (NUT-11).',
        );
      }

      return MintValidationResult(
        isValid: true,
        nut11Supported: true,
        mintName: name,
      );
    } catch (e) {
      return MintValidationResult(
        isValid: false,
        nut11Supported: false,
        errorMessage: 'Could not connect to mint: $e',
      );
    }
  }
}
