import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/features/scan/screens/scan_screen.dart';

void main() {
  Widget app() => ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ScanScreen(),
        ),
      );

  testWidgets('scan route makes camera unavailability explicit',
      (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('Camera scanning coming soon'), findsOneWidget);
    expect(find.text('Paste payment request'), findsOneWidget);
    expect(find.textContaining('scan automatically'), findsNothing);
  });

  testWidgets('cashu token is rejected without opening a claim flow',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.enterText(find.byType(TextField), 'cashuBtoken');
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(
        find.text('Cashu token import is not available yet.'), findsOneWidget);
  });
}
