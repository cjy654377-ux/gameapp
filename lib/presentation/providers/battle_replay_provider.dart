import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

// =============================================================================
// Battle Record (serializable)
// =============================================================================

class BattleRecord {
  final String id;
  final DateTime timestamp;
  final String label; // e.g. "Stage 1-3" or "Dungeon 5F"
  final bool isVictory;
  final int totalTurns;
  final List<String> playerNames;
  final List<String> enemyNames;
  final List<String> logLines; // BattleLogEntry.description list

  const BattleRecord({
    required this.id,
    required this.timestamp,
    required this.label,
    required this.isVictory,
    required this.totalTurns,
    required this.playerNames,
    required this.enemyNames,
    required this.logLines,
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
      };

  factory BattleRecord.fromJson(Map<String, dynamic> json) => BattleRecord(
        id: json['id'] as String,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
        label: json['label'] as String,
        isVictory: json['victory'] as bool,
        totalTurns: json['turns'] as int? ?? 0,
        playerNames: (json['players'] as List).cast<String>(),
        enemyNames: (json['enemies'] as List).cast<String>(),
        logLines: (json['logs'] as List).cast<String>(),
      );
}

// =============================================================================
// State
// =============================================================================

class BattleReplayState {
  final List<BattleRecord> records;

  const BattleReplayState({this.records = const []});

  BattleReplayState copyWith({List<BattleRecord>? records}) =>
      BattleReplayState(records: records ?? this.records);
}

// =============================================================================
// Notifier
// =============================================================================

class BattleReplayNotifier extends StateNotifier<BattleReplayState> {
  BattleReplayNotifier() : super(const BattleReplayState()) {
    _load();
  }

  static const _key = 'battle_replays';
  static const _maxRecords = 10;

  void _load() {
    final box = Hive.box('settings');
    final raw = box.get(_key) as String?;
    if (raw == null) return;
    final list = (jsonDecode(raw) as List)
        .map((e) => BattleRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    state = BattleReplayState(records: list);
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
