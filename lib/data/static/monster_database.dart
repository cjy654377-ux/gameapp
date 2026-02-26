/// Static monster template data.
///
/// [MonsterTemplate] holds immutable, design-time data that every monster of
/// the same species shares.  Individual [MonsterModel] instances reference a
/// template via [templateId] and store the per-instance mutable state (level,
/// experience, evolution stage, …).
class MonsterTemplate {
  final String id;
  final String name;

  /// 1 = 일반 (1-star), 2 = 고급 (2-star),
  /// 3 = 희귀 (3-star),   4 = 영웅 (4-star), 5 = 전설 (5-star)
  final int rarity;

  /// 'fire', 'water', 'electric', 'stone', 'grass', 'ghost', 'light', 'dark'
  final String element;

  /// 'small', 'medium', 'large', 'extraLarge'
  final String size;

  /// Description shown in the monster detail screen.
  final String description;

  // Base stats at level 1, evolution stage 0.
  final double baseAtk;
  final double baseDef;
  final double baseHp;
  final double baseSpd;

  /// Gacha weight (higher = more common).
  final int gachaWeight;

  const MonsterTemplate({
    required this.id,
    required this.name,
    required this.rarity,
    required this.element,
    required this.size,
    required this.description,
    required this.baseAtk,
    required this.baseDef,
    required this.baseHp,
    required this.baseSpd,
    required this.gachaWeight,
  });
}

// =============================================================================
// Monster Database
// =============================================================================

/// All available monster templates.
///
/// Stat guidelines (base, level 1, stage 0):
///   1성 일반 : ATK 25-42,  DEF 12-35,  HP 160-280,  SPD 8-16
///   2성 고급 : ATK 50-65,  DEF 30-75,  HP 320-520,  SPD 6-18
///   3성 희귀 : ATK 70-95,  DEF 45-95,  HP 480-700,  SPD 8-24
///   4성 영웅 : ATK 115-125,DEF 75-100, HP 720-850,  SPD 14-20
///   5성 전설 : ATK 160-170,DEF 130-140,HP 1100-1200,SPD 22-25
class MonsterDatabase {
  MonsterDatabase._();

  // ---------------------------------------------------------------------------
  // 1성 일반 monsters (6 total)
  // ---------------------------------------------------------------------------

  static const MonsterTemplate slime = MonsterTemplate(
    id:          'slime',
    name:        '슬라임',
    rarity:      1,
    element:     'water',
    size:        'small',
    description: '물로 이루어진 젤리 같은 몬스터. 초보 모험가들의 단골 사냥감이다.',
    baseAtk:     30.0,
    baseDef:     20.0,
    baseHp:      240.0,
    baseSpd:     12.0,
    gachaWeight: 500,
  );

  static const MonsterTemplate goblin = MonsterTemplate(
    id:          'goblin',
    name:        '고블린',
    rarity:      1,
    element:     'grass',
    size:        'small',
    description: '숲속에 서식하는 작은 녹색 생물. 무리를 지어 행동한다.',
    baseAtk:     38.0,
    baseDef:     22.0,
    baseHp:      210.0,
    baseSpd:     14.0,
    gachaWeight: 500,
  );

  static const MonsterTemplate sparkBug = MonsterTemplate(
    id:          'spark_bug',
    name:        '전기벌레',
    rarity:      1,
    element:     'electric',
    size:        'small',
    description: '몸에서 전기를 방전하는 작은 벌레. 접촉하면 찌릿한 충격을 준다.',
    baseAtk:     35.0,
    baseDef:     15.0,
    baseHp:      180.0,
    baseSpd:     16.0,
    gachaWeight: 500,
  );

  static const MonsterTemplate pebble = MonsterTemplate(
    id:          'pebble',
    name:        '자갈몬',
    rarity:      1,
    element:     'stone',
    size:        'small',
    description: '단단한 자갈로 뒤덮인 몬스터. 느리지만 높은 방어력을 자랑한다.',
    baseAtk:     25.0,
    baseDef:     35.0,
    baseHp:      280.0,
    baseSpd:     8.0,
    gachaWeight: 500,
  );

  static const MonsterTemplate wisp = MonsterTemplate(
    id:          'wisp',
    name:        '도깨비불',
    rarity:      1,
    element:     'ghost',
    size:        'small',
    description: '어둠 속을 떠도는 작은 유령 불꽃. 실체가 없어 물리 공격이 통하지 않는다.',
    baseAtk:     40.0,
    baseDef:     12.0,
    baseHp:      160.0,
    baseSpd:     15.0,
    gachaWeight: 500,
  );

  static const MonsterTemplate flameSpirit = MonsterTemplate(
    id:          'flame_spirit',
    name:        '불꽃정령',
    rarity:      1,
    element:     'fire',
    size:        'small',
    description: '작은 불꽃에서 태어난 정령. 분노하면 더욱 강해진다.',
    baseAtk:     42.0,
    baseDef:     18.0,
    baseHp:      200.0,
    baseSpd:     11.0,
    gachaWeight: 500,
  );

