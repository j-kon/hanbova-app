import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../errors/app_failure.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.development;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  String effectiveBaseUrl = config.apiBaseUrl;
  try {
    if (Platform.isAndroid &&
        (effectiveBaseUrl.contains('127.0.0.1') ||
            effectiveBaseUrl.contains('localhost'))) {
      effectiveBaseUrl = effectiveBaseUrl
          .replaceAll('127.0.0.1', '10.0.2.2')
          .replaceAll('localhost', '10.0.2.2');
    }
  } catch (_) {}
  return ApiClient(baseUrl: effectiveBaseUrl, httpClient: http.Client());
});

class ApiClient {
  final String baseUrl;
  final http.Client _httpClient;
  String? _authToken;

  ApiClient({
    required this.baseUrl,
    required http.Client httpClient,
  }) : _httpClient = httpClient;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<http.Response> _sendWithRetry(
      Future<http.Response> Function() requestFn) async {
    try {
      return await requestFn();
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('connection reset') ||
          errStr.contains('broken pipe') ||
          errStr.contains('clientexception') ||
          errStr.contains('socketexception')) {
        // Transient socket drop / idle keepalive reset -> retry once
        await Future.delayed(const Duration(milliseconds: 250));
        return await requestFn();
      }
      rethrow;
    }
  }

  String _formatNetworkError(dynamic e) {
    final str = e.toString();
    if (str.contains('Connection reset by peer') ||
        str.contains('Broken pipe') ||
        str.contains('SocketException') ||
        str.contains('Failed host lookup')) {
      return 'Unable to connect to server. Please check your network connection.';
    }
    if (str.contains('TimeoutException')) {
      return 'Server request timed out. Please try again.';
    }
    return str
        .replaceAll('Exception:', '')
        .replaceAll('ClientException:', '')
        .trim();
  }

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await _sendWithRetry(() => _httpClient
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 10)));

      return _handleResponse(response);
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw AppFailure(
          message: _formatNetworkError(e), originalError: e);
    }
  }

  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await _sendWithRetry(() => _httpClient
          .post(
            uri,
            headers: _buildHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10)));

      return _handleResponse(response);
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw AppFailure(
          message: _formatNetworkError(e), originalError: e);
    }
  }

  Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await _sendWithRetry(() => _httpClient
          .put(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10)));

      return _handleResponse(response);
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw AppFailure(
          message: _formatNetworkError(e), originalError: e);
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await _sendWithRetry(() => _httpClient
          .delete(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 10)));

      return _handleResponse(response);
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw AppFailure(
          message: _formatNetworkError(e), originalError: e);
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      if (response.body.isEmpty) return {};
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else if (decoded is List) {
        return {'data': decoded};
      }
      return {'result': decoded};
    }

    try {
      final errorJson = jsonDecode(response.body);
      final message =
          errorJson['message'] ?? errorJson['error'] ?? 'Request failed';
      throw AppFailure(
        message: message.toString(),
        code: errorJson['error']?.toString() ?? status.toString(),
      );
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw AppFailure(
        message: 'HTTP $status: ${response.reasonPhrase ?? 'Request failed'}',
        code: status.toString(),
      );
    }
  }
}
