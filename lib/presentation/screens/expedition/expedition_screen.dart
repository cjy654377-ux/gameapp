import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/enums/monster_element.dart';
import '../../../core/utils/format_utils.dart';
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
    final l = AppLocalizations.of(context)!;

    final completedCount = state.expeditions
        .where((e) => e.isComplete && !e.isCollected)
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.expedition),
        backgroundColor: Colors.transparent,
        actions: [
          if (completedCount >= 2)
            TextButton.icon(
              onPressed: () => _collectAll(),
              icon: const Icon(Icons.done_all, size: 18),
              label: Text(l.expeditionCollectAll),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
            ),
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
                .map((e) => _ExpeditionCard(
                      expedition: e,
                      onCollect: () => _collectSingle(e.id),
                    )),
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

  Future<void> _collectSingle(String id) async {
    final reward = await ref.read(expeditionProvider.notifier).collectReward(id);
    if (reward != null && mounted) {
      _showRewardDialog(reward);
    }
  }

  Future<void> _collectAll() async {
    final reward = await ref.read(expeditionProvider.notifier).collectAll();
    if (reward != null && mounted) {
      _showRewardDialog(reward);
    }
  }

  void _showRewardDialog(ExpeditionReward reward) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => _RewardDialog(reward: reward, l: l),
    );
  }
}

// =============================================================================
// Reward dialog
// =============================================================================

