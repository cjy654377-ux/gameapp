import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gameapp/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../providers/currency_provider.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.shopTitle),
        backgroundColor: AppColors.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current balance
          _BalanceCard(gold: currency.gold, diamond: currency.diamond),
          const SizedBox(height: 16),

          // Exchange section
          Text(
            l.shopExchange,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _ShopItem(
            icon: Icons.monetization_on,
            iconColor: Colors.amber,
            title: l.shopBuyGold,
            subtitle: '10 ${l.diamond} → 1,000 ${l.gold}',
            cost: '10 💎',
            onBuy: () => _buyGoldWithDiamond(context, ref, l),
          ),
          _ShopItem(
            icon: Icons.diamond,
            iconColor: Colors.cyan,
            title: l.shopBuyDiamond,
            subtitle: '5,000 ${l.gold} → 1 ${l.diamond}',
            cost: '5,000 G',
            onBuy: () => _buyDiamondWithGold(context, ref, l),
          ),
          const SizedBox(height: 16),

          // Items section
          Text(
            l.shopItems,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _ShopItem(
            icon: Icons.auto_awesome,
            iconColor: Colors.purple,
            title: l.shopBuyTicket,
            subtitle: l.shopBuyTicketDesc,
            cost: '30 💎',
            onBuy: () => _buyGachaTicket(context, ref, l),
          ),
          _ShopItem(
            icon: Icons.science,
            iconColor: Colors.green,
            title: l.shopBuyExpPotion,
            subtitle: l.shopBuyExpPotionDesc,
            cost: '500 G',
            onBuy: () => _buyExpPotion(context, ref, l),
          ),
          _ShopItem(
            icon: Icons.auto_awesome,
            iconColor: Colors.deepPurple,
            title: l.shopBuyTicket10,
            subtitle: l.shopBuyTicket10Desc,
            cost: '250 💎',
            onBuy: () => _buyGachaTicket10(context, ref, l),
          ),
          _ShopItem(
            icon: Icons.science,
            iconColor: Colors.lightGreen,
            title: l.shopBuyExpPotion10,
            subtitle: l.shopBuyExpPotion10Desc,
            cost: '4,000 G',
            onBuy: () => _buyExpPotion10(context, ref, l),
          ),
        ],
      ),
    );
  }

  void _showResult(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _buyGoldWithDiamond(BuildContext context, WidgetRef ref, AppLocalizations l) async {
    final notifier = ref.read(currencyProvider.notifier);
    final ok = await notifier.spendDiamond(10);
    if (!ok) {
      if (context.mounted) _showResult(context, l.shopInsufficient);
      return;
    }
    await notifier.addGold(1000);
    if (context.mounted) _showResult(context, l.shopPurchaseSuccess);
  }

  void _buyDiamondWithGold(BuildContext context, WidgetRef ref, AppLocalizations l) async {
    final notifier = ref.read(currencyProvider.notifier);
    final ok = await notifier.spendGold(5000);
    if (!ok) {
      if (context.mounted) _showResult(context, l.shopInsufficient);
      return;
    }
    await notifier.addDiamond(1);
    if (context.mounted) _showResult(context, l.shopPurchaseSuccess);
  }

  void _buyGachaTicket(BuildContext context, WidgetRef ref, AppLocalizations l) async {
    final notifier = ref.read(currencyProvider.notifier);
    final ok = await notifier.spendDiamond(30);
    if (!ok) {
      if (context.mounted) _showResult(context, l.shopInsufficient);
      return;
    }
    await notifier.addGachaTicket(1);
    if (context.mounted) _showResult(context, l.shopPurchaseSuccess);
  }

  void _buyExpPotion(BuildContext context, WidgetRef ref, AppLocalizations l) async {
    final notifier = ref.read(currencyProvider.notifier);
    final ok = await notifier.spendGold(500);
    if (!ok) {
      if (context.mounted) _showResult(context, l.shopInsufficient);
      return;
    }
    await notifier.addExpPotion(1);
    if (context.mounted) _showResult(context, l.shopPurchaseSuccess);
  }

  void _buyGachaTicket10(BuildContext context, WidgetRef ref, AppLocalizations l) async {
    final notifier = ref.read(currencyProvider.notifier);
    final ok = await notifier.spendDiamond(250);
    if (!ok) {
      if (context.mounted) _showResult(context, l.shopInsufficient);
      return;
    }
    await notifier.addGachaTicket(10);
    if (context.mounted) _showResult(context, l.shopPurchaseSuccess);
  }

  void _buyExpPotion10(BuildContext context, WidgetRef ref, AppLocalizations l) async {
    final notifier = ref.read(currencyProvider.notifier);
    final ok = await notifier.spendGold(4000);
    if (!ok) {
      if (context.mounted) _showResult(context, l.shopInsufficient);
      return;
    }
    await notifier.addExpPotion(10);
    if (context.mounted) _showResult(context, l.shopPurchaseSuccess);
  }
}

// =============================================================================
// Balance Card
// =============================================================================

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.gold, required this.diamond});
  final int gold;
  final int diamond;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CurrencyDisplay(icon: Icons.monetization_on, color: Colors.amber, value: gold),
          Container(width: 1, height: 30, color: AppColors.border),
          _CurrencyDisplay(icon: Icons.diamond, color: Colors.cyan, value: diamond),
        ],
      ),
    );
  }
}

class _CurrencyDisplay extends StatelessWidget {
  const _CurrencyDisplay({required this.icon, required this.color, required this.value});
  final IconData icon;
  final Color color;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 6),
        Text(
          _formatValue(value),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatValue(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toString();
  }
}

// =============================================================================
// Shop Item Card
// =============================================================================

class _ShopItem extends StatelessWidget {
  const _ShopItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.cost,
    required this.onBuy,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String cost;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onBuy,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(cost, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(l.shopBuy, style: const TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
