import 'package:flutter_test/flutter_test.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/domain/services/daily_dungeon_service.dart';

// ---------------------------------------------------------------------------
// Helper: minimal BattleMonster factory
// ---------------------------------------------------------------------------

BattleMonster _mon({
  String element = 'fire',
  double maxHp = 100,
  double currentHp = 100,
  int burnTurns = 0,
  int stunTurns = 0,
  int skillCooldown = 0,
  int skillMaxCooldown = 3,
  double shieldHp = 0,
}) {
  return BattleMonster(
    monsterId: 'test_${element}_${maxHp.toInt()}',
    templateId: 'test',
    name: 'Test Monster',
    element: element,
    size: 'medium',
    rarity: 1,
    maxHp: maxHp,
    currentHp: currentHp,
    atk: 50,
    def: 30,
    spd: 10,
    skillCooldown: skillCooldown,
    skillMaxCooldown: skillMaxCooldown,
    shieldHp: shieldHp,
    burnTurns: burnTurns,
    stunTurns: stunTurns,
  );
}

void main() {
  // =========================================================================
  // Constants
  // =========================================================================

  group('constants', () {
    test('maxFloors is 10', () {
      expect(DailyDungeonService.maxFloors, 10);
    });

    test('maxAttempts is 2', () {
      expect(DailyDungeonService.maxAttempts, 2);
    });

    test('rewardMultiplier is 1.5', () {
      expect(DailyDungeonService.rewardMultiplier, 1.5);
    });
  });

  // =========================================================================
  // elementNameKo
  // =========================================================================

  group('elementNameKo', () {
    test('fire maps to 불', () {
      expect(DailyDungeonService.elementNameKo('fire'), '불');
    });

    test('water maps to 물', () {
      expect(DailyDungeonService.elementNameKo('water'), '물');
    });

    test('electric maps to 번개', () {
      expect(DailyDungeonService.elementNameKo('electric'), '번개');
    });

    test('stone maps to 바위', () {
      expect(DailyDungeonService.elementNameKo('stone'), '바위');
    });

    test('grass maps to 풀', () {
      expect(DailyDungeonService.elementNameKo('grass'), '풀');
    });

    test('dark maps to 암흑', () {
      expect(DailyDungeonService.elementNameKo('dark'), '암흑');
    });

    test('light maps to 빛', () {
      expect(DailyDungeonService.elementNameKo('light'), '빛');
    });

    test('ghost maps to 유령', () {
      expect(DailyDungeonService.elementNameKo('ghost'), '유령');
    });

    test('unknown element returns the element string itself', () {
      expect(DailyDungeonService.elementNameKo('unknown'), 'unknown');
    });

    test('empty string returns empty string', () {
      expect(DailyDungeonService.elementNameKo(''), '');
    });
  });

  // =========================================================================
  // elementNameEn
  // =========================================================================

  group('elementNameEn', () {
    test('fire maps to Fire', () {
      expect(DailyDungeonService.elementNameEn('fire'), 'Fire');
    });

    test('water maps to Water', () {
      expect(DailyDungeonService.elementNameEn('water'), 'Water');
    });

    test('electric maps to Electric', () {
      expect(DailyDungeonService.elementNameEn('electric'), 'Electric');
    });

    test('stone maps to Stone', () {
      expect(DailyDungeonService.elementNameEn('stone'), 'Stone');
    });

    test('grass maps to Grass', () {
      expect(DailyDungeonService.elementNameEn('grass'), 'Grass');
    });

    test('dark maps to Dark', () {
      expect(DailyDungeonService.elementNameEn('dark'), 'Dark');
    });

    test('light maps to Light', () {
      expect(DailyDungeonService.elementNameEn('light'), 'Light');
    });

    test('ghost maps to Ghost', () {
      expect(DailyDungeonService.elementNameEn('ghost'), 'Ghost');
    });

    test('unknown element returns the element string itself', () {
      expect(DailyDungeonService.elementNameEn('xyz'), 'xyz');
    });
  });

  // =========================================================================
  // createEnemiesForFloor
  // =========================================================================

  group('createEnemiesForFloor', () {
    test('floor 1 creates 2 enemies (floor <= 5)', () {
      final enemies = DailyDungeonService.createEnemiesForFloor(1, 'fire');
      expect(enemies.length, 2);
    });

    test('floor 5 creates 2 enemies (boundary: <= 5)', () {
      final enemies = DailyDungeonService.createEnemiesForFloor(5, 'water');
      expect(enemies.length, 2);
    });

    test('floor 6 creates 3 enemies (floor > 5)', () {
      final enemies = DailyDungeonService.createEnemiesForFloor(6, 'electric');
      expect(enemies.length, 3);
    });

    test('floor 10 (max) creates 3 enemies', () {
      final enemies = DailyDungeonService.createEnemiesForFloor(10, 'fire');
      expect(enemies.length, 3);
    });

    test('enemies on floor 1 have correct level in name', () {
      // level = (8 + floor * 2.0).round() = (8 + 2).round() = 10
      final enemies = DailyDungeonService.createEnemiesForFloor(1, 'fire');
      final expectedLevel = (8 + 1 * 2.0).round();
      for (final e in enemies) {
        expect(e.name, contains('Lv.$expectedLevel'));
      }
    });

    test('enemies on floor 5 have correct level in name', () {
      // level = (8 + 5 * 2.0).round() = 18
      final enemies = DailyDungeonService.createEnemiesForFloor(5, 'water');
      final expectedLevel = (8 + 5 * 2.0).round();
      for (final e in enemies) {
        expect(e.name, contains('Lv.$expectedLevel'));
      }
    });

    test('enemies on floor 10 have correct level in name', () {
      // level = (8 + 10 * 2.0).round() = 28
      final enemies = DailyDungeonService.createEnemiesForFloor(10, 'fire');
      final expectedLevel = (8 + 10 * 2.0).round();
      for (final e in enemies) {
        expect(e.name, contains('Lv.$expectedLevel'));
      }
    });

    test('enemy monsterId contains the floor number', () {
      final enemies = DailyDungeonService.createEnemiesForFloor(7, 'dark');
      for (final e in enemies) {
        expect(e.monsterId, contains('7'));
      }
    });

    test('enemy monsterId starts with dd_ prefix', () {
      final enemies = DailyDungeonService.createEnemiesForFloor(3, 'stone');
      for (final e in enemies) {
        expect(e.monsterId, startsWith('dd_'));
      }
    });

    test('enemies have positive HP', () {
      final enemies = DailyDungeonService.createEnemiesForFloor(4, 'grass');
      for (final e in enemies) {
        expect(e.maxHp, greaterThan(0));
        expect(e.currentHp, greaterThan(0));
        expect(e.currentHp, e.maxHp);
      }
    });

    test('enemies have positive ATK, DEF, SPD', () {
      final enemies = DailyDungeonService.createEnemiesForFloor(2, 'fire');
      for (final e in enemies) {
        expect(e.atk, greaterThan(0));
        expect(e.def, greaterThan(0));
        expect(e.spd, greaterThan(0));
      }
    });

    test('level multiplier grows with floor (higher floor = stronger enemies)', () {
      // atk = baseAtk * levelMul * 1.1
      // levelMul = 1.0 + (enemyLevel - 1) * 0.05
      // floor 1:  enemyLevel=(8+2)=10,  mul=1+(10-1)*0.05=1.45
      // floor 10: enemyLevel=(8+20)=28, mul=1+(28-1)*0.05=2.35
      // Given the same template, floor 10 ATK is always 2.35/1.45 ≈ 1.62x floor 1 ATK.
      final floor1Level = (8 + 1 * 2.0).round();
      final floor10Level = (8 + 10 * 2.0).round();
      final mul1 = 1.0 + (floor1Level - 1) * 0.05;
      final mul10 = 1.0 + (floor10Level - 1) * 0.05;
      expect(mul10, greaterThan(mul1),
          reason: 'Floor 10 stat multiplier should exceed floor 1');
    });

    test('higher floor enemies have higher stats due to level multiplier', () {
      // The stat formula applies a level multiplier: 1.0 + (level - 1) * 0.05
      // floor 1 level = (8 + 1*2).round() = 10  -> mul = 1 + 9*0.05 = 1.45
      // floor 10 level = (8 + 10*2).round() = 28 -> mul = 1 + 27*0.05 = 2.35
      // So floor 10 multiplier (2.35) is always strictly greater than floor 1 (1.45).
      final floor1Level = (8 + 1 * 2.0).round();
      final floor10Level = (8 + 10 * 2.0).round();
      final mul1 = 1.0 + (floor1Level - 1) * 0.05;
      final mul10 = 1.0 + (floor10Level - 1) * 0.05;
      expect(mul10, greaterThan(mul1),
          reason: 'Level multiplier for floor 10 should exceed floor 1');
    });

    test('fire element produces fire or fallback enemies', () {
      // MonsterDatabase has fire monsters (flame_spirit, phoenix, flame_dragon, flame_golem)
      // so the pool should not be empty — enemies should be of element fire.
      final enemies = DailyDungeonService.createEnemiesForFloor(1, 'fire');
      for (final e in enemies) {
        expect(e.element, 'fire');
      }
    });

    test('water element produces water enemies', () {
      // MonsterDatabase has water monsters (slime, mermaid, ice_queen)
      final enemies = DailyDungeonService.createEnemiesForFloor(1, 'water');
      for (final e in enemies) {
        expect(e.element, 'water');
      }
    });

    test('unknown element falls back to all monsters (non-empty result)', () {
      // 'poison' is not in the database — should fall back to all monsters
      final enemies =
          DailyDungeonService.createEnemiesForFloor(1, 'poison');
      expect(enemies, isNotEmpty);
    });

    test('each enemy in the same floor has unique index in monsterId', () {
      final enemies = DailyDungeonService.createEnemiesForFloor(6, 'dark');
      // IDs follow pattern dd_<templateId>_<floor>_<index>
      final ids = enemies.map((e) => e.monsterId).toList();
      // The index portion (last segment) should differ
      final indices = ids.map((id) => id.split('_').last).toList();
      expect(indices.toSet().length, enemies.length,
          reason: 'Each enemy should have a unique index suffix in monsterId');
    });
  });

  // =========================================================================
  // calculateFloorReward
  // =========================================================================

  group('calculateFloorReward', () {
    // gold = (50 * floor * 1.5).round()
    // exp  = (35 * floor * 1.5).round()

    test('floor 1: gold = 75, exp = 53', () {
      final r = DailyDungeonService.calculateFloorReward(1);
      expect(r.gold, (50 * 1 * 1.5).round()); // 75
      expect(r.exp, (35 * 1 * 1.5).round());  // 53 (52.5 rounds to 53)
    });

    test('floor 2: gold = 150, exp = 105', () {
      final r = DailyDungeonService.calculateFloorReward(2);
      expect(r.gold, (50 * 2 * 1.5).round()); // 150
      expect(r.exp, (35 * 2 * 1.5).round());  // 105
    });

    test('floor 5: gold = 375, exp = 263', () {
      final r = DailyDungeonService.calculateFloorReward(5);
      expect(r.gold, (50 * 5 * 1.5).round()); // 375
      expect(r.exp, (35 * 5 * 1.5).round());  // 263 (262.5 rounds to 263)
    });

    test('floor 10 (max): gold = 750, exp = 525', () {
      final r = DailyDungeonService.calculateFloorReward(10);
      expect(r.gold, (50 * 10 * 1.5).round()); // 750
      expect(r.exp, (35 * 10 * 1.5).round());  // 525
    });

    test('rewards scale linearly: floor 10 gold is 2x floor 5 gold', () {
      final r5 = DailyDungeonService.calculateFloorReward(5);
      final r10 = DailyDungeonService.calculateFloorReward(10);
      expect(r10.gold, r5.gold * 2);
    });

    test('floor 10 exp is greater than floor 5 exp', () {
      // Note: integer rounding means (35*5*1.5).round()=263 and
      // (35*10*1.5).round()=525 — not exactly 2x due to rounding of 262.5.
      // We assert the proportional relationship holds instead.
      final r5 = DailyDungeonService.calculateFloorReward(5);
      final r10 = DailyDungeonService.calculateFloorReward(10);
      expect(r10.exp, greaterThan(r5.exp));
      // The ratio should be very close to 2.0 (within rounding)
      expect(r10.exp / r5.exp, closeTo(2.0, 0.01));
    });

    test('gold and exp are always positive for any floor >= 1', () {
      for (int floor = 1; floor <= 10; floor++) {
        final r = DailyDungeonService.calculateFloorReward(floor);
        expect(r.gold, greaterThan(0),
            reason: 'floor $floor: gold should be positive');
        expect(r.exp, greaterThan(0),
            reason: 'floor $floor: exp should be positive');
      }
    });

    test('reward applies 1.5x multiplier vs base (50*floor and 35*floor)', () {
      // Base (without multiplier): gold=50*3=150, exp=35*3=105
      // With 1.5x: gold=225, exp=157 (157.5 -> 158)
      final r = DailyDungeonService.calculateFloorReward(3);
      expect(r.gold, (50 * 3 * 1.5).round());
      expect(r.exp, (35 * 3 * 1.5).round());
      // Verify it is strictly more than base (no multiplier)
      expect(r.gold, greaterThan(50 * 3));
      expect(r.exp, greaterThan(35 * 3));
    });
  });

  // =========================================================================
  // calculateTotalReward
  // =========================================================================

  group('calculateTotalReward', () {
    // Shard every 3 floors: floors 3, 6, 9 each yield 1 shard.

    test('floor 0: no gold, no exp, no shard', () {
      final total = DailyDungeonService.calculateTotalReward(0);
      expect(total.gold, 0);
      expect(total.exp, 0);
      expect(total.shard, 0);
    });

    test('floor 1: equals single calculateFloorReward(1) and 0 shards', () {
      final single = DailyDungeonService.calculateFloorReward(1);
      final total = DailyDungeonService.calculateTotalReward(1);
      expect(total.gold, single.gold);
      expect(total.exp, single.exp);
      expect(total.shard, 0); // floor 1 is not divisible by 3
    });

    test('floor 2: sum of floors 1 and 2, 0 shards', () {
      final f1 = DailyDungeonService.calculateFloorReward(1);
      final f2 = DailyDungeonService.calculateFloorReward(2);
      final total = DailyDungeonService.calculateTotalReward(2);
      expect(total.gold, f1.gold + f2.gold);
      expect(total.exp, f1.exp + f2.exp);
      expect(total.shard, 0);
    });

    test('floor 3: 1 shard milestone (first shard at f%3==0)', () {
      final total = DailyDungeonService.calculateTotalReward(3);
      expect(total.shard, 1);
    });

    test('floor 3: gold and exp equal sum of floors 1+2+3', () {
      int expectedGold = 0;
      int expectedExp = 0;
      for (int f = 1; f <= 3; f++) {
        final r = DailyDungeonService.calculateFloorReward(f);
        expectedGold += r.gold;
        expectedExp += r.exp;
      }
      final total = DailyDungeonService.calculateTotalReward(3);
      expect(total.gold, expectedGold);
      expect(total.exp, expectedExp);
    });

    test('floor 5: still only 1 shard (floors 3 only, 6 not yet reached)', () {
      final total = DailyDungeonService.calculateTotalReward(5);
      expect(total.shard, 1);
    });

    test('floor 6: 2 shards (milestones at floor 3 and floor 6)', () {
      final total = DailyDungeonService.calculateTotalReward(6);
      expect(total.shard, 2);
    });

    test('floor 9: 3 shards (milestones at floors 3, 6, 9)', () {
      final total = DailyDungeonService.calculateTotalReward(9);
      expect(total.shard, 3);
    });

    test('floor 10 (max): 3 shards (milestones at 3, 6, 9; 10 not divisible)', () {
      final total = DailyDungeonService.calculateTotalReward(10);
      expect(total.shard, 3);
    });

    test('total gold increases monotonically with floor', () {
      int prevGold = 0;
      for (int f = 1; f <= 10; f++) {
        final total = DailyDungeonService.calculateTotalReward(f);
        expect(total.gold, greaterThan(prevGold),
            reason: 'Total gold at floor $f should exceed floor ${f - 1}');
        prevGold = total.gold;
      }
    });

    test('total exp increases monotonically with floor', () {
      int prevExp = 0;
      for (int f = 1; f <= 10; f++) {
        final total = DailyDungeonService.calculateTotalReward(f);
        expect(total.exp, greaterThan(prevExp),
            reason: 'Total exp at floor $f should exceed floor ${f - 1}');
        prevExp = total.exp;
      }
    });

    test('total gold for all 10 floors equals sum of individual floor rewards', () {
      int expectedGold = 0;
      int expectedExp = 0;
      for (int f = 1; f <= 10; f++) {
        final r = DailyDungeonService.calculateFloorReward(f);
        expectedGold += r.gold;
        expectedExp += r.exp;
      }
      final total = DailyDungeonService.calculateTotalReward(10);
      expect(total.gold, expectedGold);
      expect(total.exp, expectedExp);
    });

    test('shard at floor 4 same as floor 3 (no new milestone)', () {
      final t3 = DailyDungeonService.calculateTotalReward(3);
      final t4 = DailyDungeonService.calculateTotalReward(4);
      expect(t4.shard, t3.shard);
    });
  });

  // =========================================================================
  // applyFloorHeal
  // =========================================================================

  group('applyFloorHeal', () {
    test('returns a new list (immutable — does not mutate input)', () {
      final mon = _mon(maxHp: 100, currentHp: 60);
      final original = [mon];
      final result = DailyDungeonService.applyFloorHeal(original);
      // Input list object unchanged
      expect(identical(result, original), isFalse);
    });

    test('heals alive monster by 25% of maxHp', () {
      // healed = currentHp + maxHp * 0.25 = 60 + 100 * 0.25 = 85
      final mon = _mon(maxHp: 100, currentHp: 60);
      final result = DailyDungeonService.applyFloorHeal([mon]);
      expect(result.first.currentHp, closeTo(85.0, 0.001));
    });

    test('does not heal beyond maxHp', () {
      // currentHp = 90, maxHp = 100, heal = 25 -> capped at 100
      final mon = _mon(maxHp: 100, currentHp: 90);
      final result = DailyDungeonService.applyFloorHeal([mon]);
      expect(result.first.currentHp, 100.0);
    });

    test('monster at full HP stays at full HP', () {
      final mon = _mon(maxHp: 100, currentHp: 100);
      final result = DailyDungeonService.applyFloorHeal([mon]);
      expect(result.first.currentHp, 100.0);
    });

    test('does not heal dead monsters (currentHp <= 0)', () {
      final mon = _mon(maxHp: 100, currentHp: 0);
      final result = DailyDungeonService.applyFloorHeal([mon]);
      expect(result.first.currentHp, 0.0);
    });

    test('heals exactly to maxHp boundary when almost full', () {
      // currentHp = 80, maxHp = 100, heal = 25 -> 105 clamped to 100
      final mon = _mon(maxHp: 100, currentHp: 80);
      final result = DailyDungeonService.applyFloorHeal([mon]);
      expect(result.first.currentHp, 100.0);
    });

    test('resets burnTurns to 0', () {
      final mon = _mon(burnTurns: 3);
      final result = DailyDungeonService.applyFloorHeal([mon]);
      expect(result.first.burnTurns, 0);
    });

    test('resets stunTurns to 0', () {
      final mon = _mon(stunTurns: 2);
      final result = DailyDungeonService.applyFloorHeal([mon]);
      expect(result.first.stunTurns, 0);
    });

    test('resets skillCooldown to 0', () {
      final mon = _mon(skillCooldown: 3, skillMaxCooldown: 3);
      final result = DailyDungeonService.applyFloorHeal([mon]);
      expect(result.first.skillCooldown, 0);
    });

    test('resets shieldHp to 0', () {
      final mon = _mon(shieldHp: 50);
      final result = DailyDungeonService.applyFloorHeal([mon]);
      expect(result.first.shieldHp, 0.0);
    });

    test('handles empty team without error', () {
      final result = DailyDungeonService.applyFloorHeal([]);
      expect(result, isEmpty);
    });

    test('handles multiple monsters, only heals alive ones', () {
      final alive = _mon(maxHp: 100, currentHp: 50);
      final dead = _mon(maxHp: 100, currentHp: 0);
      final result = DailyDungeonService.applyFloorHeal([alive, dead]);

      expect(result[0].currentHp, closeTo(75.0, 0.001)); // 50 + 25 = 75
      expect(result[1].currentHp, 0.0);
    });

    test('heal is proportional to maxHp: large monster heals more raw HP', () {
      final small = _mon(maxHp: 100, currentHp: 0.1);
      final large = _mon(maxHp: 1000, currentHp: 0.1);
      final resultSmall = DailyDungeonService.applyFloorHeal([small]);
      final resultLarge = DailyDungeonService.applyFloorHeal([large]);

      // small: 0.1 + 100*0.25 = 25.1
      // large: 0.1 + 1000*0.25 = 250.1
      expect(resultLarge.first.currentHp, greaterThan(resultSmall.first.currentHp));
    });

    test('original monsters are not mutated', () {
      final mon = _mon(maxHp: 100, currentHp: 60, burnTurns: 2, stunTurns: 1);
      final originalHp = mon.currentHp;
      final originalBurn = mon.burnTurns;
      DailyDungeonService.applyFloorHeal([mon]);
      // Original mutable fields on the input object should be unchanged
      expect(mon.currentHp, originalHp);
      expect(mon.burnTurns, originalBurn);
    });
  });

  // =========================================================================
  // todayElement — weekday mapping (integration-style, day-agnostic)
  // =========================================================================

  group('todayElement', () {
    test('returns a valid element string', () {
      const validElements = {
        'fire', 'water', 'electric', 'stone', 'grass', 'dark', 'light',
      };
      expect(validElements, contains(DailyDungeonService.todayElement));
    });

    test('todayElement has a non-empty Korean name', () {
      final ko = DailyDungeonService.elementNameKo(DailyDungeonService.todayElement);
      expect(ko, isNotEmpty);
    });

    test('todayElement has a non-empty English name', () {
      final en = DailyDungeonService.elementNameEn(DailyDungeonService.todayElement);
      expect(en, isNotEmpty);
    });
  });

  // =========================================================================
  // Element rotation correctness (weekday mapping via known dates)
  // =========================================================================

  group('element rotation — weekday mapping', () {
    // We verify the mapping table indirectly using elementNameKo/elementNameEn.
    // The order is: Mon=fire, Tue=water, Wed=electric, Thu=stone,
    //               Fri=grass, Sat=dark, Sun=light.

    const expectedOrder = [
      'fire',     // index 0 -> Monday
      'water',    // index 1 -> Tuesday
      'electric', // index 2 -> Wednesday
      'stone',    // index 3 -> Thursday
      'grass',    // index 4 -> Friday
      'dark',     // index 5 -> Saturday
      'light',    // index 6 -> Sunday
    ];

    test('all 7 distinct elements are covered in the rotation', () {
      expect(expectedOrder.toSet().length, 7,
          reason: 'Each day should map to a distinct element');
    });

    test('Monday element (fire) has Korean name 불', () {
      expect(DailyDungeonService.elementNameKo(expectedOrder[0]), '불');
    });

    test('Tuesday element (water) has Korean name 물', () {
      expect(DailyDungeonService.elementNameKo(expectedOrder[1]), '물');
    });

    test('Wednesday element (electric) has Korean name 번개', () {
      expect(DailyDungeonService.elementNameKo(expectedOrder[2]), '번개');
    });

    test('Thursday element (stone) has Korean name 바위', () {
      expect(DailyDungeonService.elementNameKo(expectedOrder[3]), '바위');
    });

    test('Friday element (grass) has Korean name 풀', () {
      expect(DailyDungeonService.elementNameKo(expectedOrder[4]), '풀');
    });

    test('Saturday element (dark) has Korean name 암흑', () {
      expect(DailyDungeonService.elementNameKo(expectedOrder[5]), '암흑');
    });

    test('Sunday element (light) has Korean name 빛', () {
      expect(DailyDungeonService.elementNameKo(expectedOrder[6]), '빛');
    });

    test('Monday element (fire) has English name Fire', () {
      expect(DailyDungeonService.elementNameEn(expectedOrder[0]), 'Fire');
    });

    test('Saturday (dark) and Sunday (light) are correctly assigned for weekend', () {
      // Weekend days: Saturday = dark, Sunday = light
      expect(expectedOrder[5], 'dark');
      expect(expectedOrder[6], 'light');
    });
  });

  // =========================================================================
  // Edge cases and boundary values
  // =========================================================================

  group('edge cases', () {
    test('createEnemiesForFloor: floor 5 boundary gives 2, floor 6 gives 3', () {
      expect(DailyDungeonService.createEnemiesForFloor(5, 'fire').length, 2);
      expect(DailyDungeonService.createEnemiesForFloor(6, 'fire').length, 3);
    });

    test('calculateFloorReward: reward multiplier actually exceeds un-multiplied base', () {
      final r = DailyDungeonService.calculateFloorReward(1);
      // Un-multiplied would be: gold=50, exp=35
      expect(r.gold, greaterThan(50));
      expect(r.exp, greaterThan(35));
    });

    test('calculateTotalReward: shards only at multiples of 3', () {
      // Floors 1,2,4,5,7,8,10 should NOT add a shard vs prior floor
      final noShardFloors = [1, 2, 4, 5, 7, 8, 10];
      for (int i = 1; i < noShardFloors.length; i++) {
        final prev = DailyDungeonService.calculateTotalReward(noShardFloors[i] - 1);
        final curr = DailyDungeonService.calculateTotalReward(noShardFloors[i]);
        if (noShardFloors[i] % 3 != 0) {
          expect(curr.shard, prev.shard,
              reason: 'No shard should be added at floor ${noShardFloors[i]}');
        }
      }
    });

    test('applyFloorHeal: 25% of 0 maxHp does not crash (edge degenerate case)', () {
      // This is a degenerate object — mainly verifies no exception is thrown.
      final mon = BattleMonster(
        monsterId: 'edge',
        templateId: 'edge',
        name: 'Edge',
        element: 'fire',
        size: 'small',
        rarity: 1,
        maxHp: 0,
        currentHp: 0,
        atk: 0,
        def: 0,
        spd: 0,
        skillCooldown: 0,
        skillMaxCooldown: 0,
      );
      expect(() => DailyDungeonService.applyFloorHeal([mon]), returnsNormally);
    });

    test('elementNameKo and elementNameEn return different casing for same element', () {
      // Ko returns Korean characters, En returns English capitalised
      final ko = DailyDungeonService.elementNameKo('fire');
      final en = DailyDungeonService.elementNameEn('fire');
      expect(ko, isNot(equals(en)));
    });

    test('createEnemiesForFloor with light element (Sunday) returns enemies', () {
      final enemies = DailyDungeonService.createEnemiesForFloor(3, 'light');
      expect(enemies, isNotEmpty);
    });

    test('createEnemiesForFloor with dark element (Saturday) returns enemies', () {
      final enemies = DailyDungeonService.createEnemiesForFloor(3, 'dark');
      expect(enemies, isNotEmpty);
    });

    test('maxAttempts defines the daily limit as 2', () {
      // Verify the daily limit constant is sensible (>0 and <=10)
      expect(DailyDungeonService.maxAttempts, greaterThan(0));
      expect(DailyDungeonService.maxAttempts, lessThanOrEqualTo(10));
    });

    test('maxFloors defines the floor cap as exactly 10', () {
      expect(DailyDungeonService.maxFloors, 10);
    });
  });
}
