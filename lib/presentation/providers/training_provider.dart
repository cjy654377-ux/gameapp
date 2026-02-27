import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/models/app_message.dart';
import '../../data/models/monster_model.dart';
import '../../domain/services/training_service.dart';
import 'package:gameapp/presentation/providers/monster_provider.dart';

// =============================================================================
// Training Slot data
// =============================================================================

class TrainingSlot {
  final String id;
  final String monsterId;
  final String monsterName;
  final int monsterLevel;
  final int durationSeconds;
  final DateTime startedAt;
  final bool isCollected;

  const TrainingSlot({
    required this.id,
    required this.monsterId,
    required this.monsterName,
    required this.monsterLevel,
    required this.durationSeconds,
    required this.startedAt,
    this.isCollected = false,
  });

  DateTime get completesAt => startedAt.add(Duration(seconds: durationSeconds));
  bool get isComplete => DateTime.now().isAfter(completesAt);

  Duration get remainingTime {
    final diff = completesAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  double get progress {
    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    return (elapsed / durationSeconds).clamp(0.0, 1.0);
  }

  int get xpReward => TrainingService.calculateXp(
        durationSeconds: durationSeconds,
        monsterLevel: monsterLevel,
      );

  TrainingSlot copyWith({bool? isCollected}) => TrainingSlot(
        id: id,
        monsterId: monsterId,
        monsterName: monsterName,
        monsterLevel: monsterLevel,
        durationSeconds: durationSeconds,
        startedAt: startedAt,
        isCollected: isCollected ?? this.isCollected,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'monsterId': monsterId,
        'monsterName': monsterName,
        'monsterLevel': monsterLevel,
        'durationSeconds': durationSeconds,
        'startedAt': startedAt.toIso8601String(),
        'isCollected': isCollected,
      };

  factory TrainingSlot.fromJson(Map<String, dynamic> j) => TrainingSlot(
        id: j['id'] as String,
        monsterId: j['monsterId'] as String,
        monsterName: j['monsterName'] as String,
        monsterLevel: j['monsterLevel'] as int,
        durationSeconds: j['durationSeconds'] as int,
        startedAt: DateTime.parse(j['startedAt'] as String),
        isCollected: j['isCollected'] as bool? ?? false,
      );
}

// =============================================================================
// State
// =============================================================================

class TrainingState {
  final List<TrainingSlot> slots;
  final AppMessage? message;

  const TrainingState({this.slots = const [], this.message});

  int get activeCount => slots.where((s) => !s.isCollected).length;
  int get completedCount =>
      slots.where((s) => s.isComplete && !s.isCollected).length;
  bool get canStartNew => activeCount < TrainingService.maxSlots;

  /// Monster IDs currently in training (not collected).
  Set<String> get trainingMonsterIds =>
      slots.where((s) => !s.isCollected).map((s) => s.monsterId).toSet();

  TrainingState copyWith({
    List<TrainingSlot>? slots,
    AppMessage? message,
    bool clearMessage = false,
  }) =>
      TrainingState(
        slots: slots ?? this.slots,
        message: clearMessage ? null : (message ?? this.message),
      );
}

// =============================================================================
// Provider
// =============================================================================

final trainingProvider =
    StateNotifierProvider<TrainingNotifier, TrainingState>((ref) {
  return TrainingNotifier(ref);
});

class TrainingNotifier extends StateNotifier<TrainingState> {
  TrainingNotifier(this._ref) : super(const TrainingState());
  final Ref _ref;

  static const _key = 'training_slots';

  // ── Persistence ──────────────────────────────────────────────────────────

  void load() {
    final box = Hive.box('settings');
    final raw = box.get(_key) as String?;
    if (raw == null || raw.isEmpty) return;

    final list = (jsonDecode(raw) as List)
        .map((e) => TrainingSlot.fromJson(e as Map<String, dynamic>))
        .toList();

    // Purge collected slots older than 24h
    final now = DateTime.now();
    final active = list
        .where((s) =>
            !s.isCollected ||
            now.difference(s.completesAt).inHours < 24)
        .toList();

    state = TrainingState(slots: active);
  }

  Future<void> _save() async {
    final box = Hive.box('settings');
    final json = jsonEncode(state.slots.map((s) => s.toJson()).toList());
    await box.put(_key, json);
  }

  // ── Start training ───────────────────────────────────────────────────────

  Future<bool> startTraining({
    required MonsterModel monster,
    required int durationSeconds,
  }) async {
    if (!state.canStartNew) return false;

    // Check not already training
    if (state.trainingMonsterIds.contains(monster.id)) return false;

    final slot = TrainingSlot(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      monsterId: monster.id,
      monsterName: monster.name,
      monsterLevel: monster.level,
      durationSeconds: durationSeconds,
      startedAt: DateTime.now(),
    );

    state = state.copyWith(
      slots: [...state.slots, slot],
      message: AppMessage.trainingStart(monster.name),
    );
    await _save();
    return true;
  }

  // ── Collect XP ───────────────────────────────────────────────────────────

  Future<bool> collectTraining(String slotId) async {
    final idx = state.slots.indexWhere((s) => s.id == slotId);
    if (idx < 0) return false;

    final slot = state.slots[idx];
    if (!slot.isComplete || slot.isCollected) return false;

    // Find monster and apply XP
    final monsters = _ref.read(monsterListProvider);
    final monsterIdx = monsters.indexWhere((m) => m.id == slot.monsterId);
    if (monsterIdx < 0) return false;

    final monster = monsters[monsterIdx];
    final updated =
        TrainingService.applyTrainingXp(monster, slot.xpReward);
    await _ref.read(monsterListProvider.notifier).addMonster(updated);

    // Mark collected
    final updatedSlots = [...state.slots];
    updatedSlots[idx] = slot.copyWith(isCollected: true);

    final levelsGained = updated.level - monster.level;
    final msg = levelsGained > 0
        ? AppMessage.trainingCollectLevelUp(
            monster.name, slot.xpReward, monster.level, updated.level)
        : AppMessage.trainingCollect(monster.name, slot.xpReward);

    state = state.copyWith(slots: updatedSlots, message: msg);
    await _save();
    return true;
  }

  // ── Cancel ───────────────────────────────────────────────────────────────

  Future<void> cancelTraining(String slotId) async {
    final updated = state.slots.where((s) => s.id != slotId).toList();
    state = state.copyWith(slots: updated, message: AppMessage.trainingCancel());
    await _save();
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }
}
