import 'package:flutter_test/flutter_test.dart';
import 'package:gameapp/data/models/monster_model.dart';

// ---------------------------------------------------------------------------
// Helper: builds a baseline MonsterModel with sensible defaults so that
// individual tests only need to override the fields they care about.
// ---------------------------------------------------------------------------
MonsterModel buildMonster({
  String id = 'test-id',
  String templateId = 'tmpl-001',
  String name = 'TestMon',
  int rarity = 3,
  String element = 'fire',
  int level = 1,
  int experience = 0,
  int evolutionStage = 0,
  double baseAtk = 100.0,
  double baseDef = 80.0,
  double baseHp = 500.0,
  double baseSpd = 60.0,
  DateTime? acquiredAt,
  bool isInTeam = false,
  String size = 'medium',
  String? skillName,
  int awakeningStars = 0,
  int battleCount = 0,
}) {
  return MonsterModel(
    id: id,
    templateId: templateId,
    name: name,
    rarity: rarity,
    element: element,
    level: level,
    experience: experience,
    evolutionStage: evolutionStage,
    baseAtk: baseAtk,
    baseDef: baseDef,
    baseHp: baseHp,
    baseSpd: baseSpd,
    acquiredAt: acquiredAt ?? DateTime(2024, 1, 1),
    isInTeam: isInTeam,
    size: size,
    skillName: skillName,
    awakeningStars: awakeningStars,
    battleCount: battleCount,
  );
}

