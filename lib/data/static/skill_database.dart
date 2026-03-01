// Static skill definitions for the monster skill system.
//
// Each monster template maps to exactly one [SkillDefinition]. Skills activate
// automatically when their cooldown reaches 0, replacing the monster's normal
// attack for that turn.

// =============================================================================
// PassiveTrigger
// =============================================================================

/// When the passive effect activates.
enum PassiveTrigger {
  /// At the start of the monster's turn.
  onTurnStart,

  /// When the monster deals damage.
  onAttack,

  /// When the monster takes damage.
  onDamaged,

  /// Applied once at battle start (permanent stat buff).
  battleStart,
}

// =============================================================================
// PassiveDefinition
// =============================================================================

/// A passive ability that triggers automatically.
class PassiveDefinition {
  final String id;
  final String name;
  final String description;
  final PassiveTrigger trigger;

  /// ATK boost multiplier (e.g. 0.1 = +10% ATK).
  final double atkBoost;

  /// DEF boost multiplier.
  final double defBoost;

  /// HP regen as fraction of maxHp per trigger.
  final double hpRegenPercent;

  /// Chance to counter-attack when damaged (0.0-1.0).
  final double counterChance;

  /// Counter damage multiplier (of ATK).
  final double counterMultiplier;

  /// Critical hit rate boost (added to base 5%).
  final double critBoost;

  const PassiveDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.trigger,
    this.atkBoost = 0.0,
    this.defBoost = 0.0,
    this.hpRegenPercent = 0.0,
    this.counterChance = 0.0,
    this.counterMultiplier = 0.0,
    this.critBoost = 0.0,
  });
}

// =============================================================================
// UltimateDefinition
// =============================================================================

/// A powerful skill that charges through combat and fires when full.
class UltimateDefinition {
  final String id;
  final String name;
  final String description;

  /// Charge needed to activate (typically 100).
  final int maxCharge;

  /// Charge gained per point of damage dealt (charge += damage * chargeRate).
  final double chargeRate;

  /// Damage multiplier (0 = no damage).
  final double damageMultiplier;
  final SkillTargetType damageTarget;

  /// Heal as fraction of caster maxHp (0 = no heal).
  final double healPercent;
  final bool isTeamHeal;

  /// Stun chance on targets.
  final double stunChance;

  const UltimateDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.maxCharge = 100,
    this.chargeRate = 0.01,
    this.damageMultiplier = 0.0,
    this.damageTarget = SkillTargetType.allEnemies,
    this.healPercent = 0.0,
    this.isTeamHeal = false,
    this.stunChance = 0.0,
  });
}

// =============================================================================
// SkillTargetType
// =============================================================================

/// Who the skill targets.
enum SkillTargetType {
  /// Single random enemy.
  singleEnemy,

  /// All enemies.
  allEnemies,

  /// Self only.
  self,

  /// All allies (including self).
  allAllies,
}

// =============================================================================
// SkillDefinition
// =============================================================================

/// Immutable definition of a monster's active skill.
class SkillDefinition {
  /// Unique skill identifier (matches the monster templateId for simplicity).
  final String id;

  /// Korean display name (e.g. '화염탄').
  final String name;

  /// Korean description shown in UI tooltips.
  final String description;

  /// Number of turns between activations. After firing, cooldown resets to this
  /// value. The first activation happens after [cooldown] turns.
  final int cooldown;

  // -- Damage ----------------------------------------------------------------

  /// Damage multiplier applied to the caster's ATK. 0 = no direct damage.
  final double damageMultiplier;

  /// Target for the damage component.
  final SkillTargetType damageTarget;

  // -- Shield ----------------------------------------------------------------

  /// Shield granted as a fraction of the caster's maxHp. 0 = no shield.
  final double shieldPercent;

  /// Whether the shield is applied to all allies (true) or self only (false).
  final bool isTeamShield;

  // -- Heal ------------------------------------------------------------------

