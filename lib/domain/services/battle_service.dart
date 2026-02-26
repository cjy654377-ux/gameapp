import 'dart:math' as math;

import 'package:gameapp/data/models/monster_model.dart';
import 'package:gameapp/data/static/monster_database.dart';
import 'package:gameapp/data/static/skill_database.dart';
import 'package:gameapp/data/static/stage_database.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/domain/entities/synergy.dart';
import 'package:gameapp/domain/services/synergy_service.dart';

/// Core battle logic service.
///
/// All methods are static — no state is held by [BattleService] itself.
/// Callers are responsible for maintaining the mutable [BattleMonster] lists
/// that represent the two teams.
class BattleService {
  BattleService._();

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  static final math.Random _random = math.Random();

  /// Crit rate: 10 %
  static const double _critRate = 0.10;

  /// Crit damage multiplier: ×1.5
  static const double _critMultiplier = 1.5;

  /// Lower bound of damage variance: ×0.9
  static const double _varianceMin = 0.9;

  /// Upper bound of damage variance: ×1.1
  static const double _varianceMax = 1.1;

  // ---------------------------------------------------------------------------
  // Element advantage
  // ---------------------------------------------------------------------------

  /// Returns the element damage multiplier when [attackerElement] attacks
  /// [defenderElement].
  ///
  /// Advantage chart (mirrored from [MonsterElement.getAdvantage]):
  ///
  /// * fire    > grass  > water  > fire   (triangular)
  /// * electric > water, stone > electric > ghost
  /// * ghost   > light  > dark   > ghost  (triangular)
  /// * stone resists fire (fire → stone = 0.7×)
  ///
  /// Returns 1.3 for advantage, 0.7 for disadvantage, 1.0 for neutral.
  static double getElementMultiplier(
    String attackerElement,
    String defenderElement,
  ) {
    if (attackerElement == defenderElement) return 1.0;

    switch (attackerElement) {
      case 'fire':
        if (defenderElement == 'grass')    return 1.3; // fire > grass
        if (defenderElement == 'water')    return 0.7; // fire < water
        if (defenderElement == 'stone')    return 0.7; // stone resists fire
        return 1.0;

      case 'water':
        if (defenderElement == 'fire')     return 1.3; // water > fire
        if (defenderElement == 'grass')    return 0.7; // water < grass
        if (defenderElement == 'electric') return 0.7; // water < electric
        return 1.0;

      case 'electric':
        if (defenderElement == 'water')    return 1.3; // electric > water
        if (defenderElement == 'ghost')    return 1.3; // electric > ghost
        if (defenderElement == 'stone')    return 0.7; // electric < stone
        return 1.0;

      case 'stone':
        if (defenderElement == 'electric') return 1.3; // stone > electric
        // stone has neutral damage vs fire even though fire is weak vs stone
        return 1.0;

      case 'grass':
        if (defenderElement == 'water')    return 1.3; // grass > water
        if (defenderElement == 'fire')     return 0.7; // grass < fire
        return 1.0;

      case 'ghost':
        if (defenderElement == 'light')    return 1.3; // ghost > light
        if (defenderElement == 'electric') return 0.7; // ghost < electric
        return 1.0;

      case 'light':
        if (defenderElement == 'dark')     return 1.3; // light > dark
        if (defenderElement == 'ghost')    return 0.7; // light < ghost
        return 1.0;

      case 'dark':
        if (defenderElement == 'ghost')    return 1.3; // dark > ghost
        if (defenderElement == 'light')    return 0.7; // dark < light
        return 1.0;

      default:
        return 1.0;
    }
  }

  // ---------------------------------------------------------------------------
  // Damage calculation
  // ---------------------------------------------------------------------------

  /// Internal damage roll returning damage, crit flag, and element multiplier.
  static ({double damage, bool isCrit, double elementMult}) _rollDamage({
    required BattleMonster attacker,
    required BattleMonster defender,
  }) {
    final double defReduction = defender.def / (defender.def + 100.0);
    final double baseDamage = attacker.atk * (1.0 - defReduction);

    final double elementMult =
        getElementMultiplier(attacker.element, defender.element);

    final bool isCrit = _random.nextDouble() < _critRate;
    final double critMult = isCrit ? _critMultiplier : 1.0;

    final double variance =
        _varianceMin + _random.nextDouble() * (_varianceMax - _varianceMin);

    final double raw = baseDamage * elementMult * critMult * variance;
    return (damage: math.max(1.0, raw), isCrit: isCrit, elementMult: elementMult);
  }

