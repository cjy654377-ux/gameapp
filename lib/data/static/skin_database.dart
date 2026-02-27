import 'package:flutter/material.dart';

/// Immutable definition of a monster skin/costume.
class SkinDefinition {
  final String id;
  final String name;
  final String nameEn;
  final String description;
  final String descriptionEn;

  /// Override emoji displayed for the monster (nullable = keep original).
  final String? overrideEmoji;

  /// Override color for the monster visual (nullable = keep original).
  final Color? overrideColor;

  /// If set, only monsters of this element can equip this skin.
  final String? targetElement;

  /// If set, only monsters with this templateId can equip this skin.
  final String? targetTemplateId;

  /// Cost in monster shards to unlock.
  final int shardCost;

  /// 1 = common, 2 = uncommon, 3 = rare, 4 = epic, 5 = legendary
  final int rarity;

  const SkinDefinition({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.description,
    required this.descriptionEn,
    this.overrideEmoji,
    this.overrideColor,
    this.targetElement,
    this.targetTemplateId,
    this.shardCost = 10,
    this.rarity = 1,
  });
}

// =============================================================================
// Skin Database
// =============================================================================

class SkinDatabase {
  SkinDatabase._();

  // ---------------------------------------------------------------------------
  // Universal skins (any monster)
  // ---------------------------------------------------------------------------

  static const SkinDefinition crystalArmor = SkinDefinition(
    id: 'crystal_armor',
    name: '크리스탈 갑옷',
    nameEn: 'Crystal Armor',
    description: '수정으로 만든 빛나는 갑옷. 어떤 몬스터든 찬란하게 빛난다.',
    descriptionEn: 'Shining crystal armor. Makes any monster dazzle.',
    overrideEmoji: '💎',
    overrideColor: Color(0xFF00BCD4),
    shardCost: 15,
    rarity: 2,
  );

  static const SkinDefinition shadowCloak = SkinDefinition(
    id: 'shadow_cloak',
    name: '그림자 망토',
    nameEn: 'Shadow Cloak',
    description: '어둠의 기운이 감도는 신비한 망토.',
    descriptionEn: 'A mysterious cloak shrouded in darkness.',
    overrideEmoji: '🌑',
    overrideColor: Color(0xFF37474F),
    shardCost: 15,
    rarity: 2,
  );

  static const SkinDefinition goldenCrown = SkinDefinition(
    id: 'golden_crown',
    name: '황금 왕관',
    nameEn: 'Golden Crown',
    description: '왕족만이 착용할 수 있는 황금 왕관. 위엄이 넘친다.',
    descriptionEn: 'A golden crown fit for royalty. Radiates majesty.',
    overrideEmoji: '👑',
    overrideColor: Color(0xFFFFD700),
    shardCost: 30,
    rarity: 3,
  );

  static const SkinDefinition stardustAura = SkinDefinition(
    id: 'stardust_aura',
    name: '별빛 오라',
    nameEn: 'Stardust Aura',
    description: '별빛 가루가 온몸을 감싸는 신비로운 오라.',
    descriptionEn: 'A mystical aura of glittering stardust.',
    overrideEmoji: '🌟',
    overrideColor: Color(0xFFE1BEE7),
    shardCost: 25,
    rarity: 3,
  );

  static const SkinDefinition rainbowPrism = SkinDefinition(
    id: 'rainbow_prism',
    name: '무지개 프리즘',
    nameEn: 'Rainbow Prism',
    description: '일곱 빛깔로 빛나는 전설의 프리즘 장식.',
    descriptionEn: 'A legendary prism that shines in seven colors.',
    overrideEmoji: '🌈',
    overrideColor: Color(0xFFFF7043),
    shardCost: 50,
    rarity: 4,
  );

  static const SkinDefinition cosmicVoid = SkinDefinition(
    id: 'cosmic_void',
    name: '우주의 공허',
    nameEn: 'Cosmic Void',
    description: '우주의 심연을 담은 전설의 장식. 보는 이를 압도한다.',
    descriptionEn: 'Legendary adornment containing the cosmic abyss.',
    overrideEmoji: '🌌',
    overrideColor: Color(0xFF1A237E),
    shardCost: 80,
    rarity: 5,
  );

  // ---------------------------------------------------------------------------
  // Element-specific skins
  // ---------------------------------------------------------------------------

  static const SkinDefinition infernalFlame = SkinDefinition(
    id: 'infernal_flame',
    name: '지옥불 형상',
    nameEn: 'Infernal Flame',
    description: '지옥의 불꽃으로 타오르는 형상.',
    descriptionEn: 'A form blazing with hellfire.',
    overrideEmoji: '🔥',
    overrideColor: Color(0xFFD50000),
    targetElement: 'fire',
    shardCost: 20,
    rarity: 3,
  );

