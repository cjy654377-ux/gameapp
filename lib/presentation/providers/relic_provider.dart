import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:gameapp/data/datasources/local_storage.dart';
import 'package:gameapp/data/models/relic_model.dart';
import 'package:gameapp/data/static/relic_database.dart';

// =============================================================================
// RelicNotifier
// =============================================================================

class RelicNotifier extends StateNotifier<List<RelicModel>> {
  RelicNotifier() : super(const []);

  final LocalStorage _storage = LocalStorage.instance;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  Future<void> loadRelics() async {
    state = _storage.getAllRelics();
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<void> addRelic(RelicModel relic) async {
    await _storage.saveRelic(relic);
    state = [...state, relic];
  }

  Future<void> removeRelic(String id) async {
    await _storage.deleteRelic(id);
    state = state.where((r) => r.id != id).toList();
  }

  Future<void> updateRelic(RelicModel relic) async {
    final idx = state.indexWhere((r) => r.id == relic.id);
    if (idx < 0) return;
    final updated = [...state];
    updated[idx] = relic;
    await _storage.saveRelic(relic);
    state = updated;
  }

  // ---------------------------------------------------------------------------
  // Equip / Unequip
  // ---------------------------------------------------------------------------

  /// Equips [relicId] to [monsterId].
  /// If the relic is already equipped to another monster, unequips first.
  /// If the monster already has a relic of the same type, swaps.
  Future<void> equipRelic(String relicId, String monsterId) async {
    final relic = state.firstWhere((r) => r.id == relicId);

    // Unequip any existing relic of the same type from the monster.
    final sameTypeEquipped = state.where(
      (r) => r.equippedMonsterId == monsterId && r.type == relic.type && r.id != relicId,
    );
    for (final existing in sameTypeEquipped) {
      final unequipped = existing.copyWith(clearEquip: true);
      await _storage.saveRelic(unequipped);
    }

    // Equip the relic.
    final equipped = relic.copyWith(equippedMonsterId: monsterId);
    await _storage.saveRelic(equipped);

    // Reload state.
    state = _storage.getAllRelics();
  }

  /// Unequips a relic.
  Future<void> unequipRelic(String relicId) async {
    final idx = state.indexWhere((r) => r.id == relicId);
    if (idx < 0) return;

    final relic = state[idx];
    final unequipped = relic.copyWith(clearEquip: true);
    await _storage.saveRelic(unequipped);

    final updated = [...state];
    updated[idx] = unequipped;
    state = updated;
  }

  /// Unequips all relics from a specific monster.
  Future<void> unequipAllFromMonster(String monsterId) async {
    final equipped = state.where((r) => r.equippedMonsterId == monsterId);
    for (final relic in equipped) {
      final unequipped = relic.copyWith(clearEquip: true);
      await _storage.saveRelic(unequipped);
    }
    state = _storage.getAllRelics();
  }

  // ---------------------------------------------------------------------------
  // Random relic generation (for drops)
  // ---------------------------------------------------------------------------

  /// Generates a random relic with the given max rarity.
  Future<RelicModel> generateRandomRelic({int maxRarity = 3}) async {
    final random = math.Random();

    // Roll rarity (weighted: lower rarities more common).
    final rarityRoll = random.nextDouble();
    int rarity;
    if (maxRarity >= 5 && rarityRoll < 0.02) {
      rarity = 5;
    } else if (maxRarity >= 4 && rarityRoll < 0.08) {
      rarity = 4;
    } else if (maxRarity >= 3 && rarityRoll < 0.25) {
      rarity = 3;
    } else if (maxRarity >= 2 && rarityRoll < 0.55) {
      rarity = 2;
    } else {
      rarity = 1;
    }

    final candidates = RelicDatabase.byRarity(rarity);
    if (candidates.isEmpty) {
      // Fallback to rarity 1.
      final fallback = RelicDatabase.byRarity(1);
      final template = fallback[random.nextInt(fallback.length)];
      return _createFromTemplate(template);
    }

    final template = candidates[random.nextInt(candidates.length)];
    return _createFromTemplate(template);
  }

  RelicModel _createFromTemplate(RelicTemplate template) {
    return RelicModel(
      id: const Uuid().v4(),
      templateId: template.id,
      name: template.name,
      type: template.type,
      rarity: template.rarity,
      statType: template.statType,
      statValue: template.statValue,
      acquiredAt: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Query helpers
  // ---------------------------------------------------------------------------

  /// Returns relics equipped to a specific monster.
  List<RelicModel> relicsForMonster(String monsterId) {
    return state.where((r) => r.equippedMonsterId == monsterId).toList();
  }

  /// Returns total stat bonuses from all relics equipped to a monster.
  ({double atk, double def, double hp, double spd}) relicBonuses(
      String monsterId) {
    double atkBonus = 0, defBonus = 0, hpBonus = 0, spdBonus = 0;
    for (final relic in state) {
      if (relic.equippedMonsterId != monsterId) continue;
      switch (relic.statType) {
        case 'atk':
          atkBonus += relic.statValue;
        case 'def':
          defBonus += relic.statValue;
        case 'hp':
          hpBonus += relic.statValue;
        case 'spd':
          spdBonus += relic.statValue;
      }
    }
    return (atk: atkBonus, def: defBonus, hp: hpBonus, spd: spdBonus);
  }
}

// =============================================================================
// Provider
// =============================================================================

final relicProvider =
    StateNotifierProvider<RelicNotifier, List<RelicModel>>(
  (ref) => RelicNotifier(),
);
