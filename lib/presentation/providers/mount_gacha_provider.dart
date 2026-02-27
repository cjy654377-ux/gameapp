import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:gameapp/core/constants/game_config.dart';
import 'package:gameapp/data/datasources/local_storage.dart';
import 'package:gameapp/data/models/mount_model.dart';
import 'package:gameapp/data/static/mount_database.dart';
import 'package:gameapp/domain/services/gacha_service.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';

// =============================================================================
// State
// =============================================================================

class MountGachaState {
  final int pityCount;
  final bool isAnimating;
  final List<MountPullResult> lastResults;
  final bool showResults;
  final int revealIndex;
  final int totalPulls;

  const MountGachaState({
    this.pityCount = 0,
    this.isAnimating = false,
    this.lastResults = const [],
    this.showResults = false,
    this.revealIndex = -1,
    this.totalPulls = 0,
  });

  MountGachaState copyWith({
    int? pityCount,
    bool? isAnimating,
    List<MountPullResult>? lastResults,
    bool? showResults,
    int? revealIndex,
    int? totalPulls,
  }) {
    return MountGachaState(
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

class MountGachaNotifier extends StateNotifier<MountGachaState> {
  MountGachaNotifier(this.ref) : super(const MountGachaState());

  final Ref ref;
  static const _uuid = Uuid();

  Future<bool> pullSingleWithGem() async {
    if (state.isAnimating) return false;

    final success = await ref.read(currencyProvider.notifier).spendMountGem(
          GameConfig.mountGachaCostGem1,
        );
    if (!success) return false;

    return _executeSinglePull();
  }

  Future<bool> pullTenWithGem() async {
    if (state.isAnimating) return false;

    final success = await ref.read(currencyProvider.notifier).spendMountGem(
          GameConfig.mountGachaCostGem10,
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

    final pull = GachaService.performMountPull(state.pityCount);
    final mount = _createMountFromTemplate(pull.result.template);

    await LocalStorage.instance.saveMount(mount);

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

    final pull = GachaService.performMountTenPull(state.pityCount);
    final mounts = pull.results
        .map((r) => _createMountFromTemplate(r.template))
        .toList();
    await LocalStorage.instance.saveMounts(mounts);

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

  MountModel _createMountFromTemplate(MountTemplate template) {
    return MountModel(
      id: _uuid.v4(),
      templateId: template.id,
      name: template.name,
      rarity: template.rarity,
      statType: template.statType,
      statValue: template.statValue,
      acquiredAt: DateTime.now(),
      description: template.description,
    );
  }
}

// =============================================================================
// Provider
// =============================================================================

final mountGachaProvider =
    StateNotifierProvider<MountGachaNotifier, MountGachaState>(
  (ref) => MountGachaNotifier(ref),
);
