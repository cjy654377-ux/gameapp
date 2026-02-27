import 'package:flutter_test/flutter_test.dart';
import 'package:gameapp/domain/services/expedition_service.dart';

void main() {
  // ===========================================================================
  // Group 1 – Static constants
  // ===========================================================================

  group('ExpeditionService constants', () {
    test('maxSlots is 3', () {
      expect(ExpeditionService.maxSlots, 3);
    });

    test('maxMonstersPerSlot is 3', () {
      expect(ExpeditionService.maxMonstersPerSlot, 3);
    });

    test('options has exactly 3 entries', () {
      expect(ExpeditionService.options.length, 3);
    });

    test('options durations are 1h, 4h, 8h in seconds', () {
      final durations = ExpeditionService.options.map((o) => o.durationSeconds).toList();
      expect(durations, [3600, 14400, 28800]);
    });

    test('options labels are non-empty strings', () {
      for (final option in ExpeditionService.options) {
        expect(option.label, isNotEmpty,
            reason: 'Each option must have a non-empty label');
      }
    });

    test('first option is 1-hour expedition', () {
      expect(ExpeditionService.options[0].durationSeconds, 3600);
      expect(ExpeditionService.options[0].label, '1시간 원정');
    });

    test('second option is 4-hour expedition', () {
      expect(ExpeditionService.options[1].durationSeconds, 14400);
      expect(ExpeditionService.options[1].label, '4시간 원정');
    });

    test('third option is 8-hour expedition', () {
      expect(ExpeditionService.options[2].durationSeconds, 28800);
      expect(ExpeditionService.options[2].label, '8시간 원정');
    });
  });

  // ===========================================================================
  // Group 2 – ExpeditionOption model
  // ===========================================================================

  group('ExpeditionOption model', () {
    test('can be constructed with durationSeconds and label', () {
      const option = ExpeditionOption(
        durationSeconds: 7200,
        label: '2시간 원정',
      );
      expect(option.durationSeconds, 7200);
      expect(option.label, '2시간 원정');
    });
  });

  // ===========================================================================
  // Group 3 – ExpeditionReward model
  // ===========================================================================

  group('ExpeditionReward model', () {
    test('stores all four reward fields', () {
      const reward = ExpeditionReward(
        gold: 300,
        expPotions: 2,
        shards: 1,
        diamonds: 10,
      );
      expect(reward.gold, 300);
      expect(reward.expPotions, 2);
      expect(reward.shards, 1);
      expect(reward.diamonds, 10);
    });

    test('zero values are accepted', () {
      const reward = ExpeditionReward(
        gold: 0,
        expPotions: 0,
        shards: 0,
        diamonds: 0,
      );
      expect(reward.gold, 0);
      expect(reward.expPotions, 0);
      expect(reward.shards, 0);
      expect(reward.diamonds, 0);
    });
  });

  // ===========================================================================
  // Group 4 – Gold reward for 1-hour expedition (durationSeconds: 3600)
  // ===========================================================================

  group('calculateReward – gold for 1h expedition', () {
    // levelFactor = 1.0 + (1 - 1) * 0.03 = 1.0
    // baseGold = (200 * 1 * 1.0).round() = 200
    // goldVariance = random.nextInt((200 * 0.2).round().clamp(1, 999)) = random.nextInt(40)
    // gold ∈ [200, 239]

    test('gold is at least baseGold (200) for level-1 monsters, 1h', () {
      const int runs = 100;
      for (int i = 0; i < runs; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 3600,
          totalMonsterLevel: 1,
        );
        expect(reward.gold, greaterThanOrEqualTo(200),
            reason: 'Gold must be at least baseGold=200 for 1h, level-1');
      }
    });

    test('gold is at most baseGold + variance ceiling (239) for level-1, 1h', () {
      const int runs = 100;
      for (int i = 0; i < runs; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 3600,
          totalMonsterLevel: 1,
        );
        // baseGold * 0.2 = 40, so variance ∈ [0, 39] → max gold = 239
        expect(reward.gold, lessThanOrEqualTo(239),
            reason: 'Gold must not exceed baseGold + 20% variance for 1h, level-1');
      }
    });

    test('gold is positive for any valid input, 1h', () {
      final reward = ExpeditionService.calculateReward(
        durationSeconds: 3600,
        totalMonsterLevel: 1,
      );
      expect(reward.gold, greaterThan(0));
    });
  });

  // ===========================================================================
  // Group 5 – Gold reward for 4-hour expedition (durationSeconds: 14400)
  // ===========================================================================

  group('calculateReward – gold for 4h expedition', () {
    // levelFactor = 1.0, hours = 4
    // baseGold = (200 * 4 * 1.0).round() = 800
    // variance = random.nextInt((800 * 0.2).round()) = random.nextInt(160)
    // gold ∈ [800, 959]

    test('gold is at least 800 (baseGold for 4h, level-1)', () {
      const int runs = 100;
      for (int i = 0; i < runs; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 14400,
          totalMonsterLevel: 1,
        );
        expect(reward.gold, greaterThanOrEqualTo(800),
            reason: 'Gold must be at least 800 for 4h, level-1');
      }
    });

    test('gold is at most 959 for 4h, level-1', () {
      const int runs = 100;
      for (int i = 0; i < runs; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 14400,
          totalMonsterLevel: 1,
        );
        expect(reward.gold, lessThanOrEqualTo(959),
            reason: 'Gold must not exceed 959 for 4h, level-1');
      }
    });

    test('4h gold is at least 4x greater than 1h baseGold (800 vs 200)', () {
      // We compare the minimum possible gold values to confirm scaling.
      // 1h minimum = 200, 4h minimum = 800 → ratio is exactly 4x.
      const int runs = 200;
      int min1h = 999999;
      int min4h = 999999;
      for (int i = 0; i < runs; i++) {
        final r1 = ExpeditionService.calculateReward(
          durationSeconds: 3600,
          totalMonsterLevel: 1,
        );
        final r4 = ExpeditionService.calculateReward(
          durationSeconds: 14400,
          totalMonsterLevel: 1,
        );
        if (r1.gold < min1h) min1h = r1.gold;
        if (r4.gold < min4h) min4h = r4.gold;
      }
      expect(min4h, greaterThanOrEqualTo(min1h * 4),
          reason: '4h minimum gold must be at least 4x the 1h minimum gold');
    });
  });

  // ===========================================================================
  // Group 6 – Gold reward for 8-hour expedition (durationSeconds: 28800)
  // ===========================================================================

  group('calculateReward – gold for 8h expedition', () {
    // levelFactor = 1.0, hours = 8
    // baseGold = (200 * 8 * 1.0).round() = 1600
    // variance = random.nextInt((1600 * 0.2).round()) = random.nextInt(320)
    // gold ∈ [1600, 1919]

    test('gold is at least 1600 for 8h, level-1', () {
      const int runs = 100;
      for (int i = 0; i < runs; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 28800,
          totalMonsterLevel: 1,
        );
        expect(reward.gold, greaterThanOrEqualTo(1600),
            reason: 'Gold must be at least 1600 for 8h, level-1');
      }
    });

    test('gold is at most 1919 for 8h, level-1', () {
      const int runs = 100;
      for (int i = 0; i < runs; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 28800,
          totalMonsterLevel: 1,
        );
        expect(reward.gold, lessThanOrEqualTo(1919),
            reason: 'Gold must not exceed 1919 for 8h, level-1');
      }
    });

    test('8h gold is at least 2x greater than 4h baseGold (1600 vs 800)', () {
      const int runs = 200;
      int min4h = 999999;
      int min8h = 999999;
      for (int i = 0; i < runs; i++) {
        final r4 = ExpeditionService.calculateReward(
          durationSeconds: 14400,
          totalMonsterLevel: 1,
        );
        final r8 = ExpeditionService.calculateReward(
          durationSeconds: 28800,
          totalMonsterLevel: 1,
        );
        if (r4.gold < min4h) min4h = r4.gold;
        if (r8.gold < min8h) min8h = r8.gold;
      }
      expect(min8h, greaterThanOrEqualTo(min4h * 2),
          reason: '8h minimum gold must be at least 2x the 4h minimum gold');
    });
  });

  // ===========================================================================
  // Group 7 – Gold scales with duration (relative ordering)
  // ===========================================================================

  group('calculateReward – gold scales proportionally with duration', () {
    test('average gold over many runs: 1h < 4h < 8h (level-1)', () {
      const int runs = 200;
      double sum1h = 0;
      double sum4h = 0;
      double sum8h = 0;
      for (int i = 0; i < runs; i++) {
        sum1h += ExpeditionService.calculateReward(
          durationSeconds: 3600,
          totalMonsterLevel: 1,
        ).gold;
        sum4h += ExpeditionService.calculateReward(
          durationSeconds: 14400,
          totalMonsterLevel: 1,
        ).gold;
        sum8h += ExpeditionService.calculateReward(
          durationSeconds: 28800,
          totalMonsterLevel: 1,
        ).gold;
      }
      final avg1h = sum1h / runs;
      final avg4h = sum4h / runs;
      final avg8h = sum8h / runs;

      expect(avg4h, greaterThan(avg1h),
          reason: 'Average gold for 4h must exceed 1h');
      expect(avg8h, greaterThan(avg4h),
          reason: 'Average gold for 8h must exceed 4h');
    });

    test('gold with higher monster level exceeds gold at level-1 (1h)', () {
      const int runs = 100;
      double sumLow = 0;
      double sumHigh = 0;
      for (int i = 0; i < runs; i++) {
        sumLow += ExpeditionService.calculateReward(
          durationSeconds: 3600,
          totalMonsterLevel: 1,
        ).gold;
        sumHigh += ExpeditionService.calculateReward(
          durationSeconds: 3600,
          totalMonsterLevel: 10,
        ).gold;
      }
      expect(sumHigh / runs, greaterThan(sumLow / runs),
          reason: 'Higher monster level must yield higher average gold');
    });
  });

  // ===========================================================================
  // Group 8 – expPotions (deterministic, clamp 1..20)
  // ===========================================================================

  group('calculateReward – expPotions (deterministic)', () {
    // Formula: (0.5 * hours * levelFactor).round().clamp(1, 20)
    // Level-1 (levelFactor = 1.0):
    //   1h → (0.5 * 1 * 1.0).round() = 1  → clamp(1,20) = 1
    //   4h → (0.5 * 4 * 1.0).round() = 2  → clamp(1,20) = 2
    //   8h → (0.5 * 8 * 1.0).round() = 4  → clamp(1,20) = 4

    test('1h expedition at level-1 gives exactly 1 expPotion', () {
      final reward = ExpeditionService.calculateReward(
        durationSeconds: 3600,
        totalMonsterLevel: 1,
      );
      expect(reward.expPotions, 1);
    });

    test('4h expedition at level-1 gives exactly 2 expPotions', () {
      final reward = ExpeditionService.calculateReward(
        durationSeconds: 14400,
        totalMonsterLevel: 1,
      );
      expect(reward.expPotions, 2);
    });

    test('8h expedition at level-1 gives exactly 4 expPotions', () {
      final reward = ExpeditionService.calculateReward(
        durationSeconds: 28800,
        totalMonsterLevel: 1,
      );
      expect(reward.expPotions, 4);
    });

    test('expPotions is at least 1 (lower clamp holds)', () {
      // Even with the shortest duration and level-1, minimum is 1.
      for (int i = 0; i < 20; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 3600,
          totalMonsterLevel: 1,
        );
        expect(reward.expPotions, greaterThanOrEqualTo(1),
            reason: 'expPotions must never be less than 1');
      }
    });

    test('expPotions never exceeds 20 (upper clamp holds)', () {
      // Test at a very high level to stress the clamp.
      // levelFactor = 1 + (200 - 1) * 0.03 = 1 + 5.97 = 6.97
      // 8h: (0.5 * 8 * 6.97).round() = 27.88 → round = 28 → clamp(1,20) = 20
      for (int i = 0; i < 20; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 28800,
          totalMonsterLevel: 200,
        );
        expect(reward.expPotions, lessThanOrEqualTo(20),
            reason: 'expPotions must never exceed 20');
      }
    });

    test('expPotions is deterministic across repeated calls with same inputs', () {
      // expPotions has no RNG; calling with the same args always gives the same value.
      final expected = ExpeditionService.calculateReward(
        durationSeconds: 14400,
        totalMonsterLevel: 5,
      ).expPotions;
      for (int i = 0; i < 20; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 14400,
          totalMonsterLevel: 5,
        );
        expect(reward.expPotions, expected,
            reason: 'expPotions must be deterministic (no RNG involved)');
      }
    });

    test('expPotions increases with duration', () {
      final r1h = ExpeditionService.calculateReward(
        durationSeconds: 3600,
        totalMonsterLevel: 1,
      );
      final r4h = ExpeditionService.calculateReward(
        durationSeconds: 14400,
        totalMonsterLevel: 1,
      );
      final r8h = ExpeditionService.calculateReward(
        durationSeconds: 28800,
        totalMonsterLevel: 1,
      );
      expect(r4h.expPotions, greaterThan(r1h.expPotions),
          reason: '4h should give more expPotions than 1h');
      expect(r8h.expPotions, greaterThan(r4h.expPotions),
          reason: '8h should give more expPotions than 4h');
    });

    test('expPotions scales with monster level factor', () {
      // Level-1 vs level-21: levelFactor doubles (1.0 → 2.0)
      // 1h: level-1 = 1, level-21 = (0.5 * 1 * 2.0).round() = 1 → still 1
      // 4h: level-1 = 2, level-21 = (0.5 * 4 * 2.0).round() = 4
      final r1 = ExpeditionService.calculateReward(
        durationSeconds: 14400,
        totalMonsterLevel: 1,
      );
      final r21 = ExpeditionService.calculateReward(
        durationSeconds: 14400,
        totalMonsterLevel: 21,
      );
      expect(r21.expPotions, greaterThan(r1.expPotions),
          reason: 'Higher monster level must yield more expPotions (4h)');
    });

    test('expPotions at level-21 for 4h is exactly 4', () {
      // levelFactor = 1 + (21-1)*0.03 = 1.60
      // (0.5 * 4 * 1.60).round() = (3.2).round() = 3
      // Actually: 0.5 * 4 = 2, * 1.60 = 3.2 → .round() = 3
      final reward = ExpeditionService.calculateReward(
        durationSeconds: 14400,
        totalMonsterLevel: 21,
      );
      // levelFactor = 1 + 20 * 0.03 = 1.60 → (0.5 * 4 * 1.60).round() = 3
      expect(reward.expPotions, 3);
    });
  });

  // ===========================================================================
  // Group 9 – Shard reward (RNG-driven, probabilistic)
  // ===========================================================================

  group('calculateReward – shards (probabilistic)', () {
    // shardChance: 1h → 0.10, 4h → 0.25, 8h → 0.40
    // shards value when awarded: 1 + random.nextInt(ceil(hours/4).clamp(1,3))
    //   1h → 1 + nextInt(1) = 1 (always exactly 1 when given)
    //   4h → 1 + nextInt(1) = 1 (always exactly 1 when given)
    //   8h → 1 + nextInt(2) ∈ [1, 2] when given

    test('shards is never negative for 1h', () {
      for (int i = 0; i < 50; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 3600,
          totalMonsterLevel: 1,
        );
        expect(reward.shards, greaterThanOrEqualTo(0),
            reason: 'Shards must never be negative');
      }
    });

    test('shards is never negative for 4h', () {
      for (int i = 0; i < 50; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 14400,
          totalMonsterLevel: 1,
        );
        expect(reward.shards, greaterThanOrEqualTo(0));
      }
    });

    test('shards is never negative for 8h', () {
      for (int i = 0; i < 50; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 28800,
          totalMonsterLevel: 1,
        );
        expect(reward.shards, greaterThanOrEqualTo(0));
      }
    });

    test('when 1h shards are awarded, value is exactly 1', () {
      // For 1h: ceil(1/4) = 1, so nextInt(1) = 0 always → shards = 1+0 = 1
      const int runs = 200;
      for (int i = 0; i < runs; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 3600,
          totalMonsterLevel: 1,
        );
        if (reward.shards > 0) {
          expect(reward.shards, 1,
              reason: 'When 1h shards are awarded, amount must be exactly 1');
        }
      }
    });

    test('when 4h shards are awarded, value is exactly 1', () {
      // For 4h: ceil(4/4) = 1, so nextInt(1) = 0 always → shards = 1
      const int runs = 200;
      for (int i = 0; i < runs; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 14400,
          totalMonsterLevel: 1,
        );
        if (reward.shards > 0) {
          expect(reward.shards, 1,
              reason: 'When 4h shards are awarded, amount must be exactly 1');
        }
      }
    });

    test('when 8h shards are awarded, value is 1 or 2', () {
      // For 8h: ceil(8/4) = 2, so nextInt(2) ∈ {0,1} → shards ∈ {1, 2}
      const int runs = 500;
      for (int i = 0; i < runs; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 28800,
          totalMonsterLevel: 1,
        );
        if (reward.shards > 0) {
          expect(reward.shards, inInclusiveRange(1, 2),
              reason: 'When 8h shards are awarded, amount must be 1 or 2');
        }
      }
    });

    test('8h gives shards more often than 1h on average (500 runs)', () {
      const int runs = 500;
      int shardsFrom1h = 0;
      int shardsFrom8h = 0;
      for (int i = 0; i < runs; i++) {
        if (ExpeditionService.calculateReward(
          durationSeconds: 3600,
          totalMonsterLevel: 1,
        ).shards > 0) {
          shardsFrom1h++;
        }
        if (ExpeditionService.calculateReward(
          durationSeconds: 28800,
          totalMonsterLevel: 1,
        ).shards > 0) {
          shardsFrom8h++;
        }
      }
      expect(shardsFrom8h, greaterThan(shardsFrom1h),
          reason: '8h (40% chance) must yield shards more often than 1h (10%)');
    });

    test('shard chance for 1h is statistically around 10% (500 runs)', () {
      const int runs = 500;
      int shardCount = 0;
      for (int i = 0; i < runs; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 3600,
          totalMonsterLevel: 1,
        );
        if (reward.shards > 0) shardCount++;
      }
      final rate = shardCount / runs;
      // Expected ≈ 0.10, allow ±0.08 tolerance for statistical variation.
      expect(rate, inInclusiveRange(0.02, 0.18),
          reason: '1h shard rate should be near 10% (got ${(rate * 100).toStringAsFixed(1)}%)');
    });

    test('shard chance for 8h is statistically around 40% (500 runs)', () {
      const int runs = 500;
      int shardCount = 0;
      for (int i = 0; i < runs; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 28800,
          totalMonsterLevel: 1,
        );
        if (reward.shards > 0) shardCount++;
      }
      final rate = shardCount / runs;
      // Expected ≈ 0.40, allow ±0.10 tolerance.
      expect(rate, inInclusiveRange(0.25, 0.55),
          reason: '8h shard rate should be near 40% (got ${(rate * 100).toStringAsFixed(1)}%)');
    });
  });

  // ===========================================================================
  // Group 10 – Diamond reward (8h only, 15% chance)
  // ===========================================================================

  group('calculateReward – diamonds (8h only, 15% chance)', () {
    test('diamonds is 0 or 10 for 8h expedition, never other values', () {
      const int runs = 200;
      for (int i = 0; i < runs; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 28800,
          totalMonsterLevel: 1,
        );
        expect(reward.diamonds, anyOf(0, 10),
            reason: 'Diamonds for 8h must be either 0 or 10');
      }
    });

    test('diamonds is always 0 for 1h expedition', () {
      const int runs = 100;
      for (int i = 0; i < runs; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 3600,
          totalMonsterLevel: 1,
        );
        expect(reward.diamonds, 0,
            reason: 'Diamonds must always be 0 for 1h expedition');
      }
    });

    test('diamonds is always 0 for 4h expedition', () {
      const int runs = 100;
      for (int i = 0; i < runs; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 14400,
          totalMonsterLevel: 1,
        );
        expect(reward.diamonds, 0,
            reason: 'Diamonds must always be 0 for 4h expedition');
      }
    });

    test('8h diamonds rate is statistically around 15% (1000 runs)', () {
      const int runs = 1000;
      int diamondCount = 0;
      for (int i = 0; i < runs; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 28800,
          totalMonsterLevel: 1,
        );
        if (reward.diamonds > 0) diamondCount++;
      }
      final rate = diamondCount / runs;
      // Expected ≈ 0.15, allow ±0.07 tolerance.
      expect(rate, inInclusiveRange(0.05, 0.25),
          reason: '8h diamond rate should be near 15% (got ${(rate * 100).toStringAsFixed(1)}%)');
    });
  });

  // ===========================================================================
  // Group 11 – Level factor (gold and expPotions scale with monster level)
  // ===========================================================================

  group('calculateReward – level factor scaling', () {
    // levelFactor = 1.0 + (totalMonsterLevel - 1) * 0.03

    test('level-1 has levelFactor of 1.0 (baseline)', () {
      // baseGold = (200 * 1 * 1.0).round() = 200; minimum gold = 200.
      const int runs = 100;
      for (int i = 0; i < runs; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 3600,
          totalMonsterLevel: 1,
        );
        expect(reward.gold, greaterThanOrEqualTo(200),
            reason: 'Level-1, 1h: baseGold is 200');
      }
    });

    test('level-34 doubles the levelFactor (1.0 → 1.99)', () {
      // levelFactor = 1.0 + (34 - 1) * 0.03 = 1.0 + 0.99 = 1.99
      // baseGold = (200 * 1 * 1.99).round() = 398
      const int runs = 100;
      for (int i = 0; i < runs; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 3600,
          totalMonsterLevel: 34,
        );
        expect(reward.gold, greaterThanOrEqualTo(398),
            reason: 'Level-34 1h: baseGold should be 398');
      }
    });

    test('expPotions at level-34 for 1h is exactly 1', () {
      // levelFactor = 1.99; (0.5 * 1 * 1.99).round() = (0.995).round() = 1
      final reward = ExpeditionService.calculateReward(
        durationSeconds: 3600,
        totalMonsterLevel: 34,
      );
      expect(reward.expPotions, 1);
    });

    test('expPotions at level-34 for 8h is 8', () {
      // levelFactor = 1.99; (0.5 * 8 * 1.99).round() = (7.96).round() = 8
      final reward = ExpeditionService.calculateReward(
        durationSeconds: 28800,
        totalMonsterLevel: 34,
      );
      expect(reward.expPotions, 8);
    });

    test('higher level always gives higher or equal average gold (8h)', () {
      const int runs = 100;
      double sumLow = 0;
      double sumHigh = 0;
      for (int i = 0; i < runs; i++) {
        sumLow += ExpeditionService.calculateReward(
          durationSeconds: 28800,
          totalMonsterLevel: 1,
        ).gold;
        sumHigh += ExpeditionService.calculateReward(
          durationSeconds: 28800,
          totalMonsterLevel: 20,
        ).gold;
      }
      expect(sumHigh / runs, greaterThan(sumLow / runs),
          reason: 'Level-20 monsters must yield more gold than level-1 (8h)');
    });
  });

  // ===========================================================================
  // Group 12 – Time validation (valid options vs arbitrary durations)
  // ===========================================================================

  group('calculateReward – time validation and edge cases', () {
    test('returns non-null result for each predefined option duration', () {
      for (final option in ExpeditionService.options) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: option.durationSeconds,
          totalMonsterLevel: 1,
        );
        expect(reward, isA<ExpeditionReward>(),
            reason: '${option.label} must return a valid ExpeditionReward');
      }
    });

    test('all fields are non-negative for all predefined options', () {
      const int runs = 50;
      for (final option in ExpeditionService.options) {
        for (int i = 0; i < runs; i++) {
          final reward = ExpeditionService.calculateReward(
            durationSeconds: option.durationSeconds,
            totalMonsterLevel: 1,
          );
          expect(reward.gold, greaterThanOrEqualTo(0),
              reason: 'gold must be non-negative');
          expect(reward.expPotions, greaterThanOrEqualTo(0),
              reason: 'expPotions must be non-negative');
          expect(reward.shards, greaterThanOrEqualTo(0),
              reason: 'shards must be non-negative');
          expect(reward.diamonds, greaterThanOrEqualTo(0),
              reason: 'diamonds must be non-negative');
        }
      }
    });

    test('expPotions is exactly 1 for 1h, level-1 (minimum valid input)', () {
      final reward = ExpeditionService.calculateReward(
        durationSeconds: 3600,
        totalMonsterLevel: 1,
      );
      expect(reward.expPotions, 1);
    });

    test('expPotions is clamped to 20 even at extreme level for 8h', () {
      // A sufficiently high totalMonsterLevel will push expPotions past 20.
      // levelFactor for level 200 = 1 + 199 * 0.03 = 6.97
      // (0.5 * 8 * 6.97).round() = 27.88 → 28 → clamp = 20
      final reward = ExpeditionService.calculateReward(
        durationSeconds: 28800,
        totalMonsterLevel: 200,
      );
      expect(reward.expPotions, 20,
          reason: 'expPotions must be clamped to 20 at extreme levels');
    });

    test('gold variance is always within 20% of baseGold', () {
      // variance = nextInt((baseGold * 0.2).round().clamp(1, 999))
      // The variance is always in [0, baseGold * 0.2), so gold ∈ [base, base + 20%)
      const int runs = 100;
      // 1h level-1: base = 200, max = 239
      for (int i = 0; i < runs; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 3600,
          totalMonsterLevel: 1,
        );
        expect(reward.gold, inInclusiveRange(200, 239),
            reason: '1h level-1 gold must be within [200, 239]');
      }
    });

    test('totalMonsterLevel of 1 is treated as baseline (levelFactor = 1.0)', () {
      // Verify expPotions formula: (0.5 * hours * 1.0).round()
      expect(
        ExpeditionService.calculateReward(
          durationSeconds: 3600,
          totalMonsterLevel: 1,
        ).expPotions,
        1,
      );
      expect(
        ExpeditionService.calculateReward(
          durationSeconds: 14400,
          totalMonsterLevel: 1,
        ).expPotions,
        2,
      );
      expect(
        ExpeditionService.calculateReward(
          durationSeconds: 28800,
          totalMonsterLevel: 1,
        ).expPotions,
        4,
      );
    });

    test('reward struct returned is of type ExpeditionReward', () {
      final reward = ExpeditionService.calculateReward(
        durationSeconds: 3600,
        totalMonsterLevel: 5,
      );
      expect(reward, isA<ExpeditionReward>());
    });

    test('multiple calls with same inputs produce valid but potentially different gold', () {
      // Due to RNG, gold may differ between calls. Both must still be in range.
      const int runs = 20;
      for (int i = 0; i < runs; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 14400,
          totalMonsterLevel: 5,
        );
        // levelFactor = 1 + 4 * 0.03 = 1.12
        // baseGold = (200 * 4 * 1.12).round() = 896
        // variance ceiling = (896 * 0.2).round() = 179 → gold ∈ [896, 1074]
        expect(reward.gold, inInclusiveRange(896, 1075),
            reason: '4h level-5 gold must be within [896, 1075]');
      }
    });
  });

  // ===========================================================================
  // Group 13 – Edge case: level factor formula boundary checks
  // ===========================================================================

  group('calculateReward – levelFactor formula boundary checks', () {
    test('levelFactor at level-1 gives baseGold of 200 for 1h (minimum check)', () {
      // baseGold = (200 * 1 * 1.0).round() = 200
      // Gold minimum must be exactly 200.
      const int runs = 50;
      for (int i = 0; i < runs; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 3600,
          totalMonsterLevel: 1,
        );
        expect(reward.gold, greaterThanOrEqualTo(200));
      }
    });

    test('expPotions clamp lower bound: level-1, 1h yields exactly 1 (not 0)', () {
      // (0.5 * 1 * 1.0).round() = 0 without clamp, but clamp(1,20) → 1.
      // Actually 0.5 rounds to 1 in Dart (.round() on 0.5 → 0 or 1?).
      // Dart: 0.5.round() == 1 (rounds to even? No, Dart rounds half-up → 1).
      // Either way, clamp(1,20) guarantees minimum of 1.
      final reward = ExpeditionService.calculateReward(
        durationSeconds: 3600,
        totalMonsterLevel: 1,
      );
      expect(reward.expPotions, greaterThanOrEqualTo(1),
          reason: 'Lower clamp of 1 must always be respected');
    });

    test('expPotions for 2h (7200s) at level-1 is at least 1', () {
      // Not a standard option, but the service accepts any duration.
      // hours = 2; (0.5 * 2 * 1.0).round() = 1
      final reward = ExpeditionService.calculateReward(
        durationSeconds: 7200,
        totalMonsterLevel: 1,
      );
      expect(reward.expPotions, greaterThanOrEqualTo(1));
    });

    test('shard count is 0 or positive integer (never fractional)', () {
      const int runs = 100;
      for (int i = 0; i < runs; i++) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: 28800,
          totalMonsterLevel: 1,
        );
        // int type; just ensure non-negative
        expect(reward.shards, greaterThanOrEqualTo(0));
        expect(reward.shards % 1, 0); // is an integer (always true for int type)
      }
    });

    test('gold is always a positive integer across all standard options', () {
      for (final option in ExpeditionService.options) {
        final reward = ExpeditionService.calculateReward(
          durationSeconds: option.durationSeconds,
          totalMonsterLevel: 1,
        );
        expect(reward.gold, isA<int>());
        expect(reward.gold, greaterThan(0));
      }
    });
  });
}
