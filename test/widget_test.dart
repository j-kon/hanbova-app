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
    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('Send'), findsWidgets);
    expect(find.text('Receive'), findsWidgets);
    expect(find.text('Protected'), findsWidgets);
    expect(find.text('Scan'), findsWidgets);

    // Verify 5 Bottom Navigation Items
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Pay'), findsWidgets);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('Me'), findsOneWidget);
  });

  testWidgets(
      'Bottom navigation tabs switch between Home, Pay, Activity, Travel, Me', (
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

    // Switch to Pay Tab via Bottom Navigation
    await tester.tap(find.byIcon(Icons.payments_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Send Money'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Everyday'), findsOneWidget);

    // Switch to Activity Tab
    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Money In'), findsOneWidget);
    expect(find.text('Money Out'), findsOneWidget);

    // Switch to Travel Tab
    await tester.tap(find.byIcon(Icons.flight_takeoff_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Travel & Spend Hub'), findsOneWidget);

    // Switch to Me Tab
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Recovery Phrase Backup'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Display Currency'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('Pay Tab displays Pay Again carousel and Everyday services', (
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

    // Tap bottom Pay icon
    await tester.tap(find.byIcon(Icons.payments_outlined));
    await tester.pumpAndSettle();

    // Verify Pay Hub content
    expect(find.text('Pay'), findsWidgets);
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Airtime'), findsOneWidget);
    expect(find.text('Data Bundles'), findsOneWidget);
    expect(find.text('Electricity'), findsOneWidget);
    expect(find.text('TV Cables'), findsOneWidget);
  });
}
