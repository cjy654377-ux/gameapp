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

/// Shows the milestone claiming dialog.
/// Returns the set of milestone days that were claimed.
Future<Set<int>> showMilestoneDialog(
  BuildContext context, {
  required AttendanceState attendance,
}) async {
  final result = await showDialog<Set<int>>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _MilestoneDialog(attendance: attendance),
  );
  return result ?? {};
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
            // Milestone summary
            if (attendance.claimableMilestones.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l.milestonePending(attendance.claimableMilestones.length),
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    final isClaimed = attendance.canCheckIn
        ? day < currentDay
        : day <= attendance.currentStreak;
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

// =============================================================================
// Milestone Dialog
// =============================================================================

class _MilestoneDialog extends StatefulWidget {
  const _MilestoneDialog({required this.attendance});
  final AttendanceState attendance;

  @override
  State<_MilestoneDialog> createState() => _MilestoneDialogState();
}

class _MilestoneDialogState extends State<_MilestoneDialog> {
  late Set<int> _claimed;

  @override
  void initState() {
    super.initState();
    _claimed = {...widget.attendance.claimedMilestones};
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      title: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
          const SizedBox(width: 8),
          Text(
            l.milestoneTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.milestoneDesc(widget.attendance.totalDays),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            ...AttendanceMilestone.milestones.map((m) =>
                _buildMilestoneRow(context, l, m)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(_claimed),
          child: Text(l.confirm, style: TextStyle(color: AppColors.textTertiary)),
        ),
      ],
    );
  }

  Widget _buildMilestoneRow(
      BuildContext context, AppLocalizations l, AttendanceMilestone m) {
    final reached = widget.attendance.totalDays >= m.totalDays;
    final claimed = _claimed.contains(m.totalDays);
    final claimable = reached && !claimed;

    final progress = reached
        ? 1.0
        : widget.attendance.totalDays / m.totalDays;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: claimed
              ? AppColors.success.withValues(alpha: 0.08)
              : claimable
                  ? Colors.amber.withValues(alpha: 0.1)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: claimable
                ? Colors.amber.withValues(alpha: 0.6)
                : claimed
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.border,
            width: claimable ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Day badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: reached
                    ? Colors.amber.withValues(alpha: 0.2)
                    : AppColors.border.withValues(alpha: 0.3),
              ),
              child: Center(
                child: Text(
                  '${m.totalDays}',
                  style: TextStyle(
                    color: reached ? Colors.amber : AppColors.textTertiary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Reward info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.milestoneDayLabel(m.totalDays),
                    style: TextStyle(
                      color: reached ? AppColors.textPrimary : AppColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    children: _rewardChips(l, m, reached),
                  ),
                  if (!reached) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status
            if (claimed)
              const Icon(Icons.check_circle, color: AppColors.success, size: 24)
            else if (claimable)
              SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _claimed.add(m.totalDays));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    l.milestoneClaim,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
            else
              Icon(Icons.lock, color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  List<Widget> _rewardChips(AppLocalizations l, AttendanceMilestone m, bool reached) {
    final chips = <Widget>[];
    final color = reached ? AppColors.textSecondary : AppColors.textTertiary;
    final fontSize = 10.0;

    if (m.gold > 0) {
      chips.add(_chip('🪙${m.gold}', color, fontSize));
    }
    if (m.diamond > 0) {
      chips.add(_chip('💎${m.diamond}', color, fontSize));
    }
    if (m.gachaTicket > 0) {
      chips.add(_chip('🎟️${m.gachaTicket}', color, fontSize));
    }
    if (m.expPotion > 0) {
      chips.add(_chip('🧪${m.expPotion}', color, fontSize));
    }
    return chips;
  }

  Widget _chip(String text, Color color, double fontSize) {
    return Text(
      text,
      style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600),
    );
  }
}
