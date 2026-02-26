import 'package:flutter_test/flutter_test.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/domain/services/dungeon_service.dart';

BattleMonster _mon({
  String name = 'Test',
  double maxHp = 100,
  double currentHp = 100,
}) {
  return BattleMonster(
    monsterId: 'test',
    templateId: 'test',
    name: name,
    element: 'fire',
    size: 'medium',
    rarity: 1,
    maxHp: maxHp,
    currentHp: currentHp,
    atk: 50,
    def: 30,
    spd: 10,
    skillCooldown: 3,
    skillMaxCooldown: 3,
  );
}

void main() {
  // ===========================================================================
  // createEnemiesForFloor
  // ===========================================================================

  group('createEnemiesForFloor', () {
    test('floor 1 creates 2 enemies (floor <= 5)', () {
      final enemies = DungeonService.createEnemiesForFloor(1);
      expect(enemies.length, 2);
    });

    test('floor 5 creates 2 enemies', () {
      final enemies = DungeonService.createEnemiesForFloor(5);
      expect(enemies.length, 2);
    });

    test('floor 6 creates 3 enemies (floor > 5)', () {
      final enemies = DungeonService.createEnemiesForFloor(6);
      expect(enemies.length, 3);
    });

    test('floor 10 creates 3 enemies', () {
      final enemies = DungeonService.createEnemiesForFloor(10);
      expect(enemies.length, 3);
    });

    test('enemies have correct level in name', () {
      final enemies = DungeonService.createEnemiesForFloor(1);
      final expectedLevel = (5 + 1 * 1.8).round();
      for (final e in enemies) {
        expect(e.name, contains('Lv.$expectedLevel'));
      }
    });

    test('enemies on higher floors have higher stats', () {
      final floor1 = DungeonService.createEnemiesForFloor(1);
      final floor20 = DungeonService.createEnemiesForFloor(20);

      // Average ATK should be higher on floor 20
      final avgAtk1 =
          floor1.map((e) => e.atk).reduce((a, b) => a + b) / floor1.length;
      final avgAtk20 =
          floor20.map((e) => e.atk).reduce((a, b) => a + b) / floor20.length;

      expect(avgAtk20, greaterThan(avgAtk1),
          reason: 'Higher floor enemies should have higher ATK');
    });

    test('enemy IDs contain floor number', () {
      final enemies = DungeonService.createEnemiesForFloor(7);
      for (final e in enemies) {
        expect(e.monsterId, contains('7'));
      }
    });
  });

  // ===========================================================================
  // calculateFloorReward
  // ===========================================================================

  group('calculateFloorReward', () {
    test('floor 1 gives 40 gold, 25 exp', () {
      final reward = DungeonService.calculateFloorReward(1);
      expect(reward.gold, 40);
      expect(reward.exp, 25);
    });

    test('floor 5 gives bonus shard (every 5 floors)', () {
      final reward = DungeonService.calculateFloorReward(5);
      expect(reward.bonusShard, 1);
    });

    test('floor 4 gives no shard', () {
      final reward = DungeonService.calculateFloorReward(4);
      expect(reward.bonusShard, isNull);
    });

    test('floor 10 gives 400 gold, 250 exp, shard', () {
      final reward = DungeonService.calculateFloorReward(10);
      expect(reward.gold, 400);
      expect(reward.exp, 250);
      expect(reward.bonusShard, 1);
    });

    test('rewards scale linearly with floor', () {
      final r5 = DungeonService.calculateFloorReward(5);
      final r10 = DungeonService.calculateFloorReward(10);
      expect(r10.gold, r5.gold * 2);
      expect(r10.exp, r5.exp * 2);
    });
  });

  // ===========================================================================
  // calculateTotalReward
  // ===========================================================================

  group('calculateTotalReward', () {
    test('total for floor 1 equals floor 1 reward', () {
      final total = DungeonService.calculateTotalReward(1);
      expect(total.gold, 40);
      expect(total.exp, 25);
    });

    test('total for floor 3 is sum of floors 1+2+3', () {
      final total = DungeonService.calculateTotalReward(3);
      // gold: 40*1 + 40*2 + 40*3 = 40+80+120 = 240
      expect(total.gold, 240);
      // exp: 25*1 + 25*2 + 25*3 = 25+50+75 = 150
      expect(total.exp, 150);
    });

    test('total for floor 5 includes 1 shard', () {
      final total = DungeonService.calculateTotalReward(5);
      expect(total.bonusShard, 1);
    });

    test('total for floor 10 includes 2 shards (at floor 5 and 10)', () {
      final total = DungeonService.calculateTotalReward(10);
      expect(total.bonusShard, 2);
    });

    test('total for floor 0 is zero', () {
      final total = DungeonService.calculateTotalReward(0);
      expect(total.gold, 0);
      expect(total.exp, 0);
      expect(total.bonusShard, isNull);
    });
  });

  // ===========================================================================
  // applyFloorHeal
  // ===========================================================================

  group('applyFloorHeal', () {
    test('heals alive monsters by 25%', () {
      final mon = _mon(maxHp: 100, currentHp: 60);
      DungeonService.applyFloorHeal([mon]);

      // 60 + 100*0.25 = 85
      expect(mon.currentHp, 85);
    });

    test('does not exceed maxHp', () {
      final mon = _mon(maxHp: 100, currentHp: 90);
      DungeonService.applyFloorHeal([mon]);

      expect(mon.currentHp, 100); // capped at maxHp
    });

    test('does not heal dead monsters', () {
      final mon = _mon(maxHp: 100, currentHp: 0);
      mon.currentHp = 0;
      DungeonService.applyFloorHeal([mon]);

      expect(mon.currentHp, 0);
    });

    test('resets burn status', () {
      final mon = _mon();
      mon.burnTurns = 3;
      mon.burnDamagePerTurn = 10;

      DungeonService.applyFloorHeal([mon]);

      expect(mon.burnTurns, 0);
      expect(mon.burnDamagePerTurn, 0);
    });

    test('resets stun status', () {
      final mon = _mon();
      mon.stunTurns = 2;

      DungeonService.applyFloorHeal([mon]);

      expect(mon.stunTurns, 0);
    });

    test('resets skill cooldown to max', () {
      final mon = _mon();
      mon.skillCooldown = 1;

      DungeonService.applyFloorHeal([mon]);

      expect(mon.skillCooldown, mon.skillMaxCooldown);
    });
  });
}
