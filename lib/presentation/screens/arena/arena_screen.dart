import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/core/utils/format_utils.dart';
import 'package:gameapp/domain/services/arena_service.dart';
import 'package:gameapp/presentation/providers/arena_provider.dart';
import 'package:gameapp/presentation/widgets/battle/monster_battle_card.dart';

class ArenaScreen extends ConsumerStatefulWidget {
  const ArenaScreen({super.key});

  @override
  ConsumerState<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends ConsumerState<ArenaScreen> {
  Timer? _battleTimer;

  @override
  void initState() {
    super.initState();
    // Generate opponents on first enter.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arena = ref.read(arenaProvider);
      if (arena.opponents.isEmpty) {
        ref.read(arenaProvider.notifier).refreshOpponents();
      }
    });
  }

  @override
  void dispose() {
    _battleTimer?.cancel();
    super.dispose();
  }

  void _startBattleTimer() {
    _battleTimer?.cancel();
    _battleTimer = Timer.periodic(
      Duration(
          milliseconds:
              (500 / ref.read(arenaProvider).battleSpeed).round()),
      (_) {
        final phase = ref.read(arenaProvider).phase;
        if (phase == ArenaPhase.fighting) {
          ref.read(arenaProvider.notifier).processTurn();
        } else {
          _battleTimer?.cancel();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final phase = ref.watch(arenaProvider.select((s) => s.phase));

    // Restart timer when speed changes.
    ref.listen(arenaProvider.select((s) => s.battleSpeed), (_, __) {
      if (ref.read(arenaProvider).phase == ArenaPhase.fighting) {
        _startBattleTimer();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('PvP 아레나'),
        centerTitle: true,
      ),
      body: switch (phase) {
        ArenaPhase.lobby => const _LobbyView(),
        ArenaPhase.fighting => _FightView(onStart: _startBattleTimer),
        ArenaPhase.victory => const _ResultView(isVictory: true),
        ArenaPhase.defeat => const _ResultView(isVictory: false),
      },
    );
  }
}

// =============================================================================
// _LobbyView — opponent selection
// =============================================================================

class _LobbyView extends ConsumerWidget {
  const _LobbyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arena = ref.watch(arenaProvider);
    final opponents = arena.opponents;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Rating & stats bar.
        _RatingBar(
          rating: arena.rating,
          wins: arena.totalWins,
          losses: arena.totalLosses,
          remaining: arena.remainingAttempts,
        ),
        const SizedBox(height: 16),

        // Opponent cards.
        ...List.generate(opponents.length, (i) {
          final op = opponents[i];
          final diffLabel = ['쉬움', '보통', '어려움'][i];
          final diffColor = [Colors.green, Colors.orange, Colors.red][i];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OpponentCard(
              opponent: op,
              difficultyLabel: diffLabel,
              difficultyColor: diffColor,
              canFight: arena.canAttempt,
              onFight: () =>
                  ref.read(arenaProvider.notifier).startFight(i),
            ),
          );
        }),

        const SizedBox(height: 8),
        // Refresh button.
        Center(
          child: TextButton.icon(
            onPressed: () =>
                ref.read(arenaProvider.notifier).refreshOpponents(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('상대 갱신'),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _RatingBar
// =============================================================================

class _RatingBar extends StatelessWidget {
  const _RatingBar({
    required this.rating,
    required this.wins,
    required this.losses,
    required this.remaining,
  });

  final int rating;
  final int wins;
  final int losses;
  final int remaining;

  String get _rankTitle {
    if (rating >= 2000) return '챔피언';
    if (rating >= 1500) return '다이아몬드';
    if (rating >= 1200) return '골드';
    if (rating >= 900) return '실버';
    return '브론즈';
  }

  Color get _rankColor {
    if (rating >= 2000) return Colors.red;
    if (rating >= 1500) return Colors.cyan;
    if (rating >= 1200) return Colors.amber;
    if (rating >= 900) return Colors.grey;
    return Colors.brown;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _rankColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Rank icon.
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _rankColor.withValues(alpha: 0.2),
            ),
            child: Icon(Icons.emoji_events, color: _rankColor, size: 24),
          ),
          const SizedBox(width: 12),
          // Rating info.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_rankTitle · $rating점',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _rankColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$wins승 $losses패',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Attempts remaining.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: remaining > 0
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : AppColors.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '남은 도전: $remaining/${ArenaService.maxDailyAttempts}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: remaining > 0 ? AppColors.primary : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _OpponentCard
// =============================================================================

class _OpponentCard extends StatelessWidget {
  const _OpponentCard({
    required this.opponent,
    required this.difficultyLabel,
    required this.difficultyColor,
    required this.canFight,
    required this.onFight,
  });

  final ArenaOpponent opponent;
  final String difficultyLabel;
  final Color difficultyColor;
  final bool canFight;
  final VoidCallback onFight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: difficultyColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: name + difficulty badge.
          Row(
            children: [
              Icon(Icons.person, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  opponent.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: difficultyColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  difficultyLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: difficultyColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Team preview.
          Row(
            children: [
              ...opponent.team.map((m) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        m.name,
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: AppColors.background,
                      side: BorderSide(color: AppColors.border),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 8),

          // Rewards & fight button.
          Row(
            children: [
              Text(
                '레이팅 ${opponent.rating}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.monetization_on, size: 14, color: Colors.amber),
              Text(
                ' ${FormatUtils.formatNumber(opponent.rewardGold)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.diamond, size: 14, color: Colors.cyan),
              Text(
                ' ${opponent.rewardDiamond}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: canFight ? onFight : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: difficultyColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '도전',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _FightView — arena battle
// =============================================================================

class _FightView extends ConsumerStatefulWidget {
  const _FightView({required this.onStart});
  final VoidCallback onStart;

  @override
  ConsumerState<_FightView> createState() => _FightViewState();
}

class _FightViewState extends ConsumerState<_FightView> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_started) {
        _started = true;
        widget.onStart();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final arena = ref.watch(arenaProvider);
    final opponent = arena.opponents.isNotEmpty &&
            arena.selectedOpponentIndex >= 0
        ? arena.opponents[arena.selectedOpponentIndex]
        : null;

    return Column(
      children: [
        // Opponent name header.
        if (opponent != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'VS ${opponent.name}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),

        // Battle arena.
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Player team.
                Expanded(
                  child: _TeamGrid(
                    team: arena.playerTeam,
                    label: '나',
                    color: Colors.blue,
                  ),
                ),
                // VS divider.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                // Enemy team.
                Expanded(
                  child: _TeamGrid(
                    team: arena.enemyTeam,
                    label: '상대',
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),

        Container(height: 1, color: AppColors.border),

        // Battle log.
        Expanded(
          flex: 3,
          child: _BattleLogView(log: arena.battleLog),
        ),

        // Speed controls.
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SpeedButton(
                  speed: arena.battleSpeed,
                  onTap: () =>
                      ref.read(arenaProvider.notifier).toggleSpeed(),
                ),
                const SizedBox(width: 12),
                Text(
                  '턴 ${arena.currentTurn}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _TeamGrid
// =============================================================================

class _TeamGrid extends StatelessWidget {
  const _TeamGrid({
    required this.team,
    required this.label,
    required this.color,
  });

  final List team;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            physics: const NeverScrollableScrollPhysics(),
            children: team
                .map<Widget>((m) => MonsterBattleCard(monster: m))
                .toList(),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _BattleLogView
// =============================================================================

class _BattleLogView extends StatelessWidget {
  const _BattleLogView({required this.log});
  final List log;

  @override
  Widget build(BuildContext context) {
    if (log.isEmpty) {
      return Center(
        child: Text(
          '전투 대기 중...',
          style: TextStyle(color: AppColors.textTertiary),
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: log.length,
      itemBuilder: (ctx, i) {
        final entry = log[log.length - 1 - i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text(
            entry.description,
            style: TextStyle(
              fontSize: 11,
              color: entry.isSkillActivation
                  ? Colors.purple[300]
                  : entry.isCritical
                      ? Colors.orange[300]
                      : AppColors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// _SpeedButton
// =============================================================================

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({required this.speed, required this.onTap});
  final double speed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          '${speed.toStringAsFixed(0)}x',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _ResultView — victory / defeat
// =============================================================================

class _ResultView extends ConsumerWidget {
  const _ResultView({required this.isVictory});
  final bool isVictory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arena = ref.watch(arenaProvider);
    final reward = arena.lastReward;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Result icon.
            Icon(
              isVictory ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              size: 64,
              color: isVictory ? Colors.amber : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isVictory ? '승리!' : '패배',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isVictory ? Colors.amber : AppColors.error,
              ),
            ),
            const SizedBox(height: 24),

            // Rating change.
            if (reward != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _RewardRow(
                      icon: Icons.trending_up,
                      label: '레이팅',
                      value: '${reward.ratingChange > 0 ? '+' : ''}${reward.ratingChange}',
                      color: reward.ratingChange > 0
                          ? Colors.green
                          : AppColors.error,
                    ),
                    if (reward.gold > 0) ...[
                      const SizedBox(height: 8),
                      _RewardRow(
                        icon: Icons.monetization_on,
                        label: '골드',
                        value: '+${FormatUtils.formatNumber(reward.gold)}',
                        color: Colors.amber,
                      ),
                    ],
                    if (reward.diamond > 0) ...[
                      const SizedBox(height: 8),
                      _RewardRow(
                        icon: Icons.diamond,
                        label: '다이아',
                        value: '+${reward.diamond}',
                        color: Colors.cyan,
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (isVictory) {
                    ref.read(arenaProvider.notifier).collectAndReturn();
                  } else {
                    ref.read(arenaProvider.notifier).returnToLobby();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isVictory ? Colors.amber : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isVictory ? '보상 받기' : '돌아가기',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
