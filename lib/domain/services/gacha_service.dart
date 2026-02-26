import 'dart:math' as math;

import 'package:gameapp/core/constants/game_config.dart';
import 'package:gameapp/data/static/monster_database.dart';

/// Result of a single gacha pull.
class GachaPullResult {
  final MonsterTemplate template;

  /// Whether this pull was a pity guarantee (legendary forced).
  final bool wasPity;

  const GachaPullResult({required this.template, this.wasPity = false});
}

/// Static gacha pull logic.
///
/// Uses [MonsterDatabase.weightedPool] for weighted random selection and
/// implements a pity system that guarantees a legendary monster after
/// [GameConfig.pityThreshold] pulls without one.
class GachaService {
  GachaService._();

  static final math.Random _random = math.Random();

  // ---------------------------------------------------------------------------
  // Single pull
  // ---------------------------------------------------------------------------

  /// Performs a single gacha pull.
  ///
  /// [pityCount] is the number of pulls since the last legendary.
  /// Returns the pull result and the updated pity counter.
  static ({GachaPullResult result, int newPityCount}) performSinglePull(
    int pityCount,
  ) {
    final int updatedPity = pityCount + 1;

    // Pity guarantee: force a legendary after threshold.
    if (updatedPity >= GameConfig.pityThreshold) {
      final legendaries = MonsterDatabase.byRarity(5);
      final template = legendaries[_random.nextInt(legendaries.length)];
      return (
        result: GachaPullResult(template: template, wasPity: true),
        newPityCount: 0,
      );
    }

    // Normal weighted random selection.
    final pool = MonsterDatabase.weightedPool;
    final templateId = pool[_random.nextInt(pool.length)];
    final template = MonsterDatabase.findById(templateId)!;

    // Reset pity if legendary.
    final int finalPity = template.rarity == 5 ? 0 : updatedPity;

    return (
      result: GachaPullResult(template: template),
      newPityCount: finalPity,
    );
  }

  // ---------------------------------------------------------------------------
  // Multi pull (10x)
  // ---------------------------------------------------------------------------

  /// Performs 10 consecutive gacha pulls with a guarantee of at least one
  /// 3-star (희귀) or higher monster.
  ///
  /// Returns the list of results and the updated pity counter.
  static ({List<GachaPullResult> results, int newPityCount}) performTenPull(
    int pityCount,
  ) {
    final List<GachaPullResult> results = [];
    int currentPity = pityCount;
    bool hasRareOrAbove = false;

    for (int i = 0; i < 10; i++) {
      final pull = performSinglePull(currentPity);
      results.add(pull.result);
      currentPity = pull.newPityCount;
      if (pull.result.template.rarity >= 3) {
        hasRareOrAbove = true;
      }
    }

    // Guarantee: if no 3★+ in 10 pulls, replace last normal with a random rare+.
    if (!hasRareOrAbove) {
      final rareOrAbove = MonsterDatabase.all
          .where((t) => t.rarity >= 3)
          .toList();
      final replacement = rareOrAbove[_random.nextInt(rareOrAbove.length)];
      results[9] = GachaPullResult(template: replacement);
      // Pity not affected since rare ≠ legendary.
    }

    return (results: results, newPityCount: currentPity);
  }
}
