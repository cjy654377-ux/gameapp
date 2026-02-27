import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/enums/monster_element.dart';
import '../../../core/enums/monster_rarity.dart';
import '../../../data/models/monster_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/monster_provider.dart';

// =============================================================================
// MonsterCompareScreen
// =============================================================================

class MonsterCompareScreen extends ConsumerStatefulWidget {
  const MonsterCompareScreen({super.key});

  @override
  ConsumerState<MonsterCompareScreen> createState() =>
      _MonsterCompareScreenState();
}

class _MonsterCompareScreenState extends ConsumerState<MonsterCompareScreen> {
  MonsterModel? _monsterA;
  MonsterModel? _monsterB;

  void _selectMonster(bool isSlotA) {
    final roster = ref.read(monsterListProvider);
    final other = isSlotA ? _monsterB : _monsterA;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _MonsterPicker(
        roster: roster,
        excludeId: other?.id,
        onSelect: (m) {
          setState(() {
            if (isSlotA) {
              _monsterA = m;
            } else {
              _monsterB = m;
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.compareTitle),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          // Slot selectors
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _SlotCard(
                    monster: _monsterA,
                    label: 'A',
                    onTap: () => _selectMonster(true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.compare_arrows, color: AppColors.textTertiary),
                ),
                Expanded(
                  child: _SlotCard(
                    monster: _monsterB,
                    label: 'B',
                    onTap: () => _selectMonster(false),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Comparison bars
          Expanded(
            child: _monsterA != null && _monsterB != null
                ? _ComparisonBody(a: _monsterA!, b: _monsterB!)
                : Center(
                    child: Text(
                      l.compareSelectTwo,
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _SlotCard
// =============================================================================

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.monster,
    required this.label,
    required this.onTap,
  });

  final MonsterModel? monster;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = monster;
    final element = m != null
        ? MonsterElement.fromName(m.element) ?? MonsterElement.fire
        : null;
    final rarity = m != null ? MonsterRarity.fromRarity(m.rarity) : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: rarity?.color ?? AppColors.border,
            width: m != null ? 1.5 : 1,
          ),
        ),
        child: m == null
            ? Column(
                children: [
                  Icon(Icons.add_circle_outline,
                      size: 32, color: AppColors.textTertiary),
                  const SizedBox(height: 4),
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textTertiary)),
                ],
              )
            : Column(
                children: [
                  Text(element!.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text(
                    m.displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Lv.${m.level} ${rarity!.starsDisplay}',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),
      ),
    );
  }
}

// =============================================================================
// _ComparisonBody
// =============================================================================

class _ComparisonBody extends StatelessWidget {
  const _ComparisonBody({required this.a, required this.b});

  final MonsterModel a;
  final MonsterModel b;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final stats = [
      _StatPair(l.statAttack, a.finalAtk, b.finalAtk),
      _StatPair(l.statDefense, a.finalDef, b.finalDef),
      _StatPair(l.statHp, a.finalHp, b.finalHp),
      _StatPair(l.statSpeed, a.finalSpd, b.finalSpd),
    ];

    final totalA = a.finalAtk + a.finalDef + a.finalHp + a.finalSpd;
    final totalB = b.finalAtk + b.finalDef + b.finalHp + b.finalSpd;

    // Element matchup
    final elemA = MonsterElement.fromName(a.element) ?? MonsterElement.fire;
    final elemB = MonsterElement.fromName(b.element) ?? MonsterElement.fire;
    final matchup = elemA.getAdvantage(elemB);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Total power comparison
        _PowerCompareRow(
          labelA: a.displayName,
          labelB: b.displayName,
          valueA: totalA,
          valueB: totalB,
        ),
        const SizedBox(height: 16),

        // Element matchup
        _ElementMatchupRow(
          elemA: elemA,
          elemB: elemB,
          matchup: matchup,
        ),
        const SizedBox(height: 16),

        // Stat bars
        ...stats.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StatCompareBar(stat: s),
            )),

        const SizedBox(height: 8),

        // Additional info
        _InfoRow(l.statLevel, 'Lv.${a.level}', 'Lv.${b.level}'),
        _InfoRow(
          l.evolutionTree,
          '${a.evolutionStage}${l.evoStageBase.substring(0, 1)}',
          '${b.evolutionStage}${l.evoStageBase.substring(0, 1)}',
        ),
        _InfoRow(l.affinity, 'Lv.${a.affinityLevel}', 'Lv.${b.affinityLevel}'),
        if (a.skillName != null || b.skillName != null)
          _InfoRow(l.skill, a.skillName ?? '-', b.skillName ?? '-'),
      ],
    );
  }
}

// =============================================================================
// Helper data class
// =============================================================================