  /// Heal amount as a fraction of the caster's maxHp. 0 = no heal.
  final double healPercent;

  /// Whether the heal applies to all allies (true) or self only (false).
  final bool isTeamHeal;

  // -- Drain (damage → self-heal) --------------------------------------------

  /// Fraction of damage dealt that heals the caster. 0 = no drain.
  final double drainPercent;

  // -- Status effects --------------------------------------------------------

  /// Burn duration in turns. 0 = no burn.
  final int burnTurns;

  /// Burn damage per tick as a fraction of the target's maxHp.
  final double burnDamagePercent;

  /// Probability (0.0–1.0) of stunning the target for 1 turn.
  final double stunChance;

  /// Freeze duration in turns. 0 = no freeze.
  final int freezeTurns;

  /// Poison duration in turns. 0 = no poison.
  final int poisonTurns;

  /// Poison damage per tick as fraction of target's maxHp.
  final double poisonDamagePercent;

  const SkillDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.cooldown,
    this.damageMultiplier = 0.0,
    this.damageTarget = SkillTargetType.singleEnemy,
    this.shieldPercent = 0.0,
    this.isTeamShield = false,
    this.healPercent = 0.0,
    this.isTeamHeal = false,
    this.drainPercent = 0.0,
    this.burnTurns = 0,
    this.burnDamagePercent = 0.0,
    this.stunChance = 0.0,
    this.freezeTurns = 0,
    this.poisonTurns = 0,
    this.poisonDamagePercent = 0.0,
  });
}

// =============================================================================
// SkillDatabase
// =============================================================================

/// Maps monster templateId → [SkillDefinition].
class SkillDatabase {
  SkillDatabase._();

  // ---------------------------------------------------------------------------
  // 1★ 일반 monsters (6)
  // ---------------------------------------------------------------------------

  static const SkillDefinition slime = SkillDefinition(
    id: 'slime',
    name: '물방울 방패',
    description: '물방울로 자신을 감싸 보호막을 생성한다.',
    cooldown: 4,
    shieldPercent: 0.20,
  );

  static const SkillDefinition goblin = SkillDefinition(
    id: 'goblin',
    name: '독침',
    description: '독이 묻은 침을 던져 적에게 피해를 주고 화상을 입힌다.',
    cooldown: 4,
    damageMultiplier: 1.2,
    burnTurns: 2,
    burnDamagePercent: 0.03,
  );

  static const SkillDefinition sparkBug = SkillDefinition(
    id: 'spark_bug',
    name: '방전',
    description: '강한 전기를 방출하여 적에게 피해를 주고 기절시킨다.',
    cooldown: 4,
    damageMultiplier: 1.3,
    stunChance: 0.5,
  );

  static const SkillDefinition pebble = SkillDefinition(
    id: 'pebble',
    name: '돌벽',
    description: '단단한 돌벽을 세워 자신에게 큰 보호막을 부여한다.',
    cooldown: 4,
    shieldPercent: 0.30,
  );

  static const SkillDefinition wisp = SkillDefinition(
    id: 'wisp',
    name: '영혼 흡수',
    description: '적의 생명력을 흡수하여 자신의 체력을 회복한다.',
    cooldown: 4,
    damageMultiplier: 1.2,
    drainPercent: 0.50,
  );

  static const SkillDefinition flameSpirit = SkillDefinition(
    id: 'flame_spirit',
    name: '화염탄',
    description: '응축된 불꽃을 날려 적에게 큰 피해를 준다.',
    cooldown: 4,
    damageMultiplier: 1.8,
  );

  // ---------------------------------------------------------------------------
  // 2★ 고급 monsters (5)
  // ---------------------------------------------------------------------------

  static const SkillDefinition bat = SkillDefinition(
    id: 'bat',
    name: '암흑 물기',
    description: '어둠의 힘을 담은 물기로 적에게 피해를 주고 화상을 입힌다.',
    cooldown: 3,
    damageMultiplier: 1.5,
    burnTurns: 2,
    burnDamagePercent: 0.04,
  );