  /// Calculates the raw damage dealt by [attacker] hitting [defender].
  ///
  /// Formula:
  /// ```
  /// damage = atk * (1 − def / (def + 100)) * elementMult * critMult * variance
  /// ```
  ///
  /// The returned value is always at least 1.0 (floor damage).
  static double calculateDamage({
    required BattleMonster attacker,
    required BattleMonster defender,
  }) {
    return _rollDamage(attacker: attacker, defender: defender).damage;
  }

  // ---------------------------------------------------------------------------
  // Single attack processing
  // ---------------------------------------------------------------------------

  /// Processes a single attack from [attacker] to [target], mutates
  /// [target.currentHp], and returns an immutable [BattleLogEntry] describing
  /// the event.
  ///
  /// The HP of [target] is clamped to 0 (never goes negative).
  static BattleLogEntry processSingleAttack({
    required BattleMonster attacker,
    required BattleMonster target,
  }) {
    final roll = _rollDamage(attacker: attacker, defender: target);
    final double damage = roll.damage;
    final bool isCrit = roll.isCrit;
    final bool isAdvantage = roll.elementMult > 1.0;

    // --- Apply damage (shield absorbs first) ------------------------------------
    _applyDamage(target, damage);

    // --- Build Korean description -----------------------------------------------
    final String subjectMarker = _endsWithConsonant(attacker.name) ? '이' : '가';
    final int displayDamage = damage.round();
    final StringBuffer sb = StringBuffer();
    sb.write('${attacker.name}$subjectMarker(가) ${target.name}에게 '
        '$displayDamage 데미지!');
    if (isCrit) sb.write(' (치명타!)');
    if (isAdvantage) sb.write(' (효과가 뛰어나다!)');

    return BattleLogEntry(
      attackerName:      attacker.name,
      targetName:        target.name,
      damage:            damage,
      isCritical:        isCrit,
      isElementAdvantage: isAdvantage,
      description:       sb.toString(),
      timestamp:         DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Skill processing
  // ---------------------------------------------------------------------------

  /// Processes the skill for [caster] if it is ready. Returns a list of
  /// [BattleLogEntry] describing all effects (may be empty if skill is not
  /// ready or the monster has no skill).
  ///
  /// Mutates monsters in [playerTeam] and [enemyTeam] in place.
  static List<BattleLogEntry> processSkill({
    required BattleMonster caster,
    required List<BattleMonster> playerTeam,
    required List<BattleMonster> enemyTeam,
    required bool isCasterPlayer,
  }) {
    if (!caster.isSkillReady) return const [];

    final skill = SkillDatabase.findByTemplateId(caster.templateId);
    if (skill == null) return const [];

    final logs = <BattleLogEntry>[];
    final allies = isCasterPlayer ? playerTeam : enemyTeam;
    final enemies = isCasterPlayer ? enemyTeam : playerTeam;
    final now = DateTime.now();
    final sm = _endsWithConsonant(caster.name) ? '이' : '가';

    // -- Damage component -------------------------------------------------------
    if (skill.damageMultiplier > 0) {
      final targets = skill.damageTarget == SkillTargetType.allEnemies
          ? enemies.where((m) => m.isAlive).toList()
          : [BattleService.selectTarget(enemies)].whereType<BattleMonster>().toList();

      for (final target in targets) {
        final double rawDmg = caster.atk * skill.damageMultiplier;
        final double defReduction = target.def / (target.def + 100.0);
        final double damage = math.max(1.0, rawDmg * (1.0 - defReduction));

        _applyDamage(target, damage);

        final sb = StringBuffer();
        sb.write('[${skill.name}] ${caster.name}$sm(가) ${target.name}에게 '
            '${damage.round()} 데미지!');

        // Apply burn
        if (skill.burnTurns > 0) {
          target.burnTurns = skill.burnTurns;
          target.burnDamagePerTurn = target.maxHp * skill.burnDamagePercent;
          sb.write(' (화상 ${skill.burnTurns}턴!)');
        }

        // Apply stun
        if (skill.stunChance > 0 && _random.nextDouble() < skill.stunChance) {
          target.stunTurns = 1;
          sb.write(' (기절!)');
        }

        logs.add(BattleLogEntry(
          attackerName: caster.name,
          targetName: target.name,
          damage: damage,
          isCritical: false,
          isElementAdvantage: false,
          isSkillActivation: true,
          description: sb.toString(),
          timestamp: now,
        ));
      }

      // Drain — heal caster based on total damage dealt
      if (skill.drainPercent > 0 && logs.isNotEmpty) {
        final totalDamage = logs.fold<double>(0, (s, e) => s + e.damage);
        final healAmount = totalDamage * skill.drainPercent;
        caster.currentHp = math.min(caster.maxHp, caster.currentHp + healAmount);
      }
    }

    // -- Shield component -------------------------------------------------------
    if (skill.shieldPercent > 0) {
      final shieldAmount = caster.maxHp * skill.shieldPercent;
      final shieldTargets = skill.isTeamShield
          ? allies.where((m) => m.isAlive).toList()
          : [caster];

      for (final target in shieldTargets) {
        target.shieldHp += shieldAmount;
      }

      final targetDesc = skill.isTeamShield ? '아군 전체' : caster.name;
      logs.add(BattleLogEntry(
        attackerName: caster.name,
        targetName: targetDesc,
        damage: 0,
        isCritical: false,
        isElementAdvantage: false,
        isSkillActivation: true,
        description: '[${skill.name}] ${caster.name}$sm(가) $targetDesc에게 '
            '보호막 ${shieldAmount.round()} 부여!',
        timestamp: now,
      ));
    }

    // -- Heal component ---------------------------------------------------------
    if (skill.healPercent > 0) {
      final healAmount = caster.maxHp * skill.healPercent;
      final healTargets = skill.isTeamHeal
          ? allies.where((m) => m.isAlive).toList()
          : [caster];

      for (final target in healTargets) {
        target.currentHp = math.min(target.maxHp, target.currentHp + healAmount);
      }

      final targetDesc = skill.isTeamHeal ? '아군 전체' : caster.name;
      logs.add(BattleLogEntry(
        attackerName: caster.name,
        targetName: targetDesc,
        damage: 0,
        isCritical: false,
        isElementAdvantage: false,
        isSkillActivation: true,
        description: '[${skill.name}] ${caster.name}$sm(가) $targetDesc '
            '체력 ${healAmount.round()} 회복!',
        timestamp: now,
      ));
    }

    // Reset cooldown after activation.
    caster.skillCooldown = skill.cooldown;

    return logs;
  }

  /// Applies burn damage at the start of a monster's turn.
  /// Returns a [BattleLogEntry] if burn damage was applied, null otherwise.
  static BattleLogEntry? processBurn(BattleMonster monster) {
    if (monster.burnTurns <= 0 || !monster.isAlive) return null;

    final damage = monster.burnDamagePerTurn;
    monster.currentHp = math.max(0.0, monster.currentHp - damage);
    monster.burnTurns--;

    return BattleLogEntry(
      attackerName: '화상',
      targetName: monster.name,
      damage: damage,
      isCritical: false,
      isElementAdvantage: false,
      isSkillActivation: true,
      description: '${monster.name} 화상 피해 ${damage.round()}! '
          '(남은 ${monster.burnTurns}턴)',
      timestamp: DateTime.now(),
    );
  }

  /// Checks and consumes stun at the start of a monster's turn.
  /// Returns a [BattleLogEntry] if the monster is stunned, null otherwise.
  static BattleLogEntry? processStun(BattleMonster monster) {
    if (monster.stunTurns <= 0 || !monster.isAlive) return null;

    monster.stunTurns--;

    return BattleLogEntry(
      attackerName: '기절',
      targetName: monster.name,
      damage: 0,
      isCritical: false,
      isElementAdvantage: false,
      isSkillActivation: true,
      description: '${monster.name} 기절 상태! (행동 불가)',
      timestamp: DateTime.now(),
    );
  }

  /// Decrements the skill cooldown for a monster. Call once per turn.
  static void tickSkillCooldown(BattleMonster monster) {
    if (monster.skillCooldown > 0) {
      monster.skillCooldown--;
    }
  }

  /// Applies damage to a monster, with shield absorbing first.
  static void _applyDamage(BattleMonster target, double damage) {
    if (target.shieldHp > 0) {
      if (target.shieldHp >= damage) {
        target.shieldHp -= damage;
        return;
      } else {
        final remaining = damage - target.shieldHp;
        target.shieldHp = 0;
        target.currentHp = math.max(0.0, target.currentHp - remaining);
        return;
      }
    }
    target.currentHp = math.max(0.0, target.currentHp - damage);
  }

  // ---------------------------------------------------------------------------
  // Target selection
  // ---------------------------------------------------------------------------

  /// Randomly selects an alive enemy from [enemies].
  ///
  /// Returns `null` when the list is empty or all monsters are defeated.
  static BattleMonster? selectTarget(List<BattleMonster> enemies) {
    final alive = enemies.where((m) => m.isAlive).toList();
    if (alive.isEmpty) return null;
    return alive[_random.nextInt(alive.length)];
  }

  // ---------------------------------------------------------------------------
  // Turn order
  // ---------------------------------------------------------------------------

  /// Returns [allMonsters] sorted by speed descending (fastest acts first).
  ///
  /// Only alive monsters are included in the returned list.
  static List<BattleMonster> getTurnOrder(List<BattleMonster> allMonsters) {
    final alive = allMonsters.where((m) => m.isAlive).toList();
    alive.sort((a, b) => b.spd.compareTo(a.spd));
    return alive;
  }

  // ---------------------------------------------------------------------------
  // Battle end detection
  // ---------------------------------------------------------------------------

  /// Returns the appropriate [BattlePhase] based on the current state of both
  /// teams.
  ///
  /// * [BattlePhase.victory] — all enemies are defeated.
  /// * [BattlePhase.defeat]  — all player monsters are defeated.
  /// * [BattlePhase.fighting] — both teams still have alive members.
  static BattlePhase checkBattleEnd(
    List<BattleMonster> playerTeam,
    List<BattleMonster> enemyTeam,
  ) {
    final bool allEnemiesDead = enemyTeam.every((m) => !m.isAlive);
    final bool allPlayersDead = playerTeam.every((m) => !m.isAlive);

    if (allEnemiesDead) return BattlePhase.victory;
    if (allPlayersDead) return BattlePhase.defeat;
    return BattlePhase.fighting;
  }

  // ---------------------------------------------------------------------------
  // Stage enemy creation
  // ---------------------------------------------------------------------------

  /// Creates enemy [BattleMonster] instances for the stage identified by the
  /// 1-based linear [stageId] (stage '1-1' = 1, '2-1' = 7, …, '5-6' = 30).
  ///
  /// Looks up the [StageData] from [StageDatabase] and the corresponding
  /// [MonsterTemplate] from [MonsterDatabase].  Unknown templates are skipped
  /// with a warning comment in code (runtime: silently skipped).
  ///
  /// Enemy stats are scaled as:
  /// ```
  /// finalStat = baseStat * (1 + (level - 1) * 0.05)
  /// ```
  /// (evolution stage 0 for all enemies).
  static List<BattleMonster> createEnemiesForStage(int stageId) {
    // Convert 1-based linear stageId to '${area}-${num}' string format.
    final String stageKey = _linearIdToKey(stageId);
    final StageData? stageData = StageDatabase.findById(stageKey);
    if (stageData == null) return [];

    final enemies = <BattleMonster>[];
    for (int i = 0; i < stageData.enemyTemplateIds.length; i++) {
      final String templateId = stageData.enemyTemplateIds[i];
      final int level = stageData.enemyLevels[i];
      final MonsterTemplate? template = MonsterDatabase.findById(templateId);
      if (template == null) continue;

      final double levelMult = 1.0 + (level - 1) * 0.05;
      final double hp  = template.baseHp  * levelMult;
      final double atk = template.baseAtk * levelMult;
      final double def = template.baseDef * levelMult;
      final double spd = template.baseSpd * levelMult;

      final skill = SkillDatabase.findByTemplateId(templateId);
      enemies.add(BattleMonster(
        monsterId:  'enemy_${templateId}_$i',
        templateId: templateId,
        name:       template.name,
        element:    template.element,
        size:       template.size,
        rarity:     template.rarity,
        maxHp:      hp,
        currentHp:  hp,
        atk:        atk,
        def:        def,
        spd:        spd,
        skillId:          skill?.id,
        skillName:        skill?.name,
        skillCooldown:    skill?.cooldown ?? 0,
        skillMaxCooldown: skill?.cooldown ?? 0,
      ));
    }
    return enemies;
  }

  // ---------------------------------------------------------------------------
  // Player team creation
  // ---------------------------------------------------------------------------

  /// Creates player [BattleMonster] instances from a list of [MonsterModel]
  /// objects, applying active synergy bonuses.
  ///
  /// Returns a record containing the built team and the list of active
  /// synergies so the caller can expose them in the UI.
  static ({List<BattleMonster> team, List<SynergyEffect> synergies})
      createPlayerTeam(List<dynamic> monsters) {
    final models = monsters.whereType<MonsterModel>().toList();

    // Build MonsterInfo list for synergy evaluation.
    final infos = models
        .map((m) => MonsterInfo(
              templateId: m.templateId,
              element: m.element,
              size: m.size,
              rarity: m.rarity,
            ))
        .toList();

    final synergies = SynergyService.getActiveSynergies(infos);
    final bonuses = SynergyService.getTotalBonuses(infos);

    final atkMult = 1.0 + (bonuses['atk'] ?? 0.0);
    final defMult = 1.0 + (bonuses['def'] ?? 0.0);
    final hpMult  = 1.0 + (bonuses['hp']  ?? 0.0);
    final spdMult = 1.0 + (bonuses['spd'] ?? 0.0);

    final team = models.map((m) {
      final double hp = m.finalHp * hpMult;
      final skill = SkillDatabase.findByTemplateId(m.templateId);
      return BattleMonster(
        monsterId:  m.id,
        templateId: m.templateId,
        name:       m.name,
        element:    m.element,
        size:       m.size,
        rarity:     m.rarity,
        maxHp:      hp,
        currentHp:  hp,
        atk:        m.finalAtk * atkMult,
        def:        m.finalDef * defMult,
        spd:        m.finalSpd * spdMult,
        skillId:          skill?.id,
        skillName:        skill?.name,
        skillCooldown:    skill?.cooldown ?? 0,
        skillMaxCooldown: skill?.cooldown ?? 0,
      );
    }).toList();

    return (team: team, synergies: synergies);
  }

  // ---------------------------------------------------------------------------
  // Reward calculation
  // ---------------------------------------------------------------------------

  /// Returns the [BattleReward] for the given 1-based linear [stageId].
  ///
  /// * A 5 % random chance to include a bonus evolution shard (1 shard).
  /// * Returns a zero reward if the stage is not found in the database.
  static BattleReward calculateReward(int stageId) {
    final String stageKey = _linearIdToKey(stageId);
    final StageData? stageData = StageDatabase.findById(stageKey);
    if (stageData == null) {
      return const BattleReward(gold: 0, exp: 0);
    }

    final bool hasBonusShard = _random.nextDouble() < 0.05;
    return BattleReward(
      gold:        stageData.goldReward,
      exp:         stageData.expReward,
      bonusShard:  hasBonusShard ? 1 : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Private utilities
  // ---------------------------------------------------------------------------

  /// Converts a 1-based linear stage index to the `'${area}-${num}'` key used
  /// by [StageDatabase].
  ///
  /// Stage layout: 5 areas × 6 stages each (total 30 stages).
  ///   stageId 1  → '1-1'
  ///   stageId 6  → '1-6'
  ///   stageId 7  → '2-1'
  ///   stageId 30 → '5-6'
  static String _linearIdToKey(int stageId) {
    final int idx  = (stageId - 1).clamp(0, 29); // 0-based
    final int area = idx ~/ 6 + 1;               // 1–5
    final int num  = idx % 6 + 1;                // 1–6
    return '$area-$num';
  }

  /// Returns `true` when the last character of [str] ends with a Korean
  /// consonant (받침 있음), used to select the correct subject particle.
  ///
  /// Korean Unicode block: AC00–D7A3.
  /// A syllable has a final consonant when `(codeUnit - 0xAC00) % 28 != 0`.
  static bool _endsWithConsonant(String str) {
    if (str.isEmpty) return false;
    final int code = str.codeUnitAt(str.length - 1);
    if (code < 0xAC00 || code > 0xD7A3) return false; // not Hangul syllable
    return (code - 0xAC00) % 28 != 0;
  }
}
