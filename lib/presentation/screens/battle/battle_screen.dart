import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/l10n/app_localizations.dart';
import 'package:gameapp/core/utils/format_utils.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/domain/services/battle_statistics_service.dart';
import 'package:gameapp/presentation/providers/battle_provider.dart';
import 'package:gameapp/presentation/providers/player_provider.dart';
import 'package:gameapp/presentation/widgets/battle/damage_number.dart';
import 'package:gameapp/presentation/widgets/battle/monster_battle_card.dart';
import 'package:gameapp/presentation/widgets/battle/stage_progress_bar.dart';
import 'package:gameapp/presentation/widgets/battle/battle_sidebar.dart';
import 'package:gameapp/presentation/widgets/common/currency_bar.dart';
import 'package:gameapp/presentation/widgets/tutorial_overlay.dart';
import 'package:gameapp/domain/services/prestige_service.dart';

// =============================================================================
// BattleScreen — root entry point
// =============================================================================

/// The main battle screen. Auto-starts battle on init.
/// Hosts: CurrencyBar -> StageProgressBar -> BattleArena.
/// Overlays: BattleSidebar (left), RepeatCounter (top-right), VictoryDialog.
class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  bool _autoStarted = false;

  @override
  void initState() {
    super.initState();
    // Auto-start battle once after providers are ready.
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
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // ── Main vertical layout ─────────────────────────────────────
              Column(
                children: [
                  // Currency bar — handles its own SafeArea top padding
                  const CurrencyBar(),

                  // Stage progress bar (replaces old StageHeader)
                  const StageProgressBar(),

                  // Battle arena
                  const Expanded(
                    child: _BattleArena(),
                  ),

                  // Bottom safe area padding
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),

              // ── Battle sidebar (left) ──────────────────────────────────────
              Positioned(
                left: 0,
                top: MediaQuery.of(context).padding.top + 100,
                bottom: MediaQuery.of(context).padding.bottom + 60,
                child: const BattleSidebar(),
              ),

              // ── Victory dialog overlay (skip in repeat mode) ─────────────
              if (phase == BattlePhase.victory && !isRepeatMode) const _VictoryDialog(),

              // ── Defeat overlay with retry ─────────────────────────────────
              if (phase == BattlePhase.defeat) const _DefeatBanner(),

              // ── Repeat mode counter overlay ────────────────────────────────
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
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _DefeatBanner — shown when battle is lost
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

// (Old _StageHeader removed — replaced by StageProgressBar widget)

// =============================================================================
// _BattleArena
// =============================================================================

class _BattleArena extends ConsumerStatefulWidget {
  const _BattleArena();

  @override
  ConsumerState<_BattleArena> createState() => _BattleArenaState();
}

class _BattleArenaState extends ConsumerState<_BattleArena> {
  final _overlayKey = GlobalKey<DamageNumberOverlayState>();
  int _lastLogLength = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(battleProvider);

    // Trigger damage numbers when new log entries appear
    if (state.battleLog.length > _lastLogLength && state.phase == BattlePhase.fighting) {
      final oldLen = _lastLogLength;
      _lastLogLength = state.battleLog.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final overlay = _overlayKey.currentState;
        if (overlay == null) return;
        for (int i = oldLen; i < state.battleLog.length; i++) {
          final entry = state.battleLog[i];
          final isEnemy = state.enemyTeam.any((m) => m.name == entry.attackerName);
          overlay.addDamage(
            damage: entry.damage.round(),
            isCritical: entry.isCritical,
            isSkill: entry.isSkillActivation,
            isElementAdvantage: entry.isElementAdvantage,
            isEnemy: !isEnemy,
          );
        }
      });
    } else {
      _lastLogLength = state.battleLog.length;
    }

    // Reset on idle — auto-restart battle
    if (state.phase == BattlePhase.idle) {
      _lastLogLength = 0;
      // Auto-start next battle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(battleProvider.notifier).startBattle();
      });
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              l.preparingBattle,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // area 계산: stageId 기반으로 area 번호 결정
    final areaIndex = ((state.currentStageId - 1) ~/ 6 + 1).clamp(1, 5);
    const areaNames = ['forest', 'volcano', 'dungeon', 'ocean', 'sky'];
    final areaName = areaNames[areaIndex - 1];
    final bgPath = 'assets/images/backgrounds/area_${areaIndex}_$areaName.png';

    return Stack(
      children: [
        // ── 배경 이미지 레이어 ──────────────────────────────────────────
        Positioned.fill(
          child: Image.asset(
            bgPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.surface,
            ),
          ),
        ),
        // ── 반투명 다크 오버레이 ────────────────────────────────────────
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.45),
          ),
        ),
        // ── 기존 전투 UI ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Player team (left) ──────────────────────────────────────────
          Expanded(
            child: RepaintBoundary(
              child: _MonsterGrid(
                monsters: state.playerTeam,
                label: l.ourTeam,
                labelColor: AppColors.primary,
              ),
            ),
          ),

          // ── VS divider ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PhaseBadge(phase: state.phase),
                const SizedBox(height: 6),
                const Text(
                  'VS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.turnN(state.currentTurn),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // ── Enemy team (right) ──────────────────────────────────────────
          Expanded(
            child: RepaintBoundary(
              child: _MonsterGrid(
                monsters: state.enemyTeam,
                label: l.enemyTeam,
                labelColor: AppColors.error,
              ),
            ),
          ),
        ],
      ),
        ),
        // Floating damage numbers overlay
        Positioned.fill(
          child: RepaintBoundary(
            child: DamageNumberOverlay(key: _overlayKey),
          ),
        ),
      ],
    );
  }
}

