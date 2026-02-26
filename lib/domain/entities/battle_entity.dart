/// Battle domain entities for the monster idle game.
///
/// These are pure Dart value objects used exclusively within the battle
/// domain.  They have no Hive annotations and no Flutter dependencies.

// =============================================================================
// BattlePhase
// =============================================================================

/// Represents the current phase of a battle session.
enum BattlePhase {
  /// No battle is active.
  idle,

  /// Battle is being set up (teams created, order determined).
  preparing,

  /// Battle is actively processing turns.
  fighting,

  /// All enemies have been defeated — player wins.
  victory,

  /// All player monsters have been defeated — player loses.
  defeat,
}

// =============================================================================
// BattleMonster
// =============================================================================

/// A lightweight, battle-specific snapshot of a monster's stats.
///
/// Created from either a [MonsterModel] (player side) or a [MonsterTemplate]
/// + level (enemy side).  [currentHp] is the only mutable field; all combat
/// stats are final for the duration of a battle.
class BattleMonster {
  /// The unique instance ID (matches [MonsterModel.id] for player monsters,
  /// or a generated string for enemies such as `'enemy_slime_0'`).
  final String monsterId;

  /// The template ID that this monster was created from (e.g. `'slime'`).
  final String templateId;

  /// Display name in Korean (e.g. `'슬라임'`).
  final String name;

  /// Element string: 'fire', 'water', 'electric', 'stone',
  /// 'grass', 'ghost', 'light', or 'dark'.
  final String element;

  /// Size string: 'small', 'medium', 'large', or 'extraLarge'.
  final String size;

  /// Rarity: 1 = 일반 … 5 = 전설.
  final int rarity;

  /// Maximum HP for this battle (computed from base stats * level * evolution).
  final double maxHp;

  /// Current HP.  Mutated by [BattleService.processSingleAttack].
  double currentHp;

  /// Final attack stat.
  final double atk;

  /// Final defence stat.
  final double def;

  /// Final speed stat (determines turn order).
  final double spd;

  /// Whether this monster can still act (HP > 0).
  bool get isAlive => currentHp > 0;

  BattleMonster({
    required this.monsterId,
    required this.templateId,
    required this.name,
    required this.element,
    required this.size,
    required this.rarity,
    required this.maxHp,
    required this.currentHp,
    required this.atk,
    required this.def,
    required this.spd,
  });

  /// Returns a new [BattleMonster] with the specified fields overridden.
  BattleMonster copyWith({
    String? monsterId,
    String? templateId,
    String? name,
    String? element,
    String? size,
    int? rarity,
    double? maxHp,
    double? currentHp,
    double? atk,
    double? def,
    double? spd,
  }) {
    return BattleMonster(
      monsterId:  monsterId  ?? this.monsterId,
      templateId: templateId ?? this.templateId,
      name:       name       ?? this.name,
      element:    element    ?? this.element,
      size:       size       ?? this.size,
      rarity:     rarity     ?? this.rarity,
      maxHp:      maxHp      ?? this.maxHp,
      currentHp:  currentHp  ?? this.currentHp,
      atk:        atk        ?? this.atk,
      def:        def        ?? this.def,
      spd:        spd        ?? this.spd,
    );
  }

  @override
  String toString() =>
      'BattleMonster($name, hp: $currentHp/$maxHp, '
      'atk: $atk, def: $def, spd: $spd, element: $element)';
}

// =============================================================================
// BattleLogEntry
// =============================================================================

/// An immutable record of a single attack event during a battle.
class BattleLogEntry {
  /// Korean display name of the attacker.
  final String attackerName;

  /// Korean display name of the target.
  final String targetName;

  /// Raw damage dealt (after all multipliers, before HP floor clamping).
  final double damage;

  /// Whether the hit was a critical strike.
  final bool isCritical;

  /// Whether the attacker's element had an advantage over the target's element
  /// (multiplier > 1.0).
  final bool isElementAdvantage;

  /// Human-readable Korean battle log text, e.g.:
  /// `"슬라임이(가) 고블린에게 42 데미지! (치명타!)"`
  final String description;

  /// Wall-clock time at which this entry was created.
  final DateTime timestamp;

  const BattleLogEntry({
    required this.attackerName,
    required this.targetName,
    required this.damage,
    required this.isCritical,
    required this.isElementAdvantage,
    required this.description,
    required this.timestamp,
  });

  @override
  String toString() => description;
}

// =============================================================================
// BattleReward
// =============================================================================

/// Rewards granted to the player upon winning a stage.
class BattleReward {
  /// Gold coins earned.
  final int gold;

  /// Player experience points earned.
  final int exp;

  /// Bonus evolution shard (nullable — rare random drop).
  final int? bonusShard;

  const BattleReward({
    required this.gold,
    required this.exp,
    this.bonusShard,
  });

  @override
  String toString() =>
      'BattleReward(gold: $gold, exp: $exp, bonusShard: $bonusShard)';
}

// =============================================================================
// StageInfo
// =============================================================================

/// A fully resolved stage snapshot used by the battle UI.
///
/// Differs from [StageData] in that it contains instantiated [BattleMonster]
/// objects ready for combat, rather than raw template IDs and levels.
class StageInfo {
  /// Numeric stage identifier (1-based linear index across all areas).
  ///
  /// E.g. stage '1-1' = 1, '1-6' = 6, '2-1' = 7, '5-6' = 30.
  final int stageId;

  /// Korean display name (e.g. `'1-1 시작의 숲'`).
  final String stageName;

  /// Enemy [BattleMonster] instances for this stage.
  final List<BattleMonster> enemies;

  /// Rewards awarded when the player clears this stage.
  final BattleReward reward;

  const StageInfo({
    required this.stageId,
    required this.stageName,
    required this.enemies,
    required this.reward,
  });

  @override
  String toString() =>
      'StageInfo(stageId: $stageId, stageName: $stageName, '
      'enemies: ${enemies.length}, reward: $reward)';
}
