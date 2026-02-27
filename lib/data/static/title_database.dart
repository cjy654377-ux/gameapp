// Title definitions unlockable through hidden achievements.

class TitleDefinition {
  final String id;
  final String nameKo;
  final String nameEn;
  final String descKo;
  final String descEn;
  final String unlockCondition;
  final int points; // achievement points awarded on unlock

  const TitleDefinition({
    required this.id,
    required this.nameKo,
    required this.nameEn,
    required this.descKo,
    required this.descEn,
    required this.unlockCondition,
    this.points = 10,
  });
}

/// Milestone reward tiers for achievement points.
class AchievementMilestone {
  final int requiredPoints;
  final String rewardType; // 'gold', 'diamond', 'shard', 'gachaTicket'
  final int rewardAmount;
  final String descKo;
  final String descEn;

  const AchievementMilestone({
    required this.requiredPoints,
    required this.rewardType,
    required this.rewardAmount,
    required this.descKo,
    required this.descEn,
  });
}

class TitleDatabase {
  TitleDatabase._();

  static const List<TitleDefinition> titles = [
    // Battle achievements
    TitleDefinition(
      id: 'warrior',
      nameKo: '전사',
      nameEn: 'Warrior',
      descKo: '전투 100회 승리',
      descEn: 'Win 100 battles',
      unlockCondition: 'battle_100',
      points: 5,
    ),
    TitleDefinition(
      id: 'champion',
      nameKo: '챔피언',
      nameEn: 'Champion',
      descKo: '전투 500회 승리',
      descEn: 'Win 500 battles',
      unlockCondition: 'battle_500',
      points: 15,
    ),
    TitleDefinition(
      id: 'legend',
      nameKo: '전설',
      nameEn: 'Legend',
      descKo: '전투 1000회 승리',
      descEn: 'Win 1000 battles',
      unlockCondition: 'battle_1000',
      points: 25,
    ),

    // Collection
    TitleDefinition(
      id: 'collector',
      nameKo: '수집가',
      nameEn: 'Collector',
      descKo: '몬스터 10종 수집',
      descEn: 'Collect 10 monster types',
      unlockCondition: 'collect_10',
      points: 10,
    ),
    TitleDefinition(
      id: 'professor',
      nameKo: '교수',
      nameEn: 'Professor',
      descKo: '몬스터 전종 수집',
      descEn: 'Collect all monster types',
      unlockCondition: 'collect_all',
      points: 30,
    ),

    // Gacha
    TitleDefinition(
      id: 'lucky',
      nameKo: '행운아',
      nameEn: 'Lucky',
      descKo: '소환 50회 수행',
      descEn: 'Perform 50 summons',
      unlockCondition: 'gacha_50',
      points: 5,
    ),
    TitleDefinition(
      id: 'whale',
      nameKo: '고래',
      nameEn: 'Whale',
      descKo: '소환 200회 수행',
      descEn: 'Perform 200 summons',
      unlockCondition: 'gacha_200',
      points: 15,
    ),

    // Dungeon
    TitleDefinition(
      id: 'explorer',
      nameKo: '탐험가',
      nameEn: 'Explorer',
      descKo: '던전 20층 도달',
      descEn: 'Reach dungeon floor 20',
      unlockCondition: 'dungeon_20',
      points: 10,
    ),
    TitleDefinition(
      id: 'deepdiver',
      nameKo: '심해탐사자',
      nameEn: 'Deep Diver',
      descKo: '던전 50층 도달',
      descEn: 'Reach dungeon floor 50',
      unlockCondition: 'dungeon_50',
      points: 20,
    ),

    // Prestige
    TitleDefinition(
      id: 'reborn',
      nameKo: '전생자',
      nameEn: 'Reborn',
      descKo: '첫 전생 달성',
      descEn: 'Complete first prestige',
      unlockCondition: 'prestige_1',
      points: 15,
    ),
    TitleDefinition(
      id: 'immortal',
      nameKo: '불멸자',
      nameEn: 'Immortal',
      descKo: '전생 5회 달성',
      descEn: 'Complete 5 prestiges',
      unlockCondition: 'prestige_5',
      points: 25,
    ),

    // Special
    TitleDefinition(
      id: 'dedicated',
      nameKo: '헌신자',
      nameEn: 'Dedicated',
      descKo: '7일 연속 출석',
      descEn: 'Check in 7 days in a row',
      unlockCondition: 'checkin_7',
      points: 10,
    ),
  ];

  /// Achievement point milestones with rewards.
  static const List<AchievementMilestone> milestones = [
    AchievementMilestone(
      requiredPoints: 10,
      rewardType: 'gold',
      rewardAmount: 5000,
      descKo: '골드 5,000',
      descEn: '5,000 Gold',
    ),
    AchievementMilestone(
      requiredPoints: 25,
      rewardType: 'diamond',
      rewardAmount: 50,
      descKo: '다이아 50',
      descEn: '50 Diamonds',
    ),
    AchievementMilestone(
      requiredPoints: 50,
      rewardType: 'gachaTicket',
      rewardAmount: 5,
      descKo: '소환권 5장',
      descEn: '5 Summon Tickets',
    ),
    AchievementMilestone(
      requiredPoints: 75,
      rewardType: 'shard',
      rewardAmount: 10,
      descKo: '소환석 10개',
      descEn: '10 Shards',
    ),
    AchievementMilestone(
      requiredPoints: 100,
      rewardType: 'diamond',
      rewardAmount: 200,
      descKo: '다이아 200',
      descEn: '200 Diamonds',
    ),
    AchievementMilestone(
      requiredPoints: 150,
      rewardType: 'gachaTicket',
      rewardAmount: 10,
      descKo: '소환권 10장',
      descEn: '10 Summon Tickets',
    ),
  ];

  static TitleDefinition? findById(String id) {
    for (final t in titles) {
      if (t.id == id) return t;
    }
    return null;
  }
}
