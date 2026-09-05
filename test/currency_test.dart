import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/currency/currency_provider.dart';
import 'package:hanbova_app/core/market/market_provider.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/features/profile/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Display Currency Tests', () {
    test('Converts satoshis to NGN, KES, GHS, ZAR, USD accurately', () {
      const sats = 100000; // 0.001 BTC

      // 1 BTC = 95,000,000 NGN -> 0.001 BTC = 95,000 NGN
      expect(FiatCurrency.ngn.satsToFiat(sats), 95000.0);
      expect(FiatCurrency.ngn.format(sats), '₦95,000.00');

      // 1 BTC = 7,800,000 KES -> 0.001 BTC = 7,800 KES
      expect(FiatCurrency.kes.satsToFiat(sats), 7800.0);
      expect(FiatCurrency.kes.format(sats), 'KSh 7,800.00');

      // 1 BTC = 900,000 GHS -> 0.001 BTC = 900 GHS
      expect(FiatCurrency.ghs.satsToFiat(sats), 900.0);
      expect(FiatCurrency.ghs.format(sats), 'GH₵ 900.00');

      // 1 BTC = $60,000 USD -> 0.001 BTC = $60 USD
      expect(FiatCurrency.usd.satsToFiat(sats), 60.0);
      expect(FiatCurrency.usd.format(sats), r'$60.00');
    });

    test('Converts fiat back to satoshis accurately', () {
      final satsFromUsd = FiatCurrency.usd.fiatToSats(60.0);
      expect(satsFromUsd, 100000);

      final satsFromNgn = FiatCurrency.ngn.fiatToSats(95000.0);
      expect(satsFromNgn, 100000);
    });

    test('FiatCurrency has human-readable currencyName', () {
      expect(FiatCurrency.ngn.currencyName, 'Nigerian Naira');
      expect(FiatCurrency.usd.currencyName, 'US Dollar');
      expect(FiatCurrency.kes.currencyName, 'Kenyan Shilling');
      expect(FiatCurrency.ghs.currencyName, 'Ghanaian Cedi');
      expect(FiatCurrency.rwf.currencyName, 'Rwandan Franc');
      expect(FiatCurrency.ugx.currencyName, 'Ugandan Shilling');
      expect(FiatCurrency.tzs.currencyName, 'Tanzanian Shilling');
      expect(FiatCurrency.zar.currencyName, 'South African Rand');
      expect(FiatCurrency.eur.currencyName, 'Euro');
      expect(FiatCurrency.gbp.currencyName, 'British Pound');
    });

    test('CurrencyNotifier updates active currency', () async {
      final notifier = CurrencyNotifier();
      expect(notifier.state, FiatCurrency.ngn);

      await notifier.setCurrency(FiatCurrency.kes);
      expect(notifier.state, FiatCurrency.kes);

      await notifier.setCurrency(FiatCurrency.usd);
      expect(notifier.state, FiatCurrency.usd);
    });

    testWidgets(
        'SettingsScreen Display Currency sheet renders without overflow on mobile',
        (tester) async {
      // Set to standard mobile viewport
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5; // ~432 x 960 logical px
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Display Currency tile and tap
      final displayCurrencyTile = find.text('Display Currency');
      expect(displayCurrencyTile, findsOneWidget);
      await tester.tap(displayCurrencyTile);
      await tester.pumpAndSettle();

      // Verify bottom sheet appears with title and description
      expect(
          find.text(
              'Choose reference currency for converted prices and portfolio views.'),
          findsOneWidget);

      // Verify rich currency names (e.g. USD • US Dollar)
      expect(find.text('USD • US Dollar'), findsOneWidget);
      expect(find.text('NGN • Nigerian Naira'), findsOneWidget);
      expect(find.text('KES • Kenyan Shilling'), findsOneWidget);

      // Tap on USD
      await tester.tap(find.text('USD • US Dollar'));
      await tester.pumpAndSettle();

      // Verify sheet closed and currency updated
      expect(container.read(marketProvider).displayCurrency, FiatCurrency.usd);
      expect(container.read(currencyProvider), FiatCurrency.usd);
    });
  });
}
