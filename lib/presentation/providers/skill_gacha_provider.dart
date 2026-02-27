import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:gameapp/core/constants/game_config.dart';
import 'package:gameapp/data/datasources/local_storage.dart';
import 'package:gameapp/data/models/equippable_skill_model.dart';
import 'package:gameapp/data/static/equippable_skill_database.dart';
import 'package:gameapp/domain/services/gacha_service.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';

// =============================================================================
// State
// =============================================================================

class SkillGachaState {
  final int pityCount;
  final bool isAnimating;
  final List<SkillPullResult> lastResults;
  final bool showResults;
  final int revealIndex;
  final int totalPulls;

  const SkillGachaState({
    this.pityCount = 0,
    this.isAnimating = false,
    this.lastResults = const [],
    this.showResults = false,
    this.revealIndex = -1,
    this.totalPulls = 0,
  });

  SkillGachaState copyWith({
    int? pityCount,
    bool? isAnimating,
    List<SkillPullResult>? lastResults,
    bool? showResults,
    int? revealIndex,
    int? totalPulls,
  }) {
    return SkillGachaState(
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

class SkillGachaNotifier extends StateNotifier<SkillGachaState> {
  SkillGachaNotifier(this.ref) : super(const SkillGachaState());

  final Ref ref;
  static const _uuid = Uuid();

  Future<bool> pullSingleWithTicket() async {
    if (state.isAnimating) return false;

    final success = await ref.read(currencyProvider.notifier).spendSkillTicket(
          GameConfig.skillGachaCostTicket1,
        );
    if (!success) return false;

    return _executeSinglePull();
  }

  Future<bool> pullTenWithTicket() async {
    if (state.isAnimating) return false;

    final success = await ref.read(currencyProvider.notifier).spendSkillTicket(
          GameConfig.skillGachaCostTicket10,
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

    final pull = GachaService.performSkillPull(state.pityCount);
    final skill = _createSkillFromTemplate(pull.result.template);

    await LocalStorage.instance.saveSkill(skill);

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

    final pull = GachaService.performSkillTenPull(state.pityCount);
    final skills = pull.results
        .map((r) => _createSkillFromTemplate(r.template))
        .toList();
    await LocalStorage.instance.saveSkills(skills);

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

  EquippableSkillModel _createSkillFromTemplate(EquippableSkillTemplate template) {
    return EquippableSkillModel(
      id: _uuid.v4(),
      templateId: template.id,
      name: template.name,
      rarity: template.rarity,
      skillType: template.skillType,
      value: template.value,
      cooldown: template.cooldown,
      acquiredAt: DateTime.now(),
      description: template.description,
    );
  }
}

// =============================================================================
// Provider
// =============================================================================

final skillGachaProvider =
    StateNotifierProvider<SkillGachaNotifier, SkillGachaState>(
  (ref) => SkillGachaNotifier(ref),
);
