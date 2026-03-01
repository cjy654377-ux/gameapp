import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:gameapp/presentation/providers/currency_provider.dart';

// =============================================================================
// Lucky Box Reward
// =============================================================================

enum LuckyBoxRewardType {
  gold,
  diamond,
  expPotion,
  gachaTicket,
}

class LuckyBoxReward {
  final LuckyBoxRewardType type;
  final int amount;
  /// Actual probability (0.0–1.0) used for random selection.
  final double probability;

  const LuckyBoxReward({
    required this.type,
    required this.amount,
    required this.probability,
  });

  String get emoji {
    switch (type) {
      case LuckyBoxRewardType.gold:
        return '🪙';
      case LuckyBoxRewardType.diamond:
        return '💎';
      case LuckyBoxRewardType.expPotion:
        return '🧪';
      case LuckyBoxRewardType.gachaTicket:
        return '🎟️';
    }
  }
}

// =============================================================================
// Lucky Box State
// =============================================================================

class LuckyBoxState {
  /// Whether the player has already claimed today's lucky box.
  final bool claimedToday;
  /// The last claim date (YYYYMMDD).
  final int lastClaimDate;
  /// The reward from the current/last spin.
  final LuckyBoxReward? currentReward;
  /// Whether the spin animation is playing.
  final bool isSpinning;
  /// Consecutive daily claim streak.
  final int streak;

  const LuckyBoxState({
    this.claimedToday = false,
    this.lastClaimDate = 0,
    this.currentReward,
    this.isSpinning = false,
    this.streak = 0,
  });

  LuckyBoxState copyWith({
    bool? claimedToday,
    int? lastClaimDate,
    LuckyBoxReward? Function()? currentReward,
    bool? isSpinning,
    int? streak,
  }) {
    return LuckyBoxState(
      claimedToday: claimedToday ?? this.claimedToday,
      lastClaimDate: lastClaimDate ?? this.lastClaimDate,
      currentReward: currentReward != null ? currentReward() : this.currentReward,
      isSpinning: isSpinning ?? this.isSpinning,
      streak: streak ?? this.streak,
    );
  }
}

// =============================================================================
// Lucky Box Reward Table
// =============================================================================

class LuckyBoxDatabase {
  LuckyBoxDatabase._();

  static const List<LuckyBoxReward> rewards = [
    // 40% gold small
    LuckyBoxReward(type: LuckyBoxRewardType.gold, amount: 500, probability: 0.25),
    LuckyBoxReward(type: LuckyBoxRewardType.gold, amount: 1000, probability: 0.15),
    // 25% exp potion
    LuckyBoxReward(type: LuckyBoxRewardType.expPotion, amount: 3, probability: 0.15),
    LuckyBoxReward(type: LuckyBoxRewardType.expPotion, amount: 5, probability: 0.10),
    // 20% diamond
    LuckyBoxReward(type: LuckyBoxRewardType.diamond, amount: 10, probability: 0.12),
    LuckyBoxReward(type: LuckyBoxRewardType.diamond, amount: 30, probability: 0.08),
    // 10% gold large
    LuckyBoxReward(type: LuckyBoxRewardType.gold, amount: 3000, probability: 0.07),
    LuckyBoxReward(type: LuckyBoxRewardType.gold, amount: 5000, probability: 0.03),
    // 5% gacha ticket
    LuckyBoxReward(type: LuckyBoxRewardType.gachaTicket, amount: 1, probability: 0.04),
    LuckyBoxReward(type: LuckyBoxRewardType.gachaTicket, amount: 2, probability: 0.01),
  ];

  /// Streak bonus rewards (every 7 days).
  static LuckyBoxReward streakBonus(int streak) {
    if (streak >= 28) {
      return const LuckyBoxReward(
        type: LuckyBoxRewardType.gachaTicket, amount: 3, probability: 1.0,
      );
    } else if (streak >= 21) {
      return const LuckyBoxReward(
        type: LuckyBoxRewardType.diamond, amount: 100, probability: 1.0,
      );
    } else if (streak >= 14) {
      return const LuckyBoxReward(
        type: LuckyBoxRewardType.diamond, amount: 50, probability: 1.0,
      );
    } else if (streak >= 7) {
      return const LuckyBoxReward(
        type: LuckyBoxRewardType.expPotion, amount: 10, probability: 1.0,
      );
    }
    return const LuckyBoxReward(
      type: LuckyBoxRewardType.gold, amount: 500, probability: 1.0,
    );
  }

