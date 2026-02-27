import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/l10n/app_localizations.dart';
import 'package:gameapp/core/utils/format_utils.dart';
import 'package:gameapp/data/static/stage_database.dart';
import 'package:gameapp/presentation/providers/battle_provider.dart';
import 'package:gameapp/presentation/providers/player_provider.dart';

const _areaEmojis = ['🌲', '🌋', '🏚️', '🌊', '☁️'];

List<String> _areaNames(AppLocalizations l) => [
  l.areaForest,
  l.areaVolcano,
  l.areaDungeon,
  l.areaTemple,
  l.areaSky,
];

// =============================================================================
// StageSelectScreen
// =============================================================================

class StageSelectScreen extends ConsumerStatefulWidget {
  const StageSelectScreen({super.key});

  @override
  ConsumerState<StageSelectScreen> createState() => _StageSelectScreenState();
}

class _StageSelectScreenState extends ConsumerState<StageSelectScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Default to the area of the player's current stage.
    final player = ref.read(playerProvider).player;
    final currentStageId = player?.currentStageId ?? '1-1';
    final area = int.tryParse(currentStageId.split('-').first) ?? 1;
    _tabController = TabController(
      length: StageDatabase.areaCount,
      initialIndex: (area - 1).clamp(0, StageDatabase.areaCount - 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final areaNames = _areaNames(l);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          l.stageSelect,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textTertiary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabAlignment: TabAlignment.start,
          tabs: List.generate(StageDatabase.areaCount, (i) {
            return Tab(text: '${_areaEmojis[i]} ${areaNames[i]}');
          }),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(StageDatabase.areaCount, (areaIdx) {
          return _AreaStageGrid(area: areaIdx + 1);
        }),
      ),
    );
  }
}

// =============================================================================
// _AreaStageGrid
// =============================================================================

class _AreaStageGrid extends ConsumerWidget {
  const _AreaStageGrid({required this.area});

  final int area;

  int _linearIndex(String stageId) {
    if (stageId.isEmpty) return 0;
    final parts = stageId.split('-');
    if (parts.length != 2) return 0;
    final a = int.tryParse(parts[0]) ?? 0;
    final s = int.tryParse(parts[1]) ?? 0;
    return (a - 1) * 6 + s;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider).player;
    final maxClearedStr = player?.maxClearedStageId ?? '';
    final currentStr = player?.currentStageId ?? '1-1';
    final maxClearedIdx = _linearIndex(maxClearedStr);
    final currentIdx = _linearIndex(currentStr);
    final stages = StageDatabase.byArea(area);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: stages.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
        ),
        itemBuilder: (context, index) {
          final stage = stages[index];
          final stageIdx = _linearIndex(stage.id);
          final isCleared = stageIdx <= maxClearedIdx;
          final isCurrent = stageIdx == currentIdx;
          // Unlocked if cleared or is the next stage after max cleared
          final isUnlocked = stageIdx <= maxClearedIdx + 1;

          return _StageCard(
            stage: stage,
            isCleared: isCleared,
            isCurrent: isCurrent,
            isUnlocked: isUnlocked,
            onTap: isUnlocked
                ? () {
                    // Start battle at this stage and go back.
                    ref.read(battleProvider.notifier).startBattle(stageIdx);
                    context.pop();
                  }
                : null,
            onSkip: isCleared
                ? () async {
                    final reward = await ref
                        .read(battleProvider.notifier)
                        .skipBattle(stageIdx);
                    if (reward != null && context.mounted) {
                      final l = AppLocalizations.of(context)!;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${l.stageSkipResult}  ${l.stageSkipGold(reward.gold)}  ${l.stageSkipExp(reward.exp)}',
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                : null,
          );
        },
      ),
    );
  }
}

// =============================================================================
// _StageCard
// =============================================================================

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stage,
    required this.isCleared,
    required this.isCurrent,
    required this.isUnlocked,
    this.onTap,
    this.onSkip,
  });

  final StageData stage;
  final bool isCleared;
  final bool isCurrent;
  final bool isUnlocked;
  final VoidCallback? onTap;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final borderColor = isCurrent
        ? AppColors.primary
        : isCleared
            ? AppColors.success.withValues(alpha: 0.5)
            : isUnlocked
                ? AppColors.warning.withValues(alpha: 0.5)
                : AppColors.border;

    final bgColor = isCurrent
        ? AppColors.primary.withValues(alpha: 0.15)
        : isCleared
            ? AppColors.surfaceVariant
            : isUnlocked
                ? AppColors.surface
                : AppColors.background;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top row: stage name + status icon
            Row(
              children: [
                Expanded(
                  child: Text(
                    stage.name,
                    style: TextStyle(
                      color: isUnlocked
                          ? AppColors.textPrimary
                          : AppColors.disabledText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCleared)
                  const Icon(Icons.check_circle, color: AppColors.success, size: 16)
                else if (isCurrent)
                  const Icon(Icons.play_circle_fill, color: AppColors.primary, size: 16)
                else if (!isUnlocked)
                  const Icon(Icons.lock, color: AppColors.disabledText, size: 16),
              ],
            ),

            // Bottom row: enemies count + rewards + skip button
            Row(
              children: [
                // Enemy count
                Text(
                  '${stage.enemyTemplateIds.length}',
                  style: TextStyle(
                    color: isUnlocked
                        ? AppColors.textSecondary
                        : AppColors.disabledText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                // Gold reward
                Text(
                  '${FormatUtils.formatNumber(stage.goldReward)} G',
                  style: TextStyle(
                    color: isUnlocked ? AppColors.gold : AppColors.disabledText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                // EXP reward
                Text(
                  '${FormatUtils.formatNumber(stage.expReward)} EXP',
                  style: TextStyle(
                    color: isUnlocked
                        ? AppColors.experience
                        : AppColors.disabledText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // Skip button for cleared stages
                if (onSkip != null)
                  GestureDetector(
                    onTap: onSkip,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Text(
                        '⚡',
                        style: TextStyle(fontSize: 12),
                      ),
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
