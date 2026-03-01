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
    final idx = state.indexWhere((r) => r.id == relicId);
    if (idx < 0) return;
    final relic = state[idx];

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
  // Enhancement
  // ---------------------------------------------------------------------------

  /// Gold cost for next enhancement level.
  static int enhanceCost(RelicModel relic) {
    return 500 * (relic.enhanceLevel + 1) * relic.rarity;
  }

  /// Enhance a relic by one level, increasing stat value.
  Future<bool> enhanceRelic(String relicId) async {
    final idx = state.indexWhere((r) => r.id == relicId);
    if (idx < 0) return false;
    final relic = state[idx];
    if (!relic.canEnhance) return false;

    final enhanced = relic.copyWith(enhanceLevel: relic.enhanceLevel + 1);
    await _storage.saveRelic(enhanced);
    final updated = [...state];
    updated[idx] = enhanced;
    state = updated;
    return true;
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
  // Relic fusion
  // ---------------------------------------------------------------------------

  /// Fuse two relics of the same rarity into a random higher-rarity relic.
  /// Returns the new relic if successful, null otherwise.
  Future<RelicModel?> fuseRelics(String relicId1, String relicId2) async {
    final r1 = state.cast<RelicModel?>().firstWhere(
          (r) => r!.id == relicId1, orElse: () => null);
    final r2 = state.cast<RelicModel?>().firstWhere(
          (r) => r!.id == relicId2, orElse: () => null);
    if (r1 == null || r2 == null) return null;
    if (r1.rarity != r2.rarity) return null;
    if (r1.rarity >= 5) return null; // can't fuse 5-star
    if (r1.isEquipped || r2.isEquipped) return null;

    // Remove both relics.
    await removeRelic(relicId1);
    await removeRelic(relicId2);

    // Generate new relic at next rarity.
    final targetRarity = r1.rarity + 1;
    final candidates = RelicDatabase.byRarity(targetRarity);
    if (candidates.isEmpty) return null;
    final random = math.Random();
    final template = candidates[random.nextInt(candidates.length)];
    final newRelic = _createFromTemplate(template);
    await addRelic(newRelic);
    return newRelic;
  }

  // ---------------------------------------------------------------------------
  // Bulk dismantle
  // ---------------------------------------------------------------------------

  /// Dismantles all unequipped relics at or below [maxRarity].
  /// Returns the total gold earned.
  int dismantleByRarity(int maxRarity) {
    final targets = state.where(
      (r) => !r.isEquipped && r.rarity <= maxRarity,
    ).toList();
    if (targets.isEmpty) return 0;

    int totalGold = 0;
    for (final relic in targets) {
      // Gold value: 100 * rarity * (1 + enhanceLevel)
      totalGold += 100 * relic.rarity * (1 + relic.enhanceLevel);
      _storage.deleteRelic(relic.id);
    }
    state = state.where((r) => !targets.any((t) => t.id == r.id)).toList();
    return totalGold;
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
      final val = relic.enhancedStatValue;
      switch (relic.statType) {
        case 'atk':
          atkBonus += val;
        case 'def':
          defBonus += val;
        case 'hp':
          hpBonus += val;
        case 'spd':
          spdBonus += val;
      }
    }

    // Add set bonuses
    final setBonuses = activeSetBonuses(monsterId);
    for (final set in setBonuses) {
      for (final bonus in set.bonuses) {
        switch (bonus.statType) {
          case 'atk': atkBonus += bonus.statValue;
          case 'def': defBonus += bonus.statValue;
          case 'hp': hpBonus += bonus.statValue;
          case 'spd': spdBonus += bonus.statValue;
        }
      }
    }

    return (atk: atkBonus, def: defBonus, hp: hpBonus, spd: spdBonus);
  }

  /// Returns active set bonuses for a specific monster.
  List<RelicSetBonus> activeSetBonuses(String monsterId) {
    final equipped = relicsForMonster(monsterId);
    if (equipped.isEmpty) return [];

    final active = <RelicSetBonus>[];
    for (final set in RelicSetDatabase.all) {
      if (set.requiredType == 'mixed') {
        // Destroyer: needs 1 weapon + 1 accessory, both >= requiredMinRarity
        final hasWeapon = equipped.any((r) => r.type == 'weapon' && r.rarity >= set.requiredMinRarity);
        final hasAccessory = equipped.any((r) => r.type == 'accessory' && r.rarity >= set.requiredMinRarity);
        if (hasWeapon && hasAccessory) active.add(set);
      } else {
        // Count matching type with sufficient rarity
        final matching = equipped.where(
          (r) => r.type == set.requiredType && r.rarity >= set.requiredMinRarity,
        ).length;
        if (matching >= set.requiredPieces) active.add(set);
      }
    }
    return active;
  }
}

// =============================================================================
// Provider
// =============================================================================

final relicProvider =
    StateNotifierProvider<RelicNotifier, List<RelicModel>>(
  (ref) => RelicNotifier(),
);
