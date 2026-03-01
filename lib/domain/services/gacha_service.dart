import 'dart:math' as math;

import 'package:gameapp/core/constants/game_config.dart';
import 'package:gameapp/data/static/equippable_skill_database.dart';
import 'package:gameapp/data/static/monster_database.dart';
import 'package:gameapp/data/static/mount_database.dart';
import 'package:gameapp/data/static/relic_database.dart';

// =============================================================================
// Pickup Banner
// =============================================================================

/// A limited-time gacha banner with featured monsters at boosted rates.
class PickupBanner {
  final String id;
  final String nameKey; // l10n key
  final String descKey; // l10n key
  final List<String> featuredMonsterIds;
  /// Multiplier applied to gachaWeight of featured monsters (e.g., 5.0 = 5x).
  final double rateUpMultiplier;
  /// Duration in days per banner rotation.
  final int durationDays;
  /// Gradient colors for the banner UI.
  final List<int> gradientColors;

  const PickupBanner({
    required this.id,
    required this.nameKey,
    required this.descKey,
    required this.featuredMonsterIds,
    this.rateUpMultiplier = 5.0,
    this.durationDays = 3,
    this.gradientColors = const [0xFF1A0A3E, 0xFF3B1F7E, 0xFF6B3FA0],
  });
}

/// Rotating pickup banner schedule.
class PickupBannerSchedule {
  PickupBannerSchedule._();

  static const List<PickupBanner> banners = [
    PickupBanner(
      id: 'flame_dragon_pickup',
      nameKey: 'bannerFlameDragon',
      descKey: 'bannerFlameDragonDesc',
      featuredMonsterIds: ['flame_dragon', 'phoenix'],
      rateUpMultiplier: 5.0,
      gradientColors: [0xFF3E0A0A, 0xFF7E1F1F, 0xFFA03F3F],
    ),
    PickupBanner(
      id: 'archangel_pickup',
      nameKey: 'bannerArchangel',
      descKey: 'bannerArchangelDesc',
      featuredMonsterIds: ['archangel', 'ice_queen'],
      rateUpMultiplier: 5.0,
      gradientColors: [0xFF0A1A3E, 0xFF1F3B7E, 0xFF3F6BA0],
    ),
    PickupBanner(
      id: 'dark_knight_pickup',
      nameKey: 'bannerDarkKnight',
      descKey: 'bannerDarkKnightDesc',
      featuredMonsterIds: ['dark_knight', 'phoenix'],
      rateUpMultiplier: 5.0,
      gradientColors: [0xFF1A0A2E, 0xFF2E1F5E, 0xFF4A3F7E],
    ),
    PickupBanner(
      id: 'ice_queen_pickup',
      nameKey: 'bannerIceQueen',
      descKey: 'bannerIceQueenDesc',
      featuredMonsterIds: ['ice_queen', 'phoenix'],
      rateUpMultiplier: 5.0,
      gradientColors: [0xFF0A2E3E, 0xFF1F5E7E, 0xFF3F7EA0],
    ),
  ];

  /// Returns the banner index for a given timestamp.
  static int _bannerIndex(DateTime time) {
    // Use epoch day for stable rotation across year boundaries.
    final epochDay = time.millisecondsSinceEpoch ~/ 86400000;
    return (epochDay ~/ 3) % banners.length;
  }

  /// Returns the currently active banner based on date rotation.
  static PickupBanner get current => banners[_bannerIndex(DateTime.now())];

  /// Hours remaining until the current banner expires.
  static int get hoursRemaining {
    final now = DateTime.now();
    final epochDay = now.millisecondsSinceEpoch ~/ 86400000;
    final bannerEndEpochDay = ((epochDay ~/ 3) + 1) * 3;
    final endMs = bannerEndEpochDay * 86400000;
    final remaining = endMs - now.millisecondsSinceEpoch;
    return (remaining ~/ 3600000).clamp(0, 999);
  }
}

/// Result of a single monster gacha pull.
class GachaPullResult {
  final MonsterTemplate template;

