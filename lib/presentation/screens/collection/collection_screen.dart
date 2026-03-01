import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gameapp/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/enums/monster_element.dart';
import '../../../core/enums/monster_rarity.dart';
import '../../../routing/app_router.dart';
import '../../providers/collection_provider.dart';
import '../../providers/collection_challenge_provider.dart';
import '../../providers/monster_provider.dart';
import '../../widgets/common/currency_bar.dart';
import '../../widgets/monster_avatar.dart';
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
              _buildChallengeBar(context, ref),
              _buildSearchBar(context, ref),
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
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.compare_arrows, size: 22),
            tooltip: l.compareTitle,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => context.push(AppRoutes.monsterCompare),
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
                m.milestone.localizedLabel(AppLocalizations.of(context)!),
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
                                l.milestoneReward(m.milestone.localizedLabel(l), m.milestone.gold, m.milestone.diamond)),
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

  Widget _buildChallengeBar(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final challengeState = ref.watch(collectionChallengeProvider);
    final ownedIds = ref.watch(monsterListProvider).map((m) => m.templateId).toSet();
    final isKo = Localizations.localeOf(context).languageCode == 'ko';

    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: ChallengeDatabase.all.length,
        itemBuilder: (_, i) {
          final ch = ChallengeDatabase.all[i];
          final (current, required) = ch.progressFn(ownedIds);
          final isComplete = current >= required;
          final isClaimed = challengeState.claimedIds.contains(ch.id);

          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isClaimed
                  ? AppColors.surface.withValues(alpha: 0.5)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isClaimed
                    ? AppColors.border
                    : isComplete
                        ? Colors.green.withValues(alpha: 0.6)
                        : AppColors.border,
                width: isComplete && !isClaimed ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isKo ? ch.titleKo : ch.titleEn,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isClaimed ? AppColors.textTertiary : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: required > 0 ? current / required : 0,
                          minHeight: 4,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation(
                            isClaimed ? AppColors.textTertiary : isComplete ? Colors.green : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (isClaimed)
                      const Icon(Icons.check_circle, size: 14, color: AppColors.textTertiary)
                    else if (isComplete)
                      GestureDetector(
                        onTap: () => ref.read(collectionChallengeProvider.notifier).claimChallenge(ch.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l.questClaim,
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    else
                      Text(
                        '$current/$required',
                        style: TextStyle(fontSize: 9, color: AppColors.textTertiary),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: _SearchField(
        hintText: l.searchMonster,
        onChanged: (query) {
          ref.read(collectionFilterProvider.notifier).setSearchQuery(query);
        },
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
          // Favorite toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              avatar: Icon(
                filter.showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
                size: 16,
                color: filter.showOnlyFavorites ? Colors.red : AppColors.textTertiary,
              ),
              label: Text(l.favoriteOnly),
              selected: filter.showOnlyFavorites,
              onSelected: (_) {
                ref.read(collectionFilterProvider.notifier).toggleShowOnlyFavorites();
              },
              selectedColor: Colors.red.withValues(alpha: 0.15),
              checkmarkColor: Colors.red,
              labelStyle: TextStyle(
                fontSize: 12,
                color: filter.showOnlyFavorites
                    ? Colors.red
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
          // Sort dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: PopupMenuButton<CollectionSort>(
              initialValue: filter.sort,
              onSelected: (sort) {
                ref.read(collectionFilterProvider.notifier).setSort(sort);
              },
              child: Chip(
                avatar: const Icon(Icons.sort, size: 16),
                label: Text(
                  _sortLabel(l, filter.sort),
                  style: TextStyle(
                    fontSize: 12,
                    color: filter.sort != CollectionSort.defaultOrder
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: CollectionSort.defaultOrder,
                  child: Text(l.sortDefault),
                ),
                PopupMenuItem(
                  value: CollectionSort.name,
                  child: Text(l.sortName),
                ),
                PopupMenuItem(
                  value: CollectionSort.rarityDesc,
                  child: Text(l.sortRarity),
                ),
                PopupMenuItem(
                  value: CollectionSort.levelDesc,
                  child: Text(l.sortLevel),
                ),
                PopupMenuItem(
                  value: CollectionSort.powerDesc,
                  child: Text(l.sortPower),
                ),
              ],
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

  String _sortLabel(AppLocalizations l, CollectionSort sort) {
    switch (sort) {
      case CollectionSort.defaultOrder:
        return l.sortDefault;
      case CollectionSort.name:
        return l.sortName;
      case CollectionSort.rarityDesc:
        return l.sortRarity;
      case CollectionSort.levelDesc:
        return l.sortLevel;
      case CollectionSort.powerDesc:
        return l.sortPower;
    }
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

class _MonsterCard extends ConsumerWidget {
  const _MonsterCard({required this.entry, required this.onTap});

  final CollectionEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final rarity = MonsterRarity.fromRarity(entry.template.rarity);
    final element =
        MonsterElement.fromName(entry.template.element) ?? MonsterElement.fire;
    final isFavorite = entry.best?.isFavorite ?? false;

    return Semantics(
      label: entry.isOwned ? entry.template.name : l.collectionUnknownMonster,
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
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Monster icon (silhouette if not owned)
                  _buildIcon(element, l),
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
                  // Power score
                  if (entry.isOwned && entry.best != null)
                    Text(
                      '⚔${entry.best!.powerScore}',
                      style: TextStyle(
                        fontSize: 8,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            // Favorite heart
            if (entry.isOwned && entry.best != null)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    ref.read(monsterListProvider.notifier)
                        .toggleFavorite(entry.best!.id);
                  },
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: isFavorite ? Colors.red : AppColors.textTertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildIcon(MonsterElement element, AppLocalizations l) {
    if (!entry.isOwned) {
      return Icon(
        Icons.help_outline,
        size: 36,
        color: AppColors.disabled,
        semanticLabel: l.collectionUnknownMonster,
      );
    }
    return MonsterAvatar(
      name: entry.template.name,
      element: entry.template.element,
      rarity: entry.template.rarity,
      templateId: entry.template.id,
      size: 40,
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
              MonsterAvatar(
                name: t.name,
                element: t.element,
                rarity: t.rarity,
                templateId: t.id,
                size: 56,
                showRarityGlow: true,
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

// =============================================================================
// Search field with debounce
// =============================================================================

class _SearchField extends StatefulWidget {
  const _SearchField({required this.hintText, required this.onChanged});
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _controller,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(fontSize: 13, color: AppColors.textTertiary),
          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textTertiary),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primary),
          ),
        ),
        onChanged: (value) {
          setState(() {});
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 300), () {
            widget.onChanged(value);
          });
        },
      ),
    );
  }
}
