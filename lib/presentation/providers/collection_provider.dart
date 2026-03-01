import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/l10n/app_localizations.dart';
import '../../data/models/monster_model.dart';
import '../../data/static/monster_database.dart';
import '../../domain/services/audio_service.dart';
import 'currency_provider.dart';
import 'monster_provider.dart';
import 'player_provider.dart';

// =============================================================================
// Sort / Filter state
// =============================================================================

enum CollectionSort { defaultOrder, name, rarityDesc, levelDesc, powerDesc }

class CollectionFilter {
  final int? rarity;
  final String? element;
  final bool showOnlyOwned;
  final bool showOnlyFavorites;
  final CollectionSort sort;
  final String searchQuery;

  const CollectionFilter({
    this.rarity,
    this.element,
    this.showOnlyOwned = false,
    this.showOnlyFavorites = false,
    this.sort = CollectionSort.defaultOrder,
    this.searchQuery = '',
  });

  CollectionFilter copyWith({
    int? rarity,
    String? element,
    bool? showOnlyOwned,
    bool? showOnlyFavorites,
    CollectionSort? sort,
    bool clearRarity = false,
    bool clearElement = false,
    String? searchQuery,
  }) {
    return CollectionFilter(
      rarity: clearRarity ? null : (rarity ?? this.rarity),
      element: clearElement ? null : (element ?? this.element),
      showOnlyOwned: showOnlyOwned ?? this.showOnlyOwned,
      showOnlyFavorites: showOnlyFavorites ?? this.showOnlyFavorites,
      sort: sort ?? this.sort,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasFilter =>
      rarity != null ||
      element != null ||
      showOnlyOwned ||
      showOnlyFavorites ||
      sort != CollectionSort.defaultOrder ||
      searchQuery.isNotEmpty;
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

  void toggleShowOnlyFavorites() {
    state = state.copyWith(showOnlyFavorites: !state.showOnlyFavorites);
  }

  void setSort(CollectionSort sort) {
    state = state.copyWith(sort: sort);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.trim().toLowerCase());
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

  // Apply search filter
  if (filter.searchQuery.isNotEmpty) {
    templates = templates.where((t) =>
        t.name.toLowerCase().contains(filter.searchQuery));
  }

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
  if (filter.showOnlyFavorites) {
    entries = entries.where((e) =>
        e.ownedInstances.any((m) => m.isFavorite));
  }

  final result = entries.toList();

  // Apply sort
  switch (filter.sort) {
    case CollectionSort.defaultOrder:
      break; // keep MonsterDatabase order
    case CollectionSort.name:
      result.sort((a, b) => a.template.name.compareTo(b.template.name));
    case CollectionSort.rarityDesc:
      result.sort((a, b) => b.template.rarity.compareTo(a.template.rarity));
    case CollectionSort.levelDesc:
      result.sort((a, b) {
        final aLv = a.best?.level ?? 0;
        final bLv = b.best?.level ?? 0;
        return bLv.compareTo(aLv);
      });
    case CollectionSort.powerDesc:
      result.sort((a, b) {
        final aPow = a.best != null
            ? a.best!.finalAtk +
                a.best!.finalDef +
                a.best!.finalHp +
                a.best!.finalSpd
            : 0.0;
        final bPow = b.best != null
            ? b.best!.finalAtk +
                b.best!.finalDef +
                b.best!.finalHp +
                b.best!.finalSpd
            : 0.0;
        return bPow.compareTo(aPow);
      });
  }

  return result;
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

// =============================================================================
// Collection milestone rewards
// =============================================================================

class CollectionMilestone {
  final int index; // 0-based, used for bitmask
  final int requiredCount;
  final int gold;
  final int diamond;
  final int gachaTickets;

  const CollectionMilestone({
    required this.index,
    required this.requiredCount,
    required this.gold,
    required this.diamond,
    required this.gachaTickets,
  });

  String localizedLabel(AppLocalizations l) {
    if (requiredCount >= MonsterDatabase.all.length) {
      return l.milestoneComplete;
    }
    return l.milestoneCollect(requiredCount);
  }
}

const collectionMilestones = [
  CollectionMilestone(
    index: 0, requiredCount: 5, gold: 200, diamond: 20, gachaTickets: 1,
  ),
  CollectionMilestone(
    index: 1, requiredCount: 10, gold: 500, diamond: 50, gachaTickets: 2,
  ),
  CollectionMilestone(
    index: 2, requiredCount: 15, gold: 1000, diamond: 100, gachaTickets: 3,
  ),
  CollectionMilestone(
    index: 3, requiredCount: 20, gold: 2000, diamond: 300, gachaTickets: 5,
  ),
];

/// Provides milestone status: reached, claimed, claimable.
final collectionMilestoneProvider =
    Provider<List<({CollectionMilestone milestone, bool reached, bool claimed})>>(
        (ref) {
  final stats = ref.watch(collectionStatsProvider);
  final player = ref.watch(playerProvider).player;
  final claimedBitmask = player?.collectionRewardsClaimed ?? 0;

  return collectionMilestones.map((m) {
    final reached = stats.owned >= m.requiredCount;
    final claimed = (claimedBitmask & (1 << m.index)) != 0;
    return (milestone: m, reached: reached, claimed: claimed);
  }).toList();
});

/// Claims a collection milestone reward.
Future<void> claimCollectionMilestone(WidgetRef ref, int milestoneIndex) async {
  if (milestoneIndex < 0 || milestoneIndex >= collectionMilestones.length) return;
  final milestone = collectionMilestones[milestoneIndex];
  final player = ref.read(playerProvider).player;
  if (player == null) return;

  // Check not already claimed.
  if ((player.collectionRewardsClaimed & (1 << milestone.index)) != 0) return;

  // Grant rewards (single Hive write via addReward).
  final currency = ref.read(currencyProvider.notifier);
  await currency.addReward(
    gold: milestone.gold,
    diamond: milestone.diamond,
    gachaTicket: milestone.gachaTickets,
  );

  // Mark as claimed.
  final newBitmask = player.collectionRewardsClaimed | (1 << milestone.index);
  await ref.read(playerProvider.notifier).updateCollectionRewards(newBitmask);

  AudioService.instance.playRewardCollect();
}