  static const SkinDefinition abyssalTide = SkinDefinition(
    id: 'abyssal_tide',
    name: '심해의 파도',
    nameEn: 'Abyssal Tide',
    description: '심해의 파도를 머금은 물의 형상.',
    descriptionEn: 'A watery form imbued with deep-sea tides.',
    overrideEmoji: '🌊',
    overrideColor: Color(0xFF0D47A1),
    targetElement: 'water',
    shardCost: 20,
    rarity: 3,
  );

  static const SkinDefinition thunderStrike = SkinDefinition(
    id: 'thunder_strike',
    name: '낙뢰 형상',
    nameEn: 'Thunder Strike',
    description: '번개가 온몸을 감싸는 전격 형상.',
    descriptionEn: 'An electric form wreathed in lightning.',
    overrideEmoji: '⛈️',
    overrideColor: Color(0xFFFFC107),
    targetElement: 'electric',
    shardCost: 20,
    rarity: 3,
  );

  static const SkinDefinition ancientMoss = SkinDefinition(
    id: 'ancient_moss',
    name: '고대 이끼',
    nameEn: 'Ancient Moss',
    description: '수백 년 된 고대 이끼로 뒤덮인 형상.',
    descriptionEn: 'Covered in centuries-old ancient moss.',
    overrideEmoji: '🌲',
    overrideColor: Color(0xFF2E7D32),
    targetElement: 'grass',
    shardCost: 20,
    rarity: 3,
  );

  static const SkinDefinition spectralPhantom = SkinDefinition(
    id: 'spectral_phantom',
    name: '유령 환영',
    nameEn: 'Spectral Phantom',
    description: '반투명한 유령의 형상으로 변하는 스킨.',
    descriptionEn: 'A skin that turns into a translucent phantom.',
    overrideEmoji: '👻',
    overrideColor: Color(0xFF9575CD),
    targetElement: 'ghost',
    shardCost: 20,
    rarity: 3,
  );

  // ---------------------------------------------------------------------------
  // Template-specific skins (legendary)
  // ---------------------------------------------------------------------------

  static const SkinDefinition dragonEmperor = SkinDefinition(
    id: 'dragon_emperor',
    name: '용제의 위엄',
    nameEn: 'Dragon Emperor',
    description: '화염드래곤 전용. 고대 용제의 황금 비늘.',
    descriptionEn: 'Flame Dragon exclusive. Golden scales of the ancient Dragon Emperor.',
    overrideEmoji: '🐉',
    overrideColor: Color(0xFFFF8F00),
    targetTemplateId: 'flame_dragon',
    shardCost: 60,
    rarity: 5,
  );

  static const SkinDefinition divineWings = SkinDefinition(
    id: 'divine_wings',
    name: '신성한 날개',
    nameEn: 'Divine Wings',
    description: '대천사 전용. 순백의 빛나는 날개.',
    descriptionEn: 'Archangel exclusive. Radiant white wings.',
    overrideEmoji: '👼',
    overrideColor: Color(0xFFFFF9C4),
    targetTemplateId: 'archangel',
    shardCost: 60,
    rarity: 5,
  );

  static const SkinDefinition phoenixNirvana = SkinDefinition(
    id: 'phoenix_nirvana',
    name: '열반의 불사조',
    nameEn: 'Phoenix Nirvana',
    description: '피닉스 전용. 열반에 도달한 불사조의 형상.',
    descriptionEn: 'Phoenix exclusive. The form of a phoenix that achieved nirvana.',
    overrideEmoji: '🦅',
    overrideColor: Color(0xFFFF6F00),
    targetTemplateId: 'phoenix',
    shardCost: 40,
    rarity: 4,
  );

  // ---------------------------------------------------------------------------
  // Master list and lookup
  // ---------------------------------------------------------------------------

  static const List<SkinDefinition> all = [
    // Universal
    crystalArmor,
    shadowCloak,
    goldenCrown,
    stardustAura,
    rainbowPrism,
    cosmicVoid,
    // Element-specific
    infernalFlame,
    abyssalTide,
    thunderStrike,
    ancientMoss,
    spectralPhantom,
    // Template-specific
    dragonEmperor,
    divineWings,
    phoenixNirvana,
  ];

  /// Find skin by ID.
  static SkinDefinition? findById(String id) {
    for (final skin in all) {
      if (skin.id == id) return skin;
    }
    return null;
  }

  /// Returns skins applicable to the given monster.
  static List<SkinDefinition> applicableTo({
    required String element,
    required String templateId,
  }) {
    return all.where((skin) {
      // Template-specific: must match
      if (skin.targetTemplateId != null) {
        return skin.targetTemplateId == templateId;
      }
      // Element-specific: must match
      if (skin.targetElement != null) {
        return skin.targetElement == element;
      }
      // Universal: always applicable
      return true;
    }).toList();
  }
}
