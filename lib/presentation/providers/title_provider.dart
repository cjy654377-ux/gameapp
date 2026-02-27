import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../data/static/title_database.dart';
import 'currency_provider.dart';
import 'player_provider.dart';
import 'collection_provider.dart';

// =============================================================================
// State
// =============================================================================

class TitleState {
  final Set<String> unlockedTitleIds;
  final String? equippedTitleId;
  final Set<int> claimedMilestones; // indices of claimed milestones

  const TitleState({
    this.unlockedTitleIds = const {},
    this.equippedTitleId,
    this.claimedMilestones = const {},
  });

  /// Total achievement points from unlocked titles.
  int get achievementPoints {
    int pts = 0;
    for (final t in TitleDatabase.titles) {
      if (unlockedTitleIds.contains(t.id)) pts += t.points;
    }
    return pts;
  }

  TitleState copyWith({
    Set<String>? unlockedTitleIds,
    String? equippedTitleId,
    bool clearEquipped = false,
    Set<int>? claimedMilestones,
  }) =>
      TitleState(
        unlockedTitleIds: unlockedTitleIds ?? this.unlockedTitleIds,
        equippedTitleId:
            clearEquipped ? null : (equippedTitleId ?? this.equippedTitleId),
        claimedMilestones: claimedMilestones ?? this.claimedMilestones,
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

  static const _milestoneKey = 'claimed_milestones';

  void load() {
    final box = Hive.box('settings');
    final raw = box.get(_key) as String?;
    Set<String> unlocked = {};
    if (raw != null && raw.isNotEmpty) {
      unlocked = (jsonDecode(raw) as List).cast<String>().toSet();
    }

    final milestoneRaw = box.get(_milestoneKey) as String?;
    Set<int> claimed = {};
    if (milestoneRaw != null && milestoneRaw.isNotEmpty) {
      claimed = (jsonDecode(milestoneRaw) as List).cast<int>().toSet();
    }

    final player = _ref.read(playerProvider).player;
    state = TitleState(
      unlockedTitleIds: unlocked,
      equippedTitleId: player?.currentTitle,
      claimedMilestones: claimed,
    );
  }

  Future<void> _save() async {
    final box = Hive.box('settings');
    await box.put(_key, jsonEncode(state.unlockedTitleIds.toList()));
    await box.put(_milestoneKey, jsonEncode(state.claimedMilestones.toList()));
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

  /// Claim a milestone reward by index.
  Future<bool> claimMilestone(int index) async {
    if (state.claimedMilestones.contains(index)) return false;
    if (index < 0 || index >= TitleDatabase.milestones.length) return false;

    final milestone = TitleDatabase.milestones[index];
    if (state.achievementPoints < milestone.requiredPoints) return false;

    final currency = _ref.read(currencyProvider.notifier);
    switch (milestone.rewardType) {
      case 'gold':
        await currency.addGold(milestone.rewardAmount);
      case 'diamond':
        await currency.addDiamond(milestone.rewardAmount);
      case 'shard':
        await currency.addShard(milestone.rewardAmount);
      case 'gachaTicket':
        await currency.addGachaTicket(milestone.rewardAmount);
    }

    state = state.copyWith(
      claimedMilestones: {...state.claimedMilestones, index},
    );
    await _save();
    return true;
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
