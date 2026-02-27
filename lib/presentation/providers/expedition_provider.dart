import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/app_message.dart';
import '../../data/datasources/local_storage.dart';
import '../../data/models/expedition_model.dart';
import '../../domain/services/audio_service.dart';
import '../../domain/services/expedition_service.dart';
import 'currency_provider.dart';
import 'monster_provider.dart';

// =============================================================================
// State
// =============================================================================

class ExpeditionState {
  final List<ExpeditionModel> expeditions;
  final AppMessage? successMessage;

  const ExpeditionState({
    this.expeditions = const [],
    this.successMessage,
  });

  int get activeCount => expeditions.where((e) => !e.isCollected).length;
  int get completedCount => expeditions.where((e) => e.isComplete && !e.isCollected).length;
  bool get canStartNew => activeCount < ExpeditionService.maxSlots;

  ExpeditionState copyWith({
    List<ExpeditionModel>? expeditions,
    AppMessage? successMessage,
    bool clearMessage = false,
  }) {
    return ExpeditionState(
      expeditions: expeditions ?? this.expeditions,
      successMessage: clearMessage ? null : (successMessage ?? this.successMessage),
    );
  }
}

// =============================================================================
// Notifier
// =============================================================================

class ExpeditionNotifier extends StateNotifier<ExpeditionState> {
  ExpeditionNotifier(this._ref) : super(const ExpeditionState());

  final Ref _ref;

  /// Must be called after LocalStorage.init() completes.
  void load() {
    final expeditions = LocalStorage.instance.getAllExpeditions();
    // Clean up collected expeditions older than 24h
    final now = DateTime.now();
    final active = expeditions.where((e) {
      if (e.isCollected) {
        return now.difference(e.completesAt).inHours < 24;
      }
      return true;
    }).toList();
    state = ExpeditionState(expeditions: active);
  }

  /// Start a new expedition with selected monsters.
  Future<bool> startExpedition({
    required int durationSeconds,
    required List<String> monsterIds,
  }) async {
    if (!state.canStartNew) return false;
    if (monsterIds.isEmpty || monsterIds.length > ExpeditionService.maxMonstersPerSlot) {
      return false;
    }

    // Verify monsters are not in team and not already on expedition
    final roster = _ref.read(monsterListProvider);
    final onExpedition = state.expeditions
        .where((e) => !e.isCollected)
        .expand((e) => e.monsterIds)
        .toSet();

    final selectedMonsters = roster.where((m) =>
        monsterIds.contains(m.id) && !m.isInTeam && !onExpedition.contains(m.id)).toList();

    if (selectedMonsters.length != monsterIds.length) return false;

    final totalLevel = selectedMonsters.fold<int>(0, (s, m) => s + m.level);

    final expedition = ExpeditionModel(
      id: const Uuid().v4(),
      durationSeconds: durationSeconds,
      startedAt: DateTime.now(),
      monsterIds: monsterIds,
      monsterNames: selectedMonsters.map((m) => m.name).toList(),
      totalMonsterLevel: totalLevel,
    );

    await LocalStorage.instance.saveExpedition(expedition);
    final updated = List<ExpeditionModel>.from(state.expeditions)..add(expedition);
    state = state.copyWith(
      expeditions: updated,
      successMessage: AppMessage.expeditionStart(expedition.durationSeconds ~/ 3600),
    );
    return true;
  }

  /// Collect rewards from a completed expedition.
  Future<bool> collectReward(String expeditionId) async {
    final idx = state.expeditions.indexWhere((e) => e.id == expeditionId);
    if (idx < 0) return false;

    final expedition = state.expeditions[idx];
    if (!expedition.isComplete || expedition.isCollected) return false;

    final reward = ExpeditionService.calculateReward(
      durationSeconds: expedition.durationSeconds,
      totalMonsterLevel: expedition.totalMonsterLevel,
    );

    // Grant rewards
    final currency = _ref.read(currencyProvider.notifier);
    if (reward.gold > 0) await currency.addGold(reward.gold);
    if (reward.expPotions > 0) await currency.addExpPotion(reward.expPotions);
    if (reward.shards > 0) await currency.addShard(reward.shards);
    if (reward.diamonds > 0) await currency.addDiamond(reward.diamonds);

    // Mark collected
    final collected = expedition.copyWith(isCollected: true);
    await LocalStorage.instance.saveExpedition(collected);

    final updated = List<ExpeditionModel>.from(state.expeditions);
    updated[idx] = collected;

    AudioService.instance.playRewardCollect();

    state = state.copyWith(
      expeditions: updated,
      successMessage: AppMessage.rewardSummary(
        gold: reward.gold,
        expPotions: reward.expPotions,
        shards: reward.shards,
        diamonds: reward.diamonds,
      ),
    );
    return true;
  }

  /// Remove a collected expedition from the list.
  Future<void> removeExpedition(String id) async {
    await LocalStorage.instance.deleteExpedition(id);
    final updated = state.expeditions.where((e) => e.id != id).toList();
    state = state.copyWith(expeditions: updated);
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }
}

// =============================================================================
// Provider
// =============================================================================

final expeditionProvider =
    StateNotifierProvider<ExpeditionNotifier, ExpeditionState>(
  (ref) => ExpeditionNotifier(ref),
);
