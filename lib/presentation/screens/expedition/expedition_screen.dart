import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/enums/monster_element.dart';
import '../../../domain/services/expedition_service.dart';
import '../../providers/expedition_provider.dart';
import '../../providers/monster_provider.dart';

class ExpeditionScreen extends ConsumerStatefulWidget {
  const ExpeditionScreen({super.key});

  @override
  ConsumerState<ExpeditionScreen> createState() => _ExpeditionScreenState();
}

class _ExpeditionScreenState extends ConsumerState<ExpeditionScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Refresh UI every second for countdown timers
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expeditionProvider);

    // Listen for success messages
    ref.listen<ExpeditionState>(expeditionProvider, (prev, next) {
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!.resolve(AppLocalizations.of(context)!)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(expeditionProvider.notifier).clearMessage();
      }
    });

    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.expedition),
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                l.expeditionSlots(state.activeCount, ExpeditionService.maxSlots),
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Active expeditions
          if (state.expeditions.where((e) => !e.isCollected).isNotEmpty) ...[
            Text(
              l.expeditionActive,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...state.expeditions
                .where((e) => !e.isCollected)
                .map((e) => _ExpeditionCard(expedition: e)),
            const SizedBox(height: 16),
          ],

          // Start new expedition
          if (state.canStartNew) ...[
            Text(
              l.expeditionNew,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...ExpeditionService.options.map((opt) => _StartOption(option: opt)),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                l.expeditionAllUsed(ExpeditionService.maxSlots, ExpeditionService.maxSlots),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Expedition card (active/completed)
// =============================================================================

class _ExpeditionCard extends ConsumerWidget {
  const _ExpeditionCard({required this.expedition});
  final dynamic expedition; // ExpeditionModel

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exp = expedition;
    final isComplete = exp.isComplete as bool;
    final remaining = exp.remainingTime as Duration;
    final progress = exp.progress as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete
              ? Colors.green.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isComplete ? Icons.check_circle : Icons.explore,
                color: isComplete ? Colors.green : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exp.durationLabel as String,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              if (isComplete)
                GestureDetector(
                  onTap: () => ref.read(expeditionProvider.notifier).collectReward(exp.id as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.expeditionCollect,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              else
                Text(
                  _formatDuration(remaining, AppLocalizations.of(context)!),
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceVariant,
              color: isComplete ? Colors.green : Colors.blue,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          // Monster names
          Wrap(
            spacing: 6,
            children: (exp.monsterNames as List<String>).map((name) =>
              Chip(
                label: Text(name, style: const TextStyle(fontSize: 10)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d, AppLocalizations l) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return l.timerHMS(h, m, s);
    if (m > 0) return l.timerMS(m, s);
    return l.timerS(s);
  }
}

// =============================================================================
// Start option (duration selection + monster picker)
// =============================================================================

class _StartOption extends ConsumerStatefulWidget {
  const _StartOption({required this.option});
  final ExpeditionOption option;

  @override
  ConsumerState<_StartOption> createState() => _StartOptionState();
}

class _StartOptionState extends ConsumerState<_StartOption> {
  final Set<String> _selectedIds = {};
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.explore, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.expeditionOptionLabel(widget.option.hours),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Expanded monster picker
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            _buildMonsterPicker(),
            // Start button
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedIds.isNotEmpty
                      ? () async {
                          final ok = await ref.read(expeditionProvider.notifier).startExpedition(
                            durationSeconds: widget.option.durationSeconds,
                            monsterIds: _selectedIds.toList(),
                          );
                          if (ok) {
                            setState(() {
                              _selectedIds.clear();
                              _expanded = false;
                            });
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.surfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.expeditionDepart(_selectedIds.length),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonsterPicker() {
    final roster = ref.watch(monsterListProvider);
    final expedState = ref.watch(expeditionProvider);
    final onExpedition = expedState.expeditions
        .where((e) => !e.isCollected)
        .expand((e) => e.monsterIds)
        .toSet();

    // Available: not in team, not on expedition
    final available = roster.where((m) => !m.isInTeam && !onExpedition.contains(m.id)).toList();

    if (available.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          AppLocalizations.of(context)!.expeditionNoMonster,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: available.length,
        itemBuilder: (context, index) {
          final m = available[index];
          final selected = _selectedIds.contains(m.id);
          final element = MonsterElement.fromName(m.element) ?? MonsterElement.fire;
          final atMax = _selectedIds.length >= ExpeditionService.maxMonstersPerSlot;

          return GestureDetector(
            onTap: () {
              setState(() {
                if (selected) {
                  _selectedIds.remove(m.id);
                } else if (!atMax) {
                  _selectedIds.add(m.id);
                }
              });
            },
            child: Container(
              width: 72,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.blue.withValues(alpha: 0.15)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? Colors.blue : AppColors.border,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: element.color.withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: Text(element.emoji, style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m.name,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Lv.${m.level}',
                    style: TextStyle(fontSize: 8, color: AppColors.textTertiary),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle, color: Colors.blue, size: 14),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