// (Old _IdleBanner removed — battle auto-starts now)

// (Old _IdleBanner, _AttemptCard, _QuickNavBtn removed — sidebar replaces them)

// ── _MonsterGrid ──────────────────────────────────────────────────────────────

/// Renders a labelled [Wrap] of [MonsterBattleCard]s for one team.
class _MonsterGrid extends StatelessWidget {
  const _MonsterGrid({
    required this.monsters,
    required this.label,
    required this.labelColor,
  });

  final List<BattleMonster> monsters;
  final String label;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),

        if (monsters.isEmpty)
          const Center(
            child: Text(
              '—',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 20,
              ),
            ),
          )
        else
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: monsters
                .map((m) => MonsterBattleCard(monster: m, width: 80))
                .toList(),
          ),
      ],
    );
  }
}

// ── _PhaseBadge ───────────────────────────────────────────────────────────────

class _PhaseBadge extends StatelessWidget {
  const _PhaseBadge({required this.phase});

  final BattlePhase phase;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final (label, color) = switch (phase) {
      BattlePhase.idle      => (l.standby, AppColors.textTertiary),
      BattlePhase.preparing => (l.preparing, AppColors.warning),
      BattlePhase.fighting  => (l.fighting, AppColors.success),
      BattlePhase.victory   => (l.battleVictory, AppColors.gold),
      BattlePhase.defeat    => (l.battleDefeat, AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha:0.6), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}


// (Old _ControlBar removed — auto-battle, no manual controls needed)

// ── _RepeatCounter ────────────────────────────────────────────────────────────

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

// (Old _PrimaryActionButton, _ActionButton removed)

// =============================================================================
// _VictoryDialog — full-screen overlay shown on BattlePhase.victory
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
    final state    = ref.watch(battleProvider);
    final reward   = state.lastReward;
    final notifier = ref.read(battleProvider.notifier);

    // Compute battle statistics
    final stats = BattleStatisticsService.calculate(
      log: state.battleLog,
      playerTeam: state.playerTeam,
      turnCount: state.currentTurn,
    );

    return Material(
      color: Colors.black.withValues(alpha:0.72),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          constraints: const BoxConstraints(maxHeight: 520),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.gold.withValues(alpha:0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha:0.25),
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
                // ── Title ──────────────────────────────────────────────────
                const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.gold,
                  size: 48,
                ),
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

                // ── Reward section ─────────────────────────────────────────
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

                // ── Stats toggle ───────────────────────────────────────────
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

                // ── Battle statistics panel ────────────────────────────────
                if (_showStats) ...[
                  const SizedBox(height: 12),
                  _BattleStatsPanel(stats: stats),
                ],

                const SizedBox(height: 14),

                // ── Collect button ─────────────────────────────────────────
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
                      backgroundColor: AppColors.gold.withValues(alpha:0.9),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.gold.withValues(alpha:0.4),
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
          // Summary row
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

          // MVP
          if (stats.mvpName.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.star, color: AppColors.gold, size: 16),
                const SizedBox(width: 4),
                Text(
                  'MVP: ${stats.mvpName}',
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

          // Damage contribution bars
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

// ── _RewardChip ───────────────────────────────────────────────────────────────

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

