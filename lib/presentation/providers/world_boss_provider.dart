import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/domain/services/battle_service.dart';
import 'package:gameapp/domain/services/prestige_service.dart';
import 'package:gameapp/domain/services/world_boss_service.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';
import 'package:gameapp/presentation/providers/monster_provider.dart';
import 'package:gameapp/presentation/providers/player_provider.dart';
import 'package:gameapp/domain/services/audio_service.dart';
import 'package:gameapp/presentation/providers/relic_provider.dart';

// =============================================================================
// WorldBossPhase
// =============================================================================

enum WorldBossPhase {
  idle,
  fighting,
  finished,
}

// =============================================================================
// WorldBossState
// =============================================================================

class WorldBossState {
  final WorldBossPhase phase;
  final BattleMonster? boss;
  final List<BattleMonster> playerTeam;
  final List<BattleLogEntry> battleLog;
  final int currentTurn;
  final int turnWithinRound;
  final double battleSpeed;
  final bool isAutoMode;

  /// Total damage dealt to the boss this fight.
  final double totalDamageDealt;

  /// Reward from the last completed fight.
  final WorldBossReward? lastReward;

  /// Attempts used today.
  final int attemptsUsed;

  /// Date string for tracking daily resets (yyyy-MM-dd).
  final String lastAttemptDate;

  /// Best damage record.
  final double bestDamage;

  const WorldBossState({
    this.phase = WorldBossPhase.idle,
    this.boss,
    this.playerTeam = const [],
    this.battleLog = const [],
    this.currentTurn = 0,
    this.turnWithinRound = 0,
    this.battleSpeed = 1.0,
    this.isAutoMode = false,
    this.totalDamageDealt = 0,
    this.lastReward,
    this.attemptsUsed = 0,
    this.lastAttemptDate = '',
    this.bestDamage = 0,
  });

  bool get canAttempt {
    final today = _todayStr();
    if (lastAttemptDate != today) return true;
    return attemptsUsed < WorldBossService.maxAttempts;
  }

  int get remainingAttempts {
    final today = _todayStr();
    if (lastAttemptDate != today) return WorldBossService.maxAttempts;
    return (WorldBossService.maxAttempts - attemptsUsed).clamp(0, WorldBossService.maxAttempts);
  }

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  WorldBossState copyWith({
    WorldBossPhase? phase,
    BattleMonster? boss,
    List<BattleMonster>? playerTeam,
    List<BattleLogEntry>? battleLog,
    int? currentTurn,
    int? turnWithinRound,
    double? battleSpeed,
    bool? isAutoMode,
    double? totalDamageDealt,
    WorldBossReward? lastReward,
    bool clearReward = false,
    int? attemptsUsed,
    String? lastAttemptDate,
    double? bestDamage,
  }) {
    return WorldBossState(
      phase: phase ?? this.phase,
      boss: boss ?? this.boss,
      playerTeam: playerTeam ?? this.playerTeam,
      battleLog: battleLog ?? this.battleLog,
      currentTurn: currentTurn ?? this.currentTurn,
      turnWithinRound: turnWithinRound ?? this.turnWithinRound,
      battleSpeed: battleSpeed ?? this.battleSpeed,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      totalDamageDealt: totalDamageDealt ?? this.totalDamageDealt,
      lastReward: clearReward ? null : (lastReward ?? this.lastReward),
      attemptsUsed: attemptsUsed ?? this.attemptsUsed,
      lastAttemptDate: lastAttemptDate ?? this.lastAttemptDate,
      bestDamage: bestDamage ?? this.bestDamage,
    );
  }
}

// =============================================================================
// WorldBossNotifier
// =============================================================================

class WorldBossNotifier extends StateNotifier<WorldBossState> {
  WorldBossNotifier(this.ref) : super(const WorldBossState());

  final Ref ref;

  // ---------------------------------------------------------------------------
  // Start fight
  // ---------------------------------------------------------------------------

