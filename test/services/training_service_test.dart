import 'package:flutter_test/flutter_test.dart';
import 'package:gameapp/core/constants/game_config.dart';
import 'package:gameapp/data/models/monster_model.dart';
import 'package:gameapp/domain/services/training_service.dart';

MonsterModel _monster({int level = 1, int experience = 0}) => MonsterModel(
      id: 'test',
      templateId: 'slime',
      name: 'Test',
      rarity: 1,
      element: 'fire',
      level: level,
      experience: experience,
      evolutionStage: 0,
      baseAtk: 100,
      baseDef: 50,
      baseHp: 500,
      baseSpd: 10,
      size: 'small',
      isInTeam: false,
      acquiredAt: DateTime(2025, 1, 1),
      battleCount: 0,
      awakeningStars: 0,
    );

void main() {
  group('TrainingService constants', () {
    test('maxSlots is 3', () {
      expect(TrainingService.maxSlots, 3);
    });

    test('durationOptions has 3 entries', () {
      expect(TrainingService.durationOptions.length, 3);
    });

    test('durationOptions are 1h, 4h, 8h', () {
      expect(TrainingService.durationOptions, [3600, 14400, 28800]);
    });
  });

  group('calculateXp', () {
    test('1h training at level 1 gives base XP', () {
      final xp = TrainingService.calculateXp(
        durationSeconds: 3600,
        monsterLevel: 1,
      );
      expect(xp, 80); // 80 * 1 * 1.0
    });

    test('4h training gives 4x base', () {
      final xp = TrainingService.calculateXp(
        durationSeconds: 14400,
        monsterLevel: 1,
      );
      expect(xp, 320); // 80 * 4 * 1.0
    });

    test('8h training gives 8x base', () {
      final xp = TrainingService.calculateXp(
        durationSeconds: 28800,
        monsterLevel: 1,
      );
      expect(xp, 640); // 80 * 8 * 1.0
    });

    test('higher level increases XP', () {
      final xpLow = TrainingService.calculateXp(
        durationSeconds: 3600,
        monsterLevel: 1,
      );
      final xpHigh = TrainingService.calculateXp(
        durationSeconds: 3600,
        monsterLevel: 20,
      );
      expect(xpHigh, greaterThan(xpLow));
    });

    test('level factor scales correctly', () {
      final xp = TrainingService.calculateXp(
        durationSeconds: 3600,
        monsterLevel: 21,
      );
      // 80 * 1 * (1.0 + 20 * 0.05) = 80 * 2.0 = 160
      expect(xp, 160);
    });
  });

  group('applyTrainingXp', () {
    test('adds XP to monster', () {
      final m = _monster(level: 1, experience: 0);
      final updated = TrainingService.applyTrainingXp(m, 50);
      expect(updated.experience, 50);
      expect(updated.level, 1);
    });

    test('can level up monster', () {
      final m = _monster(level: 1, experience: 0);
      // Level 1 threshold is 100 * 1.2 * 1 = 120
      final updated = TrainingService.applyTrainingXp(m, 150);
      expect(updated.level, greaterThan(1));
    });

    test('handles multi-level-up', () {
      final m = _monster(level: 1, experience: 0);
      final updated = TrainingService.applyTrainingXp(m, 10000);
      expect(updated.level, greaterThan(5));
    });

    test('caps at max level', () {
      final m = _monster(level: GameConfig.maxMonsterLevel - 1, experience: 0);
      final updated = TrainingService.applyTrainingXp(m, 999999);
      expect(updated.level, GameConfig.maxMonsterLevel);
      expect(updated.experience, 0);
    });

    test('does not change max level monster', () {
      final m = _monster(level: GameConfig.maxMonsterLevel, experience: 0);
      final updated = TrainingService.applyTrainingXp(m, 1000);
      expect(updated.level, GameConfig.maxMonsterLevel);
    });
  });

  group('durationLabel', () {
    test('1h', () {
      expect(TrainingService.durationLabel(3600), '1h');
    });

    test('4h', () {
      expect(TrainingService.durationLabel(14400), '4h');
    });

    test('8h', () {
      expect(TrainingService.durationLabel(28800), '8h');
    });
  });
}
