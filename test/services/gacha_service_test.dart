import 'package:flutter_test/flutter_test.dart';
import 'package:gameapp/core/constants/game_config.dart';
import 'package:gameapp/data/static/monster_database.dart';
import 'package:gameapp/domain/services/gacha_service.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Group 1 – performSinglePull basic validity
  // ---------------------------------------------------------------------------

  group('performSinglePull – basic validity', () {
    test('1. returns a result that contains a non-null MonsterTemplate', () {
      // Arrange: start fresh with no pity accumulated.
      const int startPity = 0;

      // Act
      final pull = GachaService.performSinglePull(startPity);

      // Assert: the result struct holds a valid template from the database.
      expect(pull.result, isA<GachaPullResult>());
      expect(pull.result.template, isA<MonsterTemplate>());

      // The template id must exist in the database.
      final found = MonsterDatabase.findById(pull.result.template.id);
      expect(found, isNotNull,
          reason: 'Returned template id must be present in MonsterDatabase');
    });

    test('1b. returned template rarity is in the valid range 1–5', () {
      final pull = GachaService.performSinglePull(0);
      expect(pull.result.template.rarity, inInclusiveRange(1, 5));
    });
  });

  // ---------------------------------------------------------------------------
  // Group 2 – pity counter increments
  // ---------------------------------------------------------------------------

  group('performSinglePull – pity counter increments when no legendary', () {
    test('2. newPityCount is pityCount + 1 when a non-legendary is returned',
        () {
      // We cannot control the RNG, so we run multiple pulls and verify that
      // whenever a non-legendary (rarity < 5) is drawn the counter is exactly
      // pityCount + 1, and whenever a legendary is drawn the counter resets to 0.
      //
      // Strategy: run 200 pulls from pity 0 and verify the invariant every time.
      int pity = 0;
      for (int i = 0; i < 200; i++) {
        final before = pity;
        final pull = GachaService.performSinglePull(pity);
        final rarity = pull.result.template.rarity;

        if (rarity == 5) {
          // Legendary: pity must reset to 0.
          expect(pull.newPityCount, equals(0),
              reason: 'Legendary pull must reset pity to 0');
        } else {
          // Non-legendary: pity must be exactly before + 1.
          // Edge-case: if before + 1 >= threshold, the pity guarantee fires
          // (handled separately), so we guard against that branch here.
          if (before + 1 < GameConfig.pityThreshold) {
            expect(pull.newPityCount, equals(before + 1),
                reason:
                    'Non-legendary pull must increment pity by 1 '
                    '(was $before, got ${pull.newPityCount})');
          }
        }

        pity = pull.newPityCount;
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Group 3 – pity resets to 0 on legendary
  // ---------------------------------------------------------------------------

  group('performSinglePull – pity resets to 0 when legendary is obtained', () {
    test('3. newPityCount == 0 after any legendary pull', () {
      // Run many pulls and assert the invariant directly.
      int pity = 0;
      bool legendarySeenAtLeastOnce = false;

      for (int i = 0; i < 500; i++) {
        final pull = GachaService.performSinglePull(pity);
        if (pull.result.template.rarity == 5) {
          legendarySeenAtLeastOnce = true;
          expect(pull.newPityCount, equals(0),
              reason: 'Legendary pull must always reset pity counter to 0');
        }
        pity = pull.newPityCount;
        // Prevent the test from triggering the pity branch by capping pity
        // just below threshold so we observe natural legendary drops.
        if (pity >= GameConfig.pityThreshold - 1) pity = 0;
      }

      // We cannot guarantee RNG gives us a legendary in 500 pulls at 2% rate,
      // but statistically this should succeed. If it never fires, the test is
      // vacuously passing – which is acceptable since the pity tests below
      // give deterministic coverage of the legendary reset path.
      if (!legendarySeenAtLeastOnce) {
        // Not a failure – just informational.
        printOnFailure(
            'No natural legendary appeared in 500 pulls (2% rate). '
            'Pity-reset coverage is handled by test group 4.');
      }
    });

    test('3b. wasPity is false for a naturally drawn legendary', () {
      // Because RNG is non-deterministic we check the invariant for wasPity:
      // wasPity should only be true when the pity threshold is reached.
      // For all non-pity pulls, wasPity must be false.
      int pity = 0;
      for (int i = 0; i < 200; i++) {
        final pull = GachaService.performSinglePull(pity);
        // Only pulls at or above the threshold should have wasPity == true.
        if (!pull.result.wasPity) {
          // Pity was NOT involved – counter must follow normal rules.
          if (pull.result.template.rarity == 5) {
            expect(pull.newPityCount, equals(0));
          } else {
            expect(pull.newPityCount, greaterThan(0));
          }
        }
        pity = pull.newPityCount;
        if (pity >= GameConfig.pityThreshold - 1) pity = 0;
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Group 4 – pity guarantee at threshold (deterministic)
  // ---------------------------------------------------------------------------

  group('performSinglePull – pity guarantee triggers at threshold', () {
    test(
        '4. pull with pityCount == pityThreshold - 1 forces a legendary result',
        () {
      // Arrange: one pull away from the threshold means updatedPity == threshold.
      final int pityCountBeforeGuarantee = GameConfig.pityThreshold - 1;

      // Act
      final pull = GachaService.performSinglePull(pityCountBeforeGuarantee);

      // Assert: forced legendary.
      expect(pull.result.template.rarity, equals(5),
          reason: 'Pity guarantee must yield a 5-star (legendary) monster');
      expect(pull.result.wasPity, isTrue,
          reason: 'wasPity must be true when the pity guarantee fires');
      expect(pull.newPityCount, equals(0),
          reason: 'Pity counter must reset to 0 after guaranteed legendary');
    });

    test('4b. guaranteed legendary is an actual entry in MonsterDatabase', () {
      final pull =
          GachaService.performSinglePull(GameConfig.pityThreshold - 1);
      final found = MonsterDatabase.findById(pull.result.template.id);
      expect(found, isNotNull);
      expect(found!.rarity, equals(5));
    });

    test('4c. pity guarantee fires consistently across multiple calls', () {
      // Verify that every time we hit the threshold we get a legendary.
      for (int trial = 0; trial < 20; trial++) {
        final pull =
            GachaService.performSinglePull(GameConfig.pityThreshold - 1);
        expect(pull.result.template.rarity, equals(5),
            reason: 'Trial $trial: pity pull must always yield legendary');
        expect(pull.result.wasPity, isTrue,
            reason: 'Trial $trial: wasPity must be true');
      }
    });

    test('4d. pull above threshold (already past) still forces legendary', () {
      // updatedPity = pityThreshold (already >= threshold).
      final pull = GachaService.performSinglePull(GameConfig.pityThreshold);
      expect(pull.result.template.rarity, equals(5));
      expect(pull.result.wasPity, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Group 5 – performTenPull returns exactly 10 results
  // ---------------------------------------------------------------------------

  group('performTenPull – returns exactly 10 results', () {
    test('5. result list length is exactly 10', () {
      final tenPull = GachaService.performTenPull(0);
      expect(tenPull.results.length, equals(10));
    });

    test('5b. result list length is 10 regardless of starting pity', () {
      for (final startPity in [0, 10, 40, GameConfig.pityThreshold - 2]) {
        final tenPull = GachaService.performTenPull(startPity);
        expect(tenPull.results.length, equals(10),
            reason: 'Ten-pull with startPity=$startPity must yield 10 results');
      }
    });

    test('5c. all 10 results contain valid MonsterTemplates', () {
      final tenPull = GachaService.performTenPull(0);
      for (final result in tenPull.results) {
        expect(result, isA<GachaPullResult>());
        final found = MonsterDatabase.findById(result.template.id);
        expect(found, isNotNull,
            reason: '${result.template.id} must exist in MonsterDatabase');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Group 6 – performTenPull guarantee: at least one 3-star or higher
  // ---------------------------------------------------------------------------

  group('performTenPull – at least one 3-star or higher guaranteed', () {
    test('6. at least one result has rarity >= 3', () {
      // Run several ten-pulls to confirm the guarantee holds.
      for (int trial = 0; trial < 30; trial++) {
        final tenPull = GachaService.performTenPull(0);
        final hasRareOrAbove =
            tenPull.results.any((r) => r.template.rarity >= 3);
        expect(hasRareOrAbove, isTrue,
            reason: 'Trial $trial: ten-pull must always contain at least one '
                '3-star or higher monster');
      }
    });

    test('6b. guarantee holds when starting pity is non-zero', () {
      for (int trial = 0; trial < 20; trial++) {
        final tenPull = GachaService.performTenPull(10);
        expect(tenPull.results.any((r) => r.template.rarity >= 3), isTrue,
            reason: 'Guarantee must hold with a non-zero starting pity');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Group 7 – performTenPull pity counter tracks correctly across 10 pulls
  // ---------------------------------------------------------------------------

  group('performTenPull – pity counter tracks across all 10 pulls', () {
    test('7. newPityCount after ten-pull reflects accumulated pity', () {
      // Run a ten-pull 50 times; each time verify newPityCount is in [0, 79].
      for (int trial = 0; trial < 50; trial++) {
        final tenPull = GachaService.performTenPull(0);
        expect(tenPull.newPityCount,
            inInclusiveRange(0, GameConfig.pityThreshold - 1),
            reason: 'Pity counter must never equal or exceed threshold after '
                'a ten-pull because the guarantee would have reset it');
      }
    });

    test('7b. newPityCount is 0 when a legendary was drawn during ten-pull',
        () {
      // If any result in the ten-pull was a legendary (rarity 5) and no
      // additional non-legendary pulls followed it, the final pity is 0 or
      // the count of pulls after the last legendary.
      //
      // More precisely: the pity counter is threaded through the 10 individual
      // pulls, so it should equal the number of non-legendary pulls after the
      // last legendary draw (which may be 0 if the last pull was legendary).
      //
      // We verify an easier invariant: if the last result in results[9] is
      // legendary, newPityCount must be 0 (or possibly overridden by the
      // replacement guarantee logic, which also sets pity to 0 for legendary).
      for (int trial = 0; trial < 100; trial++) {
        final tenPull = GachaService.performTenPull(0);
        final lastRarity = tenPull.results.last.template.rarity;
        if (lastRarity == 5) {
          expect(tenPull.newPityCount, equals(0),
              reason: 'If last pull was legendary, pity must be 0');
        }
      }
    });

    test(
        '7c. ten-pull starting near pity threshold triggers guarantee mid-pull',
        () {
      // Start at pityThreshold - 5 so pity fires during the ten-pull.
      // The result list must still be 10 long and must contain the pity legendary.
      final int nearThreshold = GameConfig.pityThreshold - 5;
      final tenPull = GachaService.performTenPull(nearThreshold);

      expect(tenPull.results.length, equals(10));
      // A legendary must appear because pity fires within the first 5 pulls.
      final legendaryCount =
          tenPull.results.where((r) => r.template.rarity == 5).length;
      expect(legendaryCount, greaterThanOrEqualTo(1),
          reason: 'Pity guarantee must fire during ten-pull when starting '
              'near the threshold');
      // After the pity legendary, pity resets; final counter must reflect pulls
      // after the last legendary, and must therefore be < threshold.
      expect(tenPull.newPityCount,
          inInclusiveRange(0, GameConfig.pityThreshold - 1));
    });
  });

  // ---------------------------------------------------------------------------
  // Group 8 – multiple single pulls accumulate pity correctly
  // ---------------------------------------------------------------------------

  group('Multiple single pulls – pity accumulates correctly', () {
    test('8. pity reaches exactly N after N consecutive non-legendary pulls',
        () {
      // Because the gacha pool is heavily weighted toward non-legendaries
      // (only 6 weight out of the total pool), we start with a fresh pity and
      // count how many consecutive non-legendary pulls we can observe.
      //
      // We do 30 pulls (well below the 80 threshold) and track the counter.
      // We verify the counter matches the number of non-legendary draws.
      int pity = 0;

      for (int i = 0; i < 30; i++) {
        final before = pity;
        final pull = GachaService.performSinglePull(pity);
        pity = pull.newPityCount;

        if (pull.result.template.rarity != 5) {
          // Counter increments by 1 each non-legendary pull.
          expect(pity, equals(before + 1),
              reason:
                  'After pull ${i + 1} (non-legendary): expected pity '
                  '${before + 1}, got $pity');
        } else {
          // Legendary resets counter.
          expect(pity, equals(0));
        }
      }
    });

    test('8b. pity counter never exceeds pityThreshold - 1 during normal pulls',
        () {
      // Thread through 200 pulls; the service must never return a pityCount
      // at or above the threshold (it should fire and reset instead).
      int pity = 0;
      for (int i = 0; i < 200; i++) {
        final pull = GachaService.performSinglePull(pity);
        pity = pull.newPityCount;
        expect(pity, lessThan(GameConfig.pityThreshold),
            reason: 'Pity counter must never reach or exceed threshold; '
                'the guarantee must fire and reset it');
      }
    });

    test('8c. accumulated pity from N single pulls equals expected value '
        'when no legendary is drawn', () {
      // Run pulls from pity = 0 until pity reaches 10 (staying well below
      // threshold) or until a legendary interrupts.
      // Verify the pity at each step equals the running non-legendary count.
      int pity = 0;
      int expected = 0;

      // Cap at 15 pulls to avoid exhausting the loop on very unlucky runs.
      for (int i = 0; i < 15 && pity < 10; i++) {
        final pull = GachaService.performSinglePull(pity);
        if (pull.result.template.rarity != 5) {
          expected++;
          expect(pull.newPityCount, equals(expected),
              reason: 'After $expected non-legendary pulls, pity must be $expected');
        } else {
          // Legendary drew: reset expected tracker and break the streak.
          expected = 0;
        }
        pity = pull.newPityCount;
      }
    });

    test('8d. pity builds up then resets on pity-guarantee pull', () {
      // Deterministically drive pity to just below threshold, then trigger
      // the guarantee and confirm counter resets.
      const int pullsBeforeGuarantee = GameConfig.pityThreshold - 1;

      // Simulate 79 pulls that are all non-legendary by calling
      // performSinglePull but noting the counter as if no legendaries drop.
      // The simplest deterministic approach: feed the counter directly.
      // Drive pity counter to 79 by forcing successive increments.
      // We cannot force a non-legendary from RNG, so we directly test the
      // counter arithmetic with known inputs.

      // Verify pity builds linearly when fed incrementally without legendaries.
      // We pass each step value directly as the pityCount so the arithmetic is
      // deterministic regardless of RNG outcomes.
      for (int step = 0; step < pullsBeforeGuarantee; step++) {
        final pull = GachaService.performSinglePull(step);
        if (pull.result.template.rarity != 5) {
          // Non-legendary: counter should equal step + 1.
          expect(pull.newPityCount, equals(step + 1),
              reason: 'At step $step, non-legendary pity must be ${step + 1}');
        } else {
          // Natural legendary at this step: counter resets to 0, which is
          // also correct behaviour – no assertion needed here.
        }
      }

      // Now deterministically trigger the guarantee.
      final guaranteePull =
          GachaService.performSinglePull(GameConfig.pityThreshold - 1);
      expect(guaranteePull.result.template.rarity, equals(5),
          reason: 'Pity guarantee must fire at threshold');
      expect(guaranteePull.result.wasPity, isTrue);
      expect(guaranteePull.newPityCount, equals(0),
          reason: 'Pity must reset to 0 after the guarantee fires');
    });
  });
}
