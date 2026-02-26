import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:gameapp/data/models/monster_model.dart';
import 'package:gameapp/data/static/monster_database.dart';
import 'package:gameapp/data/static/quest_database.dart';
import 'package:gameapp/domain/services/audio_service.dart';
import 'package:gameapp/domain/services/upgrade_service.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';
import 'package:gameapp/presentation/providers/monster_provider.dart';
import 'package:gameapp/presentation/providers/player_provider.dart';
import 'package:gameapp/presentation/providers/quest_provider.dart';
import 'package:gameapp/presentation/widgets/tutorial_overlay.dart';

// =============================================================================
// UpgradeTab enum
// =============================================================================

enum UpgradeTab { levelUp, evolution, fusion, awakening }

// =============================================================================
// UpgradeState
// =============================================================================

class UpgradeState {
  /// Currently selected monster ID (null = none selected).
  final String? selectedMonsterId;

  /// Active tab (level-up, evolution, or fusion).
  final UpgradeTab activeTab;

  /// Whether an upgrade operation is in progress.
  final bool isProcessing;

  /// Flash message after a successful operation (auto-dismissed).
  final String? successMessage;

  /// Second monster ID selected for fusion (null = none).
  final String? fusionMonsterId;

  /// The result monster name after a fusion (for display in success message).
  final String? fusionResultName;

  const UpgradeState({
    this.selectedMonsterId,
    this.activeTab = UpgradeTab.levelUp,
    this.isProcessing = false,
    this.successMessage,
    this.fusionMonsterId,
    this.fusionResultName,
  });

  UpgradeState copyWith({
    String? selectedMonsterId,
    bool clearSelection = false,
    UpgradeTab? activeTab,
    bool? isProcessing,
    String? successMessage,
    bool clearMessage = false,
    String? fusionMonsterId,
    bool clearFusion = false,
    String? fusionResultName,
    bool clearFusionResult = false,
  }) {
    return UpgradeState(
      selectedMonsterId:
          clearSelection ? null : (selectedMonsterId ?? this.selectedMonsterId),
      activeTab: activeTab ?? this.activeTab,
      isProcessing: isProcessing ?? this.isProcessing,
      successMessage:
          clearMessage ? null : (successMessage ?? this.successMessage),
      fusionMonsterId:
          clearFusion ? null : (fusionMonsterId ?? this.fusionMonsterId),
      fusionResultName:
          clearFusionResult ? null : (fusionResultName ?? this.fusionResultName),
    );
  }
}

// =============================================================================
// UpgradeNotifier
// =============================================================================

class UpgradeNotifier extends StateNotifier<UpgradeState> {
  UpgradeNotifier(this.ref) : super(const UpgradeState());

  final Ref ref;

  // ---------------------------------------------------------------------------
  // Selection / tab
  // ---------------------------------------------------------------------------

  void selectMonster(String monsterId) {
    state = state.copyWith(selectedMonsterId: monsterId, clearMessage: true);
  }

  void clearSelection() {
    state = state.copyWith(clearSelection: true, clearMessage: true);
  }

  void setTab(UpgradeTab tab) {
    state = state.copyWith(activeTab: tab, clearMessage: true);
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }

  // ---------------------------------------------------------------------------
  // Level-up with gold
  // ---------------------------------------------------------------------------

  /// Levels up the selected monster by spending gold.
  /// Returns `true` on success.
  Future<bool> levelUpWithGold() async {
    final monster = _selectedMonster;
    if (monster == null || state.isProcessing) return false;
    if (!UpgradeService.canLevelUp(monster)) return false;

    final cost = UpgradeService.levelUpGoldCost(monster);
    state = state.copyWith(isProcessing: true, clearMessage: true);

    final spent = await ref.read(currencyProvider.notifier).spendGold(cost);
    if (!spent) {
      state = state.copyWith(isProcessing: false);
      return false;
    }

    final upgraded = UpgradeService.applyLevelUp(monster);
    await ref.read(monsterListProvider.notifier).updateMonster(upgraded);
    ref.read(questProvider.notifier).onTrigger(QuestTrigger.monsterLevelUp);
    AudioService.instance.playLevelUp();

    // Advance tutorial after first level-up.
    final step = ref.read(playerProvider).player?.tutorialStep ?? 0;
    if (step <= TutorialSteps.upgradeIntro) {
      ref.read(playerProvider.notifier).advanceTutorial(TutorialSteps.teamIntro);
    }

    state = state.copyWith(
      isProcessing: false,
      successMessage: 'Lv.${upgraded.level} 달성!',
    );
    return true;
  }

