import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/domain/entities/synergy.dart';
import 'package:gameapp/l10n/app_localizations.dart';
import 'package:gameapp/presentation/providers/battle_provider.dart';

/// Compact progress bar showing stage name, enemy defeat progress, and retreat.
class StageProgressBar extends ConsumerWidget {
  const StageProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final stageName =
        ref.watch(battleProvider.select((s) => s.currentStageName));
    final stageId =
        ref.watch(battleProvider.select((s) => s.currentStageId));
    final phase = ref.watch(battleProvider.select((s) => s.phase));
    final totalEnemies =
        ref.watch(battleProvider.select((s) => s.initialEnemyCount));
    final aliveEnemies =
        ref.watch(battleProvider.select((s) => s.enemyTeam.where((m) => m.isAlive).length));

    final synergies =
        ref.watch(battleProvider.select((s) => s.activeSynergies));

    final defeated = totalEnemies - aliveEnemies;
    final progress = totalEnemies > 0 ? defeated / totalEnemies : 0.0;

    final displayName = stageName.isNotEmpty
        ? stageName
        : (stageId > 0 ? l.battleStageId(stageId.toString()) : l.battleStandby);

    final isFighting = phase == BattlePhase.fighting;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.black.withValues(alpha: 0.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: stage name + retreat button
          Row(
            children: [
              // Stage name
              Expanded(
                child: Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Retreat button (only during fighting)
              if (isFighting)
                GestureDetector(
                  onTap: () => _showRetreatDialog(context, ref, l),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag_rounded, size: 12, color: AppColors.error),
                        const SizedBox(width: 3),
                        Text(
                          l.battleRetreat,
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // Row 2: progress bar + count
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? AppColors.gold : AppColors.success,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l.stageProgress(defeated.toString(), totalEnemies.toString()),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          // Row 3: synergy badges (if any)
          if (synergies.isNotEmpty) ...[
            const SizedBox(height: 4),
            SizedBox(
              height: 20,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: synergies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (_, i) => _SynergyChip(synergy: synergies[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRetreatDialog(BuildContext context, WidgetRef ref, AppLocalizations l) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.retreatConfirmTitle),
        content: Text(l.retreatConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.retreatConfirmCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l.battleRetreat,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(battleProvider.notifier).retreatBattle();
      }
    });
  }
}

// ---------------------------------------------------------------------------
// _SynergyChip – compact badge shown inside the progress bar
// ---------------------------------------------------------------------------

class _SynergyChip extends StatelessWidget {
  const _SynergyChip({required this.synergy});
  final SynergyEffect synergy;

  Color get _color {
    switch (synergy.type) {
      case SynergyType.element:
        return const Color(0xFF42A5F5);
      case SynergyType.size:
        return const Color(0xFF66BB6A);
      case SynergyType.rarity:
        return const Color(0xFFFFB74D);
      case SynergyType.special:
        return const Color(0xFFCE93D8);
    }
  }

  String get _icon {
    switch (synergy.type) {
      case SynergyType.element:
        return '🔮';
      case SynergyType.size:
        return '📐';
      case SynergyType.rarity:
        return '⭐';
      case SynergyType.special:
        return '💎';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: synergy.description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _color.withValues(alpha: 0.5), width: 0.8),
        ),
        child: Text(
          '$_icon ${synergy.name}',
          style: TextStyle(color: _color, fontSize: 9, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
