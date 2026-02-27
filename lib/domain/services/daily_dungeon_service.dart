import 'dart:math';

import '../../data/static/monster_database.dart';
import '../../data/static/skill_database.dart';
import '../entities/battle_entity.dart';

/// Daily bonus dungeon: element-themed floors with boosted rewards.
/// Each day of the week features a different element.
class DailyDungeonService {
  DailyDungeonService._();

  /// Max floors per daily dungeon run.
  static const maxFloors = 10;

  /// Daily attempts allowed.
  static const maxAttempts = 2;

  /// Reward multiplier compared to normal dungeon.
  static const rewardMultiplier = 1.5;

  /// Element rotation: Mon=fire, Tue=water, Wed=electric, Thu=stone,
  /// Fri=grass, Sat=dark, Sun=light.
  static const _weekdayElements = [
    'fire',     // Monday (1)
    'water',    // Tuesday (2)
    'electric', // Wednesday (3)
    'stone',    // Thursday (4)
    'grass',    // Friday (5)
    'dark',     // Saturday (6)
    'light',    // Sunday (7)
  ];

  /// Today's featured element.
  static String get todayElement {
    final weekday = DateTime.now().weekday; // 1=Mon..7=Sun
    return _weekdayElements[weekday - 1];
  }

  /// Korean element name.
  static String elementNameKo(String element) {
    const map = {
      'fire': '불',
      'water': '물',
      'electric': '번개',
      'stone': '바위',
      'grass': '풀',
      'dark': '암흑',
      'light': '빛',
      'ghost': '유령',
    };
    return map[element] ?? element;
  }

  /// English element name.
  static String elementNameEn(String element) {
    const map = {
      'fire': 'Fire',
      'water': 'Water',
      'electric': 'Electric',
      'stone': 'Stone',
      'grass': 'Grass',
      'dark': 'Dark',
      'light': 'Light',
      'ghost': 'Ghost',
    };
    return map[element] ?? element;
  }

  /// Create enemies for a floor, filtered to today's element.
  static List<BattleMonster> createEnemiesForFloor(int floor, String element) {
    final rng = Random();
    final count = floor <= 5 ? 2 : 3;
    final enemyLevel = (8 + floor * 2.0).round();
    final levelMul = 1.0 + (enemyLevel - 1) * 0.05;

    // Filter templates by element.
    final templates = MonsterDatabase.all
        .where((t) => t.element == element)
        .toList();

    // Fallback to all if not enough of that element.
    final pool = templates.isEmpty ? MonsterDatabase.all : templates;

    final enemies = <BattleMonster>[];
    for (int i = 0; i < count; i++) {
      final t = pool[rng.nextInt(pool.length)];
      final skill = SkillDatabase.findByTemplateId(t.id);
      final hp = t.baseHp * levelMul * 1.2;
      final atk = t.baseAtk * levelMul * 1.1;
      final def = t.baseDef * levelMul * 1.1;
      final spd = t.baseSpd * levelMul;

      enemies.add(BattleMonster(
        monsterId: 'dd_${t.id}_${floor}_$i',
        templateId: t.id,
        name: '${t.name} Lv.$enemyLevel',
        element: t.element,
        size: t.size,
        rarity: t.rarity,
        maxHp: hp,
        currentHp: hp,
        atk: atk,
        def: def,
        spd: spd,
        skillId: skill?.id,
        skillName: skill?.name,
        skillCooldown: skill?.cooldown ?? 0,
        skillMaxCooldown: skill?.cooldown ?? 0,
      ));
    }
    return enemies;
  }

  /// Floor reward (boosted vs normal dungeon).
  static ({int gold, int exp}) calculateFloorReward(int floor) {
    final gold = (50 * floor * rewardMultiplier).round();
    final exp = (35 * floor * rewardMultiplier).round();
    return (gold: gold, exp: exp);
  }

  /// Total accumulated reward from floor 1 to [floor].
  static ({int gold, int exp, int shard}) calculateTotalReward(int floor) {
    int totalGold = 0;
    int totalExp = 0;
    int totalShard = 0;
    for (int f = 1; f <= floor; f++) {
      final r = calculateFloorReward(f);
      totalGold += r.gold;
      totalExp += r.exp;
      if (f % 3 == 0) totalShard++; // Shard every 3 floors (more generous)
    }
    return (gold: totalGold, exp: totalExp, shard: totalShard);
  }

  /// 25% HP heal between floors + reset status effects.
  static List<BattleMonster> applyFloorHeal(List<BattleMonster> team) {
    return team.map((m) {
      if (m.currentHp <= 0) return m;
      final healed = (m.currentHp + m.maxHp * 0.25).clamp(0.0, m.maxHp);
      return m.copyWith(
        currentHp: healed,
        burnTurns: 0,
        stunTurns: 0,
        skillCooldown: 0,
        shieldHp: 0,
      );
    }).toList();
  }
}
