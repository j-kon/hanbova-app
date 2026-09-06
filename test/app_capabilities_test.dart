import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanbova_app/core/capabilities/app_capabilities.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/features/notifications/presentation/notifications_screen.dart';

void main() {
  test('release capabilities keep unimplemented integrations disabled', () {
    const capabilities = AppCapabilities.release();

    expect(capabilities.cameraQrScanning, isFalse);
    expect(capabilities.pushNotifications, isFalse);
    expect(capabilities.biometricLogin, isFalse);
    expect(capabilities.liveExchangeRates, isFalse);
  });

  testWidgets('notifications do not fabricate payment events', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NotificationsScreen(),
        ),
      ),
    );

    expect(find.text('No notifications yet'), findsOneWidget);
    expect(find.textContaining('@amina'), findsNothing);
    expect(find.textContaining('@kofi'), findsNothing);
  });
}
