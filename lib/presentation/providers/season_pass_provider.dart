import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../data/static/season_pass_database.dart';
import 'currency_provider.dart';

// =============================================================================
// State
// =============================================================================

class SeasonPassState {
  final int level;
  final int currentXp;
  final int claimedFreeBitmask;     // bits 0-29 for levels 1-30
  final int claimedPremiumBitmask;
  final bool isPremium;
  final DateTime seasonStartDate;
  final bool isLoaded;

  const SeasonPassState({
    this.level = 0,
    this.currentXp = 0,
    this.claimedFreeBitmask = 0,
    this.claimedPremiumBitmask = 0,
    this.isPremium = false,
    required this.seasonStartDate,
    this.isLoaded = false,
  });

  SeasonPassState copyWith({
    int? level,
    int? currentXp,
    int? claimedFreeBitmask,
    int? claimedPremiumBitmask,
    bool? isPremium,
    DateTime? seasonStartDate,
    bool? isLoaded,
  }) {
    return SeasonPassState(
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      claimedFreeBitmask: claimedFreeBitmask ?? this.claimedFreeBitmask,
      claimedPremiumBitmask: claimedPremiumBitmask ?? this.claimedPremiumBitmask,
      isPremium: isPremium ?? this.isPremium,
      seasonStartDate: seasonStartDate ?? this.seasonStartDate,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  /// XP needed to reach next level from current level.
  int get xpToNextLevel => level >= SeasonPassDatabase.maxLevel
      ? 0
      : SeasonPassDatabase.xpForLevel(level + 1);

  /// Progress ratio to next level (0.0 ~ 1.0).
  double get xpProgress => xpToNextLevel > 0
      ? (currentXp / xpToNextLevel).clamp(0.0, 1.0)
      : 1.0;

  /// Days remaining in the current season.
  int get daysRemaining {
    final endDate = seasonStartDate.add(
      const Duration(days: SeasonPassDatabase.seasonDurationDays),
    );
    final remaining = endDate.difference(DateTime.now()).inDays;
    return remaining.clamp(0, SeasonPassDatabase.seasonDurationDays);
  }

  /// Whether a free reward at [rewardLevel] has been claimed.
  bool isFreeClaimed(int rewardLevel) =>
      (claimedFreeBitmask >> (rewardLevel - 1)) & 1 == 1;

  /// Whether a premium reward at [rewardLevel] has been claimed.
  bool isPremiumClaimed(int rewardLevel) =>
      (claimedPremiumBitmask >> (rewardLevel - 1)) & 1 == 1;

  /// Whether a free reward at [rewardLevel] is available to claim.
  bool canClaimFree(int rewardLevel) =>
      level >= rewardLevel && !isFreeClaimed(rewardLevel);

  /// Whether a premium reward at [rewardLevel] is available to claim.
  bool canClaimPremium(int rewardLevel) =>
      isPremium && level >= rewardLevel && !isPremiumClaimed(rewardLevel);
}

// =============================================================================
// Notifier
// =============================================================================

class SeasonPassNotifier extends StateNotifier<SeasonPassState> {
  final Ref _ref;

  SeasonPassNotifier(this._ref)
      : super(SeasonPassState(seasonStartDate: DateTime.now()));

  Box get _box => Hive.box('settings');

  /// Load state from Hive.
  void load() {
    final startDateStr = _box.get('seasonPassStartDate') as String?;
    final startDate = startDateStr != null
        ? DateTime.tryParse(startDateStr) ?? DateTime.now()
        : DateTime.now();

    // Check if season expired → reset
    final daysSinceStart = DateTime.now().difference(startDate).inDays;
    if (daysSinceStart >= SeasonPassDatabase.seasonDurationDays || startDateStr == null) {
      // New season
      final newStart = DateTime.now();
      _box.put('seasonPassStartDate', newStart.toIso8601String());
      _box.put('seasonPassLevel', 0);
      _box.put('seasonPassXp', 0);
      _box.put('seasonPassClaimedFree', 0);
      _box.put('seasonPassClaimedPremium', 0);
      // Keep isPremium across seasons
      state = SeasonPassState(
        seasonStartDate: newStart,
        isPremium: _box.get('seasonPassIsPremium', defaultValue: false) as bool,
        isLoaded: true,
      );
      return;
    }

    state = SeasonPassState(
      level: _box.get('seasonPassLevel', defaultValue: 0) as int,
      currentXp: _box.get('seasonPassXp', defaultValue: 0) as int,
      claimedFreeBitmask: _box.get('seasonPassClaimedFree', defaultValue: 0) as int,
      claimedPremiumBitmask: _box.get('seasonPassClaimedPremium', defaultValue: 0) as int,
      isPremium: _box.get('seasonPassIsPremium', defaultValue: false) as bool,
      seasonStartDate: startDate,
      isLoaded: true,
    );
  }

  /// Add XP to the season pass. Auto-levels up.
  void addXp(int amount) {
    if (amount <= 0) return;

    int xp = state.currentXp + amount;
    int level = state.level;

    while (level < SeasonPassDatabase.maxLevel) {
      final needed = SeasonPassDatabase.xpForLevel(level + 1);
      if (xp >= needed) {
        xp -= needed;
        level++;
      } else {
        break;
      }
    }

    // Cap XP at max level
    if (level >= SeasonPassDatabase.maxLevel) {
      xp = 0;
    }

    state = state.copyWith(level: level, currentXp: xp);
    _save();
  }

  /// Claim a free reward at [rewardLevel].
  void claimFreeReward(int rewardLevel) {
    if (!state.canClaimFree(rewardLevel)) return;

    final reward = SeasonPassDatabase.getReward(rewardLevel);
    if (reward == null) return;

    _grantReward(reward.freeType, reward.freeAmount);

    final newMask = state.claimedFreeBitmask | (1 << (rewardLevel - 1));
    state = state.copyWith(claimedFreeBitmask: newMask);
    _save();
  }

  /// Claim a premium reward at [rewardLevel].
  void claimPremiumReward(int rewardLevel) {
    if (!state.canClaimPremium(rewardLevel)) return;

    final reward = SeasonPassDatabase.getReward(rewardLevel);
    if (reward == null) return;

    _grantReward(reward.premiumType, reward.premiumAmount);

    final newMask = state.claimedPremiumBitmask | (1 << (rewardLevel - 1));
    state = state.copyWith(claimedPremiumBitmask: newMask);
    _save();
  }

  /// Toggle premium status (simulated purchase).
  void togglePremium() {
    state = state.copyWith(isPremium: !state.isPremium);
    _box.put('seasonPassIsPremium', state.isPremium);
  }

  void _grantReward(String type, int amount) {
    final currency = _ref.read(currencyProvider.notifier);
    switch (type) {
      case 'gold':
        currency.addGold(amount);
      case 'diamond':
        currency.addDiamond(amount);
      case 'expPotion':
        currency.addExpPotion(amount);
      case 'shard':
        currency.addShard(amount);
      case 'gachaTicket':
        currency.addGachaTicket(amount);
    }
  }

  void _save() {
    _box.put('seasonPassLevel', state.level);
    _box.put('seasonPassXp', state.currentXp);
    _box.put('seasonPassClaimedFree', state.claimedFreeBitmask);
    _box.put('seasonPassClaimedPremium', state.claimedPremiumBitmask);
  }
}

// =============================================================================
// Provider
// =============================================================================

final seasonPassProvider =
    StateNotifierProvider<SeasonPassNotifier, SeasonPassState>(
  (ref) => SeasonPassNotifier(ref),
);
