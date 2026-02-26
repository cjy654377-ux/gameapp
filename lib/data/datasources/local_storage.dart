import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/guild_model.dart';
import '../models/monster_model.dart';
import '../models/player_model.dart';
import '../models/currency_model.dart';
import '../models/quest_model.dart';
import '../models/expedition_model.dart';
import '../models/relic_model.dart';

/// Keys used to store singleton documents in their respective boxes.
const String _kPlayerKey   = 'player';
const String _kCurrencyKey = 'currency';

/// Box names.
const String _kMonsterBoxName  = 'monsters';
const String _kPlayerBoxName   = 'player';
const String _kCurrencyBoxName = 'currency';
const String _kQuestBoxName    = 'quests';
const String _kRelicBoxName    = 'relics';
const String _kGuildBoxName       = 'guild';
const String _kGuildKey           = 'guild';
const String _kExpeditionBoxName  = 'expeditions';

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
  late Box<QuestModel>    _questBox;
  late Box<RelicModel>    _relicBox;
  late Box<GuildModel>    _guildBox;
  late Box<ExpeditionModel> _expeditionBox;

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
    if (!Hive.isAdapterRegistered(QuestModelAdapter().typeId)) {
      Hive.registerAdapter(QuestModelAdapter());
    }
    if (!Hive.isAdapterRegistered(RelicModelAdapter().typeId)) {
      Hive.registerAdapter(RelicModelAdapter());
    }
    if (!Hive.isAdapterRegistered(GuildModelAdapter().typeId)) {
      Hive.registerAdapter(GuildModelAdapter());
    }
    if (!Hive.isAdapterRegistered(ExpeditionModelAdapter().typeId)) {
      Hive.registerAdapter(ExpeditionModelAdapter());
    }

    _monsterBox  = await Hive.openBox<MonsterModel>(_kMonsterBoxName);
    _playerBox   = await Hive.openBox<PlayerModel>(_kPlayerBoxName);
    _currencyBox = await Hive.openBox<CurrencyModel>(_kCurrencyBoxName);
    _questBox    = await Hive.openBox<QuestModel>(_kQuestBoxName);
    _relicBox    = await Hive.openBox<RelicModel>(_kRelicBoxName);
    _guildBox    = await Hive.openBox<GuildModel>(_kGuildBoxName);
    _expeditionBox = await Hive.openBox<ExpeditionModel>(_kExpeditionBoxName);

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
  // Quest CRUD
  // -------------------------------------------------------------------------

  /// Returns all quest progress records.
  List<QuestModel> getAllQuests() => _questBox.values.toList();

  /// Returns quest progress by quest ID, or null.
  QuestModel? getQuest(String questId) => _questBox.get(questId);

  /// Saves or updates a single quest record.
  Future<void> saveQuest(QuestModel quest) async {
    await _questBox.put(quest.questId, quest);
  }

  /// Batch saves multiple quest records.
  Future<void> saveQuests(List<QuestModel> quests) async {
    final map = {for (final q in quests) q.questId: q};
    await _questBox.putAll(map);
  }

  /// Clears all quest progress data.
  Future<void> clearQuests() async {
    await _questBox.clear();
  }

  // -------------------------------------------------------------------------
  // Relic CRUD
  // -------------------------------------------------------------------------

  /// Returns all relics stored in the collection.
  List<RelicModel> getAllRelics() => _relicBox.values.toList();

  /// Returns a single relic by its [id], or null if not found.
  RelicModel? getRelic(String id) => _relicBox.get(id);

  /// Adds or updates a relic.
  Future<void> saveRelic(RelicModel relic) async {
    await _relicBox.put(relic.id, relic);
  }

  /// Batch saves multiple relics.
  Future<void> saveRelics(List<RelicModel> relics) async {
    final map = {for (final r in relics) r.id: r};
    await _relicBox.putAll(map);
  }

  /// Removes a relic from the collection.
  Future<void> deleteRelic(String id) async {
    await _relicBox.delete(id);
  }

  /// Clears all relics.
  Future<void> clearRelics() async {
    await _relicBox.clear();
  }

  // -------------------------------------------------------------------------
  // Guild CRUD
  // -------------------------------------------------------------------------

  /// Returns the stored guild or null.
  GuildModel? getGuild() => _guildBox.get(_kGuildKey);

  /// Persists the guild.
  Future<void> saveGuild(GuildModel guild) async {
    await _guildBox.put(_kGuildKey, guild);
  }

  /// Deletes the guild.
  Future<void> deleteGuild() async {
    await _guildBox.delete(_kGuildKey);
  }

  // -------------------------------------------------------------------------
  // Expedition CRUD
  // -------------------------------------------------------------------------

  List<ExpeditionModel> getAllExpeditions() => _expeditionBox.values.toList();

  Future<void> saveExpedition(ExpeditionModel exp) async {
    await _expeditionBox.put(exp.id, exp);
  }

  Future<void> deleteExpedition(String id) async {
    await _expeditionBox.delete(id);
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
      _questBox.clear(),
      _relicBox.clear(),
      _guildBox.clear(),
      _expeditionBox.clear(),
    ]);
  }

  // -------------------------------------------------------------------------
  // JSON backup / restore
  // -------------------------------------------------------------------------

  /// Exports all game data as a JSON string.
  String exportToJson() {
    final player = getPlayer();
    final currency = getCurrency();
    final monsters = getAllMonsters();
    final quests = getAllQuests();
    final relics = getAllRelics();

    final data = <String, dynamic>{
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      if (player != null)
        'player': {
          'id': player.id,
          'nickname': player.nickname,
          'playerLevel': player.playerLevel,
          'playerExp': player.playerExp,
          'currentStageId': player.currentStageId,
          'maxClearedStageId': player.maxClearedStageId,
          'teamMonsterIds': player.teamMonsterIds,
          'lastOnlineAt': player.lastOnlineAt.toIso8601String(),
          'createdAt': player.createdAt.toIso8601String(),
          'totalBattleCount': player.totalBattleCount,
          'totalGachaPullCount': player.totalGachaPullCount,
          'maxDungeonFloor': player.maxDungeonFloor,
          'prestigeLevel': player.prestigeLevel,
          'prestigeBonusPercent': player.prestigeBonusPercent,
          'tutorialStep': player.tutorialStep,
          'collectionRewardsClaimed': player.collectionRewardsClaimed,
        },
      'currency': {
        'gold': currency.gold,
        'diamond': currency.diamond,
        'monsterShard': currency.monsterShard,
        'expPotion': currency.expPotion,
        'gachaTicket': currency.gachaTicket,
      },
      'monsters': monsters
          .map((m) => {
                'id': m.id,
                'templateId': m.templateId,
                'name': m.name,
                'rarity': m.rarity,
                'element': m.element,
                'level': m.level,
                'experience': m.experience,
                'evolutionStage': m.evolutionStage,
                'baseAtk': m.baseAtk,
                'baseDef': m.baseDef,
                'baseHp': m.baseHp,
                'baseSpd': m.baseSpd,
                'acquiredAt': m.acquiredAt.toIso8601String(),
                'isInTeam': m.isInTeam,
                'size': m.size,
                'skillName': m.skillName,
                'awakeningStars': m.awakeningStars,
                'battleCount': m.battleCount,
              })
          .toList(),
      'quests': quests
          .map((q) => {
                'questId': q.questId,
                'currentProgress': q.currentProgress,
                'isCompleted': q.isCompleted,
                'resetAt': q.resetAt?.toIso8601String(),
              })
          .toList(),
      'relics': relics
          .map((r) => {
                'id': r.id,
                'templateId': r.templateId,
                'name': r.name,
                'type': r.type,
                'rarity': r.rarity,
                'statType': r.statType,
                'statValue': r.statValue,
                'equippedMonsterId': r.equippedMonsterId,
                'acquiredAt': r.acquiredAt.toIso8601String(),
              })
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Imports game data from a JSON string. Returns true on success.
  Future<bool> importFromJson(String jsonStr) async {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Clear existing data first.
      await clearAll();

      // Restore player.
      if (data.containsKey('player')) {
        final p = data['player'] as Map<String, dynamic>;
        final player = PlayerModel(
          id: p['id'] as String,
          nickname: p['nickname'] as String,
          playerLevel: p['playerLevel'] as int,
          playerExp: p['playerExp'] as int,
          currentStageId: p['currentStageId'] as String,
          maxClearedStageId: p['maxClearedStageId'] as String,
          teamMonsterIds: (p['teamMonsterIds'] as List).cast<String>(),
          lastOnlineAt: DateTime.parse(p['lastOnlineAt'] as String),
          createdAt: DateTime.parse(p['createdAt'] as String),
          totalBattleCount: p['totalBattleCount'] as int,
          totalGachaPullCount: p['totalGachaPullCount'] as int,
          maxDungeonFloor: p['maxDungeonFloor'] as int? ?? 0,
          prestigeLevel: p['prestigeLevel'] as int? ?? 0,
          prestigeBonusPercent:
              (p['prestigeBonusPercent'] as num?)?.toDouble() ?? 0.0,
          tutorialStep: p['tutorialStep'] as int? ?? 99,
          collectionRewardsClaimed:
              p['collectionRewardsClaimed'] as int? ?? 0,
        );
        await savePlayer(player);
      }

      // Restore currency.
      if (data.containsKey('currency')) {
        final c = data['currency'] as Map<String, dynamic>;
        final currency = CurrencyModel(
          gold: c['gold'] as int,
          diamond: c['diamond'] as int,
          monsterShard: c['monsterShard'] as int,
          expPotion: c['expPotion'] as int? ?? 0,
          gachaTicket: c['gachaTicket'] as int? ?? 0,
        );
        await saveCurrency(currency);
      }

      // Restore monsters.
      if (data.containsKey('monsters')) {
        final monsters = (data['monsters'] as List).map((m) {
          final map = m as Map<String, dynamic>;
          return MonsterModel(
            id: map['id'] as String,
            templateId: map['templateId'] as String,
            name: map['name'] as String,
            rarity: map['rarity'] as int,
            element: map['element'] as String,
            level: map['level'] as int,
            experience: map['experience'] as int? ?? 0,
            evolutionStage: map['evolutionStage'] as int? ?? 0,
            baseAtk: (map['baseAtk'] as num).toDouble(),
            baseDef: (map['baseDef'] as num).toDouble(),
            baseHp: (map['baseHp'] as num).toDouble(),
            baseSpd: (map['baseSpd'] as num).toDouble(),
            acquiredAt: map['acquiredAt'] != null
                ? DateTime.parse(map['acquiredAt'] as String)
                : DateTime.now(),
            isInTeam: map['isInTeam'] as bool? ?? false,
            size: map['size'] as String? ?? 'medium',
            skillName: map['skillName'] as String?,
            awakeningStars: map['awakeningStars'] as int? ?? 0,
            battleCount: map['battleCount'] as int? ?? 0,
          );
        }).toList();
        await saveMonsters(monsters);
      }

      // Restore quests.
      if (data.containsKey('quests')) {
        final quests = (data['quests'] as List).map((q) {
          final map = q as Map<String, dynamic>;
          return QuestModel(
            questId: map['questId'] as String,
            currentProgress: map['currentProgress'] as int? ?? 0,
            isCompleted: map['isCompleted'] as bool? ?? false,
            resetAt: map['resetAt'] != null
                ? DateTime.parse(map['resetAt'] as String)
                : null,
          );
        }).toList();
        await saveQuests(quests);
      }

      // Restore relics.
      if (data.containsKey('relics')) {
        final relics = (data['relics'] as List).map((r) {
          final map = r as Map<String, dynamic>;
          return RelicModel(
            id: map['id'] as String,
            templateId: map['templateId'] as String,
            name: map['name'] as String,
            type: map['type'] as String,
            rarity: map['rarity'] as int,
            statType: map['statType'] as String,
            statValue: (map['statValue'] as num).toDouble(),
            equippedMonsterId: map['equippedMonsterId'] as String?,
            acquiredAt: map['acquiredAt'] != null
                ? DateTime.parse(map['acquiredAt'] as String)
                : DateTime.now(),
          );
        }).toList();
        await saveRelics(relics);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Closes all open Hive boxes (call this during app teardown).
  Future<void> dispose() async {
    await Future.wait([
      _monsterBox.close(),
      _playerBox.close(),
      _currencyBox.close(),
      _questBox.close(),
      _relicBox.close(),
      _guildBox.close(),
      _expeditionBox.close(),
    ]);
    _initialised = false;
  }
}
