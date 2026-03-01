import 'dart:math' as math;

import 'package:gameapp/data/static/monster_database.dart';
import 'package:gameapp/data/static/skill_database.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';

/// Static service for the Tower of Challenge (도전의 탑).
///
/// 50 floors total, weekly reset, no healing between floors,
/// harder scaling than infinite dungeon, boss floors every 10.
class TowerService {
  TowerService._();

  static final math.Random _random = math.Random();

  static const int maxFloor = 50;
  static const int maxWeeklyAttempts = 3;

  // ---------------------------------------------------------------------------
  // Enemy generation (harder than dungeon)
  // ---------------------------------------------------------------------------

  static List<BattleMonster> createEnemiesForFloor(int floor) {
    final bool isBoss = floor % 10 == 0;
    final int enemyCount = isBoss ? 1 : (floor <= 10 ? 2 : 3);
    final int enemyLevel = (8 + floor * 2.5).round();
    final double levelCoeff = floor <= 30 ? 0.06 : (floor <= 40 ? 0.08 : 0.10);
    final double levelMult = 1.0 + (enemyLevel - 1) * levelCoeff;
    final double bossMult = isBoss
        ? (floor <= 30 ? 3.0 : (floor <= 40 ? 3.5 : 4.0))
        : 1.0;

    final templates = MonsterDatabase.all;
    final enemies = <BattleMonster>[];

    for (int i = 0; i < enemyCount; i++) {
      final template = templates[_random.nextInt(templates.length)];
      final double hp  = template.baseHp  * levelMult * bossMult;
      final double atk = template.baseAtk * levelMult * bossMult * 0.8;
      final double def = template.baseDef * levelMult * bossMult * 0.7;
      final double spd = template.baseSpd * levelMult;

      final skill = SkillDatabase.findByTemplateId(template.id);
      final name = isBoss
          ? 'BOSS ${template.name} Lv.$enemyLevel'
          : '${template.name} Lv.$enemyLevel';

      enemies.add(BattleMonster(
        monsterId:  'tower_${template.id}_${floor}_$i',
        templateId: template.id,
        name:       name,
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
  // Floor rewards (fixed per floor)
  // ---------------------------------------------------------------------------

  static TowerFloorReward getFloorReward(int floor) {
    // Milestone floors give better rewards
    if (floor == 50) {
      return const TowerFloorReward(gold: 10000, diamond: 50, gachaTicket: 3);
    }
    if (floor == 40) {
      return const TowerFloorReward(gold: 7000, diamond: 25, gachaTicket: 2);
    }
    if (floor == 30) {
      return const TowerFloorReward(gold: 5000, diamond: 30, gachaTicket: 3);
    }
    if (floor == 20) {
      return const TowerFloorReward(gold: 3000, diamond: 15, gachaTicket: 1);
    }
    if (floor == 10) {
      return const TowerFloorReward(gold: 2000, diamond: 10);
    }
    if (floor % 5 == 0) {
      final scale = floor > 30 ? 1.5 : 1.0;
      return TowerFloorReward(gold: (500 * (floor ~/ 5) * scale).round(), diamond: floor > 30 ? 8 : 5);
    }
    final defaultScale = floor > 40 ? 2.0 : (floor > 30 ? 1.5 : 1.0);
    return TowerFloorReward(gold: (100 * floor * defaultScale).round(), exp: (50 * floor * defaultScale).round());
  }

  // ---------------------------------------------------------------------------
  // Weekly reset check
  // ---------------------------------------------------------------------------

  /// Returns true if [lastDate] is in a different week than now.
  static bool shouldResetWeekly(DateTime? lastDate) {
    if (lastDate == null) return true;
    final now = DateTime.now();
    // Find this week's Monday 00:00
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
    return lastDay.isBefore(monday);
  }
}

/// Reward for a single tower floor.
class TowerFloorReward {
  final int gold;
  final int exp;
  final int diamond;
  final int gachaTicket;

  const TowerFloorReward({
    this.gold = 0,
    this.exp = 0,
    this.diamond = 0,
    this.gachaTicket = 0,
  });
}
