import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/l10n/app_localizations.dart';
import 'package:gameapp/core/utils/format_utils.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/presentation/providers/dungeon_provider.dart';
import 'package:gameapp/presentation/widgets/battle/monster_battle_card.dart';

// =============================================================================
// DungeonScreen
// =============================================================================

class DungeonScreen extends ConsumerStatefulWidget {
  const DungeonScreen({super.key});

  @override
  ConsumerState<DungeonScreen> createState() => _DungeonScreenState();
}

class _DungeonScreenState extends ConsumerState<DungeonScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-start the dungeon run on first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dungeon = ref.read(dungeonProvider);
      if (dungeon.phase == DungeonPhase.idle) {
        ref.read(dungeonProvider.notifier).startRun();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dungeonProvider);

    // Auto-advance timer when fighting.
    if (state.phase == DungeonPhase.fighting) {
      _scheduleAutoTurn(state.battleSpeed, state.isAutoMode);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top bar
          _DungeonHeader(state: state),

          // Arena
          Expanded(
            flex: 5,
            child: _DungeonArena(state: state),
          ),

          Container(height: 1, color: AppColors.border),

          // Log
          Expanded(
            flex: 3,
            child: _DungeonLog(log: state.battleLog),
          ),

          // Controls
          _DungeonControls(state: state),
        ],
      ),
    );
  }

  // Auto-turn scheduling.
  bool _scheduled = false;

  void _scheduleAutoTurn(double speed, bool isAuto) {
    if (_scheduled || !isAuto) return;
    _scheduled = true;

    final ms = (800 / speed).round();
    Future.delayed(Duration(milliseconds: ms), () {
      _scheduled = false;
      if (!mounted) return;
      final current = ref.read(dungeonProvider);
      if (current.phase == DungeonPhase.fighting && current.isAutoMode) {
        ref.read(dungeonProvider.notifier).processTurn();
      }
      // Auto-advance to next floor if cleared in auto mode.
      if (current.phase == DungeonPhase.floorCleared && current.isAutoMode) {
        ref.read(dungeonProvider.notifier).advanceFloor();
      }
    });
  }
}

// =============================================================================
// _DungeonHeader
// =============================================================================

class _DungeonHeader extends StatelessWidget {
  const _DungeonHeader({required this.state});

