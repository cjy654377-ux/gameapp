import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/static/monster_database.dart';
import 'monster_provider.dart';
import 'currency_provider.dart';

// =============================================================================
// Challenge Definition
// =============================================================================

class CollectionChallenge {
  final String id;
  final String titleKo;
  final String titleEn;
  final String descKo;
  final String descEn;
  final int goldReward;
  final int diamondReward;
  /// Function that returns (current, required) based on owned templateIds.
  final (int current, int required) Function(Set<String> ownedIds) progressFn;

  const CollectionChallenge({
    required this.id,
    required this.titleKo,
    required this.titleEn,
    required this.descKo,
    required this.descEn,
    required this.goldReward,
    required this.diamondReward,
    required this.progressFn,
  });
}

// =============================================================================
// Challenge Database
// =============================================================================

class ChallengeDatabase {
  ChallengeDatabase._();

  static Set<String> _templatesByElement(String element) =>
      MonsterDatabase.all.where((t) => t.element == element).map((t) => t.id).toSet();

  static Set<String> _templatesByRarity(int rarity) =>
      MonsterDatabase.all.where((t) => t.rarity == rarity).map((t) => t.id).toSet();

  static (int, int) _elementProgress(Set<String> owned, String element) {
    final targets = _templatesByElement(element);
    return (owned.intersection(targets).length, targets.length);
  }

  static (int, int) _rarityProgress(Set<String> owned, int rarity) {
    final targets = _templatesByRarity(rarity);
    return (owned.intersection(targets).length, targets.length);
  }

  static final List<CollectionChallenge> all = [
    CollectionChallenge(
      id: 'fire_master',
      titleKo: '화염의 지배자', titleEn: 'Fire Master',
      descKo: '불 속성 몬스터 모두 수집', descEn: 'Collect all fire monsters',
      goldReward: 500, diamondReward: 10,
      progressFn: (owned) => _elementProgress(owned, 'fire'),
    ),
    CollectionChallenge(
      id: 'water_master',
      titleKo: '물의 지배자', titleEn: 'Water Master',
      descKo: '물 속성 몬스터 모두 수집', descEn: 'Collect all water monsters',
      goldReward: 500, diamondReward: 10,
      progressFn: (owned) => _elementProgress(owned, 'water'),
    ),
    CollectionChallenge(
      id: 'electric_master',
      titleKo: '번개의 지배자', titleEn: 'Electric Master',
      descKo: '전기 속성 몬스터 모두 수집', descEn: 'Collect all electric monsters',
      goldReward: 500, diamondReward: 10,
      progressFn: (owned) => _elementProgress(owned, 'electric'),
    ),
    CollectionChallenge(
      id: 'stone_master',
      titleKo: '대지의 지배자', titleEn: 'Stone Master',
      descKo: '바위 속성 몬스터 모두 수집', descEn: 'Collect all stone monsters',
      goldReward: 500, diamondReward: 10,
      progressFn: (owned) => _elementProgress(owned, 'stone'),
    ),
    CollectionChallenge(
      id: 'grass_master',
      titleKo: '자연의 지배자', titleEn: 'Grass Master',
      descKo: '풀 속성 몬스터 모두 수집', descEn: 'Collect all grass monsters',
      goldReward: 500, diamondReward: 10,
      progressFn: (owned) => _elementProgress(owned, 'grass'),
    ),
    CollectionChallenge(
      id: 'dark_lord',
      titleKo: '어둠의 군주', titleEn: 'Dark Lord',
      descKo: '암흑 속성 몬스터 모두 수집', descEn: 'Collect all dark monsters',
      goldReward: 500, diamondReward: 10,
      progressFn: (owned) => _elementProgress(owned, 'dark'),
    ),
    CollectionChallenge(
      id: 'light_guardian',
      titleKo: '빛의 수호자', titleEn: 'Light Guardian',
      descKo: '빛 속성 몬스터 모두 수집', descEn: 'Collect all light monsters',
      goldReward: 500, diamondReward: 10,
      progressFn: (owned) => _elementProgress(owned, 'light'),
    ),
    CollectionChallenge(
      id: 'common_collector',
      titleKo: '초보 수집가', titleEn: 'Starter Collector',
      descKo: '1성 몬스터 모두 수집', descEn: 'Collect all 1-star monsters',
      goldReward: 300, diamondReward: 0,
      progressFn: (owned) => _rarityProgress(owned, 1),
    ),
    CollectionChallenge(
      id: 'rare_collector',
      titleKo: '희귀 수집가', titleEn: 'Rare Collector',
      descKo: '3성 몬스터 모두 수집', descEn: 'Collect all 3-star monsters',
      goldReward: 500, diamondReward: 20,
      progressFn: (owned) => _rarityProgress(owned, 3),
    ),
    CollectionChallenge(
      id: 'legendary_collector',
      titleKo: '전설 수집가', titleEn: 'Legendary Collector',
      descKo: '5성 몬스터 모두 수집', descEn: 'Collect all 5-star monsters',
      goldReward: 1000, diamondReward: 50,
      progressFn: (owned) => _rarityProgress(owned, 5),
    ),
    CollectionChallenge(
      id: 'starter_pack',
      titleKo: '시작의 발걸음', titleEn: 'First Steps',
      descKo: '서로 다른 몬스터 5종 수집', descEn: 'Collect 5 unique monsters',
      goldReward: 200, diamondReward: 0,
      progressFn: (owned) => (owned.length.clamp(0, 5), 5),
    ),
    CollectionChallenge(
      id: 'veteran',
      titleKo: '베테랑 수집가', titleEn: 'Veteran Collector',
      descKo: '서로 다른 몬스터 15종 수집', descEn: 'Collect 15 unique monsters',
      goldReward: 1000, diamondReward: 30,
      progressFn: (owned) => (owned.length.clamp(0, 15), 15),
    ),
  ];
}

