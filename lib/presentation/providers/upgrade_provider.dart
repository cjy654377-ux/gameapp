import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/data/models/monster_model.dart';
import 'package:gameapp/domain/services/upgrade_service.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';
import 'package:gameapp/presentation/providers/monster_provider.dart';

// =============================================================================
// UpgradeTab enum
// =============================================================================

enum UpgradeTab { levelUp, evolution }

// =============================================================================
// UpgradeState
// =============================================================================

class UpgradeState {
  /// Currently selected monster ID (null = none selected).
  final String? selectedMonsterId;

  /// Active tab (level-up or evolution).
  final UpgradeTab activeTab;

  /// Whether an upgrade operation is in progress.
  final bool isProcessing;

  /// Flash message after a successful operation (auto-dismissed).
  final String? successMessage;

  const UpgradeState({
    this.selectedMonsterId,
    this.activeTab = UpgradeTab.levelUp,
    this.isProcessing = false,
    this.successMessage,
  });

  UpgradeState copyWith({
    String? selectedMonsterId,
    bool clearSelection = false,
    UpgradeTab? activeTab,
    bool? isProcessing,
    String? successMessage,
    bool clearMessage = false,
  }) {
    return UpgradeState(
      selectedMonsterId:
          clearSelection ? null : (selectedMonsterId ?? this.selectedMonsterId),
      activeTab: activeTab ?? this.activeTab,
      isProcessing: isProcessing ?? this.isProcessing,
      successMessage:
          clearMessage ? null : (successMessage ?? this.successMessage),
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

    final stageName = evolved.evolutionStage == 1 ? '1차 진화' : '최종 진화';
    state = state.copyWith(
      isProcessing: false,
      successMessage: '$stageName 성공!',
    );
    return true;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  MonsterModel? get _selectedMonster {
    final id = state.selectedMonsterId;
    if (id == null) return null;
    final roster = ref.read(monsterListProvider);
    try {
      return roster.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}

// =============================================================================
// Provider
// =============================================================================

final upgradeProvider =
    StateNotifierProvider<UpgradeNotifier, UpgradeState>(
  (ref) => UpgradeNotifier(ref),
);
