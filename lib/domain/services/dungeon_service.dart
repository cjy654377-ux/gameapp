import 'dart:math' as math;

import 'package:gameapp/data/static/monster_database.dart';
import 'package:gameapp/data/static/skill_database.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';

// Static service for the infinite dungeon system.
//
// Handles floor-based enemy scaling, random composition, and reward
// calculation. All methods are static — no state is held.

class DungeonService {
  DungeonService._();

  static final math.Random _random = math.Random();

  // ---------------------------------------------------------------------------
  // Enemy generation
  // ---------------------------------------------------------------------------

  /// Creates a set of enemies for the given dungeon [floor].
  ///
  /// * Enemy count: 2 on floors 1-5, 3 on floors 6+.
  /// * Enemy level: `5 + floor * 2`.
  /// * Templates are randomly selected from the full monster pool.
  static List<BattleMonster> createEnemiesForFloor(int floor) {
    final int enemyCount = floor <= 5 ? 2 : 3;
    final int enemyLevel = 5 + floor * 2;
    final double levelMult = 1.0 + (enemyLevel - 1) * 0.05;

    // Pick random templates (allow repeats).
    final templates = MonsterDatabase.all;
    final enemies = <BattleMonster>[];

    for (int i = 0; i < enemyCount; i++) {
      final template = templates[_random.nextInt(templates.length)];
      final double hp  = template.baseHp  * levelMult;
      final double atk = template.baseAtk * levelMult;
      final double def = template.baseDef * levelMult;
      final double spd = template.baseSpd * levelMult;

      final skill = SkillDatabase.findByTemplateId(template.id);
      enemies.add(BattleMonster(
        monsterId:  'dungeon_${template.id}_${floor}_$i',
        templateId: template.id,
        name:       '${template.name} Lv.$enemyLevel',
        element:    template.element,
        size:       template.size,
        rarity:     template.rarity,
        maxHp:      hp,
        currentHp:  hp,
        atk:        atk,
        def:        def,
        spd:        spd,
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

  /// Calculates accumulated rewards for clearing up to (and including)
  /// [floor].
  ///
  /// * Gold: `40 * floor` per floor (cumulative = `40 * floor * (floor+1) / 2`)
  /// * Exp:  `25 * floor` per floor
  /// * Bonus shard every 5 floors.
  static BattleReward calculateFloorReward(int floor) {
    final gold = (40 * floor).round();
    final exp  = (25 * floor).round();
    final shard = (floor % 5 == 0) ? 1 : null;
    return BattleReward(gold: gold, exp: exp, bonusShard: shard);
  }

  /// Returns the total accumulated reward from floor 1 to [floor].
  static BattleReward calculateTotalReward(int floor) {
    int totalGold = 0;
    int totalExp  = 0;
    int totalShard = 0;

    for (int f = 1; f <= floor; f++) {
      totalGold += (40 * f);
      totalExp  += (25 * f);
      if (f % 5 == 0) totalShard++;
    }

    return BattleReward(
      gold: totalGold,
      exp: totalExp,
      bonusShard: totalShard > 0 ? totalShard : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Between-floor healing
  // ---------------------------------------------------------------------------

  /// Applies 20% HP recovery to all alive monsters between floors.
  static void applyFloorHeal(List<BattleMonster> team) {
    for (final m in team) {
      if (m.isAlive) {
        m.currentHp = math.min(m.maxHp, m.currentHp + m.maxHp * 0.20);
        // Reset status effects between floors.
        m.burnTurns = 0;
        m.burnDamagePerTurn = 0;
        m.stunTurns = 0;
        // Reset skill cooldown for next floor.
        m.skillCooldown = m.skillMaxCooldown;
      }
    }
  }
}
