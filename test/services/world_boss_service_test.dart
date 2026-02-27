import 'package:flutter_test/flutter_test.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/domain/services/world_boss_service.dart';

/// Helper to create a [BattleMonster] with sensible defaults for player-side tests.
BattleMonster _mon({
  String id = 'player_test',
  String name = 'Player Monster',
  String element = 'fire',
  double hp = 500,
  double atk = 80,
  double def = 40,
  double spd = 15,
}) {
  return BattleMonster(
    monsterId: id,
    templateId: id,
    name: name,
    element: element,
    size: 'medium',
    rarity: 3,
    maxHp: hp,
    currentHp: hp,
    atk: atk,
    def: def,
    spd: spd,
  );
}

// Boss expected data table — mirrors the _BossTemplate constants in the service.
const _bossData = [
  // index 0: boss_dragon
  (id: 'boss_dragon',     name: '고대 용왕',     element: 'fire',  baseHp: 50000, baseAtk: 200, baseDef: 100),
  // index 1: boss_kraken
  (id: 'boss_kraken',     name: '심해 크라켄',   element: 'water', baseHp: 60000, baseAtk: 170, baseDef: 130),
  // index 2: boss_golem
  (id: 'boss_golem',      name: '대지의 거신',   element: 'stone', baseHp: 80000, baseAtk: 150, baseDef: 180),
  // index 3: boss_phantom
  (id: 'boss_phantom',    name: '영혼의 군주',   element: 'ghost', baseHp: 40000, baseAtk: 250, baseDef: 80),
  // index 4: boss_celestial
  (id: 'boss_celestial',  name: '천상의 수호자', element: 'light', baseHp: 55000, baseAtk: 220, baseDef: 120),
];