  static const SkillDefinition stoneGolem = SkillDefinition(
    id: 'stone_golem',
    name: '대지의 방패',
    description: '대지의 기운으로 거대한 방패를 생성한다.',
    cooldown: 3,
    shieldPercent: 0.35,
  );

  static const SkillDefinition thunderWolf = SkillDefinition(
    id: 'thunder_wolf',
    name: '번개 돌진',
    description: '번개를 두르고 돌진하여 적에게 큰 피해와 기절을 준다.',
    cooldown: 3,
    damageMultiplier: 1.6,
    stunChance: 0.6,
  );

  static const SkillDefinition vineSnake = SkillDefinition(
    id: 'vine_snake',
    name: '덩굴 조임',
    description: '덩굴로 적을 옭아매어 피해를 주고 기절시킨다.',
    cooldown: 3,
    damageMultiplier: 1.4,
    stunChance: 0.55,
  );

  static const SkillDefinition mermaid = SkillDefinition(
    id: 'mermaid',
    name: '치유의 노래',
    description: '아름다운 노래로 아군 전체의 체력을 회복한다.',
    cooldown: 4,
    healPercent: 0.18,
    isTeamHeal: true,
  );

  // ---------------------------------------------------------------------------
  // 3★ 희귀 monsters (4)
  // ---------------------------------------------------------------------------

  static const SkillDefinition silverWolf = SkillDefinition(
    id: 'silver_wolf',
    name: '성스러운 발톱',
    description: '빛나는 발톱으로 적을 공격하고 자신의 체력을 회복한다.',
    cooldown: 3,
    damageMultiplier: 1.8,
    drainPercent: 0.40,
  );

  static const SkillDefinition shadowCat = SkillDefinition(
    id: 'shadow_cat',
    name: '그림자 습격',
    description: '그림자에서 나타나 적에게 치명적인 일격을 가하고 독을 주입한다.',
    cooldown: 3,
    damageMultiplier: 2.5,
    poisonTurns: 3,
    poisonDamagePercent: 0.05,
  );

  static const SkillDefinition crystalTurtle = SkillDefinition(
    id: 'crystal_turtle',
    name: '수정 방벽',
    description: '수정으로 이루어진 방벽을 생성하여 아군 전체를 보호한다.',
    cooldown: 4,
    shieldPercent: 0.20,
    isTeamShield: true,
  );

  static const SkillDefinition stormEagle = SkillDefinition(
    id: 'storm_eagle',
    name: '번개 폭풍',
    description: '날개짓으로 번개 폭풍을 일으켜 모든 적에게 피해를 준다.',
    cooldown: 3,
    damageMultiplier: 1.4,
    damageTarget: SkillTargetType.allEnemies,
  );

  // ---------------------------------------------------------------------------
  // 4★ 영웅 monsters (3)
  // ---------------------------------------------------------------------------

  static const SkillDefinition phoenix = SkillDefinition(
    id: 'phoenix',
    name: '불사의 불꽃',
    description: '불사의 불꽃으로 적에게 큰 피해와 화상을 주고 자신을 회복한다.',
    cooldown: 3,
    damageMultiplier: 2.0,
    burnTurns: 3,
    burnDamagePercent: 0.05,
    healPercent: 0.15,
  );

  static const SkillDefinition iceQueen = SkillDefinition(
    id: 'ice_queen',
    name: '절대영도',
    description: '모든 적을 냉기로 얼려 피해를 주고 빙결시킨다.',
    cooldown: 4,
    damageMultiplier: 1.3,
    damageTarget: SkillTargetType.allEnemies,
    freezeTurns: 2,
  );

  static const SkillDefinition darkKnight = SkillDefinition(
    id: 'dark_knight',
    name: '암흑참격',
    description: '어둠의 검기를 날려 적에게 초강력 피해를 준다.',
    cooldown: 3,
    damageMultiplier: 2.5,
  );

