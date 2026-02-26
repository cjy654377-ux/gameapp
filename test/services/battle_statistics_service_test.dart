import 'package:flutter_test/flutter_test.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/domain/services/battle_statistics_service.dart';

BattleMonster _mon({required String name}) {
  return BattleMonster(
    monsterId: name,
    templateId: name,
    name: name,
    element: 'fire',
    size: 'medium',
    rarity: 1,
    maxHp: 100,
    currentHp: 100,
    atk: 50,
    def: 30,
    spd: 10,
  );
}

BattleLogEntry _log({
  required String attacker,
  String target = 'Enemy',
  double damage = 10,
  bool isCritical = false,
  bool isSkill = false,
  bool isElementAdv = false,
}) {
  return BattleLogEntry(
    attackerName: attacker,
    targetName: target,
    damage: damage,
    isCritical: isCritical,
    isElementAdvantage: isElementAdv,
    isSkillActivation: isSkill,
    description: '$attacker attacks $target for $damage',
    timestamp: DateTime.now(),
  );
}

void main() {
  // ===========================================================================
  // Basic statistics
  // ===========================================================================

  group('BattleStatisticsService.calculate', () {
    test('empty log returns zero stats', () {
      final stats = BattleStatisticsService.calculate(
        log: [],
        playerTeam: [_mon(name: 'P1')],
        turnCount: 0,
      );

      expect(stats.totalDamage, 0);
      expect(stats.totalTurns, 0);
      expect(stats.totalCriticals, 0);
      expect(stats.totalSkillUses, 0);
      expect(stats.mvpName, 'P1');
    });

    test('aggregates total damage from player attacks', () {
      final stats = BattleStatisticsService.calculate(
        log: [
          _log(attacker: 'P1', damage: 100),
          _log(attacker: 'P1', damage: 50),
        ],
        playerTeam: [_mon(name: 'P1')],
        turnCount: 2,
      );

      expect(stats.totalDamage, 150);
      expect(stats.totalTurns, 2);
    });

    test('ignores enemy attacks in statistics', () {
      final stats = BattleStatisticsService.calculate(
        log: [
          _log(attacker: 'P1', damage: 100),
          _log(attacker: 'Enemy', damage: 999), // enemy attack
        ],
        playerTeam: [_mon(name: 'P1')],
        turnCount: 2,
      );

      expect(stats.totalDamage, 100,
          reason: 'Only player damage should be counted');
    });

    test('counts criticals correctly', () {
      final stats = BattleStatisticsService.calculate(
        log: [
          _log(attacker: 'P1', damage: 100, isCritical: true),
          _log(attacker: 'P1', damage: 50, isCritical: false),
          _log(attacker: 'P1', damage: 75, isCritical: true),
        ],
        playerTeam: [_mon(name: 'P1')],
        turnCount: 3,
      );

      expect(stats.totalCriticals, 2);
    });

    test('counts skill uses correctly', () {
      final stats = BattleStatisticsService.calculate(
        log: [
          _log(attacker: 'P1', damage: 100, isSkill: true),
          _log(attacker: 'P1', damage: 50),
        ],
        playerTeam: [_mon(name: 'P1')],
        turnCount: 2,
      );

      expect(stats.totalSkillUses, 1);
    });

    test('counts element advantages correctly', () {
      final stats = BattleStatisticsService.calculate(
        log: [
          _log(attacker: 'P1', damage: 100, isElementAdv: true),
          _log(attacker: 'P1', damage: 50, isElementAdv: true),
          _log(attacker: 'P1', damage: 50),
        ],
        playerTeam: [_mon(name: 'P1')],
        turnCount: 3,
      );

      expect(stats.totalElementAdvantages, 2);
    });
  });

  // ===========================================================================
  // Per-monster stats
  // ===========================================================================

  group('Per-monster stats', () {
    test('tracks damage per monster', () {
      final stats = BattleStatisticsService.calculate(
        log: [
          _log(attacker: 'P1', damage: 100),
          _log(attacker: 'P2', damage: 200),
          _log(attacker: 'P1', damage: 50),
        ],
        playerTeam: [_mon(name: 'P1'), _mon(name: 'P2')],
        turnCount: 3,
      );

      expect(stats.monsterStats.length, 2);

      // Sorted by damage desc → P2 first
      expect(stats.monsterStats[0].name, 'P2');
      expect(stats.monsterStats[0].totalDamage, 200);
      expect(stats.monsterStats[1].name, 'P1');
      expect(stats.monsterStats[1].totalDamage, 150);
    });

    test('damage percent sums to ~1.0', () {
      final stats = BattleStatisticsService.calculate(
        log: [
          _log(attacker: 'P1', damage: 100),
          _log(attacker: 'P2', damage: 300),
        ],
        playerTeam: [_mon(name: 'P1'), _mon(name: 'P2')],
        turnCount: 2,
      );

      final totalPercent =
          stats.monsterStats.fold<double>(0, (s, m) => s + m.damagePercent);
      expect(totalPercent, closeTo(1.0, 0.001));
    });

    test('damage percent is correct per monster', () {
      final stats = BattleStatisticsService.calculate(
        log: [
          _log(attacker: 'P1', damage: 100),
          _log(attacker: 'P2', damage: 300),
        ],
        playerTeam: [_mon(name: 'P1'), _mon(name: 'P2')],
        turnCount: 2,
      );

      final p1 = stats.monsterStats.firstWhere((m) => m.name == 'P1');
      final p2 = stats.monsterStats.firstWhere((m) => m.name == 'P2');
      expect(p1.damagePercent, closeTo(0.25, 0.001));
      expect(p2.damagePercent, closeTo(0.75, 0.001));
    });
  });

  // ===========================================================================
  // MVP selection
  // ===========================================================================

  group('MVP selection', () {
    test('MVP is the monster with highest damage', () {
      final stats = BattleStatisticsService.calculate(
        log: [
          _log(attacker: 'P1', damage: 100),
          _log(attacker: 'P2', damage: 500),
          _log(attacker: 'P3', damage: 200),
        ],
        playerTeam: [
          _mon(name: 'P1'),
          _mon(name: 'P2'),
          _mon(name: 'P3'),
        ],
        turnCount: 3,
      );

      expect(stats.mvpName, 'P2');
    });

    test('MVP is empty string when no monster stats', () {
      final stats = BattleStatisticsService.calculate(
        log: [],
        playerTeam: [],
        turnCount: 0,
      );

      expect(stats.mvpName, '');
    });
  });
}
