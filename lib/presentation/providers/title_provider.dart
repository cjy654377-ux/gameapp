import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'player_provider.dart';
import 'collection_provider.dart';

// =============================================================================
// State
// =============================================================================

class TitleState {
  final Set<String> unlockedTitleIds;
  final String? equippedTitleId;

  const TitleState({
    this.unlockedTitleIds = const {},
    this.equippedTitleId,
  });

  TitleState copyWith({
    Set<String>? unlockedTitleIds,
    String? equippedTitleId,
    bool clearEquipped = false,
  }) =>
      TitleState(
        unlockedTitleIds: unlockedTitleIds ?? this.unlockedTitleIds,
        equippedTitleId:
            clearEquipped ? null : (equippedTitleId ?? this.equippedTitleId),
      );
}

// =============================================================================
// Provider
// =============================================================================

final titleProvider =
    StateNotifierProvider<TitleNotifier, TitleState>((ref) {
  return TitleNotifier(ref);
});

class TitleNotifier extends StateNotifier<TitleState> {
  TitleNotifier(this._ref) : super(const TitleState());
  final Ref _ref;

  static const _key = 'unlocked_titles';

  void load() {
    final box = Hive.box('settings');
    final raw = box.get(_key) as String?;
    Set<String> unlocked = {};
    if (raw != null && raw.isNotEmpty) {
      unlocked = (jsonDecode(raw) as List).cast<String>().toSet();
    }

    final player = _ref.read(playerProvider).player;
    state = TitleState(
      unlockedTitleIds: unlocked,
      equippedTitleId: player?.currentTitle,
    );
  }

  Future<void> _save() async {
    final box = Hive.box('settings');
    await box.put(_key, jsonEncode(state.unlockedTitleIds.toList()));
  }

  /// Check all conditions and unlock any new titles.
  Future<void> checkUnlocks() async {
    final player = _ref.read(playerProvider).player;
    if (player == null) return;

    final collection = _ref.read(collectionStatsProvider);
    final newUnlocks = <String>{...state.unlockedTitleIds};

    // Battle milestones
    if (player.totalBattleCount >= 100) newUnlocks.add('warrior');
    if (player.totalBattleCount >= 500) newUnlocks.add('champion');
    if (player.totalBattleCount >= 1000) newUnlocks.add('legend');

    // Collection milestones
    if (collection.owned >= 10) newUnlocks.add('collector');
    if (collection.owned >= collection.total && collection.total > 0) {
      newUnlocks.add('professor');
    }

    // Gacha milestones
    if (player.totalGachaPullCount >= 50) newUnlocks.add('lucky');
    if (player.totalGachaPullCount >= 200) newUnlocks.add('whale');

    // Dungeon milestones
    if (player.maxDungeonFloor >= 20) newUnlocks.add('explorer');
    if (player.maxDungeonFloor >= 50) newUnlocks.add('deepdiver');

    // Prestige milestones
    if (player.prestigeLevel >= 1) newUnlocks.add('reborn');
    if (player.prestigeLevel >= 5) newUnlocks.add('immortal');

    // Check-in milestones
    if (player.checkInStreak >= 7) newUnlocks.add('dedicated');

    if (newUnlocks.length != state.unlockedTitleIds.length) {
      state = state.copyWith(unlockedTitleIds: newUnlocks);
      await _save();
    }
  }

  Future<void> equipTitle(String? titleId) async {
    if (titleId != null && !state.unlockedTitleIds.contains(titleId)) return;

    final playerNotifier = _ref.read(playerProvider.notifier);
    if (titleId == null) {
      await playerNotifier.updatePlayer((p) => p.copyWith(clearTitle: true));
      state = state.copyWith(clearEquipped: true);
    } else {
      await playerNotifier.updatePlayer((p) => p.copyWith(currentTitle: titleId));
      state = state.copyWith(equippedTitleId: titleId);
    }
  }
}
