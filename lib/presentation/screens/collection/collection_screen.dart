import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gameapp/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/enums/monster_element.dart';
import '../../../core/enums/monster_rarity.dart';
import '../../../routing/app_router.dart';
import '../../providers/collection_provider.dart';
import '../../widgets/common/currency_bar.dart';
import '../../widgets/tutorial_overlay.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final entries = ref.watch(collectionEntriesProvider);
    final stats = ref.watch(collectionStatsProvider);
    final filter = ref.watch(collectionFilterProvider);

    return TutorialOverlay(
      forStep: TutorialSteps.teamIntro,
      nextStep: TutorialSteps.completed,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(AppRoutes.teamEdit),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.groups, color: Colors.white),
          label: Text(l.teamEdit, style: const TextStyle(color: Colors.white)),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const CurrencyBar(),
              _buildHeader(context, stats),
              _buildMilestoneBar(context, ref),
              _buildFilterBar(context, ref, filter),
              Expanded(
                child: entries.isEmpty
                    ? _buildEmpty(context)
                    : _buildGrid(context, ref, entries),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, ({int total, int owned}) stats) {
    final l = AppLocalizations.of(context)!;
    final progress = stats.total > 0 ? stats.owned / stats.total : 0.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Text(
            l.monsterCollection,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          Text(
            '${stats.owned}/${stats.total}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            height: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceVariant,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneBar(BuildContext context, WidgetRef ref) {
    final milestones = ref.watch(collectionMilestoneProvider);

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: milestones.map((m) {
          final canClaim = m.reached && !m.claimed;
          final color = m.claimed
              ? Colors.green
              : m.reached
                  ? Colors.amber
                  : AppColors.textTertiary;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              avatar: Icon(
                m.claimed
                    ? Icons.check_circle
                    : m.reached
                        ? Icons.card_giftcard
                        : Icons.lock,
                size: 16,
                color: color,
              ),
              label: Text(
                m.milestone.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: canClaim ? FontWeight.bold : FontWeight.normal,
                  color: color,
                ),
              ),
              backgroundColor: canClaim
                  ? Colors.amber.withValues(alpha: 0.15)
                  : AppColors.surface,
              side: BorderSide(
                color: canClaim
                    ? Colors.amber.withValues(alpha: 0.5)
                    : AppColors.border,
              ),
              onPressed: canClaim
                  ? () async {
                      await claimCollectionMilestone(ref, m.milestone.index);
                      if (context.mounted) {
                        final l = AppLocalizations.of(context)!;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                l.milestoneReward(m.milestone.label, m.milestone.gold, m.milestone.diamond)),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterBar(
      BuildContext context, WidgetRef ref, CollectionFilter filter) {
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // Owned toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(l.ownedOnly),
              selected: filter.showOnlyOwned,
              onSelected: (_) {
                ref.read(collectionFilterProvider.notifier).toggleShowOnlyOwned();
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.3),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                fontSize: 12,
                color: filter.showOnlyOwned
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          // Rarity filters
          for (final r in MonsterRarity.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(r.starsDisplay),
                selected: filter.rarity == r.rarity,
                onSelected: (_) {
                  ref
                      .read(collectionFilterProvider.notifier)
                      .setRarity(r.rarity);
                },
                selectedColor: r.color.withValues(alpha: 0.3),
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: filter.rarity == r.rarity
                      ? r.color
                      : AppColors.textSecondary,
                ),
              ),
            ),
          // Element filters
          for (final e in MonsterElement.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(e.emoji),
                selected: filter.element == e.name,
                onSelected: (_) {
                  ref
                      .read(collectionFilterProvider.notifier)
                      .setElement(e.name);
                },
                selectedColor: e.color.withValues(alpha: 0.3),
                labelStyle: const TextStyle(fontSize: 14),
              ),
            ),
          // Clear
          if (filter.hasFilter)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ActionChip(
                label: Text(
                  l.reset,
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                ),
                onPressed: () {
                  ref.read(collectionFilterProvider.notifier).clearAll();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Text(
        l.noMatchingMonster,
        style: const TextStyle(color: AppColors.textTertiary),
      ),
    );
  }

  Widget _buildGrid(
      BuildContext context, WidgetRef ref, List<CollectionEntry> entries) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      cacheExtent: 600,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _MonsterCard(
          entry: entry,
          onTap: () => _showDetail(context, entry),
        );
      },
    );
  }

  void _showDetail(BuildContext context, CollectionEntry entry) {
    // Owned monster → full detail screen
    if (entry.isOwned && entry.best != null) {
      context.push(AppRoutes.monsterDetail, extra: entry.best);
      return;
    }
    // Unowned → bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MonsterDetailSheet(entry: entry),
    );
  }
}