  // ---------------------------------------------------------------------------
  // Level-up with exp potions
  // ---------------------------------------------------------------------------

  /// Uses [count] exp potions on the selected monster.
  /// Returns `true` on success.
  Future<bool> useExpPotions(int count) async {
    final monster = _selectedMonster;
    if (monster == null || state.isProcessing) return false;
    if (!UpgradeService.canLevelUp(monster)) return false;
    if (count <= 0) return false;

    state = state.copyWith(isProcessing: true, clearMessage: true);

    final spent =
        await ref.read(currencyProvider.notifier).spendExpPotion(count);
    if (!spent) {
      state = state.copyWith(isProcessing: false);
      return false;
    }

    final upgraded = UpgradeService.applyExpPotions(monster, count);
    await ref.read(monsterListProvider.notifier).updateMonster(upgraded);

    final levelsGained = upgraded.level - monster.level;
    state = state.copyWith(
      isProcessing: false,
      successMessage: levelsGained > 0
          ? 'Lv.${upgraded.level} 달성! (+$levelsGained)'
          : '경험치 획득!',
    );
    return true;
  }

  // ---------------------------------------------------------------------------
  // Evolution
  // ---------------------------------------------------------------------------

  /// Evolves the selected monster by spending shards and gold.
  /// Returns `true` on success.
  Future<bool> evolve() async {
    final monster = _selectedMonster;
    if (monster == null || state.isProcessing) return false;
    if (!UpgradeService.canEvolve(monster)) return false;

    final shardCost = UpgradeService.evolutionShardCost(monster);
    final goldCost = UpgradeService.evolutionGoldCost(monster);

    state = state.copyWith(isProcessing: true, clearMessage: true);

    // Pre-check both currencies.
    final currency = ref.read(currencyProvider);
    if (!currency.canAfford(gold: goldCost, monsterShard: shardCost)) {
      state = state.copyWith(isProcessing: false);
      return false;
    }

    // Spend gold first, then shards.
    final goldOk = await ref.read(currencyProvider.notifier).spendGold(goldCost);
    if (!goldOk) {
      state = state.copyWith(isProcessing: false);
      return false;
    }
    final shardOk =
        await ref.read(currencyProvider.notifier).spendShard(shardCost);
    if (!shardOk) {
      // Refund gold if shards fail (should not happen after canAfford check).
      await ref.read(currencyProvider.notifier).addGold(goldCost);
      state = state.copyWith(isProcessing: false);
      return false;
    }

    final evolved = UpgradeService.applyEvolution(monster);
    await ref.read(monsterListProvider.notifier).updateMonster(evolved);
    ref.read(questProvider.notifier).onTrigger(QuestTrigger.monsterEvolve);
    AudioService.instance.playEvolution();

    final stageName = evolved.evolutionStage == 1 ? '1차 진화' : '최종 진화';
    state = state.copyWith(
      isProcessing: false,
      successMessage: '$stageName 성공!',
    );
    return true;
  }

  // ---------------------------------------------------------------------------
  // Fusion
  // ---------------------------------------------------------------------------

  /// Selects or deselects the second monster for fusion.
  void selectFusionMonster(String monsterId) {
    if (state.fusionMonsterId == monsterId) {
      state = state.copyWith(clearFusion: true, clearMessage: true);
    } else {
      state = state.copyWith(fusionMonsterId: monsterId, clearMessage: true);
    }
  }

  void clearFusionSelection() {
    state = state.copyWith(clearFusion: true, clearMessage: true);
  }

  /// Gold cost for fusion: 300 * rarity.
  static int fusionGoldCost(int rarity) => 300 * rarity;

  /// Whether two monsters can be fused.
  static bool canFuse(MonsterModel a, MonsterModel b) {
    if (a.id == b.id) return false;
    if (a.rarity != b.rarity) return false;
    if (a.rarity >= 5) return false; // Cannot fuse legendary
    if (a.isInTeam || b.isInTeam) return false;
    return true;
  }

