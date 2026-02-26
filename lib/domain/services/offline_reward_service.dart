import 'dart:math';

import '../../core/constants/game_config.dart';

/// Result of an offline reward calculation.
class OfflineReward {
  final int gold;
  final int exp;
  final Duration elapsed;

  const OfflineReward({
    required this.gold,
    required this.exp,
    required this.elapsed,
  });

  bool get hasReward => gold > 0 || exp > 0;

  /// Elapsed time capped at [GameConfig.maxOfflineHours].
  double get cappedHours =>
      min(elapsed.inMinutes / 60.0, GameConfig.maxOfflineHours.toDouble());
}

/// Pure calculation service for offline rewards.
///
/// Rewards are based on the player's current stage, time elapsed, and
/// efficiency constants from [GameConfig].
class OfflineRewardService {
  const OfflineRewardService();

  /// Calculates offline rewards earned between [lastOnlineAt] and now.
  ///
  /// [stageId] is the player's current stage (e.g. '3-4').
  /// Returns [OfflineReward] with earned gold, exp, and elapsed time.
  OfflineReward calculate({
    required DateTime lastOnlineAt,
    required String stageId,
  }) {
    final now = DateTime.now();
    final elapsed = now.difference(lastOnlineAt);

    // No reward for very short absences.
    if (elapsed.inMinutes < GameConfig.minOfflineMinutes) {
      return OfflineReward(gold: 0, exp: 0, elapsed: elapsed);
    }

    // Cap at max offline hours.
    final hours = min(
      elapsed.inMinutes / 60.0,
      GameConfig.maxOfflineHours.toDouble(),
    );

    // Stage-based reward scaling.
    final stageIndex = _linearIndex(stageId);
    if (stageIndex <= 0) {
      return OfflineReward(gold: 0, exp: 0, elapsed: elapsed);
    }

    final scaling = pow(GameConfig.stageScalingFactor, stageIndex - 1);

    final goldPerBattle = GameConfig.baseGoldPerWin * scaling;
    final expPerBattle = GameConfig.baseExpPerWin * scaling;

    final totalGold = (goldPerBattle *
            GameConfig.offlineBattlesPerHour *
            hours *
            GameConfig.offlineGoldEfficiency)
        .round();

    final totalExp = (expPerBattle *
            GameConfig.offlineBattlesPerHour *
            hours *
            GameConfig.offlineExpEfficiency)
        .round();

    return OfflineReward(
      gold: totalGold,
      exp: totalExp,
      elapsed: elapsed,
    );
  }

  /// Converts a stage string ID (e.g. '3-4') to a 1-based linear index.
  static int _linearIndex(String stageId) {
    if (stageId.isEmpty) return 0;
    final parts = stageId.split('-');
    if (parts.length != 2) return 0;
    final area = int.tryParse(parts[0]) ?? 0;
    final stage = int.tryParse(parts[1]) ?? 0;
    return (area - 1) * 6 + stage;
  }
}
