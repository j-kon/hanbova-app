import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/currency/currency_provider.dart';
import 'package:hanbova_app/core/demo/demo_personas.dart';
import 'package:hanbova_app/core/market/country_model.dart';
import 'package:hanbova_app/core/market/market_provider.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/features/auth/screens/sign_up_screen.dart';
import 'package:hanbova_app/features/home/presentation/home_screen.dart';
import 'package:hanbova_app/features/spend/presentation/pay_hub_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Hanbova Global Registration & Market-Adaptive Architecture Tests', () {
    // 1. Country model completeness and lookup helpers
    test('1. Country model completeness and lookup helpers', () {
      expect(CountryInfo.allCountries.length, greaterThanOrEqualTo(240));

      final us = CountryInfo.findByCode('US');
      expect(us.code, 'US');
      expect(us.name, 'United States');
      expect(us.defaultCurrency, FiatCurrency.usd);

      final ng = CountryInfo.findByCode('ng');
      expect(ng.code, 'NG');
      expect(ng.name, 'Nigeria');
      expect(ng.defaultCurrency, FiatCurrency.ngn);

      final ke = CountryInfo.findByCode('KE');
      expect(ke.code, 'KE');
      expect(ke.defaultCurrency, FiatCurrency.kes);

      final sn = CountryInfo.findByCode('sn');
      expect(sn.code, 'SN');
      expect(sn.name, 'Senegal');
    });

    // 2. Registration country search by name and ISO code (case-insensitive)
    test('2. Registration country search by name and ISO code', () {
      final searchByName = CountryInfo.search('senegal');
      expect(searchByName.any((c) => c.code == 'SN'), isTrue);

      final searchByCode = CountryInfo.search('us');
      expect(searchByCode.any((c) => c.code == 'US'), isTrue);

      final searchRwanda = CountryInfo.search('RW');
      expect(searchRwanda.any((c) => c.name == 'Rwanda'), isTrue);

      final emptyQuery = CountryInfo.search('');
      expect(emptyQuery.length, equals(CountryInfo.allCountries.length));
    });

    // 3. MarketCapabilities matrix serialization/deserialization
    test('3. MarketCapabilities serialization and deserialization', () {
      final defaultCaps = MarketCapabilities.globalDefault;
      expect(defaultCaps.bitcoin, isTrue);
      expect(defaultCaps.cashu, isTrue);
      expect(defaultCaps.protectedPayments, isTrue);
      expect(defaultCaps.airtime, isFalse);
      expect(defaultCaps.electricity, isFalse);
      expect(defaultCaps.bankPayout, isFalse);
      expect(defaultCaps.mobileMoney, isFalse);

      final json = defaultCaps.toJson();
      final revived = MarketCapabilities.fromJson(json);
      expect(revived.bitcoin, isTrue);
      expect(revived.airtime, isFalse);
      expect(revived.electricity, isFalse);
    });

    // 4. Unsupported country defaults to global baseline
    test('4. Unsupported country defaults to global baseline', () {
      final usCaps = MarketCapabilities.forMarket('US');
      expect(usCaps.hasLocalServices, isFalse);
      expect(usCaps.hasEverydayBills, isFalse);
      expect(usCaps.bitcoin, isTrue);
      expect(usCaps.cashu, isTrue);
      expect(usCaps.protectedPayments, isTrue);
      expect(usCaps.airtime, isFalse);
      expect(usCaps.bankPayout, isFalse);
    });

    // 5. Senegal (SN) does not assume local capabilities
    test('5. Senegal (SN) does not assume local capabilities', () {
      final snCaps = MarketCapabilities.forMarket('SN');
      expect(snCaps.hasLocalServices, isFalse);
      expect(snCaps.hasEverydayBills, isFalse);
      expect(snCaps.airtime, isFalse);
      expect(snCaps.mobileMoney, isFalse);
      expect(snCaps.bankPayout, isFalse);
    });

    // 6. Supported country exposes local capabilities without Roam
    test('6. Supported country exposes local capabilities without Roam', () {
      final ngCaps = MarketCapabilities.forMarket('NG');
      expect(ngCaps.hasLocalServices, isTrue);
      expect(ngCaps.hasEverydayBills, isTrue);
      expect(ngCaps.airtime, isTrue);
      expect(ngCaps.data, isTrue);
      expect(ngCaps.electricity, isTrue);
      expect(ngCaps.bankPayout, isTrue);

      final keCaps = MarketCapabilities.forMarket('KE');
      expect(keCaps.hasLocalServices, isTrue);
      expect(keCaps.mobileMoney, isTrue);
      expect(keCaps.airtime, isTrue);
    });

    // 7. Roam activation mutates activeMarket and displayCurrency, leaves residenceCountry unchanged
    test('7. Roam activation mutates activeMarket and displayCurrency',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(marketProvider.notifier);
      await notifier.setResidenceCountry('US');

      var state = container.read(marketProvider);
      expect(state.residenceCountry, 'US');
      expect(state.activeMarket, 'US');
      expect(state.displayCurrency, FiatCurrency.usd);
      expect(state.roamEnabled, isFalse);
      expect(state.isRoamActive, isFalse);
      expect(state.capabilities.hasLocalServices, isFalse);

      // Activate Roam in Kenya
      await notifier.activateRoam('KE');

      state = container.read(marketProvider);
      expect(state.residenceCountry, 'US',
          reason: 'Residence MUST NOT mutate on Roam');
      expect(state.activeMarket, 'KE');
      expect(state.displayCurrency, FiatCurrency.kes);
      expect(state.roamEnabled, isTrue);
      expect(state.isRoamActive, isTrue);
      expect(state.capabilities.hasLocalServices, isTrue);
      expect(state.capabilities.mobileMoney, isTrue);
    });

    // 8. Roam deactivation restores residenceCountry context and currency
    test('8. Roam deactivation restores residenceCountry context and currency',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(marketProvider.notifier);
      await notifier.setResidenceCountry('US');
      await notifier.activateRoam('KE');

      // Now turn off Roam
      await notifier.deactivateRoam();

      final state = container.read(marketProvider);
      expect(state.residenceCountry, 'US');
      expect(state.activeMarket, 'US');
      expect(state.displayCurrency, FiatCurrency.usd);
      expect(state.roamEnabled, isFalse);
      expect(state.isRoamActive, isFalse);
      expect(state.capabilities.hasLocalServices, isFalse);
    });

    // 9. Persona switching (A, B, C) behaves correctly
    test('9. Persona switching (A, B, C) behaves correctly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Persona A: NG, Roam Off
      await applyPersona(container, DemoPersonas.personaA);
      var state = container.read(marketProvider);
      expect(state.residenceCountry, 'NG');
      expect(state.activeMarket, 'NG');
      expect(state.roamEnabled, isFalse);
      expect(state.displayCurrency, FiatCurrency.ngn);
      expect(state.capabilities.hasLocalServices, isTrue);

      // Persona B: US, Roam Off
      await applyPersona(container, DemoPersonas.personaB);
      state = container.read(marketProvider);
      expect(state.residenceCountry, 'US');
      expect(state.activeMarket, 'US');
      expect(state.roamEnabled, isFalse);
      expect(state.displayCurrency, FiatCurrency.usd);
      expect(state.capabilities.hasLocalServices, isFalse);

      // Persona C: US, Roam KE
      await applyPersona(container, DemoPersonas.personaC);
      state = container.read(marketProvider);
      expect(state.residenceCountry, 'US');
      expect(state.activeMarket, 'KE');
      expect(state.roamEnabled, isTrue);
      expect(state.displayCurrency, FiatCurrency.kes);
      expect(state.capabilities.hasLocalServices, isTrue);
    });

    // 10. KYC status model verification
    test('10. KYC status enum exists without fake verification flow', () {
      expect(KycStatus.values, contains(KycStatus.unverified));
      expect(KycStatus.values, contains(KycStatus.pendingVerification));
      expect(KycStatus.values, contains(KycStatus.verified));
      expect(KycStatus.values, contains(KycStatus.restricted));
    });

    // 11. Widget Test: Global Registration with non-African country (US) in SignUpScreen
    testWidgets(
        '11. Global Registration with non-African country (US) in SignUpScreen',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProviderScope(child: SignUpScreen()),
        ),
      );

      // Step 0: Name and Username
      expect(find.text('Create an account'), findsOneWidget);
      expect(find.text('First name'), findsOneWidget);
      expect(find.text('Last name'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Alice');
      await tester.enterText(find.byType(TextFormField).at(1), 'Smith');
      await tester.enterText(find.byType(TextFormField).at(2), 'alicesmith');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      // Step 1: Email and Password
      expect(find.text('Email address'), findsOneWidget);
      await tester.enterText(
          find.byType(TextFormField).at(0), 'alice@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'Password123!');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123!');
      await tester.tap(
          find.widgetWithText(ElevatedButton, 'Continue to Country Selection'));
      await tester.pumpAndSettle();

      // Step 2: Country of Residence
      expect(find.text('Where do you live?'), findsOneWidget);
      expect(find.textContaining('country of residence'), findsOneWidget);

      // Search for United States
      final searchField = find.byKey(const Key('countrySearchField'));
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'United States');
      await tester.pumpAndSettle();

      final usOption = find.widgetWithText(ListTile, 'United States');
      expect(usOption, findsOneWidget);
      await tester.tap(usOption);
      await tester.pumpAndSettle();

      // Step 3: Explanation Confirmation
      expect(find.text('Hanbova in United States'), findsOneWidget);
      expect(find.text('Bitcoin wallet'), findsOneWidget);
      expect(find.text('Continue to Wallet Setup'), findsOneWidget);
    });

    // 12. Widget Test: Quick Pay is hidden when no everyday bill capabilities exist (US)
    testWidgets(
        '12. Quick Pay is hidden when no everyday bill capabilities exist (US)',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(overrides: [
        marketProvider.overrideWith((ref) => MarketNotifier()),
      ]);
      addTearDown(container.dispose);

      await container.read(marketProvider.notifier).setResidenceCountry('US');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Quick Pay header should NOT be present for US baseline
      expect(find.text('Quick Pay'), findsNothing);
      expect(find.text('All Bills'), findsNothing);

      // Action Rail buttons should be present
      expect(find.text('Send'), findsWidgets);
      expect(find.text('Receive'), findsWidgets);
      expect(find.text('Protected'), findsWidgets);
      expect(find.text('Scan'), findsWidgets);
      expect(find.text('Request'), findsWidgets);
      // Airtime should NOT be on action rail for US
      expect(find.text('Airtime'), findsNothing);
      expect(find.text('More'), findsWidgets);
    });

    // 13. Widget Test: Quick Pay and Action Rail adapt for supported local market (NG)
    testWidgets(
        '13. Quick Pay and Action Rail adapt for supported local market (NG)',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(overrides: [
        marketProvider.overrideWith((ref) => MarketNotifier()),
      ]);
      addTearDown(container.dispose);

      await container.read(marketProvider.notifier).setResidenceCountry('NG');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Quick Pay should be present for NG
      expect(find.text('Quick Pay'), findsOneWidget);
      expect(find.text('All Bills'), findsOneWidget);

      // Airtime should be present in Action Rail and Quick Pay
      expect(find.text('Airtime'), findsWidgets);
    });

    // 14. Widget Test: Pay Hub adapts between global (US) and local (NG) views
    testWidgets('14. Pay Hub adapts for global market (US)', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(overrides: [
        marketProvider.overrideWith((ref) => MarketNotifier()),
      ]);
      addTearDown(container.dispose);

      await container.read(marketProvider.notifier).setResidenceCountry('US');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const PayHubScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In global view:
      expect(find.text('Send'), findsOneWidget);
      expect(find.text('Wallet'), findsOneWidget);
      expect(find.text('Local services'), findsOneWidget);
      expect(find.text('Activate Roam for Local Services'), findsOneWidget);
      expect(find.text('Explore Supported Markets'), findsOneWidget);
      expect(find.text('Stablecoin'), findsOneWidget);
      expect(find.text('Coming soon'), findsOneWidget);

      // Everyday bills grid should NOT be visible
      expect(find.text('Everyday'), findsNothing);
      expect(find.text('Airtime'), findsNothing);
      expect(find.text('Prepaid token generator'), findsNothing);
    });

    testWidgets('15. Pay Hub adapts for supported market (NG)', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(overrides: [
        marketProvider.overrideWith((ref) => MarketNotifier()),
      ]);
      addTearDown(container.dispose);

      await container.read(marketProvider.notifier).setResidenceCountry('NG');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const PayHubScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In supported market view:
      expect(find.text('Send Money'), findsOneWidget);
      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('Everyday'), findsOneWidget);
      expect(find.text('Manage'), findsOneWidget);
      expect(find.text('Airtime'), findsOneWidget);
      expect(find.text('Prepaid token generator'), findsOneWidget);
    });

    // 16. Normalization: UserCountryContext consistency across operations
    test('16. UserCountryContext consistency across operations', () {
      const initial = UserCountryContext(
        residenceCountry: 'US',
        activeMarket: 'US',
        displayCurrency: FiatCurrency.usd,
        roamEnabled: false,
        capabilities: MarketCapabilities.globalDefault,
      );

      expect(initial.isRoamActive, isFalse);
      expect(initial.identityCountry, 'US');
      expect(initial.spendCountry, 'US');

      final roamed = initial.copyWith(
        activeMarket: 'KE',
        displayCurrency: FiatCurrency.kes,
        roamEnabled: true,
      );

      expect(roamed.residenceCountry, 'US');
      expect(roamed.activeMarket, 'KE');
      expect(roamed.isRoamActive, isTrue);

      final json = roamed.toJson();
      final revived = UserCountryContext.fromJson(json);
      expect(revived.residenceCountry, 'US');
      expect(revived.activeMarket, 'KE');
      expect(revived.roamEnabled, isTrue);
      expect(revived.displayCurrency, FiatCurrency.kes);
    });
  });
}
