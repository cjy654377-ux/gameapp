// ignore_for_file: avoid_positional_boolean_parameters

/// Lightweight monster descriptor used exclusively for synergy evaluation.
/// Avoids importing the heavier Monster model from the data layer.
class MonsterInfo {
  const MonsterInfo({
    required this.templateId,
    required this.element,
    required this.size,
    required this.rarity,
  });

  /// Unique template identifier (e.g. 'fire_dragon', 'angel').
  final String templateId;

  /// Elemental affinity (e.g. 'fire', 'water', 'earth', 'wind', 'light', 'dark').
  final String element;

  /// Body size: 'small' | 'medium' | 'large' | 'extraLarge'
  final String size;

  /// 1 = common, 2 = uncommon, 3 = rare, 4 = epic, 5 = legendary
  final int rarity;
}

// ---------------------------------------------------------------------------
// Synergy type
// ---------------------------------------------------------------------------

enum SynergyType { element, size, rarity, special }

// ---------------------------------------------------------------------------
// SynergyEffect
// ---------------------------------------------------------------------------

/// A single synergy rule.  [condition] is evaluated against the current team
/// and returns `true` when this synergy is active.
class SynergyEffect {
  const SynergyEffect({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.statBonuses,
    required this.condition,
  });

  /// Unique identifier used as a map key (ASCII, no spaces).
  final String id;

  /// Display name shown in UI (Korean).
  final String name;

  /// Flavour description shown in UI (Korean).
  final String description;

  final SynergyType type;

  /// Fractional bonus values keyed by stat name.
  /// Keys: 'atk', 'def', 'hp', 'spd'
  /// Example: {'atk': 0.10} means +10 % ATK.
  final Map<String, double> statBonuses;

  /// Returns `true` when [team] satisfies this synergy.
  final bool Function(List<MonsterInfo> team) condition;
}

// ---------------------------------------------------------------------------
// Synergy catalogue
// ---------------------------------------------------------------------------

/// Central catalogue that defines every synergy in the game.
/// Prefer accessing synergies through [SynergyDefinitions.all] so the list
/// is computed only once.
class SynergyDefinitions {
  SynergyDefinitions._();

  // -------------------------------------------------------------------------
  // 1. Element synergies (속성 시너지)
  // -------------------------------------------------------------------------

  /// Returns true when any element appears at least [n] times in [team].
  static bool _anyElementAtLeast(List<MonsterInfo> team, int n) {
    final counts = <String, int>{};
    for (final m in team) {
      counts[m.element] = (counts[m.element] ?? 0) + 1;
    }
    return counts.values.any((c) => c >= n);
  }

  static final SynergyEffect elementResonance = SynergyEffect(
    id: 'element_resonance',
    name: '속성 공명',
    description: '같은 속성 몬스터 2마리: 공격력 +10%',
    type: SynergyType.element,
    statBonuses: const {'atk': 0.10},
    condition: (team) => _anyElementAtLeast(team, 2),
  );

  static final SynergyEffect elementDominance = SynergyEffect(
    id: 'element_dominance',
    name: '속성 지배',
    description: '같은 속성 몬스터 3마리: 공격력 +20%, 방어력 +10%',
    type: SynergyType.element,
    statBonuses: const {'atk': 0.20, 'def': 0.10},
    condition: (team) => _anyElementAtLeast(team, 3),
  );

  static final SynergyEffect elementTranscendence = SynergyEffect(
    id: 'element_transcendence',
    name: '속성 초월',
    description: '같은 속성 몬스터 4마리: 공격력 +30%, 방어력 +15%, HP +10%',
    type: SynergyType.element,
    statBonuses: const {'atk': 0.30, 'def': 0.15, 'hp': 0.10},
    condition: (team) => _anyElementAtLeast(team, 4),
  );

  // -------------------------------------------------------------------------
  // 2. Size synergies (크기 시너지)
  // -------------------------------------------------------------------------

  static const _sizes = ['small', 'medium', 'large', 'extraLarge'];

  static int _countSize(List<MonsterInfo> team, String size) =>
      team.where((m) => m.size == size).length;

  /// All four sizes appear at least once.
  static bool _allDifferentSizes(List<MonsterInfo> team) {
    final present = team.map((m) => m.size).toSet();
    return _sizes.every(present.contains);
  }

  static final SynergyEffect diverseForce = SynergyEffect(
    id: 'diverse_force',
    name: '다양한 전력',
    description: '모든 크기의 몬스터가 팀에 존재: 이속 +15%',
    type: SynergyType.size,
    statBonuses: const {'spd': 0.15},
    condition: _allDifferentSizes,
  );

  static final SynergyEffect agileUnit = SynergyEffect(
    id: 'agile_unit',
    name: '민첩한 부대',
    description: '소형 몬스터 2마리 이상: 이속 +20%',
    type: SynergyType.size,
    statBonuses: const {'spd': 0.20},
    condition: (team) => _countSize(team, 'small') >= 2,
  );

  static final SynergyEffect giantWall = SynergyEffect(
    id: 'giant_wall',
    name: '거대한 방벽',
    description: '대형/초대형 몬스터 2마리 이상: 방어력 +20%, HP +15%',
    type: SynergyType.size,
    statBonuses: const {'def': 0.20, 'hp': 0.15},
    condition: (team) =>
        _countSize(team, 'large') + _countSize(team, 'extraLarge') >= 2,
  );

  // -------------------------------------------------------------------------
  // 3. Rarity synergies (등급 시너지)
  // -------------------------------------------------------------------------