  // ---------------------------------------------------------------------------
  // 5★ 전설 monsters (2)
  // ---------------------------------------------------------------------------

  static const SkillDefinition flameDragon = SkillDefinition(
    id: 'flame_dragon',
    name: '드래곤 브레스',
    description: '용의 숨결로 모든 적을 불태워 큰 피해와 화상을 입힌다.',
    cooldown: 3,
    damageMultiplier: 1.8,
    damageTarget: SkillTargetType.allEnemies,
    burnTurns: 3,
    burnDamagePercent: 0.05,
  );

  static const SkillDefinition archangel = SkillDefinition(
    id: 'archangel',
    name: '심판의 빛',
    description: '성스러운 빛으로 적 전체에 피해를 주고 아군 전체를 회복한다.',
    cooldown: 4,
    damageMultiplier: 1.6,
    damageTarget: SkillTargetType.allEnemies,
    healPercent: 0.15,
    isTeamHeal: true,
  );

  // ---------------------------------------------------------------------------
  // Area 6 심연 monsters
  // ---------------------------------------------------------------------------

  static const SkillDefinition abyssSlug = SkillDefinition(
    id: 'abyss_slug',
    name: '심연의 점액',
    description: '심연의 독으로 적을 감싸 피해와 화상을 준다.',
    cooldown: 3,
    damageMultiplier: 1.6,
    burnTurns: 2,
    burnDamagePercent: 0.04,
  );

  static const SkillDefinition crystalBat = SkillDefinition(
    id: 'crystal_bat',
    name: '수정 초음파',
    description: '수정의 힘을 담은 초음파로 적에게 피해를 주고 기절시킨다.',
    cooldown: 3,
    damageMultiplier: 1.7,
    stunChance: 0.5,
  );

  static const SkillDefinition shadowSerpent = SkillDefinition(
    id: 'shadow_serpent',
    name: '독아 일격',
    description: '독이 묻은 송곳니로 적에게 큰 피해와 독을 준다.',
    cooldown: 3,
    damageMultiplier: 2.2,
    poisonTurns: 3,
    poisonDamagePercent: 0.05,
  );

  static const SkillDefinition abyssTitan = SkillDefinition(
    id: 'abyss_titan',
    name: '심연의 포효',
    description: '심연의 힘으로 모든 적을 압도한다.',
    cooldown: 4,
    damageMultiplier: 1.5,
    damageTarget: SkillTargetType.allEnemies,
    stunChance: 0.35,
  );

  // ---------------------------------------------------------------------------
  // Lookup
  // ---------------------------------------------------------------------------

  /// All skill definitions indexed by template ID.
  static const Map<String, SkillDefinition> _byTemplateId = {
    'slime': slime,
    'goblin': goblin,
    'spark_bug': sparkBug,
    'pebble': pebble,
    'wisp': wisp,
    'flame_spirit': flameSpirit,
    'bat': bat,
    'stone_golem': stoneGolem,
    'thunder_wolf': thunderWolf,
    'vine_snake': vineSnake,
    'mermaid': mermaid,
    'silver_wolf': silverWolf,
    'shadow_cat': shadowCat,
    'crystal_turtle': crystalTurtle,
    'storm_eagle': stormEagle,
    'phoenix': phoenix,
    'ice_queen': iceQueen,
    'dark_knight': darkKnight,
    'flame_dragon': flameDragon,
    'archangel': archangel,
    'abyss_slug': abyssSlug,
    'crystal_bat': crystalBat,
    'shadow_serpent': shadowSerpent,
    'abyss_titan': abyssTitan,
  };

  /// Returns the [SkillDefinition] for a given monster template ID,
  /// or `null` if the monster has no skill.
  static SkillDefinition? findByTemplateId(String templateId) =>
      _byTemplateId[templateId];

  // ---------------------------------------------------------------------------
  // Passive skills
  // ---------------------------------------------------------------------------

