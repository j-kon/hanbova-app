import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/config/app_config.dart';
import 'package:hanbova_app/core/networking/api_client.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/features/mints/presentation/mints_screen.dart';

void main() {
  testWidgets(
      'private pilot mint screen shows only its locked test mint at large text',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.createPilot(
            apiBaseUrl: 'https://api.pilot.example.com/api/v1',
            mintUrl: 'https://mint.pilot.example.com',
          )),
        ],
        child: MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(2)),
                child: child!),
            home: const MintsScreen())));
    await tester.pump();
    expect(find.byTooltip('Add Custom Mint'), findsNothing);
    expect(find.text('Add Another Mint'), findsNothing);
    expect(find.text('Cashu Space Testnut (NUT-11 enabled)'), findsNothing);
    expect(
        find.textContaining('Private pilot uses only the configured test mint'),
        findsOneWidget);
    expect(find.text('https://mint.pilot.example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
