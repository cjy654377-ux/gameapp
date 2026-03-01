import 'dart:math' as math;

/// Static service for expedition reward calculation.
class ExpeditionService {
  ExpeditionService._();

  static const int maxSlots = 3;
  static const int maxMonstersPerSlot = 3;

  static final _random = math.Random();

  /// Available expedition durations (seconds).
  static const List<ExpeditionOption> options = [
    ExpeditionOption(durationSeconds: 3600),
    ExpeditionOption(durationSeconds: 14400),
    ExpeditionOption(durationSeconds: 28800),
  ];

  /// Preview expected reward ranges for a given duration and total level.
  static ExpeditionRewardPreview previewReward({
    required int durationSeconds,
    required int totalMonsterLevel,
  }) {
    final hours = durationSeconds / 3600.0;
    final levelFactor = 1.0 + (totalMonsterLevel - 1) * 0.03;

    final baseGold = (200 * hours * levelFactor).round();
    final goldMin = baseGold;
    final goldMax = baseGold + (baseGold * 0.2).round().clamp(1, 999);

    final baseExpMin = (0.5 * hours * levelFactor).round().clamp(1, 20);
    final baseExpMax = baseExpMin; // exp is deterministic

    final shardChance = hours >= 8 ? 40 : (hours >= 4 ? 25 : 10);
    final diamondChance = hours >= 8 ? 15 : 0;

    return ExpeditionRewardPreview(
      goldMin: goldMin,
      goldMax: goldMax,
      expMin: baseExpMin,
      expMax: baseExpMax,
      shardChancePct: shardChance,
      diamondChancePct: diamondChance,
    );
  }

  /// Calculate expedition rewards based on duration and total monster level.
  static ExpeditionReward calculateReward({
    required int durationSeconds,
    required int totalMonsterLevel,
  }) {
    final hours = durationSeconds / 3600.0;
    final levelFactor = 1.0 + (totalMonsterLevel - 1) * 0.03;

    // Base rewards scale with duration
    final baseGold = (200 * hours * levelFactor).round();
    final baseExpPotions = (0.5 * hours * levelFactor).round().clamp(1, 20);

    // Shard chance increases with duration
    final shardChance = hours >= 8 ? 0.4 : (hours >= 4 ? 0.25 : 0.1);
    final shards = _random.nextDouble() < shardChance
        ? (1 + _random.nextInt((hours / 4).ceil().clamp(1, 3)))
        : 0;

    // Bonus diamond for 8h expedition
    final diamonds = hours >= 8 && _random.nextDouble() < 0.15 ? 10 : 0;

    return ExpeditionReward(
      gold: baseGold + _random.nextInt((baseGold * 0.2).round().clamp(1, 999)),
      expPotions: baseExpPotions,
      shards: shards,
      diamonds: diamonds,
    );
  }
}

class ExpeditionOption {
  final int durationSeconds;

  const ExpeditionOption({required this.durationSeconds});

  int get hours => durationSeconds ~/ 3600;
}

/// Preview of expected reward ranges (before expedition starts).
class ExpeditionRewardPreview {
  final int goldMin;
  final int goldMax;
  final int expMin;
  final int expMax;
  final int shardChancePct;
  final int diamondChancePct;

  const ExpeditionRewardPreview({
    required this.goldMin,
    required this.goldMax,
    required this.expMin,
    required this.expMax,
    required this.shardChancePct,
    required this.diamondChancePct,
  });
}

class ExpeditionReward {
  final int gold;
  final int expPotions;
  final int shards;
  final int diamonds;

  const ExpeditionReward({
    required this.gold,
    required this.expPotions,
    required this.shards,
    required this.diamonds,
  });
}