class _StatPair {
  final String label;
  final double valueA;
  final double valueB;
  const _StatPair(this.label, this.valueA, this.valueB);
}

// =============================================================================
// _PowerCompareRow
// =============================================================================

class _PowerCompareRow extends StatelessWidget {
  const _PowerCompareRow({
    required this.labelA,
    required this.labelB,
    required this.valueA,
    required this.valueB,
  });

  final String labelA, labelB;
  final double valueA, valueB;

  @override
  Widget build(BuildContext context) {
    final winner =
        valueA > valueB ? 'A' : (valueB > valueA ? 'B' : 'tie');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  labelA,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: winner == 'A' ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                Text(
                  valueA.round().toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: winner == 'A' ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Text('VS', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              Icon(
                winner == 'tie' ? Icons.drag_handle : Icons.arrow_forward,
                color: AppColors.textTertiary,
                size: 16,
              ),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  labelB,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: winner == 'B' ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                Text(
                  valueB.round().toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: winner == 'B' ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _ElementMatchupRow
// =============================================================================

class _ElementMatchupRow extends StatelessWidget {
  const _ElementMatchupRow({
    required this.elemA,
    required this.elemB,
    required this.matchup,
  });

  final MonsterElement elemA, elemB;
  final double matchup;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isAdvantage = matchup > 1.0;
    final isDisadvantage = matchup < 1.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isAdvantage
            ? Colors.green.withValues(alpha: 0.1)
            : isDisadvantage
                ? Colors.red.withValues(alpha: 0.1)
                : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAdvantage
              ? Colors.green.withValues(alpha: 0.3)
              : isDisadvantage
                  ? Colors.red.withValues(alpha: 0.3)
                  : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${elemA.emoji} ${elemA.name}',
              style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Text(
            '→ ${matchup}x',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isAdvantage
                  ? Colors.green
                  : isDisadvantage
                      ? Colors.red
                      : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Text('${elemB.emoji} ${elemB.name}',
              style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Text(
            isAdvantage
                ? l.superEffective
                : isDisadvantage
                    ? l.notEffective
                    : '-',
            style: TextStyle(
              fontSize: 11,
              color: isAdvantage ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _StatCompareBar
// =============================================================================

class _StatCompareBar extends StatelessWidget {
  const _StatCompareBar({required this.stat});

  final _StatPair stat;

  @override
  Widget build(BuildContext context) {
    final maxVal = [stat.valueA, stat.valueB]
        .reduce((a, b) => a > b ? a : b)
        .clamp(1.0, double.infinity);
    final ratioA = stat.valueA / maxVal;
    final ratioB = stat.valueB / maxVal;
    final aWins = stat.valueA > stat.valueB;
    final bWins = stat.valueB > stat.valueA;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(stat.label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(
          children: [
            // A bar (right-aligned, grows leftward visually)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    stat.valueA.round().toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: aWins ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerRight,
                        widthFactor: ratioA,
                        child: Container(
                          color: aWins
                              ? AppColors.primary
                              : AppColors.textTertiary.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // B bar (left-aligned, grows rightward)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.valueB.round().toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: bWins ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: ratioB,
                        child: Container(
                          color: bWins
                              ? AppColors.primary
                              : AppColors.textTertiary.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// _InfoRow
// =============================================================================

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.valueA, this.valueB);

  final String label;
  final String valueA, valueB;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              valueA,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valueB,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _MonsterPicker
// =============================================================================

class _MonsterPicker extends StatelessWidget {
  const _MonsterPicker({
    required this.roster,
    this.excludeId,
    required this.onSelect,
  });

  final List<MonsterModel> roster;
  final String? excludeId;
  final void Function(MonsterModel) onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final filtered = excludeId != null
        ? roster.where((m) => m.id != excludeId).toList()
        : roster;
    final sorted = List<MonsterModel>.from(filtered)
      ..sort((a, b) {
        if (a.rarity != b.rarity) return b.rarity.compareTo(a.rarity);
        return b.level.compareTo(a.level);
      });

    return SizedBox(
      height: 400,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l.compareSelectMonster,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.78,
              ),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final m = sorted[index];
                final element =
                    MonsterElement.fromName(m.element) ?? MonsterElement.fire;
                final rarity = MonsterRarity.fromRarity(m.rarity);
                return GestureDetector(
                  onTap: () => onSelect(m),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: rarity.color, width: 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(element.emoji,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 2),
                        Text(
                          m.displayName,
                          style: const TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Lv.${m.level}',
                          style: TextStyle(
                              fontSize: 8, color: AppColors.textTertiary),
                        ),
                        Text(
                          rarity.starsDisplay,
                          style: TextStyle(fontSize: 7, color: rarity.color),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
