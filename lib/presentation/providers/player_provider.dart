import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gameapp/data/datasources/local_storage.dart';
import 'package:gameapp/data/models/player_model.dart';
import 'package:gameapp/data/static/stage_database.dart';

// =============================================================================
// PlayerState
// =============================================================================

/// Immutable state for the player provider.
class PlayerState {
  /// The loaded player, or `null` before [PlayerNotifier.loadPlayer] completes
  /// or when no player has been created yet.
  final PlayerModel? player;

  /// Whether the player data has been loaded from Hive (even if no record exists).
  final bool isLoaded;

  const PlayerState({
    this.player,
    this.isLoaded = false,
  });

  PlayerState copyWith({
    PlayerModel? player,
    bool? isLoaded,
    bool clearPlayer = false,
  }) {
    return PlayerState(
      player:   clearPlayer ? null : (player ?? this.player),
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  String toString() =>
      'PlayerState(player: ${player?.nickname}, isLoaded: $isLoaded)';
}

// =============================================================================
// PlayerNotifier
// =============================================================================

/// Manages all player-related state and persists changes to Hive via
/// [LocalStorage].
///
/// Call [loadPlayer] once during app initialisation (after
/// [LocalStorage.init()] has been awaited) to populate the state.
class PlayerNotifier extends StateNotifier<PlayerState> {
  PlayerNotifier() : super(const PlayerState());

  final LocalStorage _storage = LocalStorage.instance;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Reads the stored [PlayerModel] from Hive and updates the state.
  ///
  /// After this call, [PlayerState.isLoaded] will be `true` regardless of
  /// whether a player record was found.
  Future<void> loadPlayer() async {
    final player = _storage.getPlayer();
    state = PlayerState(player: player, isLoaded: true);
  }

  // ---------------------------------------------------------------------------
  // Player creation
  // ---------------------------------------------------------------------------

  /// Creates a brand-new player with the given [nickname], persists it to Hive,
  /// and replaces the current state.
  Future<void> createNewPlayer(String nickname) async {
    final player = await _storage.createPlayer(nickname: nickname);
    state = PlayerState(player: player, isLoaded: true);
  }

  // ---------------------------------------------------------------------------
  // Stage progression
  // ---------------------------------------------------------------------------

  /// Updates [PlayerModel.currentStageId] and, if the stage is the furthest
  /// the player has reached, also updates [PlayerModel.maxClearedStageId].
  ///
  /// Persists immediately.
  Future<void> updateStage(String stageId) async {
    final current = state.player;
    if (current == null) return;

    // Determine the highest cleared stage.  Compare by linear index to handle
    // multi-area IDs like '2-3' correctly.
    final bool isNewMax = _linearIndex(stageId) >
        _linearIndex(current.maxClearedStageId);

    final updated = current.copyWith(
      currentStageId:    stageId,
      maxClearedStageId: isNewMax ? stageId : null,
    );

    await _storage.savePlayer(updated);
    state = state.copyWith(player: updated);
  }

  /// Updates [PlayerModel.maxHardClearedStageId] for hard-mode clears.
  Future<void> updateHardStage(String stageId) async {
    final current = state.player;
    if (current == null) return;

    final isNewMax = _linearIndex(stageId) >
        _linearIndex(current.maxHardClearedStageId);
    if (!isNewMax) return;

    final updated = current.copyWith(maxHardClearedStageId: stageId);
    await _storage.savePlayer(updated);
    state = state.copyWith(player: updated);
  }

  // ---------------------------------------------------------------------------
  // Battle statistics
  // ---------------------------------------------------------------------------

  /// Increments [PlayerModel.totalBattleCount] and persists.
  Future<void> addBattleCount() async {
    final current = state.player;
    if (current == null) return;

    final updated = current.copyWith(
      totalBattleCount: current.totalBattleCount + 1,
    );

    await _storage.savePlayer(updated);
    state = state.copyWith(player: updated);
  }

  // ---------------------------------------------------------------------------
  // Session management
  // ---------------------------------------------------------------------------

  /// Updates [PlayerModel.lastOnlineAt] to the current time and persists.
  /// Replaces the current player model with [player] and updates state.
  void forceUpdate(PlayerModel player) {
    state = state.copyWith(player: player);
  }

  Future<void> updateLastOnline() async {
    final current = state.player;
    if (current == null) return;

    final updated = current.copyWith(lastOnlineAt: DateTime.now());
    await _storage.savePlayer(updated);
    state = state.copyWith(player: updated);
  }

  // ---------------------------------------------------------------------------
  // Experience & levelling
  // ---------------------------------------------------------------------------

  /// Adds [expAmount] to [PlayerModel.playerExp].
  ///
  /// Automatically levels up (and resets excess exp) when the threshold is
  /// reached.  Persists after any change.
  Future<void> addPlayerExp(int expAmount) async {
    final current = state.player;
    if (current == null) return;

    int newExp   = current.playerExp + expAmount;
    int newLevel = current.playerLevel;

    // Level-up loop: handles multiple level gains from a large exp award.
    // Cap at 999 to prevent infinite loops with huge exp awards.
    const maxPlayerLevel = 999;
    while (newLevel < maxPlayerLevel) {
      final threshold = PlayerModel.expForLevel(newLevel);
      if (newExp >= threshold) {
        newExp -= threshold;
        newLevel++;
      } else {
        break;
      }
    }

    // Grant 2 stat investment points per level gained.
    final levelsGained = newLevel - current.playerLevel;
    final pointsGained = levelsGained * 2;

    final updated = current.copyWith(
      playerExp:      newExp,
      playerLevel:    newLevel,
      heroStatPoints: current.heroStatPoints + pointsGained,
    );

    await _storage.savePlayer(updated);
    state = state.copyWith(player: updated);
  }

  // ---------------------------------------------------------------------------
  // Gacha statistics
  // ---------------------------------------------------------------------------

  /// Increments [PlayerModel.totalGachaPullCount] by [count] and persists.
  Future<void> addGachaPullCount(int count) async {
    final current = state.player;
    if (current == null) return;

    final updated = current.copyWith(
      totalGachaPullCount: current.totalGachaPullCount + count,
    );

    await _storage.savePlayer(updated);
    state = state.copyWith(player: updated);
  }

  // ---------------------------------------------------------------------------
  // Dungeon
  // ---------------------------------------------------------------------------

  /// Updates [PlayerModel.maxDungeonFloor] if [floor] is a new record.
  Future<void> updateMaxDungeonFloor(int floor) async {
    final current = state.player;
    if (current == null) return;
    if (floor <= current.maxDungeonFloor) return;

    final updated = current.copyWith(maxDungeonFloor: floor);
    await _storage.savePlayer(updated);
    state = state.copyWith(player: updated);
  }

  // ---------------------------------------------------------------------------
  // Team management (mirror of monster provider, player model side)
  // ---------------------------------------------------------------------------

  /// Updates [PlayerModel.teamMonsterIds] and persists.
  Future<void> updateTeamIds(List<String> ids) async {
    final current = state.player;
    if (current == null) return;

    final updated = current.copyWith(teamMonsterIds: List<String>.from(ids));
    await _storage.savePlayer(updated);
    state = state.copyWith(player: updated);
  }

  // ---------------------------------------------------------------------------
  // Collection rewards
  // ---------------------------------------------------------------------------

  Future<void> updateCollectionRewards(int bitmask) async {
    final current = state.player;
    if (current == null) return;

    final updated = current.copyWith(collectionRewardsClaimed: bitmask);
    await _storage.savePlayer(updated);
    state = state.copyWith(player: updated);
  }

  // ---------------------------------------------------------------------------
  // Tutorial
  // ---------------------------------------------------------------------------

  /// Advances the tutorial step if [step] is the next expected step.
  Future<void> advanceTutorial(int step) async {
    final current = state.player;
    if (current == null) return;
    if (current.tutorialStep >= step) return; // already past this step

    final updated = current.copyWith(tutorialStep: step);
    await _storage.savePlayer(updated);
    state = state.copyWith(player: updated);
  }

  /// Marks the tutorial as fully completed (step 99).
  Future<void> completeTutorial() async {
    await advanceTutorial(99);
  }

  // ---------------------------------------------------------------------------
  // Hero stat investment
  // ---------------------------------------------------------------------------

  /// Spends 1 hero stat point to permanently boost the given stat.
  /// [stat] must be one of 'atk', 'def', 'hp', 'spd'.
  Future<void> investHeroStat(String stat) async {
    final current = state.player;
    if (current == null) return;
    if (current.heroStatPoints <= 0) return;

    double atkAdd = 0, defAdd = 0, hpAdd = 0, spdAdd = 0;
    switch (stat) {
      case 'atk': atkAdd = 3.0;
      case 'def': defAdd = 2.0;
      case 'hp':  hpAdd  = 20.0;
      case 'spd': spdAdd = 1.0;
      default: return;
    }

    final updated = current.copyWith(
      heroStatPoints: current.heroStatPoints - 1,
      heroBaseAtk:   current.heroBaseAtk + atkAdd,
      heroBaseDef:   current.heroBaseDef + defAdd,
      heroBaseHp:    current.heroBaseHp  + hpAdd,
      heroBaseSpd:   current.heroBaseSpd + spdAdd,
    );

    await _storage.savePlayer(updated);
    state = state.copyWith(player: updated);
  }

  /// Generic update: apply [transform] to the current player and persist.
  Future<void> updatePlayer(PlayerModel Function(PlayerModel) transform) async {
    final current = state.player;
    if (current == null) return;
    final updated = transform(current);
    await _storage.savePlayer(updated);
    state = state.copyWith(player: updated);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static int _linearIndex(String stageId) =>
      StageDatabase.linearIndex(stageId);
}

// =============================================================================
// Provider
// =============================================================================

/// Global player provider.  Access via `ref.watch(playerProvider)` or
/// `ref.read(playerProvider.notifier)`.
final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>(
  (ref) => PlayerNotifier(),
);