void main() {
  // =========================================================================
  // 1. fromTemplate factory
  // =========================================================================
  group('MonsterModel.fromTemplate', () {
    late MonsterModel monster;

    setUp(() {
      monster = MonsterModel.fromTemplate(
        id: 'from-tmpl-id',
        templateId: 'tmpl-fire-001',
        name: 'Flameling',
        rarity: 4,
        element: 'fire',
        baseAtk: 120.0,
        baseDef: 90.0,
        baseHp: 600.0,
        baseSpd: 70.0,
        size: 'small',
        skillName: '화염 강타',
      );
    });

    test('sets level to 1', () {
      expect(monster.level, 1);
    });

    test('sets experience to 0', () {
      expect(monster.experience, 0);
    });

    test('sets evolutionStage to 0', () {
      expect(monster.evolutionStage, 0);
    });

    test('sets awakeningStars to 0', () {
      expect(monster.awakeningStars, 0);
    });

    test('sets battleCount to 0', () {
      expect(monster.battleCount, 0);
    });

    test('sets isInTeam to false', () {
      expect(monster.isInTeam, false);
    });

    test('preserves provided fields (id, name, rarity, element, baseAtk, skillName)', () {
      expect(monster.id, 'from-tmpl-id');
      expect(monster.templateId, 'tmpl-fire-001');
      expect(monster.name, 'Flameling');
      expect(monster.rarity, 4);
      expect(monster.element, 'fire');
      expect(monster.baseAtk, 120.0);
      expect(monster.skillName, '화염 강타');
    });

    test('acquiredAt is set to a recent DateTime', () {
      final now = DateTime.now();
      expect(monster.acquiredAt.isBefore(now.add(const Duration(seconds: 5))), isTrue);
      expect(monster.acquiredAt.isAfter(now.subtract(const Duration(seconds: 5))), isTrue);
    });
  });

  // =========================================================================
  // 2. copyWith
  // =========================================================================
  group('MonsterModel.copyWith', () {
    late MonsterModel original;

    setUp(() {
      original = buildMonster(
        id: 'orig-id',
        name: 'OrigMon',
        level: 5,
        experience: 200,
        evolutionStage: 1,
        baseAtk: 100.0,
        baseDef: 80.0,
        baseHp: 500.0,
        baseSpd: 60.0,
        awakeningStars: 2,
        battleCount: 15,
        isInTeam: true,
        skillName: '원래 스킬',
      );
    });

    test('returns a new instance, not the same reference', () {
      final copy = original.copyWith(level: 6);
      expect(identical(copy, original), false);
    });

    test('updated field is applied', () {
      final copy = original.copyWith(level: 10);
      expect(copy.level, 10);
    });

    test('unchanged fields are preserved', () {
      final copy = original.copyWith(level: 10);
      expect(copy.id, 'orig-id');
      expect(copy.name, 'OrigMon');
      expect(copy.experience, 200);
      expect(copy.evolutionStage, 1);
      expect(copy.baseAtk, 100.0);
      expect(copy.baseDef, 80.0);
      expect(copy.baseHp, 500.0);
      expect(copy.baseSpd, 60.0);
      expect(copy.awakeningStars, 2);
      expect(copy.battleCount, 15);
      expect(copy.isInTeam, true);
      expect(copy.skillName, '원래 스킬');
    });

    test('multiple fields can be updated simultaneously', () {
      final copy = original.copyWith(
        level: 20,
        experience: 0,
        evolutionStage: 2,
        isInTeam: false,
      );
      expect(copy.level, 20);
      expect(copy.experience, 0);
      expect(copy.evolutionStage, 2);
      expect(copy.isInTeam, false);
      // Unchanged
      expect(copy.id, 'orig-id');
      expect(copy.name, 'OrigMon');
    });

    test('skillName can be explicitly set to null via copyWith', () {
      final copy = original.copyWith(skillName: null);
      expect(copy.skillName, isNull);
    });

    test('skillName is preserved when not passed to copyWith (sentinel behavior)', () {
      final copy = original.copyWith(level: 3);
      expect(copy.skillName, '원래 스킬');
    });
  });

  // =========================================================================
  // 3. _levelMultiplier
  //    Formula: 1.0 + (level - 1) * 0.05
  // =========================================================================
  group('_levelMultiplier (via finalAtk at stage-0, 0-star, 0-battle)', () {
    // With evolutionStage=0, awakeningStars=0, battleCount=0 the composite
    // multiplier reduces to levelMultiplier alone (all others are 1.0).

    double levelMult(int level) => buildMonster(level: level).finalAtk / 100.0;

    test('level 1 → multiplier 1.0', () {
      expect(levelMult(1), closeTo(1.0, 1e-9));
    });

    test('level 11 → multiplier 1.5  (1 + 10 * 0.05)', () {
      expect(levelMult(11), closeTo(1.5, 1e-9));
    });

    test('level 21 → multiplier 2.0  (1 + 20 * 0.05)', () {
      expect(levelMult(21), closeTo(2.0, 1e-9));
    });
  });

  // =========================================================================
  // 4. _evolutionMultiplier
  // =========================================================================
  group('_evolutionMultiplier (via finalAtk at level-1, 0-star, 0-battle)', () {
    double evoMult(int stage) =>
        buildMonster(evolutionStage: stage).finalAtk / 100.0;

    test('stage 0 → multiplier 1.0', () {
      expect(evoMult(0), closeTo(1.0, 1e-9));
    });

    test('stage 1 → multiplier 1.25', () {
      expect(evoMult(1), closeTo(1.25, 1e-9));
    });

    test('stage 2 → multiplier 1.60', () {
      expect(evoMult(2), closeTo(1.60, 1e-9));
    });
  });

  // =========================================================================
  // 5. _awakeningMultiplier
  //    Formula: 1.0 + awakeningStars * 0.10
  // =========================================================================
  group('_awakeningMultiplier (via finalAtk at level-1, stage-0, 0-battle)', () {
    double awakMult(int stars) =>
        buildMonster(awakeningStars: stars).finalAtk / 100.0;

    test('0 stars → multiplier 1.0', () {
      expect(awakMult(0), closeTo(1.0, 1e-9));
    });

    test('3 stars → multiplier 1.30', () {
      expect(awakMult(3), closeTo(1.30, 1e-9));
    });

    test('5 stars → multiplier 1.50', () {
      expect(awakMult(5), closeTo(1.50, 1e-9));
    });
  });

  // =========================================================================
  // 6. finalAtk / finalDef / finalHp / finalSpd via compositeMultiplier
  // =========================================================================
  group('final stats use compositeMultiplier correctly', () {
    // Use level=11 (×1.5), stage=1 (×1.25), 5 stars (×1.5), 0 battles (×1.0)
    // compositeMultiplier = 1.5 * 1.25 * 1.5 * 1.0 = 2.8125
    const double expectedComposite = 1.5 * 1.25 * 1.5 * 1.0;

    late MonsterModel monster;

    setUp(() {
      monster = buildMonster(
        level: 11,
        evolutionStage: 1,
        awakeningStars: 5,
        battleCount: 0,
        baseAtk: 100.0,
        baseDef: 80.0,
        baseHp: 500.0,
        baseSpd: 60.0,
      );
    });

    test('finalAtk = baseAtk * compositeMultiplier', () {
      expect(monster.finalAtk, closeTo(100.0 * expectedComposite, 1e-6));
    });

    test('finalDef = baseDef * compositeMultiplier', () {
      expect(monster.finalDef, closeTo(80.0 * expectedComposite, 1e-6));
    });

    test('finalHp = baseHp * compositeMultiplier', () {
      expect(monster.finalHp, closeTo(500.0 * expectedComposite, 1e-6));
    });

    test('finalSpd = baseSpd * compositeMultiplier', () {
      expect(monster.finalSpd, closeTo(60.0 * expectedComposite, 1e-6));
    });
  });

  // =========================================================================
  // 7. affinityLevel thresholds
  // =========================================================================
  group('affinityLevel thresholds', () {
    int aff(int battles) => buildMonster(battleCount: battles).affinityLevel;

    test('0 battles → level 0', () {
      expect(aff(0), 0);
    });

    test('9 battles → level 0 (just below first threshold)', () {
      expect(aff(9), 0);
    });

    test('10 battles → level 1', () {
      expect(aff(10), 1);
    });

    test('29 battles → level 1 (just below next threshold)', () {
      expect(aff(29), 1);
    });

    test('30 battles → level 2', () {
      expect(aff(30), 2);
    });

    test('59 battles → level 2', () {
      expect(aff(59), 2);
    });

    test('60 battles → level 3', () {
      expect(aff(60), 3);
    });

    test('99 battles → level 3', () {
      expect(aff(99), 3);
    });

    test('100 battles → level 4', () {
      expect(aff(100), 4);
    });

    test('149 battles → level 4', () {
      expect(aff(149), 4);
    });

    test('150 battles → level 5 (max)', () {
      expect(aff(150), 5);
    });

    test('200 battles → level 5 (max, beyond cap)', () {
      expect(aff(200), 5);
    });
  });

  // =========================================================================
  // 8. _affinityMultiplier
  //    Formula: 1.0 + affinityLevel * 0.02
  // =========================================================================
  group('_affinityMultiplier (via finalAtk at level-1, stage-0, 0-star)', () {
    // At these settings levelMult=1.0, evoMult=1.0, awakMult=1.0
    // so finalAtk = baseAtk * affinityMult = 100 * (1.0 + affinityLevel * 0.02)

    double affMult(int battles) =>
        buildMonster(battleCount: battles).finalAtk / 100.0;

    test('affinityLevel 0 (0 battles) → multiplier 1.0', () {
      expect(affMult(0), closeTo(1.0, 1e-9));
    });

    test('affinityLevel 3 (60 battles) → multiplier 1.06', () {
      expect(affMult(60), closeTo(1.06, 1e-9));
    });

    test('affinityLevel 5 (150 battles) → multiplier 1.10', () {
      expect(affMult(150), closeTo(1.10, 1e-9));
    });
  });

  // =========================================================================
  // 9. battleCountToNextAffinity
  //    Thresholds: [10, 30, 60, 100, 150]
  // =========================================================================
  group('battleCountToNextAffinity', () {
    int toNext(int battles) =>
        buildMonster(battleCount: battles).battleCountToNextAffinity;

    test('at 0 battles (level 0) → needs 10 more', () {
      expect(toNext(0), 10);
    });

    test('at 5 battles (level 0) → needs 5 more', () {
      expect(toNext(5), 5);
    });

    test('at 10 battles (level 1) → needs 20 more (to reach 30)', () {
      expect(toNext(10), 20);
    });

    test('at 25 battles (level 1) → needs 5 more (to reach 30)', () {
      expect(toNext(25), 5);
    });

    test('at 30 battles (level 2) → needs 30 more (to reach 60)', () {
      expect(toNext(30), 30);
    });

    test('at 60 battles (level 3) → needs 40 more (to reach 100)', () {
      expect(toNext(60), 40);
    });

    test('at 100 battles (level 4) → needs 50 more (to reach 150)', () {
      expect(toNext(100), 50);
    });

    test('at 150 battles (level 5, max) → 0 (already max)', () {
      expect(toNext(150), 0);
    });

    test('at 200 battles (beyond max) → 0', () {
      expect(toNext(200), 0);
    });
  });

  // =========================================================================
  // 10. expToNextLevel formula
  //     Formula: (100 * (1.2 * level)).round()
  // =========================================================================
  group('expToNextLevel formula', () {
    int exp(int level) => buildMonster(level: level).expToNextLevel;

    test('level 1 → (100 * 1.2).round() = 120', () {
      expect(exp(1), (100 * (1.2 * 1)).round());
      expect(exp(1), 120);
    });

    test('level 5 → (100 * 6.0).round() = 600', () {
      expect(exp(5), (100 * (1.2 * 5)).round());
      expect(exp(5), 600);
    });

    test('level 10 → (100 * 12.0).round() = 1200', () {
      expect(exp(10), (100 * (1.2 * 10)).round());
      expect(exp(10), 1200);
    });

    test('level 20 → (100 * 24.0).round() = 2400', () {
      expect(exp(20), (100 * (1.2 * 20)).round());
      expect(exp(20), 2400);
    });

    test('expToNextLevel increases as level increases', () {
      expect(exp(2), greaterThan(exp(1)));
      expect(exp(10), greaterThan(exp(5)));
      expect(exp(20), greaterThan(exp(10)));
    });
  });
}