  // ---------------------------------------------------------------------------
  // 2성 고급 monsters (5 total)
  // ---------------------------------------------------------------------------

  static const MonsterTemplate bat = MonsterTemplate(
    id:          'bat',
    name:        '박쥐',
    rarity:      2,
    element:     'dark',
    size:        'small',
    description: '어둠 속에서 초음파로 먹잇감을 찾는 날쌘 몬스터.',
    baseAtk:     55.0,
    baseDef:     30.0,
    baseHp:      320.0,
    baseSpd:     18.0,
    gachaWeight: 200,
  );

  static const MonsterTemplate stoneGolem = MonsterTemplate(
    id:          'stone_golem',
    name:        '스톤골렘',
    rarity:      2,
    element:     'stone',
    size:        'large',
    description: '대지의 기운으로 만들어진 암석 거인. 느리지만 막강한 방어력을 자랑한다.',
    baseAtk:     50.0,
    baseDef:     75.0,
    baseHp:      520.0,
    baseSpd:     6.0,
    gachaWeight: 200,
  );

  static const MonsterTemplate thunderWolf = MonsterTemplate(
    id:          'thunder_wolf',
    name:        '번개늑대',
    rarity:      2,
    element:     'electric',
    size:        'medium',
    description: '번개처럼 빠르게 달리는 늑대. 몸에서 전기 오라를 발산하며 적을 마비시킨다.',
    baseAtk:     65.0,
    baseDef:     40.0,
    baseHp:      380.0,
    baseSpd:     17.0,
    gachaWeight: 200,
  );

  static const MonsterTemplate vineSnake = MonsterTemplate(
    id:          'vine_snake',
    name:        '덩굴뱀',
    rarity:      2,
    element:     'grass',
    size:        'medium',
    description: '덩굴로 몸을 감싼 거대한 뱀. 덩굴로 적을 옭아매어 움직임을 봉쇄한다.',
    baseAtk:     58.0,
    baseDef:     45.0,
    baseHp:      400.0,
    baseSpd:     13.0,
    gachaWeight: 200,
  );

  static const MonsterTemplate mermaid = MonsterTemplate(
    id:          'mermaid',
    name:        '인어',
    rarity:      2,
    element:     'water',
    size:        'medium',
    description: '깊은 바다에서 온 신비로운 존재. 아름다운 노래로 적을 혼란에 빠뜨린다.',
    baseAtk:     60.0,
    baseDef:     50.0,
    baseHp:      420.0,
    baseSpd:     14.0,
    gachaWeight: 200,
  );

  // ---------------------------------------------------------------------------
  // 3성 희귀 monsters (4 total)
  // ---------------------------------------------------------------------------

  static const MonsterTemplate silverWolf = MonsterTemplate(
    id:          'silver_wolf',
    name:        '은빛늑대',
    rarity:      3,
    element:     'light',
    size:        'medium',
    description: '달빛을 받아 빛나는 은빛 털을 가진 늑대. 예리한 발톱으로 적을 공격한다.',
    baseAtk:     85.0,
    baseDef:     55.0,
    baseHp:      550.0,
    baseSpd:     19.0,
    gachaWeight: 60,
  );

  static const MonsterTemplate shadowCat = MonsterTemplate(
    id:          'shadow_cat',
    name:        '그림자고양이',
    rarity:      3,
    element:     'dark',
    size:        'small',
    description: '어둠 속에 녹아드는 신비한 고양이. 그림자를 타고 이동하며 적의 뒤를 노린다.',
    baseAtk:     90.0,
    baseDef:     45.0,
    baseHp:      480.0,
    baseSpd:     22.0,
    gachaWeight: 60,
  );

  static const MonsterTemplate crystalTurtle = MonsterTemplate(
    id:          'crystal_turtle',
    name:        '수정거북',
    rarity:      3,
    element:     'stone',
    size:        'large',
    description: '수정 같은 단단한 등껍질을 가진 거북. 압도적인 방어력으로 모든 공격을 튕겨낸다.',
    baseAtk:     70.0,
    baseDef:     95.0,
    baseHp:      700.0,
    baseSpd:     8.0,
    gachaWeight: 60,
  );

  static const MonsterTemplate stormEagle = MonsterTemplate(
    id:          'storm_eagle',
    name:        '폭풍매',
    rarity:      3,
    element:     'electric',
    size:        'medium',
    description: '폭풍을 일으키며 날아다니는 전설의 매. 날개짓 한 번으로 번개를 떨어뜨린다.',
    baseAtk:     95.0,
    baseDef:     50.0,
    baseHp:      500.0,
    baseSpd:     24.0,
    gachaWeight: 60,
  );

  // ---------------------------------------------------------------------------
  // 4성 영웅 monsters (3 total)
  // ---------------------------------------------------------------------------