  static const Map<String, PassiveDefinition> _passives = {
    // 1★ passives
    'slime': PassiveDefinition(
      id: 'slime_p', name: '점액 재생', description: '매 턴 HP 2% 회복',
      trigger: PassiveTrigger.onTurnStart, hpRegenPercent: 0.02,
    ),
    'goblin': PassiveDefinition(
      id: 'goblin_p', name: '교활함', description: '공격 시 크리 확률 +10%',
      trigger: PassiveTrigger.onAttack, critBoost: 0.10,
    ),
    'spark_bug': PassiveDefinition(
      id: 'spark_bug_p', name: '정전기', description: '피격 시 15% 확률로 반격',
      trigger: PassiveTrigger.onDamaged, counterChance: 0.15, counterMultiplier: 0.5,
    ),
    'pebble': PassiveDefinition(
      id: 'pebble_p', name: '단단한 표피', description: '방어력 +8%',
      trigger: PassiveTrigger.battleStart, defBoost: 0.08,
    ),
    'wisp': PassiveDefinition(
      id: 'wisp_p', name: '흡수체질', description: '매 턴 HP 3% 회복',
      trigger: PassiveTrigger.onTurnStart, hpRegenPercent: 0.03,
    ),
    'flame_spirit': PassiveDefinition(
      id: 'flame_spirit_p', name: '불꽃의 기운', description: '공격력 +8%',
      trigger: PassiveTrigger.battleStart, atkBoost: 0.08,
    ),
    // 2★ passives
    'bat': PassiveDefinition(
      id: 'bat_p', name: '흡혈 본능', description: '공격 시 크리 확률 +12%',
      trigger: PassiveTrigger.onAttack, critBoost: 0.12,
    ),
    'stone_golem': PassiveDefinition(
      id: 'stone_golem_p', name: '바위 갑옷', description: '방어력 +12%',
      trigger: PassiveTrigger.battleStart, defBoost: 0.12,
    ),
    'thunder_wolf': PassiveDefinition(
      id: 'thunder_wolf_p', name: '야생의 직감', description: '공격력 +10%',
      trigger: PassiveTrigger.battleStart, atkBoost: 0.10,
    ),
    'vine_snake': PassiveDefinition(
      id: 'vine_snake_p', name: '덩굴 재생', description: '매 턴 HP 3% 회복',
      trigger: PassiveTrigger.onTurnStart, hpRegenPercent: 0.03,
    ),
    'mermaid': PassiveDefinition(
      id: 'mermaid_p', name: '수호의 노래', description: '피격 시 20% 확률로 반격',
      trigger: PassiveTrigger.onDamaged, counterChance: 0.20, counterMultiplier: 0.6,
    ),
    // 3★ passives
    'silver_wolf': PassiveDefinition(
      id: 'silver_wolf_p', name: '달빛 축복', description: '공격력 +12%, 크리 +5%',
      trigger: PassiveTrigger.battleStart, atkBoost: 0.12, critBoost: 0.05,
    ),
    'shadow_cat': PassiveDefinition(
      id: 'shadow_cat_p', name: '그림자 은신', description: '크리 확률 +15%',
      trigger: PassiveTrigger.onAttack, critBoost: 0.15,
    ),
    'crystal_turtle': PassiveDefinition(
      id: 'crystal_turtle_p', name: '수정 흡수', description: '방어력 +15%',
      trigger: PassiveTrigger.battleStart, defBoost: 0.15,
    ),
    'storm_eagle': PassiveDefinition(
      id: 'storm_eagle_p', name: '질풍', description: '공격력 +10%',
      trigger: PassiveTrigger.battleStart, atkBoost: 0.10,
    ),
    // 4★ passives
    'phoenix': PassiveDefinition(
      id: 'phoenix_p', name: '불사', description: '매 턴 HP 4% 회복',
      trigger: PassiveTrigger.onTurnStart, hpRegenPercent: 0.04,
    ),
    'ice_queen': PassiveDefinition(
      id: 'ice_queen_p', name: '얼음 갑옷', description: '방어력 +15%, 반격 20%',
      trigger: PassiveTrigger.onDamaged, defBoost: 0.15, counterChance: 0.20, counterMultiplier: 0.7,
    ),
    'dark_knight': PassiveDefinition(
      id: 'dark_knight_p', name: '암흑 집중', description: '공격력 +15%',
      trigger: PassiveTrigger.battleStart, atkBoost: 0.15,
    ),
    // 5★ passives
    'flame_dragon': PassiveDefinition(
      id: 'flame_dragon_p', name: '용의 위엄', description: '공격력 +15%, 방어력 +10%',
      trigger: PassiveTrigger.battleStart, atkBoost: 0.15, defBoost: 0.10,
    ),
    'archangel': PassiveDefinition(
      id: 'archangel_p', name: '신의 가호', description: '매 턴 HP 5% 회복',
      trigger: PassiveTrigger.onTurnStart, hpRegenPercent: 0.05,
    ),
    // Area 6 passives
    'abyss_slug': PassiveDefinition(
      id: 'abyss_slug_p', name: '심연의 재생', description: '매 턴 HP 3% 회복',
      trigger: PassiveTrigger.onTurnStart, hpRegenPercent: 0.03,
    ),
    'crystal_bat': PassiveDefinition(
      id: 'crystal_bat_p', name: '수정 반사', description: '피격 시 20% 확률 반격',
      trigger: PassiveTrigger.onDamaged, counterChance: 0.20, counterMultiplier: 0.6,
    ),
    'shadow_serpent': PassiveDefinition(
      id: 'shadow_serpent_p', name: '독의 기운', description: '공격력 +12%',
      trigger: PassiveTrigger.battleStart, atkBoost: 0.12,
    ),
    'abyss_titan': PassiveDefinition(
      id: 'abyss_titan_p', name: '심연의 갑옷', description: '방어력 +18%',
      trigger: PassiveTrigger.battleStart, defBoost: 0.18,
    ),
  };

