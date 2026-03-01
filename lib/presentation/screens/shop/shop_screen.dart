import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gameapp/l10n/app_localizations.dart';
import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/routing/app_router.dart';
import 'package:gameapp/data/datasources/local_storage.dart';
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
              const Tab(text: '일일 특가'),
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
              _DailyDealTab(),
            ],
          ),
        ),
      ],
    );

    if (embedded) {
      return DefaultTabController(
        length: 4,
        child: body,
      );
    }

    return DefaultTabController(
      length: 4,
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
// Daily Deal Tab
// =============================================================================

/// Represents one daily deal item.
class _DealItem {
  final String title;
  final String subtitle;
  final String cost;
  final IconData icon;
  final Color iconColor;
  final String purchaseKey;
  final Future<bool> Function(CurrencyNotifier n) spend;
  final Future<void> Function(CurrencyNotifier n) give;

  const _DealItem({
    required this.title,
    required this.subtitle,
    required this.cost,
    required this.icon,
    required this.iconColor,
    required this.purchaseKey,
    required this.spend,
    required this.give,
  });
}

class _DailyDealTab extends ConsumerStatefulWidget {
  const _DailyDealTab();

  @override
  ConsumerState<_DailyDealTab> createState() => _DailyDealTabState();
}

class _DailyDealTabState extends ConsumerState<_DailyDealTab> {
  static const _allDeals = [
    _DealItem(
      title: '소환권 1장',
      subtitle: '오늘의 특가! 가챠 소환권',
      cost: '100 G',
      icon: Icons.auto_awesome,
      iconColor: Colors.purple,
      purchaseKey: 'daily_deal_0',
      spend: _spendGold100,
      give: _giveTicket1,
    ),
    _DealItem(
      title: '골드팩 500',
      subtitle: '다이아 50개로 골드 500 획득',
      cost: '50 💎',
      icon: Icons.monetization_on,
      iconColor: Colors.amber,
      purchaseKey: 'daily_deal_1',
      spend: _spendDiamond50,
      give: _giveGold500,
    ),
    _DealItem(
      title: '경험치 부스트',
      subtitle: '경험치 포션 1개',
      cost: '200 G',
      icon: Icons.science,
      iconColor: Colors.green,
      purchaseKey: 'daily_deal_2',
      spend: _spendGold200,
      give: _giveExpPotion,
    ),
    _DealItem(
      title: '소환석 3개',
      subtitle: '진화 소환석 3개 묶음',
      cost: '150 G',
      icon: Icons.hexagon,
      iconColor: Colors.teal,
      purchaseKey: 'daily_deal_3',
      spend: _spendGold150,
      give: _giveShard3,
    ),
    _DealItem(
      title: '진화석 2개',
      subtitle: '진화에 필요한 진화석',
      cost: '300 G',
      icon: Icons.hexagon,
      iconColor: Colors.orange,
      purchaseKey: 'daily_deal_4',
      spend: _spendGold300,
      give: _giveShard2,
    ),
    _DealItem(
      title: '스태미나 5',
      subtitle: '배틀 스태미나 5 회복',
      cost: '80 G',
      icon: Icons.bolt,
      iconColor: Colors.yellow,
      purchaseKey: 'daily_deal_5',
      spend: _spendGold80,
      give: _giveGold100,
    ),
    _DealItem(
      title: '다이아 10개',
      subtitle: '다이아몬드 10개',
      cost: '500 G',
      icon: Icons.diamond,
      iconColor: Colors.cyan,
      purchaseKey: 'daily_deal_6',
      spend: _spendGold500,
      give: _giveDiamond10,
    ),
  ];

  // --- static spend/give helpers (top-level compatible via static) ---
  static Future<bool> _spendGold100(CurrencyNotifier n) => n.spendGold(100);
  static Future<bool> _spendDiamond50(CurrencyNotifier n) => n.spendDiamond(50);
  static Future<bool> _spendGold200(CurrencyNotifier n) => n.spendGold(200);
  static Future<bool> _spendGold150(CurrencyNotifier n) => n.spendGold(150);
  static Future<bool> _spendGold300(CurrencyNotifier n) => n.spendGold(300);
  static Future<bool> _spendGold80(CurrencyNotifier n) => n.spendGold(80);
  static Future<bool> _spendGold500(CurrencyNotifier n) => n.spendGold(500);
  static Future<void> _giveTicket1(CurrencyNotifier n) => n.addGachaTicket(1);
  static Future<void> _giveGold500(CurrencyNotifier n) => n.addGold(500);
  static Future<void> _giveExpPotion(CurrencyNotifier n) => n.addExpPotion(1);
  static Future<void> _giveShard3(CurrencyNotifier n) => n.addShard(3);
  static Future<void> _giveShard2(CurrencyNotifier n) => n.addShard(2);
  // stam not in currency — give gold instead as placeholder
  static Future<void> _giveGold100(CurrencyNotifier n) => n.addGold(100);
  static Future<void> _giveDiamond10(CurrencyNotifier n) => n.addDiamond(10);

  List<_DealItem> _getTodayDeals() {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final rng = Random(seed);
    final indices = List<int>.generate(_allDeals.length, (i) => i)..shuffle(rng);
    return [_allDeals[indices[0]], _allDeals[indices[1]], _allDeals[indices[2]]];
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  bool _isPurchased(_DealItem deal) {
    final storage = LocalStorage.instance;
    final key = '${deal.purchaseKey}_${_todayKey()}';
    return storage.getSetting<bool>(key) ?? false;
  }

  Future<void> _purchase(_DealItem deal) async {
    final storage = LocalStorage.instance;
    final key = '${deal.purchaseKey}_${_todayKey()}';
    final notifier = ref.read(currencyProvider.notifier);
    final ok = await deal.spend(notifier);
    if (!ok) {
      if (mounted) _snack(context, '재화가 부족합니다.');
      return;
    }
    await deal.give(notifier);
    await storage.setSetting<bool>(key, true);
    if (mounted) {
      setState(() {});
      _snack(context, '구매 완료!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final deals = _getTodayDeals();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_offer, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '매일 자정 리셋되는 특가 상품! 각 1회 구매 가능.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        ...deals.map((deal) {
          final purchased = _isPurchased(deal);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: purchased
                  ? AppColors.surface.withValues(alpha: 0.5)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: purchased
                    ? AppColors.border.withValues(alpha: 0.4)
                    : AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (purchased ? Colors.grey : deal.iconColor)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    deal.icon,
                    color: purchased ? Colors.grey : deal.iconColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deal.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: purchased
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        deal.subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (purchased)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '구매 완료',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () => _purchase(deal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          deal.cost,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          '구매',
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }),
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
