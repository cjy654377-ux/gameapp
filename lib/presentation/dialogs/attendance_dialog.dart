import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../providers/attendance_provider.dart';
import 'package:gameapp/l10n/app_localizations.dart';

/// Shows the 7-day attendance reward dialog.
/// Returns true if the user checked in.
Future<bool> showAttendanceDialog(
  BuildContext context, {
  required AttendanceState attendance,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _AttendanceDialog(attendance: attendance),
  );
  return result ?? false;
}

class _AttendanceDialog extends StatelessWidget {
  const _AttendanceDialog({required this.attendance});
  final AttendanceState attendance;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final currentDay = attendance.canCheckIn
        ? (attendance.currentStreak % 7) + 1
        : attendance.currentStreak;

    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      title: Row(
        children: [
          Icon(Icons.calendar_today, color: AppColors.primary, size: 24),
          const SizedBox(width: 8),
          Text(
            l.attendanceTitle,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.attendanceDesc(attendance.totalDays),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            // 7-day grid (2 rows: 4+3)
            _buildRewardGrid(context, currentDay),
          ],
        ),
      ),
      actions: [
        if (!attendance.canCheckIn)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.confirm, style: TextStyle(color: AppColors.textTertiary)),
          ),
        if (attendance.canCheckIn)
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l.cancel, style: TextStyle(color: AppColors.textTertiary)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    l.attendanceCheckIn,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRewardGrid(BuildContext context, int currentDay) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: _buildDayCell(context, l, i + 1, currentDay)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (int i = 4; i < 7; i++) ...[
              if (i > 4) const SizedBox(width: 6),
              Expanded(child: _buildDayCell(context, l, i + 1, currentDay)),
            ],
            const SizedBox(width: 6),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildDayCell(
      BuildContext context, AppLocalizations l, int day, int currentDay) {
    final reward = AttendanceReward.cycle[day - 1];
    final isClaimed = day <= attendance.currentStreak && !attendance.canCheckIn
        ? day <= attendance.currentStreak
        : day < currentDay;
    final isToday = attendance.canCheckIn && day == currentDay;
    final isGrandPrize = day == 7;

    Color borderColor;
    Color bgColor;
    if (isToday) {
      borderColor = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.15);
    } else if (isClaimed) {
      borderColor = AppColors.success.withValues(alpha: 0.5);
      bgColor = AppColors.success.withValues(alpha: 0.1);
    } else {
      borderColor = AppColors.border;
      bgColor = AppColors.surface;
    }

    if (isGrandPrize && !isClaimed) {
      borderColor = Colors.amber;
      if (isToday) bgColor = Colors.amber.withValues(alpha: 0.15);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: isToday ? 2 : 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.attendanceDay(day),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isToday
                  ? AppColors.primary
                  : isGrandPrize
                      ? Colors.amber
                      : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          if (isClaimed)
            Icon(Icons.check_circle, color: AppColors.success, size: 20)
          else ...[
            _rewardIcon(reward),
            Text(
              _rewardText(reward),
              style: TextStyle(
                fontSize: 9,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _rewardIcon(AttendanceReward reward) {
    if (reward.diamond > 0 && reward.gachaTicket > 0) {
      return Icon(Icons.star, color: Colors.amber, size: 18);
    }
    if (reward.gachaTicket > 0) {
      return Icon(Icons.confirmation_number, color: Colors.purple, size: 18);
    }
    if (reward.diamond > 0) {
      return Icon(Icons.diamond, color: Colors.cyan, size: 18);
    }
    return Icon(Icons.monetization_on, color: Colors.amber[700], size: 18);
  }

  String _rewardText(AttendanceReward reward) {
    final parts = <String>[];
    if (reward.gold > 0) parts.add('${reward.gold}G');
    if (reward.diamond > 0) parts.add('${reward.diamond}D');
    if (reward.gachaTicket > 0) parts.add('${reward.gachaTicket}T');
    if (reward.expPotion > 0) parts.add('${reward.expPotion}P');
    return parts.join('\n');
  }
}
