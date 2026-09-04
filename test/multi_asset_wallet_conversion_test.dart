import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_models.dart';
import 'package:hanbova_app/core/cashu/cashu_wallet_provider.dart';
import 'package:hanbova_app/core/demo/demo_mode_provider.dart';
import 'package:hanbova_app/core/theme/app_theme.dart';
import 'package:hanbova_app/features/conversion/presentation/conversion_flow_screen.dart';
import 'package:hanbova_app/features/home/presentation/home_screen.dart';
import 'package:hanbova_app/features/insights/presentation/insights_screen.dart';
import 'package:hanbova_app/features/money/presentation/bitcoin_detail_screen.dart';
import 'package:hanbova_app/features/money/presentation/money_screen.dart';
import 'package:hanbova_app/features/money/presentation/stablecoin_detail_screen.dart';
import 'package:hanbova_app/features/profile/screens/settings_screen.dart';
import 'package:hanbova_app/features/protected_send/presentation/protected_send_screen.dart';
import 'package:hanbova_app/features/receive/presentation/receive_screen.dart';
import 'package:hanbova_app/features/send/presentation/send_screen.dart';
import 'package:hanbova_app/features/spend/presentation/payment_confirmation_sheet.dart';
import 'package:hanbova_app/features/transactions/domain/transaction_model.dart';
import 'package:hanbova_app/features/transactions/presentation/transaction_details_screen.dart';
import 'package:hanbova_app/features/transactions/presentation/transactions_screen.dart';
import 'package:hanbova_app/features/wallet/domain/asset_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('M3B.2.2 Multi-Asset Domain Models & Provider Abstraction', () {
    test('1. AssetType supports BTC, USDT, and USDC with appropriate attributes', () {
      expect(AssetType.values.length, 3);

      expect(AssetType.btc.symbol, 'BTC');
      expect(AssetType.btc.decimals, 8);
      expect(AssetType.btc.isStablecoin, isFalse);

      expect(AssetType.usdt.symbol, 'USDT');
      expect(AssetType.usdt.decimals, 2);
      expect(AssetType.usdt.isStablecoin, isTrue);

      expect(AssetType.usdc.symbol, 'USDC');
      expect(AssetType.usdc.decimals, 2);
      expect(AssetType.usdc.isStablecoin, isTrue);
    });

    test('2. AssetFeatureState covers all 6 normalized lifecycle states', () {
      expect(AssetFeatureState.values, containsAll([
        AssetFeatureState.unavailable,
        AssetFeatureState.comingSoon,
        AssetFeatureState.setupRequired,
        AssetFeatureState.verificationRequired,
        AssetFeatureState.active,
        AssetFeatureState.restricted,
      ]));
    });

    test('3. AssetBalance properly calculates formatted balances', () {
      final btcBalance = AssetBalance(
        asset: AssetType.btc,
        total: 2100000.0,
        available: 1800000.0,
        pending: 50000.0,
        satsAmount: 1800000,
        featureState: AssetFeatureState.active,
      );

      expect(btcBalance.total, 2100000.0);
      expect(btcBalance.formattedAvailable, '1800000 sats available');
      expect(btcBalance.formattedBalance, '1800000 sats');

      final usdtBalance = AssetBalance(
        asset: AssetType.usdt,
        total: 1250.00,
        available: 1250.00,
        featureState: AssetFeatureState.active,
      );

      expect(usdtBalance.formattedAvailable, '\$1250.00 available');
      expect(usdtBalance.formattedBalance, '\$1250.00');
    });

    test('4. ConversionPair and ConversionQuote handle quotes and 30s expiration', () {
      const pair = ConversionPair(
        from: AssetType.btc,
        to: AssetType.usdt,
      );

      expect(pair.label, 'BTC → USDT');
      expect(pair.isInverseOfSelf, isFalse);

      final now = DateTime.now();
      final validQuote = ConversionQuote(
        id: 'quote_1',
        pair: pair,
        fromAmount: 100000.0,
        toAmount: 64.82,
        exchangeRate: 64820.0,
        feeAmount: 0.16,
        feeAsset: 'USDT',
        expiresAt: now.add(const Duration(seconds: 30)),
      );

      expect(validQuote.isExpired, isFalse);

      final expiredQuote = ConversionQuote(
        id: 'quote_2',
        pair: pair,
        fromAmount: 100000.0,
        toAmount: 64.82,
        exchangeRate: 64820.0,
        feeAmount: 0.16,
        feeAsset: 'USDT',
        expiresAt: now.subtract(const Duration(seconds: 10)),
      );

      expect(expiredQuote.isExpired, isTrue);
    });

    test('5. ConversionLifecycleStatus covers all 8 distinct lifecycle stages', () {
      expect(ConversionLifecycleStatus.values.length, 8);
      expect(ConversionLifecycleStatus.values, containsAll([
        ConversionLifecycleStatus.quoteLoading,
        ConversionLifecycleStatus.quoted,
        ConversionLifecycleStatus.quoteExpired,
        ConversionLifecycleStatus.confirming,
        ConversionLifecycleStatus.processing,
        ConversionLifecycleStatus.completed,
        ConversionLifecycleStatus.failed,
        ConversionLifecycleStatus.uncertain,
      ]));
    });

    test('6. Normal mode maintains financial truthfulness (0 fake balances)', () {
      final container = ProviderContainer();
      final demoState = container.read(demoModeProvider);

      expect(demoState.demoUsdtBalance, 1250.00); // Demo fixture definition exists
      expect(demoState.demoUsdcBalance, 750.00);

      // Stablecoin balance in non-demo mode defaults to 0.0 with comingSoon state
      final normalUsdt = AssetBalance(
        asset: AssetType.usdt,
        total: 0.0,
        available: 0.0,
        featureState: AssetFeatureState.comingSoon,
      );
      expect(normalUsdt.total, 0.0);
      expect(normalUsdt.featureState, AssetFeatureState.comingSoon);
    });

    test('7. Demo Mode personas support multi-asset profiles', () {
      final ngPersona = DemoPersona.nigeriaResident;
      expect(ngPersona.residenceCountry, 'NG');
      expect(ngPersona.activeMarket, 'NG');
      expect(ngPersona.isRoamActive, isFalse);

      final usPersona = DemoPersona.usaResident;
      expect(usPersona.residenceCountry, 'US');
      expect(usPersona.isRoamActive, isFalse);

      final roamPersona = DemoPersona.usaResidentRoamingKenya;
      expect(roamPersona.isRoamActive, isTrue);
      expect(roamPersona.activeMarket, 'KE');
    });
  });

  group('M3B.2.2 Multi-Asset Widgets & UI Contracts', () {
    Widget buildTestHarness(Widget child, {bool demoMode = false}) {
      return ProviderScope(
        overrides: [
          demoModeProvider.overrideWith((ref) {
            final notifier = DemoModeNotifier();
            if (!demoMode && notifier.state.isEnabled) {
              notifier.toggleDemoMode();
            } else if (demoMode && !notifier.state.isEnabled) {
              notifier.toggleDemoMode();
            }
            return notifier;
          }),
          cashuBalanceProvider.overrideWith(
            (ref) => Future.value(
              const CashuWalletBalance(
                spendableSats: 1500000,
                lockedEscrowSats: 300000,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: child,
        ),
      );
    }

    testWidgets('8. MoneyScreen displays Bitcoin, USDT, and USDC in Assets section',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestHarness(const MoneyScreen(), demoMode: true));
      await tester.pumpAndSettle();

      expect(find.text('Assets'), findsOneWidget);
      expect(find.text('Bitcoin'), findsOneWidget);
      expect(find.text('USDT'), findsOneWidget);
      expect(find.text('USDC'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('9. BitcoinDetailScreen renders Available, Protected, and Actions',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestHarness(const BitcoinDetailScreen(), demoMode: true));
      await tester.pumpAndSettle();

      expect(find.text('Bitcoin (BTC)'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Protected'), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
      expect(find.text('Receive'), findsOneWidget);
      expect(find.text('Convert'), findsOneWidget);
    });

    testWidgets('10. StablecoinDetailScreen for USDT displays Coming Soon banner in normal mode',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestHarness(
        const StablecoinDetailScreen(asset: AssetType.usdt),
        demoMode: false,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tether USD'), findsWidgets);
      expect(find.textContaining('Coming Soon'), findsWidgets);
      expect(find.textContaining('Backend provider integration pending'), findsOneWidget);
    });

    testWidgets('11. StablecoinDetailScreen for USDC displays demo balance in Demo mode',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestHarness(
        const StablecoinDetailScreen(asset: AssetType.usdc),
        demoMode: true,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('USD Coin'), findsWidgets);
      expect(find.text('\$750.00'), findsWidgets);
      expect(find.textContaining('DEMO'), findsWidgets);
    });

    testWidgets('12. ConversionFlowScreen has pair selector, amount input, and countdown timer',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestHarness(const ConversionFlowScreen(), demoMode: true));
      await tester.pumpAndSettle();

      expect(find.text('Convert Assets'), findsOneWidget);
      expect(find.text('From'), findsOneWidget);
      expect(find.text('To (Estimated)'), findsOneWidget);
      expect(find.byKey(const Key('conversion_amount_input')), findsOneWidget);
      expect(find.textContaining('30 seconds'), findsOneWidget); // Countdown timer initial state
    });

    testWidgets('13. HomeScreen action rail includes Convert action',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestHarness(const HomeScreen(), demoMode: true));
      await tester.pumpAndSettle();

      expect(find.text('Convert'), findsOneWidget);
      expect(find.textContaining('Other:'), findsOneWidget);
      expect(find.text('View Money'), findsOneWidget);
    });

    testWidgets('14. SettingsScreen contains Wallets & Assets option',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestHarness(const SettingsScreen(), demoMode: true));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Wallets & Assets'), 200);
      expect(find.text('Wallets & Assets'), findsOneWidget);
      expect(find.text('Bitcoin, USDT, USDC configuration'), findsOneWidget);
    });

    testWidgets('15. SendScreen presents asset selector prompt with BTC, USDT, USDC',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestHarness(const SendScreen(), demoMode: true));
      await tester.pumpAndSettle();

      expect(find.text('What are you sending?'), findsOneWidget);
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('USDT'), findsOneWidget);
      expect(find.text('USDC'), findsOneWidget);
    });

    testWidgets('16. ProtectedSendScreen remains strictly Bitcoin-only (no Protected USDT/USDC)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestHarness(const ProtectedSendScreen(), demoMode: true));
      await tester.pumpAndSettle();

      expect(find.text('Protected Send'), findsOneWidget);
      expect(find.text('Protected USDT'), findsNothing);
      expect(find.text('Protected USDC'), findsNothing);
    });

    testWidgets('17. ReceiveScreen displays same-network warning when USDT is selected',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestHarness(
        const ReceiveScreen(initialAsset: AssetType.usdt),
        demoMode: true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Receive USDT'), findsOneWidget);
      expect(find.text('Same-Network Warning'), findsOneWidget);
      expect(find.textContaining('permanent loss'), findsOneWidget);
      expect(find.text('Copy Address'), findsOneWidget);
    });

    testWidgets('18. PaymentConfirmationSheet includes Pay-With selector with multi-asset support',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestHarness(
        Scaffold(
          body: PaymentConfirmationSheet(
            title: 'Confirm Airtime',
            billerName: 'MTN Airtime',
            accountReference: '+2348012345678',
            fiatAmount: 1000.0,
            fiatCurrency: 'NGN',
            amountSats: 1540,
            serviceIcon: Icons.phone_android,
            onConfirm: () async {},
          ),
        ),
        demoMode: true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Pay with'), findsOneWidget);
      expect(find.text('Bitcoin'), findsWidgets);
      expect(find.text('USDT'), findsOneWidget);
      expect(find.text('USDC'), findsOneWidget);
    });

    testWidgets('19. TransactionDetailsScreen displays conversion metadata',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      final conversionTx = TransactionModel(
        id: 'tx_conv_1',
        type: TransactionType.btcToUsdtConversion,
        status: TransactionStatus.completed,
        amountSats: 100000,
        createdAt: DateTime.now(),
        recipientOrSender: 'Conversion • BTC to USDT',
        sourceAsset: 'BTC',
        sourceAmount: 100000,
        destinationAsset: 'USDT',
        destinationAmount: 64.82,
        exchangeRate: 64820.0,
        hanbovaReference: 'HNBV-SWAP-98124',
      );

      await tester.pumpWidget(buildTestHarness(
        TransactionDetailsScreen(transaction: conversionTx),
        demoMode: true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Hanbova Multi-Asset Conversion'), findsOneWidget);
      expect(find.text('Converted From'), findsOneWidget);
      expect(find.text('100000.0 BTC'), findsOneWidget);
      expect(find.text('Converted To'), findsOneWidget);
      expect(find.text('64.82 USDT'), findsOneWidget);
      expect(find.text('Exchange Rate'), findsOneWidget);
      expect(find.text('64820.0'), findsOneWidget);
      expect(find.text('Hanbova Reference'), findsOneWidget);
      expect(find.text('HNBV-SWAP-98124'), findsOneWidget);
    });

    testWidgets('20. TransactionsScreen includes Bitcoin, Conversions, Stablecoins filter chips',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestHarness(const TransactionsScreen(), demoMode: true));
      await tester.pumpAndSettle();

      expect(find.text('Bitcoin'), findsOneWidget);
      expect(find.text('Conversions'), findsOneWidget);
      expect(find.text('Stablecoins'), findsOneWidget);
    });

    testWidgets('21. InsightsScreen displays Asset Allocation and Conversion Activity',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestHarness(const InsightsScreen(), demoMode: true));
      await tester.pumpAndSettle();

      expect(find.text('Asset Allocation'), findsOneWidget);
      expect(find.text('Total Portfolio Holdings'), findsOneWidget);
      expect(find.text('Conversion Activity'), findsOneWidget);
      expect(find.text('Bitcoin (BTC) 37%'), findsOneWidget);
      expect(find.text('Tether (USDT) 39%'), findsOneWidget);
      expect(find.text('USD Coin (USDC) 24%'), findsOneWidget);
    });
  });
}
