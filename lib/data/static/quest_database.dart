/// Quest type: resets daily vs. permanent achievements.
enum QuestType { daily, weekly, achievement }

/// The in-game event that increments a quest's progress counter.
enum QuestTrigger {
  battleWin,       // win any battle
  gachaPull,       // perform any gacha pull
  monsterLevelUp,  // level up a monster
  monsterEvolve,   // evolve a monster
  stageFirstClear, // clear a new stage for the first time
  collectMonster,  // collect a unique monster template
}

// =============================================================================
// QuestDefinition — immutable static data for one quest type
// =============================================================================

/// Immutable design-time data describing a quest.
///
/// Individual player progress is tracked in [QuestModel] instances that
/// reference a definition via [id].
class QuestDefinition {
  final String     id;

  /// Display name shown in the quest list (Korean).
  final String     name;

  /// Short description shown below the quest name (Korean).
  final String     description;

  final QuestType    type;
  final QuestTrigger trigger;

  /// How many times the trigger must fire before the quest is complete.
  final int targetCount;

  /// Gold rewarded on completion (0 if none).
  final int rewardGold;

  /// Diamond rewarded on completion (0 if none).
  final int rewardDiamond;

  /// Gacha ticket rewarded on completion (0 if none).
  /// Also used for monster shard rewards where noted.
  final int rewardGachaTicket;

  const QuestDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.trigger,
    required this.targetCount,
    this.rewardGold        = 0,
    this.rewardDiamond     = 0,
    this.rewardGachaTicket = 0,
  });
}

// =============================================================================
// Quest Database
// =============================================================================

/// All quest definitions, split by type.
class QuestDatabase {
  QuestDatabase._();

  // ---------------------------------------------------------------------------
  // Daily quests (6 total) — reset each day at midnight UTC
  // ---------------------------------------------------------------------------

  static const QuestDefinition dailyBattle3 = QuestDefinition(
    id:          'daily_battle_3',
    name:        '일일 전투 3회',
    description: '오늘 전투에서 3번 승리하세요.',
    type:        QuestType.daily,
    trigger:     QuestTrigger.battleWin,
    targetCount: 3,
    rewardGold:  200,
  );

  static const QuestDefinition dailyBattle10 = QuestDefinition(
    id:            'daily_battle_10',
    name:          '일일 전투 10회',
    description:   '오늘 전투에서 10번 승리하세요.',
    type:          QuestType.daily,
    trigger:       QuestTrigger.battleWin,
    targetCount:   10,
    rewardGold:    500,
    rewardDiamond: 50,
  );

  static const QuestDefinition dailyGacha1 = QuestDefinition(
    id:          'daily_gacha_1',
    name:        '일일 소환 1회',
    description: '오늘 가챠 소환을 1번 수행하세요.',
    type:        QuestType.daily,
    trigger:     QuestTrigger.gachaPull,
    targetCount: 1,
    rewardGold:  300,
  );

  static const QuestDefinition dailyLevelUp1 = QuestDefinition(
    id:          'daily_levelup_1',
    name:        '일일 강화 1회',
    description: '오늘 몬스터를 1번 강화하세요.',
    type:        QuestType.daily,
    trigger:     QuestTrigger.monsterLevelUp,
    targetCount: 1,
    rewardGold:  200,
  );

  static const QuestDefinition dailyGacha3 = QuestDefinition(
    id:            'daily_gacha_3',
    name:          '일일 소환 3회',
    description:   '오늘 가챠 소환을 3번 수행하세요.',
    type:          QuestType.daily,
    trigger:       QuestTrigger.gachaPull,
    targetCount:   3,
    rewardDiamond: 100,
  );

  static const QuestDefinition dailyEvolve1 = QuestDefinition(
    id:                'daily_evolve_1',
    name:              '일일 진화 1회',
    description:       '오늘 몬스터를 1번 진화시키세요.',
    type:              QuestType.daily,
    trigger:           QuestTrigger.monsterEvolve,
    targetCount:       1,
    rewardDiamond:     50,
    rewardGachaTicket: 5,   // 5 monster shards
  );

  // ---------------------------------------------------------------------------
  // Weekly quests (4 total) — reset each Monday
  // ---------------------------------------------------------------------------

  static const QuestDefinition weeklyBattle30 = QuestDefinition(
    id:            'weekly_battle_30',
    name:          '주간 전투 30회',
    description:   '이번 주 전투에서 30번 승리하세요.',
    type:          QuestType.weekly,
    trigger:       QuestTrigger.battleWin,
    targetCount:   30,
    rewardGold:    2000,
    rewardDiamond: 100,
  );

