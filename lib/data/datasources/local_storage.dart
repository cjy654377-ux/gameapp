import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/monster_model.dart';
import '../models/player_model.dart';
import '../models/currency_model.dart';

/// Keys used to store singleton documents in their respective boxes.
const String _kPlayerKey   = 'player';
const String _kCurrencyKey = 'currency';

/// Box names.
const String _kMonsterBoxName  = 'monsters';
const String _kPlayerBoxName   = 'player';
const String _kCurrencyBoxName = 'currency';

/// [LocalStorage] is a singleton that wraps all Hive persistence operations.
///
/// Usage:
/// ```dart
/// await LocalStorage.instance.init();
/// final player = LocalStorage.instance.getPlayer();
/// ```
class LocalStorage {
  LocalStorage._();

  static final LocalStorage instance = LocalStorage._();

  late Box<MonsterModel>  _monsterBox;
  late Box<PlayerModel>   _playerBox;
  late Box<CurrencyModel> _currencyBox;

  bool _initialised = false;

  // -------------------------------------------------------------------------
  // Initialisation
  // -------------------------------------------------------------------------

  /// Must be called once at app start, after [Hive.init] / [Hive.initFlutter].
  ///
  /// Registers all [TypeAdapter]s and opens every Hive box.
  Future<void> init() async {
    if (_initialised) return;

    // Register adapters (guard against double registration).
    if (!Hive.isAdapterRegistered(MonsterModelAdapter().typeId)) {
      Hive.registerAdapter(MonsterModelAdapter());
    }
    if (!Hive.isAdapterRegistered(PlayerModelAdapter().typeId)) {
      Hive.registerAdapter(PlayerModelAdapter());
    }
    if (!Hive.isAdapterRegistered(CurrencyModelAdapter().typeId)) {
      Hive.registerAdapter(CurrencyModelAdapter());
    }

    _monsterBox  = await Hive.openBox<MonsterModel>(_kMonsterBoxName);
    _playerBox   = await Hive.openBox<PlayerModel>(_kPlayerBoxName);
    _currencyBox = await Hive.openBox<CurrencyModel>(_kCurrencyBoxName);

    _initialised = true;
  }

  // -------------------------------------------------------------------------
  // Player CRUD
  // -------------------------------------------------------------------------

  /// Returns the stored [PlayerModel] or null if no player exists yet.
  PlayerModel? getPlayer() => _playerBox.get(_kPlayerKey);

  /// Persists [player] to the player box.
  Future<void> savePlayer(PlayerModel player) async {
    await _playerBox.put(_kPlayerKey, player);
  }

  /// Creates a brand-new player record and returns it.
  Future<PlayerModel> createPlayer({required String nickname}) async {
    final player = PlayerModel.newPlayer(
      id: const Uuid().v4(),
      nickname: nickname,
    );
    await savePlayer(player);
    return player;
  }

  /// Deletes the stored player (used for account reset / testing).
  Future<void> deletePlayer() async {
    await _playerBox.delete(_kPlayerKey);
  }

  // -------------------------------------------------------------------------
  // Currency CRUD
  // -------------------------------------------------------------------------

  /// Returns the stored [CurrencyModel] or the initial defaults.
  CurrencyModel getCurrency() =>
      _currencyBox.get(_kCurrencyKey) ?? CurrencyModel.initial();

  /// Persists [currency] to the currency box.
  Future<void> saveCurrency(CurrencyModel currency) async {
    await _currencyBox.put(_kCurrencyKey, currency);
  }

  /// Resets currency to new-player defaults.
  Future<CurrencyModel> resetCurrency() async {
    final defaults = CurrencyModel.initial();
    await saveCurrency(defaults);
    return defaults;
  }

  // -------------------------------------------------------------------------
  // Monster CRUD
  // -------------------------------------------------------------------------

  /// Returns all monsters stored in the collection.
  List<MonsterModel> getAllMonsters() => _monsterBox.values.toList();

  /// Returns a single monster by its [id], or null if not found.
  MonsterModel? getMonster(String id) => _monsterBox.get(id);

  /// Adds or updates a monster.  The monster's [id] is used as the box key.
  Future<void> saveMonster(MonsterModel monster) async {
    await _monsterBox.put(monster.id, monster);
  }

  /// Adds or updates several monsters in a single batch write.
  Future<void> saveMonsters(List<MonsterModel> monsters) async {
    final map = {for (final m in monsters) m.id: m};
    await _monsterBox.putAll(map);
  }

  /// Removes a monster from the collection.
  Future<void> deleteMonster(String id) async {
    await _monsterBox.delete(id);
  }

  /// Removes several monsters in a single batch delete.
  Future<void> deleteMonsters(List<String> ids) async {
    await _monsterBox.deleteAll(ids);
  }

  /// Returns monsters whose [MonsterModel.isInTeam] flag is true.
  List<MonsterModel> getTeamMonsters() =>
      _monsterBox.values.where((m) => m.isInTeam).toList();

  /// Updates the [isInTeam] flag for a set of monster IDs.
  ///
  /// Monsters with IDs in [teamIds] are marked as in-team; all others are
  /// marked as not-in-team.
  Future<void> updateTeam(List<String> teamIds) async {
    final teamSet = Set<String>.from(teamIds);
    final updates = <String, MonsterModel>{};

    for (final monster in _monsterBox.values) {
      final shouldBeInTeam = teamSet.contains(monster.id);
      if (monster.isInTeam != shouldBeInTeam) {
        updates[monster.id] = monster.copyWith(isInTeam: shouldBeInTeam);
      }
    }

    if (updates.isNotEmpty) {
      await _monsterBox.putAll(updates);
    }
  }

  // -------------------------------------------------------------------------
  // Bulk operations
  // -------------------------------------------------------------------------

  /// Writes player, currency, and all provided monsters in three awaited calls.
  Future<void> saveAll({
    PlayerModel? player,
    CurrencyModel? currency,
    List<MonsterModel>? monsters,
  }) async {
    final futures = <Future<void>>[];

    if (player != null) futures.add(savePlayer(player));
    if (currency != null) futures.add(saveCurrency(currency));
    if (monsters != null && monsters.isNotEmpty) {
      futures.add(saveMonsters(monsters));
    }

    await Future.wait(futures);
  }

  /// Loads the player, currency, and all monsters in one call.
  Future<({PlayerModel? player, CurrencyModel currency, List<MonsterModel> monsters})>
      loadAll() async {
    return (
      player:   getPlayer(),
      currency: getCurrency(),
      monsters: getAllMonsters(),
    );
  }

  // -------------------------------------------------------------------------
  // Utility
  // -------------------------------------------------------------------------

  /// Wipes every Hive box (useful for a full reset or logout).
  Future<void> clearAll() async {
    await Future.wait([
      _monsterBox.clear(),
      _playerBox.clear(),
      _currencyBox.clear(),
    ]);
  }

  /// Closes all open Hive boxes (call this during app teardown).
  Future<void> dispose() async {
    await Future.wait([
      _monsterBox.close(),
      _playerBox.close(),
      _currencyBox.close(),
    ]);
    _initialised = false;
  }
}
