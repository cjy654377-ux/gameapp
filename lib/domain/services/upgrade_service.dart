import 'package:gameapp/core/constants/game_config.dart';
import 'package:gameapp/core/enums/monster_rarity.dart';
import 'package:gameapp/data/models/monster_model.dart';

/// Static upgrade / evolution logic.
///
/// All methods are pure — they compute costs, check preconditions,
/// and return new [MonsterModel] instances without side-effects.
class UpgradeService {
  UpgradeService._();

  // ---------------------------------------------------------------------------
  // Level-up (gold)
  // ---------------------------------------------------------------------------

  /// Gold cost to level up [monster] by one level.
  ///
  /// Formula: `baseLevelUpGold * currentLevel * rarityExpMultiplier`
  static int levelUpGoldCost(MonsterModel monster) {
    final multiplier = MonsterRarity.fromRarity(monster.rarity).expMultiplier;
    return (GameConfig.baseLevelUpGold * monster.level * multiplier).round();
  }

  /// Whether the monster can still gain levels.
  static bool canLevelUp(MonsterModel monster) =>
      monster.level < GameConfig.maxMonsterLevel;

  /// Returns a new [MonsterModel] with level incremented by one and
  /// experience reset to 0.
  static MonsterModel applyLevelUp(MonsterModel monster) {
    return monster.copyWith(
      level: monster.level + 1,
      experience: 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Exp potion usage
  // ---------------------------------------------------------------------------

  /// The amount of experience a single potion grants.
  ///
  /// Scales mildly with monster level so that potions stay useful.
  static int expPerPotion(MonsterModel monster) =>
      (50 + monster.level * 10).round();

  /// Applies [potionCount] potions to [monster], handling multi-level-ups.
  ///
  /// Returns the updated monster (capped at [GameConfig.maxMonsterLevel]).
  static MonsterModel applyExpPotions(MonsterModel monster, int potionCount) {
    if (!canLevelUp(monster)) return monster;

    int totalExp = monster.experience + expPerPotion(monster) * potionCount;
    int newLevel = monster.level;

    while (newLevel < GameConfig.maxMonsterLevel) {
      // Re-compute threshold for the tentative level.
      final threshold = _expToNextLevel(newLevel);
      if (totalExp >= threshold) {
        totalExp -= threshold;
        newLevel++;
      } else {
        break;
      }
    }

    // Clamp at max level with 0 excess exp.
    if (newLevel >= GameConfig.maxMonsterLevel) {
      return monster.copyWith(
        level: GameConfig.maxMonsterLevel,
        experience: 0,
      );
    }

    return monster.copyWith(level: newLevel, experience: totalExp);
  }

  // ---------------------------------------------------------------------------
  // Evolution
  // ---------------------------------------------------------------------------

  /// Monster shard cost to evolve [monster] to the next stage.
  static int evolutionShardCost(MonsterModel monster) {
    final multiplier =
        MonsterRarity.fromRarity(monster.rarity).shardsMultiplier;
    return (GameConfig.baseEvolutionShards *
            multiplier *
            (monster.evolutionStage + 1))
        .round();
  }

  /// Gold cost to evolve [monster] to the next stage.
  static int evolutionGoldCost(MonsterModel monster) {
    final multiplier =
        MonsterRarity.fromRarity(monster.rarity).shardsMultiplier;
    return (GameConfig.baseEvolutionGold *
            multiplier *
            (monster.evolutionStage + 1))
        .round();
  }

  /// Whether the monster can evolve further.
  static bool canEvolve(MonsterModel monster) =>
      monster.evolutionStage < GameConfig.maxEvolutionStage;

  /// Returns a new [MonsterModel] with evolution stage incremented.
  ///
  /// Stats recalculate automatically via the model's `_evolutionMultiplier`.
  static MonsterModel applyEvolution(MonsterModel monster) {
    return monster.copyWith(
      evolutionStage: monster.evolutionStage + 1,
    );
  }

  // ---------------------------------------------------------------------------
  // Stat preview helpers
  // ---------------------------------------------------------------------------

  /// Returns a map of stat names to (before, after) value pairs for a
  /// level-up preview.
  static Map<String, (double, double)> levelUpStatPreview(
      MonsterModel monster) {
    final after = applyLevelUp(monster);
    return {
      'HP': (monster.finalHp, after.finalHp),
      'ATK': (monster.finalAtk, after.finalAtk),
      'DEF': (monster.finalDef, after.finalDef),
      'SPD': (monster.finalSpd, after.finalSpd),
    };
  }

  /// Returns a map of stat names to (before, after) value pairs for an
  /// evolution preview.
  static Map<String, (double, double)> evolutionStatPreview(
      MonsterModel monster) {
    final after = applyEvolution(monster);
    return {
      'HP': (monster.finalHp, after.finalHp),
      'ATK': (monster.finalAtk, after.finalAtk),
      'DEF': (monster.finalDef, after.finalDef),
      'SPD': (monster.finalSpd, after.finalSpd),
    };
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Mirrors [MonsterModel.expToNextLevel] for a given level.
  static int _expToNextLevel(int level) => (100 * (1.2 * level)).round();
}
