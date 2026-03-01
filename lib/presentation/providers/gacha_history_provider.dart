import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

// =============================================================================
// GachaHistoryEntry
// =============================================================================

class GachaHistoryEntry {
  final String monsterName;
  final int rarity;
  final String element;
  final DateTime timestamp;
  final bool isPity;
  final bool isPickup;

  const GachaHistoryEntry({
    required this.monsterName,
    required this.rarity,
    required this.element,
    required this.timestamp,
    this.isPity = false,
    this.isPickup = false,
  });

  Map<String, dynamic> toJson() => {
        'name': monsterName,
        'rarity': rarity,
        'element': element,
        'ts': timestamp.millisecondsSinceEpoch,
        'pity': isPity,
        'pickup': isPickup,
      };

  factory GachaHistoryEntry.fromJson(Map<String, dynamic> json) =>
      GachaHistoryEntry(
        monsterName: json['name'] as String,
        rarity: json['rarity'] as int,
        element: json['element'] as String,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
        isPity: json['pity'] as bool? ?? false,
        isPickup: json['pickup'] as bool? ?? false,
      );
}

// =============================================================================
// State
// =============================================================================

class GachaHistoryState {
  final List<GachaHistoryEntry> entries;

  const GachaHistoryState({this.entries = const []});

  /// Stats by rarity
  Map<int, int> get rarityStats {
    final map = <int, int>{};
    for (final e in entries) {
      map[e.rarity] = (map[e.rarity] ?? 0) + 1;
    }
    return map;
  }

  int get totalPulls => entries.length;
}

// =============================================================================
// Notifier
// =============================================================================

class GachaHistoryNotifier extends StateNotifier<GachaHistoryState> {
  GachaHistoryNotifier() : super(const GachaHistoryState()) {
    _load();
  }

  static const _key = 'gachaHistory';
  static const int _maxEntries = 100;

  void _load() {
    final box = Hive.box('settings');
    final raw = box.get(_key) as String?;
    if (raw == null) return;
    final list = (jsonDecode(raw) as List)
        .map((e) => GachaHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    state = GachaHistoryState(entries: list);
  }

  Future<void> _save() async {
    final box = Hive.box('settings');
    await box.put(
        _key, jsonEncode(state.entries.map((e) => e.toJson()).toList()));
  }

  /// Add entries from a pull result.
  Future<void> addEntries(List<GachaHistoryEntry> newEntries) async {
    final combined = [...newEntries, ...state.entries];
    if (combined.length > _maxEntries) {
      combined.removeRange(_maxEntries, combined.length);
    }
    state = GachaHistoryState(entries: combined);
    await _save();
  }

  Future<void> clearAll() async {
    state = const GachaHistoryState();
    await _save();
  }
}

// =============================================================================
// Provider
// =============================================================================

final gachaHistoryProvider =
    StateNotifierProvider<GachaHistoryNotifier, GachaHistoryState>(
  (ref) => GachaHistoryNotifier(),
);
