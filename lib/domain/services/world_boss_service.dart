import 'dart:math' as math;

import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/data/static/skill_database.dart';

// =============================================================================
// BossRageLevel — rage state based on boss HP percentage
// =============================================================================

enum BossRageLevel { normal, angry, berserk }

// =============================================================================
// WorldBossService — static utility for world boss encounters
// =============================================================================

class WorldBossService {
  WorldBossService._();

  // ---------------------------------------------------------------------------
  // Rage system
  // ---------------------------------------------------------------------------

  static final Set<String> _healedBosses = {};

  static void resetHealTracker() => _healedBosses.clear();

  static BossRageLevel getRageLevel(int currentHp, int maxHp) {
    if (maxHp <= 0) return BossRageLevel.normal;
    final pct = currentHp / maxHp;
    if (pct >= 0.70) return BossRageLevel.normal;
    if (pct >= 0.40) return BossRageLevel.angry;
    return BossRageLevel.berserk;
  }

  static double getRageAtkMultiplier(BossRageLevel level) {
    return switch (level) {
      BossRageLevel.normal => 1.0,
      BossRageLevel.angry => 1.3,
      BossRageLevel.berserk => 1.6,
    };
  }

  static double getRageDefMultiplier(BossRageLevel level) {
    return switch (level) {
      BossRageLevel.normal => 1.0,
      BossRageLevel.angry => 1.0,
      BossRageLevel.berserk => 0.8,
    };
  }

  static BattleLogEntry? processBossHeal(BattleMonster boss) {
    final rage = getRageLevel(boss.currentHp.toInt(), boss.maxHp.toInt());
    if (rage != BossRageLevel.berserk) return null;
    if (_healedBosses.contains(boss.monsterId)) return null;
    _healedBosses.add(boss.monsterId);
    final healAmount = boss.maxHp * 0.10;
    boss.currentHp = (boss.currentHp + healAmount).clamp(0, boss.maxHp);
    return BattleLogEntry(
      attackerName: boss.name,
      targetName: boss.name,
      damage: 0,
      isCritical: false,
      isElementAdvantage: false,
      description: '${boss.name}이(가) 분노하여 HP ${healAmount.toInt()}를 회복했다!',
      timestamp: DateTime.now(),
    );
  }

  /// Maximum turns allowed per boss fight.
  static const int maxTurns = 30;

  /// Daily attempts allowed.
  static const int maxAttempts = 3;

