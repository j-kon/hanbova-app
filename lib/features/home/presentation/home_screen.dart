import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cashu/cashu_wallet_models.dart';
import '../../../core/cashu/cashu_wallet_provider.dart';
import '../../../core/crypto/crypto_identity_service.dart';
import '../../../core/currency/balance_visibility_provider.dart';
import '../../../core/currency/currency_provider.dart';
import '../../../core/network/network_environment.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/notifications/in_app_notification.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/wallet/wallet_context.dart';
import '../../auth/providers/auth_provider.dart';
import '../../protected/data/protected_message_service.dart';
import '../../protected_send/data/payment_intent_repository.dart';
import '../../security/presentation/mainnet_safety_dialog.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/presentation/transactions_provider.dart';
import '../../wallet/presentation/unified_deposit_sheet.dart';
import '../../../core/demo/demo_mode_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _syncTimer;
  String? _syncedContextId;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  void initState() {
    super.initState();
    _syncInbox();
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        _syncInbox();
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncInbox() async {
    final authState = ref.read(authProvider);
    final walletContext = ref.read(activeWalletContextKeyProvider);
    if (authState.user == null || walletContext == null) return;
    try {
      if (_syncedContextId != walletContext.storageId) {
        final identity =
            await ref.read(cryptoIdentityProvider.notifier).requireIdentity();
        final apiClient = ref.read(apiClientProvider);
        await ref.read(cryptoIdentityProvider.notifier).publishPublicKeys(
              apiClient: apiClient,
              identity: identity,
            );
        _syncedContextId = walletContext.storageId;
      }
      final messageService = ref.read(protectedMessageServiceProvider);
      final intentRepo = ref.read(paymentIntentRepositoryProvider);
      final inbox = await messageService.getInbox();
      if (!mounted) return;
      final newTxs =
          await ref.read(transactionsProvider.notifier).syncIncomingMessages(
                inbox: inbox,
                getIntentDetails: (id) => intentRepo.getPaymentIntent(id),
              );
      if (newTxs.isNotEmpty && mounted) {
        final newest = newTxs.first;
        ref.read(inAppNotificationProvider.notifier).show(
              title: 'Protected Payment Received!',
              message:
                  '${Formatters.formatSats(newest.amountSats)} waiting from ${newest.recipientOrSender}',
              icon: Icons.shield_outlined,
              type: InAppNotificationType.incoming,
              onTap: () {
                context.push('/claim');
              },
            );
      }

      // Sync full payment intent history (sent & received)
      try {
        final intents = await intentRepo.getPaymentIntents();
        if (mounted) {
          ref.read(transactionsProvider.notifier).syncPaymentIntents(
                intents: intents,
                currentUserId: authState.user!.id,
                currentUsername: authState.user!.username,
              );
        }
      } catch (_) {}
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final isBalanceVisible = ref.watch(balanceVisibilityProvider);
    final currency = ref.watch(currencyProvider);
    final transactions = ref.watch(transactionsProvider);
    final demoState = ref.watch(demoModeProvider);
    final cashuBalanceAsync = ref.watch(cashuBalanceProvider);
    final cashuBalance = cashuBalanceAsync.value ??
        const CashuWalletBalance(spendableSats: 0, lockedEscrowSats: 0);

    final protectedCount = transactions
        .where((t) =>
            t.type == TransactionType.protectedSend &&
            t.status == TransactionStatus.claimable)
        .length;
    final incomingClaimable = transactions
        .where((t) =>
            t.type == TransactionType.protectedClaim &&
            t.status == TransactionStatus.claimable)
        .toList();
    final protectedSats = cashuBalance.lockedEscrowSats;
    final spendableSats = cashuBalance.spendableSats;
    final totalBalanceSats = cashuBalance.totalSats;

    final greeting = _getGreeting();
    final firstName =
        user?.firstName.isNotEmpty == true ? user!.firstName : 'Jeremiah';

    final currentNetwork = ref.watch(networkEnvironmentProvider);
    final isPilotActive = ref.watch(mainnetPilotOverrideProvider);
    final netConfig =
        NetworkConfig.fromNetwork(currentNetwork, pilotActive: isPilotActive);
    final isMainnet = currentNetwork == HanbovaNetwork.mainnet;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(cashuBalanceProvider);
            ref.invalidate(transactionsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header (User profile, Greeting, Actions)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              colors.primary.withValues(alpha: 0.15),
                          child: Text(
                            firstName.isNotEmpty
                                ? firstName[0].toUpperCase()
                                : 'H',
                            style: AppTypography.titleMedium
                                .copyWith(color: colors.primary),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: AppTypography.caption
                                  .copyWith(color: colors.textSecondary),
                            ),
                            Text(
                              firstName,
                              style: AppTypography.titleMedium
                                  .copyWith(color: colors.textPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.notifications_none_rounded,
                              color: colors.textPrimary),
                          onPressed: () => context.push('/notifications'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 2. Demo Banner (if demo active)
                if (ref.watch(demoModeProvider).isEnabled)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.15),
                      borderRadius: AppRadius.xsRadius,
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: colors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'DEMO MODE • SAMPLE DATA • NO REAL MONEY',
                          style: AppTypography.caption.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                // 2. Balance Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colors.surfaceCard,
                    borderRadius: AppRadius.lgRadius,
                    border: Border.all(color: colors.border, width: 1),
                    boxShadow: AppShadows.card(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          if (!isMainnet) {
                            MainnetSafetyDialog.show(context);
                          }
                        },
                        borderRadius: AppRadius.xsRadius,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isMainnet
                                    ? (netConfig.isPilot
                                        ? Colors.amber
                                        : colors.success)
                                    : colors.gold)
                                .withValues(alpha: 0.12),
                            borderRadius: AppRadius.xsRadius,
                            border: Border.all(
                              color: (isMainnet
                                      ? (netConfig.isPilot
                                          ? Colors.amber
                                          : colors.success)
                                      : colors.gold)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isMainnet
                                    ? (netConfig.isPilot
                                        ? Icons.warning_amber_rounded
                                        : Icons.verified_user)
                                    : Icons.science_outlined,
                                color: isMainnet
                                    ? (netConfig.isPilot
                                        ? Colors.amber
                                        : colors.success)
                                    : colors.gold,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isMainnet
                                    ? (netConfig.isPilot
                                        ? 'PILOT DEMO • Max 10k sats • Real Bitcoin'
                                        : 'MAINNET (LOCKED)')
                                    : 'TEST MODE • No monetary value',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isMainnet
                                      ? (netConfig.isPilot
                                          ? Colors.amber
                                          : colors.success)
                                      : colors.gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Balance',
                            style: AppTypography.bodySmall
                                .copyWith(color: colors.textSecondary),
                          ),
                          IconButton(
                            icon: Icon(
                              isBalanceVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: colors.textTertiary,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => ref
                                .read(balanceVisibilityProvider.notifier)
                                .toggle(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      InkWell(
                        onTap: () => context.push('/money'),
                        borderRadius: AppRadius.smRadius,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fiat display
                            Text(
                              isBalanceVisible
                                  ? currency.format(totalBalanceSats)
                                  : '••••••••',
                              style: AppTypography.display.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),

                            // Sats display
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isBalanceVisible
                                      ? '${Formatters.formatSatsNumber(totalBalanceSats)} ${isMainnet ? "sats" : "test sats"}'
                                      : '•••• ${isMainnet ? "sats" : "test sats"}',
                                  style: AppTypography.titleSmall.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Balances Hub',
                                      style: TextStyle(
                                        color: colors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 14,
                                      color: colors.primary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Divider & Breakdown
                      Divider(color: colors.divider),
                      const SizedBox(height: AppSpacing.sm),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Spendable',
                                  style: AppTypography.caption
                                      .copyWith(color: colors.textTertiary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isBalanceVisible
                                      ? Formatters.formatSats(spendableSats)
                                      : '••••',
                                  style: AppTypography.titleSmall.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                              height: 28, width: 1, color: colors.divider),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Protected balance',
                                  style: AppTypography.caption
                                      .copyWith(color: colors.textTertiary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isBalanceVisible
                                      ? Formatters.formatSats(protectedSats)
                                      : '••••',
                                  style: AppTypography.titleSmall.copyWith(
                                    color: colors.protected,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 2.5 Attention Hub (High-priority actionable items only)
                // Card 1: Refund Available
                if (demoState.isEnabled &&
                    demoState.protectedRefundableSats > 0) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF06B6D4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.refresh_rounded,
                              color: Colors.black, size: 18),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Protected Refund Ready',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${Formatters.formatSats(demoState.protectedRefundableSats)} sats expired locktime can be claimed back.',
                                style: const TextStyle(
                                  color: AppColors.darkTextSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => context.push('/pending'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF06B6D4),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Refund',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Card 2: Payment Uncertain Notice
                if (transactions
                        .any((t) => t.status == TransactionStatus.uncertain) ||
                    (demoState.isEnabled &&
                        demoState.demoTransactions.any((t) =>
                            t.status == TransactionStatus.uncertain))) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.hourglass_top_rounded,
                              color: Colors.black, size: 18),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Processing (Uncertain)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Checking status with biller. Please don\'t pay again yet.',
                                style: TextStyle(
                                  color: AppColors.darkTextSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => context.push('/pending'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Status',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Card 3: Incoming Protected Payment Received
                if (incomingClaimable.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.incoming.withValues(alpha: 0.12),
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: colors.incoming.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: colors.incoming,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Protected Payment Received!',
                                style: AppTypography.titleSmall.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.incoming.withValues(alpha: 0.2),
                                borderRadius: AppRadius.xsRadius,
                              ),
                              child: Text(
                                '${incomingClaimable.length} Waiting',
                                style: AppTypography.caption.copyWith(
                                  color: colors.incoming,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${Formatters.formatSats(incomingClaimable.first.amountSats)} waiting from ${incomingClaimable.first.recipientOrSender}',
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.push('/claim');
                            },
                            icon: const Icon(Icons.check_circle_outline,
                                size: 18),
                            label: const Text('Claim to Wallet Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.incoming,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Card 4: eSIM Low Data Alert
                if (demoState.isEnabled) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF8B5CF6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sim_card_rounded,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'eSIM Low Data (250 MB left)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Kenya Traveler 3 GB eSIM is running low.',
                                style: TextStyle(
                                  color: AppColors.darkTextSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => context.push('/travel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Top Up',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 3. Primary Quick Action Grid (Send, Receive, Pay, Scan)
                Row(
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.arrow_upward_rounded,
                      label: 'Send',
                      color: colors.primary,
                      onTap: () => context.push('/send'),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      icon: Icons.arrow_downward_rounded,
                      label: 'Receive',
                      color: const Color(0xFF10B981),
                      onTap: () => UnifiedDepositSheet.show(context),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      icon: Icons.payments_rounded,
                      label: 'Pay',
                      color: const Color(0xFFF59E0B),
                      onTap: () => context.go('/pay'),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Scan',
                      color: const Color(0xFF38BDF8),
                      onTap: () => context.push('/scan'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 3.6 Financial Services Quick Hub Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickHubItem(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Money',
                        color: AppColors.primary,
                        onTap: () => context.push('/money'),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickHubItem(
                        icon: Icons.pie_chart_outline_rounded,
                        label: 'Insights',
                        color: const Color(0xFF38BDF8),
                        onTap: () => context.push('/insights'),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickHubItem(
                        icon: Icons.hourglass_top_rounded,
                        label: 'Pending Hub',
                        color: const Color(0xFFF59E0B),
                        onTap: () => context.push('/pending'),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickHubItem(
                        icon: Icons.request_quote_outlined,
                        label: 'Request',
                        color: const Color(0xFF10B981),
                        onTap: () => context.push('/request-money'),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickHubItem(
                        icon: Icons.credit_card_outlined,
                        label: 'Cards',
                        color: const Color(0xFFEC4899),
                        onTap: () => context.push('/cards'),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickHubItem(
                        icon: Icons.people_outline_rounded,
                        label: 'Beneficiaries',
                        color: const Color(0xFF8B5CF6),
                        onTap: () => context.push('/beneficiaries'),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickHubItem(
                        icon: Icons.description_outlined,
                        label: 'Statements',
                        color: AppColors.primary,
                        onTap: () => context.push('/statements'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 4. Protected Summary Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.protected.withValues(alpha: 0.08),
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(
                        color: colors.protected.withValues(alpha: 0.25),
                        width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: colors.protected.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.shield_outlined,
                            color: colors.protected, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Protected Payments',
                              style: AppTypography.titleSmall
                                  .copyWith(color: colors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$protectedCount active • ${Formatters.formatSats(protectedSats)} protected',
                              style: AppTypography.bodySmall
                                  .copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/protected'),
                        child: const Text('View'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 5. Quick Claim Banner
                Material(
                  color: colors.surfaceCard,
                  borderRadius: AppRadius.mdRadius,
                  child: InkWell(
                    onTap: () => context.push('/claim'),
                    borderRadius: AppRadius.mdRadius,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm + 2),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.mdRadius,
                        border: Border.all(color: colors.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.vpn_key_outlined,
                              color: colors.primary, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Have a claim code?',
                              style: AppTypography.bodyMedium
                                  .copyWith(color: colors.textPrimary),
                            ),
                          ),
                          Text(
                            'Claim',
                            style: AppTypography.titleSmall
                                .copyWith(color: colors.primary),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right,
                              color: colors.primary, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 6. Recent Activity Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: AppTypography.titleMedium
                          .copyWith(color: colors.textPrimary),
                    ),
                    TextButton(
                      onPressed: () => context.go('/activity'),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                // Recent Activity List
                if (transactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: colors.surfaceCard,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(color: colors.border, width: 1),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              color: colors.textTertiary, size: 36),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'No transactions yet',
                            style: AppTypography.titleSmall
                                .copyWith(color: colors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your Hanbova payments will appear here.',
                            style: AppTypography.bodySmall
                                .copyWith(color: colors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...transactions.take(4).map(
                        (tx) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: _TransactionCard(tx: tx),
                        ),
                      ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickHubItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.darkCardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends ConsumerWidget {
  final TransactionModel tx;

  const _TransactionCard({required this.tx});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currency = ref.watch(currencyProvider);

    IconData icon;
    Color iconColor;
    String prefix;

    switch (tx.type) {
      case TransactionType.instantSend:
        icon = Icons.arrow_upward;
        iconColor = colors.outgoing;
        prefix = '-';
        break;
      case TransactionType.instantReceive:
        icon = Icons.arrow_downward;
        iconColor = colors.incoming;
        prefix = '+';
        break;
      case TransactionType.protectedSend:
        icon = Icons.shield_outlined;
        iconColor = colors.protected;
        prefix = '-';
        break;
      case TransactionType.protectedClaim:
        icon = Icons.check_circle_outline;
        iconColor = colors.incoming;
        prefix = '+';
        break;
      case TransactionType.protectedRefund:
        icon = Icons.replay;
        iconColor = colors.success;
        prefix = '+';
        break;
      default:
        icon = tx.isOutgoing ? Icons.arrow_upward : Icons.arrow_downward;
        iconColor = tx.isOutgoing ? colors.outgoing : colors.incoming;
        prefix = tx.isOutgoing ? '-' : '+';
        break;
    }

    return Material(
      color: colors.surfaceCard,
      borderRadius: AppRadius.mdRadius,
      child: InkWell(
        onTap: () => context.push('/activity/details', extra: tx),
        borderRadius: AppRadius.mdRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: colors.border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.smRadius,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.recipientOrSender,
                      style: AppTypography.titleSmall
                          .copyWith(color: colors.textPrimary, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatDate(tx.createdAt),
                      style: AppTypography.bodySmall
                          .copyWith(color: colors.textTertiary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$prefix${Formatters.formatSats(tx.amountSats)}',
                    style: AppTypography.titleSmall.copyWith(
                      color:
                          tx.isOutgoing ? colors.textPrimary : colors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currency.format(tx.amountSats),
                    style: AppTypography.bodySmall
                        .copyWith(color: colors.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