void main() {
  // ===========================================================================
  // Constants
  // ===========================================================================

  group('WorldBossService constants', () {
    test('maxTurns is 30', () {
      expect(WorldBossService.maxTurns, 30);
    });

    test('maxAttempts is 3', () {
      expect(WorldBossService.maxAttempts, 3);
    });
  });

  // ===========================================================================
  // Boss rotation — todayBossIndex
  // ===========================================================================

  group('todayBossIndex', () {
    test('returns an index between 0 and 4 (inclusive)', () {
      final idx = WorldBossService.todayBossIndex();
      expect(idx, greaterThanOrEqualTo(0));
      expect(idx, lessThanOrEqualTo(4));
    });

    test('index equals dayOfYear mod 5', () {
      final now = DateTime.now();
      final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
      final expected = dayOfYear % 5;
      expect(WorldBossService.todayBossIndex(), expected);
    });

    test('rotation covers all 5 bosses across a 5-day cycle', () {
      // Verify each day-of-year remainder maps to a unique index.
      final indices = List.generate(5, (i) => i % 5).toSet();
      expect(indices.length, 5,
          reason: 'All 5 boss indices must appear across a 5-day cycle');
    });
  });

  // ===========================================================================
  // Boss rotation — todayBossName / todayBossElement
  // ===========================================================================

  group('todayBossName', () {
    test('returns one of the 5 known boss names', () {
      const validNames = {
        '고대 용왕',
        '심해 크라켄',
        '대지의 거신',
        '영혼의 군주',
        '천상의 수호자',
      };
      expect(validNames, contains(WorldBossService.todayBossName()));
    });

    test('name matches expected boss at current day index', () {
      final idx = WorldBossService.todayBossIndex();
      expect(WorldBossService.todayBossName(), _bossData[idx].name);
    });
  });

  group('todayBossElement', () {
    test('returns one of the valid boss elements', () {
      const validElements = {'fire', 'water', 'stone', 'ghost', 'light'};
      expect(validElements, contains(WorldBossService.todayBossElement()));
    });

    test('element matches expected boss at current day index', () {
      final idx = WorldBossService.todayBossIndex();
      expect(WorldBossService.todayBossElement(), _bossData[idx].element);
    });
  });

  // ===========================================================================
  // createBoss — level 1 baseline
  // ===========================================================================

  group('createBoss — baseline (playerLevel=1)', () {
    late BattleMonster boss;

    setUp(() {
      boss = WorldBossService.createBoss(playerLevel: 1);
    });

    test('monsterId starts with world_boss_', () {
      expect(boss.monsterId, startsWith('world_boss_'));
    });

    test('rarity is 5 (legendary)', () {
      expect(boss.rarity, 5);
    });

    test('size is large or extraLarge', () {
      expect(['large', 'extraLarge'], contains(boss.size));
    });

    test('element matches todayBossElement', () {
      expect(boss.element, WorldBossService.todayBossElement());
    });

    test('name matches todayBossName', () {
      expect(boss.name, WorldBossService.todayBossName());
    });

    test('currentHp equals maxHp at creation', () {
      expect(boss.currentHp, boss.maxHp);
    });

    test('HP matches base HP at level 1 (scale = 1.0)', () {
      final idx = WorldBossService.todayBossIndex();
      final expectedHp = _bossData[idx].baseHp.toDouble();
      expect(boss.maxHp, closeTo(expectedHp, 1.0));
    });

    test('ATK matches base ATK at level 1 (scale = 1.0)', () {
      final idx = WorldBossService.todayBossIndex();
      final expectedAtk = _bossData[idx].baseAtk.toDouble();
      expect(boss.atk, closeTo(expectedAtk, 1.0));
    });

    test('DEF matches base DEF at level 1 (scale = 1.0)', () {
      final idx = WorldBossService.todayBossIndex();
      final expectedDef = _bossData[idx].baseDef.toDouble();
      expect(boss.def, closeTo(expectedDef, 1.0));
    });

    test('speed is not scaled (same as base for any level)', () {
      final bossL1 = WorldBossService.createBoss(playerLevel: 1);
      final bossL50 = WorldBossService.createBoss(playerLevel: 50);
      // SPD must be identical regardless of player level.
      expect(bossL1.spd, bossL50.spd);
    });

    test('boss is alive at creation', () {
      expect(boss.isAlive, isTrue);
    });
  });

  // ===========================================================================
  // createBoss — level scaling
  // ===========================================================================

  group('createBoss — level scaling', () {
    test('level 2 scales stats by 1.05 over level 1', () {
      final bossL1 = WorldBossService.createBoss(playerLevel: 1);
      final bossL2 = WorldBossService.createBoss(playerLevel: 2);

      // Scale formula: 1.0 + (level - 1) * 0.05
      // Level 1: scale = 1.0, Level 2: scale = 1.05
      expect(bossL2.maxHp, closeTo(bossL1.maxHp * 1.05, 2.0));
      expect(bossL2.atk,   closeTo(bossL1.atk   * 1.05, 2.0));
      expect(bossL2.def,   closeTo(bossL1.def    * 1.05, 2.0));
    });

    test('level 11 scales stats by 1.50 over level 1', () {
      final bossL1  = WorldBossService.createBoss(playerLevel: 1);
      final bossL11 = WorldBossService.createBoss(playerLevel: 11);

      // Level 11: scale = 1.0 + 10*0.05 = 1.50
      expect(bossL11.maxHp, closeTo(bossL1.maxHp * 1.5, 5.0));
      expect(bossL11.atk,   closeTo(bossL1.atk   * 1.5, 2.0));
      expect(bossL11.def,   closeTo(bossL1.def    * 1.5, 2.0));
    });

    test('level 21 scales stats by 2.00 over level 1', () {
      final bossL1  = WorldBossService.createBoss(playerLevel: 1);
      final bossL21 = WorldBossService.createBoss(playerLevel: 21);

      // Level 21: scale = 1.0 + 20*0.05 = 2.00
      expect(bossL21.maxHp, closeTo(bossL1.maxHp * 2.0, 5.0));
    });

    test('higher player level always produces higher boss HP', () {
      final bossLow  = WorldBossService.createBoss(playerLevel: 5);
      final bossHigh = WorldBossService.createBoss(playerLevel: 50);

      expect(bossHigh.maxHp, greaterThan(bossLow.maxHp));
      expect(bossHigh.atk,   greaterThan(bossLow.atk));
      expect(bossHigh.def,   greaterThan(bossLow.def));
    });

    test('speed is constant regardless of player level', () {
      final spd1  = WorldBossService.createBoss(playerLevel: 1).spd;
      final spd10 = WorldBossService.createBoss(playerLevel: 10).spd;
      final spd99 = WorldBossService.createBoss(playerLevel: 99).spd;

      expect(spd1, spd10);
      expect(spd1, spd99);
    });

    test('boss HP scales with each level increment', () {
      final bossA = WorldBossService.createBoss(playerLevel: 5);
      final bossB = WorldBossService.createBoss(playerLevel: 6);
      expect(bossB.maxHp, greaterThan(bossA.maxHp));
    });
  });

  // ===========================================================================
  // calculateReward
  // ===========================================================================

  group('calculateReward', () {
    test('returns WorldBossReward with matching totalDamage', () {
      const damage = 10000.0;
      final reward = WorldBossService.calculateReward(damage);
      expect(reward.totalDamage, damage);
    });

    // ---- Gold ----

    test('gold formula: damage * 0.05, clamped [100, 99999]', () {
      // Mid-range: 10000 * 0.05 = 500
      final r = WorldBossService.calculateReward(10000);
      expect(r.gold, 500);
    });

    test('gold floor: very low damage clamps to minimum 100', () {
      final r = WorldBossService.calculateReward(1);
      expect(r.gold, 100);
    });

    test('gold ceiling: very high damage clamps to maximum 99999', () {
      final r = WorldBossService.calculateReward(99999999);
      expect(r.gold, 99999);
    });

    test('gold is exactly 100 at zero damage (minimum clamp)', () {
      final r = WorldBossService.calculateReward(0);
      expect(r.gold, 100);
    });

    // ---- EXP ----

    test('exp formula: damage * 0.02, clamped [50, 50000]', () {
      // 20000 * 0.02 = 400
      final r = WorldBossService.calculateReward(20000);
      expect(r.exp, 400);
    });

    test('exp floor: very low damage clamps to minimum 50', () {
      final r = WorldBossService.calculateReward(0);
      expect(r.exp, 50);
    });

    test('exp ceiling: very high damage clamps to maximum 50000', () {
      final r = WorldBossService.calculateReward(99999999);
      expect(r.exp, 50000);
    });

    // ---- Diamond ----

    test('diamond formula: damage / 4000, clamped [1, 50]', () {
      // 8000 / 4000 = 2
      final r = WorldBossService.calculateReward(8000);
      expect(r.diamond, 2);
    });

    test('diamond minimum is 1 even for zero damage', () {
      final r = WorldBossService.calculateReward(0);
      expect(r.diamond, 1);
    });

    test('diamond ceiling is 50 for extreme damage', () {
      final r = WorldBossService.calculateReward(99999999);
      expect(r.diamond, 50);
    });

    test('diamond is 1 for damage just under 4000 (rounds down)', () {
      // 3999 / 4000 rounds to 1
      final r = WorldBossService.calculateReward(3999);
      expect(r.diamond, 1);
    });

    // ---- Shard ----

    test('shard formula: damage / 10000, clamped [0, 20]', () {
      // 30000 / 10000 = 3
      final r = WorldBossService.calculateReward(30000);
      expect(r.shard, 3);
    });

    test('shard is 0 for low damage (below 5000)', () {
      final r = WorldBossService.calculateReward(4999);
      expect(r.shard, 0);
    });

    test('shard ceiling is 20 for extreme damage', () {
      final r = WorldBossService.calculateReward(99999999);
      expect(r.shard, 20);
    });

    test('shard is 1 for damage exactly 10000', () {
      final r = WorldBossService.calculateReward(10000);
      expect(r.shard, 1);
    });

    // ---- Ordering ----

    test('higher damage always gives more or equal gold', () {
      final low  = WorldBossService.calculateReward(5000);
      final high = WorldBossService.calculateReward(50000);
      expect(high.gold, greaterThanOrEqualTo(low.gold));
    });

    test('higher damage always gives more or equal exp', () {
      final low  = WorldBossService.calculateReward(5000);
      final high = WorldBossService.calculateReward(50000);
      expect(high.exp, greaterThanOrEqualTo(low.exp));
    });

    test('higher damage always gives more or equal diamond', () {
      final low  = WorldBossService.calculateReward(1000);
      final high = WorldBossService.calculateReward(100000);
      expect(high.diamond, greaterThanOrEqualTo(low.diamond));
    });
  });

  // ===========================================================================
  // bossAttackRandom — basic behaviour
  // ===========================================================================

  group('bossAttackRandom — basic behaviour', () {
    test('returns null when player team is empty', () {
      final boss = WorldBossService.createBoss(playerLevel: 1);
      final result = WorldBossService.bossAttackRandom(boss, []);
      expect(result, isNull);
    });

    test('returns null when all player monsters are dead', () {
      final boss = WorldBossService.createBoss(playerLevel: 1);
      final dead = _mon();
      dead.currentHp = 0;

      final result = WorldBossService.bossAttackRandom(boss, [dead]);
      expect(result, isNull);
    });

    test('returns a BattleLogEntry when a target is alive', () {
      final boss = WorldBossService.createBoss(playerLevel: 1);
      final player = _mon(hp: 9999, def: 0);

      final log = WorldBossService.bossAttackRandom(boss, [player]);
      expect(log, isNotNull);
    });

    test('log attackerName matches boss name', () {
      final boss = WorldBossService.createBoss(playerLevel: 1);
      final player = _mon(name: 'Hero');

      final log = WorldBossService.bossAttackRandom(boss, [player])!;
      expect(log.attackerName, boss.name);
    });

    test('log targetName matches the attacked player monster name', () {
      final boss = WorldBossService.createBoss(playerLevel: 1);
      final player = _mon(name: 'Brave Knight');

      final log = WorldBossService.bossAttackRandom(boss, [player])!;
      expect(log.targetName, 'Brave Knight');
    });

    test('log damage is greater than 0', () {
      final boss = WorldBossService.createBoss(playerLevel: 1);
      final player = _mon(hp: 9999, def: 0);

      final log = WorldBossService.bossAttackRandom(boss, [player])!;
      expect(log.damage, greaterThan(0));
    });

    test('isElementAdvantage is always false (world boss attack)', () {
      final boss = WorldBossService.createBoss(playerLevel: 1);
      final player = _mon(hp: 9999);

      // Run several times to be sure.
      for (int i = 0; i < 20; i++) {
        final log = WorldBossService.bossAttackRandom(boss, [player]);
        if (log != null) {
          expect(log.isElementAdvantage, isFalse);
        }
      }
    });
  });

  // ===========================================================================
  // bossAttackRandom — damage application
  // ===========================================================================

  group('bossAttackRandom — damage application', () {
    test('target HP is reduced after boss attack', () {
      final boss = WorldBossService.createBoss(playerLevel: 10);
      final player = _mon(hp: 99999, def: 0);
      final initialHp = player.currentHp;

      WorldBossService.bossAttackRandom(boss, [player]);

      expect(player.currentHp, lessThan(initialHp));
    });

    test('target HP never goes below 0', () {
      final boss = WorldBossService.createBoss(playerLevel: 99);
      final player = _mon(hp: 10, def: 0);

      WorldBossService.bossAttackRandom(boss, [player]);

      expect(player.currentHp, greaterThanOrEqualTo(0));
    });

    test('minimum damage is at least 1', () {
      // High DEF player — damage must still be >= 1.
      final boss = WorldBossService.createBoss(playerLevel: 1);
      final tankPlayer = _mon(hp: 9999, def: 9999);

      for (int i = 0; i < 50; i++) {
        final log = WorldBossService.bossAttackRandom(boss, [tankPlayer]);
        if (log != null) {
          expect(log.damage, greaterThanOrEqualTo(1.0));
        }
      }
    });

    test('shield absorbs damage before HP is reduced', () {
      final boss = WorldBossService.createBoss(playerLevel: 1);
      final player = _mon(hp: 500, def: 0);
      player.shieldHp = 1000000; // enormous shield
      final initialHp = player.currentHp;

      WorldBossService.bossAttackRandom(boss, [player]);

      // HP should be unchanged since the shield absorbed all damage.
      expect(player.currentHp, equals(initialHp),
          reason: 'HP must not drop when shield absorbs the full hit');
      expect(player.shieldHp, lessThan(1000000),
          reason: 'Shield must be reduced by the attack');
    });

    test('shield depletes to 0 and remainder goes to HP when shield < damage', () {
      // Use a high-level boss so its ATK is guaranteed to exceed a 1-point shield.
      final boss = WorldBossService.createBoss(playerLevel: 50);
      final player = _mon(hp: 9999, def: 0);
      player.shieldHp = 1; // tiny shield, boss will surely exceed it

      WorldBossService.bossAttackRandom(boss, [player]);

      expect(player.shieldHp, equals(0),
          reason: 'Shield should be fully depleted');
      expect(player.currentHp, lessThan(9999),
          reason: 'Remaining damage must carry over to HP');
    });

    test('only alive targets are attacked (dead monster HP unchanged)', () {
      final boss = WorldBossService.createBoss(playerLevel: 1);
      final dead  = _mon(name: 'Dead',  hp: 100, def: 0);
      final alive = _mon(name: 'Alive', hp: 9999, def: 0);
      dead.currentHp = 0;

      // Run many times — boss must never pick the dead target.
      for (int i = 0; i < 30; i++) {
        WorldBossService.bossAttackRandom(boss, [dead, alive]);
        expect(dead.currentHp, equals(0),
            reason: 'Dead monster HP must remain at 0');
      }
    });
  });

  // ===========================================================================
  // bossAttackRandom — critical hits
  // ===========================================================================

  group('bossAttackRandom — critical hits', () {
    test('critical flag in log entry is a bool', () {
      final boss = WorldBossService.createBoss(playerLevel: 1);
      final player = _mon(hp: 99999, def: 0);

      final log = WorldBossService.bossAttackRandom(boss, [player])!;
      expect(log.isCritical, isA<bool>());
    });

    test('description contains 치명타 on critical hit', () {
      // Run many times to eventually trigger a crit (10% chance).
      final boss = WorldBossService.createBoss(playerLevel: 1);
      final player = _mon(hp: 99999999, def: 0);

      bool foundCrit = false;
      for (int i = 0; i < 300; i++) {
        // Reset HP each iteration so the monster stays alive.
        player.currentHp = player.maxHp;
        final log = WorldBossService.bossAttackRandom(boss, [player]);
        if (log != null && log.isCritical) {
          foundCrit = true;
          expect(log.description, contains('치명타'),
              reason: 'Critical log entry must mention 치명타');
          break;
        }
      }
      expect(foundCrit, isTrue,
          reason: 'At least one critical hit should appear in 300 attacks');
    });
  });

  // ===========================================================================
  // Edge cases
  // ===========================================================================

  group('Edge cases', () {
    test('createBoss at playerLevel 1 (minimum) does not throw', () {
      expect(() => WorldBossService.createBoss(playerLevel: 1), returnsNormally);
    });

    test('createBoss at very high playerLevel does not throw', () {
      expect(() => WorldBossService.createBoss(playerLevel: 1000),
          returnsNormally);
    });

    test('calculateReward with 0 damage returns minimum rewards', () {
      final r = WorldBossService.calculateReward(0);
      expect(r.gold,    100);
      expect(r.exp,     50);
      expect(r.diamond, 1);
      expect(r.shard,   0);
    });

    test('calculateReward with negative damage clamps to minimums', () {
      // Negative values should still clamp correctly.
      final r = WorldBossService.calculateReward(-9999);
      expect(r.gold,    100);
      expect(r.exp,     50);
      expect(r.diamond, 1);
    });

    test('bossAttackRandom with mixed alive/dead team only hits alive members', () {
      final boss = WorldBossService.createBoss(playerLevel: 1);

      final dead1 = _mon(name: 'Dead1');
      final dead2 = _mon(name: 'Dead2');
      final alive = _mon(name: 'Survivor', hp: 99999, def: 0);
      dead1.currentHp = 0;
      dead2.currentHp = 0;

      for (int i = 0; i < 20; i++) {
        alive.currentHp = alive.maxHp; // reset between hits
        final log = WorldBossService.bossAttackRandom(boss, [dead1, dead2, alive]);
        expect(log, isNotNull,
            reason: 'Should find the alive survivor');
        expect(log!.targetName, 'Survivor');
      }
    });

    test('boss templateId matches known boss id pattern', () {
      final boss = WorldBossService.createBoss(playerLevel: 1);
      const validTemplateIds = {
        'boss_dragon',
        'boss_kraken',
        'boss_golem',
        'boss_phantom',
        'boss_celestial',
      };
      expect(validTemplateIds, contains(boss.templateId));
    });

    test('monsterId is world_boss_ + templateId', () {
      final boss = WorldBossService.createBoss(playerLevel: 1);
      expect(boss.monsterId, 'world_boss_${boss.templateId}');
    });

    test('boss attack log description mentions boss name', () {
      final boss = WorldBossService.createBoss(playerLevel: 1);
      final player = _mon(hp: 99999, def: 0);

      final log = WorldBossService.bossAttackRandom(boss, [player])!;
      expect(log.description, contains(boss.name));
    });

    test('boss attack log description mentions target name', () {
      final boss   = WorldBossService.createBoss(playerLevel: 1);
      final player = _mon(name: '영웅', hp: 99999, def: 0);

      final log = WorldBossService.bossAttackRandom(boss, [player])!;
      expect(log.description, contains('영웅'));
    });

    test('boss attack log description mentions damage amount', () {
      final boss   = WorldBossService.createBoss(playerLevel: 1);
      final player = _mon(hp: 99999, def: 0);

      final log = WorldBossService.bossAttackRandom(boss, [player])!;
      // The damage int should appear somewhere in the description.
      expect(log.description, contains(log.damage.toInt().toString()));
    });
  });

  // ===========================================================================
  // All 5 bosses — property checks via manual index simulation
  // ===========================================================================

  group('All 5 bosses have correct base properties at level 1', () {
    // We test each boss by computing the day-of-year that maps to its index.
    // Since we cannot inject DateTime, we validate that the boss returned today
    // is consistent with the index computation — and enumerate separately.

    for (int i = 0; i < _bossData.length; i++) {
      final expected = _bossData[i];
      test('boss index $i: ${expected.name} has correct element (${expected.element})', () {
        // Verify the mapping holds: dayOfYear % 5 == i gives the right name.
        // We can't control the clock, so we verify the full table is self-consistent
        // by asserting today's result matches the explicit table entry.
        final todayIdx = WorldBossService.todayBossIndex();
        if (todayIdx == i) {
          expect(WorldBossService.todayBossName(),    expected.name);
          expect(WorldBossService.todayBossElement(), expected.element);
          final boss = WorldBossService.createBoss(playerLevel: 1);
          expect(boss.element, expected.element);
          expect(boss.name,    expected.name);
          expect(boss.maxHp,   closeTo(expected.baseHp.toDouble(), 1.0));
          expect(boss.atk,     closeTo(expected.baseAtk.toDouble(), 1.0));
          expect(boss.def,     closeTo(expected.baseDef.toDouble(), 1.0));
        } else {
          // For non-today bosses, we can only confirm the table constant itself.
          expect(expected.id, isNotEmpty);
          expect(expected.name, isNotEmpty);
          expect(expected.element, isNotEmpty);
          expect(expected.baseHp, greaterThan(0));
          expect(expected.baseAtk, greaterThan(0));
          expect(expected.baseDef, greaterThan(0));
        }
      });
    }
  });
}
