import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/l10n/app_localizations.dart';
import 'package:gameapp/core/utils/format_utils.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/domain/services/battle_statistics_service.dart';
import 'package:gameapp/presentation/providers/battle_provider.dart';
import 'package:gameapp/presentation/providers/player_provider.dart';
import 'package:gameapp/presentation/widgets/battle/stage_progress_bar.dart';
import 'package:gameapp/presentation/widgets/battle/battle_sidebar.dart';
import 'package:gameapp/presentation/widgets/common/currency_bar.dart';
import 'package:gameapp/presentation/widgets/tutorial_overlay.dart';
import 'package:gameapp/domain/services/prestige_service.dart';
import 'package:gameapp/presentation/flame/battle_arena_widget.dart';

// =============================================================================
// BattleView — pure widget (no Scaffold) for embedding in HomeScreen
// =============================================================================

class BattleView extends ConsumerStatefulWidget {
  const BattleView({super.key});

  @override
  ConsumerState<BattleView> createState() => _BattleViewState();
}

class _BattleViewState extends ConsumerState<BattleView> {
  bool _autoStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_autoStarted || !mounted) return;
      _autoStarted = true;
      final phase = ref.read(battleProvider).phase;
      if (phase == BattlePhase.idle) {
        ref.read(battleProvider.notifier).startBattle();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final phase = ref.watch(battleProvider.select((s) => s.phase));
    final isRepeatMode = ref.watch(battleProvider.select((s) => s.isRepeatMode));
    final repeatCount = ref.watch(battleProvider.select((s) => s.repeatCount));
    final repeatGold = ref.watch(battleProvider.select((s) => s.repeatTotalGold));
    final repeatExp = ref.watch(battleProvider.select((s) => s.repeatTotalExp));

    return TutorialOverlay(
      forStep: TutorialSteps.battleIntro,
      child: TutorialOverlay(
        forStep: TutorialSteps.afterFirstVictory,
        child: Container(
          color: AppColors.background,
          child: Stack(
            children: [
              // Main vertical layout
              Column(
                children: [
                  const CurrencyBar(),
                  const StageProgressBar(),
                  const Expanded(child: BattleArenaWidget()),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),

              // Battle sidebar (left)
              Positioned(
                left: 0,
                top: MediaQuery.of(context).padding.top + 100,
                bottom: MediaQuery.of(context).padding.bottom + 60,
                child: const BattleSidebar(),
              ),

              // Victory dialog overlay (skip in repeat mode)
              if (phase == BattlePhase.victory && !isRepeatMode)
                const _VictoryDialog(),

              // Defeat overlay with retry
              if (phase == BattlePhase.defeat) const _DefeatBanner(),

              // Repeat mode counter overlay
              if (isRepeatMode && repeatCount > 0)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 50,
                  right: 12,
                  child: _RepeatCounter(
                    count: repeatCount,
                    totalGold: repeatGold,
                    totalExp: repeatExp,
                  ),
                ),

              // Status icons overlay (top-right area)
              const _StatusIconOverlay(),

              // Battle effects overlay
              const _BattleEffectsOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _DefeatBanner
// =============================================================================

class _DefeatBanner extends ConsumerWidget {
  const _DefeatBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final stageId = ref.watch(battleProvider.select((s) => s.currentStageId));
    final notifier = ref.read(battleProvider.notifier);

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sentiment_very_dissatisfied, color: AppColors.error, size: 48),
              const SizedBox(height: 8),
              Text(
                l.battleDefeat,
                style: const TextStyle(color: AppColors.error, fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => notifier.startBattle(stageId),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(l.retry, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.85),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
// _RepeatCounter
// =============================================================================

class _RepeatCounter extends StatelessWidget {
  const _RepeatCounter({
    required this.count,
    required this.totalGold,
    required this.totalExp,
  });

  final int count;
  final int totalGold;
  final int totalExp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${count}x',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '${FormatUtils.formatNumber(totalGold)}G  ${FormatUtils.formatNumber(totalExp)}XP',
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _VictoryDialog
// =============================================================================

class _VictoryDialog extends ConsumerStatefulWidget {
  const _VictoryDialog();

  @override
  ConsumerState<_VictoryDialog> createState() => _VictoryDialogState();
}

class _VictoryDialogState extends ConsumerState<_VictoryDialog> {
  bool _showStats = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(battleProvider);
    final reward = state.lastReward;
    final notifier = ref.read(battleProvider.notifier);

    final stats = BattleStatisticsService.calculate(
      log: state.battleLog,
      playerTeam: state.playerTeam,
      turnCount: state.currentTurn,
    );

    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          constraints: const BoxConstraints(maxHeight: 520),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.25),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 48),
                const SizedBox(height: 6),
                Text(
                  l.battleVictory,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(color: AppColors.border),
                const SizedBox(height: 10),

                if (reward != null) ...[
                  () {
                    final playerData = ref.read(playerProvider).player;
                    final mult = playerData != null
                        ? PrestigeService.bonusMultiplier(playerData)
                        : 1.0;
                    final displayGold = (reward.gold * mult).round();
                    final displayExp = (reward.exp * mult).round();
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l.earnedReward,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (mult > 1.0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  '×${mult.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _RewardChip(
                              icon: Icons.monetization_on_rounded,
                              iconColor: AppColors.gold,
                              label: FormatUtils.formatNumber(displayGold),
                              sublabel: l.gold,
                            ),
                            _RewardChip(
                              icon: Icons.auto_awesome_rounded,
                              iconColor: AppColors.experience,
                              label: FormatUtils.formatNumber(displayExp),
                              sublabel: l.experience,
                            ),
                            if (reward.bonusShard != null)
                              _RewardChip(
                                icon: Icons.diamond_rounded,
                                iconColor: AppColors.primaryLight,
                                label: '×${reward.bonusShard}',
                                sublabel: l.monsterShard,
                              ),
                          ],
                        ),
                      ],
                    );
                  }(),
                  const SizedBox(height: 12),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      l.collectingReward,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ),

                GestureDetector(
                  onTap: () => setState(() => _showStats = !_showStats),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showStats ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showStats ? l.hideStats : l.showStats,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_showStats) ...[
                  const SizedBox(height: 12),
                  _BattleStatsPanel(stats: stats),
                ],

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => notifier.collectReward(),
                    icon: const Icon(Icons.emoji_events_rounded, size: 18),
                    label: Text(
                      l.reward,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold.withValues(alpha: 0.9),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Battle statistics panel
// =============================================================================

class _BattleStatsPanel extends StatelessWidget {
  const _BattleStatsPanel({required this.stats});
  final BattleStatistics stats;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatMini(label: l.totalDamage, value: FormatUtils.formatCompact(stats.totalDamage.round())),
              _StatMini(label: l.turnLabel, value: '${stats.totalTurns}'),
              _StatMini(label: l.critCount, value: '${stats.totalCriticals}'),
              _StatMini(label: l.skillCount, value: '${stats.totalSkillUses}'),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),
          if (stats.mvpName.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.star, color: AppColors.gold, size: 16),
                const SizedBox(width: 4),
                Text(
                  l.mvpLabel(stats.mvpName),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          ...stats.monsterStats.map((m) => _DamageBar(stat: m)),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _DamageBar extends StatelessWidget {
  const _DamageBar({required this.stat});
  final MonsterBattleStats stat;

  @override
  Widget build(BuildContext context) {
    final pctText = '${(stat.damagePercent * 100).toStringAsFixed(1)}%';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              stat.name,
              style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: stat.damagePercent.clamp(0.0, 1.0),
                backgroundColor: AppColors.surfaceVariant,
                color: _barColor(stat.damagePercent),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 40,
            child: Text(
              pctText,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _barColor(double pct) {
    if (pct >= 0.4) return AppColors.gold;
    if (pct >= 0.25) return Colors.cyan;
    return AppColors.primary;
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sublabel,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          sublabel,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _StatusIconOverlay — shows active status effects for both teams
// =============================================================================

class _StatusIconOverlay extends ConsumerWidget {
  const _StatusIconOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerTeam = ref.watch(battleProvider.select((s) => s.playerTeam));
    final enemyTeam = ref.watch(battleProvider.select((s) => s.enemyTeam));
    final phase = ref.watch(battleProvider.select((s) => s.phase));

    if (phase != BattlePhase.fighting) return const SizedBox.shrink();

    final playerStatuses = _collectStatuses(playerTeam);
    final enemyStatuses = _collectStatuses(enemyTeam);

    if (playerStatuses.isEmpty && enemyStatuses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 8,
      top: MediaQuery.of(context).padding.top + 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (playerStatuses.isNotEmpty)
            _StatusRow(label: '아군', statuses: playerStatuses, color: Colors.blue),
          if (playerStatuses.isNotEmpty && enemyStatuses.isNotEmpty)
            const SizedBox(height: 4),
          if (enemyStatuses.isNotEmpty)
            _StatusRow(label: '적군', statuses: enemyStatuses, color: Colors.red),
        ],
      ),
    );
  }

  List<_StatusInfo> _collectStatuses(List<BattleMonster> team) {
    final Map<String, int> statusCounts = {};
    for (final m in team) {
      if (!m.isAlive) continue;
      if (m.burnTurns > 0) {
        statusCounts['burn'] = (statusCounts['burn'] ?? 0) + m.burnTurns;
      }
      if (m.freezeTurns > 0) {
        statusCounts['freeze'] = (statusCounts['freeze'] ?? 0) + m.freezeTurns;
      }
      if (m.poisonTurns > 0) {
        statusCounts['poison'] = (statusCounts['poison'] ?? 0) + m.poisonTurns;
      }
      if (m.stunTurns > 0) {
        statusCounts['stun'] = (statusCounts['stun'] ?? 0) + m.stunTurns;
      }
      if (m.shieldHp > 0) {
        statusCounts['shield'] = (statusCounts['shield'] ?? 0) + 1;
      }
    }
    return statusCounts.entries.map((e) => _StatusInfo(e.key, e.value)).toList();
  }
}

class _StatusInfo {
  final String type;
  final int value;
  const _StatusInfo(this.type, this.value);
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.statuses, required this.color});
  final String label;
  final List<_StatusInfo> statuses;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          ...statuses.map((s) => Padding(
            padding: const EdgeInsets.only(right: 3),
            child: _StatusBadge(status: s),
          )),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final _StatusInfo status;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status.type) {
      'burn' => ('🔥', Colors.orange),
      'freeze' => ('❄️', Colors.cyan),
      'poison' => ('☠️', Colors.green),
      'stun' => ('⚡', Colors.yellow),
      'shield' => ('🛡️', Colors.blue),
      _ => ('❓', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 1),
          Text(
            '${status.value}',
            style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _BattleEffectsOverlay — screen flash + shake
// =============================================================================

class _BattleEffectsOverlay extends ConsumerStatefulWidget {
  const _BattleEffectsOverlay();

  @override
  ConsumerState<_BattleEffectsOverlay> createState() => _BattleEffectsOverlayState();
}

class _BattleEffectsOverlayState extends ConsumerState<_BattleEffectsOverlay>
    with TickerProviderStateMixin {
  AnimationController? _flashController;
  AnimationController? _shakeController;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _flashController?.dispose();
    _shakeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      battleProvider.select((s) => s.effectTrigger),
      (prev, next) {
        if (prev == null || next <= prev) return;
        final state = ref.read(battleProvider);
        if (state.lastWasCritical) {
          _flashController?.forward(from: 0);
        }
        if (state.lastWasBigDamage) {
          _shakeController?.forward(from: 0);
        }
      },
    );

    return Stack(
      children: [
        // Screen shake wrapper
        AnimatedBuilder(
          animation: _shakeController!,
          builder: (context, child) {
            if (!_shakeController!.isAnimating) return const SizedBox.shrink();
            final progress = _shakeController!.value;
            final dx = sin(progress * pi * 6) * 4 * (1 - progress);
            final dy = cos(progress * pi * 4) * 3 * (1 - progress);
            return Positioned.fill(
              child: IgnorePointer(
                child: Transform.translate(
                  offset: Offset(dx, dy),
                  child: const SizedBox.shrink(),
                ),
              ),
            );
          },
        ),
        // Screen flash
        AnimatedBuilder(
          animation: _flashController!,
          builder: (context, child) {
            if (!_flashController!.isAnimating) return const SizedBox.shrink();
            final opacity = (1 - _flashController!.value) * 0.4;
            return Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
