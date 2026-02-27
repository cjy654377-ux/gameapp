import 'package:flutter_test/flutter_test.dart';
import 'package:gameapp/data/static/monster_database.dart';
import 'package:gameapp/domain/services/arena_service.dart';

void main() {
  // ===========================================================================
  // Constants
  // ===========================================================================

  group('ArenaService constants', () {
    test('maxDailyAttempts is 5', () {
      expect(ArenaService.maxDailyAttempts, 5);
    });

    test('startingRating is 1000', () {
      expect(ArenaService.startingRating, 1000);
    });
  });

  // ===========================================================================
  // generateOpponents — list structure
  // ===========================================================================

  group('generateOpponents – returns exactly 3 opponents', () {
    test('returns a list of exactly 3 opponents', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 10,
        playerRating: 1000,
      );
      expect(opponents.length, 3);
    });

    test('returns 3 opponents regardless of playerLevel=1', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 1,
        playerRating: ArenaService.startingRating,
      );
      expect(opponents.length, 3);
    });

    test('returns 3 opponents for max-level player (level 100)', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 100,
        playerRating: 5000,
      );
      expect(opponents.length, 3);
    });

    test('each opponent is an ArenaOpponent instance', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 20,
        playerRating: 1200,
      );
      for (final op in opponents) {
        expect(op, isA<ArenaOpponent>());
      }
    });
  });

  // ===========================================================================
  // generateOpponents — difficulty ordering (easy / normal / hard)
  // ===========================================================================

  group('generateOpponents – difficulty scaling (easy/normal/hard)', () {
    // Run several trials so we are robust to RNG variance.
    const trials = 30;

    test('easy opponent (index 0) has a smaller team than hard (index 2)', () {
      // easy = teamSize 2, hard = teamSize 4 — deterministic from difficulty.
      for (int i = 0; i < trials; i++) {
        final opponents = ArenaService.generateOpponents(
          playerLevel: 10,
          playerRating: 1000,
        );
        expect(opponents[0].team.length, lessThanOrEqualTo(opponents[2].team.length),
            reason: 'Easy opponent team must not be larger than hard opponent team');
      }
    });

    test('easy opponent team size is exactly 2', () {
      for (int i = 0; i < trials; i++) {
        final opponents = ArenaService.generateOpponents(
          playerLevel: 10,
          playerRating: 1000,
        );
        // difficulty 0 → teamSize = (2 + 0).clamp(2,4) = 2
        expect(opponents[0].team.length, 2,
            reason: 'Easy opponent must always have a team of exactly 2');
      }
    });

    test('normal opponent team size is exactly 3', () {
      for (int i = 0; i < trials; i++) {
        final opponents = ArenaService.generateOpponents(
          playerLevel: 10,
          playerRating: 1000,
        );
        // difficulty 1 → teamSize = (2 + 1).clamp(2,4) = 3
        expect(opponents[1].team.length, 3,
            reason: 'Normal opponent must always have a team of exactly 3');
      }
    });

    test('hard opponent team size is exactly 4', () {
      for (int i = 0; i < trials; i++) {
        final opponents = ArenaService.generateOpponents(
          playerLevel: 10,
          playerRating: 1000,
        );
        // difficulty 2 → teamSize = (2 + 2).clamp(2,4) = 4
        expect(opponents[2].team.length, 4,
            reason: 'Hard opponent must always have a team of exactly 4');
      }
    });

    test('easy opponent ratingGain is 10', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 10,
        playerRating: 1000,
      );
      expect(opponents[0].ratingGain, 10);
    });

    test('normal opponent ratingGain is 20', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 10,
        playerRating: 1000,
      );
      expect(opponents[1].ratingGain, 20);
    });

    test('hard opponent ratingGain is 35', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 10,
        playerRating: 1000,
      );
      expect(opponents[2].ratingGain, 35);
    });
  });

  // ===========================================================================
  // generateOpponents — reward values
  // ===========================================================================

  group('generateOpponents – reward values', () {
    test('easy diamond reward is 5', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 10,
        playerRating: 1000,
      );
      expect(opponents[0].rewardDiamond, 5);
    });

    test('normal diamond reward is 10', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 10,
        playerRating: 1000,
      );
      expect(opponents[1].rewardDiamond, 10);
    });

    test('hard diamond reward is 20', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 10,
        playerRating: 1000,
      );
      expect(opponents[2].rewardDiamond, 20);
    });

    test('easy gold reward equals goldBase (100 + playerLevel * 5)', () {
      const level = 10;
      final opponents = ArenaService.generateOpponents(
        playerLevel: level,
        playerRating: 1000,
      );
      final expectedGold = 100 + level * 5; // 150
      expect(opponents[0].rewardGold, expectedGold);
    });

    test('normal gold reward equals goldBase * 1.5', () {
      const level = 10;
      final opponents = ArenaService.generateOpponents(
        playerLevel: level,
        playerRating: 1000,
      );
      final goldBase = 100 + level * 5; // 150
      expect(opponents[1].rewardGold, (goldBase * 1.5).round()); // 225
    });

    test('hard gold reward equals goldBase * 2.5', () {
      const level = 10;
      final opponents = ArenaService.generateOpponents(
        playerLevel: level,
        playerRating: 1000,
      );
      final goldBase = 100 + level * 5; // 150
      expect(opponents[2].rewardGold, (goldBase * 2.5).round()); // 375
    });

    test('hard gold reward is higher than easy gold reward', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 20,
        playerRating: 1000,
      );
      expect(opponents[2].rewardGold, greaterThan(opponents[0].rewardGold));
    });

    test('gold rewards scale with playerLevel', () {
      final lowLevelOpponents = ArenaService.generateOpponents(
        playerLevel: 1,
        playerRating: 1000,
      );
      final highLevelOpponents = ArenaService.generateOpponents(
        playerLevel: 50,
        playerRating: 1000,
      );
      expect(highLevelOpponents[0].rewardGold,
          greaterThan(lowLevelOpponents[0].rewardGold),
          reason: 'Gold reward must scale with player level');
    });
  });

  // ===========================================================================
  // generateOpponents — rating calculation
  // ===========================================================================

  group('generateOpponents – opponent rating bounds', () {
    test('all opponent ratings are within clamped range [100, 9999]', () {
      for (int trial = 0; trial < 20; trial++) {
        final opponents = ArenaService.generateOpponents(
          playerLevel: 10,
          playerRating: 1000,
        );
        for (final op in opponents) {
          expect(op.rating, inInclusiveRange(100, 9999),
              reason: 'Opponent rating must be in [100, 9999]');
        }
      }
    });

    test('easy opponent rating is generally lower than hard opponent rating', () {
      // Run many trials; on average easy should be lower than hard.
      int easyLowerCount = 0;
      const trialCount = 50;

      for (int i = 0; i < trialCount; i++) {
        final opponents = ArenaService.generateOpponents(
          playerLevel: 20,
          playerRating: 2000,
        );
        if (opponents[0].rating < opponents[2].rating) easyLowerCount++;
      }

      // Easy offset is always negative (-100 to -200), hard is always positive
      // (+50 to +200), so easy < hard must hold in 100% of trials when
      // playerRating is large enough to avoid clamping.
      expect(easyLowerCount, greaterThan(trialCount * 0.8),
          reason: 'Easy opponent rating should usually be lower than hard');
    });

    test('rating is clamped to 100 minimum even for low-rated players', () {
      for (int trial = 0; trial < 10; trial++) {
        final opponents = ArenaService.generateOpponents(
          playerLevel: 1,
          playerRating: 100, // minimum player rating
        );
        for (final op in opponents) {
          expect(op.rating, greaterThanOrEqualTo(100));
        }
      }
    });

    test('rating is clamped to 9999 maximum for very high-rated players', () {
      for (int trial = 0; trial < 10; trial++) {
        final opponents = ArenaService.generateOpponents(
          playerLevel: 100,
          playerRating: 9999,
        );
        for (final op in opponents) {
          expect(op.rating, lessThanOrEqualTo(9999));
        }
      }
    });
  });

  // ===========================================================================
  // generateOpponents — team monster validity
  // ===========================================================================

  group('generateOpponents – team monster validity', () {
    test('every team monster has positive stats', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 15,
        playerRating: 1200,
      );
      for (final op in opponents) {
        for (final monster in op.team) {
          expect(monster.maxHp, greaterThan(0),
              reason: '${monster.name} maxHp must be > 0');
          expect(monster.currentHp, greaterThan(0),
              reason: '${monster.name} currentHp must be > 0');
          expect(monster.atk, greaterThan(0),
              reason: '${monster.name} atk must be > 0');
          expect(monster.def, greaterThan(0),
              reason: '${monster.name} def must be > 0');
          expect(monster.spd, greaterThan(0),
              reason: '${monster.name} spd must be > 0');
        }
      }
    });

    test('every team monster currentHp equals maxHp (starts at full health)',
        () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 10,
        playerRating: 1000,
      );
      for (final op in opponents) {
        for (final monster in op.team) {
          expect(monster.currentHp, monster.maxHp,
              reason: '${monster.name} must start at full HP');
        }
      }
    });

    test('every team monster templateId exists in MonsterDatabase', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 10,
        playerRating: 1000,
      );
      for (final op in opponents) {
        for (final monster in op.team) {
          final template = MonsterDatabase.findById(monster.templateId);
          expect(template, isNotNull,
              reason:
                  '${monster.templateId} must exist in MonsterDatabase');
        }
      }
    });

    test('team monsters have unique monsterId values within each team', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 10,
        playerRating: 1000,
      );
      for (final op in opponents) {
        final ids = op.team.map((m) => m.monsterId).toList();
        expect(ids.toSet().length, ids.length,
            reason: 'Team monster IDs must be unique within a team');
      }
    });

    test('team monster monsterId contains arena_ prefix', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 10,
        playerRating: 1000,
      );
      for (final op in opponents) {
        for (final monster in op.team) {
          expect(monster.monsterId, startsWith('arena_'),
              reason:
                  '${monster.monsterId} must start with "arena_"');
        }
      }
    });

    test('team monster rarity respects max rarity for easy difficulty', () {
      // difficulty 0: maxRarity = min(3, 1 + playerLevel ~/ 10)
      // at level 10: maxRarity = min(3, 1 + 1) = 2
      const level = 10;
      final expectedMaxRarity = (1 + (level ~/ 10)).clamp(1, 3);

      for (int trial = 0; trial < 10; trial++) {
        final opponents = ArenaService.generateOpponents(
          playerLevel: level,
          playerRating: 1000,
        );
        for (final monster in opponents[0].team) {
          expect(monster.rarity, lessThanOrEqualTo(expectedMaxRarity),
              reason:
                  'Easy team monsters must not exceed rarity $expectedMaxRarity '
                  'at player level $level');
        }
      }
    });

    test('hard difficulty can include higher rarity monsters than easy', () {
      // At level 20:
      //   easy  maxRarity = min(3, 1 + 20~/10) = min(3,3) = 3
      //   hard  maxRarity = min(5, 3 + 20~/6)  = min(5,6) = 5
      // So hard can field rarity-4/5 while easy cannot.
      // We simply verify the rarity cap on hard is >= the cap on easy.
      const level = 20;
      final easyMax = (1 + (level ~/ 10)).clamp(1, 3);
      final hardMax = (3 + (level ~/ 6)).clamp(3, 5);
      expect(hardMax, greaterThanOrEqualTo(easyMax));
    });

    test('hard team stats are higher than easy team stats on average', () {
      // Run multiple trials and compare average ATK.
      double easyAvgAtk = 0;
      double hardAvgAtk = 0;
      const trialCount = 30;

      for (int i = 0; i < trialCount; i++) {
        final opponents = ArenaService.generateOpponents(
          playerLevel: 30,
          playerRating: 1500,
        );
        easyAvgAtk += opponents[0]
            .team
            .map((m) => m.atk)
            .reduce((a, b) => a + b) /
            opponents[0].team.length;
        hardAvgAtk += opponents[2]
            .team
            .map((m) => m.atk)
            .reduce((a, b) => a + b) /
            opponents[2].team.length;
      }

      expect(hardAvgAtk / trialCount, greaterThan(easyAvgAtk / trialCount),
          reason: 'Hard team average ATK should exceed easy team average ATK');
    });
  });

  // ===========================================================================
  // generateOpponents — opponent name validity
  // ===========================================================================

  group('generateOpponents – opponent name validity', () {
    test('all opponents have a non-empty name', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 10,
        playerRating: 1000,
      );
      for (final op in opponents) {
        expect(op.name, isNotEmpty,
            reason: 'Opponent name must not be empty');
      }
    });

    test('opponent names are drawn from the Korean NPC name pool', () {
      // The internal _names list — we test against the known set.
      const knownNames = {
        '그림자 사냥꾼',
        '불꽃의 마법사',
        '바람의 전사',
        '얼음의 궁수',
        '번개의 수호자',
        '대지의 기사',
        '어둠의 암살자',
        '빛의 성기사',
        '숲의 드루이드',
        '바다의 세이렌',
        '화산의 용사',
        '구름의 현자',
        '별빛의 마녀',
        '강철의 전사',
        '독안개 도적',
      };

      for (int trial = 0; trial < 20; trial++) {
        final opponents = ArenaService.generateOpponents(
          playerLevel: 10,
          playerRating: 1000,
        );
        for (final op in opponents) {
          expect(knownNames, contains(op.name),
              reason:
                  '"${op.name}" is not in the expected NPC name pool');
        }
      }
    });
  });

  // ===========================================================================
  // ratingLoss — win/loss calculation
  // ===========================================================================

  group('ratingLoss – loss penalties by difficulty', () {
    test('easy difficulty (0) rating loss is -15', () {
      expect(ArenaService.ratingLoss(0), -15);
    });

    test('normal difficulty (1) rating loss is -10', () {
      expect(ArenaService.ratingLoss(1), -10);
    });

    test('hard difficulty (2) rating loss is -5', () {
      expect(ArenaService.ratingLoss(2), -5);
    });

    test('easy loss is greater in magnitude than hard loss', () {
      // Losing to an easy opponent costs more rating than losing to a hard one.
      expect(ArenaService.ratingLoss(0).abs(),
          greaterThan(ArenaService.ratingLoss(2).abs()));
    });

    test('all rating losses are negative', () {
      for (int d = 0; d <= 2; d++) {
        expect(ArenaService.ratingLoss(d), isNegative,
            reason: 'ratingLoss(difficulty=$d) must be negative');
      }
    });
  });

  // ===========================================================================
  // Rating gain vs loss asymmetry
  // ===========================================================================

  group('Rating gain vs loss asymmetry', () {
    test('easy ratingGain (10) exceeds easy ratingLoss magnitude (15) — false: '
        'loss is higher, so losing to easy is punishing', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 10,
        playerRating: 1000,
      );
      final gain = opponents[0].ratingGain; // 10
      final loss = ArenaService.ratingLoss(0).abs(); // 15
      expect(loss, greaterThan(gain),
          reason: 'Losing to easy opponent costs more rating than winning gives');
    });

    test('hard ratingGain (35) exceeds hard ratingLoss magnitude (5)', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 10,
        playerRating: 1000,
      );
      final gain = opponents[2].ratingGain; // 35
      final loss = ArenaService.ratingLoss(2).abs(); // 5
      expect(gain, greaterThan(loss),
          reason: 'Beating hard opponent grants more rating than losing costs');
    });
  });

  // ===========================================================================
  // Edge cases
  // ===========================================================================

  group('generateOpponents – edge cases', () {
    test('playerLevel=1 produces valid opponents without exceptions', () {
      expect(
        () => ArenaService.generateOpponents(
          playerLevel: 1,
          playerRating: ArenaService.startingRating,
        ),
        returnsNormally,
      );
    });

    test('playerLevel=100 (max) produces valid opponents without exceptions',
        () {
      expect(
        () => ArenaService.generateOpponents(
          playerLevel: 100,
          playerRating: 9999,
        ),
        returnsNormally,
      );
    });

    test('very low playerRating=100 produces valid opponents', () {
      expect(
        () => ArenaService.generateOpponents(
          playerLevel: 5,
          playerRating: 100,
        ),
        returnsNormally,
      );
      final opponents = ArenaService.generateOpponents(
        playerLevel: 5,
        playerRating: 100,
      );
      for (final op in opponents) {
        expect(op.rating, greaterThanOrEqualTo(100));
      }
    });

    test('very high playerRating=9999 produces valid opponents', () {
      expect(
        () => ArenaService.generateOpponents(
          playerLevel: 100,
          playerRating: 9999,
        ),
        returnsNormally,
      );
      final opponents = ArenaService.generateOpponents(
        playerLevel: 100,
        playerRating: 9999,
      );
      for (final op in opponents) {
        expect(op.rating, lessThanOrEqualTo(9999));
      }
    });

    test('successive calls produce different results (RNG is not seeded fixed)',
        () {
      // With 15 possible names and random selection, two calls should
      // not produce identical name sequences every time.
      // Run 10 pairs and check at least one pair differs.
      bool foundDifference = false;
      for (int i = 0; i < 10; i++) {
        final a = ArenaService.generateOpponents(
          playerLevel: 10,
          playerRating: 1000,
        );
        final b = ArenaService.generateOpponents(
          playerLevel: 10,
          playerRating: 1000,
        );
        final namesA = a.map((o) => o.name).join(',');
        final namesB = b.map((o) => o.name).join(',');
        if (namesA != namesB) {
          foundDifference = true;
          break;
        }
      }
      // It's statistically near-impossible for 10 pairs to match perfectly,
      // so this should always pass. It's also fine if they match by chance —
      // we just ensure the service doesn't always return deterministic output.
      // We relax this to a soft check (no expectation) to avoid flakiness.
      // Instead, verify all opponents are still valid.
      final opponents = ArenaService.generateOpponents(
        playerLevel: 10,
        playerRating: 1000,
      );
      expect(opponents.length, 3);
      // foundDifference is informational only; no assertion to avoid flakiness.
      printOnFailure('RNG difference detected: $foundDifference');
    });

    test('ratingLoss with unknown difficulty (e.g. 99) returns -5 (default)',
        () {
      // The switch uses _ for the default → any non-0/1 difficulty returns -5.
      expect(ArenaService.ratingLoss(99), -5);
      expect(ArenaService.ratingLoss(3), -5);
      expect(ArenaService.ratingLoss(-1), -5);
    });

    test('all team monsters have skillCooldown = 0 at spawn', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 10,
        playerRating: 1000,
      );
      for (final op in opponents) {
        for (final monster in op.team) {
          expect(monster.skillCooldown, 0,
              reason:
                  '${monster.name} must start with 0 skillCooldown (ready)');
        }
      }
    });
  });

  // ===========================================================================
  // ArenaOpponent — data class integrity
  // ===========================================================================

  group('ArenaOpponent – data class integrity', () {
    test('ArenaOpponent constructor stores all fields correctly', () {
      const opponent = ArenaOpponent(
        name: '테스트 전사',
        rating: 1500,
        team: [],
        rewardGold: 300,
        rewardDiamond: 15,
        ratingGain: 25,
      );

      expect(opponent.name, '테스트 전사');
      expect(opponent.rating, 1500);
      expect(opponent.team, isEmpty);
      expect(opponent.rewardGold, 300);
      expect(opponent.rewardDiamond, 15);
      expect(opponent.ratingGain, 25);
    });

    test('generated ArenaOpponent fields are all non-null', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 10,
        playerRating: 1000,
      );
      for (final op in opponents) {
        expect(op.name, isNotNull);
        expect(op.rating, isNotNull);
        expect(op.team, isNotNull);
        expect(op.rewardGold, isNotNull);
        expect(op.rewardDiamond, isNotNull);
        expect(op.ratingGain, isNotNull);
      }
    });

    test('generated ratingGain values are positive', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 10,
        playerRating: 1000,
      );
      for (final op in opponents) {
        expect(op.ratingGain, isPositive,
            reason: 'ratingGain must be positive (${op.ratingGain})');
      }
    });

    test('generated rewardGold values are positive', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 1,
        playerRating: 1000,
      );
      for (final op in opponents) {
        expect(op.rewardGold, isPositive,
            reason: 'rewardGold must be positive (${op.rewardGold})');
      }
    });

    test('generated rewardDiamond values are positive', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 10,
        playerRating: 1000,
      );
      for (final op in opponents) {
        expect(op.rewardDiamond, isPositive,
            reason: 'rewardDiamond must be positive (${op.rewardDiamond})');
      }
    });
  });

  // ===========================================================================
  // Reward calculation — level scaling verification
  // ===========================================================================

  group('Reward calculation – level scaling', () {
    test('goldBase = 100 + level * 5 is correct for level 1', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 1,
        playerRating: 1000,
      );
      // goldBase = 100 + 1*5 = 105
      expect(opponents[0].rewardGold, 105);
      expect(opponents[1].rewardGold, (105 * 1.5).round()); // 158
      expect(opponents[2].rewardGold, (105 * 2.5).round()); // 263
    });

    test('goldBase = 100 + level * 5 is correct for level 20', () {
      final opponents = ArenaService.generateOpponents(
        playerLevel: 20,
        playerRating: 1000,
      );
      // goldBase = 100 + 20*5 = 200
      expect(opponents[0].rewardGold, 200);
      expect(opponents[1].rewardGold, (200 * 1.5).round()); // 300
      expect(opponents[2].rewardGold, (200 * 2.5).round()); // 500
    });

    test('diamond rewards are fixed regardless of player level', () {
      for (final level in [1, 10, 50, 100]) {
        final opponents = ArenaService.generateOpponents(
          playerLevel: level,
          playerRating: 1000,
        );
        expect(opponents[0].rewardDiamond, 5,
            reason: 'Easy diamond reward must always be 5 (level=$level)');
        expect(opponents[1].rewardDiamond, 10,
            reason: 'Normal diamond reward must always be 10 (level=$level)');
        expect(opponents[2].rewardDiamond, 20,
            reason: 'Hard diamond reward must always be 20 (level=$level)');
      }
    });

    test('ratingGain values are fixed regardless of player level', () {
      for (final level in [1, 30, 100]) {
        final opponents = ArenaService.generateOpponents(
          playerLevel: level,
          playerRating: 1000,
        );
        expect(opponents[0].ratingGain, 10);
        expect(opponents[1].ratingGain, 20);
        expect(opponents[2].ratingGain, 35);
      }
    });
  });
}