// =============================================================================
// Monster card in grid
// =============================================================================

class _MonsterCard extends StatelessWidget {
  const _MonsterCard({required this.entry, required this.onTap});

  final CollectionEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rarity = MonsterRarity.fromRarity(entry.template.rarity);
    final element =
        MonsterElement.fromName(entry.template.element) ?? MonsterElement.fire;

    return Semantics(
      label: entry.isOwned ? entry.template.name : '미발견 몬스터',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: entry.isOwned
                ? AppColors.surfaceVariant
                : AppColors.surfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: entry.isOwned
                  ? rarity.color.withValues(alpha: 0.5)
                  : AppColors.border,
              width: entry.isOwned ? 1.5 : 1,
            ),
          ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Monster icon (silhouette if not owned)
            _buildIcon(element),
            const SizedBox(height: 4),
            // Name
            Text(
              entry.isOwned ? entry.template.name : '???',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: entry.isOwned
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            // Stars
            Text(
              rarity.starsDisplay,
              style: TextStyle(
                fontSize: 10,
                color: entry.isOwned ? rarity.color : AppColors.disabled,
              ),
            ),
            // Count badge
            if (entry.count > 1)
              Text(
                'x${entry.count}',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.textTertiary,
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildIcon(MonsterElement element) {
    if (!entry.isOwned) {
      return Icon(
        Icons.help_outline,
        size: 36,
        color: AppColors.disabled,
        semanticLabel: '미발견 몬스터',
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: element.color.withValues(alpha: 0.2),
      ),
      child: Center(
        child: Text(
          element.emoji,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}

// =============================================================================
// Detail bottom sheet
// =============================================================================

class _MonsterDetailSheet extends StatelessWidget {
  const _MonsterDetailSheet({required this.entry});

  final CollectionEntry entry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = entry.template;
    final rarity = MonsterRarity.fromRarity(t.rarity);
    final element =
        MonsterElement.fromName(t.element) ?? MonsterElement.fire;
    final best = entry.best;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: element.color.withValues(alpha: 0.2),
                  border: Border.all(color: rarity.color, width: 2),
                ),
                child: Center(
                  child: Text(element.emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.isOwned ? t.name : '???',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          rarity.starsDisplay,
                          style: TextStyle(color: rarity.color),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${element.koreanName} | ${rarity.koreanName}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (entry.isOwned)
                      Text(
                        l.ownedCount(entry.count),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          if (entry.isOwned) ...[
            Text(
              t.description,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Stats
          if (best != null) ...[
            Text(
              l.bestUnit(best.level),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _StatRow(label: 'HP', value: best.finalHp.round()),
            _StatRow(label: 'ATK', value: best.finalAtk.round()),
            _StatRow(label: 'DEF', value: best.finalDef.round()),
            _StatRow(label: 'SPD', value: best.finalSpd.round()),
          ] else ...[
            Center(
              child: Text(
                l.unownedMonster,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (value / 2000).clamp(0.0, 1.0),
                backgroundColor: AppColors.surfaceVariant,
                color: AppColors.primary,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
