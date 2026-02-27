import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gameapp/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/static/title_database.dart';
import '../../providers/title_provider.dart';

class TitleScreen extends ConsumerStatefulWidget {
  const TitleScreen({super.key});

  @override
  ConsumerState<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends ConsumerState<TitleScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(titleProvider.notifier).load();
    // Check for new unlocks on screen open
    Future.microtask(() => ref.read(titleProvider.notifier).checkUnlocks());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(titleProvider);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.titleScreenTitle),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          // Current title display
          _CurrentTitleBar(state: state, isKo: isKo, l: l),
          // Milestone bar
          _MilestoneBar(
            state: state,
            isKo: isKo,
            l: l,
            onClaim: (idx) => ref.read(titleProvider.notifier).claimMilestone(idx),
          ),
          // Title grid
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              cacheExtent: 400,
              itemCount: TitleDatabase.titles.length,
              itemBuilder: (_, i) {
                final def = TitleDatabase.titles[i];
                final isUnlocked = state.unlockedTitleIds.contains(def.id);
                final isEquipped = state.equippedTitleId == def.id;
                return _TitleCard(
                  def: def,
                  isUnlocked: isUnlocked,
                  isEquipped: isEquipped,
                  isKo: isKo,
                  onEquip: isUnlocked
                      ? () => ref.read(titleProvider.notifier).equipTitle(
                            isEquipped ? null : def.id,
                          )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Milestone Bar
// =============================================================================

class _MilestoneBar extends StatelessWidget {
  const _MilestoneBar({
    required this.state,
    required this.isKo,
    required this.l,
    required this.onClaim,
  });
  final TitleState state;
  final bool isKo;
  final AppLocalizations l;
  final Future<bool> Function(int) onClaim;

  @override
  Widget build(BuildContext context) {
    final pts = state.achievementPoints;
    final milestones = TitleDatabase.milestones;
    final maxPts = milestones.isNotEmpty ? milestones.last.requiredPoints : 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 18),
              const SizedBox(width: 6),
              Text(
                l.achievementPoints(pts),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar with milestone markers
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (pts / maxPts).clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceVariant,
              color: Colors.amber,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          // Milestone chips
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: milestones.length,
              itemBuilder: (_, i) {
                final m = milestones[i];
                final reached = pts >= m.requiredPoints;
                final claimed = state.claimedMilestones.contains(i);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: reached && !claimed ? () => onClaim(i) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: claimed
                            ? AppColors.disabled.withValues(alpha: 0.1)
                            : reached
                                ? Colors.amber.withValues(alpha: 0.15)
                                : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: claimed
                              ? AppColors.border
                              : reached
                                  ? Colors.amber
                                  : AppColors.border,
                          width: reached && !claimed ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${m.requiredPoints}P',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: claimed
                                  ? AppColors.textTertiary
                                  : reached
                                      ? Colors.amber
                                      : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            claimed
                                ? l.questClaim
                                : (isKo ? m.descKo : m.descEn),
                            style: TextStyle(
                              fontSize: 9,
                              color: claimed
                                  ? AppColors.textTertiary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Current Title Bar
// =============================================================================

class _CurrentTitleBar extends StatelessWidget {
  const _CurrentTitleBar({
    required this.state,
    required this.isKo,
    required this.l,
  });
  final TitleState state;
  final bool isKo;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final equipped = state.equippedTitleId != null
        ? TitleDatabase.findById(state.equippedTitleId!)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.military_tech, color: Colors.amber, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.titleCurrent,
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 2),
                Text(
                  equipped != null
                      ? (isKo ? equipped.nameKo : equipped.nameEn)
                      : l.titleNone,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: equipped != null ? Colors.amber : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${state.unlockedTitleIds.length}/${TitleDatabase.titles.length}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Title Card
// =============================================================================

class _TitleCard extends StatelessWidget {
  const _TitleCard({
    required this.def,
    required this.isUnlocked,
    required this.isEquipped,
    required this.isKo,
    this.onEquip,
  });

  final TitleDefinition def;
  final bool isUnlocked;
  final bool isEquipped;
  final bool isKo;
  final VoidCallback? onEquip;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEquipped
            ? Colors.amber.withValues(alpha: 0.1)
            : isUnlocked
                ? AppColors.surface
                : AppColors.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEquipped
              ? Colors.amber.withValues(alpha: 0.5)
              : isUnlocked
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.border,
          width: isEquipped ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? Colors.amber.withValues(alpha: 0.15)
                  : AppColors.disabled.withValues(alpha: 0.15),
            ),
            child: Center(
              child: Icon(
                isUnlocked ? Icons.military_tech : Icons.lock,
                color: isUnlocked ? Colors.amber : AppColors.textTertiary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUnlocked
                      ? (isKo ? def.nameKo : def.nameEn)
                      : '???',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked
                        ? (isEquipped ? Colors.amber : AppColors.textPrimary)
                        : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isUnlocked
                      ? (isKo ? def.descKo : def.descEn)
                      : l.titleHidden,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Points badge
          if (isUnlocked)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+${def.points}P',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ),

          // Equip button
          if (isUnlocked)
            TextButton(
              onPressed: onEquip,
              child: Text(
                isEquipped ? l.titleUnequip : l.titleEquip,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isEquipped ? AppColors.error : AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
