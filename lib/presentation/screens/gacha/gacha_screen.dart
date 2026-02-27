import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/l10n/app_localizations.dart';
import 'package:gameapp/core/constants/game_config.dart';
import 'package:gameapp/core/enums/monster_element.dart';
import 'package:gameapp/core/enums/monster_rarity.dart';
import 'package:gameapp/data/static/monster_database.dart';
import 'package:gameapp/domain/services/gacha_service.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';
import 'package:gameapp/presentation/providers/gacha_provider.dart';
import 'package:gameapp/presentation/widgets/common/currency_bar.dart';
import 'package:gameapp/presentation/widgets/tutorial_overlay.dart';
import 'package:gameapp/routing/app_router.dart';
import 'package:go_router/go_router.dart';

class GachaScreen extends ConsumerWidget {
  const GachaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final showResults = ref.watch(gachaProvider.select((s) => s.showResults));

    return TutorialOverlay(
      forStep: TutorialSteps.gachaIntro,
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              Column(
                children: [
                  const CurrencyBar(),
                  // ── Summon type tabs ──────────────────────────────────
                  Container(
                    color: AppColors.surface,
                    child: TabBar(
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: const TextStyle(fontSize: 13),
                      tabs: [
                        Tab(text: l.tabMonster),
                        Tab(text: l.tabSkillSummon),
                        Tab(text: l.tabRelicSummon),
                        Tab(text: l.tabMountSummon),
                      ],
                    ),
                  ),
                  // ── Tab content ──────────────────────────────────────
                  const Expanded(
                    child: TabBarView(
                      children: [
                        _MonsterGachaTab(),
                        _SkillGachaTab(),
                        _RelicGachaTab(),
                        _MountGachaTab(),
                      ],
                    ),
                  ),
                ],
              ),
              if (showResults) const _ResultOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Monster Gacha Tab (original content)
// =============================================================================

class _MonsterGachaTab extends StatelessWidget {
  const _MonsterGachaTab();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(height: 12),
          _GachaBanner(),
          SizedBox(height: 16),
          _PityBar(),
          SizedBox(height: 16),
          _RateTable(),
          SizedBox(height: 20),
          _PullButtons(),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

// =============================================================================
// Skill Gacha Tab
// =============================================================================

class _SkillGachaTab extends ConsumerWidget {
  const _SkillGachaTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Banner
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_fix_high, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    l.skillSummonTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.skillSummonDesc,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Pull buttons
          _GenericPullButton(
            label: l.pull10,
            cost: '10',
            currencyIcon: Icons.confirmation_number,
            currencyColor: Colors.purple,
            onTap: () {
              // TODO: implement skill gacha pull
            },
          ),
          const SizedBox(height: 10),
          _GenericPullButton(
            label: l.pull100,
            cost: '100',
            currencyIcon: Icons.confirmation_number,
            currencyColor: Colors.purple,
            onTap: () {
              // TODO: implement skill gacha 100-pull
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Relic (Item) Gacha Tab
// =============================================================================

class _RelicGachaTab extends ConsumerWidget {
  const _RelicGachaTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Banner
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    l.relicSummonTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.relicSummonDesc,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _GenericPullButton(
            label: l.pull10,
            cost: '10',
            currencyIcon: Icons.toll,
            currencyColor: Colors.blue,
            onTap: () {
              // TODO: implement relic gacha pull
            },
          ),
          const SizedBox(height: 10),
          _GenericPullButton(
            label: l.pull100,
            cost: '100',
            currencyIcon: Icons.toll,
            currencyColor: Colors.blue,
            onTap: () {
              // TODO: implement relic gacha 100-pull
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Mount Gacha Tab
// =============================================================================

class _MountGachaTab extends ConsumerWidget {
  const _MountGachaTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Banner
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFFF9800)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pets, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    l.mountSummonTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.mountSummonDesc,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _GenericPullButton(
            label: l.pull1,
            cost: '300',
            currencyIcon: Icons.diamond,
            currencyColor: Colors.orange,
            onTap: () {
              // TODO: implement mount gacha pull
            },
          ),
          const SizedBox(height: 10),
          _GenericPullButton(
            label: l.pull10,
            cost: '2700',
            currencyIcon: Icons.diamond,
            currencyColor: Colors.orange,
            onTap: () {
              // TODO: implement mount gacha 10-pull
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Shared pull button widget
// =============================================================================

class _GenericPullButton extends StatelessWidget {
  const _GenericPullButton({
    required this.label,
    required this.cost,
    required this.currencyIcon,
    required this.currencyColor,
    required this.onTap,
  });

  final String label;
  final String cost;
  final IconData currencyIcon;
  final Color currencyColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: currencyColor.withValues(alpha: 0.15),
          foregroundColor: currencyColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: currencyColor.withValues(alpha: 0.4)),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(width: 10),
            Icon(currencyIcon, size: 18),
            const SizedBox(width: 4),
            Text(cost, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _GachaBanner — top visual banner
// =============================================================================

class _GachaBanner extends StatelessWidget {
  const _GachaBanner();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A0A3E),
            Color(0xFF3B1F7E),
            Color(0xFF6B3FA0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha:0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative particles
          ...List.generate(8, (i) {
            final rng = math.Random(i);
            return Positioned(
              left: rng.nextDouble() * 300,
              top: rng.nextDouble() * 160,
              child: Icon(
                Icons.star_rounded,
                color: Colors.white.withValues(alpha:0.1 + rng.nextDouble() * 0.15),
                size: 12 + rng.nextDouble() * 18,
              ),
            );
          }),
          // History button (top-right)
          Positioned(
            top: 12,
            right: 12,
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () => context.push(AppRoutes.gachaHistory),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history_rounded, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        l.gachaHistoryTitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: AppColors.rarityLegendary,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.gachaTitle,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            color: AppColors.primary.withValues(alpha:0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l.gachaDesc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha:0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.rarityLegendary.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.rarityLegendary.withValues(alpha:0.4),
                    ),
                  ),
                  child: Text(
                    l.gachaLegendaryUp,
                    style: const TextStyle(
                      color: AppColors.rarityLegendary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _PityBar — pity counter progress bar
// =============================================================================

class _PityBar extends ConsumerWidget {
  const _PityBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final pityCount = ref.watch(gachaProvider.select((s) => s.pityCount));
    final remaining = GameConfig.pityThreshold - pityCount;
    final progress = pityCount / GameConfig.pityThreshold;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.whatshot_rounded,
                    color: pityCount >= 80
                        ? AppColors.rarityLegendary
                        : AppColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l.gachaUntilLegend,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '$pityCount / ${GameConfig.pityThreshold}',
                style: TextStyle(
                  color: pityCount >= 80
                      ? AppColors.rarityLegendary
                      : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.card,
              valueColor: AlwaysStoppedAnimation<Color>(
                pityCount >= 80
                    ? AppColors.rarityLegendary
                    : pityCount >= 50
                        ? AppColors.rarityEpic
                        : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            remaining > 0 ? l.gachaRemainingCount(remaining) : l.gachaNextGuaranteed,
            style: TextStyle(
              color: remaining <= 0
                  ? AppColors.rarityLegendary
                  : AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _RateTable — gacha probability breakdown
// =============================================================================

class _RateTable extends StatelessWidget {
  const _RateTable();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final probs = MonsterDatabase.gachaProbabilities;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 6),
              Text(
                l.gachaRates,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int rarity = 5; rarity >= 1; rarity--)
            _buildRateRow(rarity, probs[rarity] ?? 0),
        ],
      ),
    );
  }

  Widget _buildRateRow(int rarity, double probability) {
    final rarityEnum = MonsterRarity.fromRarity(rarity);
    final percent = (probability * 100).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rarityEnum.color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            rarityEnum.starsDisplay,
            style: TextStyle(
              color: rarityEnum.color,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            rarityEnum.koreanName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            '$percent%',
            style: TextStyle(
              color: rarityEnum.color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _PullButtons — single and 10x pull buttons
// =============================================================================

class _PullButtons extends ConsumerWidget {
  const _PullButtons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);
    final isAnimating = ref.watch(gachaProvider.select((s) => s.isAnimating));

    final canSingleDiamond = currency.diamond >= GameConfig.singlePullCostDiamond;
    final canSingleTicket = currency.gachaTicket >= 1;
    final canTen = currency.diamond >= GameConfig.tenPullCostDiamond;

    return Column(
      children: [
        // 10x Pull button (featured)
        _PullButton(
          label: l.gachaTenPull,
          sublabel: '${GameConfig.tenPullCostDiamond}',
          icon: Icons.diamond_rounded,
          iconColor: AppColors.diamond,
          gradient: canTen && !isAnimating
              ? const [Color(0xFF6B3FA0), Color(0xFF3B1F7E)]
              : const [Color(0xFF2A2A40), Color(0xFF1F1F35)],
          enabled: canTen && !isAnimating,
          badge: l.gachaThreeStarGuarantee,
          onTap: () async {
            final notifier = ref.read(gachaProvider.notifier);
            final success = await notifier.pullTenWithDiamond();
            if (!success && context.mounted) {
              _showInsufficientDialog(context, l.gachaDiamondShort);
            }
          },
        ),
        const SizedBox(height: 10),
        // Single pull row
        Row(
          children: [
            // Single with diamond
            Expanded(
              child: _PullButton(
                label: l.gachaSinglePull,
                sublabel: '${GameConfig.singlePullCostDiamond}',
                icon: Icons.diamond_rounded,
                iconColor: AppColors.diamond,
                gradient: canSingleDiamond && !isAnimating
                    ? const [Color(0xFF2A3F60), Color(0xFF1A2A40)]
                    : const [Color(0xFF2A2A40), Color(0xFF1F1F35)],
                enabled: canSingleDiamond && !isAnimating,
                compact: true,
                onTap: () async {
                  final notifier = ref.read(gachaProvider.notifier);
                  final success = await notifier.pullSingleWithDiamond();
                  if (!success && context.mounted) {
                    _showInsufficientDialog(context, l.gachaDiamondShort);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            // Single with ticket
            Expanded(
              child: _PullButton(
                label: l.gachaUseTicket,
                sublabel: l.gachaTicketCount(currency.gachaTicket),
                icon: Icons.confirmation_number_rounded,
                iconColor: AppColors.primaryLight,
                gradient: canSingleTicket && !isAnimating
                    ? const [Color(0xFF2A4040), Color(0xFF1A2A30)]
                    : const [Color(0xFF2A2A40), Color(0xFF1F1F35)],
                enabled: canSingleTicket && !isAnimating,
                compact: true,
                onTap: () async {
                  final notifier = ref.read(gachaProvider.notifier);
                  final success = await notifier.pullSingleWithTicket();
                  if (!success && context.mounted) {
                    _showInsufficientDialog(context, l.gachaTicketShort);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showInsufficientDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// =============================================================================
// _PullButton — reusable pull button widget
// =============================================================================

class _PullButton extends StatelessWidget {
  const _PullButton({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.iconColor,
    required this.gradient,
    required this.enabled,
    required this.onTap,
    this.badge,
    this.compact = false,
  });

  final String label;
  final String sublabel;
  final IconData icon;
  final Color iconColor;
  final List<Color> gradient;
  final bool enabled;
  final VoidCallback onTap;
  final String? badge;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: enabled,
      child: GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 20,
          vertical: compact ? 14 : 16,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(colors: gradient),
          border: Border.all(
            color: enabled
                ? AppColors.primary.withValues(alpha:0.4)
                : AppColors.border,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha:0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.rarityRare.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: AppColors.rarityRare,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.white : AppColors.disabledText,
                fontSize: compact ? 14 : 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: enabled ? iconColor : AppColors.disabledText,
                  size: compact ? 14 : 16,
                ),
                const SizedBox(width: 4),
                Text(
                  sublabel,
                  style: TextStyle(
                    color: enabled ? iconColor : AppColors.disabledText,
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w600,
                  ),
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

// =============================================================================
// _ResultOverlay — card reveal animation
// =============================================================================

class _ResultOverlay extends ConsumerStatefulWidget {
  const _ResultOverlay();

  @override
  ConsumerState<_ResultOverlay> createState() => _ResultOverlayState();
}

class _ResultOverlayState extends ConsumerState<_ResultOverlay>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _entranceFade;
  late Animation<double> _entranceScale;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _entranceScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );
    _entranceController.forward();

    // Auto-reveal cards one by one.
    _autoReveal();
  }

  Future<void> _autoReveal() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final results = ref.read(gachaProvider).lastResults;
    for (int i = 0; i < results.length; i++) {
      if (!mounted) return;
      ref.read(gachaProvider.notifier).revealNext();
      // Longer pause for higher rarity.
      final rarity = results[i].template.rarity;
      await Future.delayed(Duration(milliseconds: rarity >= 4 ? 600 : 300));
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final results = ref.watch(gachaProvider.select((s) => s.lastResults));
    final revealIndex = ref.watch(gachaProvider.select((s) => s.revealIndex));

    return FadeTransition(
      opacity: _entranceFade,
      child: Container(
        color: AppColors.overlayDark,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Title
              Text(
                results.length == 1 ? l.gachaResultSingle : l.gachaResultTen,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              // Cards grid
              Expanded(
                child: ScaleTransition(
                  scale: _entranceScale,
                  child: results.length == 1
                      ? Center(
                          child: _ResultCard(
                            result: results[0],
                            revealed: revealIndex >= 0,
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: RepaintBoundary(child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.7,
                            ),
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              return _ResultCard(
                                result: results[index],
                                revealed: index <= revealIndex,
                              );
                            },
                          )),
                        ),
                ),
              ),
              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    if (revealIndex < results.length - 1)
                      Expanded(
                        child: _OverlayButton(
                          label: l.gachaRevealAll,
                          onTap: () =>
                              ref.read(gachaProvider.notifier).revealAll(),
                        ),
                      ),
                    if (revealIndex < results.length - 1)
                      const SizedBox(width: 10),
                    Expanded(
                      child: _OverlayButton(
                        label: l.confirm,
                        primary: true,
                        onTap: () =>
                            ref.read(gachaProvider.notifier).dismissResults(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _ResultCard — individual card in results
// =============================================================================

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.revealed});

  final GachaPullResult result;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final template = result.template;
    final rarityEnum = MonsterRarity.fromRarity(template.rarity);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: revealed
          ? Container(
              key: const ValueKey('revealed'),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    rarityEnum.color.withValues(alpha:0.3),
                    AppColors.surface,
                  ],
                ),
                border: Border.all(
                  color: rarityEnum.color.withValues(alpha:0.6),
                  width: template.rarity >= 4 ? 2 : 1,
                ),
                boxShadow: template.rarity >= 4
                    ? [
                        BoxShadow(
                          color: rarityEnum.color.withValues(alpha:0.3),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rarity stars
                  Text(
                    rarityEnum.starsDisplay,
                    style: TextStyle(
                      color: rarityEnum.color,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Monster icon placeholder
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rarityEnum.color.withValues(alpha:0.2),
                    ),
                    child: Icon(
                      _getElementIcon(template.element),
                      color: rarityEnum.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Monster name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      template.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: rarityEnum.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (result.wasPity)
                    Text(
                      l.gachaGuaranteed,
                      style: const TextStyle(
                        color: AppColors.rarityLegendary,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            )
          // Unrevealed card back
          : Container(
              key: const ValueKey('hidden'),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.card,
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Icon(
                  Icons.help_outline_rounded,
                  color: AppColors.textTertiary,
                  size: 28,
                ),
              ),
            ),
    );
  }

  IconData _getElementIcon(String element) {
    return MonsterElement.fromName(element)?.icon ?? Icons.pets_rounded;
  }
}

// =============================================================================
// _OverlayButton
// =============================================================================

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: primary ? AppColors.primary : AppColors.surface,
            border: Border.all(
              color: primary
                  ? AppColors.primaryLight.withValues(alpha:0.4)
                  : AppColors.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primary ? Colors.white : AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