  /// Returns true when [team] contains at least [n] monsters of exactly
  /// [rarity].
  static bool _exactRarity(
    List<MonsterInfo> team,
    int rarity,
    int count,
  ) =>
      team.where((m) => m.rarity == rarity).length >= count;

  /// Returns true when every monster has rarity >= 3 (rare or above).
  static bool _allRarePlus(List<MonsterInfo> team) =>
      team.isNotEmpty && team.every((m) => m.rarity >= 3);

  /// Returns true when the team contains all four distinct rarity values
  /// (rare 3, epic 4, legendary 5, and at least one lower).
  static bool _rainbowRarity(List<MonsterInfo> team) {
    final rarities = team.map((m) => m.rarity).toSet();
    // Rainbow: all five rarities present (1 through 5).
    return rarities.length >= 5 ||
        // Or at least one monster of each of the four meaningful tiers.
        ({1, 2, 3, 4, 5}.difference(rarities).isEmpty);
  }

  static final SynergyEffect legendaryAura = SynergyEffect(
    id: 'legendary_aura',
    name: '전설의 기운',
    description: '전설 등급 몬스터 1마리 이상: 팀 전체 공격력 +5%',
    type: SynergyType.rarity,
    statBonuses: const {'atk': 0.05},
    condition: (team) => _exactRarity(team, 5, 1),
  );

  static final SynergyEffect heroicResolve = SynergyEffect(
    id: 'heroic_resolve',
    name: '영웅의 결의',
    description: '영웅 등급 몬스터 2마리 이상: 방어력 +10%',
    type: SynergyType.rarity,
    statBonuses: const {'def': 0.10},
    condition: (team) => _exactRarity(team, 4, 2),
  );

  static final SynergyEffect eliteSquad = SynergyEffect(
    id: 'elite_squad',
    name: '정예 부대',
    description: '전원 레어 이상: 모든 스탯 +8%',
    type: SynergyType.rarity,
    statBonuses: const {'atk': 0.08, 'def': 0.08, 'hp': 0.08, 'spd': 0.08},
    condition: _allRarePlus,
  );

  static final SynergyEffect rainbowFormation = SynergyEffect(
    id: 'rainbow_formation',
    name: '무지개 편성',
    description: '모든 등급이 팀에 존재: 모든 스탯 +12%',
    type: SynergyType.rarity,
    statBonuses: const {
      'atk': 0.12,
      'def': 0.12,
      'hp': 0.12,
      'spd': 0.12,
    },
    condition: _rainbowRarity,
  );

  // -------------------------------------------------------------------------
  // 4. Special combo synergies (특수 조합)
  // -------------------------------------------------------------------------

  /// Returns true when [team] contains all monster template IDs in [ids].
  static bool _hasAll(List<MonsterInfo> team, List<String> ids) {
    final teamIds = team.map((m) => m.templateId).toSet();
    return ids.every(teamIds.contains);
  }

  static final SynergyEffect dragonFlame = SynergyEffect(
    id: 'dragon_flame',
    name: '용의 불꽃',
    description: '화염드래곤 + 불꽃정령: 화염 공격력 +25%',
    type: SynergyType.special,
    statBonuses: const {'atk': 0.25},
    condition: (team) => _hasAll(team, ['fire_dragon', 'flame_spirit']),
  );

  static final SynergyEffect lightAndDark = SynergyEffect(
    id: 'light_and_dark',
    name: '빛과 어둠',
    description: '대천사 + 암흑기사: 모든 스탯 +15%',
    type: SynergyType.special,
    statBonuses: const {
      'atk': 0.15,
      'def': 0.15,
      'hp': 0.15,
      'spd': 0.15,
    },
    condition: (team) => _hasAll(team, ['archangel', 'dark_knight']),
  );

  static final SynergyEffect iceAndFire = SynergyEffect(
    id: 'ice_and_fire',
    name: '얼음과 불',
    description: '얼음여왕 + 피닉스: 공격력 +20%, 방어력 +20%',
    type: SynergyType.special,
    statBonuses: const {'atk': 0.20, 'def': 0.20},
    condition: (team) => _hasAll(team, ['ice_queen', 'phoenix']),
  );

  static final SynergyEffect natureGuardian = SynergyEffect(
    id: 'nature_guardian',
    name: '자연의 수호자',
    description: '스톤골렘 + 고블린: 방어력 +25%, HP +15%',
    type: SynergyType.special,
    statBonuses: const {'def': 0.25, 'hp': 0.15},
    condition: (team) => _hasAll(team, ['stone_golem', 'goblin']),
  );

  static final SynergyEffect moonlightHunter = SynergyEffect(
    id: 'moonlight_hunter',
    name: '달빛 사냥꾼',
    description: '은빛늑대 + 박쥐: 이속 +25%, 공격력 +10%',
    type: SynergyType.special,
    statBonuses: const {'spd': 0.25, 'atk': 0.10},
    condition: (team) => _hasAll(team, ['silver_wolf', 'bat']),
  );

  // -------------------------------------------------------------------------
  // Master list (ordered for UI display)
  // -------------------------------------------------------------------------

  /// All synergies in display order: element → size → rarity → special.
  static final List<SynergyEffect> all = [
    // Element
    elementResonance,
    elementDominance,
    elementTranscendence,
    // Size
    diverseForce,
    agileUnit,
    giantWall,
    // Rarity
    legendaryAura,
    heroicResolve,
    eliteSquad,
    rainbowFormation,
    // Special combo
    dragonFlame,
    lightAndDark,
    iceAndFire,
    natureGuardian,
    moonlightHunter,
  ];
}