  void startFight() {
    if (!state.canAttempt) return;

    final roster = ref.read(monsterListProvider);
    final result = BattleService.createPlayerTeam(
        roster.where((m) => m.isInTeam).toList());
    if (result.team.isEmpty) return;

    // Apply relic bonuses.
    final relicNotifier = ref.read(relicProvider.notifier);
    final teamWithRelics = result.team.map((m) {
      final bonus = relicNotifier.relicBonuses(m.monsterId);
      if (bonus.atk == 0 && bonus.def == 0 && bonus.hp == 0 && bonus.spd == 0) {
        return m;
      }
      final newHp = m.maxHp + bonus.hp;
      return m.copyWith(
        atk: m.atk + bonus.atk,
        def: m.def + bonus.def,
        maxHp: newHp,
        currentHp: newHp,
        spd: m.spd + bonus.spd,
      );
    }).toList();

    final playerLevel = ref.read(playerProvider).player?.playerLevel ?? 1;
    final boss = WorldBossService.createBoss(playerLevel: playerLevel);

    final today = WorldBossState._todayStr();
    final attemptsUsed = state.lastAttemptDate == today
        ? state.attemptsUsed + 1
        : 1;

    state = WorldBossState(
      phase: WorldBossPhase.fighting,
      boss: boss,
      playerTeam: teamWithRelics,
      battleLog: const [],
      currentTurn: 1,
      turnWithinRound: 0,
      battleSpeed: state.battleSpeed,
      isAutoMode: state.isAutoMode,
      totalDamageDealt: 0,
      attemptsUsed: attemptsUsed,
      lastAttemptDate: today,
      bestDamage: state.bestDamage,
    );
  }

  // ---------------------------------------------------------------------------
  // Turn processing
  // ---------------------------------------------------------------------------

  void processTurn() {
    if (state.phase != WorldBossPhase.fighting) return;
    if (state.boss == null) return;

    // Check turn limit.
    if (state.currentTurn > WorldBossService.maxTurns) {
      _finishFight();
      return;
    }

    final playerTeam = _copyTeam(state.playerTeam);
    final boss = state.boss!.copyWith();

    // Build turn order: all alive player monsters + boss.
    final allUnits = <BattleMonster>[
      ...playerTeam.where((m) => m.isAlive),
      if (boss.isAlive) boss,
    ];
    allUnits.sort((a, b) => b.spd.compareTo(a.spd));
    if (allUnits.isEmpty) {
      _finishFight();
      return;
    }

    int slot = state.turnWithinRound;
    if (slot >= allUnits.length) slot = 0;

    final attacker = allUnits[slot];
    final log = List<BattleLogEntry>.from(state.battleLog);
    double damageThisTurn = 0;

    // Check if attacker is the boss or a player monster.
    final isBoss = attacker.monsterId == boss.monsterId;

    // Burn
    final burnEntry = BattleService.processBurn(attacker);
    if (burnEntry != null) {
      log.add(burnEntry);
      if (!isBoss && !attacker.isAlive) {
        _emitFightState(playerTeam, boss, log, slot, allUnits.length, damageThisTurn);
        return;
      }
      if (isBoss && burnEntry.damage > 0) {
        damageThisTurn += burnEntry.damage;
      }
    }

    // Stun
    final stunEntry = BattleService.processStun(attacker);
    if (stunEntry != null) {
      log.add(stunEntry);
      BattleService.tickSkillCooldown(attacker);
      _emitFightState(playerTeam, boss, log, slot, allUnits.length, damageThisTurn);
      return;
    }

    BattleService.tickSkillCooldown(attacker);

    if (isBoss) {
      // Boss attacks random player monster.
      final entry = WorldBossService.bossAttackRandom(boss, playerTeam);
      if (entry != null) log.add(entry);
    } else {
      // Player monster attacks the boss.
      if (attacker.isSkillReady) {
        // Use skill — treat boss as single-member "enemy team".
        AudioService.instance.playSkillActivation();
        final bossTeam = [boss];
        final skillLogs = BattleService.processSkill(
          caster: attacker,
          playerTeam: playerTeam,
          enemyTeam: bossTeam,
          isCasterPlayer: true,
        );
        for (final entry in skillLogs) {
          log.add(entry);
          if (entry.targetName == boss.name) {
            damageThisTurn += entry.damage;
          }
        }
      } else {
        // Normal attack on boss.
        final entry = BattleService.processSingleAttack(
          attacker: attacker,
          target: boss,
        );
        log.add(entry);
        damageThisTurn += entry.damage;
        AudioService.instance.playHit();
      }
    }

    _emitFightState(playerTeam, boss, log, slot, allUnits.length, damageThisTurn);
  }

