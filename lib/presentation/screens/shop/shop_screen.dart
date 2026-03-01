import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gameapp/l10n/app_localizations.dart';
import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/routing/app_router.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';
import 'package:gameapp/presentation/widgets/common/currency_bar.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key, this.embedded = false});

  /// When true, renders without Scaffold/CurrencyBar for bottom sheet embedding.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;

    final body = Column(
      children: [
        if (!embedded) const CurrencyBar(),
        // Header with settings gear
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.store, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(l.shopHeader,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.settings, color: AppColors.textSecondary),
                onPressed: () => context.push(AppRoutes.settings),
              ),
            ],
          ),
        ),
        // Tabs
        Container(
          color: AppColors.surface,
          child: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: [
              Tab(text: l.shopTabGeneral),
              Tab(text: l.shopTabSummon),
              Tab(text: l.shopTabCurrency),
            ],
          ),
        ),
        // Tab content
        const Expanded(
          child: TabBarView(
            children: [
              _GeneralShopTab(),
              _SummonShopTab(),
              _CurrencyShopTab(),
            ],
          ),
        ),
      ],
    );

    if (embedded) {
      return DefaultTabController(
        length: 3,
        child: body,
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: body,
      ),
    );
  }
}

// =============================================================================
// General Shop Tab (original items)
// =============================================================================

class _GeneralShopTab extends ConsumerWidget {
  const _GeneralShopTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle(title: l.shopItems),
        const SizedBox(height: 8),
        _ShopItem(
          icon: Icons.auto_awesome,
          iconColor: Colors.purple,
          title: l.shopBuyTicket,
          subtitle: l.shopBuyTicketDesc,
          cost: '30 💎',
          onBuy: () async {
            final n = ref.read(currencyProvider.notifier);
            if (!await n.spendDiamond(30)) {
              if (!context.mounted) return;
              _snack(context, l.shopInsufficient);
              return;
            }
            await n.addGachaTicket(1);
            if (!context.mounted) return;
            _snack(context, l.shopPurchaseSuccess);
          },
        ),
        _ShopItem(
          icon: Icons.auto_awesome,
          iconColor: Colors.deepPurple,
          title: l.shopBuyTicket10,
          subtitle: l.shopBuyTicket10Desc,
          cost: '250 💎',
          onBuy: () async {
            final n = ref.read(currencyProvider.notifier);
            if (!await n.spendDiamond(250)) {
              if (!context.mounted) return;
              _snack(context, l.shopInsufficient);
              return;
            }
            await n.addGachaTicket(10);
            if (!context.mounted) return;
            _snack(context, l.shopPurchaseSuccess);
          },
        ),
        _ShopItem(
          icon: Icons.science,
          iconColor: Colors.green,
          title: l.shopBuyExpPotion,
          subtitle: l.shopBuyExpPotionDesc,
          cost: '500 G',
          onBuy: () async {
            final n = ref.read(currencyProvider.notifier);
            if (!await n.spendGold(500)) {
              if (!context.mounted) return;
              _snack(context, l.shopInsufficient);
              return;
            }
            await n.addExpPotion(1);
            if (!context.mounted) return;
            _snack(context, l.shopPurchaseSuccess);
          },
        ),
        _ShopItem(
          icon: Icons.science,
          iconColor: Colors.lightGreen,
          title: l.shopBuyExpPotion10,
          subtitle: l.shopBuyExpPotion10Desc,
          cost: '4,000 G',
          onBuy: () async {
            final n = ref.read(currencyProvider.notifier);
            if (!await n.spendGold(4000)) {
              if (!context.mounted) return;
              _snack(context, l.shopInsufficient);
              return;
            }
            await n.addExpPotion(10);
            if (!context.mounted) return;
            _snack(context, l.shopPurchaseSuccess);
          },
        ),
        _ShopItem(
          icon: Icons.hexagon,
          iconColor: Colors.teal,
          title: l.shopBuyShard,
          subtitle: l.shopBuyShardDesc,
          cost: '20 💎',
          onBuy: () async {
            final n = ref.read(currencyProvider.notifier);
            if (!await n.spendDiamond(20)) {
              if (!context.mounted) return;
              _snack(context, l.shopInsufficient);
              return;
            }
            await n.addShard(5);
            if (!context.mounted) return;
            _snack(context, l.shopPurchaseSuccess);
          },
        ),
        _ShopItem(
          icon: Icons.hexagon,
          iconColor: Colors.tealAccent,
          title: l.shopBuyShard10,
          subtitle: l.shopBuyShard10Desc,
          cost: '70 💎',
          onBuy: () async {
            final n = ref.read(currencyProvider.notifier);
            if (!await n.spendDiamond(70)) {
              if (!context.mounted) return;
              _snack(context, l.shopInsufficient);
              return;
            }
            await n.addShard(20);
            if (!context.mounted) return;
            _snack(context, l.shopPurchaseSuccess);
          },
        ),
      ],
    );
  }
}

// =============================================================================
// Summon Shop Tab (gacha tickets for new systems)
// =============================================================================

