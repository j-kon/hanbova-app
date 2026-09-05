import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hanbova_app/core/currency/currency_provider.dart';
import 'package:hanbova_app/core/demo/demo_mode_provider.dart';
import 'package:hanbova_app/core/theme/app_colors.dart';

class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  bool _revealDetails = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final demoState = ref.watch(demoModeProvider);
    final currency = ref.watch(currencyProvider);
    final card = demoState.demoCard;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          'Virtual Cards (Sandbox)',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: card == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.credit_card_off_outlined,
                    size: 64,
                    color: colors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Cards Created',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create an instant virtual Visa card for online global payments.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // Demo Banner
                if (demoState.isEnabled)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: colors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'DEMO MODE • SAMPLE DATA • NO REAL MONEY',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Sandbox Notice Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.science_outlined,
                          size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sandbox / Demo Experience. Virtual cards fund directly from Bitcoin satoshis for global subscriptions.',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Physical Card Mock Visual
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: card.isFrozen
                          ? [const Color(0xFF334155), const Color(0xFF1E293B)]
                          : [const Color(0xFF0F766E), const Color(0xFF042F2E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.credit_card,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                card.cardType,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          if (card.isFrozen)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('FROZEN',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            )
                          else
                            const Text(
                              'VISA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() => _revealDetails = !_revealDetails);
                            },
                            child: Row(
                              children: [
                                Expanded(
                                    child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          _revealDetails
                                              ? card.cardNumber
                                              : '•••• •••• •••• 9821',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 2.0,
                                            fontFamily: 'Courier',
                                          ),
                                        ))),
                                const SizedBox(width: 8),
                                Icon(
                                  _revealDetails
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 16,
                            runSpacing: 4,
                            children: [
                              Text(
                                card.cardholderName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'EXP: ${_revealDetails ? card.expiry : "••/••"}   CVV: ${_revealDetails ? card.cvv : "•••"}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Card Balance & Action Row
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CARD BALANCE',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${card.balanceUsd.toStringAsFixed(2)} USD',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '≈ ${currency.format(currency.fiatToSats(card.balanceUsd * 60000.0 / 60000.0))}',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showFundCardDialog(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Fund Card'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: AppColors.charcoal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Freeze / Unfreeze Toggle
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        card.isFrozen ? 'Card is Frozen' : 'Card is Active',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        card.isFrozen
                            ? 'Transactions are blocked. Tap to reactivate.'
                            : 'Online payments enabled. Tap to temporarily lock.',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      value: card.isFrozen,
                      activeTrackColor: Colors.red,
                      onChanged: (_) {
                        ref.read(demoModeProvider.notifier).toggleCardFreeze();
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Card Transactions History
                Text(
                  'Recent Card Activity',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                _buildCardTxRow(
                    'Netflix Subscription', '-\$15.99', 'Aug 28, 2026', colors),
                _buildCardTxRow(
                    'Amazon Web Services', '-\$42.50', 'Aug 21, 2026', colors),
                _buildCardTxRow('Card Funding (via Sats)', '+\$100.00',
                    'Aug 15, 2026', colors,
                    isPositive: true),

                const SizedBox(height: 30),
              ],
            ),
    );
  }

  Widget _buildCardTxRow(
      String merchant, String amount, String date, HanbovaColors colors,
      {bool isPositive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPositive
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : colors.surfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPositive ? Icons.add_rounded : Icons.shopping_bag_outlined,
                  color: isPositive
                      ? const Color(0xFF10B981)
                      : colors.textSecondary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    merchant,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    date,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              )),
            ],
          )),
          const SizedBox(width: 12),
          Text(
            amount,
            style: TextStyle(
              color: isPositive ? const Color(0xFF10B981) : colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showFundCardDialog(BuildContext context) {
    final colors = context.colors;
    final amountCtrl = TextEditingController(text: '50.00');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surfaceCard,
        title: Text('Fund Virtual Card',
            style: TextStyle(color: colors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter USD amount to load onto your card. Funds will be converted from Bitcoin sats.',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: colors.textPrimary, fontSize: 20),
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: TextStyle(color: colors.primary, fontSize: 20),
                labelText: 'Amount (USD)',
                labelStyle: TextStyle(color: colors.textSecondary),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: colors.border)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: colors.primary)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '≈ 75,000 sats at reference rate',
              style: TextStyle(color: colors.primary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(amountCtrl.text) ?? 0.0;
              if (val > 0) {
                ref.read(demoModeProvider.notifier).fundCard(val);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Card funded with \$${val.toStringAsFixed(2)} USD!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: AppColors.charcoal,
            ),
            child: const Text('Fund Now'),
          ),
        ],
      ),
    );
  }
}
