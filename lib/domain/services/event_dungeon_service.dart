import 'dart:math' as math;

import 'package:gameapp/data/static/monster_database.dart';
import 'package:gameapp/data/static/skill_database.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';

// =============================================================================
// EventDungeon — time-limited special stage definition
// =============================================================================

class EventDungeon {
  final String id;
  final String name;
  final String description;
  final String element; // dominant element theme
  final int recommendedLevel;
  final int stages; // number of waves
  final int rewardGold;
  final int rewardDiamond;
  final int rewardExpPotions;
  final int rewardGachaTickets;
  final DateTime startDate;
  final DateTime endDate;

  const EventDungeon({
    required this.id,
    required this.name,
    required this.description,
    required this.element,
    required this.recommendedLevel,
    required this.stages,
    required this.rewardGold,
    required this.rewardDiamond,
    required this.rewardExpPotions,
    required this.rewardGachaTickets,
    required this.startDate,
    required this.endDate,
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return Duration.zero;
    return endDate.difference(now);
  }
}

// =============================================================================
// EventDungeonService
// =============================================================================

class EventDungeonService {
  EventDungeonService._();

  static final _rng = math.Random();

  /// Returns all currently active event dungeons.
  /// Events rotate weekly — 2 events active at any given time.
  static List<EventDungeon> getActiveEvents() {
    final now = DateTime.now();
    final weekOfYear = _weekOfYear(now);

    // Generate 2 events per week based on week number.
    return [
      _generateEvent(
        seed: weekOfYear * 2,
        index: 0,
        now: now,
      ),
      _generateEvent(
        seed: weekOfYear * 2 + 1,
        index: 1,
        now: now,
      ),
    ];
  }

  static int _weekOfYear(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return (dayOfYear / 7).floor();
  }

  static const _eventNames = [
    ('불꽃 시련', 'fire', '타오르는 화염 속에서 살아남으세요!'),
    ('얼음 미궁', 'water', '얼어붙은 동굴의 비밀을 파헤치세요!'),
    ('번개 탑', 'electric', '전격의 탑 꼭대기에 도달하세요!'),
    ('대지의 균열', 'stone', '땅 속 깊은 곳의 보물을 찾으세요!'),
    ('숲의 축제', 'grass', '고대 숲의 정령을 만나보세요!'),
    ('어둠의 제단', 'dark', '어둠의 의식을 저지하세요!'),
    ('빛의 성소', 'light', '빛나는 성소의 시련을 통과하세요!'),
    ('유령의 저택', 'ghost', '유령이 출몰하는 저택을 탐험하세요!'),
  ];

  static EventDungeon _generateEvent({
    required int seed,
    required int index,
    required DateTime now,
  }) {
    final rng = math.Random(seed);
    final eventIdx = rng.nextInt(_eventNames.length);
    final (name, element, desc) = _eventNames[eventIdx];

    // Weekly events: start Monday, end Sunday.
    final weekday = now.weekday; // 1=Monday
    final monday = now.subtract(Duration(days: weekday - 1));
    final startDate = DateTime(monday.year, monday.month, monday.day);
    final endDate = startDate.add(const Duration(days: 7));

    final difficulty = index == 0 ? 1 : 2; // 1=normal, 2=hard
    final recLevel = 5 + difficulty * 10;
    final stages = 3 + difficulty;

    return EventDungeon(
      id: 'event_${seed}_$index',
      name: '$name ${difficulty == 2 ? "(고급)" : "(일반)"}',
      description: desc,
      element: element,
      recommendedLevel: recLevel,
      stages: stages,
      rewardGold: 500 * difficulty,
      rewardDiamond: 15 * difficulty,
      rewardExpPotions: 2 * difficulty,
      rewardGachaTickets: difficulty,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Creates enemy team for a specific wave of an event dungeon.
  static List<BattleMonster> createEnemies({
    required String element,
    required int wave,
    required int totalWaves,
    required int recommendedLevel,
  }) {
    // Enemy level scales with wave.
    final baseLevel = recommendedLevel + (wave - 1) * 3;
    final count = 2 + (wave * 0.5).floor().clamp(0, 2); // 2-4 enemies

    // Prefer monsters of the event's element.
    final templates = MonsterDatabase.all;
    final elementMonsters =
        templates.where((t) => t.element == element).toList();
    final otherMonsters =
        templates.where((t) => t.element != element).toList();

    final enemies = <BattleMonster>[];
    for (int i = 0; i < count; i++) {
      // 70% chance of same element, 30% other.
      final pool = (_rng.nextDouble() < 0.7 && elementMonsters.isNotEmpty)
          ? elementMonsters
          : otherMonsters;
      final template = pool[_rng.nextInt(pool.length)];

      final level = (baseLevel + _rng.nextInt(3) - 1).clamp(1, 100);
      final scale = 1.0 + (level - 1) * 0.05;

      // Boss on final wave: 1.5x stats.
      final bossMultiplier = (wave == totalWaves) ? 1.5 : 1.0;

      final hp = template.baseHp * scale * bossMultiplier;
      final skill = SkillDatabase.findByTemplateId(template.id);

      enemies.add(BattleMonster(
        monsterId: 'event_enemy_${template.id}_${wave}_$i',
        templateId: template.id,
        name: wave == totalWaves && i == 0
            ? '${template.name} (보스)'
            : template.name,
        element: template.element,
        size: template.size,
        rarity: template.rarity,
        maxHp: hp,
        currentHp: hp,
        atk: template.baseAtk * scale * bossMultiplier,
        def: template.baseDef * scale * bossMultiplier,
        spd: template.baseSpd * scale,
        skillId: skill?.id,
        skillName: skill?.name,
        skillCooldown: 0,
        skillMaxCooldown: skill?.cooldown ?? 0,
      ));
    }

    return enemies;
  }
}
