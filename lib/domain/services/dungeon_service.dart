import 'dart:math' as math;

import 'package:gameapp/data/static/monster_database.dart';
import 'package:gameapp/data/static/skill_database.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';

// Static service for the infinite dungeon system.
//
// Handles floor-based enemy scaling, random composition, and reward
// calculation. All methods are static — no state is held.

// =============================================================================
// FloorType
// =============================================================================

/// The special classification of a dungeon floor.
enum FloorType {
  /// Standard combat floor.
  normal,

  /// Every 10th floor — one powerful boss enemy, 2× rewards.
  boss,

  /// Floors 7, 17, 27, … — no enemies, 3× gold, 0 exp.
  treasure,

  /// Floors 5, 15, 25, … (but not 10, 20, …) — standard enemies + 50% heal.
  healing,
}

class DungeonService {
  DungeonService._();

  static final math.Random _random = math.Random();

  // ---------------------------------------------------------------------------
  // Floor type classification
  // ---------------------------------------------------------------------------

  /// Returns the [FloorType] for the given [floor] number.
  ///
  /// * floor % 10 == 0 → boss
  /// * floor % 10 == 7 → treasure  (7, 17, 27, 37, …)
  /// * floor % 5  == 0 && floor % 10 != 0 → healing  (5, 15, 25, 35, …)
  /// * otherwise → normal
  static FloorType getFloorType(int floor) {
    if (floor % 10 == 0) return FloorType.boss;
    if (floor % 10 == 7) return FloorType.treasure;
    if (floor % 5 == 0)  return FloorType.healing;
    return FloorType.normal;
  }

  // ---------------------------------------------------------------------------
  // Enemy generation
  // ---------------------------------------------------------------------------

  /// Creates a set of enemies for the given dungeon [floor].
  ///
  /// * Boss floor: 1 enemy with 3× stat multiplier.
  /// * Treasure floor: empty list (no combat).
  /// * Healing / normal: 2 enemies on floors 1-5, 3 on floors 6+.
  /// * Enemy level: `5 + floor * 1.8` (rounded).
  static List<BattleMonster> createEnemiesForFloor(int floor) {
    final floorType  = getFloorType(floor);
    final int        enemyLevel = (5 + floor * 1.8).round();
    final double     levelMult  = 1.0 + (enemyLevel - 1) * 0.05;

    // Treasure floor — no combat.
    if (floorType == FloorType.treasure) return [];

    final templates = MonsterDatabase.all;

    // Boss floor — single enemy with bossMult.
    if (floorType == FloorType.boss) {
      const double bossMult = 3.0;
      final template = templates[_random.nextInt(templates.length)];
      final double hp  = template.baseHp  * levelMult * bossMult;
      final double atk = template.baseAtk * levelMult * bossMult;
      final double def = template.baseDef * levelMult * bossMult;
      final double spd = template.baseSpd * levelMult;

      final skill = SkillDatabase.findByTemplateId(template.id);
      return [
        BattleMonster(
          monsterId:        'dungeon_${template.id}_${floor}_boss',
          templateId:       template.id,
          name:             '[보스] ${template.name} Lv.$enemyLevel',
          element:          template.element,
          size:             template.size,
          rarity:           template.rarity,
          maxHp:            hp,
          currentHp:        hp,
          atk:              atk,
          def:              def,
          spd:              spd,
          skillId:          skill?.id,
          skillName:        skill?.name,
          skillCooldown:    skill?.cooldown ?? 0,
          skillMaxCooldown: skill?.cooldown ?? 0,
        ),
      ];
    }

    // Normal / healing floor.
    final int enemyCount = floor <= 5 ? 2 : 3;
    final enemies = <BattleMonster>[];

    for (int i = 0; i < enemyCount; i++) {
      final template = templates[_random.nextInt(templates.length)];
      final double hp  = template.baseHp  * levelMult;
      final double atk = template.baseAtk * levelMult;
      final double def = template.baseDef * levelMult;
      final double spd = template.baseSpd * levelMult;

      final skill = SkillDatabase.findByTemplateId(template.id);
      enemies.add(BattleMonster(
        monsterId:        'dungeon_${template.id}_${floor}_$i',
        templateId:       template.id,
        name:             '${template.name} Lv.$enemyLevel',
        element:          template.element,
        size:             template.size,
        rarity:           template.rarity,
        maxHp:            hp,
        currentHp:        hp,
        atk:              atk,
        def:              def,
        spd:              spd,
        skillId:          skill?.id,
        skillName:        skill?.name,
        skillCooldown:    skill?.cooldown ?? 0,
        skillMaxCooldown: skill?.cooldown ?? 0,
      ));
    }

    return enemies;
  }

  // ---------------------------------------------------------------------------
  // Floor rewards
  // ---------------------------------------------------------------------------

  /// Calculates the reward for clearing [floor].
  ///
  /// * Boss floor:    gold 2×, exp 2×, shard every 10 floors.
  /// * Treasure floor: gold 3×, exp 0.
  /// * Other floors:  gold = 40×floor, exp = 25×floor, shard every 5 floors.
  static BattleReward calculateFloorReward(int floor) {
    final floorType = getFloorType(floor);

    switch (floorType) {
      case FloorType.boss:
        final gold  = (40 * floor * 2).round();
        final exp   = (25 * floor * 2).round();
        final shard = (floor % 10 == 0) ? 1 : null;
        return BattleReward(gold: gold, exp: exp, bonusShard: shard);

      case FloorType.treasure:
        final gold = (40 * floor * 3).round();
        return BattleReward(gold: gold, exp: 0, bonusShard: null);

      case FloorType.healing:
      case FloorType.normal:
        final gold  = (40 * floor).round();
        final exp   = (25 * floor).round();
        final shard = (floor % 5 == 0) ? 1 : null;
        return BattleReward(gold: gold, exp: exp, bonusShard: shard);
    }
  }

  /// Returns the total accumulated reward from floor 1 to [floor].
  static BattleReward calculateTotalReward(int floor) {
    int totalGold  = 0;
    int totalExp   = 0;
    int totalShard = 0;

    for (int f = 1; f <= floor; f++) {
      final r = calculateFloorReward(f);
      totalGold  += r.gold;
      totalExp   += r.exp;
      totalShard += r.bonusShard ?? 0;
    }

    return BattleReward(
      gold:        totalGold,
      exp:         totalExp,
      bonusShard:  totalShard > 0 ? totalShard : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Between-floor healing
  // ---------------------------------------------------------------------------

  /// Applies HP recovery to all alive monsters between floors.
  ///
  /// * [healPercent] defaults to 0.25 (25%) for normal floors.
  /// * Pass 0.50 for healing floors.
  static void applyFloorHeal(List<BattleMonster> team, {double healPercent = 0.25}) {
    for (final m in team) {
      if (m.isAlive) {
        m.currentHp = math.min(m.maxHp, m.currentHp + m.maxHp * healPercent);
        // Reset status effects between floors.
        m.burnTurns        = 0;
        m.burnDamagePerTurn = 0;
        m.stunTurns        = 0;
        // Reset skill cooldown for next floor.
        m.skillCooldown = m.skillMaxCooldown;
      }
    }
  }

  /// Convenience wrapper: applies 50% HP recovery for healing floors.
  static void applyHealingFloor(List<BattleMonster> team) =>
      applyFloorHeal(team, healPercent: 0.50);
}
