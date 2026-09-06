import 'dart:io';

class AppConfig {
  final String appName;
  final String appVersion;
  final String apiBaseUrl;
  final String mintUrl;
  final String environment;
  final bool isMockEnvironment;

  const AppConfig({
    required this.appName,
    required this.appVersion,
    required this.apiBaseUrl,
    this.mintUrl = 'http://127.0.0.1:3338',
    this.environment = 'development',
    this.isMockEnvironment = false,
  });

  bool get isDevelopment => environment == 'development';
  bool get isPilot => environment == 'pilot';
  bool get isProduction => environment == 'production';
  bool get isTest => environment == 'test';
  bool get isMock => environment == 'mock' || isMockEnvironment;

  static String get defaultHost {
    try {
      if (Platform.isAndroid) return '10.0.2.2';
    } catch (_) {}
    return '127.0.0.1';
  }

  static AppConfig get development => AppConfig(
        appName: 'Hanbova',
        appVersion: '0.1.0',
        apiBaseUrl: 'http://$defaultHost:8080/api/v1',
        mintUrl: 'http://$defaultHost:3338',
        environment: 'development',
        isMockEnvironment: false,
      );

  static AppConfig get mock => AppConfig(
        appName: 'Hanbova (Mock)',
        appVersion: '0.1.0-mock',
        apiBaseUrl: 'http://$defaultHost:8080/api/v1',
        mintUrl: 'http://$defaultHost:3338',
        environment: 'mock',
        isMockEnvironment: true,
      );

  static AppConfig createPilot({
    required String apiBaseUrl,
    required String mintUrl,
    String appName = 'Hanbova',
    String appVersion = '0.1.0',
  }) {
    if (apiBaseUrl.trim().isEmpty) {
      throw StateError(
          'Pilot environment requires HANBOVA_API_BASE_URL to be set');
    }
    if (!apiBaseUrl.startsWith('https://')) {
      throw StateError(
          'Pilot environment requires HTTPS API URL, got: $apiBaseUrl');
    }
    if (apiBaseUrl.contains('localhost') ||
        apiBaseUrl.contains('127.0.0.1') ||
        apiBaseUrl.contains('10.0.2.2')) {
      throw StateError(
          'Pilot environment cannot use localhost or private IP for API URL, got: $apiBaseUrl');
    }

    if (mintUrl.trim().isEmpty) {
      throw StateError('Pilot environment requires HANBOVA_MINT_URL to be set');
    }
    if (!mintUrl.startsWith('https://')) {
      throw StateError(
          'Pilot environment requires HTTPS Mint URL, got: $mintUrl');
    }
    if (mintUrl.contains('localhost') ||
        mintUrl.contains('127.0.0.1') ||
        mintUrl.contains('10.0.2.2')) {
      throw StateError(
          'Pilot environment cannot use localhost or private IP for Mint URL, got: $mintUrl');
    }

    return AppConfig(
      appName: appName,
      appVersion: appVersion,
      apiBaseUrl: apiBaseUrl,
      mintUrl: mintUrl,
      environment: 'pilot',
      isMockEnvironment: false,
    );
  }

  static AppConfig createProduction({
    required String apiBaseUrl,
    required String mintUrl,
    String appName = 'Hanbova',
    String appVersion = '0.1.0',
  }) {
    if (apiBaseUrl.trim().isEmpty || !apiBaseUrl.startsWith('https://')) {
      throw StateError('Production requires HTTPS API URL');
    }
    if (apiBaseUrl.contains('localhost') ||
        apiBaseUrl.contains('127.0.0.1') ||
        apiBaseUrl.contains('10.0.2.2')) {
      throw StateError(
          'Production environment cannot use localhost or private IP for API URL, got: $apiBaseUrl');
    }
    if (mintUrl.trim().isEmpty || !mintUrl.startsWith('https://')) {
      throw StateError('Production requires HTTPS Mint URL');
    }
    if (mintUrl.contains('localhost') ||
        mintUrl.contains('127.0.0.1') ||
        mintUrl.contains('10.0.2.2')) {
      throw StateError(
          'Production environment cannot use localhost or private IP for Mint URL, got: $mintUrl');
    }
    return AppConfig(
      appName: appName,
      appVersion: appVersion,
      apiBaseUrl: apiBaseUrl,
      mintUrl: mintUrl,
      environment: 'production',
      isMockEnvironment: false,
    );
  }

  static AppConfig fromEnvironment() {
    const env =
        String.fromEnvironment('HANBOVA_ENV', defaultValue: 'development');
    const apiBase =
        String.fromEnvironment('HANBOVA_API_BASE_URL', defaultValue: '');
    const mint = String.fromEnvironment('HANBOVA_MINT_URL', defaultValue: '');
    const appVer = String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0');
    const appNm = String.fromEnvironment('APP_NAME', defaultValue: 'Hanbova');

    if (env == 'pilot') {
      return createPilot(
        apiBaseUrl: apiBase,
        mintUrl: mint,
        appName: appNm,
        appVersion: appVer,
      );
    } else if (env == 'production') {
      return createProduction(
        apiBaseUrl: apiBase,
        mintUrl: mint,
        appName: appNm,
        appVersion: appVer,
      );
    } else if (env == 'mock') {
      return mock;
    }

    return AppConfig(
      appName: appNm,
      appVersion: appVer,
      apiBaseUrl:
          apiBase.isNotEmpty ? apiBase : 'http://$defaultHost:8080/api/v1',
      mintUrl: mint.isNotEmpty ? mint : 'http://$defaultHost:3338',
      environment: 'development',
      isMockEnvironment: false,
    );
  }
}
