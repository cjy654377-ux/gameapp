import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gameapp/data/datasources/local_storage.dart';
import 'package:gameapp/data/models/monster_model.dart';

// =============================================================================
// MonsterListNotifier
// =============================================================================

/// Manages the player's full monster roster and persists mutations to Hive.
///
/// Call [loadMonsters] once during app initialisation (after
/// [LocalStorage.init()] has been awaited).
class MonsterListNotifier extends StateNotifier<List<MonsterModel>> {
  MonsterListNotifier() : super(const []);

  final LocalStorage _storage = LocalStorage.instance;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Reads all [MonsterModel] records from Hive and replaces the current state.
  Future<void> loadMonsters() async {
    state = _storage.getAllMonsters();
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Adds [monster] to the roster and persists.
  ///
  /// If a monster with the same [MonsterModel.id] already exists it is replaced
  /// (acts as upsert).
  Future<void> addMonster(MonsterModel monster) async {
    final idx = state.indexWhere((m) => m.id == monster.id);
    final updated = List<MonsterModel>.from(state);
    if (idx >= 0) {
      updated[idx] = monster;
    } else {
      updated.add(monster);
    }
    await _storage.saveMonster(monster);
    state = updated;
  }

  /// Removes the monster with [id] from the roster and persists.
  ///
  /// Does nothing when no matching monster is found.
  Future<void> removeMonster(String id) async {
    final updated = state.where((m) => m.id != id).toList();
    await _storage.deleteMonster(id);
    state = updated;
  }

  /// Replaces the monster with the same [MonsterModel.id] as [monster] and
  /// persists.
  ///
  /// Does nothing when no matching monster is found.
  Future<void> updateMonster(MonsterModel monster) async {
    final idx = state.indexWhere((m) => m.id == monster.id);
    if (idx < 0) return;

    final updated = List<MonsterModel>.from(state);
    updated[idx] = monster;

    await _storage.saveMonster(monster);
    state = updated;
  }

  // ---------------------------------------------------------------------------
  // Team management
  // ---------------------------------------------------------------------------

  /// Returns the subset of the roster whose [MonsterModel.isInTeam] flag is
  /// `true`.
  List<MonsterModel> getTeamMonsters() =>
      state.where((m) => m.isInTeam).toList();

  /// Sets the battle team to the monsters identified by [ids].
  ///
  /// Monsters in [ids] have [MonsterModel.isInTeam] set to `true`; all others
  /// are set to `false`.  The change is persisted in a single batch write.
  Future<void> setTeam(List<String> ids) async {
    final teamSet = Set<String>.from(ids);
    final updated = state.map((m) {
      final shouldBeInTeam = teamSet.contains(m.id);
      if (m.isInTeam == shouldBeInTeam) return m;
      return m.copyWith(isInTeam: shouldBeInTeam);
    }).toList();

    // Persist via LocalStorage.updateTeam for efficient batch write.
    await _storage.updateTeam(ids);
    state = updated;
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  /// Persists the full current roster to Hive in a single batch write.
  ///
  /// Prefer the fine-grained [addMonster] / [updateMonster] / [removeMonster]
  /// helpers for most operations.  Use [save] when you need to flush multiple
  /// in-memory changes at once (e.g. after a gacha pull that modifies several
  /// monsters).
  Future<void> save() async {
    await _storage.saveMonsters(state);
  }
}

// =============================================================================
// Providers
// =============================================================================

/// Global monster roster provider.
///
/// Access via `ref.watch(monsterListProvider)` or
/// `ref.read(monsterListProvider.notifier)`.
final monsterListProvider =
    StateNotifierProvider<MonsterListNotifier, List<MonsterModel>>(
  (ref) => MonsterListNotifier(),
);

/// Derived provider that exposes only the monsters currently placed in the
/// battle team ([MonsterModel.isInTeam] == `true`).
///
/// Automatically updates whenever [monsterListProvider] changes.
final teamMonstersProvider = Provider<List<MonsterModel>>((ref) {
  final roster = ref.watch(monsterListProvider);
  return roster.where((m) => m.isInTeam).toList();
});