  /// Boss templates — rotates daily.
  static const List<_BossTemplate> _bosses = [
    _BossTemplate(
      id: 'boss_dragon',
      name: '고대 용왕',
      element: 'fire',
      size: 'extraLarge',
      baseHp: 50000,
      baseAtk: 200,
      baseDef: 100,
      baseSpd: 80,
    ),
    _BossTemplate(
      id: 'boss_kraken',
      name: '심해 크라켄',
      element: 'water',
      size: 'extraLarge',
      baseHp: 60000,
      baseAtk: 170,
      baseDef: 130,
      baseSpd: 60,
    ),
    _BossTemplate(
      id: 'boss_golem',
      name: '대지의 거신',
      element: 'stone',
      size: 'extraLarge',
      baseHp: 80000,
      baseAtk: 150,
      baseDef: 180,
      baseSpd: 40,
    ),
    _BossTemplate(
      id: 'boss_phantom',
      name: '영혼의 군주',
      element: 'ghost',
      size: 'large',
      baseHp: 40000,
      baseAtk: 250,
      baseDef: 80,
      baseSpd: 120,
    ),
    _BossTemplate(
      id: 'boss_celestial',
      name: '천상의 수호자',
      element: 'light',
      size: 'extraLarge',
      baseHp: 55000,
      baseAtk: 220,
      baseDef: 120,
      baseSpd: 90,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Boss selection
  // ---------------------------------------------------------------------------

  /// Returns today's boss template index (rotates daily).
  static int todayBossIndex() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return dayOfYear % _bosses.length;
  }

  /// Returns today's boss name.
  static String todayBossName() => _bosses[todayBossIndex()].name;

  /// Returns today's boss element.
  static String todayBossElement() => _bosses[todayBossIndex()].element;

  // ---------------------------------------------------------------------------
  // Boss creation
  // ---------------------------------------------------------------------------

  /// Creates a [BattleMonster] for today's world boss.
  /// Boss level scales with player level for challenge.
  static BattleMonster createBoss({int playerLevel = 1}) {
    final template = _bosses[todayBossIndex()];
    // Scale HP and stats with player level.
    final levelScale = 1.0 + (playerLevel - 1) * 0.05;

    final hp = (template.baseHp * levelScale).roundToDouble();
    final atk = (template.baseAtk * levelScale).roundToDouble();
    final def = (template.baseDef * levelScale).roundToDouble();
    final spd = template.baseSpd.toDouble();

    // Check if boss has a skill.
    final skill = SkillDatabase.findByTemplateId(template.id);

    return BattleMonster(
      monsterId: 'world_boss_${template.id}',
      templateId: template.id,
      name: template.name,
      element: template.element,
      size: template.size,
      rarity: 5,
      maxHp: hp,
      currentHp: hp,
      atk: atk,
      def: def,
      spd: spd,
      skillId: skill?.id,
      skillName: skill?.name,
      skillCooldown: skill?.cooldown ?? 0,
      skillMaxCooldown: skill?.cooldown ?? 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Reward calculation
  // ---------------------------------------------------------------------------

  /// Calculates rewards based on total damage dealt to the boss.
  static WorldBossReward calculateReward(double totalDamage) {
    final gold = (totalDamage * 0.05).round().clamp(100, 99999);
    final exp = (totalDamage * 0.02).round().clamp(50, 50000);
    final diamond = (totalDamage / 4000).round().clamp(1, 50);
    final shard = (totalDamage / 10000).round().clamp(0, 20);

    return WorldBossReward(
      gold: gold,
      exp: exp,
      diamond: diamond,
      shard: shard,
      totalDamage: totalDamage,
    );
  }

  // ---------------------------------------------------------------------------
  // Boss attack (simplified — boss attacks random player monster)
  // ---------------------------------------------------------------------------

  /// Processes a single boss attack on a random alive player monster.
  static BattleLogEntry? bossAttackRandom(
    BattleMonster boss,
    List<BattleMonster> playerTeam,
  ) {
    final alive = playerTeam.where((m) => m.isAlive).toList();
    if (alive.isEmpty) return null;

    final random = math.Random();
    final target = alive[random.nextInt(alive.length)];

    // Damage formula (same as BattleService) with rage multiplier.
    final rage = getRageLevel(boss.currentHp.toInt(), boss.maxHp.toInt());
    final atkMult = getRageAtkMultiplier(rage);
    final rawDamage = (boss.atk * atkMult - target.def * 0.5).clamp(1.0, 999999.0);
    final variance = 0.85 + random.nextDouble() * 0.30;
    final isCrit = random.nextDouble() < 0.1;
    final critMult = isCrit ? 1.5 : 1.0;
    final finalDamage = (rawDamage * variance * critMult).roundToDouble();

    // Apply damage (shield first, then HP).
    if (target.shieldHp > 0) {
      if (finalDamage <= target.shieldHp) {
        target.shieldHp -= finalDamage;
      } else {
        final remaining = finalDamage - target.shieldHp;
        target.shieldHp = 0;
        target.currentHp = (target.currentHp - remaining).clamp(0, target.maxHp);
      }
    } else {
      target.currentHp = (target.currentHp - finalDamage).clamp(0, target.maxHp);
    }

    final critText = isCrit ? ' (치명타!)' : '';
    return BattleLogEntry(
      attackerName: boss.name,
      targetName: target.name,
      damage: finalDamage,
      isCritical: isCrit,
      isElementAdvantage: false,
      description: '${boss.name}이(가) ${target.name}에게 '
          '${finalDamage.toInt()} 데미지!$critText',
      timestamp: DateTime.now(),
    );
  }
}

// =============================================================================
// Supporting classes
// =============================================================================

class _BossTemplate {
  final String id;
  final String name;
  final String element;
  final String size;
  final int baseHp;
  final int baseAtk;
  final int baseDef;
  final int baseSpd;

  const _BossTemplate({
    required this.id,
    required this.name,
    required this.element,
    required this.size,
    required this.baseHp,
    required this.baseAtk,
    required this.baseDef,
    required this.baseSpd,
  });
}

class WorldBossReward {
  final int gold;
  final int exp;
  final int diamond;
  final int shard;
  final double totalDamage;

  const WorldBossReward({
    required this.gold,
    required this.exp,
    required this.diamond,
    required this.shard,
    required this.totalDamage,
  });
}
