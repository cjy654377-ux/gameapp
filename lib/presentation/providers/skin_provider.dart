import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../data/static/skin_database.dart';
import 'currency_provider.dart';
import 'monster_provider.dart';

// =============================================================================
// Skin State
// =============================================================================

/// Tracks which skins the player has unlocked.
class SkinState {
  final Set<String> unlockedSkinIds;

  const SkinState({this.unlockedSkinIds = const {}});

  bool isUnlocked(String skinId) => unlockedSkinIds.contains(skinId);

  SkinState copyWith({Set<String>? unlockedSkinIds}) {
    return SkinState(
      unlockedSkinIds: unlockedSkinIds ?? this.unlockedSkinIds,
    );
  }
}

// =============================================================================
// Skin Notifier
// =============================================================================

class SkinNotifier extends StateNotifier<SkinState> {
  SkinNotifier(this._ref) : super(const SkinState());

  final Ref _ref;
  static const String _boxName = 'settings';
  static const String _key = 'unlockedSkins';

  /// Load unlocked skins from Hive settings box.
  Future<void> load() async {
    final box = Hive.box(_boxName);
    final raw = box.get(_key);
    if (raw is List) {
      state = SkinState(
        unlockedSkinIds: Set<String>.from(raw.cast<String>()),
      );
    }
  }

  /// Persist unlocked skins to Hive.
  Future<void> _save() async {
    final box = Hive.box(_boxName);
    await box.put(_key, state.unlockedSkinIds.toList());
  }

  /// Unlock a skin by spending monster shards.
  /// Returns true on success, false if not enough shards.
  Future<bool> unlockSkin(String skinId) async {
    if (state.isUnlocked(skinId)) return true; // Already unlocked

    final skin = SkinDatabase.findById(skinId);
    if (skin == null) return false;

    final currencyNotifier = _ref.read(currencyProvider.notifier);
    final ok = await currencyNotifier.spendShard(skin.shardCost);
    if (!ok) return false;

    state = state.copyWith(
      unlockedSkinIds: {...state.unlockedSkinIds, skinId},
    );
    await _save();
    return true;
  }

  /// Equip a skin on a monster. The skin must be unlocked.
  Future<bool> equipSkin({
    required String monsterId,
    required String skinId,
  }) async {
    if (!state.isUnlocked(skinId)) return false;

    final monsterNotifier = _ref.read(monsterListProvider.notifier);
    final roster = _ref.read(monsterListProvider);
    final monster = roster.where((m) => m.id == monsterId).firstOrNull;
    if (monster == null) return false;

    // Verify skin is applicable
    final skin = SkinDatabase.findById(skinId);
    if (skin == null) return false;
    if (skin.targetTemplateId != null &&
        skin.targetTemplateId != monster.templateId) {
      return false;
    }
    if (skin.targetElement != null &&
        skin.targetElement != monster.element) {
      return false;
    }

    final updated = monster.copyWith(equippedSkinId: skinId);
    await monsterNotifier.updateMonster(updated);
    return true;
  }

  /// Unequip the skin from a monster.
  Future<void> unequipSkin(String monsterId) async {
    final monsterNotifier = _ref.read(monsterListProvider.notifier);
    final roster = _ref.read(monsterListProvider);
    final monster = roster.where((m) => m.id == monsterId).firstOrNull;
    if (monster == null) return;

    final updated = monster.copyWith(equippedSkinId: null);
    await monsterNotifier.updateMonster(updated);
  }
}

// =============================================================================
// Provider
// =============================================================================

final skinProvider = StateNotifierProvider<SkinNotifier, SkinState>(
  (ref) => SkinNotifier(ref),
);
