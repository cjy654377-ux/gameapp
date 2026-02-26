import 'package:flutter_test/flutter_test.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/domain/services/battle_service.dart';

/// Helper to create a [BattleMonster] with sensible defaults.
BattleMonster _mon({
  String id = 'test',
  String name = 'Test',
  String element = 'fire',
  double hp = 100,
  double atk = 50,
  double def = 30,
  double spd = 10,
  int rarity = 1,
}) {
  return BattleMonster(
    monsterId: id,
    templateId: id,
    name: name,
    element: element,
    size: 'medium',
    rarity: rarity,
    maxHp: hp,
    currentHp: hp,
    atk: atk,
    def: def,
    spd: spd,
  );
}

void main() {
  // ===========================================================================
  // getElementMultiplier
  // ===========================================================================

  group('getElementMultiplier', () {
    test('same element returns 1.0', () {
      expect(BattleService.getElementMultiplier('fire', 'fire'), 1.0);
      expect(BattleService.getElementMultiplier('water', 'water'), 1.0);
      expect(BattleService.getElementMultiplier('dark', 'dark'), 1.0);
    });

    test('fire > grass (advantage 1.3)', () {
      expect(BattleService.getElementMultiplier('fire', 'grass'), 1.3);
    });

    test('fire < water (disadvantage 0.7)', () {
      expect(BattleService.getElementMultiplier('fire', 'water'), 0.7);
    });

    test('fire < stone (stone resists fire, 0.7)', () {
      expect(BattleService.getElementMultiplier('fire', 'stone'), 0.7);
    });

    test('water > fire', () {
      expect(BattleService.getElementMultiplier('water', 'fire'), 1.3);
    });

    test('water < grass', () {
      expect(BattleService.getElementMultiplier('water', 'grass'), 0.7);
    });

    test('water < electric', () {
      expect(BattleService.getElementMultiplier('water', 'electric'), 0.7);
    });

    test('electric > water', () {
      expect(BattleService.getElementMultiplier('electric', 'water'), 1.3);
    });

    test('electric > ghost', () {
      expect(BattleService.getElementMultiplier('electric', 'ghost'), 1.3);
    });

    test('electric < stone', () {
      expect(BattleService.getElementMultiplier('electric', 'stone'), 0.7);
    });

    test('stone > electric', () {
      expect(BattleService.getElementMultiplier('stone', 'electric'), 1.3);
    });

    test('stone vs fire is neutral', () {
      expect(BattleService.getElementMultiplier('stone', 'fire'), 1.0);
    });

    test('grass > water', () {
      expect(BattleService.getElementMultiplier('grass', 'water'), 1.3);
    });

    test('grass < fire', () {
      expect(BattleService.getElementMultiplier('grass', 'fire'), 0.7);
    });

    test('ghost > light', () {
      expect(BattleService.getElementMultiplier('ghost', 'light'), 1.3);
    });

    test('ghost < electric', () {
      expect(BattleService.getElementMultiplier('ghost', 'electric'), 0.7);
    });

    test('light > dark', () {
      expect(BattleService.getElementMultiplier('light', 'dark'), 1.3);
    });

    test('light < ghost', () {
      expect(BattleService.getElementMultiplier('light', 'ghost'), 0.7);
    });

    test('dark > ghost', () {
      expect(BattleService.getElementMultiplier('dark', 'ghost'), 1.3);
    });

    test('dark < light', () {
      expect(BattleService.getElementMultiplier('dark', 'light'), 0.7);
    });

    test('unknown element returns 1.0', () {
      expect(BattleService.getElementMultiplier('unknown', 'fire'), 1.0);
      expect(BattleService.getElementMultiplier('fire', 'unknown'), 1.0);
    });
  });

  // ===========================================================================
  // calculateDamage
  // ===========================================================================

  group('calculateDamage', () {
    test('damage is always at least 1.0', () {
      final attacker = _mon(atk: 1, element: 'fire');
      final defender = _mon(def: 9999, element: 'water'); // huge def + disadvantage

      // Run many times to account for variance
      for (int i = 0; i < 100; i++) {
        final dmg = BattleService.calculateDamage(
          attacker: attacker,
          defender: defender,
        );
        expect(dmg, greaterThanOrEqualTo(1.0),
            reason: 'Damage must never be less than 1.0');
      }
    });

    test('higher ATK produces more damage on average', () {
      final weakAttacker = _mon(atk: 10, element: 'fire');
      final strongAttacker = _mon(atk: 100, element: 'fire');
      final defender = _mon(def: 20, element: 'fire');

      double weakTotal = 0;
      double strongTotal = 0;
      const trials = 500;

      for (int i = 0; i < trials; i++) {
        weakTotal += BattleService.calculateDamage(
            attacker: weakAttacker, defender: defender);
        strongTotal += BattleService.calculateDamage(
            attacker: strongAttacker, defender: defender);
      }

      expect(strongTotal / trials, greaterThan(weakTotal / trials),
          reason: 'Stronger attacker should deal more average damage');
    });

    test('higher DEF reduces damage on average', () {
      final attacker = _mon(atk: 50, element: 'fire');
      final weakDef = _mon(def: 10, element: 'fire');
      final strongDef = _mon(def: 100, element: 'fire');

      double weakDefTotal = 0;
      double strongDefTotal = 0;
      const trials = 500;

      for (int i = 0; i < trials; i++) {
        weakDefTotal += BattleService.calculateDamage(
            attacker: attacker, defender: weakDef);
        strongDefTotal += BattleService.calculateDamage(
            attacker: attacker, defender: strongDef);
      }

      expect(strongDefTotal / trials, lessThan(weakDefTotal / trials),
          reason: 'Higher DEF should reduce average damage');
    });
  });

  // ===========================================================================
  // processSingleAttack
  // ===========================================================================

  group('processSingleAttack', () {
    test('reduces target HP', () {
      final attacker = _mon(atk: 50);
      final target = _mon(hp: 200, def: 20);
      final initialHp = target.currentHp;

      BattleService.processSingleAttack(attacker: attacker, target: target);

      expect(target.currentHp, lessThan(initialHp),
          reason: 'Target HP should be reduced after attack');
    });

    test('target HP never goes negative', () {
      final attacker = _mon(atk: 9999);
      final target = _mon(hp: 10, def: 0);

      BattleService.processSingleAttack(attacker: attacker, target: target);

      expect(target.currentHp, greaterThanOrEqualTo(0));
    });

    test('returns a BattleLogEntry with correct attacker and target names', () {
      final attacker = _mon(name: 'Attacker');
      final target = _mon(name: 'Target');

      final log =
          BattleService.processSingleAttack(attacker: attacker, target: target);

      expect(log.attackerName, 'Attacker');
      expect(log.targetName, 'Target');
      expect(log.damage, greaterThan(0));
    });

    test('shield absorbs damage before HP', () {
      final attacker = _mon(atk: 50);
      final target = _mon(hp: 100, def: 0);
      target.shieldHp = 1000; // large shield

      final initialHp = target.currentHp;
      BattleService.processSingleAttack(attacker: attacker, target: target);

      expect(target.currentHp, equals(initialHp),
          reason: 'HP should not change when shield absorbs all damage');
      expect(target.shieldHp, lessThan(1000),
          reason: 'Shield should be reduced');
    });
  });

  // ===========================================================================
  // selectTarget
  // ===========================================================================

  group('selectTarget', () {
    test('returns null for empty list', () {
      expect(BattleService.selectTarget([]), isNull);
    });

    test('returns null when all enemies are dead', () {
      final dead = _mon(hp: 0);
      dead.currentHp = 0;
      expect(BattleService.selectTarget([dead]), isNull);
    });

    test('returns an alive monster', () {
      final alive = _mon(name: 'Alive');
      final dead = _mon(name: 'Dead');
      dead.currentHp = 0;

      final target = BattleService.selectTarget([dead, alive]);
      expect(target, isNotNull);
      expect(target!.name, 'Alive');
    });
  });

  // ===========================================================================
  // getTurnOrder
  // ===========================================================================

  group('getTurnOrder', () {
    test('sorts by speed descending (fastest first)', () {
      final slow = _mon(name: 'Slow', spd: 5);
      final fast = _mon(name: 'Fast', spd: 20);
      final mid = _mon(name: 'Mid', spd: 10);

      final order = BattleService.getTurnOrder([slow, fast, mid]);

      expect(order[0].name, 'Fast');
      expect(order[1].name, 'Mid');
      expect(order[2].name, 'Slow');
    });

    test('excludes dead monsters', () {
      final alive = _mon(name: 'Alive', spd: 10);
      final dead = _mon(name: 'Dead', spd: 100);
      dead.currentHp = 0;

      final order = BattleService.getTurnOrder([alive, dead]);

      expect(order.length, 1);
      expect(order[0].name, 'Alive');
    });
  });

  // ===========================================================================
  // checkBattleEnd
  // ===========================================================================

  group('checkBattleEnd', () {
    test('returns victory when all enemies dead', () {
      final player = [_mon(name: 'P1')];
      final enemy = [_mon(name: 'E1')];
      enemy[0].currentHp = 0;

      expect(BattleService.checkBattleEnd(player, enemy), BattlePhase.victory);
    });

    test('returns defeat when all players dead', () {
      final player = [_mon(name: 'P1')];
      final enemy = [_mon(name: 'E1')];
      player[0].currentHp = 0;

      expect(BattleService.checkBattleEnd(player, enemy), BattlePhase.defeat);
    });

    test('returns fighting when both teams have alive members', () {
      final player = [_mon(name: 'P1')];
      final enemy = [_mon(name: 'E1')];

      expect(
          BattleService.checkBattleEnd(player, enemy), BattlePhase.fighting);
    });

    test('returns victory when all enemies dead (multi-monster)', () {
      final players = [_mon(name: 'P1'), _mon(name: 'P2')];
      final enemies = [_mon(name: 'E1'), _mon(name: 'E2')];
      enemies[0].currentHp = 0;
      enemies[1].currentHp = 0;

      expect(BattleService.checkBattleEnd(players, enemies),
          BattlePhase.victory);
    });

    test('returns fighting when some enemies still alive', () {
      final players = [_mon(name: 'P1')];
      final enemies = [_mon(name: 'E1'), _mon(name: 'E2')];
      enemies[0].currentHp = 0;

      expect(BattleService.checkBattleEnd(players, enemies),
          BattlePhase.fighting);
    });
  });

  // ===========================================================================
  // processBurn
  // ===========================================================================

  group('processBurn', () {
    test('returns null when monster has no burn', () {
      final mon = _mon();
      expect(BattleService.processBurn(mon), isNull);
    });

    test('applies burn damage and decrements burn turns', () {
      final mon = _mon(hp: 100);
      mon.burnTurns = 3;
      mon.burnDamagePerTurn = 10;

      final log = BattleService.processBurn(mon);

      expect(log, isNotNull);
      expect(mon.currentHp, 90);
      expect(mon.burnTurns, 2);
    });

    test('returns null for dead monster', () {
      final mon = _mon(hp: 0);
      mon.currentHp = 0;
      mon.burnTurns = 3;
      mon.burnDamagePerTurn = 10;

      expect(BattleService.processBurn(mon), isNull);
    });
  });

  // ===========================================================================
  // processStun
  // ===========================================================================

  group('processStun', () {
    test('returns null when monster has no stun', () {
      final mon = _mon();
      expect(BattleService.processStun(mon), isNull);
    });

    test('consumes stun turn and returns log', () {
      final mon = _mon();
      mon.stunTurns = 2;

      final log = BattleService.processStun(mon);

      expect(log, isNotNull);
      expect(mon.stunTurns, 1);
      expect(log!.description, contains('기절'));
    });
  });

  // ===========================================================================
  // tickSkillCooldown
  // ===========================================================================

  group('tickSkillCooldown', () {
    test('decrements cooldown by 1', () {
      final mon = _mon();
      mon.skillCooldown = 3;

      BattleService.tickSkillCooldown(mon);

      expect(mon.skillCooldown, 2);
    });

    test('does not go below 0', () {
      final mon = _mon();
      mon.skillCooldown = 0;

      BattleService.tickSkillCooldown(mon);

      expect(mon.skillCooldown, 0);
    });
  });

  // ===========================================================================
  // createEnemiesForStage
  // ===========================================================================

  group('createEnemiesForStage', () {
    test('returns enemies for valid stage 1', () {
      final enemies = BattleService.createEnemiesForStage(1);
      expect(enemies, isNotEmpty, reason: 'Stage 1 should have enemies');
    });

    test('all enemies have positive stats', () {
      final enemies = BattleService.createEnemiesForStage(1);
      for (final e in enemies) {
        expect(e.atk, greaterThan(0));
        expect(e.def, greaterThan(0));
        expect(e.maxHp, greaterThan(0));
        expect(e.spd, greaterThan(0));
      }
    });

    test('enemy stats scale with stage level', () {
      final earlyEnemies = BattleService.createEnemiesForStage(1);
      final lateEnemies = BattleService.createEnemiesForStage(25);

      if (earlyEnemies.isNotEmpty && lateEnemies.isNotEmpty) {
        // Later stage enemies should generally have higher stats
        final earlyAvgAtk =
            earlyEnemies.map((e) => e.atk).reduce((a, b) => a + b) /
                earlyEnemies.length;
        final lateAvgAtk =
            lateEnemies.map((e) => e.atk).reduce((a, b) => a + b) /
                lateEnemies.length;
        expect(lateAvgAtk, greaterThan(earlyAvgAtk),
            reason: 'Later stage enemies should be stronger');
      }
    });
  });
}
