import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

// =============================================================================
// Battle Record (serializable)
// =============================================================================

class BattleRecordStats {
  final double totalDamage;
  final int totalCriticals;
  final int totalSkillUses;
  final String mvpName;

  const BattleRecordStats({
    this.totalDamage = 0,
    this.totalCriticals = 0,
    this.totalSkillUses = 0,
    this.mvpName = '',
  });

  Map<String, dynamic> toJson() => {
        'dmg': totalDamage,
        'crit': totalCriticals,
        'skill': totalSkillUses,
        'mvp': mvpName,
      };

  factory BattleRecordStats.fromJson(Map<String, dynamic> json) =>
      BattleRecordStats(
        totalDamage: (json['dmg'] as num?)?.toDouble() ?? 0,
        totalCriticals: json['crit'] as int? ?? 0,
        totalSkillUses: json['skill'] as int? ?? 0,
        mvpName: json['mvp'] as String? ?? '',
      );
}

class BattleRecord {
  final String id;
  final DateTime timestamp;
  final String label; // e.g. "Stage 1-3" or "Dungeon 5F"
  final bool isVictory;
  final int totalTurns;
  final List<String> playerNames;
  final List<String> enemyNames;
  final List<String> logLines; // BattleLogEntry.description list
  final BattleRecordStats stats;

  const BattleRecord({
    required this.id,
    required this.timestamp,
    required this.label,
    required this.isVictory,
    required this.totalTurns,
    required this.playerNames,
    required this.enemyNames,
    required this.logLines,
    this.stats = const BattleRecordStats(),
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ts': timestamp.millisecondsSinceEpoch,
        'label': label,
        'victory': isVictory,
        'turns': totalTurns,
        'players': playerNames,
        'enemies': enemyNames,
        'logs': logLines,
        'stats': stats.toJson(),
      };

  factory BattleRecord.fromJson(Map<String, dynamic> json) => BattleRecord(
        id: json['id'] as String? ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            json['ts'] as int? ?? 0),
        label: json['label'] as String? ?? 'Unknown',
        isVictory: json['victory'] as bool? ?? false,
        totalTurns: json['turns'] as int? ?? 0,
        playerNames: (json['players'] as List?)
            ?.map((e) => e?.toString() ?? '')
            .toList() ?? const [],
        enemyNames: (json['enemies'] as List?)
            ?.map((e) => e?.toString() ?? '')
            .toList() ?? const [],
        logLines: (json['logs'] as List?)
            ?.map((e) => e?.toString() ?? '')
            .toList() ?? const [],
        stats: json['stats'] != null
            ? BattleRecordStats.fromJson(json['stats'] as Map<String, dynamic>)
            : const BattleRecordStats(),
      );
}

// =============================================================================
// Filter
// =============================================================================

enum ReplayFilter { all, victory, defeat }

// =============================================================================
// State
// =============================================================================

class BattleReplayState {
  final List<BattleRecord> records;
  final ReplayFilter filter;

  const BattleReplayState({
    this.records = const [],
    this.filter = ReplayFilter.all,
  });

  List<BattleRecord> get filteredRecords {
    switch (filter) {
      case ReplayFilter.all:
        return records;
      case ReplayFilter.victory:
        return records.where((r) => r.isVictory).toList();
      case ReplayFilter.defeat:
        return records.where((r) => !r.isVictory).toList();
    }
  }

  int get victoryCount => records.where((r) => r.isVictory).length;
  int get defeatCount => records.where((r) => !r.isVictory).length;

  BattleReplayState copyWith({
    List<BattleRecord>? records,
    ReplayFilter? filter,
  }) =>
      BattleReplayState(
        records: records ?? this.records,
        filter: filter ?? this.filter,
      );
}

// =============================================================================
// Notifier
// =============================================================================

class BattleReplayNotifier extends StateNotifier<BattleReplayState> {
  BattleReplayNotifier() : super(const BattleReplayState()) {
    _load();
  }

  static const _key = 'battle_replays';
  static const _maxRecords = 20;

  void _load() {
    try {
      final box = Hive.box('settings');
      final raw = box.get(_key) as String?;
      if (raw == null) return;
      final list = (jsonDecode(raw) as List)
          .map((e) => BattleRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      state = BattleReplayState(records: list);
    } catch (_) {
      state = const BattleReplayState();
    }
  }

  Future<void> _save() async {
    final box = Hive.box('settings');
    await box.put(_key, jsonEncode(state.records.map((r) => r.toJson()).toList()));
  }

  /// Add a new battle record. Keeps at most [_maxRecords].
  Future<void> addRecord(BattleRecord record) async {
    final updated = [record, ...state.records];
    if (updated.length > _maxRecords) {
      updated.removeRange(_maxRecords, updated.length);
    }
    state = state.copyWith(records: updated);
    await _save();
  }

  /// Delete a single record by id.
  Future<void> deleteRecord(String id) async {
    final updated = state.records.where((r) => r.id != id).toList();
    state = state.copyWith(records: updated);
    await _save();
  }

  void setFilter(ReplayFilter filter) {
    state = state.copyWith(filter: filter);
  }

  Future<void> clearAll() async {
    state = const BattleReplayState();
    await _save();
  }
}

// =============================================================================
// Provider
// =============================================================================

final battleReplayProvider =
    StateNotifierProvider<BattleReplayNotifier, BattleReplayState>(
  (ref) => BattleReplayNotifier(),
);