  static const QuestDefinition weeklyGacha10 = QuestDefinition(
    id:                'weekly_gacha_10',
    name:              '주간 소환 10회',
    description:       '이번 주 가챠 소환을 10번 수행하세요.',
    type:              QuestType.weekly,
    trigger:           QuestTrigger.gachaPull,
    targetCount:       10,
    rewardDiamond:     150,
    rewardGachaTicket: 2,
  );

  static const QuestDefinition weeklyLevelUp10 = QuestDefinition(
    id:          'weekly_levelup_10',
    name:        '주간 강화 10회',
    description: '이번 주 몬스터를 10번 강화하세요.',
    type:        QuestType.weekly,
    trigger:     QuestTrigger.monsterLevelUp,
    targetCount: 10,
    rewardGold:  3000,
  );

  static const QuestDefinition weeklyEvolve3 = QuestDefinition(
    id:            'weekly_evolve_3',
    name:          '주간 진화 3회',
    description:   '이번 주 몬스터를 3번 진화시키세요.',
    type:          QuestType.weekly,
    trigger:       QuestTrigger.monsterEvolve,
    targetCount:   3,
    rewardDiamond: 200,
  );

  // ---------------------------------------------------------------------------
  // Achievements (6 total) — never reset
  // ---------------------------------------------------------------------------

  static const QuestDefinition achBattle100 = QuestDefinition(
    id:            'ach_battle_100',
    name:          '전투 100회 달성',
    description:   '누적 전투 승리 횟수가 100회에 도달하세요.',
    type:          QuestType.achievement,
    trigger:       QuestTrigger.battleWin,
    targetCount:   100,
    rewardDiamond: 200,
  );

  static const QuestDefinition achBattle500 = QuestDefinition(
    id:            'ach_battle_500',
    name:          '전투 500회 달성',
    description:   '누적 전투 승리 횟수가 500회에 도달하세요.',
    type:          QuestType.achievement,
    trigger:       QuestTrigger.battleWin,
    targetCount:   500,
    rewardDiamond: 500,
  );

  static const QuestDefinition achStage10 = QuestDefinition(
    id:            'ach_stage_10',
    name:          '10 스테이지 클리어',
    description:   '서로 다른 스테이지를 10개 최초 클리어하세요.',
    type:          QuestType.achievement,
    trigger:       QuestTrigger.stageFirstClear,
    targetCount:   10,
    rewardDiamond: 300,
  );

  static const QuestDefinition achStage30 = QuestDefinition(
    id:            'ach_stage_30',
    name:          '전 스테이지 클리어',
    description:   '모든 30개 스테이지를 최초 클리어하세요.',
    type:          QuestType.achievement,
    trigger:       QuestTrigger.stageFirstClear,
    targetCount:   30,
    rewardDiamond: 1000,
  );

  static const QuestDefinition achCollect10 = QuestDefinition(
    id:            'ach_collect_10',
    name:          '10종 몬스터 수집',
    description:   '서로 다른 종류의 몬스터를 10종 수집하세요.',
    type:          QuestType.achievement,
    trigger:       QuestTrigger.collectMonster,
    targetCount:   10,
    rewardDiamond: 200,
  );

  static const QuestDefinition achCollect20 = QuestDefinition(
    id:            'ach_collect_20',
    name:          '전 몬스터 수집',
    description:   '모든 20종의 몬스터를 수집하세요.',
    type:          QuestType.achievement,
    trigger:       QuestTrigger.collectMonster,
    targetCount:   20,
    rewardDiamond: 1000,
  );

  // ---------------------------------------------------------------------------
  // Grouped lists
  // ---------------------------------------------------------------------------

  /// All six daily quests.
  static const List<QuestDefinition> dailyQuests = [
    dailyBattle3,
    dailyBattle10,
    dailyGacha1,
    dailyLevelUp1,
    dailyGacha3,
    dailyEvolve1,
  ];

  /// All four weekly quests.
  static const List<QuestDefinition> weeklyQuests = [
    weeklyBattle30,
    weeklyGacha10,
    weeklyLevelUp10,
    weeklyEvolve3,
  ];

  /// All six achievement quests.
  static const List<QuestDefinition> achievements = [
    achBattle100,
    achBattle500,
    achStage10,
    achStage30,
    achCollect10,
    achCollect20,
  ];

  /// Every quest definition in the database.
  static const List<QuestDefinition> all = [
    ...dailyQuests,
    ...weeklyQuests,
    ...achievements,
  ];

  // ---------------------------------------------------------------------------
  // Lookup helper
  // ---------------------------------------------------------------------------

  /// Finds a definition by its [id], returning null if not found.
  static QuestDefinition? findById(String id) {
    try {
      return all.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }
}
