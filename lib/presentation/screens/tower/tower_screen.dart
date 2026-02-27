import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/core/utils/format_utils.dart';
import 'package:gameapp/presentation/widgets/common/reward_chip.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/domain/services/tower_service.dart';
import 'package:gameapp/presentation/providers/tower_provider.dart';
import 'package:gameapp/presentation/widgets/battle/monster_battle_card.dart';
import 'package:gameapp/presentation/widgets/common/battle_log_list.dart';
import 'package:gameapp/l10n/app_localizations.dart';

// =============================================================================
// TowerScreen
// =============================================================================

class TowerScreen extends ConsumerStatefulWidget {
  const TowerScreen({super.key});

  @override
  ConsumerState<TowerScreen> createState() => _TowerScreenState();
}

class _TowerScreenState extends ConsumerState<TowerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tower = ref.read(towerProvider);
      if (tower.phase == TowerPhase.idle && tower.canStartRun) {
        ref.read(towerProvider.notifier).startRun();
      }
    });
  }

  bool _scheduled = false;

  void _scheduleAutoTurn(double speed, bool isAuto) {
    if (_scheduled || !isAuto) return;
    _scheduled = true;
    final ms = (800 / speed).round();
    Future.delayed(Duration(milliseconds: ms), () {
      _scheduled = false;
      if (!mounted) return;
      final current = ref.read(towerProvider);
      if (current.phase == TowerPhase.fighting && current.isAutoMode) {
        ref.read(towerProvider.notifier).processTurn();
      }
      if (current.phase == TowerPhase.floorCleared && current.isAutoMode) {
        if (current.currentFloor < TowerService.maxFloor) {
          ref.read(towerProvider.notifier).advanceFloor();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(towerProvider);
    if (state.phase == TowerPhase.fighting) {
      _scheduleAutoTurn(state.battleSpeed, state.isAutoMode);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _TowerHeader(state: state),
          Expanded(flex: 5, child: _TowerArena(state: state)),
          Container(height: 1, color: AppColors.border),
          Expanded(
            flex: 3,
            child: _BattleLog(log: state.battleLog),
          ),
          _TowerControls(state: state),
        ],
      ),
    );
  }
}

// =============================================================================
// Header
// =============================================================================

class _TowerHeader extends StatelessWidget {
  const _TowerHeader({required this.state});
  final TowerState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16, right: 16, bottom: 8,
      ),
      color: const Color(0xFF1A0A2E),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textSecondary, size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.castle, color: Color(0xFFFFD740), size: 20),
              const SizedBox(width: 6),
              Text(
                state.currentFloor > 0
                    ? '${l.towerTitle} - ${state.currentFloor}F'
                    : l.towerTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                l.towerAttempts(
                  TowerService.maxWeeklyAttempts - state.weeklyAttempts,
                  TowerService.maxWeeklyAttempts,
                ),
                style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              RewardChip(
                icon: Icons.monetization_on_rounded,
                color: AppColors.gold,
                value: FormatUtils.formatNumber(state.accGold),
              ),
              const SizedBox(width: 12),
              RewardChip(
                icon: Icons.auto_awesome_rounded,
                color: AppColors.experience,
                value: FormatUtils.formatNumber(state.accExp),
              ),
              if (state.accDiamond > 0) ...[
                const SizedBox(width: 12),
                RewardChip(
                  icon: Icons.diamond_rounded,
                  color: Colors.cyan,
                  value: '${state.accDiamond}',
                ),
              ],
              if (state.accTicket > 0) ...[
                const SizedBox(width: 12),
                RewardChip(
                  icon: Icons.confirmation_number,
                  color: Colors.purple,
                  value: '${state.accTicket}',
                ),
              ],
            ],
          ),
          if (state.highestCleared > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  l.towerBest(state.highestCleared),
                  style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Arena
// =============================================================================

class _TowerArena extends StatelessWidget {
  const _TowerArena({required this.state});
  final TowerState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (state.phase == TowerPhase.idle) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.castle, color: Colors.amber, size: 48),
            const SizedBox(height: 12),
            Text(
              l.towerTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.canStartRun
                  ? l.towerReady
                  : l.towerNoAttempts,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _TeamColumn(
              monsters: state.playerTeam,
              label: l.ourTeam,
              labelColor: AppColors.primary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FloorBadge(floor: state.currentFloor, phase: state.phase),
                const SizedBox(height: 6),
                const Text('VS', style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                )),
              ],
            ),
          ),
          Expanded(
            child: _TeamColumn(
              monsters: state.enemyTeam,
              label: l.enemyTeam,
              labelColor: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({required this.monsters, required this.label, required this.labelColor});
  final List<BattleMonster> monsters;
  final String label;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(
          color: labelColor, fontSize: 10, fontWeight: FontWeight.w700,
        )),
        const SizedBox(height: 6),
        ...monsters.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: MonsterBattleCard(monster: m),
        )),
      ],
    );
  }
}

