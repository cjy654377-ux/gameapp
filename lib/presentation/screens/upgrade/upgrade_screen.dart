import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/l10n/app_localizations.dart';
import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/core/constants/game_config.dart';
import 'package:gameapp/core/enums/monster_element.dart';
import 'package:gameapp/core/enums/monster_rarity.dart';
import 'package:gameapp/core/utils/format_utils.dart';
import 'package:gameapp/data/models/monster_model.dart';
import 'package:gameapp/domain/services/upgrade_service.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';
import 'package:gameapp/presentation/providers/monster_provider.dart';
import 'package:gameapp/presentation/providers/upgrade_provider.dart';
import 'package:gameapp/presentation/widgets/common/currency_bar.dart';
import 'package:gameapp/presentation/widgets/tutorial_overlay.dart';

class UpgradeScreen extends ConsumerWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId =
        ref.watch(upgradeProvider.select((s) => s.selectedMonsterId));

    // Listen for success messages.
    ref.listen<UpgradeState>(upgradeProvider, (prev, next) {
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 2),
          ),
        );
        ref.read(upgradeProvider.notifier).clearMessage();
      }
    });

    return TutorialOverlay(
      forStep: TutorialSteps.upgradeIntro,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const CurrencyBar(),
            Expanded(
              child: selectedId == null
                  ? const _MonsterSelector()
                  : const _UpgradePanel(),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _MonsterSelector — grid of owned monsters
// =============================================================================

class _MonsterSelector extends ConsumerWidget {
  const _MonsterSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final roster = ref.watch(monsterListProvider);

    if (roster.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pets_rounded, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              l.noMonsterOwned,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              l.getMonsterFromGacha,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Sort: highest rarity first, then by level descending.
    final sorted = List<MonsterModel>.from(roster)
      ..sort((a, b) {
        final rc = b.rarity.compareTo(a.rarity);
        if (rc != 0) return rc;
        return b.level.compareTo(a.level);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            l.selectMonsterToUpgrade,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              return _MonsterGridTile(monster: sorted[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _MonsterGridTile extends ConsumerWidget {
  const _MonsterGridTile({required this.monster});
  final MonsterModel monster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rarityEnum = MonsterRarity.fromRarity(monster.rarity);

    return GestureDetector(
      onTap: () => ref.read(upgradeProvider.notifier).selectMonster(monster.id),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.surface,
          border: Border.all(
            color: rarityEnum.color.withValues(alpha:0.4),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Element icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rarityEnum.color.withValues(alpha:0.15),
              ),
              child: Icon(
                _elementIcon(monster.element),
                color: rarityEnum.color,
                size: 18,
              ),
            ),
            const SizedBox(height: 4),
            // Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                monster.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: rarityEnum.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // Stars + Level
            Text(
              rarityEnum.starsDisplay,
              style: TextStyle(color: rarityEnum.color, fontSize: 8),
            ),
            Text(
              'Lv.${monster.level}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _UpgradePanel — main upgrade interface
// =============================================================================

class _UpgradePanel extends ConsumerWidget {
  const _UpgradePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId =
        ref.watch(upgradeProvider.select((s) => s.selectedMonsterId));
    final monster = ref.watch(
      monsterListProvider.select(
        (list) => list.where((m) => m.id == selectedId).firstOrNull,
      ),
    );
    final activeTab = ref.watch(upgradeProvider.select((s) => s.activeTab));

    if (monster == null) {
      // Selection became invalid (e.g. monster deleted).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(upgradeProvider.notifier).clearSelection();
      });
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Back + monster header
          _MonsterHeader(monster: monster),
          const SizedBox(height: 14),
          // Tab selector
          _TabSelector(activeTab: activeTab),
          const SizedBox(height: 14),
          // Tab content
          if (activeTab == UpgradeTab.levelUp)
            _LevelUpPanel(monster: monster)
          else if (activeTab == UpgradeTab.evolution)
            _EvolutionPanel(monster: monster)
          else if (activeTab == UpgradeTab.fusion)
            _FusionPanel(monster: monster)
          else
            _AwakeningPanel(monster: monster),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// =============================================================================
// _MonsterHeader — selected monster info
// =============================================================================

class _MonsterHeader extends ConsumerWidget {
  const _MonsterHeader({required this.monster});
  final MonsterModel monster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rarityEnum = MonsterRarity.fromRarity(monster.rarity);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            rarityEnum.color.withValues(alpha:0.15),
            AppColors.surface,
          ],
        ),
        border: Border.all(color: rarityEnum.color.withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => ref.read(upgradeProvider.notifier).clearSelection(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.card.withValues(alpha:0.6),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Monster icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rarityEnum.color.withValues(alpha:0.2),
            ),
            child: Icon(
              _elementIcon(monster.element),
              color: rarityEnum.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Name + details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      monster.name,
                      style: TextStyle(
                        color: rarityEnum.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      rarityEnum.starsDisplay,
                      style: TextStyle(color: rarityEnum.color, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Lv.${monster.level}  |  진화 ${monster.evolutionStage}단계',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
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
// _TabSelector
// =============================================================================

class _TabSelector extends ConsumerWidget {
  const _TabSelector({required this.activeTab});
  final UpgradeTab activeTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        _TabButton(
          label: l.upgradeLevelUp,
          icon: Icons.arrow_upward_rounded,
          isActive: activeTab == UpgradeTab.levelUp,
          onTap: () =>
              ref.read(upgradeProvider.notifier).setTab(UpgradeTab.levelUp),
        ),
        const SizedBox(width: 6),
        _TabButton(
          label: l.upgradeEvolution,
          icon: Icons.auto_awesome_rounded,
          isActive: activeTab == UpgradeTab.evolution,
          onTap: () =>
              ref.read(upgradeProvider.notifier).setTab(UpgradeTab.evolution),
        ),
        const SizedBox(width: 6),
        _TabButton(
          label: l.upgradeFusion,
          icon: Icons.merge_rounded,
          isActive: activeTab == UpgradeTab.fusion,
          onTap: () =>
              ref.read(upgradeProvider.notifier).setTab(UpgradeTab.fusion),
        ),
        const SizedBox(width: 6),
        _TabButton(
          label: l.upgradeAwakening,
          icon: Icons.brightness_7_rounded,
          isActive: activeTab == UpgradeTab.awakening,
          onTap: () =>
              ref.read(upgradeProvider.notifier).setTab(UpgradeTab.awakening),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isActive ? AppColors.primary : AppColors.surface,
            border: Border.all(
              color: isActive
                  ? AppColors.primaryLight.withValues(alpha:0.4)
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : AppColors.textTertiary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.textTertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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
// _LevelUpPanel
// =============================================================================

class _LevelUpPanel extends ConsumerWidget {
  const _LevelUpPanel({required this.monster});
  final MonsterModel monster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);
    final isProcessing =
        ref.watch(upgradeProvider.select((s) => s.isProcessing));
    final isMaxLevel = monster.level >= GameConfig.maxMonsterLevel;
    final goldCost = UpgradeService.levelUpGoldCost(monster);
    final canAffordGold = currency.canAfford(gold: goldCost);
    final expPerPotion = UpgradeService.expPerPotion(monster);

    return Column(
      children: [
        // Current stats
        _StatCard(monster: monster),
        const SizedBox(height: 12),

        if (isMaxLevel) ...[
          _InfoBanner(
            icon: Icons.emoji_events_rounded,
            text: l.maxLevelReached(GameConfig.maxMonsterLevel),
            color: AppColors.rarityLegendary,
          ),
        ] else ...[
          // Level-up stat preview
          _StatPreview(
            title: l.levelUpPreview,
            preview: UpgradeService.levelUpStatPreview(monster),
          ),
          const SizedBox(height: 12),

          // Gold level-up button
          _ActionButton(
            label: l.levelUpWithGold,
            sublabel: FormatUtils.formatGold(goldCost),
            icon: Icons.monetization_on_rounded,
            iconColor: AppColors.gold,
            enabled: canAffordGold && !isProcessing,
            onTap: () async {
              final ok =
                  await ref.read(upgradeProvider.notifier).levelUpWithGold();
              if (!ok && context.mounted) {
                _showError(context, l.goldShort);
              }
            },
          ),
          const SizedBox(height: 8),

          // Exp potion section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.science_rounded,
                        color: AppColors.experience, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      l.expPotion,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      l.expPotionOwned(currency.expPotion, expPerPotion),
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SmallActionButton(
                      label: l.potionUse1,
                      enabled: currency.expPotion >= 1 && !isProcessing,
                      onTap: () => _usePotion(ref, context, 1, l),
                    ),
                    const SizedBox(width: 6),
                    _SmallActionButton(
                      label: l.potionUse5,
                      enabled: currency.expPotion >= 5 && !isProcessing,
                      onTap: () => _usePotion(ref, context, 5, l),
                    ),
                    const SizedBox(width: 6),
                    _SmallActionButton(
                      label: l.potionUse10,
                      enabled: currency.expPotion >= 10 && !isProcessing,
                      onTap: () => _usePotion(ref, context, 10, l),
                    ),
                    const SizedBox(width: 6),
                    _SmallActionButton(
                      label: l.potionUseAll,
                      enabled: currency.expPotion >= 1 && !isProcessing,
                      onTap: () =>
                          _usePotion(ref, context, currency.expPotion, l),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _usePotion(WidgetRef ref, BuildContext context, int count, AppLocalizations l) async {
    final ok = await ref.read(upgradeProvider.notifier).useExpPotions(count);
    if (!ok && context.mounted) {
      _showError(context, l.expPotionShort);
    }
  }
}

// =============================================================================
// _EvolutionPanel
// =============================================================================

class _EvolutionPanel extends ConsumerWidget {
  const _EvolutionPanel({required this.monster});
  final MonsterModel monster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);
    final isProcessing =
        ref.watch(upgradeProvider.select((s) => s.isProcessing));
    final isMaxEvo =
        monster.evolutionStage >= GameConfig.maxEvolutionStage;

    return Column(
      children: [
        // Current stats
        _StatCard(monster: monster),
        const SizedBox(height: 12),

        // Evolution stage indicator
        _EvolutionStageIndicator(stage: monster.evolutionStage),
        const SizedBox(height: 12),

        if (isMaxEvo) ...[
          _InfoBanner(
            icon: Icons.workspace_premium_rounded,
            text: l.finalEvolutionDone,
            color: AppColors.rarityLegendary,
          ),
        ] else ...[
          // Evolution stat preview
          _StatPreview(
            title: l.evolutionPreview,
            preview: UpgradeService.evolutionStatPreview(monster),
          ),
          const SizedBox(height: 12),

          // Cost breakdown
          _EvolutionCostCard(monster: monster, currency: currency),
          const SizedBox(height: 12),

          // Evolve button
          Builder(builder: (context) {
            final shardCost = UpgradeService.evolutionShardCost(monster);
            final goldCost = UpgradeService.evolutionGoldCost(monster);
            final canAfford = currency.canAfford(
                gold: goldCost, monsterShard: shardCost);

            return _ActionButton(
              label: monster.evolutionStage == 0 ? l.firstEvolution : l.finalEvolution,
              sublabel: l.evolve,
              icon: Icons.auto_awesome_rounded,
              iconColor: AppColors.rarityEpic,
              enabled: canAfford && !isProcessing,
              onTap: () async {
                final ok =
                    await ref.read(upgradeProvider.notifier).evolve();
                if (!ok && context.mounted) {
                  _showError(context, l.materialShort);
                }
              },
            );
          }),
        ],
      ],
    );
  }
}

// =============================================================================
// _FusionPanel
// =============================================================================

class _FusionPanel extends ConsumerWidget {
  const _FusionPanel({required this.monster});
  final MonsterModel monster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final roster = ref.watch(monsterListProvider);
    final fusionId =
        ref.watch(upgradeProvider.select((s) => s.fusionMonsterId));
    final isProcessing =
        ref.watch(upgradeProvider.select((s) => s.isProcessing));
    final currency = ref.watch(currencyProvider);

    // Can't fuse 5★
    if (monster.rarity >= 5) {
      return _InfoBanner(
        icon: Icons.workspace_premium_rounded,
        text: l.fusionLegendaryLimit,
        color: AppColors.rarityLegendary,
      );
    }

    // Can't fuse team members
    if (monster.isInTeam) {
      return _InfoBanner(
        icon: Icons.info_rounded,
        text: l.fusionTeamLimit,
        color: AppColors.warning,
      );
    }

    // Find eligible fusion partners (same rarity, not in team, not self).
    final eligible = roster
        .where((m) =>
            m.id != monster.id &&
            m.rarity == monster.rarity &&
            !m.isInTeam)
        .toList()
      ..sort((a, b) => b.level.compareTo(a.level));

    MonsterModel? fusionMonster;
    if (fusionId != null) {
      try {
        fusionMonster = roster.firstWhere((m) => m.id == fusionId);
      } catch (_) {
        fusionMonster = null;
      }
    }

    final goldCost = UpgradeNotifier.fusionGoldCost(monster.rarity);
    final canAfford = currency.canAfford(gold: goldCost);
    final canFuse = fusionMonster != null &&
        UpgradeNotifier.canFuse(monster, fusionMonster) &&
        canAfford;

    final nextRarity = MonsterRarity.fromRarity(monster.rarity + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Explanation
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFFCE93D8).withValues(alpha: 0.1),
            border: Border.all(
              color: const Color(0xFFCE93D8).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.merge_rounded,
                  color: Color(0xFFCE93D8), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.fusionDesc(nextRarity.starsDisplay, nextRarity.koreanName),
                  style: const TextStyle(
                    color: Color(0xFFCE93D8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Fusion preview
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Monster A (selected)
              Expanded(
                child: _FusionSlot(
                  monster: monster,
                  label: l.material1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.add_rounded,
                    color: AppColors.textTertiary, size: 20),
              ),
              // Monster B (fusion partner)
              Expanded(
                child: fusionMonster != null
                    ? _FusionSlot(
                        monster: fusionMonster,
                        label: l.material2,
                        onClear: () => ref
                            .read(upgradeProvider.notifier)
                            .clearFusionSelection(),
                      )
                    : Container(
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.card,
                          border: Border.all(
                            color: AppColors.border,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            l.selectMaterial2,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded,
                    color: AppColors.textTertiary, size: 20),
              ),
              // Result
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: nextRarity.color.withValues(alpha: 0.15),
                  border: Border.all(
                    color: nextRarity.color.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.help_outline_rounded,
                        color: nextRarity.color, size: 20),
                    Text(
                      nextRarity.starsDisplay,
                      style: TextStyle(
                        color: nextRarity.color,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Cost
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.monetization_on_rounded,
                  color: AppColors.gold, size: 16),
              const SizedBox(width: 6),
              Text(
                l.fusionCost,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                FormatUtils.formatGold(goldCost),
                style: TextStyle(
                  color: canAfford ? AppColors.gold : AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Fuse button
        _ActionButton(
          label: l.fusionExecute,
          sublabel: l.fusionFormula(monster.rarity, monster.rarity + 1),
          icon: Icons.merge_rounded,
          iconColor: const Color(0xFFCE93D8),
          enabled: canFuse && !isProcessing,
          onTap: () async {
            final ok = await ref.read(upgradeProvider.notifier).fuse();
            if (!ok && context.mounted) {
              _showError(context, l.fusionCheckCondition);
            }
          },
        ),
        const SizedBox(height: 16),

        // Eligible partners grid
        if (eligible.isEmpty)
          _InfoBanner(
            icon: Icons.search_off_rounded,
            text: l.noFusionMaterial,
            color: AppColors.textTertiary,
          )
        else ...[
          Text(
            l.selectFusionMaterial,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: eligible.map((m) {
              final isSelected = m.id == fusionId;
              final rarityEnum = MonsterRarity.fromRarity(m.rarity);
              return GestureDetector(
                onTap: () => ref
                    .read(upgradeProvider.notifier)
                    .selectFusionMonster(m.id),
                child: Container(
                  width: 72,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? const Color(0xFFCE93D8).withValues(alpha: 0.2)
                        : AppColors.surface,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFCE93D8)
                          : rarityEnum.color.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _elementIcon(m.element),
                        color: rarityEnum.color,
                        size: 18,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        m.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: rarityEnum.color,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Lv.${m.level}',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _FusionSlot extends StatelessWidget {
  const _FusionSlot({
    required this.monster,
    required this.label,
    this.onClear,
  });

  final MonsterModel monster;
  final String label;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final rarityEnum = MonsterRarity.fromRarity(monster.rarity);
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: rarityEnum.color.withValues(alpha: 0.1),
        border: Border.all(color: rarityEnum.color.withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _elementIcon(monster.element),
                  color: rarityEnum.color,
                  size: 18,
                ),
                Text(
                  monster.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: rarityEnum.color,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
          if (onClear != null)
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// _EvolutionStageIndicator
// =============================================================================

class _EvolutionStageIndicator extends StatelessWidget {
  const _EvolutionStageIndicator({required this.stage});
  final int stage;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StageNode(label: l.basic, isActive: true, isCurrent: stage == 0),
          _StageArrow(done: stage >= 1),
          _StageNode(label: l.firstEvo, isActive: stage >= 1, isCurrent: stage == 1),
          _StageArrow(done: stage >= 2),
          _StageNode(label: l.finalEvo, isActive: stage >= 2, isCurrent: stage == 2),
        ],
      ),
    );
  }
}

class _StageNode extends StatelessWidget {
  const _StageNode({
    required this.label,
    required this.isActive,
    required this.isCurrent,
  });
  final String label;
  final bool isActive;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrent
                ? AppColors.primary
                : isActive
                    ? AppColors.success.withValues(alpha:0.3)
                    : AppColors.card,
            border: Border.all(
              color: isCurrent
                  ? AppColors.primaryLight
                  : isActive
                      ? AppColors.success
                      : AppColors.border,
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: isActive
              ? Icon(
                  isCurrent ? Icons.star_rounded : Icons.check_rounded,
                  color: isCurrent ? Colors.white : AppColors.success,
                  size: 14,
                )
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isCurrent ? AppColors.textPrimary : AppColors.textTertiary,
            fontSize: 9,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StageArrow extends StatelessWidget {
  const _StageArrow({required this.done});
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Icon(
        Icons.arrow_forward_rounded,
        color: done ? AppColors.success : AppColors.textTertiary,
        size: 16,
      ),
    );
  }
}

// =============================================================================
// _EvolutionCostCard
// =============================================================================

class _EvolutionCostCard extends StatelessWidget {
  const _EvolutionCostCard({
    required this.monster,
    required this.currency,
  });
  final MonsterModel monster;
  final dynamic currency;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final shardCost = UpgradeService.evolutionShardCost(monster);
    final goldCost = UpgradeService.evolutionGoldCost(monster);
    final hasShards = currency.monsterShard >= shardCost;
    final hasGold = currency.gold >= goldCost;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.evolutionMaterial,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Shards
          _CostRow(
            icon: Icons.diamond_outlined,
            label: l.evolutionStone,
            required: shardCost,
            current: currency.monsterShard,
            sufficient: hasShards,
          ),
          const SizedBox(height: 4),
          // Gold
          _CostRow(
            icon: Icons.monetization_on_rounded,
            label: l.gold,
            required: goldCost,
            current: currency.gold,
            sufficient: hasGold,
          ),
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.icon,
    required this.label,
    required this.required,
    required this.current,
    required this.sufficient,
  });

  final IconData icon;
  final String label;
  final int required;
  final int current;
  final bool sufficient;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const Spacer(),
        Text(
          FormatUtils.formatNumber(current),
          style: TextStyle(
            color: sufficient ? AppColors.textPrimary : AppColors.error,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          ' / ${FormatUtils.formatNumber(required)}',
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
        ),
      ],
    );
  }
}

// =============================================================================
// _StatCard — current monster stats
// =============================================================================

class _StatCard extends StatelessWidget {
  const _StatCard({required this.monster});
  final MonsterModel monster;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _StatRow(label: 'HP', value: monster.finalHp, color: AppColors.error),
          const SizedBox(height: 4),
          _StatRow(
              label: 'ATK',
              value: monster.finalAtk,
              color: AppColors.warning),
          const SizedBox(height: 4),
          _StatRow(
              label: 'DEF',
              value: monster.finalDef,
              color: AppColors.info),
          const SizedBox(height: 4),
          _StatRow(
              label: 'SPD',
              value: monster.finalSpd,
              color: AppColors.experience),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (value / 2000).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.card,
              valueColor: AlwaysStoppedAnimation<Color>(color.withValues(alpha:0.7)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          child: Text(
            value.round().toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _StatPreview — before/after comparison
// =============================================================================

class _StatPreview extends StatelessWidget {
  const _StatPreview({required this.title, required this.preview});
  final String title;
  final Map<String, (double, double)> preview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.surfaceVariant,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded,
                  color: AppColors.success, size: 14),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final entry in preview.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    entry.value.$1.round().toString(),
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward_rounded,
                        color: AppColors.success, size: 10),
                  ),
                  Text(
                    entry.value.$2.round().toString(),
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(+${(entry.value.$2 - entry.value.$1).round()})',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 9,
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
// _ActionButton
// =============================================================================

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.iconColor,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final IconData icon;
  final Color iconColor;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: enabled
                ? const [Color(0xFF3B1F7E), Color(0xFF6B3FA0)]
                : const [Color(0xFF2A2A40), Color(0xFF1F1F35)],
          ),
          border: Border.all(
            color: enabled
                ? AppColors.primary.withValues(alpha:0.4)
                : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.white : AppColors.disabledText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: enabled ? iconColor : AppColors.disabledText,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  sublabel,
                  style: TextStyle(
                    color: enabled ? iconColor : AppColors.disabledText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _SmallActionButton
// =============================================================================

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: enabled ? AppColors.experience.withValues(alpha:0.15) : AppColors.card,
            border: Border.all(
              color: enabled
                  ? AppColors.experience.withValues(alpha:0.4)
                  : AppColors.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: enabled ? AppColors.experience : AppColors.disabledText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _InfoBanner
// =============================================================================

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.text,
    required this.color,
  });
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha:0.1),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Shared helpers
// =============================================================================

void _showError(BuildContext context, String message) {
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

IconData _elementIcon(String element) =>
    MonsterElement.fromName(element)?.icon ?? Icons.pets_rounded;

// =============================================================================
// _AwakeningPanel — awakening (post-evolution enhancement)
// =============================================================================

class _AwakeningPanel extends ConsumerWidget {
  const _AwakeningPanel({required this.monster});
  final MonsterModel monster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final isMaxEvo = monster.evolutionStage >= GameConfig.maxEvolutionStage;
    final canAwaken = UpgradeNotifier.canAwaken(monster);
    final isMaxAwakening = monster.awakeningStars >= UpgradeNotifier.maxAwakeningStars;

    if (!isMaxEvo) {
      return _buildInfoBanner(
        icon: Icons.lock_outline,
        text: l.awakeningRequireEvo,
        color: AppColors.textTertiary,
      );
    }

    if (isMaxAwakening) {
      return Column(
        children: [
          _buildStarsDisplay(),
          const SizedBox(height: 12),
          _buildInfoBanner(
            icon: Icons.brightness_7_rounded,
            text: l.awakeningMaxDone,
            color: Colors.amber,
          ),
          const SizedBox(height: 8),
          _buildStatPreview(l),
        ],
      );
    }

    final goldCost = UpgradeNotifier.awakeningGoldCost(monster);
    final shardCost = UpgradeNotifier.awakeningShardCost(monster);
    final currency = ref.watch(currencyProvider);
    final canAfford = currency.canAfford(gold: goldCost, monsterShard: shardCost);
    final processing = ref.watch(upgradeProvider.select((s) => s.isProcessing));

    return Column(
      children: [
        _buildStarsDisplay(),
        const SizedBox(height: 12),
        _buildStatPreview(l),
        const SizedBox(height: 16),

        // Cost display
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(
                l.awakeningCostTitle(monster.awakeningStars + 1),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CostChip(
                    icon: Icons.monetization_on_rounded,
                    label: FormatUtils.formatNumber(goldCost),
                    available: currency.gold >= goldCost,
                  ),
                  _CostChip(
                    icon: Icons.diamond_rounded,
                    label: l.shardCost(shardCost),
                    available: currency.monsterShard >= shardCost,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Awaken button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canAwaken && canAfford && !processing
                ? () => ref.read(upgradeProvider.notifier).awaken()
                : null,
            icon: const Icon(Icons.brightness_7_rounded, size: 18),
            label: Text(
              processing ? l.awakeningInProgress : l.awakening,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.withValues(alpha: 0.9),
              foregroundColor: Colors.black87,
              disabledBackgroundColor: AppColors.surfaceVariant,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStarsDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(UpgradeNotifier.maxAwakeningStars, (i) {
        final active = i < monster.awakeningStars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Icon(
            active ? Icons.brightness_7_rounded : Icons.brightness_7_outlined,
            size: 28,
            color: active ? Colors.amber : AppColors.textTertiary,
          ),
        );
      }),
    );
  }

  Widget _buildStatPreview(AppLocalizations l) {
    final bonus = monster.awakeningStars * 10;
    final nextBonus = (monster.awakeningStars + 1) * 10;
    final isMax = monster.awakeningStars >= UpgradeNotifier.maxAwakeningStars;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            l.currentAwakeningBonus(bonus),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: bonus > 0 ? Colors.amber : AppColors.textTertiary,
            ),
          ),
          if (!isMax) ...[
            const SizedBox(height: 4),
            Text(
              l.nextAwakeningBonus(nextBonus),
              style: TextStyle(fontSize: 12, color: Colors.green[300]),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatMiniPreview(label: 'HP', value: monster.finalHp),
              _StatMiniPreview(label: 'ATK', value: monster.finalAtk),
              _StatMiniPreview(label: 'DEF', value: monster.finalDef),
              _StatMiniPreview(label: 'SPD', value: monster.finalSpd),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner({required IconData icon, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

class _CostChip extends StatelessWidget {
  const _CostChip({required this.icon, required this.label, required this.available});
  final IconData icon;
  final String label;
  final bool available;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: available ? AppColors.gold : AppColors.error),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: available ? AppColors.textPrimary : AppColors.error,
          ),
        ),
      ],
    );
  }
}

class _StatMiniPreview extends StatelessWidget {
  const _StatMiniPreview({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
        Text(
          '${value.round()}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
