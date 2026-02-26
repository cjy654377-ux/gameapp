import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/game_config.dart';
import '../../core/utils/format_utils.dart';
import '../../domain/services/offline_reward_service.dart';

/// Shows a modal dialog presenting offline rewards and returns `true` when the
/// user taps the claim button.
Future<bool> showOfflineRewardDialog(
  BuildContext context, {
  required OfflineReward reward,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.overlayDark,
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (context, anim, secondAnim, child) {
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: child,
        ),
      );
    },
    pageBuilder: (context, _, __) => _OfflineRewardContent(reward: reward),
  );
  return result ?? false;
}

class _OfflineRewardContent extends StatelessWidget {
  const _OfflineRewardContent({required this.reward});

  final OfflineReward reward;

  @override
  Widget build(BuildContext context) {
    final hours = reward.cappedHours.floor();
    final minutes = ((reward.cappedHours - hours) * 60).round();

    String timeText;
    if (hours > 0 && minutes > 0) {
      timeText = '$hours시간 $minutes분';
    } else if (hours > 0) {
      timeText = '$hours시간';
    } else {
      timeText = '$minutes분';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.3),
                        AppColors.primaryDark.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.card_giftcard_rounded,
                        size: 48,
                        color: AppColors.gold,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '오프라인 보상',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$timeText 동안 모은 보상',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Rewards
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _RewardRow(
                        icon: Icons.monetization_on_rounded,
                        iconColor: AppColors.gold,
                        label: '골드',
                        value: '+${FormatUtils.formatNumberWithComma(reward.gold)}',
                        valueColor: AppColors.gold,
                      ),
                      const SizedBox(height: 16),
                      _RewardRow(
                        icon: Icons.auto_awesome_rounded,
                        iconColor: AppColors.experience,
                        label: '경험치',
                        value: '+${FormatUtils.formatNumberWithComma(reward.exp)}',
                        valueColor: AppColors.experience,
                      ),
                      if (reward.cappedHours >=
                          GameConfig.maxOfflineHours) ...[
                        const SizedBox(height: 12),
                        Text(
                          '최대 보상 시간에 도달했습니다',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Claim button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        '보상 받기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

