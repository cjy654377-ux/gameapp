import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:gameapp/core/constants/game_config.dart';
import 'package:gameapp/data/models/relic_model.dart';
import 'package:gameapp/data/static/relic_database.dart';
import 'package:gameapp/domain/services/gacha_service.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';
import 'package:gameapp/presentation/providers/relic_provider.dart';

// =============================================================================
// State
// =============================================================================

class RelicGachaState {
  final int pityCount;
  final bool isAnimating;
  final List<RelicPullResult> lastResults;
  final bool showResults;
  final int revealIndex;
  final int totalPulls;

  const RelicGachaState({
    this.pityCount = 0,
    this.isAnimating = false,
    this.lastResults = const [],
    this.showResults = false,
    this.revealIndex = -1,
    this.totalPulls = 0,
  });

  RelicGachaState copyWith({
    int? pityCount,
    bool? isAnimating,
    List<RelicPullResult>? lastResults,
    bool? showResults,
    int? revealIndex,
    int? totalPulls,
  }) {
    return RelicGachaState(
      pityCount: pityCount ?? this.pityCount,
      isAnimating: isAnimating ?? this.isAnimating,
      lastResults: lastResults ?? this.lastResults,
      showResults: showResults ?? this.showResults,
      revealIndex: revealIndex ?? this.revealIndex,
      totalPulls: totalPulls ?? this.totalPulls,
    );
  }

  int get pityRemaining => GameConfig.pityThreshold - pityCount;
}

// =============================================================================
// Notifier
// =============================================================================

class RelicGachaNotifier extends StateNotifier<RelicGachaState> {
  RelicGachaNotifier(this.ref) : super(const RelicGachaState());

  final Ref ref;
  static const _uuid = Uuid();

  Future<bool> pullSingleWithTicket() async {
    if (state.isAnimating) return false;

    final success = await ref.read(currencyProvider.notifier).spendRelicTicket(
          GameConfig.relicGachaCostTicket1,
        );
    if (!success) return false;

    return _executeSinglePull();
  }

  Future<bool> pullTenWithTicket() async {
    if (state.isAnimating) return false;

    final success = await ref.read(currencyProvider.notifier).spendRelicTicket(
          GameConfig.relicGachaCostTicket10,
        );
    if (!success) return false;

    return _executeTenPull();
  }

  void dismissResults() {
    state = state.copyWith(
      showResults: false,
      lastResults: const [],
      revealIndex: -1,
      isAnimating: false,
    );
  }

  void revealNext() {
    if (state.revealIndex < state.lastResults.length - 1) {
      state = state.copyWith(revealIndex: state.revealIndex + 1);
    }
  }

  void revealAll() {
    state = state.copyWith(revealIndex: state.lastResults.length - 1);
  }

  // ---------------------------------------------------------------------------

  Future<bool> _executeSinglePull() async {
    state = state.copyWith(isAnimating: true);

    final pull = GachaService.performRelicPull(state.pityCount);
    final relic = _createRelicFromTemplate(pull.result.template);

    await ref.read(relicProvider.notifier).addRelic(relic);

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

    final pull = GachaService.performRelicTenPull(state.pityCount);
    final relicNotifier = ref.read(relicProvider.notifier);

    for (final r in pull.results) {
      final relic = _createRelicFromTemplate(r.template);
      await relicNotifier.addRelic(relic);
    }

    state = state.copyWith(
      pityCount: pull.newPityCount,
      lastResults: pull.results,
      showResults: true,
      revealIndex: -1,
      isAnimating: false,
      totalPulls: state.totalPulls + 10,
    );

    return true;
  }

  RelicModel _createRelicFromTemplate(RelicTemplate template) {
    return RelicModel(
      id: _uuid.v4(),
      templateId: template.id,
      name: template.name,
      type: template.type,
      rarity: template.rarity,
      statType: template.statType,
      statValue: template.statValue,
      acquiredAt: DateTime.now(),
    );
  }
}

// =============================================================================
// Provider
// =============================================================================

final relicGachaProvider =
    StateNotifierProvider<RelicGachaNotifier, RelicGachaState>(
  (ref) => RelicGachaNotifier(ref),
);
