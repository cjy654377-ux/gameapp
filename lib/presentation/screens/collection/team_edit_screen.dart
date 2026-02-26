import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/game_config.dart';
import '../../../core/enums/monster_element.dart';
import '../../../core/enums/monster_rarity.dart';
import '../../../data/models/monster_model.dart';
import '../../providers/monster_provider.dart';
import '../../providers/player_provider.dart';

/// Full-screen team editor opened from CollectionScreen or battle.
class TeamEditScreen extends ConsumerStatefulWidget {
  const TeamEditScreen({super.key});

  @override
  ConsumerState<TeamEditScreen> createState() => _TeamEditScreenState();
}

class _TeamEditScreenState extends ConsumerState<TeamEditScreen> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    final team = ref.read(teamMonstersProvider);
    _selectedIds = team.map((m) => m.id).toList();
  }

  bool get _isDirty {
    final current = ref.read(teamMonstersProvider).map((m) => m.id).toSet();
    return !_setEquals(current, _selectedIds.toSet());
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  double get _totalPower {
    final monsters = ref.read(monsterListProvider);
    final selectedSet = _selectedIds.toSet();
    double total = 0;
    for (final m in monsters) {
      if (selectedSet.contains(m.id)) {
        total += m.finalAtk + m.finalDef + m.finalHp + m.finalSpd;
      }
    }
    return total;
  }

  void _toggle(MonsterModel monster) {
    setState(() {
      if (_selectedIds.contains(monster.id)) {
        _selectedIds.remove(monster.id);
      } else if (_selectedIds.length < GameConfig.maxTeamSize) {
        _selectedIds.add(monster.id);
      }
    });
  }

  Future<void> _save() async {
    await ref.read(monsterListProvider.notifier).setTeam(_selectedIds);
    await ref.read(playerProvider.notifier).updateTeamIds(_selectedIds);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final roster = ref.watch(monsterListProvider);
    final selectedSet = _selectedIds.toSet();

    // Sort: in-team first, then by rarity desc, then level desc.
    final sorted = List<MonsterModel>.from(roster)
      ..sort((a, b) {
        final aSelected = selectedSet.contains(a.id) ? 0 : 1;
        final bSelected = selectedSet.contains(b.id) ? 0 : 1;
        if (aSelected != bSelected) return aSelected.compareTo(bSelected);
        if (a.rarity != b.rarity) return b.rarity.compareTo(a.rarity);
        return b.level.compareTo(a.level);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(l.teamEdit),
        actions: [
          TextButton(
            onPressed: _isDirty ? _save : null,
            child: Text(
              l.save,
              style: TextStyle(
                color: _isDirty ? AppColors.primary : AppColors.disabled,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Team slots
          _buildTeamSlots(roster, selectedSet),
          const Divider(height: 1),
          // Power
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              l.totalPower(_totalPower.round().toString()),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          // Roster grid
          Expanded(
            child: roster.isEmpty
                ? Center(
                    child: Text(
                      '${l.noMonsterOwned}\n${l.getMonsterFromGacha}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final m = sorted[index];
                      final selected = selectedSet.contains(m.id);
                      return _RosterCard(
                        monster: m,
                        selected: selected,
                        onTap: () => _toggle(m),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSlots(
      List<MonsterModel> roster, Set<String> selectedSet) {
    // Build ID→Monster map for O(1) lookups.
    final rosterMap = {for (final m in roster) m.id: m};
    final selectedMonsters = <MonsterModel?>[];
    for (final id in _selectedIds) {
      selectedMonsters.add(rosterMap[id]);
    }
    // Fill remaining slots.
    while (selectedMonsters.length < GameConfig.maxTeamSize) {
      selectedMonsters.add(null);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(GameConfig.maxTeamSize, (i) {
          final m = selectedMonsters[i];
          return _TeamSlot(
            monster: m,
            onRemove: m != null ? () => _toggle(m) : null,
          );
        }),
      ),
    );
  }
}

// =============================================================================
// Team slot widget
// =============================================================================

class _TeamSlot extends StatelessWidget {
  const _TeamSlot({
    required this.monster,
    this.onRemove,
  });

  final MonsterModel? monster;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    if (monster == null) {
      return Container(
        width: 64,
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add,
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    final rarity = MonsterRarity.fromRarity(monster!.rarity);
    final element =
        MonsterElement.fromName(monster!.element) ?? MonsterElement.fire;

    return GestureDetector(
      onTap: onRemove,
      child: Container(
        width: 64,
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: rarity.color, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(element.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 2),
            Text(
              monster!.name,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Lv.${monster!.level}',
              style: TextStyle(fontSize: 8, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Roster card (selectable)
// =============================================================================

class _RosterCard extends StatelessWidget {
  const _RosterCard({
    required this.monster,
    required this.selected,
    required this.onTap,
  });

  final MonsterModel monster;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rarity = MonsterRarity.fromRarity(monster.rarity);
    final element =
        MonsterElement.fromName(monster.element) ?? MonsterElement.fire;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(element.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 2),
                  Text(
                    monster.name,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Lv.${monster.level}',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  Text(
                    rarity.starsDisplay,
                    style: TextStyle(fontSize: 8, color: rarity.color),
                  ),
                ],
              ),
            ),
            if (selected)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
