import 'package:flutter_test/flutter_test.dart';
import 'package:gameapp/core/constants/game_config.dart';
import 'package:gameapp/data/models/monster_model.dart';
import 'package:gameapp/domain/services/upgrade_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a minimal MonsterModel for testing without any uuid dependency.
MonsterModel _makeMonster({
  String id = 'test-id',
  String templateId = 'tmpl-001',
  String name = 'TestMonster',
  int rarity = 1,
  String element = 'fire',
  int level = 1,
  int experience = 0,
  int evolutionStage = 0,
  double baseAtk = 100,
  double baseDef = 80,
  double baseHp = 500,
  double baseSpd = 60,
}) {
  return MonsterModel(
    id: id,
    templateId: templateId,
    name: name,
    rarity: rarity,
    element: element,
    level: level,
    experience: experience,
    evolutionStage: evolutionStage,
    baseAtk: baseAtk,
    baseDef: baseDef,
    baseHp: baseHp,
    baseSpd: baseSpd,
    acquiredAt: DateTime(2024, 1, 1),
    isInTeam: false,
    size: 'medium',
  );
}

// ---------------------------------------------------------------------------
// Test suite
// ---------------------------------------------------------------------------

void main() {
  group('UpgradeService', () {
    // -----------------------------------------------------------------------
    // levelUpGoldCost
    // -----------------------------------------------------------------------

    group('levelUpGoldCost', () {
      test('normal rarity at level 1 returns baseLevelUpGold * 1 * 1.0', () {
        final monster = _makeMonster(rarity: 1, level: 1);
        // expMultiplier for normal = 1.0
        // cost = (100 * 1 * 1.0).round() = 100
        expect(UpgradeService.levelUpGoldCost(monster), equals(100));
      });

      test('normal rarity scales linearly with level', () {
        final level5 = _makeMonster(rarity: 1, level: 5);
        final level10 = _makeMonster(rarity: 1, level: 10);
        // cost = (100 * level * 1.0).round()
        expect(UpgradeService.levelUpGoldCost(level5), equals(500));
        expect(UpgradeService.levelUpGoldCost(level10), equals(1000));
      });

      test('legendary rarity (expMultiplier=2.0) doubles the cost', () {
        final monster = _makeMonster(rarity: 5, level: 10);
        // cost = (100 * 10 * 2.0).round() = 2000
        expect(UpgradeService.levelUpGoldCost(monster), equals(2000));
      });

      test('rare rarity (expMultiplier=1.25) at level 4', () {
        final monster = _makeMonster(rarity: 3, level: 4);
        // cost = (100 * 4 * 1.25).round() = 500
        expect(UpgradeService.levelUpGoldCost(monster), equals(500));
      });

      test('epic rarity (expMultiplier=1.5) at level 20', () {
        final monster = _makeMonster(rarity: 4, level: 20);
        // cost = (100 * 20 * 1.5).round() = 3000
        expect(UpgradeService.levelUpGoldCost(monster), equals(3000));
      });

      test('cost increases with higher rarity at same level', () {
        const testLevel = 10;
        final normal = _makeMonster(rarity: 1, level: testLevel);
        final advanced = _makeMonster(rarity: 2, level: testLevel);
        final rare = _makeMonster(rarity: 3, level: testLevel);
        final epic = _makeMonster(rarity: 4, level: testLevel);
        final legendary = _makeMonster(rarity: 5, level: testLevel);

        expect(
          UpgradeService.levelUpGoldCost(normal) <
              UpgradeService.levelUpGoldCost(advanced),
          isTrue,
        );
        expect(
          UpgradeService.levelUpGoldCost(advanced) <
              UpgradeService.levelUpGoldCost(rare),
          isTrue,
        );
        expect(
          UpgradeService.levelUpGoldCost(rare) <
              UpgradeService.levelUpGoldCost(epic),
          isTrue,
        );
        expect(
          UpgradeService.levelUpGoldCost(epic) <
              UpgradeService.levelUpGoldCost(legendary),
          isTrue,
        );
      });
    });

    // -----------------------------------------------------------------------
    // canLevelUp
    // -----------------------------------------------------------------------

    group('canLevelUp', () {
      test('returns true when level is below maxMonsterLevel', () {
        final monster = _makeMonster(level: 1);
        expect(UpgradeService.canLevelUp(monster), isTrue);
      });

      test('returns true when level is one below maxMonsterLevel', () {
        final monster = _makeMonster(level: GameConfig.maxMonsterLevel - 1);
        expect(UpgradeService.canLevelUp(monster), isTrue);
      });

      test('returns false when level equals maxMonsterLevel', () {
        final monster = _makeMonster(level: GameConfig.maxMonsterLevel);
        expect(UpgradeService.canLevelUp(monster), isFalse);
      });

      test('returns false when level exceeds maxMonsterLevel', () {
        // Defensive: should not happen in practice but the guard must hold.
        final monster = _makeMonster(level: GameConfig.maxMonsterLevel + 1);
        expect(UpgradeService.canLevelUp(monster), isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // applyLevelUp
    // -----------------------------------------------------------------------

    group('applyLevelUp', () {
      test('increments level by exactly 1', () {
        final monster = _makeMonster(level: 5, experience: 200);
        final result = UpgradeService.applyLevelUp(monster);
        expect(result.level, equals(6));
      });

      test('resets experience to 0', () {
        final monster = _makeMonster(level: 5, experience: 350);
        final result = UpgradeService.applyLevelUp(monster);
        expect(result.experience, equals(0));
      });

      test('does not mutate the original monster', () {
        final monster = _makeMonster(level: 5, experience: 200);
        UpgradeService.applyLevelUp(monster);
        expect(monster.level, equals(5));
        expect(monster.experience, equals(200));
      });

      test('preserves all other fields unchanged', () {
        final monster = _makeMonster(
          id: 'abc',
          rarity: 3,
          element: 'water',
          evolutionStage: 1,
          baseAtk: 150,
          baseHp: 800,
        );
        final result = UpgradeService.applyLevelUp(monster);
        expect(result.id, equals(monster.id));
        expect(result.rarity, equals(monster.rarity));
        expect(result.element, equals(monster.element));
        expect(result.evolutionStage, equals(monster.evolutionStage));
        expect(result.baseAtk, equals(monster.baseAtk));
        expect(result.baseHp, equals(monster.baseHp));
      });
    });

    // -----------------------------------------------------------------------
    // expPerPotion
    // -----------------------------------------------------------------------

    group('expPerPotion', () {
      test('formula: 50 + level * 10 at level 1', () {
        final monster = _makeMonster(level: 1);
        expect(UpgradeService.expPerPotion(monster), equals(60));
      });

      test('formula: 50 + level * 10 at level 5', () {
        final monster = _makeMonster(level: 5);
        expect(UpgradeService.expPerPotion(monster), equals(100));
      });

      test('formula: 50 + level * 10 at level 10', () {
        final monster = _makeMonster(level: 10);
        expect(UpgradeService.expPerPotion(monster), equals(150));
      });

      test('formula: 50 + level * 10 at level 50', () {
        final monster = _makeMonster(level: 50);
        expect(UpgradeService.expPerPotion(monster), equals(550));
      });

      test('scales linearly — higher level yields more exp per potion', () {
        final low = _makeMonster(level: 1);
        final high = _makeMonster(level: 20);
        expect(
          UpgradeService.expPerPotion(high) >
              UpgradeService.expPerPotion(low),
          isTrue,
        );
      });
    });

    // -----------------------------------------------------------------------
    // applyExpPotions
    // -----------------------------------------------------------------------

    group('applyExpPotions', () {
      test('single potion that does not trigger a level-up accumulates exp',
          () {
        // level 1: expPerPotion = 60, expToNextLevel = (100*1.2*1).round() = 120
        // 1 potion -> 60 exp, below threshold of 120
        final monster = _makeMonster(level: 1, experience: 0);
        final result = UpgradeService.applyExpPotions(monster, 1);
        expect(result.level, equals(1));
        expect(result.experience, equals(60));
      });

      test('single potion that exactly triggers one level-up', () {
        // level 1: expPerPotion = 60, threshold = 120
        // monster already has 60 exp; 1 potion adds 60 -> total 120 = threshold
        // -> level becomes 2, leftover exp = 0
        final monster = _makeMonster(level: 1, experience: 60);
        final result = UpgradeService.applyExpPotions(monster, 1);
        expect(result.level, equals(2));
        expect(result.experience, equals(0));
      });

      test('multiple potions can trigger multiple level-ups', () {
        // level 1: expPerPotion=60, threshold for lvl1=120, threshold for lvl2=240
        // 10 potions -> 600 exp total
        // level 1 -> 2: consume 120 exp, left 480
        // level 2 -> 3: threshold=(100*1.2*2).round()=240, consume 240, left 240
        // level 3 -> 4: threshold=(100*1.2*3).round()=360, 240 < 360 -> stop at 3
        final monster = _makeMonster(level: 1, experience: 0);
        final result = UpgradeService.applyExpPotions(monster, 10);
        expect(result.level, equals(3));
        expect(result.experience, equals(240));
      });

      test('caps level at maxMonsterLevel and sets experience to 0', () {
        // Start near max level so enough potions push past the cap.
        final monster = _makeMonster(
          level: GameConfig.maxMonsterLevel - 1,
          experience: 0,
        );
        // One very large potion count is enough to overflow the last level.
        final result = UpgradeService.applyExpPotions(monster, 1000);
        expect(result.level, equals(GameConfig.maxMonsterLevel));
        expect(result.experience, equals(0));
      });

      test('returns monster unchanged when already at maxMonsterLevel', () {
        final monster = _makeMonster(
          level: GameConfig.maxMonsterLevel,
          experience: 50,
        );
        final result = UpgradeService.applyExpPotions(monster, 5);
        expect(result.level, equals(GameConfig.maxMonsterLevel));
        expect(result.experience, equals(50));
      });

      test('existing experience is preserved and added to potion exp', () {
        // level 1 monster with 50 exp, 1 potion adds 60 -> 110 exp, below 120
        final monster = _makeMonster(level: 1, experience: 50);
        final result = UpgradeService.applyExpPotions(monster, 1);
        expect(result.level, equals(1));
        expect(result.experience, equals(110));
      });

      test('does not mutate original monster', () {
        final monster = _makeMonster(level: 1, experience: 0);
        UpgradeService.applyExpPotions(monster, 5);
        expect(monster.level, equals(1));
        expect(monster.experience, equals(0));
      });

      test('expPerPotion is read from the starting level, not intermediate', () {
        // At level 1, expPerPotion = 60; 3 potions = 180 exp.
        // threshold for level 1 = 120, so 180 - 120 = 60 leftover -> level 2.
        // The 3 potions are all computed from the STARTING level 1 stat (60 each).
        final monster = _makeMonster(level: 1, experience: 0);
        final result = UpgradeService.applyExpPotions(monster, 3);
        expect(result.level, equals(2));
        expect(result.experience, equals(60));
      });
    });

    // -----------------------------------------------------------------------
    // evolutionShardCost
    // -----------------------------------------------------------------------

    group('evolutionShardCost', () {
      test('normal rarity stage 0: baseShards * 1.0 * 1', () {
        final monster = _makeMonster(rarity: 1, evolutionStage: 0);
        // (50 * 1.0 * 1).round() = 50
        expect(UpgradeService.evolutionShardCost(monster), equals(50));
      });

      test('normal rarity stage 1 costs twice as much as stage 0', () {
        final monster = _makeMonster(rarity: 1, evolutionStage: 1);
        // (50 * 1.0 * 2).round() = 100
        expect(UpgradeService.evolutionShardCost(monster), equals(100));
      });

      test('legendary rarity (shardsMultiplier=7.0) stage 0', () {
        final monster = _makeMonster(rarity: 5, evolutionStage: 0);
        // (50 * 7.0 * 1).round() = 350
        expect(UpgradeService.evolutionShardCost(monster), equals(350));
      });

      test('legendary rarity stage 1', () {
        final monster = _makeMonster(rarity: 5, evolutionStage: 1);
        // (50 * 7.0 * 2).round() = 700
        expect(UpgradeService.evolutionShardCost(monster), equals(700));
      });

      test('rare rarity (shardsMultiplier=2.5) stage 0', () {
        final monster = _makeMonster(rarity: 3, evolutionStage: 0);
        // (50 * 2.5 * 1).round() = 125
        expect(UpgradeService.evolutionShardCost(monster), equals(125));
      });

      test('cost increases with higher rarity at the same evolution stage', () {
        const stage = 0;
        final normal = _makeMonster(rarity: 1, evolutionStage: stage);
        final advanced = _makeMonster(rarity: 2, evolutionStage: stage);
        final rare = _makeMonster(rarity: 3, evolutionStage: stage);
        final epic = _makeMonster(rarity: 4, evolutionStage: stage);
        final legendary = _makeMonster(rarity: 5, evolutionStage: stage);

        expect(
          UpgradeService.evolutionShardCost(normal) <
              UpgradeService.evolutionShardCost(advanced),
          isTrue,
        );
        expect(
          UpgradeService.evolutionShardCost(advanced) <
              UpgradeService.evolutionShardCost(rare),
          isTrue,
        );
        expect(
          UpgradeService.evolutionShardCost(rare) <
              UpgradeService.evolutionShardCost(epic),
          isTrue,
        );
        expect(
          UpgradeService.evolutionShardCost(epic) <
              UpgradeService.evolutionShardCost(legendary),
          isTrue,
        );
      });
    });

    // -----------------------------------------------------------------------
    // canEvolve
    // -----------------------------------------------------------------------

    group('canEvolve', () {
      test('returns true when evolutionStage is 0 (below max)', () {
        final monster = _makeMonster(evolutionStage: 0);
        expect(UpgradeService.canEvolve(monster), isTrue);
      });

      test('returns true when evolutionStage is 1 (below max of 2)', () {
        final monster = _makeMonster(evolutionStage: 1);
        expect(UpgradeService.canEvolve(monster), isTrue);
      });

      test('returns false when evolutionStage equals maxEvolutionStage', () {
        final monster =
            _makeMonster(evolutionStage: GameConfig.maxEvolutionStage);
        expect(UpgradeService.canEvolve(monster), isFalse);
      });

      test('returns false when evolutionStage exceeds maxEvolutionStage', () {
        final monster =
            _makeMonster(evolutionStage: GameConfig.maxEvolutionStage + 1);
        expect(UpgradeService.canEvolve(monster), isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // applyEvolution
    // -----------------------------------------------------------------------

    group('applyEvolution', () {
      test('increments evolutionStage by 1', () {
        final monster = _makeMonster(evolutionStage: 0);
        final result = UpgradeService.applyEvolution(monster);
        expect(result.evolutionStage, equals(1));
      });

      test('can go from stage 1 to stage 2 (final form)', () {
        final monster = _makeMonster(evolutionStage: 1);
        final result = UpgradeService.applyEvolution(monster);
        expect(result.evolutionStage, equals(2));
      });

      test('does not mutate the original monster', () {
        final monster = _makeMonster(evolutionStage: 0);
        UpgradeService.applyEvolution(monster);
        expect(monster.evolutionStage, equals(0));
      });

      test('preserves all other fields unchanged', () {
        final monster = _makeMonster(
          id: 'evo-id',
          name: 'EvoMonster',
          rarity: 4,
          level: 30,
          experience: 75,
          evolutionStage: 0,
          baseHp: 1200,
        );
        final result = UpgradeService.applyEvolution(monster);
        expect(result.id, equals(monster.id));
        expect(result.name, equals(monster.name));
        expect(result.rarity, equals(monster.rarity));
        expect(result.level, equals(monster.level));
        expect(result.experience, equals(monster.experience));
        expect(result.baseHp, equals(monster.baseHp));
      });

      test('final-form monster has _evolutionMultiplier 1.6 applied to stats', () {
        // Confirm stat computation picks up the new stage via _evolutionMultiplier.
        // Stage 0: multiplier = 1.0; Stage 2: multiplier = 1.6
        final base = _makeMonster(evolutionStage: 0, baseHp: 1000, level: 1);
        final evolved = UpgradeService.applyEvolution(
          UpgradeService.applyEvolution(base),
        );
        expect(evolved.evolutionStage, equals(2));
        // finalHp = baseHp * _levelMultiplier(1) * _evolutionMultiplier(1.6)
        //         = 1000 * 1.0 * 1.6 = 1600
        expect(evolved.finalHp, closeTo(1600.0, 0.01));
      });
    });
  });
}
