import 'dart:math' as math;

import 'package:gameapp/data/static/monster_database.dart';
import 'package:gameapp/data/static/skill_database.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';

// =============================================================================
// ArenaOpponent — AI-generated PvP opponent
// =============================================================================

class ArenaOpponent {
  final String name;
  final int rating;
  final List<BattleMonster> team;
  final int rewardGold;
  final int rewardDiamond;
  final int ratingGain;

  const ArenaOpponent({
    required this.name,
    required this.rating,
    required this.team,
    required this.rewardGold,
    required this.rewardDiamond,
    required this.ratingGain,
  });
}

// =============================================================================
// ArenaService
// =============================================================================

class ArenaService {
  ArenaService._();

  static const int maxDailyAttempts = 5;
  static const int startingRating = 1000;

  static final _rng = math.Random();

  // Korean NPC names for opponents.
  static const _names = [
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
  ];

  /// Generates 3 arena opponents scaled to the player's level and rating.
  static List<ArenaOpponent> generateOpponents({
    required int playerLevel,
    required int playerRating,
  }) {
    return [
      _generateOpponent(
        playerLevel: playerLevel,
        playerRating: playerRating,
        difficulty: 0, // easy
      ),
      _generateOpponent(
        playerLevel: playerLevel,
        playerRating: playerRating,
        difficulty: 1, // normal
      ),
      _generateOpponent(
        playerLevel: playerLevel,
        playerRating: playerRating,
        difficulty: 2, // hard
      ),
    ];
  }

  static ArenaOpponent _generateOpponent({
    required int playerLevel,
    required int playerRating,
    required int difficulty, // 0=easy, 1=normal, 2=hard
  }) {
    // Team size: 2-4 based on difficulty.
    final teamSize = (2 + difficulty).clamp(2, 4);

    // Monster rarity distribution by difficulty.
    final maxRarity = switch (difficulty) {
      0 => math.min(3, 1 + (playerLevel ~/ 10)),
      1 => math.min(4, 2 + (playerLevel ~/ 8)),
      _ => math.min(5, 3 + (playerLevel ~/ 6)),
    };

    // Level scaling: slightly below/at/above player level.
    final levelBase = switch (difficulty) {
      0 => (playerLevel * 0.7).round().clamp(1, 100),
      1 => playerLevel.clamp(1, 100),
      _ => (playerLevel * 1.3).round().clamp(1, 100),
    };

    // Build team.
    final allTemplates = MonsterDatabase.all;
    final eligible =
        allTemplates.where((t) => t.rarity <= maxRarity).toList();

    final usedIds = <String>{};
    final team = <BattleMonster>[];

    for (int i = 0; i < teamSize && eligible.isNotEmpty; i++) {
      // Pick a random template not already used.
      final available = eligible.where((t) => !usedIds.contains(t.id)).toList();
      if (available.isEmpty) break;

      // Bias toward higher rarity for harder opponents.
      available.sort((a, b) => b.rarity.compareTo(a.rarity));
      final pickIdx = difficulty >= 2
          ? _rng.nextInt((available.length * 0.5).ceil().clamp(1, available.length))
          : _rng.nextInt(available.length);
      final template = available[pickIdx];
      usedIds.add(template.id);

      // Scale stats by level.
      final level = (levelBase + _rng.nextInt(5) - 2).clamp(1, 100);
      final scale = 1.0 + (level - 1) * 0.05;

      final skill = SkillDatabase.findByTemplateId(template.id);

      final hp = template.baseHp * scale;
      team.add(BattleMonster(
        monsterId: 'arena_${template.id}_$i',
        templateId: template.id,
        name: template.name,
        element: template.element,
        size: template.size,
        rarity: template.rarity,
        maxHp: hp,
        currentHp: hp,
        atk: template.baseAtk * scale,
        def: template.baseDef * scale,
        spd: template.baseSpd * scale,
        skillId: skill?.id,
        skillName: skill?.name,
        skillCooldown: 0,
        skillMaxCooldown: skill?.cooldown ?? 0,
      ));
    }

    // Rating offset.
    final ratingOffset = switch (difficulty) {
      0 => -100 - _rng.nextInt(100),
      1 => -50 + _rng.nextInt(100),
      _ => 50 + _rng.nextInt(150),
    };
    final opponentRating = (playerRating + ratingOffset).clamp(100, 9999);

    // Rewards scale with difficulty.
    final goldBase = 100 + playerLevel * 5;
    final rewardGold = switch (difficulty) {
      0 => goldBase,
      1 => (goldBase * 1.5).round(),
      _ => (goldBase * 2.5).round(),
    };
    final rewardDiamond = switch (difficulty) {
      0 => 5,
      1 => 10,
      _ => 20,
    };
    final ratingGain = switch (difficulty) {
      0 => 10,
      1 => 20,
      _ => 35,
    };

    // Pick a unique name.
    final name = _names[_rng.nextInt(_names.length)];

    return ArenaOpponent(
      name: name,
      rating: opponentRating,
      team: team,
      rewardGold: rewardGold,
      rewardDiamond: rewardDiamond,
      ratingGain: ratingGain,
    );
  }

  /// Rating loss on defeat.
  static int ratingLoss(int difficulty) => switch (difficulty) {
        0 => -15,
        1 => -10,
        _ => -5,
      };

  // ---------------------------------------------------------------------------
  // Season system
  // ---------------------------------------------------------------------------

  /// 28일 시즌 번호 (epoch 기준)
  static int currentSeason() {
    final daysSinceEpoch =
        DateTime.now().difference(DateTime(2024, 1, 1)).inDays;
    return (daysSinceEpoch ~/ 28) + 1;
  }

  /// 시즌 남은 일수
  static int daysRemainingInSeason() {
    final daysSinceEpoch =
        DateTime.now().difference(DateTime(2024, 1, 1)).inDays;
    return 28 - (daysSinceEpoch % 28);
  }

  /// 시즌 종료 시 소프트 리셋 (1000으로 50% 수렴)
  static int softResetRating(int currentRating) {
    return ((currentRating + 1000) / 2).round();
  }

  /// 랭크 계산
  static String getRankName(int rating) {
    if (rating >= 2500) return '챔피언';
    if (rating >= 2000) return '다이아몬드';
    if (rating >= 1500) return '플래티넘';
    if (rating >= 1200) return '골드';
    return '실버';
  }

  /// 랭크 아이콘 코드포인트
  static int getRankIconCodePoint(int rating) {
    if (rating >= 2500) return 0xe30f; // crown
    if (rating >= 2000) return 0xe3aa; // diamond
    if (rating >= 1500) return 0xe838; // star
    if (rating >= 1200) return 0xe834; // grade
    return 0xf05be; // shield
  }

  /// 시즌 보상 계산 (골드, 다이아)
  static ({int gold, int diamond}) seasonReward(int rating) {
    if (rating >= 2500) return (gold: 10000, diamond: 200);
    if (rating >= 2000) return (gold: 7000, diamond: 150);
    if (rating >= 1500) return (gold: 5000, diamond: 100);
    if (rating >= 1200) return (gold: 3000, diamond: 50);
    return (gold: 1000, diamond: 20);
  }
}
