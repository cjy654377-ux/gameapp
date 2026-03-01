// Relic template database — static definitions for all relic types.

class RelicTemplate {
  final String id;
  final String name;
  final String type; // 'weapon', 'armor', 'accessory'
  final int rarity;
  final String statType; // 'atk', 'def', 'hp', 'spd'
  final double statValue;

  const RelicTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.rarity,
    required this.statType,
    required this.statValue,
  });
}

class RelicDatabase {
  RelicDatabase._();

  static const List<RelicTemplate> all = [
    // -- Weapons (ATK bonus) --
    RelicTemplate(
      id: 'wooden_sword', name: '나무 검', type: 'weapon',
      rarity: 1, statType: 'atk', statValue: 5,
    ),
    RelicTemplate(
      id: 'iron_sword', name: '철의 검', type: 'weapon',
      rarity: 2, statType: 'atk', statValue: 12,
    ),
    RelicTemplate(
      id: 'flame_blade', name: '화염 검', type: 'weapon',
      rarity: 3, statType: 'atk', statValue: 25,
    ),
    RelicTemplate(
      id: 'dragon_fang', name: '용의 이빨', type: 'weapon',
      rarity: 4, statType: 'atk', statValue: 45,
    ),
    RelicTemplate(
      id: 'excalibur', name: '성검 엑스칼리버', type: 'weapon',
      rarity: 5, statType: 'atk', statValue: 80,
    ),

    // -- Armor (DEF bonus) --
    RelicTemplate(
      id: 'leather_armor', name: '가죽 갑옷', type: 'armor',
      rarity: 1, statType: 'def', statValue: 5,
    ),
    RelicTemplate(
      id: 'chain_mail', name: '사슬 갑옷', type: 'armor',
      rarity: 2, statType: 'def', statValue: 12,
    ),
    RelicTemplate(
      id: 'mithril_plate', name: '미스릴 판금갑', type: 'armor',
      rarity: 3, statType: 'def', statValue: 25,
    ),
    RelicTemplate(
      id: 'dragon_scale', name: '용린 갑옷', type: 'armor',
      rarity: 4, statType: 'def', statValue: 45,
    ),
    RelicTemplate(
      id: 'divine_aegis', name: '신성한 이지스', type: 'armor',
      rarity: 5, statType: 'def', statValue: 80,
    ),

    // -- Accessories (HP/SPD bonus) --
    RelicTemplate(
      id: 'health_ring', name: '생명의 반지', type: 'accessory',
      rarity: 1, statType: 'hp', statValue: 30,
    ),
    RelicTemplate(
      id: 'swift_boots', name: '신속의 장화', type: 'accessory',
      rarity: 2, statType: 'spd', statValue: 8,
    ),
    RelicTemplate(
      id: 'emerald_amulet', name: '에메랄드 부적', type: 'accessory',
      rarity: 3, statType: 'hp', statValue: 80,
    ),
    RelicTemplate(
      id: 'wind_cloak', name: '바람의 망토', type: 'accessory',
      rarity: 4, statType: 'spd', statValue: 20,
    ),
    RelicTemplate(
      id: 'crown_of_kings', name: '왕의 왕관', type: 'accessory',
      rarity: 5, statType: 'hp', statValue: 200,
    ),
  ];

  static final Map<String, RelicTemplate> _byId = {
    for (final r in all) r.id: r,
  };

  static RelicTemplate? findById(String id) => _byId[id];

  static List<RelicTemplate> byRarity(int rarity) =>
      all.where((r) => r.rarity == rarity).toList();

  static List<RelicTemplate> byType(String type) =>
      all.where((r) => r.type == type).toList();
}

// =============================================================================
// Relic Set Bonuses
// =============================================================================

class RelicSetBonus {
  final String id;
  final String name;
  final int requiredPieces;
  final String requiredType; // 'weapon', 'armor', 'accessory', or 'mixed'
  final int requiredMinRarity;
  final List<({String statType, double statValue})> bonuses;

  const RelicSetBonus({
    required this.id,
    required this.name,
    required this.requiredPieces,
    required this.requiredType,
    required this.requiredMinRarity,
    required this.bonuses,
  });
}

class RelicSetDatabase {
  RelicSetDatabase._();

  static const List<RelicSetBonus> all = [
    // Warrior set: 2 weapons of 2★+
    RelicSetBonus(
      id: 'set_warrior',
      name: '전사의 의지',
      requiredPieces: 2,
      requiredType: 'weapon',
      requiredMinRarity: 2,
      bonuses: [(statType: 'atk', statValue: 15.0)],
    ),
    // Guardian set: 2 armors of 2★+
    RelicSetBonus(
      id: 'set_guardian',
      name: '수호자의 맹세',
      requiredPieces: 2,
      requiredType: 'armor',
      requiredMinRarity: 2,
      bonuses: [(statType: 'def', statValue: 15.0)],
    ),
    // Destroyer set: 1 weapon + 1 accessory of 3★+
    RelicSetBonus(
      id: 'set_destroyer',
      name: '파괴자의 힘',
      requiredPieces: 2,
      requiredType: 'mixed', // weapon + accessory
      requiredMinRarity: 3,
      bonuses: [(statType: 'atk', statValue: 10.0), (statType: 'spd', statValue: 5.0)],
    ),
  ];
}