class _SummonShopTab extends ConsumerWidget {
  const _SummonShopTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle(title: l.shopSkillTicket),
        const SizedBox(height: 8),
        _ShopItem(
          icon: Icons.confirmation_number,
          iconColor: Colors.purple,
          title: l.shopSkillTicket1,
          subtitle: l.shopSkillTicket1Desc,
          cost: '20 💎',
          onBuy: () async {
            final n = ref.read(currencyProvider.notifier);
            if (!await n.spendDiamond(20)) {
              if (!context.mounted) return;
              _snack(context, l.shopInsufficient);
              return;
            }
            await n.addSkillTicket(1);
            if (!context.mounted) return;
            _snack(context, l.shopPurchaseSuccess);
          },
        ),
        _ShopItem(
          icon: Icons.confirmation_number,
          iconColor: Colors.deepPurple,
          title: l.shopSkillTicket10,
          subtitle: l.shopBulkDiscount,
          cost: '170 💎',
          onBuy: () async {
            final n = ref.read(currencyProvider.notifier);
            if (!await n.spendDiamond(170)) {
              if (!context.mounted) return;
              _snack(context, l.shopInsufficient);
              return;
            }
            await n.addSkillTicket(10);
            if (!context.mounted) return;
            _snack(context, l.shopPurchaseSuccess);
          },
        ),
        const SizedBox(height: 16),
        _SectionTitle(title: l.shopRelicTicket),
        const SizedBox(height: 8),
        _ShopItem(
          icon: Icons.toll,
          iconColor: Colors.blue,
          title: l.shopRelicTicket1,
          subtitle: l.shopRelicTicket1Desc,
          cost: '20 💎',
          onBuy: () async {
            final n = ref.read(currencyProvider.notifier);
            if (!await n.spendDiamond(20)) {
              if (!context.mounted) return;
              _snack(context, l.shopInsufficient);
              return;
            }
            await n.addRelicTicket(1);
            if (!context.mounted) return;
            _snack(context, l.shopPurchaseSuccess);
          },
        ),
        _ShopItem(
          icon: Icons.toll,
          iconColor: Colors.blueAccent,
          title: l.shopRelicTicket10,
          subtitle: l.shopBulkDiscount,
          cost: '170 💎',
          onBuy: () async {
            final n = ref.read(currencyProvider.notifier);
            if (!await n.spendDiamond(170)) {
              if (!context.mounted) return;
              _snack(context, l.shopInsufficient);
              return;
            }
            await n.addRelicTicket(10);
            if (!context.mounted) return;
            _snack(context, l.shopPurchaseSuccess);
          },
        ),
        const SizedBox(height: 16),
        _SectionTitle(title: l.shopMountGem),
        const SizedBox(height: 8),
        _ShopItem(
          icon: Icons.diamond,
          iconColor: Colors.orange,
          title: l.shopMountGem300,
          subtitle: l.shopMountGem300Desc,
          cost: '30 💎',
          onBuy: () async {
            final n = ref.read(currencyProvider.notifier);
            if (!await n.spendDiamond(30)) {
              if (!context.mounted) return;
              _snack(context, l.shopInsufficient);
              return;
            }
            await n.addMountGem(300);
            if (!context.mounted) return;
            _snack(context, l.shopPurchaseSuccess);
          },
        ),
        _ShopItem(
          icon: Icons.diamond,
          iconColor: Colors.deepOrange,
          title: l.shopMountGem3000,
          subtitle: l.shopMountGem3000Desc,
          cost: '270 💎',
          onBuy: () async {
            final n = ref.read(currencyProvider.notifier);
            if (!await n.spendDiamond(270)) {
              if (!context.mounted) return;
              _snack(context, l.shopInsufficient);
              return;
            }
            await n.addMountGem(3000);
            if (!context.mounted) return;
            _snack(context, l.shopPurchaseSuccess);
          },
        ),
      ],
    );
  }
}

// =============================================================================
// Currency Shop Tab (exchange)
// =============================================================================

class _CurrencyShopTab extends ConsumerWidget {
  const _CurrencyShopTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle(title: l.shopCurrencyExchange),
        const SizedBox(height: 8),
        _ShopItem(
          icon: Icons.monetization_on,
          iconColor: Colors.amber,
          title: l.shopBuyGold,
          subtitle: l.shopExchangeGoldDesc,
          cost: '10 💎',
          onBuy: () async {
            final n = ref.read(currencyProvider.notifier);
            if (!await n.spendDiamond(10)) {
              if (!context.mounted) return;
              _snack(context, l.shopInsufficient);
              return;
            }
            await n.addGold(1000);
            if (!context.mounted) return;
            _snack(context, l.shopPurchaseSuccess);
          },
        ),
        _ShopItem(
          icon: Icons.monetization_on,
          iconColor: Colors.amberAccent,
          title: l.shopBulkGold,
          subtitle: l.shopExchangeBulkGoldDesc,
          cost: '90 💎',
          onBuy: () async {
            final n = ref.read(currencyProvider.notifier);
            if (!await n.spendDiamond(90)) {
              if (!context.mounted) return;
              _snack(context, l.shopInsufficient);
              return;
            }
            await n.addGold(10000);
            if (!context.mounted) return;
            _snack(context, l.shopPurchaseSuccess);
          },
        ),
        _ShopItem(
          icon: Icons.diamond,
          iconColor: Colors.cyan,
          title: l.shopBuyDiamond,
          subtitle: '5,000 골드 → 1 다이아',
          cost: '5,000 G',
          onBuy: () async {
            final n = ref.read(currencyProvider.notifier);
            if (!await n.spendGold(5000)) {
              if (!context.mounted) return;
              _snack(context, l.shopInsufficient);
              return;
            }
            await n.addDiamond(1);
            if (!context.mounted) return;
            _snack(context, l.shopPurchaseSuccess);
          },
        ),
      ],
    );
  }
}

// =============================================================================
// Shared Widgets
// =============================================================================

void _snack(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

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
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
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
