// Title definitions unlockable through hidden achievements.

class TitleDefinition {
  final String id;
  final String nameKo;
  final String nameEn;
  final String descKo;
  final String descEn;
  final String unlockCondition; // description of unlock condition

  const TitleDefinition({
    required this.id,
    required this.nameKo,
    required this.nameEn,
    required this.descKo,
    required this.descEn,
    required this.unlockCondition,
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
    ),
    TitleDefinition(
      id: 'champion',
      nameKo: '챔피언',
      nameEn: 'Champion',
      descKo: '전투 500회 승리',
      descEn: 'Win 500 battles',
      unlockCondition: 'battle_500',
    ),
    TitleDefinition(
      id: 'legend',
      nameKo: '전설',
      nameEn: 'Legend',
      descKo: '전투 1000회 승리',
      descEn: 'Win 1000 battles',
      unlockCondition: 'battle_1000',
    ),

    // Collection
    TitleDefinition(
      id: 'collector',
      nameKo: '수집가',
      nameEn: 'Collector',
      descKo: '몬스터 10종 수집',
      descEn: 'Collect 10 monster types',
      unlockCondition: 'collect_10',
    ),
    TitleDefinition(
      id: 'professor',
      nameKo: '교수',
      nameEn: 'Professor',
      descKo: '몬스터 전종 수집',
      descEn: 'Collect all monster types',
      unlockCondition: 'collect_all',
    ),

    // Gacha
    TitleDefinition(
      id: 'lucky',
      nameKo: '행운아',
      nameEn: 'Lucky',
      descKo: '소환 50회 수행',
      descEn: 'Perform 50 summons',
      unlockCondition: 'gacha_50',
    ),
    TitleDefinition(
      id: 'whale',
      nameKo: '고래',
      nameEn: 'Whale',
      descKo: '소환 200회 수행',
      descEn: 'Perform 200 summons',
      unlockCondition: 'gacha_200',
    ),

    // Dungeon
    TitleDefinition(
      id: 'explorer',
      nameKo: '탐험가',
      nameEn: 'Explorer',
      descKo: '던전 20층 도달',
      descEn: 'Reach dungeon floor 20',
      unlockCondition: 'dungeon_20',
    ),
    TitleDefinition(
      id: 'deepdiver',
      nameKo: '심해탐사자',
      nameEn: 'Deep Diver',
      descKo: '던전 50층 도달',
      descEn: 'Reach dungeon floor 50',
      unlockCondition: 'dungeon_50',
    ),

    // Prestige
    TitleDefinition(
      id: 'reborn',
      nameKo: '전생자',
      nameEn: 'Reborn',
      descKo: '첫 전생 달성',
      descEn: 'Complete first prestige',
      unlockCondition: 'prestige_1',
    ),
    TitleDefinition(
      id: 'immortal',
      nameKo: '불멸자',
      nameEn: 'Immortal',
      descKo: '전생 5회 달성',
      descEn: 'Complete 5 prestiges',
      unlockCondition: 'prestige_5',
    ),

    // Special
    TitleDefinition(
      id: 'dedicated',
      nameKo: '헌신자',
      nameEn: 'Dedicated',
      descKo: '7일 연속 출석',
      descEn: 'Check in 7 days in a row',
      unlockCondition: 'checkin_7',
    ),
  ];

  static TitleDefinition? findById(String id) {
    for (final t in titles) {
      if (t.id == id) return t;
    }
    return null;
  }
}