  /// Whether this pull was a pity guarantee (legendary forced).
  final bool wasPity;

  /// Whether this monster was pulled from the pickup banner boost.
  final bool wasPickup;

  const GachaPullResult({
    required this.template,
    this.wasPity = false,
    this.wasPickup = false,
  });
}

/// Result of a single relic gacha pull.
class RelicPullResult {
  final RelicTemplate template;
  final bool wasPity;
  const RelicPullResult({required this.template, this.wasPity = false});
}

/// Result of a single equippable skill gacha pull.
class SkillPullResult {
  final EquippableSkillTemplate template;
  final bool wasPity;
  const SkillPullResult({required this.template, this.wasPity = false});
}

/// Result of a single mount gacha pull.
class MountPullResult {
  final MountTemplate template;
  final bool wasPity;
  const MountPullResult({required this.template, this.wasPity = false});
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
  /// [featuredIds] optional list of featured monster IDs for pickup banner.
  /// [rateUpMultiplier] weight multiplier for featured monsters.
  /// Returns the pull result and the updated pity counter.
  static ({GachaPullResult result, int newPityCount}) performSinglePull(
    int pityCount, {
    List<String>? featuredIds,
    double rateUpMultiplier = 1.0,
  }) {
    final int updatedPity = pityCount + 1;

    // Pity guarantee: force a legendary after threshold.
    if (updatedPity >= GameConfig.pityThreshold) {
      // Prefer featured legendary if banner is active
      if (featuredIds != null) {
        final featuredLegendaries = MonsterDatabase.byRarity(5)
            .where((t) => t.gachaWeight > 0 && featuredIds.contains(t.id))
            .toList();
        if (featuredLegendaries.isNotEmpty) {
          final template = featuredLegendaries[_random.nextInt(featuredLegendaries.length)];
          return (
            result: GachaPullResult(template: template, wasPity: true, wasPickup: true),
            newPityCount: 0,
          );
        }
      }
      final legendaries = MonsterDatabase.byRarity(5)
          .where((t) => t.gachaWeight > 0)
          .toList();
      if (legendaries.isNotEmpty) {
        final template = legendaries[_random.nextInt(legendaries.length)];
        return (
          result: GachaPullResult(template: template, wasPity: true),
          newPityCount: 0,
        );
      }
    }

    // Build weighted pool with banner boost
    if (featuredIds != null && featuredIds.isNotEmpty && rateUpMultiplier > 1.0) {
      final boostedPool = _buildBoostedPool(featuredIds, rateUpMultiplier);
      if (boostedPool.isNotEmpty) {
        final templateId = boostedPool[_random.nextInt(boostedPool.length)];
        final template = MonsterDatabase.findById(templateId) ?? MonsterDatabase.all.first;
        final bool isFeatured = featuredIds.contains(template.id);
        final int finalPity = template.rarity == 5 ? 0 : updatedPity;
        return (
          result: GachaPullResult(template: template, wasPickup: isFeatured),
          newPityCount: finalPity,
        );
      }
    }

    // Normal weighted random selection.
    final pool = MonsterDatabase.weightedPool;
    if (pool.isEmpty) {
      final fallback = MonsterDatabase.all.first;
      return (result: GachaPullResult(template: fallback), newPityCount: 0);
    }
    final templateId = pool[_random.nextInt(pool.length)];
    final template = MonsterDatabase.findById(templateId) ?? MonsterDatabase.all.first;

    final int finalPity = template.rarity == 5 ? 0 : updatedPity;

    return (
      result: GachaPullResult(template: template),
      newPityCount: finalPity,
    );
  }

  // Cache for boosted pool: key = "id1,id2|multiplier"
  static String? _cachedBoostedKey;
  static List<String> _cachedBoostedPool = const [];

