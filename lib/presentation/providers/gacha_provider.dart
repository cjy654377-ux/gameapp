import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:gameapp/core/constants/game_config.dart';
import 'package:gameapp/data/models/monster_model.dart';
import 'package:gameapp/data/static/monster_database.dart';
import 'package:gameapp/domain/services/gacha_service.dart';
import 'package:gameapp/data/static/quest_database.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';
import 'package:gameapp/presentation/providers/monster_provider.dart';
import 'package:gameapp/presentation/providers/player_provider.dart';
import 'package:gameapp/presentation/providers/quest_provider.dart';

// =============================================================================
// GachaState
// =============================================================================

class GachaState {
  /// Number of pulls since the last legendary (for pity system).
  final int pityCount;

  /// Whether the pull animation is currently playing.
  final bool isAnimating;

  /// Results from the most recent pull (empty when none).
  final List<GachaPullResult> lastResults;

  /// Whether the results overlay is visible.
  final bool showResults;

  /// Index of the card currently being revealed in the animation.
  final int revealIndex;

  /// Total pulls performed in the current session (for display).
  final int totalPulls;

  const GachaState({
    this.pityCount = 0,
    this.isAnimating = false,
    this.lastResults = const [],
    this.showResults = false,
    this.revealIndex = -1,
    this.totalPulls = 0,
  });

  GachaState copyWith({
    int? pityCount,
    bool? isAnimating,
    List<GachaPullResult>? lastResults,
    bool? showResults,
    int? revealIndex,
    int? totalPulls,
  }) {
    return GachaState(
      pityCount: pityCount ?? this.pityCount,
      isAnimating: isAnimating ?? this.isAnimating,
      lastResults: lastResults ?? this.lastResults,
      showResults: showResults ?? this.showResults,
      revealIndex: revealIndex ?? this.revealIndex,
      totalPulls: totalPulls ?? this.totalPulls,
    );
  }

  /// Pulls remaining until pity guarantee.
  int get pityRemaining => GameConfig.pityThreshold - pityCount;
}

// =============================================================================
// GachaNotifier
// =============================================================================

class GachaNotifier extends StateNotifier<GachaState> {
  GachaNotifier(this.ref) : super(const GachaState());

  final Ref ref;
  static const _uuid = Uuid();

  // ---------------------------------------------------------------------------
  // Single pull (150 diamonds or 1 ticket)
  // ---------------------------------------------------------------------------

  /// Performs a single gacha pull using diamonds.
  /// Returns `true` if the pull was successful.
  Future<bool> pullSingleWithDiamond() async {
    if (state.isAnimating) return false;

    final currency = ref.read(currencyProvider.notifier);
    final success = await currency.spendDiamond(GameConfig.singlePullCostDiamond);
    if (!success) return false;

    return _executeSinglePull();
  }

  /// Performs a single gacha pull using a gacha ticket.
  /// Returns `true` if the pull was successful.
  Future<bool> pullSingleWithTicket() async {
    if (state.isAnimating) return false;

    final currency = ref.read(currencyProvider.notifier);
    final success = await currency.spendGachaTicket(1);
    if (!success) return false;

    return _executeSinglePull();
  }

  // ---------------------------------------------------------------------------
  // Ten pull (1350 diamonds)
  // ---------------------------------------------------------------------------

  /// Performs a 10x gacha pull using diamonds.
  /// Returns `true` if the pull was successful.
  Future<bool> pullTenWithDiamond() async {
    if (state.isAnimating) return false;

    final currency = ref.read(currencyProvider.notifier);
    final success = await currency.spendDiamond(GameConfig.tenPullCostDiamond);
    if (!success) return false;

    return _executeTenPull();
  }

  // ---------------------------------------------------------------------------
  // Dismiss results
  // ---------------------------------------------------------------------------

  void dismissResults() {
    state = state.copyWith(
      showResults: false,
      lastResults: const [],
      revealIndex: -1,
      isAnimating: false,
    );
  }

  /// Advance the reveal animation to show the next card.
  void revealNext() {
    if (state.revealIndex < state.lastResults.length - 1) {
      state = state.copyWith(revealIndex: state.revealIndex + 1);
    }
  }

  /// Instantly reveal all remaining cards.
  void revealAll() {
    state = state.copyWith(revealIndex: state.lastResults.length - 1);
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<bool> _executeSinglePull() async {
    state = state.copyWith(isAnimating: true);

    final pull = GachaService.performSinglePull(state.pityCount);
    final monster = _createMonsterFromTemplate(pull.result.template);

    await ref.read(monsterListProvider.notifier).addMonster(monster);
    _incrementPlayerPullCount(1);
    _updateCollectProgress();

    state = state.copyWith(
      pityCount: pull.newPityCount,
      lastResults: [pull.result],
      showResults: true,
      revealIndex: 0,
      isAnimating: false,
      totalPulls: state.totalPulls + 1,
    );

    return true;
  }

  Future<bool> _executeTenPull() async {
    state = state.copyWith(isAnimating: true);

    final pull = GachaService.performTenPull(state.pityCount);

    // Create all monsters first, then batch-add to roster (single Hive write).
    final monsterNotifier = ref.read(monsterListProvider.notifier);
    final newMonsters = pull.results
        .map((r) => _createMonsterFromTemplate(r.template))
        .toList();
    await monsterNotifier.addMonsters(newMonsters);
    _incrementPlayerPullCount(10);
    _updateCollectProgress();

    state = state.copyWith(
      pityCount: pull.newPityCount,
      lastResults: pull.results,
      showResults: true,
      revealIndex: -1, // animation starts unrevealed
      isAnimating: false,
      totalPulls: state.totalPulls + 10,
    );

    return true;
  }

  MonsterModel _createMonsterFromTemplate(MonsterTemplate template) {
    return MonsterModel.fromTemplate(
      id: _uuid.v4(),
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
  }

  void _incrementPlayerPullCount(int count) {
    ref.read(playerProvider.notifier).addGachaPullCount(count);
    ref.read(questProvider.notifier).onTrigger(
          QuestTrigger.gachaPull,
          count: count,
        );
  }

  void _updateCollectProgress() {
    final roster = ref.read(monsterListProvider);
    final uniqueCount = roster.map((m) => m.templateId).toSet().length;
    ref.read(questProvider.notifier).onTrigger(
          QuestTrigger.collectMonster,
          absoluteValue: uniqueCount,
        );
  }
}

// =============================================================================
// Provider
// =============================================================================

final gachaProvider = StateNotifierProvider<GachaNotifier, GachaState>(
  (ref) => GachaNotifier(ref),
);
