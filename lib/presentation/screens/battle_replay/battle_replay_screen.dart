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
    final filtered = state.filteredRecords;

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
          : Column(
              children: [
                // Summary + Filter bar
                _SummaryBar(state: state, l: l, ref: ref),
                // List
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            l.replayNoMatch,
                            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _RecordCard(
                            record: filtered[i],
                            l: l,
                            onTap: () => _showReplayDetail(context, ref, filtered[i], l),
                            onDelete: () => _confirmDelete(context, ref, filtered[i], l),
                          ),
                        ),
                ),
              ],
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

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BattleRecord record,
    AppLocalizations l,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l.replayDeleteOne, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          l.replayDeleteConfirm(record.label),
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(battleReplayProvider.notifier).deleteRecord(record.id);
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
    WidgetRef ref,
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
      builder: (_) => _ReplayDetailSheet(record: record, l: l, ref: ref),
    );
  }
}

// =============================================================================
// Summary Bar with Filter
// =============================================================================

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.state, required this.l, required this.ref});
  final BattleReplayState state;
  final AppLocalizations l;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final winRate = state.records.isNotEmpty
        ? (state.victoryCount / state.records.length * 100).toStringAsFixed(0)
        : '0';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      color: AppColors.surface,
      child: Column(
        children: [
          // Win rate bar
          Row(
            children: [
              _StatChip(
                icon: Icons.emoji_events,
                color: Colors.green,
                label: '${state.victoryCount}${l.replayVictory}',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.close,
                color: AppColors.error,
                label: '${state.defeatCount}${l.replayDefeat}',
              ),
              const Spacer(),
              Text(
                l.replayWinRate(winRate),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Filter chips
          Row(
            children: ReplayFilter.values.map((f) {
              final selected = state.filter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(
                    _filterLabel(f, l),
                    style: TextStyle(
                      fontSize: 11,
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  selected: selected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.background,
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                  onSelected: (_) => ref.read(battleReplayProvider.notifier).setFilter(f),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _filterLabel(ReplayFilter f, AppLocalizations l) {
    switch (f) {
      case ReplayFilter.all:
        return l.replayFilterAll;
      case ReplayFilter.victory:
        return l.replayVictory;
      case ReplayFilter.defeat:
        return l.replayDefeat;
    }
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.color, required this.label});
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
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
    required this.onDelete,
  });
  final BattleRecord record;
  final AppLocalizations l;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasStats = record.stats.totalDamage > 0;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
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
        child: Column(
          children: [
            Row(
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
            // Stats summary
            if (hasStats) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _MiniStat('DMG', FormatUtils.compact(record.stats.totalDamage), AppColors.textSecondary),
                  const SizedBox(width: 12),
                  _MiniStat('CRIT', '${record.stats.totalCriticals}', Colors.orange),
                  const SizedBox(width: 12),
                  _MiniStat('MVP', record.stats.mvpName, AppColors.primary),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: TextStyle(fontSize: 9, color: AppColors.textTertiary, fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// =============================================================================
// Replay Detail Sheet
// =============================================================================

class _ReplayDetailSheet extends StatefulWidget {
  const _ReplayDetailSheet({required this.record, required this.l, required this.ref});
  final BattleRecord record;
  final AppLocalizations l;
  final WidgetRef ref;

  @override
  State<_ReplayDetailSheet> createState() => _ReplayDetailSheetState();
}

class _ReplayDetailSheetState extends State<_ReplayDetailSheet> {
  bool _showStats = true;

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final l = widget.l;
    final hasStats = record.stats.totalDamage > 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
                // Toggle stats/log
                if (hasStats)
                  IconButton(
                    icon: Icon(
                      _showStats ? Icons.list : Icons.bar_chart,
                      color: AppColors.primary,
                    ),
                    onPressed: () => setState(() => _showStats = !_showStats),
                    tooltip: _showStats ? l.replayShowLog : l.replayShowStats,
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
          // Content
          if (hasStats && _showStats)
            _StatsPanel(stats: record.stats, l: l)
          else
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
    );
  }
}

// =============================================================================
// Stats Panel
// =============================================================================

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.stats, required this.l});
  final BattleRecordStats stats;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary stats
            Row(
              children: [
                Expanded(child: _StatBox(l.replayTotalDmg, FormatUtils.compact(stats.totalDamage), Colors.red)),
                const SizedBox(width: 8),
                Expanded(child: _StatBox(l.replayCritCount, '${stats.totalCriticals}', Colors.orange)),
                const SizedBox(width: 8),
                Expanded(child: _StatBox(l.replaySkillCount, '${stats.totalSkillUses}', Colors.purple)),
              ],
            ),
            const SizedBox(height: 16),
            // MVP
            if (stats.mvpName.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withValues(alpha: 0.15),
                      Colors.amber.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 24),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MVP',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.amber[700],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          stats.mvpName,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
