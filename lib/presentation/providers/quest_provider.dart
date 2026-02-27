import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/data/datasources/local_storage.dart';
import 'package:gameapp/data/models/quest_model.dart';
import 'package:gameapp/data/static/quest_database.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';

// =============================================================================
// QuestState
// =============================================================================

class QuestState {
  final List<QuestModel> quests;
  final bool isLoaded;

  /// Quest IDs that just became completable (progress reached target) in the
  /// latest trigger. Cleared on next trigger or when consumed by UI.
  final List<String> newlyCompletedIds;

  /// Pre-computed quest lists by type — avoids repeated O(n) DB lookups.
  late final List<QuestModel> dailyQuests;
  late final List<QuestModel> weeklyQuests;
  late final List<QuestModel> achievements;
  late final int claimableCount;

  QuestState({
    this.quests = const [],
    this.isLoaded = false,
    this.newlyCompletedIds = const [],
  }) {
    dailyQuests = _filterByType(QuestType.daily);
    weeklyQuests = _filterByType(QuestType.weekly);
    achievements = _filterByType(QuestType.achievement);
    claimableCount = _computeClaimable();
  }

  QuestState copyWith({
    List<QuestModel>? quests,
    bool? isLoaded,
    List<String>? newlyCompletedIds,
  }) {
    return QuestState(
      quests: quests ?? this.quests,
      isLoaded: isLoaded ?? this.isLoaded,
      newlyCompletedIds: newlyCompletedIds ?? this.newlyCompletedIds,
    );
  }

  List<QuestModel> _filterByType(QuestType type) => quests
      .where((q) => QuestDatabase.findById(q.questId)?.type == type)
      .toList();

  int _computeClaimable() => quests.where((q) {
        if (q.isCompleted) return false;
        final def = QuestDatabase.findById(q.questId);
        if (def == null) return false;
        return q.currentProgress >= def.targetCount;
      }).length;
}

// =============================================================================
// QuestNotifier
// =============================================================================

class QuestNotifier extends StateNotifier<QuestState> {
  QuestNotifier(this.ref) : super(QuestState());

  final Ref ref;
  final LocalStorage _storage = LocalStorage.instance;

  /// Load quests from Hive, initializing any missing ones.
  Future<void> load() async {
    var quests = _storage.getAllQuests();

    // Check daily/weekly quest resets.
    final now = DateTime.now().toUtc();
    bool needsSave = false;
    quests = quests.map((q) {
      if (q.resetAt != null && now.isAfter(q.resetAt!)) {
        needsSave = true;
        final def = QuestDatabase.findById(q.questId);
        if (def != null) {
          return QuestModel.fromDefinition(def);
        }
      }
      return q;
    }).toList();

    // Initialize missing quests.
    final existingIds = quests.map((q) => q.questId).toSet();
    for (final def in QuestDatabase.all) {
      if (!existingIds.contains(def.id)) {
        quests.add(QuestModel.fromDefinition(def));
        needsSave = true;
      }
    }

    if (needsSave) {
      await _storage.saveQuests(quests);
    }

    state = QuestState(quests: quests, isLoaded: true);
  }

  /// Increment progress for all quests matching [trigger].
  ///
  /// [count] is the amount to add (default 1).
  /// For collectMonster/stageFirstClear triggers, [absoluteValue] can be set
  /// to override progress with an absolute count instead of incrementing.
  Future<void> onTrigger(
    QuestTrigger trigger, {
    int count = 1,
    int? absoluteValue,
  }) async {
    final updated = <QuestModel>[];
    final changedQuests = <QuestModel>[];

    for (final quest in state.quests) {
      if (quest.isCompleted) {
        updated.add(quest);
        continue;
      }

      final def = QuestDatabase.findById(quest.questId);
      if (def == null || def.trigger != trigger) {
        updated.add(quest);
        continue;
      }

      final newProgress = absoluteValue ?? (quest.currentProgress + count);
      if (newProgress != quest.currentProgress) {
        final changed = quest.copyWith(
          currentProgress: newProgress.clamp(0, def.targetCount),
        );
        updated.add(changed);
        changedQuests.add(changed);
      } else {
        updated.add(quest);
      }
    }

    if (changedQuests.isNotEmpty) {
      // Save only the changed quests instead of the entire list.
      for (final q in changedQuests) {
        await _storage.saveQuest(q);
      }

      // Detect quests that just became completable.
      final newlyCompleted = <String>[];
      for (final q in changedQuests) {
        final def = QuestDatabase.findById(q.questId);
        if (def == null) continue;
        // Just reached target and not already claimed.
        if (q.currentProgress >= def.targetCount && !q.isCompleted) {
          // Check the old quest didn't already meet the target.
          final oldQuest = state.quests.firstWhere(
            (oq) => oq.questId == q.questId,
            orElse: () => q,
          );
          final oldDef = QuestDatabase.findById(oldQuest.questId);
          if (oldDef != null && oldQuest.currentProgress < oldDef.targetCount) {
            newlyCompleted.add(q.questId);
          }
        }
      }

      state = state.copyWith(
        quests: updated,
        newlyCompletedIds: newlyCompleted,
      );
    }
  }

  /// Clears the newlyCompletedIds list (called after UI consumes the toast).
  void clearNewlyCompleted() {
    if (state.newlyCompletedIds.isNotEmpty) {
      state = state.copyWith(newlyCompletedIds: const []);
    }
  }

  /// Claim reward for a completed quest.
  Future<bool> claimReward(String questId) async {
    final idx = state.quests.indexWhere((q) => q.questId == questId);
    if (idx < 0) return false;

    final quest = state.quests[idx];
    if (quest.isCompleted) return false;

    final def = QuestDatabase.findById(questId);
    if (def == null) return false;
    if (quest.currentProgress < def.targetCount) return false;

    // Mark as completed.
    final completed = quest.copyWith(isCompleted: true);
    final updated = [...state.quests];
    updated[idx] = completed;

    // Award rewards (single Hive write).
    final currency = ref.read(currencyProvider.notifier);
    await currency.addReward(
      gold: def.rewardGold,
      diamond: def.rewardDiamond,
      gachaTicket: def.rewardGachaTicket,
    );

    await _storage.saveQuest(completed);
    state = state.copyWith(quests: updated);
    return true;
  }
}

// =============================================================================
// Provider
// =============================================================================

final questProvider = StateNotifierProvider<QuestNotifier, QuestState>(
  (ref) => QuestNotifier(ref),
);
