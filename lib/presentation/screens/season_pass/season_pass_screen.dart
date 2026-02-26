import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gameapp/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/static/season_pass_database.dart';
import '../../providers/season_pass_provider.dart';

class SeasonPassScreen extends ConsumerStatefulWidget {
  const SeasonPassScreen({super.key});

  @override
  ConsumerState<SeasonPassScreen> createState() => _SeasonPassScreenState();
}

class _SeasonPassScreenState extends ConsumerState<SeasonPassScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(seasonPassProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(seasonPassProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.seasonPassTitle),
        backgroundColor: AppColors.surface,
        actions: [
          // Premium toggle (simulated)
          TextButton.icon(
            onPressed: () => ref.read(seasonPassProvider.notifier).togglePremium(),
            icon: Icon(
              state.isPremium ? Icons.star : Icons.star_border,
              color: state.isPremium ? Colors.amber : AppColors.textTertiary,
              size: 20,
            ),
            label: Text(
              state.isPremium ? l.seasonPassPremiumActive : l.seasonPassPremiumBuy,
              style: TextStyle(
                color: state.isPremium ? Colors.amber : AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header: Level + XP bar + Days remaining
          _PassHeader(state: state, l: l),
          // Reward list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              cacheExtent: 500,
              itemCount: SeasonPassDatabase.maxLevel,
              itemBuilder: (_, i) {
                final rewardLevel = i + 1;
                final reward = SeasonPassDatabase.rewards[i];
                return _RewardRow(
                  reward: reward,
                  state: state,
                  onClaimFree: () =>
                      ref.read(seasonPassProvider.notifier).claimFreeReward(rewardLevel),
                  onClaimPremium: () =>
                      ref.read(seasonPassProvider.notifier).claimPremiumReward(rewardLevel),
                  l: l,
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
// Header
// =============================================================================

class _PassHeader extends StatelessWidget {
  const _PassHeader({required this.state, required this.l});
  final SeasonPassState state;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.seasonPassLevel(state.level),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.seasonPassDaysLeft(state.daysRemaining),
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  ),
                ],
              ),
              if (state.isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l.seasonPassPremiumBadge,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // XP Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: state.xpProgress,
              minHeight: 10,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                state.isPremium ? Colors.amber : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'XP: ${state.currentXp} / ${state.xpToNextLevel}',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
              Text(
                'Lv.${state.level} / ${SeasonPassDatabase.maxLevel}',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Reward Row
// =============================================================================

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.reward,
    required this.state,
    required this.onClaimFree,
    required this.onClaimPremium,
    required this.l,
  });

  final SeasonPassReward reward;
  final SeasonPassState state;
  final VoidCallback onClaimFree;
  final VoidCallback onClaimPremium;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = state.level >= reward.level;
    final freeClaimed = state.isFreeClaimed(reward.level);
    final premiumClaimed = state.isPremiumClaimed(reward.level);
    final canFree = state.canClaimFree(reward.level);
    final canPremium = state.canClaimPremium(reward.level);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppColors.surface
            : AppColors.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUnlocked ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Level badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : AppColors.disabled.withValues(alpha: 0.2),
            ),
            child: Center(
              child: Text(
                '${reward.level}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? AppColors.primary : AppColors.textTertiary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Free reward
          Expanded(
            child: _RewardCell(
              type: reward.freeType,
              amount: reward.freeAmount,
              isClaimed: freeClaimed,
              canClaim: canFree,
              onClaim: onClaimFree,
              isLocked: !isUnlocked,
              label: l.seasonPassFree,
            ),
          ),
          const SizedBox(width: 6),

          // Premium reward
          Expanded(
            child: _RewardCell(
              type: reward.premiumType,
              amount: reward.premiumAmount,
              isClaimed: premiumClaimed,
              canClaim: canPremium,
              onClaim: onClaimPremium,
              isLocked: !isUnlocked || !state.isPremium,
              isPremium: true,
              label: l.seasonPassPremium,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Reward Cell
// =============================================================================

class _RewardCell extends StatelessWidget {
  const _RewardCell({
    required this.type,
    required this.amount,
    required this.isClaimed,
    required this.canClaim,
    required this.onClaim,
    required this.isLocked,
    required this.label,
    this.isPremium = false,
  });

  final String type;
  final int amount;
  final bool isClaimed;
  final bool canClaim;
  final VoidCallback onClaim;
  final bool isLocked;
  final bool isPremium;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canClaim ? onClaim : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isClaimed
              ? Colors.green.withValues(alpha: 0.1)
              : canClaim
                  ? (isPremium ? Colors.amber.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.1))
                  : AppColors.surfaceVariant.withValues(alpha: 0.3),
          border: Border.all(
            color: isClaimed
                ? Colors.green.withValues(alpha: 0.3)
                : canClaim
                    ? (isPremium ? Colors.amber.withValues(alpha: 0.5) : AppColors.primary.withValues(alpha: 0.3))
                    : AppColors.border.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _typeIcon(type),
                  size: 14,
                  color: isClaimed
                      ? Colors.green
                      : isLocked
                          ? AppColors.textTertiary
                          : _typeColor(type),
                ),
                const SizedBox(width: 3),
                Text(
                  '$amount',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isClaimed
                        ? Colors.green
                        : isLocked
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              isClaimed
                  ? '✓'
                  : canClaim
                      ? label
                      : isPremium && !isClaimed
                          ? '★'
                          : '🔒',
              style: TextStyle(
                fontSize: 9,
                color: isClaimed
                    ? Colors.green
                    : canClaim
                        ? AppColors.primary
                        : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'gold':
        return Icons.monetization_on;
      case 'diamond':
        return Icons.diamond;
      case 'expPotion':
        return Icons.science;
      case 'shard':
        return Icons.auto_awesome;
      case 'gachaTicket':
        return Icons.confirmation_number;
      default:
        return Icons.card_giftcard;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'gold':
        return Colors.amber;
      case 'diamond':
        return Colors.cyan;
      case 'expPotion':
        return Colors.green;
      case 'shard':
        return Colors.purple;
      case 'gachaTicket':
        return Colors.orange;
      default:
        return AppColors.textSecondary;
    }
  }
}