  void _emitFightState(
    List<BattleMonster> playerTeam,
    BattleMonster boss,
    List<BattleLogEntry> log,
    int slot,
    int roundSize,
    double damageThisTurn,
  ) {
    final newDamage = state.totalDamageDealt + damageThisTurn;

    // Check end conditions: all player monsters dead OR turn limit reached.
    final allDead = !playerTeam.any((m) => m.isAlive);
    final turnLimit = state.currentTurn > WorldBossService.maxTurns;

    if (allDead || turnLimit || !boss.isAlive) {
      final reward = WorldBossService.calculateReward(newDamage);
      final newBest = newDamage > state.bestDamage ? newDamage : state.bestDamage;
      state = state.copyWith(
        phase: WorldBossPhase.finished,
        boss: boss,
        playerTeam: playerTeam,
        battleLog: log,
        totalDamageDealt: newDamage,
        lastReward: reward,
        bestDamage: newBest,
      );
      return;
    }

    final nextSlot = slot + 1;
    final roundComplete = nextSlot >= roundSize;
    final newTurn = roundComplete ? state.currentTurn + 1 : state.currentTurn;
    final newSlot = roundComplete ? 0 : nextSlot;

    // Check turn limit after advancing.
    if (newTurn > WorldBossService.maxTurns) {
      final reward = WorldBossService.calculateReward(newDamage);
      final newBest = newDamage > state.bestDamage ? newDamage : state.bestDamage;
      state = state.copyWith(
        phase: WorldBossPhase.finished,
        boss: boss,
        playerTeam: playerTeam,
        battleLog: log,
        totalDamageDealt: newDamage,
        lastReward: reward,
        bestDamage: newBest,
      );
      return;
    }

    state = state.copyWith(
      boss: boss,
      playerTeam: playerTeam,
      battleLog: log,
      currentTurn: newTurn,
      turnWithinRound: newSlot,
      totalDamageDealt: newDamage,
    );
  }

  void _finishFight() {
    final reward = WorldBossService.calculateReward(state.totalDamageDealt);
    final newBest = state.totalDamageDealt > state.bestDamage
        ? state.totalDamageDealt
        : state.bestDamage;
    state = state.copyWith(
      phase: WorldBossPhase.finished,
      lastReward: reward,
      bestDamage: newBest,
    );
  }

  // ---------------------------------------------------------------------------
  // Collect rewards
  // ---------------------------------------------------------------------------

  Future<void> collectReward() async {
    final reward = state.lastReward;
    if (reward == null) return;

    final currency = ref.read(currencyProvider.notifier);
    final player = ref.read(playerProvider.notifier);

    // Apply prestige bonus.
    final playerData = ref.read(playerProvider).player;
    final multiplier = playerData != null
        ? PrestigeService.bonusMultiplier(playerData)
        : 1.0;

    await currency.addGold((reward.gold * multiplier).round());
    await currency.addDiamond(reward.diamond);
    await currency.addShard(reward.shard);
    await player.addPlayerExp((reward.exp * multiplier).round());

    AudioService.instance.playRewardCollect();

    // Drop a random relic from world boss.
    final relicNotifier = ref.read(relicProvider.notifier);
    final maxRarity = (reward.totalDamage / 10000).ceil().clamp(2, 5);
    final relic = await relicNotifier.generateRandomRelic(maxRarity: maxRarity);
    await relicNotifier.addRelic(relic);

    state = state.copyWith(
      phase: WorldBossPhase.idle,
      clearReward: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Controls
  // ---------------------------------------------------------------------------

  void toggleSpeed() {
    const speeds = [1.0, 2.0, 3.0];
    final current = state.battleSpeed;
    final idx = speeds.indexWhere((s) => (s - current).abs() < 0.01);
    final nextIdx = (idx + 1) % speeds.length;
    state = state.copyWith(battleSpeed: speeds[nextIdx]);
  }

  void toggleAutoMode() {
    state = state.copyWith(isAutoMode: !state.isAutoMode);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  List<BattleMonster> _copyTeam(List<BattleMonster> team) {
    return team.map((m) => m.copyWith()).toList();
  }
}

// =============================================================================
// Provider
// =============================================================================

final worldBossProvider =
    StateNotifierProvider<WorldBossNotifier, WorldBossState>(
  (ref) => WorldBossNotifier(ref),
);
