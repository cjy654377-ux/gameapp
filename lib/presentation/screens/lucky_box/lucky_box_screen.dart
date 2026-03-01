import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/l10n/app_localizations.dart';
import 'package:gameapp/presentation/providers/lucky_box_provider.dart';

class LuckyBoxScreen extends ConsumerStatefulWidget {
  const LuckyBoxScreen({super.key});

  @override
  ConsumerState<LuckyBoxScreen> createState() => _LuckyBoxScreenState();
}

class _LuckyBoxScreenState extends ConsumerState<LuckyBoxScreen>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _glowController;
  late Animation<double> _spinAnimation;
  LuckyBoxReward? _wonReward;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _onSpin() async {
    final notifier = ref.read(luckyBoxProvider.notifier);
    final currentState = ref.read(luckyBoxProvider);
    if (currentState.claimedToday || currentState.isSpinning) return;

    // Get result first
    final reward = await notifier.spin();
    if (reward == null) return;

    // Then play spin animation
    await _spinController.forward(from: 0);

    if (!mounted) return;
    setState(() {
      _wonReward = reward;
      _showResult = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(luckyBoxProvider);
    final notifier = ref.read(luckyBoxProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.luckyBoxTitle),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Streak info
            _StreakBanner(
              streak: state.streak,
              nextMilestone: notifier.nextStreakMilestone,
              l: l,
            ),
            const SizedBox(height: 24),
            // Lucky box animation area
            _LuckyBoxArea(
              spinAnimation: _spinAnimation,
              glowController: _glowController,
              claimed: state.claimedToday,
              showResult: _showResult,
              wonReward: _wonReward,
              l: l,
            ),
            const SizedBox(height: 24),
            // Spin button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (state.claimedToday || state.isSpinning) ? null : _onSpin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (state.claimedToday || state.isSpinning)
                      ? AppColors.disabled
                      : const Color(0xFFFFB300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: (state.claimedToday || state.isSpinning) ? 0 : 8,
                ),
                child: Text(
                  state.claimedToday ? l.luckyBoxClaimed : l.luckyBoxOpen,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: state.claimedToday ? AppColors.textTertiary : Colors.white,
                  ),
                ),
              ),
            ),
            if (notifier.isStreakBonusSpin) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.rarityLegendary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.rarityLegendary.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  l.luckyBoxStreakBonus,
                  style: const TextStyle(
                    color: AppColors.rarityLegendary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Reward table
            _RewardTable(l: l),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Streak Banner
// =============================================================================

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({
    required this.streak,
    required this.nextMilestone,
    required this.l,
  });

  final int streak;
  final int nextMilestone;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final progress = (streak % 7) / 7;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    l.luckyBoxStreak(streak),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                l.luckyBoxNextBonus(nextMilestone),
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          // 7-day dots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final dayNum = (streak ~/ 7) * 7 + i + 1;
              final isCompleted = dayNum <= streak;
              return Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? Colors.orange.withValues(alpha: 0.2)
                      : AppColors.surface,
                  border: Border.all(
                    color: isCompleted ? Colors.orange : AppColors.border,
                    width: isCompleted ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.orange, size: 16)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Lucky Box Area
// =============================================================================

class _LuckyBoxArea extends AnimatedWidget {
  const _LuckyBoxArea({
    required Animation<double> spinAnimation,
    required this.glowController,
    required this.claimed,
    required this.showResult,
    required this.wonReward,
    required this.l,
  }) : super(listenable: spinAnimation);

  final AnimationController glowController;
  final bool claimed;
  final bool showResult;
  final LuckyBoxReward? wonReward;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final spinValue = (listenable as Animation<double>).value;
    final glowValue = glowController.value;

    return SizedBox(
      height: 250,
      child: Center(
        child: showResult && wonReward != null
            ? _ResultDisplay(reward: wonReward!, l: l)
            : _BoxDisplay(
                spinValue: spinValue,
                glowValue: glowValue,
                claimed: claimed,
              ),
      ),
    );
  }
}

class _BoxDisplay extends StatelessWidget {
  const _BoxDisplay({
    required this.spinValue,
    required this.glowValue,
    required this.claimed,
  });

  final double spinValue;
  final double glowValue;
  final bool claimed;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: spinValue * math.pi * 4,
      child: Transform.scale(
        scale: 1.0 + (spinValue < 0.5 ? spinValue * 0.3 : (1 - spinValue) * 0.3),
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: claimed
                  ? [Colors.grey.shade700, Colors.grey.shade800]
                  : [
                      Color.lerp(
                        const Color(0xFFFFB300),
                        const Color(0xFFFF6F00),
                        glowValue,
                      )!,
                      const Color(0xFFFF8F00),
                    ],
            ),
            boxShadow: claimed
                ? null
                : [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.3 + glowValue * 0.2),
                      blurRadius: 30 + glowValue * 20,
                      spreadRadius: 5 + glowValue * 5,
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              claimed ? '📦' : '🎁',
              style: const TextStyle(fontSize: 72),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultDisplay extends StatelessWidget {
  const _ResultDisplay({required this.reward, required this.l});

  final LuckyBoxReward reward;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _rewardColor.withValues(alpha: 0.3),
                _rewardColor.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: Center(
            child: Text(
              reward.emoji,
              style: const TextStyle(fontSize: 64),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _rewardName(l),
          style: TextStyle(
            color: _rewardColor,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'x${reward.amount}',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Color get _rewardColor {
    switch (reward.type) {
      case LuckyBoxRewardType.gold:
        return Colors.amber;
      case LuckyBoxRewardType.diamond:
        return Colors.cyan;
      case LuckyBoxRewardType.expPotion:
        return Colors.green;
      case LuckyBoxRewardType.gachaTicket:
        return Colors.purple;
    }
  }

  String _rewardName(AppLocalizations l) {
    switch (reward.type) {
      case LuckyBoxRewardType.gold:
        return l.gold;
      case LuckyBoxRewardType.diamond:
        return l.diamond;
      case LuckyBoxRewardType.expPotion:
        return l.expPotion;
      case LuckyBoxRewardType.gachaTicket:
        return l.gachaTicket;
    }
  }
}

// =============================================================================
// Reward Table
// =============================================================================

class _RewardTable extends StatelessWidget {
  const _RewardTable({required this.l});

  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.luckyBoxRewardTable,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...LuckyBoxDatabase.rewards.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text(r.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _rewardLabel(r, l),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '${(r.probability * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _rewardLabel(LuckyBoxReward r, AppLocalizations l) {
    switch (r.type) {
      case LuckyBoxRewardType.gold:
        return '${l.gold} x${r.amount}';
      case LuckyBoxRewardType.diamond:
        return '${l.diamond} x${r.amount}';
      case LuckyBoxRewardType.expPotion:
        return '${l.expPotion} x${r.amount}';
      case LuckyBoxRewardType.gachaTicket:
        return '${l.gachaTicket} x${r.amount}';
    }
  }
}