  static PassiveDefinition? findPassive(String templateId) =>
      _passives[templateId];

  // ---------------------------------------------------------------------------
  // Ultimate skills (4★+, 5★ only)
  // ---------------------------------------------------------------------------

  static const Map<String, UltimateDefinition> _ultimates = {
    'phoenix': UltimateDefinition(
      id: 'phoenix_ult', name: '불사조의 부활',
      description: '아군 전체 HP 30% 회복 + 적 전체에 큰 데미지',
      maxCharge: 100, chargeRate: 0.012,
      damageMultiplier: 2.5, healPercent: 0.30, isTeamHeal: true,
    ),
    'ice_queen': UltimateDefinition(
      id: 'ice_queen_ult', name: '빙하 시대',
      description: '적 전체에 큰 데미지 + 기절',
      maxCharge: 100, chargeRate: 0.010,
      damageMultiplier: 3.0, stunChance: 0.8,
    ),
    'dark_knight': UltimateDefinition(
      id: 'dark_knight_ult', name: '절멸의 일격',
      description: '단일 적에게 초강력 데미지',
      maxCharge: 100, chargeRate: 0.015,
      damageMultiplier: 5.0, damageTarget: SkillTargetType.singleEnemy,
    ),
    'flame_dragon': UltimateDefinition(
      id: 'flame_dragon_ult', name: '종말의 불꽃',
      description: '적 전체를 불태우는 궁극의 브레스',
      maxCharge: 100, chargeRate: 0.010,
      damageMultiplier: 3.5,
    ),
    'archangel': UltimateDefinition(
      id: 'archangel_ult', name: '천상의 심판',
      description: '적 전체에 큰 데미지 + 아군 전체 회복',
      maxCharge: 100, chargeRate: 0.010,
      damageMultiplier: 2.8, healPercent: 0.25, isTeamHeal: true,
    ),
  };

  static UltimateDefinition? findUltimate(String templateId) =>
      _ultimates[templateId];
}