  final DungeonState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
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
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.layers, color: Color(0xFFCE93D8), size: 20),
              const SizedBox(width: 6),
              Text(
                state.currentFloor > 0
                    ? '${l.infiniteDungeon} - ${l.dungeonFloor(state.currentFloor)}'
                    : l.infiniteDungeon,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (state.bestFloor > 0)
                Text(
                  l.dungeonBest(state.bestFloor),
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Accumulated rewards bar.
          Row(
            children: [
              _RewardChip(
                icon: Icons.monetization_on_rounded,
                color: AppColors.gold,
                value: FormatUtils.formatNumber(state.accumulatedGold),
              ),
              const SizedBox(width: 12),
              _RewardChip(
                icon: Icons.auto_awesome_rounded,
                color: AppColors.experience,
                value: FormatUtils.formatNumber(state.accumulatedExp),
              ),
              if (state.accumulatedShard > 0) ...[
                const SizedBox(width: 12),
                _RewardChip(
                  icon: Icons.diamond_rounded,
                  color: AppColors.primaryLight,
                  value: '${state.accumulatedShard}',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.color,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _DungeonArena
// =============================================================================

class _DungeonArena extends StatelessWidget {
  const _DungeonArena({required this.state});

  final DungeonState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (state.phase == DungeonPhase.idle) {
      return Center(
        child: Text(
          l.dungeonPreparing,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player team
          Expanded(
            child: _TeamColumn(
              monsters: state.playerTeam,
              label: l.ourTeam,
              labelColor: AppColors.primary,
            ),
          ),
          // Center info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FloorBadge(
                  floor: state.currentFloor,
                  phase: state.phase,
                ),
                const SizedBox(height: 6),
                const Text(
                  'VS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.turnN(state.currentTurn),
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Enemy team
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
  const _TeamColumn({
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
          ),
        ),
        const SizedBox(height: 6),
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

class _FloorBadge extends StatelessWidget {
  const _FloorBadge({required this.floor, required this.phase});

  final int floor;
  final DungeonPhase phase;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final (label, color) = switch (phase) {
      DungeonPhase.idle         => (l.standby, AppColors.textTertiary),
      DungeonPhase.fighting     => (l.dungeonFloor(floor), const Color(0xFFCE93D8)),
      DungeonPhase.floorCleared => (l.floorCleared, AppColors.gold),
      DungeonPhase.defeated     => (l.battleDefeat, AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// =============================================================================
// _DungeonLog
// =============================================================================

class _DungeonLog extends StatefulWidget {
  const _DungeonLog({required this.log});

  final List<BattleLogEntry> log;

  @override
  State<_DungeonLog> createState() => _DungeonLogState();
}

class _DungeonLogState extends State<_DungeonLog> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    final entries = widget.log.length > 20
        ? widget.log.sublist(widget.log.length - 20)
        : widget.log;

    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            color: AppColors.surfaceVariant,
            child: Row(
              children: [
                const Icon(Icons.list_alt_rounded,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 5),
                Text(
                  l.dungeonLog,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  l.battleLogCount(entries.length),
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      l.noBattleLog,
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    itemCount: entries.length,
                    itemBuilder: (ctx, i) {
                      final entry = entries[i];
                      final color = entry.isSkillActivation
                          ? const Color(0xFFCE93D8)
                          : entry.isCritical
                              ? AppColors.error
                              : AppColors.textSecondary;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1.5),
                        child: Text(
                          entry.description,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: entry.isCritical ||
                                    entry.isSkillActivation
                                ? FontWeight.w700
                                : FontWeight.w400,
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
// _DungeonControls
// =============================================================================

class _DungeonControls extends ConsumerWidget {
  const _DungeonControls({required this.state});

  final DungeonState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(dungeonProvider.notifier);

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Speed & auto row
          Row(
            children: [
              _SpeedChip(speed: state.battleSpeed, onTap: notifier.toggleSpeed),
              const Spacer(),
              _AutoChip(isAuto: state.isAutoMode, onTap: notifier.toggleAutoMode),
            ],
          ),
          const SizedBox(height: 10),
          // Action button
          _buildActionButton(context, notifier),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, DungeonNotifier notifier) {
    final l = AppLocalizations.of(context)!;
    switch (state.phase) {
      case DungeonPhase.idle:
        return _DungeonButton(
          label: l.dungeonStart,
          icon: Icons.play_arrow_rounded,
          color: const Color(0xFFCE93D8),
          onPressed: notifier.startRun,
        );
      case DungeonPhase.fighting:
        return _DungeonButton(
          label: l.battleFighting,
          icon: Icons.bolt_rounded,
          color: AppColors.textTertiary,
          onPressed: state.isAutoMode ? null : notifier.processTurn,
        );
      case DungeonPhase.floorCleared:
        return Row(
          children: [
            Expanded(
              child: _DungeonButton(
                label: l.dungeonNextFloor,
                icon: Icons.arrow_upward_rounded,
                color: AppColors.success,
                onPressed: notifier.advanceFloor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DungeonButton(
                label: l.dungeonCollect,
                icon: Icons.emoji_events_rounded,
                color: AppColors.gold,
                onPressed: () async {
                  await notifier.collectAndExit();
                  if (context.mounted) context.pop();
                },
              ),
            ),
          ],
        );
      case DungeonPhase.defeated:
        return _DungeonButton(
          label: l.dungeonCollectFloor(state.currentFloor),
          icon: Icons.emoji_events_rounded,
          color: AppColors.gold,
          onPressed: () async {
            await notifier.collectAndExit();
            if (context.mounted) context.pop();
          },
        );
    }
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({required this.speed, required this.onTap});

  final double speed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${speed.toInt()}x',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AutoChip extends StatelessWidget {
  const _AutoChip({required this.isAuto, required this.onTap});

  final bool isAuto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isAuto
              ? AppColors.success.withValues(alpha: 0.2)
              : AppColors.card.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAuto ? AppColors.success : AppColors.border,
          ),
        ),
        child: Text(
          isAuto ? l.autoShortOn : l.autoShortOff,
          style: TextStyle(
            color: isAuto ? AppColors.success : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DungeonButton extends StatelessWidget {
  const _DungeonButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDisabled ? AppColors.disabled : color.withValues(alpha: 0.85),
          foregroundColor:
              isDisabled ? AppColors.disabledText : AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: isDisabled ? 0 : 4,
          shadowColor:
              isDisabled ? Colors.transparent : color.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
