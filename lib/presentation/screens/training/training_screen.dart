import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gameapp/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/services/training_service.dart';
import 'package:gameapp/presentation/providers/monster_provider.dart';
import '../../providers/training_provider.dart';

class TrainingScreen extends ConsumerStatefulWidget {
  const TrainingScreen({super.key});

  @override
  ConsumerState<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends ConsumerState<TrainingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    ref.read(trainingProvider.notifier).load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(trainingProvider);

    // Show snackbar for messages
    ref.listen<TrainingState>(trainingProvider, (prev, next) {
      if (next.message != null && next.message != prev?.message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message!), duration: const Duration(seconds: 2)),
        );
        ref.read(trainingProvider.notifier).clearMessage();
      }
    });

    // Build slot cards (always show 3 slots)
    final activeSlots = state.slots.where((s) => !s.isCollected).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.trainingTitle),
        backgroundColor: AppColors.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fitness_center, color: Colors.orange, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.trainingTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.trainingDesc,
                          style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${activeSlots.length}/${TrainingService.maxSlots}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Slot cards
            Expanded(
              child: ListView.builder(
                itemCount: TrainingService.maxSlots,
                itemBuilder: (_, i) {
                  if (i < activeSlots.length) {
                    return _ActiveSlotCard(slot: activeSlots[i]);
                  }
                  return _EmptySlotCard(slotIndex: i);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Active Slot Card
// =============================================================================

class _ActiveSlotCard extends ConsumerWidget {
  const _ActiveSlotCard({required this.slot});
  final TrainingSlot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final isComplete = slot.isComplete;
    final remaining = slot.remainingTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isComplete
              ? Colors.green.withValues(alpha: 0.5)
              : AppColors.primary.withValues(alpha: 0.3),
          width: isComplete ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monster name + level
          Row(
            children: [
              Icon(
                Icons.fitness_center,
                color: isComplete ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${slot.monsterName} (Lv.${slot.monsterLevel})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                TrainingService.durationLabel(slot.durationSeconds),
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: slot.progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? Colors.green : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Status + buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isComplete
                    ? l.trainingComplete
                    : '${_formatDuration(remaining)} ${l.trainingRemaining}',
                style: TextStyle(
                  fontSize: 12,
                  color: isComplete ? Colors.green : AppColors.textSecondary,
                  fontWeight: isComplete ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                '+${slot.xpReward} XP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isComplete ? Colors.green : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Action buttons
          Row(
            children: [
              if (isComplete)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(trainingProvider.notifier).collectTraining(slot.id),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: Text(l.trainingCollect),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                )
              else
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(trainingProvider.notifier).cancelTraining(slot.id),
                    icon: const Icon(Icons.cancel, size: 16),
                    label: Text(l.trainingCancel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

// =============================================================================
// Empty Slot Card
// =============================================================================

class _EmptySlotCard extends ConsumerWidget {
  const _EmptySlotCard({required this.slotIndex});
  final int slotIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final canStart = ref.watch(trainingProvider.select((s) => s.canStartNew));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: canStart ? () => _showMonsterPicker(context, ref) : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: canStart ? AppColors.primary : AppColors.disabled,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              l.trainingEmpty,
              style: TextStyle(
                fontSize: 14,
                color: canStart ? AppColors.primary : AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonsterPicker(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final monsters = ref.read(monsterListProvider);
    final trainingIds = ref.read(trainingProvider).trainingMonsterIds;

    // Filter: not in training, not max level
    final available = monsters
        .where((m) => !trainingIds.contains(m.id) && m.level < 100)
        .toList()
      ..sort((a, b) => b.level.compareTo(a.level));

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          builder: (_, scrollCtrl) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l.trainingSelectMonster,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: available.isEmpty
                      ? Center(
                          child: Text(
                            l.trainingNoMonsters,
                            style: TextStyle(color: AppColors.textTertiary),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollCtrl,
                          itemCount: available.length,
                          itemBuilder: (_, i) {
                            final m = available[i];
                            return _MonsterTile(
                              monster: m,
                              onTap: () {
                                Navigator.pop(ctx);
                                _showDurationPicker(context, ref, m);
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDurationPicker(
      BuildContext context, WidgetRef ref, dynamic monster) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(l.trainingDuration, style: const TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: TrainingService.durationOptions.map((dur) {
              final xp = TrainingService.calculateXp(
                durationSeconds: dur,
                monsterLevel: monster.level,
              );
              return ListTile(
                leading: Icon(Icons.timer, color: AppColors.primary),
                title: Text(
                  TrainingService.durationLabel(dur),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '+$xp XP',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(trainingProvider.notifier).startTraining(
                        monster: monster,
                        durationSeconds: dur,
                      );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Monster Tile for picker
// =============================================================================

class _MonsterTile extends StatelessWidget {
  const _MonsterTile({required this.monster, required this.onTap});
  final dynamic monster;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        child: Text(
          monster.name.substring(0, 1),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
      title: Text(
        monster.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        'Lv.${monster.level}  ★${monster.rarity}',
        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }
}
