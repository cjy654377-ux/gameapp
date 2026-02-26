import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gameapp/data/datasources/local_storage.dart';
import 'package:gameapp/data/models/player_model.dart';

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
    while (true) {
      // expToNextLevel is a getter on PlayerModel: (200 * 1.15 * level).round()
      final threshold = current.copyWith(playerLevel: newLevel).expToNextLevel;
      if (newExp >= threshold) {
        newExp -= threshold;
        newLevel++;
      } else {
        break;
      }
    }

    final updated = current.copyWith(
      playerExp:   newExp,
      playerLevel: newLevel,
    );

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
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Converts a stage string ID (e.g. `'3-4'`) to a 1-based linear index.
  /// Returns 0 for empty / malformed strings so comparisons still work.
  static int _linearIndex(String stageId) {
    if (stageId.isEmpty) return 0;
    final parts = stageId.split('-');
    if (parts.length != 2) return 0;
    final area  = int.tryParse(parts[0]) ?? 0;
    final stage = int.tryParse(parts[1]) ?? 0;
    return (area - 1) * 6 + stage;
  }
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