// =============================================================================
// State
// =============================================================================

class CollectionChallengeState {
  final Set<String> claimedIds;

  const CollectionChallengeState({this.claimedIds = const {}});

  CollectionChallengeState copyWith({Set<String>? claimedIds}) =>
      CollectionChallengeState(claimedIds: claimedIds ?? this.claimedIds);
}

// =============================================================================
// Notifier
// =============================================================================

class CollectionChallengeNotifier extends StateNotifier<CollectionChallengeState> {
  CollectionChallengeNotifier(this.ref) : super(const CollectionChallengeState()) {
    _load();
  }

  final Ref ref;

  void _load() {
    final box = Hive.box('settings');
    final raw = box.get('collectionChallenges');
    if (raw != null) {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final claimed = (data['claimed'] as List<dynamic>?)?.cast<String>().toSet() ?? {};
      state = CollectionChallengeState(claimedIds: claimed);
    }
  }

  Future<void> _save() async {
    final box = Hive.box('settings');
    await box.put('collectionChallenges', jsonEncode({
      'claimed': state.claimedIds.toList(),
    }));
  }

  Future<void> claimChallenge(String challengeId) async {
    if (state.claimedIds.contains(challengeId)) return;

    final challenge = ChallengeDatabase.all.firstWhere((c) => c.id == challengeId);
    final ownedIds = ref.read(monsterListProvider).map((m) => m.templateId).toSet();
    final (current, required) = challenge.progressFn(ownedIds);
    if (current < required) return;

    // Grant rewards
    final currency = ref.read(currencyProvider.notifier);
    if (challenge.goldReward > 0) await currency.addGold(challenge.goldReward);
    if (challenge.diamondReward > 0) await currency.addDiamond(challenge.diamondReward);

    state = state.copyWith(claimedIds: {...state.claimedIds, challengeId});
    await _save();
  }
}

// =============================================================================
// Provider
// =============================================================================

final collectionChallengeProvider =
    StateNotifierProvider<CollectionChallengeNotifier, CollectionChallengeState>(
  (ref) => CollectionChallengeNotifier(ref),
);
