import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/monster_model.dart';
import '../../data/static/monster_database.dart';
import 'monster_provider.dart';

// =============================================================================
// Filter state
// =============================================================================

class CollectionFilter {
  final int? rarity;
  final String? element;
  final bool showOnlyOwned;

  const CollectionFilter({
    this.rarity,
    this.element,
    this.showOnlyOwned = false,
  });

  CollectionFilter copyWith({
    int? rarity,
    String? element,
    bool? showOnlyOwned,
    bool clearRarity = false,
    bool clearElement = false,
  }) {
    return CollectionFilter(
      rarity: clearRarity ? null : (rarity ?? this.rarity),
      element: clearElement ? null : (element ?? this.element),
      showOnlyOwned: showOnlyOwned ?? this.showOnlyOwned,
    );
  }

  bool get hasFilter => rarity != null || element != null || showOnlyOwned;
}

class CollectionFilterNotifier extends StateNotifier<CollectionFilter> {
  CollectionFilterNotifier() : super(const CollectionFilter());

  void setRarity(int? rarity) {
    if (state.rarity == rarity) {
      state = state.copyWith(clearRarity: true);
    } else {
      state = state.copyWith(rarity: rarity);
    }
  }

  void setElement(String? element) {
    if (state.element == element) {
      state = state.copyWith(clearElement: true);
    } else {
      state = state.copyWith(element: element);
    }
  }

  void toggleShowOnlyOwned() {
    state = state.copyWith(showOnlyOwned: !state.showOnlyOwned);
  }

  void clearAll() {
    state = const CollectionFilter();
  }
}

final collectionFilterProvider =
    StateNotifierProvider<CollectionFilterNotifier, CollectionFilter>(
  (ref) => CollectionFilterNotifier(),
);

// =============================================================================
// Filtered collection data
// =============================================================================

/// Entry for one template in the collection grid.
class CollectionEntry {
  final MonsterTemplate template;
  final List<MonsterModel> ownedInstances;

  const CollectionEntry({
    required this.template,
    required this.ownedInstances,
  });

  bool get isOwned => ownedInstances.isNotEmpty;
  int get count => ownedInstances.length;

  /// Best (highest level) owned instance, if any.
  MonsterModel? get best {
    if (ownedInstances.isEmpty) return null;
    return ownedInstances.reduce(
        (a, b) => a.level > b.level ? a : b);
  }
}

/// Provides the filtered collection entries combining templates with owned monsters.
final collectionEntriesProvider = Provider<List<CollectionEntry>>((ref) {
  final filter = ref.watch(collectionFilterProvider);
  final ownedMonsters = ref.watch(monsterListProvider);

  // Group owned monsters by templateId.
  final ownedByTemplate = <String, List<MonsterModel>>{};
  for (final m in ownedMonsters) {
    ownedByTemplate.putIfAbsent(m.templateId, () => []).add(m);
  }

  Iterable<MonsterTemplate> templates = MonsterDatabase.all;

  // Apply filters lazily (single pass).
  if (filter.rarity != null) {
    templates = templates.where((t) => t.rarity == filter.rarity);
  }
  if (filter.element != null) {
    templates = templates.where((t) => t.element == filter.element);
  }

  Iterable<CollectionEntry> entries = templates.map((t) {
    return CollectionEntry(
      template: t,
      ownedInstances: ownedByTemplate[t.id] ?? const [],
    );
  });

  if (filter.showOnlyOwned) {
    entries = entries.where((e) => e.isOwned);
  }

  return entries.toList();
});

/// Collection progress stats.
final collectionStatsProvider = Provider<({int total, int owned})>((ref) {
  final ownedMonsters = ref.watch(monsterListProvider);
  final ownedTemplateIds = ownedMonsters.map((m) => m.templateId).toSet();
  return (
    total: MonsterDatabase.all.length,
    owned: ownedTemplateIds.length,
  );
});
