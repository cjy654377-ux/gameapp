// Static skill definitions for the monster skill system.
//
// Each monster template maps to exactly one [SkillDefinition]. Skills activate
// automatically when their cooldown reaches 0, replacing the monster's normal
// attack for that turn.

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
    description: '그림자에서 나타나 적에게 치명적인 일격을 가한다.',
    cooldown: 3,
    damageMultiplier: 2.5,
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
    description: '모든 적을 냉기로 얼려 피해를 주고 기절시킨다.',
    cooldown: 4,
    damageMultiplier: 1.3,
    damageTarget: SkillTargetType.allEnemies,
    stunChance: 0.45,
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
  };

  /// Returns the [SkillDefinition] for a given monster template ID,
  /// or `null` if the monster has no skill.
  static SkillDefinition? findByTemplateId(String templateId) =>
      _byTemplateId[templateId];
}
