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

    // Verify Navigation Items
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(
        find.byKey(const Key('navbar_center_action_button')), findsOneWidget);
    expect(find.text('Money'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets(
      'Bottom navigation tabs switch between Home, Center Action, Activity, Money, Profile',
      (
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

    // Tap Center Action Button and select Pay Everyday Bills
    await tester.tap(find.byKey(const Key('navbar_center_action_button')));
    await tester.pumpAndSettle();
    expect(find.text('Pay Everyday Bills'), findsOneWidget);
    await tester.tap(find.text('Pay Everyday Bills'));
    await tester.pumpAndSettle();

    expect(find.text('Send Money'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Everyday'), findsOneWidget);
    expect(find.text('Airtime'), findsOneWidget);

    // Switch to Activity Tab
    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Money In'), findsOneWidget);
    expect(find.text('Money Out'), findsOneWidget);

    // Switch to Money Tab
    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Money & Balances'), findsOneWidget);

    // Switch to Profile Tab
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Edit Profile'), findsOneWidget);
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

    // Tap center action button to launch Pay
    await tester.tap(find.byKey(const Key('navbar_center_action_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay Everyday Bills'));
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
