import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/core/utils/format_utils.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/presentation/providers/battle_provider.dart';
import 'package:gameapp/presentation/widgets/battle/monster_battle_card.dart';
import 'package:gameapp/presentation/widgets/common/currency_bar.dart';

// =============================================================================
// BattleScreen — root entry point
// =============================================================================

/// The main battle screen. Hosts all sub-sections from top to bottom:
/// CurrencyBar -> StageHeader -> BattleArena -> BattleLog -> ControlBar.
///
/// A [_VictoryDialog] overlay is shown whenever [BattlePhase.victory] is
/// active.
class BattleScreen extends ConsumerWidget {
  const BattleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(battleProvider.select((s) => s.phase));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Main vertical layout ─────────────────────────────────────────
          Column(
            children: [
              // Currency bar — handles its own SafeArea top padding
              const CurrencyBar(),

              // Stage header
              const _StageHeader(),

              // Battle arena: ~40 % of the remaining height
              const Expanded(
                flex: 5,
                child: _BattleArena(),
              ),

              // Thin divider
              Container(height: 1, color: AppColors.border),

              // Battle log: ~25 % of the remaining height
              const Expanded(
                flex: 3,
                child: _BattleLog(),
              ),

              // Control bar — handles its own SafeArea bottom padding
              const _ControlBar(),
            ],
          ),

          // ── Victory dialog overlay ───────────────────────────────────────
          if (phase == BattlePhase.victory) const _VictoryDialog(),
        ],
      ),
    );
  }
}

// =============================================================================
// _StageHeader
// =============================================================================

class _StageHeader extends ConsumerWidget {
  const _StageHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stageName =
        ref.watch(battleProvider.select((s) => s.currentStageName));
    final stageId =
        ref.watch(battleProvider.select((s) => s.currentStageId));

