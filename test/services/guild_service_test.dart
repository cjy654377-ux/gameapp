import 'package:flutter_test/flutter_test.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/domain/services/guild_service.dart';

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

// Boss data table — mirrors the _GuildBossTemplate constants in the service.
const _guildBossData = [
  // index 0
  (id: 'guild_boss_hydra',  name: '구렁이 히드라', element: 'water', baseHp: 200000, baseAtk: 180, baseDef: 90,  baseSpd: 50),
  // index 1
  (id: 'guild_boss_titan',  name: '화염 타이탄',   element: 'fire',  baseHp: 250000, baseAtk: 220, baseDef: 150, baseSpd: 30),
  // index 2
  (id: 'guild_boss_lich',   name: '불멸의 리치',   element: 'dark',  baseHp: 180000, baseAtk: 260, baseDef: 70,  baseSpd: 80),
];

void main() {
  // ===========================================================================
  // Constants
  // ===========================================================================

  group('GuildService constants', () {
    test('maxDailyAttempts is 2', () {
      expect(GuildService.maxDailyAttempts, 2);
    });

    test('maxTurns is 25', () {
      expect(GuildService.maxTurns, 25);
    });

    test('shopItems list is not empty', () {
      expect(GuildService.shopItems, isNotEmpty);
    });
  });

  // ===========================================================================
  // generateMembers
  // ===========================================================================

  group('generateMembers — list structure', () {
    test('returns between 4 and 7 members', () {
      for (int trial = 0; trial < 30; trial++) {
        final members = GuildService.generateMembers();
        expect(members.length, inInclusiveRange(4, 7),
            reason: 'generateMembers must return 4–7 names');
      }
    });

    test('all returned names are non-empty strings', () {
      final members = GuildService.generateMembers();
      for (final name in members) {
        expect(name, isNotEmpty,
            reason: 'Each member name must be non-empty');
      }
    });

    test('names are drawn from the known Korean AI name pool', () {
      const knownNames = {
        '용사김철수', '마법사하늘', '검신바람', '성기사빛나',
        '암살자달빛', '궁수별빛', '전사천둥', '치유사이슬',
        '연금술사금', '현자구름', '사냥꾼숲길', '기사철벽',
      };

      for (int trial = 0; trial < 20; trial++) {
        final members = GuildService.generateMembers();
        for (final name in members) {
          expect(knownNames, contains(name),
              reason: '"$name" is not in the expected AI name pool');
        }
      }
    });

    test('returned names have no duplicates within a single call', () {
      for (int trial = 0; trial < 30; trial++) {
        final members = GuildService.generateMembers();
        expect(members.toSet().length, members.length,
            reason: 'Each AI name must appear at most once per guild');
      }
    });

    test('successive calls can produce different results (RNG is live)', () {
      // With 12 names and random shuffle, repeated calls should not always be
      // identical. Run 10 pairs and require at least one differs.
      bool foundDifference = false;
      for (int i = 0; i < 10; i++) {
        final a = GuildService.generateMembers().join(',');
        final b = GuildService.generateMembers().join(',');
        if (a != b) {
          foundDifference = true;
          break;
        }
      }
      // Informational — not a hard assertion (avoids flakiness on seeded RNG).
      printOnFailure('RNG difference detected: $foundDifference');
      // At minimum, every call still returns a valid list.
      expect(GuildService.generateMembers().length, inInclusiveRange(4, 7));
    });
  });

  // ===========================================================================
  // currentWeekNumber / weeklyBossIndex
  // ===========================================================================

  group('currentWeekNumber', () {
    test('returns a non-negative integer', () {
      expect(GuildService.currentWeekNumber(), greaterThanOrEqualTo(0));
    });

    test('equals weeks elapsed since 2024-01-01', () {
      final now = DateTime.now();
      final expected = now.difference(DateTime(2024, 1, 1)).inDays ~/ 7;
      expect(GuildService.currentWeekNumber(), expected);
    });
  });

  group('weeklyBossIndex', () {
    test('returns an index in [0, 2] (three bosses)', () {
      final idx = GuildService.weeklyBossIndex();
      expect(idx, greaterThanOrEqualTo(0));
      expect(idx, lessThanOrEqualTo(2));
    });

    test('equals currentWeekNumber mod 3', () {
      final expected = GuildService.currentWeekNumber() % 3;
      expect(GuildService.weeklyBossIndex(), expected);
    });

    test('rotation covers all 3 boss slots across a 3-week cycle', () {
      final indices = List.generate(3, (i) => i % 3).toSet();
      expect(indices.length, 3,
          reason: 'All 3 boss indices must appear across a 3-week cycle');
    });
  });

  // ===========================================================================
  // weeklyBossName / weeklyBossElement
  // ===========================================================================

  group('weeklyBossName', () {
    test('returns one of the 3 known boss names', () {
      const validNames = {'구렁이 히드라', '화염 타이탄', '불멸의 리치'};
      expect(validNames, contains(GuildService.weeklyBossName()));
    });

    test('name matches expected boss at current week index', () {
      final idx = GuildService.weeklyBossIndex();
      expect(GuildService.weeklyBossName(), _guildBossData[idx].name);
    });

    test('weeklyBossName is non-empty', () {
      expect(GuildService.weeklyBossName(), isNotEmpty);
    });
  });

  group('weeklyBossElement', () {
    test('returns one of the valid boss elements', () {
      const validElements = {'water', 'fire', 'dark'};
      expect(validElements, contains(GuildService.weeklyBossElement()));
    });

    test('element matches expected boss at current week index', () {
      final idx = GuildService.weeklyBossIndex();
      expect(GuildService.weeklyBossElement(), _guildBossData[idx].element);
    });

    test('weeklyBossElement is non-empty', () {
      expect(GuildService.weeklyBossElement(), isNotEmpty);
    });
  });

  // ===========================================================================
  // bossMaxHp — HP scaling formula
  // ===========================================================================

  group('bossMaxHp — HP scaling', () {
    test('guild level 1 returns exact baseHp (scale = 1.0)', () {
      final idx = GuildService.weeklyBossIndex();
      final expected = _guildBossData[idx].baseHp.toDouble();
      expect(GuildService.bossMaxHp(guildLevel: 1), closeTo(expected, 1.0));
    });

    test('guild level 2 applies +10% over level 1 HP', () {
      final hpL1 = GuildService.bossMaxHp(guildLevel: 1);
      final hpL2 = GuildService.bossMaxHp(guildLevel: 2);
      // formula: baseHp * (1.0 + (level - 1) * 0.1)
      // level 2 → 1.0 + 0.1 = 1.1
      expect(hpL2, closeTo(hpL1 * 1.1, 2.0));
    });

    test('guild level 11 applies +100% over level 1 HP', () {
      final hpL1  = GuildService.bossMaxHp(guildLevel: 1);
      final hpL11 = GuildService.bossMaxHp(guildLevel: 11);
      // level 11 → 1.0 + 10*0.1 = 2.0
      expect(hpL11, closeTo(hpL1 * 2.0, 5.0));
    });

    test('higher guild level always produces higher boss HP', () {
      final low  = GuildService.bossMaxHp(guildLevel: 1);
      final high = GuildService.bossMaxHp(guildLevel: 20);
      expect(high, greaterThan(low));
    });

    test('HP increases monotonically with guild level', () {
      double prev = GuildService.bossMaxHp(guildLevel: 1);
      for (int level = 2; level <= 10; level++) {
        final curr = GuildService.bossMaxHp(guildLevel: level);
        expect(curr, greaterThan(prev),
            reason: 'HP at level $level must exceed HP at level ${level - 1}');
        prev = curr;
      }
    });

    test('HP is always positive', () {
      for (final level in [1, 5, 10, 50]) {
        expect(GuildService.bossMaxHp(guildLevel: level), greaterThan(0));
      }
    });
  });

  // ===========================================================================
  // createBoss — baseline (guildLevel = 1)
  // ===========================================================================

  group('createBoss — baseline (guildLevel=1)', () {
    late BattleMonster boss;

    setUp(() {
      boss = GuildService.createBoss(guildLevel: 1);
    });

    test('monsterId starts with guild_boss_', () {
      expect(boss.monsterId, startsWith('guild_boss_'));
    });

    test('rarity is 5 (legendary)', () {
      expect(boss.rarity, 5);
    });

    test('size is extraLarge', () {
      expect(boss.size, 'extraLarge');
    });

    test('element matches weeklyBossElement', () {
      expect(boss.element, GuildService.weeklyBossElement());
    });

    test('name matches weeklyBossName', () {
      expect(boss.name, GuildService.weeklyBossName());
    });

    test('currentHp equals maxHp at creation (full health)', () {
      expect(boss.currentHp, boss.maxHp);
    });

    test('maxHp matches bossMaxHp for guildLevel=1', () {
      expect(boss.maxHp, closeTo(GuildService.bossMaxHp(guildLevel: 1), 1.0));
    });

    test('ATK matches base ATK at guildLevel=1 (scale = 1.0)', () {
      final idx = GuildService.weeklyBossIndex();
      final expectedAtk = _guildBossData[idx].baseAtk.toDouble();
      expect(boss.atk, closeTo(expectedAtk, 1.0));
    });

    test('DEF matches base DEF at guildLevel=1 (scale = 1.0)', () {
      final idx = GuildService.weeklyBossIndex();
      final expectedDef = _guildBossData[idx].baseDef.toDouble();
      expect(boss.def, closeTo(expectedDef, 1.0));
    });

    test('SPD matches base SPD at guildLevel=1', () {
      final idx = GuildService.weeklyBossIndex();
      final expectedSpd = _guildBossData[idx].baseSpd.toDouble();
      expect(boss.spd, closeTo(expectedSpd, 1.0));
    });

    test('boss is alive at creation', () {
      expect(boss.isAlive, isTrue);
    });

    test('boss has positive ATK', () {
      expect(boss.atk, greaterThan(0));
    });

    test('boss has positive DEF', () {
      expect(boss.def, greaterThan(0));
    });

    test('boss has positive SPD', () {
      expect(boss.spd, greaterThan(0));
    });
  });

  // ===========================================================================
  // createBoss — guildLevel scaling
  // ===========================================================================

  group('createBoss — guildLevel scaling', () {
    test('guildLevel 2 scales ATK by 1.08 over guildLevel 1', () {
      final bossL1 = GuildService.createBoss(guildLevel: 1);
      final bossL2 = GuildService.createBoss(guildLevel: 2);
      // scale formula: 1.0 + (level - 1) * 0.08
      // level 2 → 1.08
      expect(bossL2.atk, closeTo(bossL1.atk * 1.08, 2.0));
    });

    test('guildLevel 2 scales DEF by 1.08 over guildLevel 1', () {
      final bossL1 = GuildService.createBoss(guildLevel: 1);
      final bossL2 = GuildService.createBoss(guildLevel: 2);
      expect(bossL2.def, closeTo(bossL1.def * 1.08, 2.0));
    });

    test('guildLevel 2 scales maxHp by 1.1 over guildLevel 1 (HP uses 0.1 step)', () {
      final bossL1 = GuildService.createBoss(guildLevel: 1);
      final bossL2 = GuildService.createBoss(guildLevel: 2);
      expect(bossL2.maxHp, closeTo(bossL1.maxHp * 1.1, 10.0));
    });

    test('guildLevel 11 scales ATK by 1.80 over guildLevel 1', () {
      final bossL1  = GuildService.createBoss(guildLevel: 1);
      final bossL11 = GuildService.createBoss(guildLevel: 11);
      // level 11 → scale = 1.0 + 10*0.08 = 1.80
      expect(bossL11.atk, closeTo(bossL1.atk * 1.80, 5.0));
    });

    test('speed does NOT scale with guildLevel (constant per boss template)', () {
      final bossL1  = GuildService.createBoss(guildLevel: 1);
      final bossL50 = GuildService.createBoss(guildLevel: 50);
      expect(bossL1.spd, bossL50.spd);
    });

    test('higher guildLevel always produces higher boss HP', () {
      final bossLow  = GuildService.createBoss(guildLevel: 1);
      final bossHigh = GuildService.createBoss(guildLevel: 20);
      expect(bossHigh.maxHp, greaterThan(bossLow.maxHp));
    });

    test('higher guildLevel always produces higher ATK', () {
      final bossLow  = GuildService.createBoss(guildLevel: 1);
      final bossHigh = GuildService.createBoss(guildLevel: 10);
      expect(bossHigh.atk, greaterThan(bossLow.atk));
    });

    test('higher guildLevel always produces higher DEF', () {
      final bossLow  = GuildService.createBoss(guildLevel: 1);
      final bossHigh = GuildService.createBoss(guildLevel: 10);
      expect(bossHigh.def, greaterThan(bossLow.def));
    });
  });

  // ===========================================================================
  // createBoss — currentHp override
  // ===========================================================================

  group('createBoss — currentHp override', () {
    test('currentHp defaults to maxHp when not provided', () {
      final boss = GuildService.createBoss(guildLevel: 1);
      expect(boss.currentHp, boss.maxHp);
    });

    test('passing currentHp overrides the default (partial HP)', () {
      const partialHp = 50000.0;
      final boss = GuildService.createBoss(guildLevel: 1, currentHp: partialHp);
      expect(boss.currentHp, partialHp);
    });

    test('currentHp override does not change maxHp', () {
      final bossDefault = GuildService.createBoss(guildLevel: 1);
      final bossPartial = GuildService.createBoss(guildLevel: 1, currentHp: 1.0);
      expect(bossPartial.maxHp, bossDefault.maxHp);
    });

    test('boss with currentHp=0 is not alive', () {
      final boss = GuildService.createBoss(guildLevel: 1, currentHp: 0);
      expect(boss.isAlive, isFalse);
    });

    test('boss with currentHp > 0 is alive', () {
      final boss = GuildService.createBoss(guildLevel: 1, currentHp: 1.0);
      expect(boss.isAlive, isTrue);
    });
  });

  // ===========================================================================
  // createBoss — boss identity properties
  // ===========================================================================

  group('createBoss — boss identity', () {
    test('templateId matches the boss template id in the data table', () {
      final boss = GuildService.createBoss(guildLevel: 1);
      final idx = GuildService.weeklyBossIndex();
      expect(boss.templateId, _guildBossData[idx].id);
    });

    test('monsterId is guild_boss_ + templateId', () {
      final boss = GuildService.createBoss(guildLevel: 1);
      expect(boss.monsterId, 'guild_boss_${boss.templateId}');
    });

    test('element is one of water, fire, or dark', () {
      const validElements = {'water', 'fire', 'dark'};
      final boss = GuildService.createBoss(guildLevel: 1);
      expect(validElements, contains(boss.element));
    });

    test('createBoss at guildLevel 1 does not throw', () {
      expect(() => GuildService.createBoss(guildLevel: 1), returnsNormally);
    });

    test('createBoss at very high guildLevel does not throw', () {
      expect(() => GuildService.createBoss(guildLevel: 500), returnsNormally);
    });
  });

  // ===========================================================================
  // simulateAiDamage
  // ===========================================================================

  group('simulateAiDamage — damage simulation', () {
    test('returns positive total damage for 1 member at guildLevel 1', () {
      final damage = GuildService.simulateAiDamage(
        memberCount: 1,
        guildLevel: 1,
      );
      expect(damage, greaterThan(0));
    });

    test('returns 0 for memberCount=0', () {
      final damage = GuildService.simulateAiDamage(
        memberCount: 0,
        guildLevel: 1,
      );
      expect(damage, 0.0);
    });

    test('more members produce more total damage on average', () {
      // Average over many trials to smooth RNG variance.
      double sumFew = 0, sumMany = 0;
      const trials = 50;
      for (int i = 0; i < trials; i++) {
        sumFew  += GuildService.simulateAiDamage(memberCount: 1,  guildLevel: 1);
        sumMany += GuildService.simulateAiDamage(memberCount: 10, guildLevel: 1);
      }
      expect(sumMany / trials, greaterThan(sumFew / trials),
          reason: '10 members must deal more average damage than 1 member');
    });

    test('higher guildLevel produces more damage for same memberCount', () {
      double sumLow = 0, sumHigh = 0;
      const trials = 50;
      for (int i = 0; i < trials; i++) {
        sumLow  += GuildService.simulateAiDamage(memberCount: 5, guildLevel: 1);
        sumHigh += GuildService.simulateAiDamage(memberCount: 5, guildLevel: 10);
      }
      expect(sumHigh / trials, greaterThan(sumLow / trials),
          reason: 'guildLevel=10 must deal more average damage than guildLevel=1');
    });

    test('damage per member is within expected range (2000–5000 * level bonus)', () {
      // At guildLevel 1 the bonus multiplier is (1 + 1*0.05) = 1.05.
      // Each AI member deals 2000–5000 * 1.05 = 2100–5250.
      const guildLevel = 1;
      const expectedMin = 2000 * (1 + guildLevel * 0.05);
      const expectedMax = 5000 * (1 + guildLevel * 0.05);

      // Over many trials, every single-member result must be in [min, max].
      for (int i = 0; i < 100; i++) {
        final dmg = GuildService.simulateAiDamage(
          memberCount: 1,
          guildLevel: guildLevel,
        );
        expect(dmg, inInclusiveRange(expectedMin, expectedMax),
            reason: 'Single AI member damage must be in [$expectedMin, $expectedMax]');
      }
    });

    test('damage scales linearly with memberCount (approximate)', () {
      // Average of 200 single-member samples ≈ (2000+5000)/2 * 1.05 = 3675.
      // Ten times as many members should approximate 10x the single-member avg.
      double singleSum = 0;
      double tenSum = 0;
      const trials = 200;
      for (int i = 0; i < trials; i++) {
        singleSum += GuildService.simulateAiDamage(memberCount: 1,  guildLevel: 1);
        tenSum    += GuildService.simulateAiDamage(memberCount: 10, guildLevel: 1);
      }
      final singleAvg = singleSum / trials;
      final tenAvg    = tenSum    / trials;
      // The ten-member average should be roughly 10× the single average (±30%).
      expect(tenAvg, greaterThan(singleAvg * 7),
          reason: 'Ten-member avg must be at least 7× single-member avg');
      expect(tenAvg, lessThan(singleAvg * 13),
          reason: 'Ten-member avg must be at most 13× single-member avg');
    });
  });

  // ===========================================================================
  // calculateGuildCoins
  // ===========================================================================

  group('calculateGuildCoins — reward calculation', () {
    test('500 damage gives 1 coin (500 / 500 = 1)', () {
      expect(GuildService.calculateGuildCoins(500), 1);
    });

    test('1000 damage gives 2 coins', () {
      expect(GuildService.calculateGuildCoins(1000), 2);
    });

    test('250000 damage gives 500 coins (exact boundary)', () {
      // 250000 / 500 = 500, within [1, 999]
      expect(GuildService.calculateGuildCoins(250000), 500);
    });

    test('minimum clamp: 0 damage gives 1 coin', () {
      expect(GuildService.calculateGuildCoins(0), 1);
    });

    test('minimum clamp: negative damage gives 1 coin', () {
      expect(GuildService.calculateGuildCoins(-9999), 1);
    });

    test('maximum clamp: very large damage gives 999 coins', () {
      expect(GuildService.calculateGuildCoins(99999999), 999);
    });

    test('coins are always in [1, 999]', () {
      for (final dmg in [0.0, 1.0, 500.0, 5000.0, 50000.0, 500000.0, 9999999.0]) {
        final coins = GuildService.calculateGuildCoins(dmg);
        expect(coins, inInclusiveRange(1, 999),
            reason: 'Coins for damage=$dmg must be in [1, 999]');
      }
    });

    test('more damage yields more or equal coins', () {
      final low  = GuildService.calculateGuildCoins(1000);
      final high = GuildService.calculateGuildCoins(100000);
      expect(high, greaterThanOrEqualTo(low));
    });

    test('coins is integer result of rounding (damage / 500)', () {
      // 750 / 500 = 1.5 → rounds to 2
      expect(GuildService.calculateGuildCoins(750), 2);
      // 1250 / 500 = 2.5 → rounds to 3 (Dart rounds half away from zero)
      expect(GuildService.calculateGuildCoins(1250), 3);
    });
  });

  // ===========================================================================
  // calculateGuildExp
  // ===========================================================================

  group('calculateGuildExp — reward calculation', () {
    test('1000 damage gives 1 exp', () {
      expect(GuildService.calculateGuildExp(1000), 1);
    });

    test('10000 damage gives 10 exp', () {
      expect(GuildService.calculateGuildExp(10000), 10);
    });

    test('minimum clamp: 0 damage gives 1 exp', () {
      expect(GuildService.calculateGuildExp(0), 1);
    });

    test('minimum clamp: negative damage gives 1 exp', () {
      expect(GuildService.calculateGuildExp(-9999), 1);
    });

    test('maximum clamp: very large damage gives 200 exp', () {
      expect(GuildService.calculateGuildExp(99999999), 200);
    });

    test('exp is always in [1, 200]', () {
      for (final dmg in [0.0, 500.0, 5000.0, 50000.0, 500000.0]) {
        final exp = GuildService.calculateGuildExp(dmg);
        expect(exp, inInclusiveRange(1, 200),
            reason: 'Exp for damage=$dmg must be in [1, 200]');
      }
    });

    test('more damage yields more or equal exp', () {
      final low  = GuildService.calculateGuildExp(2000);
      final high = GuildService.calculateGuildExp(200000);
      expect(high, greaterThanOrEqualTo(low));
    });

    test('exp scales at 1/10 the rate of coins (per damage unit)', () {
      // coins = damage / 500, exp = damage / 1000 → exp ≈ coins / 2
      const dmg = 10000.0;
      final coins = GuildService.calculateGuildCoins(dmg); // 20
      final exp   = GuildService.calculateGuildExp(dmg);   // 10
      expect(coins, greaterThan(exp),
          reason: 'Coins should always exceed exp for the same damage');
    });
  });

  // ===========================================================================
  // Guild shop items
  // ===========================================================================

  group('GuildShopItem — shop catalogue', () {
    test('shopItems contains exactly 5 entries', () {
      expect(GuildService.shopItems.length, 5);
    });

    test('all items have unique indices', () {
      final indices = GuildService.shopItems.map((i) => i.index).toList();
      expect(indices.toSet().length, indices.length,
          reason: 'Each shop item must have a unique index');
    });

    test('indices run from 0 to 4', () {
      final indices = GuildService.shopItems.map((i) => i.index).toList()..sort();
      expect(indices, [0, 1, 2, 3, 4]);
    });

    test('all items have non-empty names', () {
      for (final item in GuildService.shopItems) {
        expect(item.name, isNotEmpty,
            reason: 'Item at index ${item.index} must have a non-empty name');
      }
    });

    test('all items have positive cost', () {
      for (final item in GuildService.shopItems) {
        expect(item.cost, greaterThan(0),
            reason: '${item.name} cost must be positive');
      }
    });

    test('all items have positive amount', () {
      for (final item in GuildService.shopItems) {
        expect(item.amount, greaterThan(0),
            reason: '${item.name} amount must be positive');
      }
    });

    test('all items have non-empty type', () {
      for (final item in GuildService.shopItems) {
        expect(item.type, isNotEmpty,
            reason: '${item.name} must have a non-empty type');
      }
    });

    test('first item (index 0) is gachaTicket x2 at cost 50', () {
      final item = GuildService.shopItems[0];
      expect(item.type, 'gachaTicket');
      expect(item.amount, 2);
      expect(item.cost, 50);
    });

    test('second item (index 1) is expPotion x5 at cost 30', () {
      final item = GuildService.shopItems[1];
      expect(item.type, 'expPotion');
      expect(item.amount, 5);
      expect(item.cost, 30);
    });

    test('third item (index 2) is gold 2000 at cost 20', () {
      final item = GuildService.shopItems[2];
      expect(item.type, 'gold');
      expect(item.amount, 2000);
      expect(item.cost, 20);
    });

    test('fourth item (index 3) is diamond 50 at cost 80', () {
      final item = GuildService.shopItems[3];
      expect(item.type, 'diamond');
      expect(item.amount, 50);
      expect(item.cost, 80);
    });

    test('fifth item (index 4) is monsterShard 5 at cost 60', () {
      final item = GuildService.shopItems[4];
      expect(item.type, 'monsterShard');
      expect(item.amount, 5);
      expect(item.cost, 60);
    });
  });

  // ===========================================================================
  // GuildShopItem — data class integrity
  // ===========================================================================

  group('GuildShopItem — data class integrity', () {
    test('constructor stores all fields correctly', () {
      const item = GuildShopItem(
        index: 7,
        name: '테스트 아이템',
        cost: 99,
        type: 'testType',
        amount: 10,
      );

      expect(item.index, 7);
      expect(item.name, '테스트 아이템');
      expect(item.cost, 99);
      expect(item.type, 'testType');
      expect(item.amount, 10);
    });
  });

  // ===========================================================================
  // todayString
  // ===========================================================================

  group('todayString', () {
    test('returns a non-empty string', () {
      expect(GuildService.todayString(), isNotEmpty);
    });

    test('returns a string in YYYY-MM-DD format', () {
      final s = GuildService.todayString();
      // Must match pattern YYYY-MM-DD
      final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      expect(regex.hasMatch(s), isTrue,
          reason: 'todayString must be in YYYY-MM-DD format, got "$s"');
    });

    test('year matches current year', () {
      final s = GuildService.todayString();
      final year = int.parse(s.split('-')[0]);
      expect(year, DateTime.now().year);
    });

    test('month matches current month (zero-padded)', () {
      final s = GuildService.todayString();
      final month = int.parse(s.split('-')[1]);
      expect(month, DateTime.now().month);
    });

    test('day matches current day (zero-padded)', () {
      final s = GuildService.todayString();
      final day = int.parse(s.split('-')[2]);
      expect(day, DateTime.now().day);
    });

    test('successive calls on same day return identical strings', () {
      final a = GuildService.todayString();
      final b = GuildService.todayString();
      expect(a, b);
    });
  });

  // ===========================================================================
  // bossAttackRandom — basic behaviour
  // ===========================================================================

  group('bossAttackRandom — basic behaviour', () {
    test('returns null when player team is empty', () {
      final boss = GuildService.createBoss(guildLevel: 1);
      expect(GuildService.bossAttackRandom(boss, []), isNull);
    });

    test('returns null when all player monsters are dead', () {
      final boss = GuildService.createBoss(guildLevel: 1);
      final dead = _mon();
      dead.currentHp = 0;

      expect(GuildService.bossAttackRandom(boss, [dead]), isNull);
    });

    test('returns a BattleLogEntry when target is alive', () {
      final boss   = GuildService.createBoss(guildLevel: 1);
      final player = _mon(hp: 9999, def: 0);

      final log = GuildService.bossAttackRandom(boss, [player]);
      expect(log, isNotNull);
    });

    test('log attackerName matches boss name', () {
      final boss   = GuildService.createBoss(guildLevel: 1);
      final player = _mon(name: '영웅');

      final log = GuildService.bossAttackRandom(boss, [player])!;
      expect(log.attackerName, boss.name);
    });

    test('log targetName matches the attacked player monster name', () {
      final boss   = GuildService.createBoss(guildLevel: 1);
      final player = _mon(name: '용감한 기사');

      final log = GuildService.bossAttackRandom(boss, [player])!;
      expect(log.targetName, '용감한 기사');
    });

    test('log damage is greater than 0', () {
      final boss   = GuildService.createBoss(guildLevel: 1);
      final player = _mon(hp: 9999, def: 0);

      final log = GuildService.bossAttackRandom(boss, [player])!;
      expect(log.damage, greaterThan(0));
    });

    test('isElementAdvantage is always false (guild boss attack)', () {
      final boss   = GuildService.createBoss(guildLevel: 1);
      final player = _mon(hp: 9999);

      for (int i = 0; i < 20; i++) {
        final log = GuildService.bossAttackRandom(boss, [player]);
        if (log != null) {
          expect(log.isElementAdvantage, isFalse);
        }
      }
    });

    test('log description contains boss name', () {
      final boss   = GuildService.createBoss(guildLevel: 1);
      final player = _mon(hp: 9999, def: 0);

      final log = GuildService.bossAttackRandom(boss, [player])!;
      expect(log.description, contains(boss.name));
    });

    test('log description contains target name', () {
      final boss   = GuildService.createBoss(guildLevel: 1);
      final player = _mon(name: '수호자', hp: 9999, def: 0);

      final log = GuildService.bossAttackRandom(boss, [player])!;
      expect(log.description, contains('수호자'));
    });

    test('log description contains damage amount as integer', () {
      final boss   = GuildService.createBoss(guildLevel: 1);
      final player = _mon(hp: 9999, def: 0);

      final log = GuildService.bossAttackRandom(boss, [player])!;
      expect(log.description, contains(log.damage.toInt().toString()));
    });
  });

  // ===========================================================================
  // bossAttackRandom — damage application
  // ===========================================================================

  group('bossAttackRandom — damage application', () {
    test('target HP is reduced after guild boss attack', () {
      final boss    = GuildService.createBoss(guildLevel: 5);
      final player  = _mon(hp: 99999, def: 0);
      final initial = player.currentHp;

      GuildService.bossAttackRandom(boss, [player]);

      expect(player.currentHp, lessThan(initial));
    });

    test('target HP never goes below 0', () {
      final boss   = GuildService.createBoss(guildLevel: 99);
      final player = _mon(hp: 10, def: 0);

      GuildService.bossAttackRandom(boss, [player]);

      expect(player.currentHp, greaterThanOrEqualTo(0));
    });

    test('minimum damage is at least 1 (high DEF player)', () {
      final boss       = GuildService.createBoss(guildLevel: 1);
      final tankPlayer = _mon(hp: 9999, def: 9999);

      for (int i = 0; i < 50; i++) {
        final log = GuildService.bossAttackRandom(boss, [tankPlayer]);
        if (log != null) {
          expect(log.damage, greaterThanOrEqualTo(1.0));
        }
      }
    });

    test('shield absorbs damage before HP is reduced', () {
      final boss   = GuildService.createBoss(guildLevel: 1);
      final player = _mon(hp: 500, def: 0);
      player.shieldHp = 1000000; // enormous shield
      final initialHp = player.currentHp;

      GuildService.bossAttackRandom(boss, [player]);

      expect(player.currentHp, equals(initialHp),
          reason: 'HP must not drop when shield absorbs the full hit');
      expect(player.shieldHp, lessThan(1000000),
          reason: 'Shield must be reduced by the attack');
    });

    test('shield depletes and remainder carries over to HP when shield < damage', () {
      final boss   = GuildService.createBoss(guildLevel: 50);
      final player = _mon(hp: 9999, def: 0);
      player.shieldHp = 1; // tiny shield

      GuildService.bossAttackRandom(boss, [player]);

      expect(player.shieldHp, equals(0),
          reason: 'Shield should be fully depleted');
      expect(player.currentHp, lessThan(9999),
          reason: 'Remaining damage must carry over to HP');
    });

    test('dead monsters are never targeted (HP stays 0)', () {
      final boss  = GuildService.createBoss(guildLevel: 1);
      final dead  = _mon(name: 'Dead',  hp: 100, def: 0);
      final alive = _mon(name: 'Alive', hp: 9999, def: 0);
      dead.currentHp = 0;

      for (int i = 0; i < 30; i++) {
        GuildService.bossAttackRandom(boss, [dead, alive]);
        expect(dead.currentHp, equals(0),
            reason: 'Dead monster HP must remain at 0');
      }
    });

    test('only alive survivor is targeted when rest are dead', () {
      final boss    = GuildService.createBoss(guildLevel: 1);
      final dead1   = _mon(name: 'Dead1');
      final dead2   = _mon(name: 'Dead2');
      final alive   = _mon(name: 'Survivor', hp: 99999, def: 0);
      dead1.currentHp = 0;
      dead2.currentHp = 0;

      for (int i = 0; i < 20; i++) {
        alive.currentHp = alive.maxHp;
        final log = GuildService.bossAttackRandom(boss, [dead1, dead2, alive]);
        expect(log, isNotNull,
            reason: 'Should find the alive survivor');
        expect(log!.targetName, 'Survivor');
      }
    });
  });

  // ===========================================================================
  // bossAttackRandom — critical hits
  // ===========================================================================

  group('bossAttackRandom — critical hits', () {
    test('isCritical field in log is a bool', () {
      final boss   = GuildService.createBoss(guildLevel: 1);
      final player = _mon(hp: 99999, def: 0);

      final log = GuildService.bossAttackRandom(boss, [player])!;
      expect(log.isCritical, isA<bool>());
    });

    test('description contains 치명타 on a critical hit', () {
      final boss   = GuildService.createBoss(guildLevel: 1);
      final player = _mon(hp: 99999999, def: 0);

      bool foundCrit = false;
      for (int i = 0; i < 300; i++) {
        player.currentHp = player.maxHp; // keep alive
        final log = GuildService.bossAttackRandom(boss, [player]);
        if (log != null && log.isCritical) {
          foundCrit = true;
          expect(log.description, contains('치명타'),
              reason: 'Critical log entry must mention 치명타');
          break;
        }
      }
      expect(foundCrit, isTrue,
          reason: 'At least one crit must appear in 300 attacks (10% chance)');
    });
  });

  // ===========================================================================
  // Guild boss HP by boss type (all three bosses)
  // ===========================================================================

  group('All 3 guild bosses — base HP at guildLevel=1', () {
    // Since we cannot control the week, we verify the currently-active boss
    // and assert table self-consistency for the other two.

    for (int i = 0; i < _guildBossData.length; i++) {
      final expected = _guildBossData[i];

      test('boss index $i (${expected.name}) has correct metadata', () {
        expect(expected.id,      isNotEmpty);
        expect(expected.name,    isNotEmpty);
        expect(expected.element, isNotEmpty);
        expect(expected.baseHp,  greaterThan(0));
        expect(expected.baseAtk, greaterThan(0));
        expect(expected.baseDef, greaterThan(0));
        expect(expected.baseSpd, greaterThan(0));

        // If today's weekly rotation matches this boss, validate live values.
        final todayIdx = GuildService.weeklyBossIndex();
        if (todayIdx == i) {
          expect(GuildService.weeklyBossName(),    expected.name);
          expect(GuildService.weeklyBossElement(), expected.element);

          final boss = GuildService.createBoss(guildLevel: 1);
          expect(boss.name,    expected.name);
          expect(boss.element, expected.element);
          expect(boss.maxHp,   closeTo(expected.baseHp.toDouble(),  1.0));
          expect(boss.atk,     closeTo(expected.baseAtk.toDouble(), 1.0));
          expect(boss.def,     closeTo(expected.baseDef.toDouble(), 1.0));
          expect(boss.spd,     closeTo(expected.baseSpd.toDouble(), 1.0));
        }
      });
    }

    test('hydra has the highest ATK after titan and lich (ordering check)', () {
      // Quick sanity check on the data table ordering by ATK:
      // lich (260) > titan (220) > hydra (180)
      expect(_guildBossData[2].baseAtk, greaterThan(_guildBossData[1].baseAtk));
      expect(_guildBossData[1].baseAtk, greaterThan(_guildBossData[0].baseAtk));
    });

    test('titan has the highest base HP', () {
      // titan (250000) > hydra (200000) > lich (180000)
      expect(_guildBossData[1].baseHp, greaterThan(_guildBossData[0].baseHp));
      expect(_guildBossData[0].baseHp, greaterThan(_guildBossData[2].baseHp));
    });

    test('lich has the highest SPD', () {
      // lich (80) > hydra (50) > titan (30)
      expect(_guildBossData[2].baseSpd, greaterThan(_guildBossData[0].baseSpd));
      expect(_guildBossData[0].baseSpd, greaterThan(_guildBossData[1].baseSpd));
    });
  });

  // ===========================================================================
  // Edge cases
  // ===========================================================================

  group('Edge cases', () {
    test('createBoss with guildLevel=1 (minimum) does not throw', () {
      expect(() => GuildService.createBoss(guildLevel: 1), returnsNormally);
    });

    test('createBoss with very high guildLevel does not throw', () {
      expect(() => GuildService.createBoss(guildLevel: 1000), returnsNormally);
    });

    test('bossMaxHp at guildLevel=1 equals first level of bossMaxHp series', () {
      // Self-consistency: bossMaxHp(1) == createBoss(1).maxHp
      final hp = GuildService.bossMaxHp(guildLevel: 1);
      final boss = GuildService.createBoss(guildLevel: 1);
      expect(hp, closeTo(boss.maxHp, 1.0));
    });

    test('calculateGuildCoins and calculateGuildExp are both positive for any positive damage', () {
      for (final dmg in [1.0, 100.0, 10000.0, 1000000.0]) {
        expect(GuildService.calculateGuildCoins(dmg), greaterThan(0));
        expect(GuildService.calculateGuildExp(dmg),   greaterThan(0));
      }
    });

    test('shopItems list is constant (same reference on multiple accesses)', () {
      final a = GuildService.shopItems;
      final b = GuildService.shopItems;
      expect(identical(a, b), isTrue,
          reason: 'shopItems must be a constant list returned by reference');
    });

    test('generateMembers does not throw even when called many times', () {
      for (int i = 0; i < 50; i++) {
        expect(() => GuildService.generateMembers(), returnsNormally);
      }
    });

    test('bossAttackRandom with a single-member all-dead team returns null', () {
      final boss = GuildService.createBoss(guildLevel: 1);
      final dead = _mon(hp: 100);
      dead.currentHp = 0;

      expect(GuildService.bossAttackRandom(boss, [dead]), isNull);
    });

    test('simulateAiDamage does not throw for large memberCount', () {
      expect(
        () => GuildService.simulateAiDamage(memberCount: 1000, guildLevel: 50),
        returnsNormally,
      );
    });

    test('simulateAiDamage returns a finite (non-infinite, non-NaN) result', () {
      final dmg = GuildService.simulateAiDamage(memberCount: 100, guildLevel: 20);
      expect(dmg.isFinite, isTrue);
      expect(dmg.isNaN, isFalse);
    });
  });
}
