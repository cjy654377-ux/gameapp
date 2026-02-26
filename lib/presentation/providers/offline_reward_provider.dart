import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/offline_reward_service.dart';

/// State for pending offline rewards.
class OfflineRewardState {
  final OfflineReward? pendingReward;
  final bool claimed;

  const OfflineRewardState({
    this.pendingReward,
    this.claimed = false,
  });

  bool get hasPendingReward =>
      pendingReward != null && pendingReward!.hasReward && !claimed;

  OfflineRewardState copyWith({
    OfflineReward? pendingReward,
    bool? claimed,
    bool clearReward = false,
  }) {
    return OfflineRewardState(
      pendingReward: clearReward ? null : (pendingReward ?? this.pendingReward),
      claimed: claimed ?? this.claimed,
    );
  }
}

class OfflineRewardNotifier extends StateNotifier<OfflineRewardState> {
  OfflineRewardNotifier() : super(const OfflineRewardState());

  final OfflineRewardService _service = const OfflineRewardService();

  /// Calculates offline rewards based on last online time and current stage.
  void calculateRewards({
    required DateTime lastOnlineAt,
    required String stageId,
  }) {
    final reward = _service.calculate(
      lastOnlineAt: lastOnlineAt,
      stageId: stageId,
    );

    if (reward.hasReward) {
      state = OfflineRewardState(pendingReward: reward);
    }
  }

  /// Marks the pending reward as claimed. The actual gold/exp addition
  /// is handled by the caller (HomeScreen lifecycle handler).
  void markClaimed() {
    state = state.copyWith(claimed: true);
  }

  /// Clears any pending reward state.
  void clear() {
    state = const OfflineRewardState();
  }
}

final offlineRewardProvider =
    StateNotifierProvider<OfflineRewardNotifier, OfflineRewardState>(
  (ref) => OfflineRewardNotifier(),
);