    final displayName = stageName.isNotEmpty
        ? stageName
        : (stageId > 0 ? '스테이지 $stageId' : '전투 대기중');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AppColors.surfaceVariant,
      child: Text(
        displayName,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// =============================================================================
// _BattleArena
// =============================================================================

class _BattleArena extends ConsumerWidget {
  const _BattleArena();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(battleProvider);

    // Show idle banner when no battle is active
    if (state.phase == BattlePhase.idle) {
      return const _IdleBanner();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Player team (left) ──────────────────────────────────────────
          Expanded(
            child: _MonsterGrid(
              monsters: state.playerTeam,
              label: '우리 팀',
              labelColor: AppColors.primary,
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
                  '턴 ${state.currentTurn}',
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
            child: _MonsterGrid(
              monsters: state.enemyTeam,
              label: '적 팀',
              labelColor: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _IdleBanner ───────────────────────────────────────────────────────────────

class _IdleBanner extends StatelessWidget {
  const _IdleBanner();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 52,
            color: AppColors.primary.withOpacity(0.45),
          ),
          const SizedBox(height: 14),
          const Text(
            '전투 대기중',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '아래 버튼으로 전투를 시작하세요',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

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
    final (label, color) = switch (phase) {
      BattlePhase.idle      => ('대기', AppColors.textTertiary),
      BattlePhase.preparing => ('준비중', AppColors.warning),
      BattlePhase.fighting  => ('전투중', AppColors.success),
      BattlePhase.victory   => ('승리!', AppColors.gold),
      BattlePhase.defeat    => ('패배', AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6), width: 1),
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

// =============================================================================
// _BattleLog
// =============================================================================

class _BattleLog extends ConsumerStatefulWidget {
  const _BattleLog();

  @override
  ConsumerState<_BattleLog> createState() => _BattleLogState();
}

class _BattleLogState extends ConsumerState<_BattleLog> {
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
    final log = ref.watch(battleProvider.select((s) => s.battleLog));

    // Auto-scroll to bottom after each new entry renders
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // Cap display at the last 20 entries
    final entries = log.length > 20 ? log.sublist(log.length - 20) : log;

    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Log header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            color: AppColors.surfaceVariant,
            child: Row(
              children: [
                const Icon(
                  Icons.list_alt_rounded,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                const Text(
                  '전투 로그',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${entries.length}건',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // ── Log entries list ────────────────────────────────────────────
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Text(
                      '전투 기록이 없습니다',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    itemCount: entries.length,
                    itemBuilder: (ctx, i) => _LogEntryRow(entry: entries[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── _LogEntryRow ──────────────────────────────────────────────────────────────

class _LogEntryRow extends StatelessWidget {
  const _LogEntryRow({required this.entry});

  final BattleLogEntry entry;

  Color get _textColor {
    if (entry.isCritical) return AppColors.error;
    if (entry.isElementAdvantage) return AppColors.warning;
    return AppColors.textSecondary;
  }

  String get _prefix {
    if (entry.isCritical) return '[치명타] ';
    if (entry.isElementAdvantage) return '[속성유리] ';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final h = entry.timestamp.hour.toString().padLeft(2, '0');
    final m = entry.timestamp.minute.toString().padLeft(2, '0');
    final s = entry.timestamp.second.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Text(
            '$h:$m:$s',
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 6),
          // Entry text
          Expanded(
            child: Text(
              '$_prefix${entry.description}',
              style: TextStyle(
                color: _textColor,
                fontSize: 11,
                fontWeight: entry.isCritical
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _ControlBar
// =============================================================================

class _ControlBar extends ConsumerWidget {
  const _ControlBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(battleProvider);
    final notifier = ref.read(battleProvider.notifier);

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
          // ── Row 1: speed buttons + auto-battle toggle ───────────────────
          Row(
            children: [
              _SpeedButton(
                label: '1x',
                speed: 1.0,
                currentSpeed: state.battleSpeed,
                onTap: notifier.toggleSpeed,
              ),
              const SizedBox(width: 6),
              _SpeedButton(
                label: '2x',
                speed: 2.0,
                currentSpeed: state.battleSpeed,
                onTap: notifier.toggleSpeed,
              ),
              const SizedBox(width: 6),
              _SpeedButton(
                label: '3x',
                speed: 3.0,
                currentSpeed: state.battleSpeed,
                onTap: notifier.toggleSpeed,
              ),

              const Spacer(),

              _AutoBattleToggle(
                isAuto: state.isAutoMode,
                onToggle: notifier.toggleAuto,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Row 2: primary action button ───────────────────────────────
          _PrimaryActionButton(
            phase: state.phase,
            stageId: state.currentStageId,
            notifier: notifier,
          ),
        ],
      ),
    );
  }
}

// ── _SpeedButton ──────────────────────────────────────────────────────────────

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({
    required this.label,
    required this.speed,
    required this.currentSpeed,
    required this.onTap,
  });

  final String label;

  /// The speed value this button represents (1.0, 2.0, or 3.0).
  final double speed;

  final double currentSpeed;
  final VoidCallback onTap;

  bool get _isActive => speed == currentSpeed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _isActive
              ? AppColors.primary
              : AppColors.card.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isActive ? AppColors.primaryLight : AppColors.border,
            width: 1,
          ),
          boxShadow: _isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _isActive
                ? AppColors.textPrimary
                : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── _AutoBattleToggle ─────────────────────────────────────────────────────────

class _AutoBattleToggle extends StatelessWidget {
  const _AutoBattleToggle({required this.isAuto, required this.onToggle});

  final bool isAuto;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isAuto
              ? AppColors.success.withOpacity(0.2)
              : AppColors.card.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAuto ? AppColors.success : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAuto
                  ? Icons.play_circle_filled_rounded
                  : Icons.play_circle_outline_rounded,
              size: 15,
              color: isAuto ? AppColors.success : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              isAuto ? '자동전투 ON' : '자동전투 OFF',
              style: TextStyle(
                color: isAuto ? AppColors.success : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _PrimaryActionButton ──────────────────────────────────────────────────────

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.phase,
    required this.stageId,
    required this.notifier,
  });

  final BattlePhase phase;
  final int stageId;
  final BattleNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return switch (phase) {
      BattlePhase.idle => _ActionButton(
          label: '전투 시작',
          icon: Icons.play_arrow_rounded,
          color: AppColors.success,
          onPressed: () => notifier.startBattle(stageId),
        ),
      BattlePhase.preparing => const _ActionButton(
          label: '준비 중...',
          icon: Icons.hourglass_top_rounded,
          color: AppColors.warning,
          onPressed: null,
        ),
      BattlePhase.fighting => const _ActionButton(
          label: '전투 중...',
          icon: Icons.bolt_rounded,
          color: AppColors.textTertiary,
          onPressed: null,
        ),
      BattlePhase.victory => _ActionButton(
          label: '보상 받기',
          icon: Icons.emoji_events_rounded,
          color: AppColors.gold,
          onPressed: () => notifier.collectReward(),
        ),
      BattlePhase.defeat => _ActionButton(
          label: '재도전',
          icon: Icons.refresh_rounded,
          color: AppColors.error,
          onPressed: () => notifier.startBattle(stageId),
        ),
    };
  }
}

// ── _ActionButton ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDisabled ? AppColors.disabled : color.withOpacity(0.85),
          foregroundColor:
              isDisabled ? AppColors.disabledText : AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: isDisabled ? 0 : 4,
          shadowColor:
              isDisabled ? Colors.transparent : color.withOpacity(0.4),
        ),
      ),
    );
  }
}

// =============================================================================
// _VictoryDialog — full-screen overlay shown on BattlePhase.victory
// =============================================================================

class _VictoryDialog extends ConsumerWidget {
  const _VictoryDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reward   = ref.watch(battleProvider.select((s) => s.lastReward));
    final notifier = ref.read(battleProvider.notifier);

    return Material(
      color: Colors.black.withOpacity(0.72),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.gold.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.25),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Title ────────────────────────────────────────────────────
              const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.gold,
                size: 52,
              ),
              const SizedBox(height: 8),
              const Text(
                '승리!',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 20),
              const Divider(color: AppColors.border),
              const SizedBox(height: 12),

              // ── Reward section ───────────────────────────────────────────
              if (reward != null) ...[
                const Text(
                  '획득 보상',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RewardChip(
                      icon: Icons.monetization_on_rounded,
                      iconColor: AppColors.gold,
                      label: FormatUtils.formatNumber(reward.gold),
                      sublabel: '골드',
                    ),
                    _RewardChip(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: AppColors.experience,
                      label: FormatUtils.formatNumber(reward.exp),
                      sublabel: '경험치',
                    ),
                    if (reward.bonusShard != null)
                      _RewardChip(
                        icon: Icons.diamond_rounded,
                        iconColor: AppColors.primaryLight,
                        label: '×${reward.bonusShard}',
                        sublabel: '파편',
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ] else
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    '보상을 집계 중입니다...',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ),

              // ── Collect button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => notifier.collectReward(),
                  icon: const Icon(Icons.emoji_events_rounded, size: 18),
                  label: const Text(
                    '보상 받기',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold.withOpacity(0.9),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.gold.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
