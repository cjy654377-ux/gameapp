// Training Service - auto-leveling slot XP calculations
import 'package:gameapp/core/constants/game_config.dart';
import 'package:gameapp/data/models/monster_model.dart';

class TrainingService {
  TrainingService._();

  static const int maxSlots = 3;

  /// Duration options in seconds.
  static const List<int> durationOptions = [3600, 14400, 28800]; // 1h, 4h, 8h

  /// XP granted for completing training.
  ///
  /// Scales with duration and monster level.
  static int calculateXp({
    required int durationSeconds,
    required int monsterLevel,
  }) {
    final hours = durationSeconds / 3600.0;
    final levelFactor = 1.0 + (monsterLevel - 1) * 0.05;
    return (80 * hours * levelFactor).round();
  }

  /// Applies training XP to a monster, handling multi-level-ups.
  static MonsterModel applyTrainingXp(MonsterModel monster, int xp) {
    if (monster.level >= GameConfig.maxMonsterLevel) return monster;

    int totalExp = monster.experience + xp;
    int newLevel = monster.level;

    while (newLevel < GameConfig.maxMonsterLevel) {
      final threshold = _expToNextLevel(newLevel);
      if (totalExp >= threshold) {
        totalExp -= threshold;
        newLevel++;
      } else {
        break;
      }
    }

    if (newLevel >= GameConfig.maxMonsterLevel) {
      return monster.copyWith(
        level: GameConfig.maxMonsterLevel,
        experience: 0,
      );
    }

    return monster.copyWith(level: newLevel, experience: totalExp);
  }

  /// Duration label for display.
  static String durationLabel(int seconds) {
    final hours = seconds ~/ 3600;
    return '${hours}h';
  }

  static int _expToNextLevel(int level) => (100 * (1.2 * level)).round();
}