  static const MonsterTemplate phoenix = MonsterTemplate(
    id:          'phoenix',
    name:        '피닉스',
    rarity:      4,
    element:     'fire',
    size:        'large',
    description: '불사의 새. 죽을 때 불꽃 속에서 다시 태어나며, 압도적인 화염 공격을 날린다.',
    baseAtk:     120.0,
    baseDef:     80.0,
    baseHp:      780.0,
    baseSpd:     20.0,
    gachaWeight: 15,
  );

  static const MonsterTemplate iceQueen = MonsterTemplate(
    id:          'ice_queen',
    name:        '얼음여왕',
    rarity:      4,
    element:     'water',
    size:        'medium',
    description: '영원한 겨울을 다스리는 여왕. 냉기로 모든 것을 얼려 버리는 강력한 마법을 사용한다.',
    baseAtk:     125.0,
    baseDef:     75.0,
    baseHp:      720.0,
    baseSpd:     18.0,
    gachaWeight: 15,
  );

  static const MonsterTemplate darkKnight = MonsterTemplate(
    id:          'dark_knight',
    name:        '암흑기사',
    rarity:      4,
    element:     'dark',
    size:        'large',
    description: '어둠의 서약에 묶인 전사. 강인한 체력과 날카로운 검술로 전장을 지배한다.',
    baseAtk:     115.0,
    baseDef:     100.0,
    baseHp:      850.0,
    baseSpd:     14.0,
    gachaWeight: 15,
  );

  // ---------------------------------------------------------------------------
  // 5성 전설 monsters (2 total)
  // ---------------------------------------------------------------------------

  static const MonsterTemplate flameDragon = MonsterTemplate(
    id:          'flame_dragon',
    name:        '화염드래곤',
    rarity:      5,
    element:     'fire',
    size:        'extraLarge',
    description: '전설 속의 불의 군주. 한 번의 숨결로 도시를 잿더미로 만들 수 있다고 전해진다.',
    baseAtk:     170.0,
    baseDef:     130.0,
    baseHp:      1200.0,
    baseSpd:     22.0,
    gachaWeight: 3,
  );

  static const MonsterTemplate archangel = MonsterTemplate(
    id:          'archangel',
    name:        '대천사',
    rarity:      5,
    element:     'light',
    size:        'extraLarge',
    description: '신성한 빛으로 적을 심판하는 하늘의 전사. 그 존재만으로도 어둠을 몰아낸다.',
    baseAtk:     160.0,
    baseDef:     140.0,
    baseHp:      1100.0,
    baseSpd:     25.0,
    gachaWeight: 3,
  );

  // ---------------------------------------------------------------------------
  // Master list and lookup helpers
  // ---------------------------------------------------------------------------

  /// Every template in the database.
  static const List<MonsterTemplate> all = [
    // 1성 일반
    slime,
    goblin,
    sparkBug,
    pebble,
    wisp,
    flameSpirit,
    // 2성 고급
    bat,
    stoneGolem,
    thunderWolf,
    vineSnake,
    mermaid,
    // 3성 희귀
    silverWolf,
    shadowCat,
    crystalTurtle,
    stormEagle,
    // 4성 영웅
    phoenix,
    iceQueen,
    darkKnight,
    // 5성 전설
    flameDragon,
    archangel,
  ];

  /// Returns templates filtered by [rarity].
  static List<MonsterTemplate> byRarity(int rarity) =>
      all.where((t) => t.rarity == rarity).toList();

  /// Returns templates filtered by [element].
  static List<MonsterTemplate> byElement(String element) =>
      all.where((t) => t.element == element).toList();

  /// Returns templates filtered by [size].
  static List<MonsterTemplate> bySize(String size) =>
      all.where((t) => t.size == size).toList();

  /// Finds a template by [id], returning null if not found.
  static MonsterTemplate? findById(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Gacha helpers
  // ---------------------------------------------------------------------------

  /// Flat list of template IDs weighted by [MonsterTemplate.gachaWeight],
  /// suitable for random index selection.
  static final List<String> _weightedPool = [
    for (final template in all)
      for (int i = 0; i < template.gachaWeight; i++) template.id,
  ];

  /// Total gacha pool weight (sum of all [MonsterTemplate.gachaWeight] values).
  static int get totalGachaWeight =>
      all.fold(0, (sum, t) => sum + t.gachaWeight);

  /// Returns the weighted gacha pool as an unmodifiable view.
  static List<String> get weightedPool => List.unmodifiable(_weightedPool);

  /// Gacha probability breakdown for display in the UI.
  ///
  /// Returns a map of rarity → probability (0.0 – 1.0).
  static Map<int, double> get gachaProbabilities {
    final total = totalGachaWeight.toDouble();
    final Map<int, int> weightByRarity = {};
    for (final template in all) {
      weightByRarity.update(
        template.rarity,
        (w) => w + template.gachaWeight,
        ifAbsent: () => template.gachaWeight,
      );
    }
    return {
      for (final entry in weightByRarity.entries)
        entry.key: entry.value / total,
    };
  }
}
