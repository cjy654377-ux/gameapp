import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/l10n/app_localizations.dart';
import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/core/utils/format_utils.dart';
import 'package:gameapp/data/models/relic_model.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';
import 'package:gameapp/presentation/providers/monster_provider.dart';
import 'package:gameapp/presentation/providers/relic_provider.dart';

// =============================================================================
// RelicScreen — inventory and equip management
// =============================================================================

class RelicScreen extends ConsumerStatefulWidget {
  const RelicScreen({super.key});

  @override
  ConsumerState<RelicScreen> createState() => _RelicScreenState();
}

class _RelicScreenState extends ConsumerState<RelicScreen> {
  String _filter = 'all'; // 'all', 'weapon', 'armor', 'accessory', 'equipped'

  @override
  Widget build(BuildContext context) {
    final relics = ref.watch(relicProvider);
    final monsters = ref.watch(monsterListProvider);

    // Build monster ID → name map once (avoids O(n) lookup per relic).
    final monsterNameMap = {for (final m in monsters) m.id: m.name};

    List<RelicModel> filtered;
    switch (_filter) {
      case 'weapon':
        filtered = relics.where((r) => r.type == 'weapon').toList();
      case 'armor':
        filtered = relics.where((r) => r.type == 'armor').toList();
      case 'accessory':
        filtered = relics.where((r) => r.type == 'accessory').toList();
      case 'equipped':
        filtered = relics.where((r) => r.isEquipped).toList();
      default:
        filtered = relics.toList();
    }

    // Sort by rarity desc, then name.
    filtered.sort((a, b) {
      final cmp = b.rarity.compareTo(a.rarity);
      return cmp != 0 ? cmp : a.name.compareTo(b.name);
    });

    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.relicCount(relics.length)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _FilterChip(label: l.relicAll, value: 'all', selected: _filter, onTap: _setFilter),
                _FilterChip(label: l.relicWeapon, value: 'weapon', selected: _filter, onTap: _setFilter),
                _FilterChip(label: l.relicArmor, value: 'armor', selected: _filter, onTap: _setFilter),
                _FilterChip(label: l.relicAccessory, value: 'accessory', selected: _filter, onTap: _setFilter),
                _FilterChip(label: l.relicEquipped, value: 'equipped', selected: _filter, onTap: _setFilter),
              ],
            ),
          ),

          // Relic list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 48, color: Colors.grey[700]),
                        const SizedBox(height: 12),
                        Text(
                          l.noRelic,
                          style: TextStyle(color: Colors.grey[500], fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.getRelicFromBattle,
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    cacheExtent: 800,
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final relic = filtered[i];

                      return _RelicCard(
                        relic: relic,
                        equippedMonsterName: relic.equippedMonsterId != null
                            ? monsterNameMap[relic.equippedMonsterId]
                            : null,
                        onTap: () => _showRelicDetail(relic),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _setFilter(String value) {
    setState(() => _filter = value);
  }

  void _showRelicDetail(RelicModel relic) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _RelicDetailSheet(relic: relic),
    );
  }
}

// =============================================================================
// Filter Chip
// =============================================================================

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String value;
  final String selected;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.amber.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.amber.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? Colors.amber : Colors.grey[400],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Relic Card
// =============================================================================

