import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/market/country_model.dart';
import 'package:hanbova_app/core/market/market_provider.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/features/spend/presentation/pay_hub_screen.dart';

void main() {
  testWidgets(
      'Pay market selector scrolls to and selects the last market on a phone',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await (FontLoader('Poppins')
          ..addFont(
              rootBundle.load('assets/fonts/poppins/Poppins-Regular.ttf')))
        .load();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.darkTheme, home: const PayHubScreen()),
    ));
    await tester.pumpAndSettle();
    await tester
        .tap(find.text(container.read(marketProvider).activeMarketInfo.code));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final lastCountry = CountryInfo.supportedCountries.last;
    final target = find.text(lastCountry.name);
    await tester.scrollUntilVisible(target, 200,
        scrollable: find
            .descendant(
                of: find.byType(BottomSheet), matching: find.byType(Scrollable))
            .first);
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(container.read(marketProvider).activeMarket.toUpperCase(),
        lastCountry.code.toUpperCase());
    expect(find.byType(BottomSheet), findsNothing);
  });
}
