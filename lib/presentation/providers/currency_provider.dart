import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gameapp/data/datasources/local_storage.dart';
import 'package:gameapp/data/models/currency_model.dart';

// =============================================================================
// CurrencyNotifier
// =============================================================================

/// Manages [CurrencyModel] state and persists every mutation to Hive.
///
/// Initialise by calling [load] after [LocalStorage.init()] resolves.
/// All `spend*` methods return `false` (and do nothing) when the player
/// cannot afford the operation.
class CurrencyNotifier extends StateNotifier<CurrencyModel> {
  CurrencyNotifier() : super(CurrencyModel.initial());

  final LocalStorage _storage = LocalStorage.instance;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Loads the persisted [CurrencyModel] from Hive, falling back to
  /// [CurrencyModel.initial()] when no record exists.
  Future<void> load() async {
    state = _storage.getCurrency();
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  /// Persists the current state to Hive.
  Future<void> save() async {
    await _storage.saveCurrency(state);
  }

  // ---------------------------------------------------------------------------
  // Gold
  // ---------------------------------------------------------------------------

  /// Adds [amount] gold (clamped to [0, 9 999 999] by [CurrencyModel.add]).
  Future<void> addGold(int amount) async {
    state = state.add(gold: amount);
    await save();
  }

  /// Deducts [amount] gold and returns `true` on success.
  ///
  /// Returns `false` without mutating state when the player cannot afford it.
  Future<bool> spendGold(int amount) async {
    if (!state.canAfford(gold: amount)) return false;
    state = state.add(gold: -amount);
    await save();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Diamond
  // ---------------------------------------------------------------------------

  Future<void> addDiamond(int amount) async {
    state = state.add(diamond: amount);
    await save();
  }

  Future<bool> spendDiamond(int amount) async {
    if (!state.canAfford(diamond: amount)) return false;
    state = state.add(diamond: -amount);
    await save();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Monster Shard
  // ---------------------------------------------------------------------------

  Future<void> addShard(int amount) async {
    state = state.add(monsterShard: amount);
    await save();
  }

  Future<bool> spendShard(int amount) async {
    if (!state.canAfford(monsterShard: amount)) return false;
    state = state.add(monsterShard: -amount);
    await save();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Exp Potion
  // ---------------------------------------------------------------------------

  Future<void> addExpPotion(int amount) async {
    state = state.add(expPotion: amount);
    await save();
  }

  Future<bool> spendExpPotion(int amount) async {
    if (!state.canAfford(expPotion: amount)) return false;
    state = state.add(expPotion: -amount);
    await save();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Gacha Ticket
  // ---------------------------------------------------------------------------

  Future<void> addGachaTicket(int amount) async {
    state = state.add(gachaTicket: amount);
    await save();
  }

  Future<bool> spendGachaTicket(int amount) async {
    if (!state.canAfford(gachaTicket: amount)) return false;
    state = state.add(gachaTicket: -amount);
    await save();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Skill Ticket
  // ---------------------------------------------------------------------------

  Future<void> addSkillTicket(int amount) async {
    state = state.add(skillTicket: amount);
    await save();
  }

  Future<bool> spendSkillTicket(int amount) async {
    if (!state.canAfford(skillTicket: amount)) return false;
    state = state.add(skillTicket: -amount);
    await save();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Relic Ticket
  // ---------------------------------------------------------------------------

  Future<void> addRelicTicket(int amount) async {
    state = state.add(relicTicket: amount);
    await save();
  }

  Future<bool> spendRelicTicket(int amount) async {
    if (!state.canAfford(relicTicket: amount)) return false;
    state = state.add(relicTicket: -amount);
    await save();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Mount Gem
  // ---------------------------------------------------------------------------

  Future<void> addMountGem(int amount) async {
    state = state.add(mountGem: amount);
    await save();
  }

  Future<bool> spendMountGem(int amount) async {
    if (!state.canAfford(mountGem: amount)) return false;
    state = state.add(mountGem: -amount);
    await save();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Bulk helpers
  // ---------------------------------------------------------------------------

  /// Adds multiple currencies in a single state update and one Hive write.
  ///
  /// Use this instead of multiple individual `add*` calls when awarding stage
  /// clear rewards to avoid redundant persistence calls.
  Future<void> addReward({
    int gold        = 0,
    int diamond     = 0,
    int monsterShard = 0,
    int expPotion   = 0,
    int gachaTicket = 0,
  }) async {
    state = state.add(
      gold:         gold,
      diamond:      diamond,
      monsterShard: monsterShard,
      expPotion:    expPotion,
      gachaTicket:  gachaTicket,
    );
    await save();
  }

  /// Resets all currencies to the new-player defaults and persists.
  Future<void> reset() async {
    state = await _storage.resetCurrency();
  }
}

// =============================================================================
// Provider
// =============================================================================

/// Global currency provider.  Access via `ref.watch(currencyProvider)` or
/// `ref.read(currencyProvider.notifier)`.
final currencyProvider =
    StateNotifierProvider<CurrencyNotifier, CurrencyModel>(
  (ref) => CurrencyNotifier(),
);