class _RelicCard extends StatelessWidget {
  const _RelicCard({
    required this.relic,
    this.equippedMonsterName,
    required this.onTap,
  });
  final RelicModel relic;
  final String? equippedMonsterName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _rarityColor(relic.rarity).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _rarityColor(relic.rarity).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _rarityColor(relic.rarity).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _typeIcon(relic.type),
                color: _rarityColor(relic.rarity),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        relic.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _rarityColor(relic.rarity),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l.relicStarRarity(relic.rarity),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${_statLabel(l, relic.statType)} +${relic.enhancedStatValue.toInt()}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                      ),
                      if (relic.enhanceLevel > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+${relic.enhanceLevel}',
                            style: const TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Equipped badge
            if (equippedMonsterName != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  equippedMonsterName!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.greenAccent,
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
// Relic Detail Sheet
// =============================================================================

class _RelicDetailSheet extends ConsumerWidget {
  const _RelicDetailSheet({required this.relic});
  final RelicModel relic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final monsters = ref.watch(monsterListProvider);
    final relics = ref.watch(relicProvider);

    // Build monster map once for O(1) lookups.
    final monsterMap = {for (final m in monsters) m.id: m};
    final equippedMonster = relic.equippedMonsterId != null
        ? monsterMap[relic.equippedMonsterId]
        : null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                _typeIcon(relic.type),
                color: _rarityColor(relic.rarity),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      relic.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _rarityColor(relic.rarity),
                      ),
                    ),
                    Text(
                      '${_typeName(l, relic.type)} / ${l.relicStarRarity(relic.rarity)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stat bonus + enhance info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_statLabel(l, relic.statType)} +${relic.enhancedStatValue.toInt()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    if (relic.enhanceLevel > 0)
                      Text(
                        ' (+${relic.enhanceLevel})',
                        style: TextStyle(fontSize: 14, color: Colors.amber[200]),
                      ),
                  ],
                ),
                if (relic.canEnhance) ...[
                  const SizedBox(height: 8),
                  _EnhanceButton(relic: relic),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Current equip status
          if (equippedMonster != null) ...[
            Text(
              l.relicEquippedTo(equippedMonster.name),
              style: const TextStyle(fontSize: 14, color: Colors.greenAccent),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(relicProvider.notifier).unequipRelic(relic.id);
                  Navigator.of(context).pop();
                },
                child: Text(l.unequip),
              ),
            ),
          ] else ...[
            Text(
              l.selectMonsterToEquip,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: monsters.length,
                itemBuilder: (ctx, i) {
                  final m = monsters[i];
                  // Check if monster already has a relic of this type.
                  final hasType = relics.any(
                    (r) =>
                        r.equippedMonsterId == m.id &&
                        r.type == relic.type,
                  );
                  return GestureDetector(
                    onTap: () {
                      ref
                          .read(relicProvider.notifier)
                          .equipRelic(relic.id, m.id);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hasType
                              ? Colors.orange.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pets,
                            color: _rarityColor(m.rarity),
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.name,
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Lv.${m.level}',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[500]),
                          ),
                          if (hasType)
                            Text(
                              l.replace,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange[300],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Delete button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                ref.read(relicProvider.notifier).removeRelic(relic.id);
                Navigator.of(context).pop();
              },
              child: Text(
                l.relicDisassemble,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Helpers
// =============================================================================

Color _rarityColor(int rarity) {
  switch (rarity) {
    case 1:
      return Colors.grey;
    case 2:
      return Colors.green;
    case 3:
      return Colors.blue;
    case 4:
      return Colors.purple;
    case 5:
      return Colors.amber;
    default:
      return Colors.white;
  }
}

IconData _typeIcon(String type) {
  switch (type) {
    case 'weapon':
      return Icons.gavel;
    case 'armor':
      return Icons.shield;
    case 'accessory':
      return Icons.diamond;
    default:
      return Icons.inventory;
  }
}

String _typeName(AppLocalizations l, String type) {
  switch (type) {
    case 'weapon':
      return l.relicWeapon;
    case 'armor':
      return l.relicArmor;
    case 'accessory':
      return l.relicAccessory;
    default:
      return type;
  }
}

String _statLabel(AppLocalizations l, String stat) {
  switch (stat) {
    case 'atk':
      return l.statAttack;
    case 'def':
      return l.statDefense;
    case 'hp':
      return l.statHp;
    case 'spd':
      return l.statSpeed;
    default:
      return stat;
  }
}

// =============================================================================
// Enhance Button
// =============================================================================

class _EnhanceButton extends ConsumerWidget {
  const _EnhanceButton({required this.relic});
  final RelicModel relic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final gold = ref.watch(currencyProvider.select((c) => c.gold));
    final cost = RelicNotifier.enhanceCost(relic);
    final canAfford = gold >= cost;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canAfford
            ? () async {
                final success = await ref.read(currencyProvider.notifier).spendGold(cost);
                if (!success) return;
                await ref.read(relicProvider.notifier).enhanceRelic(relic.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            : null,
        icon: const Icon(Icons.upgrade, size: 18),
        label: Text(
          '${l.relicEnhance} +${relic.enhanceLevel + 1} (${FormatUtils.formatNumber(cost)} ${l.gold})',
          style: const TextStyle(fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.disabled.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}