  static LuckyBoxReward roll() {
    final rng = math.Random();
    final total = rewards.fold<double>(0, (s, r) => s + r.probability);
    final roll = rng.nextDouble() * total;
    double cumulative = 0;
    for (final reward in rewards) {
      cumulative += reward.probability;
      if (roll < cumulative) return reward;
    }
    return rewards.last;
  }
}

// =============================================================================
// Lucky Box Notifier
// =============================================================================

class LuckyBoxNotifier extends StateNotifier<LuckyBoxState> {
  LuckyBoxNotifier(this.ref) : super(const LuckyBoxState()) {
    _load();
  }

  final Ref ref;
  static const _boxKey = 'luckyBox';

  void _load() {
    final box = Hive.box('settings');
    final lastDate = box.get('${_boxKey}_lastDate', defaultValue: 0) as int;
    final streak = box.get('${_boxKey}_streak', defaultValue: 0) as int;
    final today = _dateToInt(DateTime.now());
    final claimedToday = lastDate == today;

    state = LuckyBoxState(
      claimedToday: claimedToday,
      lastClaimDate: lastDate,
      streak: streak,
    );
  }

  Future<void> _save() async {
    final box = Hive.box('settings');
    await box.put('${_boxKey}_lastDate', state.lastClaimDate);
    await box.put('${_boxKey}_streak', state.streak);
  }

  /// Spin the lucky box and claim the reward.
  Future<LuckyBoxReward?> spin() async {
    if (state.claimedToday || state.isSpinning) return null;

    state = state.copyWith(isSpinning: true);

    final reward = LuckyBoxDatabase.roll();
    final now = DateTime.now();
    final today = _dateToInt(now);
    final yesterday = _dateToInt(now.subtract(const Duration(days: 1)));

    // Calculate streak
    int newStreak;
    if (state.lastClaimDate == yesterday) {
      newStreak = state.streak + 1;
    } else if (state.lastClaimDate == today) {
      newStreak = state.streak; // already claimed
    } else {
      newStreak = 1; // streak broken
    }

    state = state.copyWith(
      currentReward: () => reward,
      claimedToday: true,
      lastClaimDate: today,
      streak: newStreak,
      isSpinning: false,
    );

    // Apply reward
    final currency = ref.read(currencyProvider.notifier);
    switch (reward.type) {
      case LuckyBoxRewardType.gold:
        await currency.addGold(reward.amount);
      case LuckyBoxRewardType.diamond:
        await currency.addDiamond(reward.amount);
      case LuckyBoxRewardType.expPotion:
        await currency.addExpPotion(reward.amount);
      case LuckyBoxRewardType.gachaTicket:
        await currency.addGachaTicket(reward.amount);
    }

    // Check streak bonus (every 7 days)
    if (newStreak > 0 && newStreak % 7 == 0) {
      final bonus = LuckyBoxDatabase.streakBonus(newStreak);
      switch (bonus.type) {
        case LuckyBoxRewardType.gold:
          await currency.addGold(bonus.amount);
        case LuckyBoxRewardType.diamond:
          await currency.addDiamond(bonus.amount);
        case LuckyBoxRewardType.expPotion:
          await currency.addExpPotion(bonus.amount);
        case LuckyBoxRewardType.gachaTicket:
          await currency.addGachaTicket(bonus.amount);
      }
    }

    await _save();
    return reward;
  }

  /// Check if streak bonus is available this spin.
  bool get isStreakBonusSpin {
    if (state.claimedToday) return false;
    final now = DateTime.now();
    final yesterday = _dateToInt(now.subtract(const Duration(days: 1)));
    final potentialStreak = state.lastClaimDate == yesterday
        ? state.streak + 1
        : 1;
    return potentialStreak > 0 && potentialStreak % 7 == 0;
  }

  /// Next streak milestone.
  int get nextStreakMilestone {
    final current = state.streak;
    return ((current ~/ 7) + 1) * 7;
  }

  static int _dateToInt(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;
}

// =============================================================================
// Provider
// =============================================================================

final luckyBoxProvider =
    StateNotifierProvider<LuckyBoxNotifier, LuckyBoxState>(
  (ref) => LuckyBoxNotifier(ref),
);
