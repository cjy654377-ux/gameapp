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

  const QuestState({
    this.quests = const [],
    this.isLoaded = false,
  });

  QuestState copyWith({
    List<QuestModel>? quests,
    bool? isLoaded,
  }) {
    return QuestState(
      quests: quests ?? this.quests,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  /// Daily quests that are active (not yet completed or not yet claimed).
  List<QuestModel> get dailyQuests => quests
      .where((q) => QuestDatabase.findById(q.questId)?.type == QuestType.daily)
      .toList();

  /// Weekly quests.
  List<QuestModel> get weeklyQuests => quests
      .where((q) => QuestDatabase.findById(q.questId)?.type == QuestType.weekly)
      .toList();

  /// Achievement quests.
  List<QuestModel> get achievements => quests
      .where((q) =>
          QuestDatabase.findById(q.questId)?.type == QuestType.achievement)
      .toList();

  /// Number of quests ready to claim rewards.
  int get claimableCount => quests.where((q) {
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
  QuestNotifier(this.ref) : super(const QuestState());

  final Ref ref;
  final LocalStorage _storage = LocalStorage.instance;

  /// Load quests from Hive, initializing any missing ones.
  Future<void> load() async {
    var quests = _storage.getAllQuests();

    // Check daily quest resets.
    final now = DateTime.now().toUtc();
    bool needsSave = false;
    quests = quests.map((q) {
      if (q.resetAt != null && now.isAfter(q.resetAt!)) {
        // Daily quest needs reset.
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
    bool changed = false;

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
        updated.add(quest.copyWith(
          currentProgress: newProgress.clamp(0, def.targetCount),
        ));
        changed = true;
      } else {
        updated.add(quest);
      }
    }

    if (changed) {
      await _storage.saveQuests(updated);
      state = state.copyWith(quests: updated);
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

    // Award rewards.
    final currency = ref.read(currencyProvider.notifier);
    if (def.rewardGold > 0) await currency.addGold(def.rewardGold);
    if (def.rewardDiamond > 0) await currency.addDiamond(def.rewardDiamond);
    if (def.rewardGachaTicket > 0) {
      await currency.addGachaTicket(def.rewardGachaTicket);
    }

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