  /// Builds a weighted pool with boosted rates for featured monsters.
  /// Cached until the banner changes.
  static List<String> _buildBoostedPool(
    List<String> featuredIds,
    double multiplier,
  ) {
    final key = '${featuredIds.join(',')}|$multiplier';
    if (key == _cachedBoostedKey) return _cachedBoostedPool;

    final List<String> pool = [];
    for (final template in MonsterDatabase.all) {
      final int weight = template.gachaWeight;
      if (weight <= 0) continue;
      final bool isFeatured = featuredIds.contains(template.id);
      final int effectiveWeight =
          isFeatured ? (weight * multiplier).round() : weight;
      for (int i = 0; i < effectiveWeight; i++) {
        pool.add(template.id);
      }
    }
    _cachedBoostedKey = key;
    _cachedBoostedPool = pool;
    return pool;
  }

  // ---------------------------------------------------------------------------
  // Multi pull (10x)
  // ---------------------------------------------------------------------------

  /// Performs 10 consecutive gacha pulls with a guarantee of at least one
  /// 3-star (희귀) or higher monster.
  ///
  /// Applies pickup banner boost when [featuredIds] is provided.
  static ({List<GachaPullResult> results, int newPityCount}) performTenPull(
    int pityCount, {
    List<String>? featuredIds,
    double rateUpMultiplier = 1.0,
  }) {
    final List<GachaPullResult> results = [];
    int currentPity = pityCount;
    bool hasRareOrAbove = false;

    for (int i = 0; i < 10; i++) {
      final pull = performSinglePull(
        currentPity,
        featuredIds: featuredIds,
        rateUpMultiplier: rateUpMultiplier,
      );
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
      if (rareOrAbove.isNotEmpty) {
        final replacement = rareOrAbove[_random.nextInt(rareOrAbove.length)];
        results[9] = GachaPullResult(template: replacement);
        if (replacement.rarity == 5) currentPity = 0;
      }
    }

    return (results: results, newPityCount: currentPity);
  }

  // ===========================================================================
  // Relic (Item) Gacha
  // ===========================================================================

  static ({RelicPullResult result, int newPityCount}) performRelicPull(
    int pityCount,
  ) {
    final int updatedPity = pityCount + 1;

    if (updatedPity >= GameConfig.pityThreshold) {
      final legendaries = RelicDatabase.byRarity(5);
      if (legendaries.isNotEmpty) {
        final template = legendaries[_random.nextInt(legendaries.length)];
        return (
          result: RelicPullResult(template: template, wasPity: true),
          newPityCount: 0,
        );
      }
    }

    // Weighted random from all relics (weight by inverse rarity)
    final all = RelicDatabase.all;
    final weights = all.map((r) => 6 - r.rarity).toList(); // 1★=5, 5★=1
    final totalWeight = weights.fold<int>(0, (s, w) => s + w);
    int roll = _random.nextInt(totalWeight);
    RelicTemplate? picked;
    for (int i = 0; i < all.length; i++) {
      roll -= weights[i];
      if (roll < 0) {
        picked = all[i];
        break;
      }
    }
    picked ??= all.first;
    final int finalPity = picked.rarity == 5 ? 0 : updatedPity;

    return (
      result: RelicPullResult(template: picked),
      newPityCount: finalPity,
    );
  }

  static ({List<RelicPullResult> results, int newPityCount}) performRelicTenPull(
    int pityCount,
  ) {
    final List<RelicPullResult> results = [];
    int currentPity = pityCount;
    bool hasRareOrAbove = false;

    for (int i = 0; i < 10; i++) {
      final pull = performRelicPull(currentPity);
      results.add(pull.result);
      currentPity = pull.newPityCount;
      if (pull.result.template.rarity >= 3) hasRareOrAbove = true;
    }

    if (!hasRareOrAbove) {
      final rareOrAbove = RelicDatabase.all.where((t) => t.rarity >= 3).toList();
      if (rareOrAbove.isNotEmpty) {
        final replacement = rareOrAbove[_random.nextInt(rareOrAbove.length)];
        results[9] = RelicPullResult(template: replacement);
        if (replacement.rarity == 5) currentPity = 0;
      }
    }

    return (results: results, newPityCount: currentPity);
  }

  // ===========================================================================
  // Mount Gacha
  // ===========================================================================

