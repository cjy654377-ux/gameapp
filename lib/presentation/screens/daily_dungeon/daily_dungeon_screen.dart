import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gameapp/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../domain/services/daily_dungeon_service.dart';
import '../../providers/daily_dungeon_provider.dart';
import '../../widgets/battle/monster_battle_card.dart';
import '../../widgets/common/reward_chip.dart';

class DailyDungeonScreen extends ConsumerStatefulWidget {
  const DailyDungeonScreen({super.key});

  @override
  ConsumerState<DailyDungeonScreen> createState() => _DailyDungeonScreenState();
}

class _DailyDungeonScreenState extends ConsumerState<DailyDungeonScreen> {
  bool _scheduled = false;

  void _scheduleAutoTurn(double speed, bool isAuto) {
    if (_scheduled || !isAuto) return;
    _scheduled = true;
    final ms = (800 / speed).round();
    Future.delayed(Duration(milliseconds: ms), () {
      _scheduled = false;
      if (!mounted) return;
      final current = ref.read(dailyDungeonProvider);
      if (current.phase == DailyDungeonPhase.fighting && current.isAutoMode) {
        ref.read(dailyDungeonProvider.notifier).processTurn();
      }
      if (current.phase == DailyDungeonPhase.floorCleared && current.isAutoMode) {
        ref.read(dailyDungeonProvider.notifier).advanceFloor();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(dailyDungeonProvider);
    final notifier = ref.read(dailyDungeonProvider.notifier);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final todayElement = DailyDungeonService.todayElement;
    final elementName = isKo
        ? DailyDungeonService.elementNameKo(todayElement)
        : DailyDungeonService.elementNameEn(todayElement);

    if (state.phase == DailyDungeonPhase.fighting ||
        state.phase == DailyDungeonPhase.floorCleared) {
      _scheduleAutoTurn(state.battleSpeed, state.isAutoMode);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.dailyDungeonTitle),
        backgroundColor: AppColors.surface,
        actions: [
          if (state.phase != DailyDungeonPhase.idle)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () => _showExitDialog(context, notifier, state, l),
            ),
        ],
      ),
      body: state.phase == DailyDungeonPhase.idle
          ? _buildLobby(context, state, notifier, l, elementName, todayElement)
          : _buildBattle(context, state, notifier, l),
    );
  }

  Widget _buildLobby(
    BuildContext context,
    DailyDungeonState state,
    DailyDungeonNotifier notifier,
    AppLocalizations l,
    String elementName,
    String element,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.wb_sunny, color: Colors.orange, size: 48),
                const SizedBox(height: 8),
                Text(
                  '$elementName ${l.dailyDungeonTheme}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.dailyDungeonDesc,
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RewardChip(icon: Icons.layers, color: Colors.purple, value: '${DailyDungeonService.maxFloors}F'),
                    const SizedBox(width: 16),
                    RewardChip(icon: Icons.bolt, color: Colors.orange, value: 'x${DailyDungeonService.rewardMultiplier}'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${l.dailyDungeonRemaining}: ${state.remainingAttempts}/${DailyDungeonService.maxAttempts}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: state.remainingAttempts > 0 ? AppColors.primary : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.remainingAttempts > 0 ? () => notifier.startRun() : null,
              icon: const Icon(Icons.play_arrow),
              label: Text(l.dailyDungeonStart),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattle(
    BuildContext context,
    DailyDungeonState state,
    DailyDungeonNotifier notifier,
    AppLocalizations l,
  ) {
    return Column(
      children: [
        // Floor info + accumulated rewards
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: AppColors.surface,
          child: Row(
            children: [
              Text(
                '${state.currentFloor}F / ${DailyDungeonService.maxFloors}F',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              RewardChip(
                icon: Icons.monetization_on,
                color: Colors.amber,
                value: FormatUtils.formatNumber(state.accumulatedGold),
              ),
              const SizedBox(width: 10),
              RewardChip(
                icon: Icons.auto_awesome,
                color: Colors.blue,
                value: FormatUtils.formatNumber(state.accumulatedExp),
              ),
            ],
          ),
        ),

        // Battle area
        Expanded(
          child: state.phase == DailyDungeonPhase.defeated
              ? _buildResult(state, notifier, l)
              : state.phase == DailyDungeonPhase.floorCleared
                  ? _buildFloorCleared(state, notifier, l)
                  : _buildFighting(state),
        ),

        // Controls
        if (state.phase == DailyDungeonPhase.fighting)
          _buildControls(state, notifier, l),
      ],
    );
  }

  Widget _buildFighting(DailyDungeonState state) {
    return Row(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: state.playerTeam.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: MonsterBattleCard(monster: m),
            )).toList(),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: state.enemyTeam.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: MonsterBattleCard(monster: m),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFloorCleared(
    DailyDungeonState state,
    DailyDungeonNotifier notifier,
    AppLocalizations l,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 8),
          Text(
            '${state.currentFloor}F ${l.dailyDungeonCleared}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => notifier.advanceFloor(),
            icon: const Icon(Icons.arrow_forward),
            label: Text(l.dailyDungeonNext),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(
    DailyDungeonState state,
    DailyDungeonNotifier notifier,
    AppLocalizations l,
  ) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              state.currentFloor >= DailyDungeonService.maxFloors
                  ? Icons.emoji_events
                  : Icons.sentiment_dissatisfied,
              color: state.currentFloor >= DailyDungeonService.maxFloors
                  ? Colors.amber
                  : AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              state.currentFloor >= DailyDungeonService.maxFloors
                  ? l.dailyDungeonComplete
                  : '${state.currentFloor}F ${l.dailyDungeonDefeated}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RewardChip(
                  icon: Icons.monetization_on,
                  color: Colors.amber,
                  value: FormatUtils.formatNumber(state.accumulatedGold),
                ),
                RewardChip(
                  icon: Icons.auto_awesome,
                  color: Colors.blue,
                  value: FormatUtils.formatNumber(state.accumulatedExp),
                ),
                if (state.accumulatedShard > 0)
                  RewardChip(
                    icon: Icons.diamond,
                    color: Colors.cyan,
                    value: 'x${state.accumulatedShard}',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => notifier.collectAndExit(),
                icon: const Icon(Icons.emoji_events),
                label: Text(l.dailyDungeonCollect),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(
    DailyDungeonState state,
    DailyDungeonNotifier notifier,
    AppLocalizations l,
  ) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      color: AppColors.surface,
      child: Row(
        children: [
          GestureDetector(
            onTap: notifier.toggleSpeed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${state.battleSpeed.toInt()}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: notifier.toggleAuto,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: state.isAutoMode
                    ? AppColors.success.withValues(alpha: 0.2)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: state.isAutoMode ? AppColors.success : AppColors.border,
                ),
              ),
              child: Text(
                state.isAutoMode ? l.autoOn : l.autoOff,
                style: TextStyle(
                  color: state.isAutoMode ? AppColors.success : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => notifier.retreatRun(),
            child: Text(l.battleRetreat, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(
    BuildContext context,
    DailyDungeonNotifier notifier,
    DailyDungeonState state,
    AppLocalizations l,
  ) {
    if (state.accumulatedGold > 0 || state.accumulatedExp > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(l.battleRetreat, style: const TextStyle(color: AppColors.textPrimary)),
          content: Text(l.dailyDungeonExitConfirm, style: TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                notifier.collectAndExit();
              },
              child: Text(l.dailyDungeonCollect),
            ),
          ],
        ),
      );
    } else {
      notifier.retreatRun();
      Navigator.pop(context);
    }
  }
}