  /// Performs fusion: consumes both selected monsters, creates a new one of
  /// the next rarity. Returns `true` on success.
  Future<bool> fuse() async {
    final monsterA = _selectedMonster;
    final monsterB = _fusionMonster;
    if (monsterA == null || monsterB == null) return false;
    if (!canFuse(monsterA, monsterB)) return false;
    if (state.isProcessing) return false;

    final cost = fusionGoldCost(monsterA.rarity);
    state = state.copyWith(isProcessing: true, clearMessage: true);

    final spent = await ref.read(currencyProvider.notifier).spendGold(cost);
    if (!spent) {
      state = state.copyWith(isProcessing: false);
      return false;
    }

    // Pick a random monster of the next rarity.
    final nextRarity = monsterA.rarity + 1;
    final candidates = MonsterDatabase.byRarity(nextRarity);
    if (candidates.isEmpty) {
      // Refund gold if no candidates (shouldn't happen).
      await ref.read(currencyProvider.notifier).addGold(cost);
      state = state.copyWith(isProcessing: false);
      return false;
    }

    final random = math.Random();
    final template = candidates[random.nextInt(candidates.length)];

    // Create the new monster.
    final newMonster = MonsterModel.fromTemplate(
      id: const Uuid().v4(),
      templateId: template.id,
      name: template.name,
      rarity: template.rarity,
      element: template.element,
      baseAtk: template.baseAtk,
      baseDef: template.baseDef,
      baseHp: template.baseHp,
      baseSpd: template.baseSpd,
      size: template.size,
    );

    // Remove both source monsters and add the new one.
    final monsterNotifier = ref.read(monsterListProvider.notifier);
    await monsterNotifier.removeMonster(monsterA.id);
    await monsterNotifier.removeMonster(monsterB.id);
    await monsterNotifier.addMonster(newMonster);

    // Update collection progress for quests.
    final roster = ref.read(monsterListProvider);
    final uniqueCount = roster.map((m) => m.templateId).toSet().length;
    ref.read(questProvider.notifier).onTrigger(
          QuestTrigger.collectMonster,
          absoluteValue: uniqueCount,
        );

    AudioService.instance.playEvolution();

    state = state.copyWith(
      isProcessing: false,
      clearSelection: true,
      clearFusion: true,
      successMessage: '${template.name} 획득! ($nextRarity성)',
      fusionResultName: template.name,
    );
    return true;
  }

  // ---------------------------------------------------------------------------
  // Awakening
  // ---------------------------------------------------------------------------

  static const int maxAwakeningStars = 5;

  /// Gold cost: 500 * rarity * (currentStars + 1)
  static int awakeningGoldCost(MonsterModel m) => 500 * m.rarity * (m.awakeningStars + 1);

  /// Shard cost: 3 * rarity * (currentStars + 1)
  static int awakeningShardCost(MonsterModel m) => 3 * m.rarity * (m.awakeningStars + 1);

  static bool canAwaken(MonsterModel m) {
    return m.evolutionStage >= 2 && m.awakeningStars < maxAwakeningStars;
  }

  Future<bool> awaken() async {
    final monster = _selectedMonster;
    if (monster == null || state.isProcessing) return false;
    if (!canAwaken(monster)) return false;

    final goldCost = awakeningGoldCost(monster);
    final shardCost = awakeningShardCost(monster);

    state = state.copyWith(isProcessing: true, clearMessage: true);

    final currency = ref.read(currencyProvider);
    if (!currency.canAfford(gold: goldCost, monsterShard: shardCost)) {
      state = state.copyWith(isProcessing: false);
      return false;
    }

    final goldOk = await ref.read(currencyProvider.notifier).spendGold(goldCost);
    if (!goldOk) {
      state = state.copyWith(isProcessing: false);
      return false;
    }
    final shardOk = await ref.read(currencyProvider.notifier).spendShard(shardCost);
    if (!shardOk) {
      await ref.read(currencyProvider.notifier).addGold(goldCost);
      state = state.copyWith(isProcessing: false);
      return false;
    }

    final awakened = monster.copyWith(awakeningStars: monster.awakeningStars + 1);
    await ref.read(monsterListProvider.notifier).updateMonster(awakened);
    AudioService.instance.playEvolution();

    state = state.copyWith(
      isProcessing: false,
      successMessage: '각성 ${awakened.awakeningStars}성 달성! (+10% 스탯)',
    );
    return true;
  }

  MonsterModel? get _fusionMonster {
    final id = state.fusionMonsterId;
    if (id == null) return null;
    final roster = ref.read(monsterListProvider);
    for (final m in roster) {
      if (m.id == id) return m;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  MonsterModel? get _selectedMonster {
    final id = state.selectedMonsterId;
    if (id == null) return null;
    final roster = ref.read(monsterListProvider);
    for (final m in roster) {
      if (m.id == id) return m;
    }
    return null;
  }
}

// =============================================================================
// Provider
// =============================================================================

final upgradeProvider =
    StateNotifierProvider<UpgradeNotifier, UpgradeState>(
  (ref) => UpgradeNotifier(ref),
);
