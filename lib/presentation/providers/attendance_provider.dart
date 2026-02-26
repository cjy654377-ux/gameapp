import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local_storage.dart';
import 'currency_provider.dart';
import 'player_provider.dart';

// =============================================================================
// Reward definitions
// =============================================================================

class AttendanceReward {
  final int day;
  final int gold;
  final int diamond;
  final int gachaTicket;
  final int expPotion;

  const AttendanceReward({
    required this.day,
    this.gold = 0,
    this.diamond = 0,
    this.gachaTicket = 0,
    this.expPotion = 0,
  });

  /// 7-day reward cycle.
  static const List<AttendanceReward> cycle = [
    AttendanceReward(day: 1, gold: 500),
    AttendanceReward(day: 2, gold: 1000, expPotion: 2),
    AttendanceReward(day: 3, diamond: 5),
    AttendanceReward(day: 4, gold: 2000, expPotion: 3),
    AttendanceReward(day: 5, diamond: 10),
    AttendanceReward(day: 6, gold: 3000, gachaTicket: 1),
    AttendanceReward(day: 7, diamond: 20, gachaTicket: 2),
  ];
}

// =============================================================================
// State
// =============================================================================

class AttendanceState {
  final bool canCheckIn;
  final int currentStreak;
  final int totalDays;

  const AttendanceState({
    this.canCheckIn = false,
    this.currentStreak = 0,
    this.totalDays = 0,
  });

  AttendanceReward get todayReward =>
      AttendanceReward.cycle[currentStreak % 7];

  AttendanceState copyWith({
    bool? canCheckIn,
    int? currentStreak,
    int? totalDays,
  }) {
    return AttendanceState(
      canCheckIn: canCheckIn ?? this.canCheckIn,
      currentStreak: currentStreak ?? this.currentStreak,
      totalDays: totalDays ?? this.totalDays,
    );
  }
}

// =============================================================================
// Notifier
// =============================================================================

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  AttendanceNotifier(this._ref) : super(const AttendanceState());

  final Ref _ref;

  void refresh() {
    final player = _ref.read(playerProvider).player;
    if (player == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool canCheck = true;
    if (player.lastCheckInDate != null) {
      final lastDate = player.lastCheckInDate!;
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      if (lastDay == today) {
        canCheck = false;
      }
    }

    state = AttendanceState(
      canCheckIn: canCheck,
      currentStreak: player.checkInStreak,
      totalDays: player.totalCheckInDays,
    );
  }

  Future<AttendanceReward?> checkIn() async {
    if (!state.canCheckIn) return null;

    final player = _ref.read(playerProvider).player;
    if (player == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate new streak
    int newStreak = player.checkInStreak;
    if (player.lastCheckInDate != null) {
      final lastDate = player.lastCheckInDate!;
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 1) {
        // Consecutive day
        newStreak = (newStreak % 7) + 1;
      } else if (diff > 1) {
        // Streak broken
        newStreak = 1;
      } else {
        // Same day (shouldn't reach here due to canCheckIn guard)
        return null;
      }
    } else {
      // First ever check-in
      newStreak = 1;
    }

    final reward = AttendanceReward.cycle[newStreak - 1];

    // Give rewards
    await _ref.read(currencyProvider.notifier).addReward(
          gold: reward.gold,
          diamond: reward.diamond,
          gachaTicket: reward.gachaTicket,
          expPotion: reward.expPotion,
        );

    // Update player
    final updated = player.copyWith(
      lastCheckInDate: now,
      checkInStreak: newStreak,
      totalCheckInDays: player.totalCheckInDays + 1,
    );
    await LocalStorage.instance.savePlayer(updated);
    _ref.read(playerProvider.notifier).forceUpdate(updated);

    state = AttendanceState(
      canCheckIn: false,
      currentStreak: newStreak,
      totalDays: updated.totalCheckInDays,
    );

    return reward;
  }
}

// =============================================================================
// Provider
// =============================================================================

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>(
  (ref) => AttendanceNotifier(ref),
);
