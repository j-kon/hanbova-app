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

  static const AppConfig development = AppConfig(
    appName: 'Hanbova',
    appVersion: '0.1.0',
    apiBaseUrl: 'http://127.0.0.1:8080/api/v1',
    mintUrl: 'http://127.0.0.1:3338',
    environment: 'development',
    isMockEnvironment: false,
  );

  static const AppConfig mock = AppConfig(
    appName: 'Hanbova (Mock)',
    appVersion: '0.1.0-mock',
    apiBaseUrl: 'http://localhost:8080/api/v1',
    mintUrl: 'http://127.0.0.1:3338',
    environment: 'mock',
    isMockEnvironment: true,
  );
}
