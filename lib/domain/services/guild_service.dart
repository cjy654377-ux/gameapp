import 'dart:math' as math;

import 'package:gameapp/data/static/skill_database.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';

/// Static service for the guild/clan system.
///
/// Handles guild boss creation, AI member simulation, reward calculation,
/// and guild shop definitions. All methods are static.
class GuildService {
  GuildService._();

  static final math.Random _random = math.Random();

  /// Maximum daily guild boss attempts.
  static const int maxDailyAttempts = 2;

  /// Max turns per guild boss fight.
  static const int maxTurns = 25;

  // ---------------------------------------------------------------------------
  // AI member names
  // ---------------------------------------------------------------------------

  static const List<String> _aiNames = [
    '용사김철수', '마법사하늘', '검신바람', '성기사빛나',
    '암살자달빛', '궁수별빛', '전사천둥', '치유사이슬',
    '연금술사금', '현자구름', '사냥꾼숲길', '기사철벽',
  ];

  /// Generates 4-7 random AI member names for a new guild.
  static List<String> generateMembers() {
    final count = 4 + _random.nextInt(4); // 4~7
    final shuffled = List<String>.from(_aiNames)..shuffle(_random);
    return shuffled.take(count).toList();
  }

  // ---------------------------------------------------------------------------
  // Guild boss
  // ---------------------------------------------------------------------------

  static const List<_GuildBossTemplate> _bosses = [
    _GuildBossTemplate(
      id: 'guild_boss_hydra',
      name: '구렁이 히드라',
      element: 'water',
      baseHp: 200000,
      baseAtk: 180,
      baseDef: 90,
      baseSpd: 50,
    ),
    _GuildBossTemplate(
      id: 'guild_boss_titan',
      name: '화염 타이탄',
      element: 'fire',
      baseHp: 250000,
      baseAtk: 220,
      baseDef: 150,
      baseSpd: 30,
    ),
    _GuildBossTemplate(
      id: 'guild_boss_lich',
      name: '불멸의 리치',
      element: 'dark',
      baseHp: 180000,
      baseAtk: 260,
      baseDef: 70,
      baseSpd: 80,
    ),
  ];

  /// Returns current week number (weeks since epoch).
  static int currentWeekNumber() {
    final now = DateTime.now();
    return now.difference(DateTime(2024, 1, 1)).inDays ~/ 7;
  }

  /// Returns this week's boss template index.
  static int weeklyBossIndex() => currentWeekNumber() % _bosses.length;

  /// Returns this week's boss name.
  static String weeklyBossName() => _bosses[weeklyBossIndex()].name;

  /// Returns this week's boss element.
  static String weeklyBossElement() => _bosses[weeklyBossIndex()].element;

  /// Returns total boss HP for this week (scales with guild level).
  static double bossMaxHp({int guildLevel = 1}) {
    final template = _bosses[weeklyBossIndex()];
    return template.baseHp * (1.0 + (guildLevel - 1) * 0.1);
  }

  /// Creates a [BattleMonster] for the guild boss.
  static BattleMonster createBoss({int guildLevel = 1, double? currentHp}) {
    final template = _bosses[weeklyBossIndex()];
    final scale = 1.0 + (guildLevel - 1) * 0.08;

    final maxHp = template.baseHp * (1.0 + (guildLevel - 1) * 0.1);
    final hp = currentHp ?? maxHp;
    final atk = (template.baseAtk * scale).roundToDouble();
    final def = (template.baseDef * scale).roundToDouble();
    final spd = template.baseSpd.toDouble();

    final skill = SkillDatabase.findByTemplateId(template.id);

    return BattleMonster(
      monsterId: 'guild_boss_${template.id}',
      templateId: template.id,
      name: template.name,
      element: template.element,
      size: 'extraLarge',
      rarity: 5,
      maxHp: maxHp,
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
  // AI contribution simulation
  // ---------------------------------------------------------------------------

  /// Simulates AI members dealing damage to the guild boss over one day.
  /// Returns total AI damage dealt.
  static double simulateAiDamage({
    required int memberCount,
    required int guildLevel,
  }) {
    // Each AI member deals roughly 2000-5000 damage per day.
    double total = 0;
    for (int i = 0; i < memberCount; i++) {
      final baseDmg = 2000.0 + _random.nextDouble() * 3000.0;
      total += baseDmg * (1 + guildLevel * 0.05);
    }
    return total;
  }

  // ---------------------------------------------------------------------------
  // Boss attack (same pattern as WorldBossService)
  // ---------------------------------------------------------------------------

  /// Processes a single boss attack on a random alive player monster.
  static BattleLogEntry? bossAttackRandom(
    BattleMonster boss,
    List<BattleMonster> playerTeam,
  ) {
    final alive = playerTeam.where((m) => m.isAlive).toList();
    if (alive.isEmpty) return null;

    final target = alive[_random.nextInt(alive.length)];

    final rawDamage = (boss.atk * 1.0 - target.def * 0.5).clamp(1.0, 999999.0);
    final variance = 0.85 + _random.nextDouble() * 0.30;
    final isCrit = _random.nextDouble() < 0.1;
    final critMult = isCrit ? 1.5 : 1.0;
    final finalDamage = (rawDamage * variance * critMult).roundToDouble();

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

  // ---------------------------------------------------------------------------
  // Reward calculation
  // ---------------------------------------------------------------------------

  /// Calculates guild coins from player's damage contribution.
  static int calculateGuildCoins(double damage) {
    return (damage / 500).round().clamp(1, 999);
  }

  /// Guild exp from boss damage.
  static int calculateGuildExp(double damage) {
    return (damage / 1000).round().clamp(1, 200);
  }

  // ---------------------------------------------------------------------------
  // Guild shop items
  // ---------------------------------------------------------------------------

  static const List<GuildShopItem> shopItems = [
    GuildShopItem(index: 0, name: '소환권 x2', cost: 50, type: 'gachaTicket', amount: 2),
    GuildShopItem(index: 1, name: '경험치 포션 x5', cost: 30, type: 'expPotion', amount: 5),
    GuildShopItem(index: 2, name: '골드 2000', cost: 20, type: 'gold', amount: 2000),
    GuildShopItem(index: 3, name: '다이아 50', cost: 80, type: 'diamond', amount: 50),
    GuildShopItem(index: 4, name: '진화석 5', cost: 60, type: 'monsterShard', amount: 5),
  ];

  /// Returns today's date string (YYYY-MM-DD).
  static String todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

// =============================================================================
// Supporting classes
// =============================================================================

class _GuildBossTemplate {
  final String id;
  final String name;
  final String element;
  final int baseHp;
  final int baseAtk;
  final int baseDef;
  final int baseSpd;

  const _GuildBossTemplate({
    required this.id,
    required this.name,
    required this.element,
    required this.baseHp,
    required this.baseAtk,
    required this.baseDef,
    required this.baseSpd,
  });
}

class GuildShopItem {
  final int index;
  final String name;
  final int cost;
  final String type;
  final int amount;

  const GuildShopItem({
    required this.index,
    required this.name,
    required this.cost,
    required this.type,
    required this.amount,
  });
}
