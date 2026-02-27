import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/enums/monster_element.dart';
import '../../../core/enums/monster_rarity.dart';
import '../../../core/utils/format_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/gacha_history_provider.dart';

class GachaHistoryScreen extends ConsumerWidget {
  const GachaHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final history = ref.watch(gachaHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.gachaHistoryTitle),
        backgroundColor: AppColors.surface,
        actions: [
          if (history.entries.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, ref),
              child: Text(l.replayClear,
                  style: TextStyle(color: Colors.red.shade300)),
            ),
        ],
      ),
      body: history.entries.isEmpty
          ? Center(
              child: Text(l.gachaHistoryEmpty,
                  style: TextStyle(color: AppColors.textTertiary)),
            )
          : Column(
              children: [
                // Stats summary
                _StatsSummary(history: history),
                const Divider(height: 1),
                // Entry list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: history.entries.length,
                    itemBuilder: (context, index) {
                      final entry = history.entries[index];
                      return _HistoryTile(entry: entry);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.replayClear),
        content: Text(l.gachaHistoryClearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(gachaHistoryProvider.notifier).clearAll();
              Navigator.pop(ctx);
            },
            child: Text(l.confirm),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _StatsSummary
// =============================================================================

class _StatsSummary extends StatelessWidget {
  const _StatsSummary({required this.history});

  final GachaHistoryState history;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final stats = history.rarityStats;

    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.surface,
      child: Column(
        children: [
          Text(
            l.gachaHistoryTotal(history.totalPulls),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int r = 5; r >= 1; r--)
                _RarityChip(
                  rarity: r,
                  count: stats[r] ?? 0,
                  total: history.totalPulls,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RarityChip extends StatelessWidget {
  const _RarityChip({
    required this.rarity,
    required this.count,
    required this.total,
  });

  final int rarity;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final mr = MonsterRarity.fromRarity(rarity);
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
    return Column(
      children: [
        Text(mr.starsDisplay, style: TextStyle(color: mr.color, fontSize: 12)),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text('$pct%', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
      ],
    );
  }
}

// =============================================================================
// _HistoryTile
// =============================================================================

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final GachaHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rarity = MonsterRarity.fromRarity(entry.rarity);
    final element =
        MonsterElement.fromName(entry.element) ?? MonsterElement.fire;

    return Card(
      color: entry.rarity >= 4
          ? rarity.color.withValues(alpha: 0.08)
          : AppColors.surfaceVariant,
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: ListTile(
        dense: true,
        leading: Text(element.emoji, style: const TextStyle(fontSize: 24)),
        title: Text(
          entry.monsterName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: entry.rarity >= 4 ? rarity.color : null,
          ),
        ),
        subtitle: Text(
          '${rarity.starsDisplay}  ${FormatUtils.formatDateTime(entry.timestamp)}',
          style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
        trailing: entry.isPity
            ? Chip(
                label: Text(l.gachaPityLabel, style: const TextStyle(fontSize: 10)),
                backgroundColor: Colors.amber.withValues(alpha: 0.2),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )
            : null,
      ),
    );
  }
}
