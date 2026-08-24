import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/app/app.dart';
import 'package:hanbova_app/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('Hanbova home screen renders balance, actions and navigation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: HanbovaApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header and balance card
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Total Balance'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    expect(find.text('Receive'), findsOneWidget);

    // Verify Quick Claim Banner & Protected Summary
    expect(find.text('Protected Payments'), findsOneWidget);
    expect(find.text('Have a claim code?'), findsOneWidget);
    expect(find.text('Claim'), findsOneWidget);

    // Verify Bottom Navigation Items
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsWidgets);
    expect(find.text('Me'), findsOneWidget);
  });

  testWidgets('Bottom navigation tabs switch between Home, Activity, Protected, Me', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: HanbovaApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Activity Tab
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(find.text('Sent'), findsOneWidget);
    expect(find.text('Received'), findsOneWidget);

    // Switch to Protected Tab via Bottom Navigation icon
    await tester.tap(find.byIcon(Icons.shield_outlined).last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Active'), findsOneWidget);
    expect(find.textContaining('Incoming'), findsOneWidget);
    expect(find.textContaining('Completed'), findsOneWidget);

    // Switch to Me Tab
    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();
    expect(find.text('Wallet Security'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Display Currency'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('Center Pay button opens Pay Action Sheet modal', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: HanbovaApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap center Pay button
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded).last);
    await tester.pumpAndSettle();

    // Verify modal sheet contents
    expect(find.text('What would you like to do?'), findsOneWidget);
    expect(find.text('Send Instant'), findsOneWidget);
    expect(find.text('Send Protected'), findsOneWidget);
    expect(find.text('Receive Bitcoin'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
  });
}
