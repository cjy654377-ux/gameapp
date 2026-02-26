import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'arena_provider.dart';
import 'player_provider.dart';
import 'tower_provider.dart';
import 'world_boss_provider.dart';

// =============================================================================
// Leaderboard Entry
// =============================================================================

class LeaderboardEntry {
  final int rank;
  final String name;
  final int score;
  final bool isPlayer;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.score,
    this.isPlayer = false,
  });
}

enum LeaderboardTab { arena, dungeon, tower, worldBoss }

// =============================================================================
// State
// =============================================================================

class LeaderboardState {
  final LeaderboardTab activeTab;
  final List<LeaderboardEntry> entries;
  final int playerRank;

  const LeaderboardState({
    this.activeTab = LeaderboardTab.arena,
    this.entries = const [],
    this.playerRank = 0,
  });

  LeaderboardState copyWith({
    LeaderboardTab? activeTab,
    List<LeaderboardEntry>? entries,
    int? playerRank,
  }) =>
      LeaderboardState(
        activeTab: activeTab ?? this.activeTab,
        entries: entries ?? this.entries,
        playerRank: playerRank ?? this.playerRank,
      );
}

// =============================================================================
// Provider
// =============================================================================

final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier(ref);
});

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  LeaderboardNotifier(this._ref) : super(const LeaderboardState());
  final Ref _ref;

  static const _aiNames = [
    '드래곤마스터', '그림자사냥꾼', '불꽃전사', '바람의검', '암흑기사',
    '빛의수호자', '폭풍마법사', '얼음여왕', '번개왕', '대지의힘',
    '별의파편', '달빛전사', '태양의창', '철벽방패', '독안개',
    '영혼파괴자', '시간여행자', '우주탐험가', '심해사냥꾼', '화산군주',
    '서리칼날', '천둥주먹', '바위거인', '숲의정령', '사막폭풍',
    '수정조각사', '그림자춤', '황금날개', '은빛화살', '루비심장',
  ];

  void load() {
    _refresh();
  }

  void setTab(LeaderboardTab tab) {
    state = state.copyWith(activeTab: tab);
    _refresh();
  }

  void _refresh() {
    final playerScore = _getPlayerScore(state.activeTab);
    final entries = _generateEntries(state.activeTab, playerScore);
    final playerRank =
        entries.indexWhere((e) => e.isPlayer) + 1;

    state = state.copyWith(entries: entries, playerRank: playerRank);
  }

  int _getPlayerScore(LeaderboardTab tab) {
    switch (tab) {
      case LeaderboardTab.arena:
        return _ref.read(arenaProvider).rating;
      case LeaderboardTab.dungeon:
        return _ref.read(playerProvider).player?.maxDungeonFloor ?? 0;
      case LeaderboardTab.tower:
        return _ref.read(towerProvider).highestCleared;
      case LeaderboardTab.worldBoss:
        return _ref.read(worldBossProvider).bestDamage.round();
    }
  }

  List<LeaderboardEntry> _generateEntries(
      LeaderboardTab tab, int playerScore) {
    final rng = Random(tab.index * 1000 + DateTime.now().day);
    final scores = <int>[];

    // Generate AI scores around/above/below player score
    final baseRange = _baseRange(tab);
    for (int i = 0; i < 30; i++) {
      final variance = (rng.nextDouble() * baseRange.spread).round();
      final score = (baseRange.top - variance).clamp(baseRange.min, baseRange.top);
      scores.add(score);
    }

    // Add player score
    scores.add(playerScore);

    // Sort descending
    scores.sort((a, b) => b.compareTo(a));

    // Build entries with unique AI names
    final usedNames = <String>{};
    final entries = <LeaderboardEntry>[];
    int playerIdx = -1;

    for (int i = 0; i < scores.length; i++) {
      if (scores[i] == playerScore && playerIdx < 0) {
        playerIdx = i;
        final playerName = _ref.read(playerProvider).player?.nickname ?? '나';
        entries.add(LeaderboardEntry(
          rank: i + 1,
          name: playerName,
          score: playerScore,
          isPlayer: true,
        ));
      } else {
        String name;
        do {
          name = _aiNames[rng.nextInt(_aiNames.length)];
        } while (usedNames.contains(name));
        usedNames.add(name);
        entries.add(LeaderboardEntry(
          rank: i + 1,
          name: name,
          score: scores[i],
        ));
      }
    }

    return entries;
  }

  _ScoreRange _baseRange(LeaderboardTab tab) {
    switch (tab) {
      case LeaderboardTab.arena:
        return const _ScoreRange(top: 2200, spread: 1400, min: 800);
      case LeaderboardTab.dungeon:
        return const _ScoreRange(top: 80, spread: 75, min: 1);
      case LeaderboardTab.tower:
        return const _ScoreRange(top: 30, spread: 28, min: 1);
      case LeaderboardTab.worldBoss:
        return const _ScoreRange(top: 500000, spread: 480000, min: 1000);
    }
  }
}

class _ScoreRange {
  final int top;
  final int spread;
  final int min;
  const _ScoreRange({required this.top, required this.spread, required this.min});
}
