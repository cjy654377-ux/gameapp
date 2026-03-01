import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:gameapp/core/constants/game_config.dart';
import 'package:gameapp/data/models/monster_model.dart';
import 'package:gameapp/data/static/monster_database.dart';
import 'package:gameapp/domain/services/gacha_service.dart'
    show GachaPullResult, GachaService, PickupBannerSchedule;
import 'package:gameapp/data/static/quest_database.dart';
import 'package:gameapp/domain/services/audio_service.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';
import 'package:gameapp/presentation/providers/monster_provider.dart';
import 'package:gameapp/presentation/providers/player_provider.dart';
import 'package:gameapp/presentation/providers/quest_provider.dart';
import 'package:gameapp/presentation/providers/gacha_history_provider.dart';
import 'package:gameapp/presentation/widgets/tutorial_overlay.dart';

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
      final nextIdx = state.revealIndex + 1;
      final result = state.lastResults[nextIdx];
      if (result.template.rarity >= 4) {
        AudioService.instance.playHighRarityReveal();
      } else {
        AudioService.instance.playCardReveal();
      }
      state = state.copyWith(revealIndex: nextIdx);
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
    AudioService.instance.playGachaPull();

    final banner = PickupBannerSchedule.current;
    final pull = GachaService.performSinglePull(
      state.pityCount,
      featuredIds: banner.featuredMonsterIds,
      rateUpMultiplier: banner.rateUpMultiplier,
    );
    final monster = _createMonsterFromTemplate(pull.result.template);

    await ref.read(monsterListProvider.notifier).addMonster(monster);
    await _incrementPlayerPullCount(1);
    _updateCollectProgress();

    // High rarity feedback (4-5 star).
    if (pull.result.template.rarity >= 4) {
      AudioService.instance.playHighRarityReveal();
    }

    state = state.copyWith(
      pityCount: pull.newPityCount,
      lastResults: [pull.result],
      showResults: true,
      revealIndex: 0,
      isAnimating: false,
      totalPulls: state.totalPulls + 1,
    );

    // Record history
    ref.read(gachaHistoryProvider.notifier).addEntries([
      GachaHistoryEntry(
        monsterName: pull.result.template.name,
        rarity: pull.result.template.rarity,
        element: pull.result.template.element,
        timestamp: DateTime.now(),
        isPity: pull.newPityCount == 0 && pull.result.template.rarity >= 5,
        isPickup: pull.result.wasPickup,
      ),
    ]);

    return true;
  }

  Future<bool> _executeTenPull() async {
    state = state.copyWith(isAnimating: true);
    AudioService.instance.playGachaPull();

    final banner = PickupBannerSchedule.current;
    final pull = GachaService.performTenPull(
      state.pityCount,
      featuredIds: banner.featuredMonsterIds,
      rateUpMultiplier: banner.rateUpMultiplier,
    );

    // Create all monsters first, then batch-add to roster (single Hive write).
    final monsterNotifier = ref.read(monsterListProvider.notifier);
    final newMonsters = pull.results
        .map((r) => _createMonsterFromTemplate(r.template))
        .toList();
    await monsterNotifier.addMonsters(newMonsters);
    await _incrementPlayerPullCount(10);
    _updateCollectProgress();

    state = state.copyWith(
      pityCount: pull.newPityCount,
      lastResults: pull.results,
      showResults: true,
      revealIndex: -1, // animation starts unrevealed
      isAnimating: false,
      totalPulls: state.totalPulls + 10,
    );

    // Record history
    final now = DateTime.now();
    ref.read(gachaHistoryProvider.notifier).addEntries(
      pull.results.map((r) => GachaHistoryEntry(
            monsterName: r.template.name,
            rarity: r.template.rarity,
            element: r.template.element,
            timestamp: now,
            isPickup: r.wasPickup,
          )).toList(),
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

  Future<void> _incrementPlayerPullCount(int count) async {
    await ref.read(playerProvider.notifier).addGachaPullCount(count);
    ref.read(questProvider.notifier).onTrigger(
          QuestTrigger.gachaPull,
          count: count,
        );
    // Advance tutorial after first gacha.
    final step = ref.read(playerProvider).player?.tutorialStep ?? 0;
    if (step <= TutorialSteps.gachaIntro) {
      ref.read(playerProvider.notifier).advanceTutorial(TutorialSteps.upgradeIntro);
    }
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