class _RewardDialog extends StatelessWidget {
  const _RewardDialog({required this.reward, required this.l});
  final ExpeditionReward reward;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.amber.shade400, Colors.orange.shade600],
                ),
              ),
              child: const Icon(Icons.card_giftcard, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              l.expeditionRewardTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Reward rows
            if (reward.gold > 0)
              _RewardRow(
                icon: Icons.monetization_on,
                color: Colors.amber,
                text: l.expeditionRewardGold(FormatUtils.formatNumber(reward.gold)),
              ),
            if (reward.expPotions > 0)
              _RewardRow(
                icon: Icons.science,
                color: Colors.green,
                text: l.expeditionRewardExp(reward.expPotions),
              ),
            if (reward.shards > 0)
              _RewardRow(
                icon: Icons.diamond,
                color: Colors.purple,
                text: l.expeditionRewardShard(reward.shards),
              ),
            if (reward.diamonds > 0)
              _RewardRow(
                icon: Icons.diamond_outlined,
                color: Colors.cyan,
                text: l.expeditionRewardDiamond(reward.diamonds),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// =============================================================================
// Expedition card (active/completed)
// =============================================================================

class _ExpeditionCard extends StatelessWidget {
  const _ExpeditionCard({required this.expedition, required this.onCollect});
  final dynamic expedition; // ExpeditionModel
  final VoidCallback onCollect;

  @override
  Widget build(BuildContext context) {
    final exp = expedition;
    final isComplete = exp.isComplete as bool;
    final remaining = exp.remainingTime as Duration;
    final progress = exp.progress as double;
    final hours = (exp.durationSeconds as int) ~/ 3600;
    final tier = _ExpeditionTier.fromHours(hours);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete
              ? Colors.green.withValues(alpha: 0.5)
              : tier.color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with tier color
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (isComplete ? Colors.green : tier.color).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isComplete ? Icons.check_circle : tier.icon,
                  color: isComplete ? Colors.green : tier.color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _tierLabel(context, hours),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isComplete ? Colors.green : tier.color,
                    ),
                  ),
                ),
                if (isComplete)
                  GestureDetector(
                    onTap: onCollect,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.expeditionCollect,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surfaceVariant,
                    color: isComplete ? Colors.green : tier.color,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                // Monster names + level
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: (exp.monsterNames as List<String>).map((name) =>
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tier.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              name,
                              style: TextStyle(fontSize: 10, color: tier.color, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ).toList(),
                      ),
                    ),
                    Text(
                      'Lv.${exp.totalMonsterLevel}',
                      style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _tierLabel(BuildContext context, int hours) {
    final l = AppLocalizations.of(context)!;
    if (hours >= 8) return l.expeditionHour8;
    if (hours >= 4) return l.expeditionHour4;
    return l.expeditionHour1;
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
// Start option (duration selection + monster picker + reward preview)
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
    final l = AppLocalizations.of(context)!;
    final hours = widget.option.hours;
    final tier = _ExpeditionTier.fromHours(hours);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _expanded ? tier.color.withValues(alpha: 0.5) : AppColors.border,
        ),
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tier.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(tier.icon, color: tier.color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tierLabel(hours, l),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          l.expeditionOptionLabel(hours),
                          style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                        ),
                      ],
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

          // Expanded: reward preview + monster picker
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            _buildRewardPreview(l, tier),
            const Divider(height: 1, color: AppColors.border),
            _buildMonsterPicker(l),
            // Team level summary
            if (_selectedIds.isNotEmpty) _buildTeamSummary(l),
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
                    backgroundColor: tier.color,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.surfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    l.expeditionDepart(_selectedIds.length),
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

  String _tierLabel(int hours, AppLocalizations l) {
    if (hours >= 8) return l.expeditionHour8;
    if (hours >= 4) return l.expeditionHour4;
    return l.expeditionHour1;
  }

  Widget _buildRewardPreview(AppLocalizations l, _ExpeditionTier tier) {
    // Compute preview based on selected monster levels or default level 1
    final roster = ref.watch(monsterListProvider);
    final selectedMonsters = roster.where((m) => _selectedIds.contains(m.id)).toList();
    final totalLevel = selectedMonsters.isEmpty
        ? 1
        : selectedMonsters.fold<int>(0, (s, m) => s + m.level);

    final preview = ExpeditionService.previewReward(
      durationSeconds: widget.option.durationSeconds,
      totalMonsterLevel: totalLevel,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: tier.color.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.expeditionRewardPreview,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tier.color),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _PreviewChip(
                icon: Icons.monetization_on,
                color: Colors.amber,
                text: l.expeditionGoldRange(
                  FormatUtils.formatNumber(preview.goldMin),
                  FormatUtils.formatNumber(preview.goldMax),
                ),
              ),
              _PreviewChip(
                icon: Icons.science,
                color: Colors.green,
                text: preview.expMin == preview.expMax
                    ? '${preview.expMin}'
                    : l.expeditionExpRange(preview.expMin, preview.expMax),
              ),
              if (preview.shardChancePct > 0)
                _PreviewChip(
                  icon: Icons.diamond,
                  color: Colors.purple,
                  text: l.expeditionShardChance(preview.shardChancePct),
                ),
              if (preview.diamondChancePct > 0)
                _PreviewChip(
                  icon: Icons.diamond_outlined,
                  color: Colors.cyan,
                  text: l.expeditionDiamondChance(preview.diamondChancePct),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSummary(AppLocalizations l) {
    final roster = ref.watch(monsterListProvider);
    final selectedMonsters = roster.where((m) => _selectedIds.contains(m.id)).toList();
    final totalLevel = selectedMonsters.fold<int>(0, (s, m) => s + m.level);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(
            l.expeditionTeamLevel(totalLevel),
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMonsterPicker(AppLocalizations l) {
    final roster = ref.watch(monsterListProvider);
    final expedState = ref.watch(expeditionProvider);
    final onExpedition = expedState.expeditions
        .where((e) => !e.isCollected)
        .expand((e) => e.monsterIds)
        .toSet();

    final available = roster.where((m) => !m.isInTeam && !onExpedition.contains(m.id)).toList();

    if (available.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          l.expeditionNoMonster,
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
                    ? element.color.withValues(alpha: 0.15)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? element.color : AppColors.border,
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
                    Icon(Icons.check_circle, color: element.color, size: 14),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Preview chip
// =============================================================================

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Expedition tier (visual differentiation)
// =============================================================================

class _ExpeditionTier {
  final Color color;
  final IconData icon;

  const _ExpeditionTier({required this.color, required this.icon});

  static _ExpeditionTier fromHours(int hours) {
    if (hours >= 8) {
      return const _ExpeditionTier(color: Color(0xFFFF8A65), icon: Icons.rocket_launch);
    }
    if (hours >= 4) {
      return const _ExpeditionTier(color: Color(0xFF7986CB), icon: Icons.sailing);
    }
    return const _ExpeditionTier(color: Color(0xFF4DB6AC), icon: Icons.directions_walk);
  }
}
