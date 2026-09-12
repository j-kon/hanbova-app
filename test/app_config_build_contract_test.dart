import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/config/app_config.dart';

void main() {
  test(
      'compile-time environment names fail closed instead of selecting development',
      () {
    const environment =
        String.fromEnvironment('HANBOVA_ENV', defaultValue: 'development');
    if (!['development', 'test', 'mock', 'pilot', 'production']
        .contains(environment)) {
      expect(AppConfig.fromEnvironment, throwsA(isA<StateError>()));
    } else {
      expect(AppConfig.fromEnvironment().environment, environment);
    }
  });
}