class _FloorBadge extends StatelessWidget {
  const _FloorBadge({required this.floor, required this.phase});
  final int floor;
  final TowerPhase phase;

  @override
  Widget build(BuildContext context) {
    final isBoss = floor % 10 == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isBoss
            ? Colors.amber.withValues(alpha: 0.2)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBoss ? Colors.amber : AppColors.border,
        ),
      ),
      child: Text(
        '${floor}F',
        style: TextStyle(
          color: isBoss ? Colors.amber : AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// =============================================================================
// Battle Log
// =============================================================================

class _BattleLog extends StatelessWidget {
  const _BattleLog({required this.log});
  final List<BattleLogEntry> log;

  @override
  Widget build(BuildContext context) {
    if (log.isEmpty) {
      return const Center(
        child: Text('...', style: TextStyle(color: AppColors.textTertiary)),
      );
    }
    return BattleLogList(
      entries: log,
      reverse: true,
    );
  }
}

// =============================================================================
// Controls
// =============================================================================

class _TowerControls extends ConsumerWidget {
  const _TowerControls({required this.state});
  final TowerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final notifier = ref.read(towerProvider.notifier);

    return Container(
      padding: EdgeInsets.only(
        left: 12, right: 12, top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Speed + Auto
          Row(
            children: [
              for (final s in [1.0, 2.0, 3.0]) ...[
                if (s > 1.0) const SizedBox(width: 6),
                _SpeedBtn(
                  label: '${s.toInt()}x',
                  isActive: (state.battleSpeed - s).abs() < 0.01,
                  onTap: notifier.toggleSpeed,
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: notifier.toggleAutoMode,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: state.isAutoMode
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: state.isAutoMode ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    l.battleAutoMode,
                    style: TextStyle(
                      color: state.isAutoMode ? AppColors.primary : AppColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Action button
          _buildActionButton(context, ref, l),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref, AppLocalizations l) {
    final notifier = ref.read(towerProvider.notifier);

    switch (state.phase) {
      case TowerPhase.idle:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.canStartRun ? notifier.startRun : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[800],
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              state.canStartRun ? l.towerStart : l.towerNoAttempts,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );

      case TowerPhase.fighting:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.isAutoMode ? null : notifier.processTurn,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(l.battleFighting, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );

      case TowerPhase.floorCleared:
        final isMaxFloor = state.currentFloor >= TowerService.maxFloor;
        return Row(
          children: [
            if (!isMaxFloor)
              Expanded(
                child: ElevatedButton(
                  onPressed: notifier.advanceFloor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(l.towerNextFloor, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            if (!isMaxFloor) const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await notifier.collectAndExit();
                  if (context.mounted) context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[800],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  isMaxFloor ? l.towerComplete : l.towerCollect,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );

      case TowerPhase.defeated:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              await notifier.collectAndExit();
              if (context.mounted) context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              l.towerCollect,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
    }
  }
}

class _SpeedBtn extends StatelessWidget {
  const _SpeedBtn({required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.primary : AppColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
