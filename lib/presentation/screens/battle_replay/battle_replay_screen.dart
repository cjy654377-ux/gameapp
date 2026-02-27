import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gameapp/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../providers/battle_replay_provider.dart';

class BattleReplayScreen extends ConsumerWidget {
  const BattleReplayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(battleReplayProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.replayTitle),
        backgroundColor: AppColors.surface,
        actions: [
          if (state.records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmClear(context, ref, l),
            ),
        ],
      ),
      body: state.records.isEmpty
          ? Center(
              child: Text(
                l.replayEmpty,
                style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.records.length,
              itemBuilder: (_, i) => _RecordCard(
                record: state.records[i],
                l: l,
                onTap: () => _showReplayDetail(context, state.records[i], l),
              ),
            ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l.replayClear, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l.replayClearConfirm, style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(battleReplayProvider.notifier).clearAll();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l.confirm, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReplayDetail(
    BuildContext context,
    BattleRecord record,
    AppLocalizations l,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    record.isVictory ? Icons.emoji_events : Icons.close,
                    color: record.isVictory ? Colors.amber : AppColors.error,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${record.totalTurns} ${l.replayTurns} | ${record.logLines.length} ${l.replayActions}',
                          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            // Team info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.replayMyTeam,
                            style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        Text(record.playerNames.join(', '),
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Text('VS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textTertiary)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(l.replayEnemyTeam,
                            style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.bold)),
                        Text(record.enemyNames.join(', '),
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            textAlign: TextAlign.right),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            // Log lines
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.all(12),
                itemCount: record.logLines.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          record.logLines[i],
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                        ),
                      ),
                    ],
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

// =============================================================================
// Record Card
// =============================================================================

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.l,
    required this.onTap,
  });
  final BattleRecord record;
  final AppLocalizations l;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: record.isVictory
                ? Colors.green.withValues(alpha: 0.3)
                : AppColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: record.isVictory
                    ? Colors.green.withValues(alpha: 0.15)
                    : AppColors.error.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Icon(
                  record.isVictory ? Icons.emoji_events : Icons.close,
                  color: record.isVictory ? Colors.green : AppColors.error,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${record.isVictory ? l.replayVictory : l.replayDefeat} | ${record.totalTurns} ${l.replayTurns}',
                    style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            Text(
              FormatUtils.formatDateTime(record.timestamp),
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}
