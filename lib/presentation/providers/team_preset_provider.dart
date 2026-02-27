import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

// =============================================================================
// TeamPreset model
// =============================================================================

class TeamPreset {
  final String name;
  final List<String> monsterIds;

  const TeamPreset({required this.name, required this.monsterIds});

  TeamPreset copyWith({String? name, List<String>? monsterIds}) => TeamPreset(
        name: name ?? this.name,
        monsterIds: monsterIds ?? this.monsterIds,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'monsterIds': monsterIds,
      };

  factory TeamPreset.fromJson(Map<String, dynamic> json) => TeamPreset(
        name: json['name'] as String,
        monsterIds: (json['monsterIds'] as List).cast<String>(),
      );
}

// =============================================================================
// State
// =============================================================================

class TeamPresetState {
  /// 5 preset slots. null means empty slot.
  final List<TeamPreset?> presets;

  const TeamPresetState({required this.presets});

  TeamPresetState copyWith({List<TeamPreset?>? presets}) =>
      TeamPresetState(presets: presets ?? this.presets);
}

// =============================================================================
// Notifier
// =============================================================================

class TeamPresetNotifier extends StateNotifier<TeamPresetState> {
  TeamPresetNotifier()
      : super(TeamPresetState(presets: List.filled(5, null))) {
    _load();
  }

  static const _key = 'teamPresets';
  static const int maxSlots = 5;

  void _load() {
    final box = Hive.box('settings');
    final raw = box.get(_key) as String?;
    if (raw == null) return;
    final list = (jsonDecode(raw) as List).map((e) {
      if (e == null) return null;
      return TeamPreset.fromJson(e as Map<String, dynamic>);
    }).toList();
    // Ensure exactly 5 slots.
    while (list.length < maxSlots) {
      list.add(null);
    }
    state = TeamPresetState(presets: list.take(maxSlots).toList());
  }

  Future<void> _save() async {
    final box = Hive.box('settings');
    final json = jsonEncode(
      state.presets.map((p) => p?.toJson()).toList(),
    );
    await box.put(_key, json);
  }

  /// Save current team to slot [index].
  Future<void> savePreset(int index, String name, List<String> ids) async {
    if (index < 0 || index >= maxSlots) return;
    final updated = [...state.presets];
    updated[index] = TeamPreset(name: name, monsterIds: List.of(ids));
    state = TeamPresetState(presets: updated);
    await _save();
  }

  /// Rename preset at [index].
  Future<void> renamePreset(int index, String newName) async {
    if (index < 0 || index >= maxSlots) return;
    final preset = state.presets[index];
    if (preset == null) return;
    final updated = [...state.presets];
    updated[index] = preset.copyWith(name: newName);
    state = TeamPresetState(presets: updated);
    await _save();
  }

  /// Delete preset at [index].
  Future<void> deletePreset(int index) async {
    if (index < 0 || index >= maxSlots) return;
    final updated = [...state.presets];
    updated[index] = null;
    state = TeamPresetState(presets: updated);
    await _save();
  }
}

// =============================================================================
// Provider
// =============================================================================

final teamPresetProvider =
    StateNotifierProvider<TeamPresetNotifier, TeamPresetState>(
  (ref) => TeamPresetNotifier(),
);