  static ({MountPullResult result, int newPityCount}) performMountPull(
    int pityCount,
  ) {
    final int updatedPity = pityCount + 1;

    if (updatedPity >= GameConfig.pityThreshold) {
      final legendaries = MountDatabase.byRarity(5);
      if (legendaries.isNotEmpty) {
        final template = legendaries[_random.nextInt(legendaries.length)];
        return (
          result: MountPullResult(template: template, wasPity: true),
          newPityCount: 0,
        );
      }
    }

    final pool = MountDatabase.weightedPool;
    if (pool.isEmpty) {
      final fallback = MountDatabase.all.first;
      return (result: MountPullResult(template: fallback), newPityCount: 0);
    }
    final templateId = pool[_random.nextInt(pool.length)];
    final template = MountDatabase.findById(templateId) ?? MountDatabase.all.first;
    final int finalPity = template.rarity == 5 ? 0 : updatedPity;

    return (
      result: MountPullResult(template: template),
      newPityCount: finalPity,
    );
  }

  static ({List<MountPullResult> results, int newPityCount}) performMountTenPull(
    int pityCount,
  ) {
    final List<MountPullResult> results = [];
    int currentPity = pityCount;
    bool hasRareOrAbove = false;

    for (int i = 0; i < 10; i++) {
      final pull = performMountPull(currentPity);
      results.add(pull.result);
      currentPity = pull.newPityCount;
      if (pull.result.template.rarity >= 3) hasRareOrAbove = true;
    }

    if (!hasRareOrAbove) {
      final rareOrAbove = MountDatabase.all.where((t) => t.rarity >= 3).toList();
      if (rareOrAbove.isNotEmpty) {
        final replacement = rareOrAbove[_random.nextInt(rareOrAbove.length)];
        results[9] = MountPullResult(template: replacement);
        if (replacement.rarity == 5) currentPity = 0;
      }
    }

    return (results: results, newPityCount: currentPity);
  }

  // ===========================================================================
  // Equippable Skill Gacha
  // ===========================================================================

  static ({SkillPullResult result, int newPityCount}) performSkillPull(
    int pityCount,
  ) {
    final int updatedPity = pityCount + 1;

    if (updatedPity >= GameConfig.pityThreshold) {
      final legendaries = EquippableSkillDatabase.byRarity(5);
      if (legendaries.isNotEmpty) {
        final template = legendaries[_random.nextInt(legendaries.length)];
        return (
          result: SkillPullResult(template: template, wasPity: true),
          newPityCount: 0,
        );
      }
    }

    final pool = EquippableSkillDatabase.weightedPool;
    if (pool.isEmpty) {
      final fallback = EquippableSkillDatabase.all.first;
      return (result: SkillPullResult(template: fallback), newPityCount: 0);
    }
    final templateId = pool[_random.nextInt(pool.length)];
    final template =
        EquippableSkillDatabase.findById(templateId) ?? EquippableSkillDatabase.all.first;
    final int finalPity = template.rarity == 5 ? 0 : updatedPity;

    return (
      result: SkillPullResult(template: template),
      newPityCount: finalPity,
    );
  }

  static ({List<SkillPullResult> results, int newPityCount}) performSkillTenPull(
    int pityCount,
  ) {
    final List<SkillPullResult> results = [];
    int currentPity = pityCount;
    bool hasRareOrAbove = false;

    for (int i = 0; i < 10; i++) {
      final pull = performSkillPull(currentPity);
      results.add(pull.result);
      currentPity = pull.newPityCount;
      if (pull.result.template.rarity >= 3) hasRareOrAbove = true;
    }

    if (!hasRareOrAbove) {
      final rareOrAbove = EquippableSkillDatabase.all.where((t) => t.rarity >= 3).toList();
      if (rareOrAbove.isNotEmpty) {
        final replacement = rareOrAbove[_random.nextInt(rareOrAbove.length)];
        results[9] = SkillPullResult(template: replacement);
        if (replacement.rarity == 5) currentPity = 0;
      }
    }

    return (results: results, newPityCount: currentPity);
  }
}
