import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/domain/services/battle_service.dart';
import 'package:gameapp/domain/services/dungeon_service.dart';
import 'package:gameapp/domain/services/prestige_service.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';
import 'package:gameapp/presentation/providers/monster_provider.dart';
import 'package:gameapp/presentation/providers/player_provider.dart';
import 'package:gameapp/presentation/providers/relic_provider.dart';

// =============================================================================
// DungeonPhase
// =============================================================================

enum DungeonPhase {
  /// Not in a dungeon run.
  idle,

  /// Currently fighting a floor.
  fighting,

  /// Floor cleared — waiting for player to advance.
  floorCleared,

  /// Player team wiped out — run is over.
  defeated,
}

// =============================================================================
// DungeonState
// =============================================================================

class DungeonState {
  final DungeonPhase phase;
  final int currentFloor;
  final int bestFloor;
  final List<BattleMonster> playerTeam;
  final List<BattleMonster> enemyTeam;
  final List<BattleLogEntry> battleLog;
  final int currentTurn;
  final int turnWithinRound;
  final double battleSpeed;
  final bool isAutoMode;

  /// Accumulated gold earned this run.
  final int accumulatedGold;

  /// Accumulated exp earned this run.
  final int accumulatedExp;

  /// Accumulated shards earned this run.
  final int accumulatedShard;

  const DungeonState({
    this.phase = DungeonPhase.idle,
    this.currentFloor = 0,
    this.bestFloor = 0,
    this.playerTeam = const [],
    this.enemyTeam = const [],
    this.battleLog = const [],
    this.currentTurn = 0,
    this.turnWithinRound = 0,
    this.battleSpeed = 1.0,
    this.isAutoMode = false,
    this.accumulatedGold = 0,
    this.accumulatedExp = 0,
    this.accumulatedShard = 0,
  });

  DungeonState copyWith({
    DungeonPhase? phase,
    int? currentFloor,
    int? bestFloor,
    List<BattleMonster>? playerTeam,
    List<BattleMonster>? enemyTeam,
    List<BattleLogEntry>? battleLog,
    int? currentTurn,
    int? turnWithinRound,
    double? battleSpeed,
    bool? isAutoMode,
    int? accumulatedGold,
    int? accumulatedExp,
    int? accumulatedShard,
  }) {
    return DungeonState(
      phase:            phase            ?? this.phase,
      currentFloor:     currentFloor     ?? this.currentFloor,
      bestFloor:        bestFloor        ?? this.bestFloor,
      playerTeam:       playerTeam       ?? this.playerTeam,
      enemyTeam:        enemyTeam        ?? this.enemyTeam,
      battleLog:        battleLog        ?? this.battleLog,
      currentTurn:      currentTurn      ?? this.currentTurn,
      turnWithinRound:  turnWithinRound  ?? this.turnWithinRound,
      battleSpeed:      battleSpeed      ?? this.battleSpeed,
      isAutoMode:       isAutoMode       ?? this.isAutoMode,
      accumulatedGold:  accumulatedGold  ?? this.accumulatedGold,
      accumulatedExp:   accumulatedExp   ?? this.accumulatedExp,
      accumulatedShard: accumulatedShard ?? this.accumulatedShard,
    );
  }
}

// =============================================================================
// DungeonNotifier
// =============================================================================

class DungeonNotifier extends StateNotifier<DungeonState> {
  DungeonNotifier(this.ref) : super(const DungeonState());

  final Ref ref;

  // ---------------------------------------------------------------------------
  // Start dungeon run
  // ---------------------------------------------------------------------------

  void startRun() {
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

    final bestFloor =
        ref.read(playerProvider).player?.maxDungeonFloor ?? 0;

    // Start at floor 1.
    final enemies = DungeonService.createEnemiesForFloor(1);

    state = DungeonState(
      phase: DungeonPhase.fighting,
      currentFloor: 1,
      bestFloor: bestFloor,
      playerTeam: teamWithRelics,
      enemyTeam: enemies,
      battleLog: const [],
      currentTurn: 1,
      turnWithinRound: 0,
      battleSpeed: state.battleSpeed,
      isAutoMode: state.isAutoMode,
      accumulatedGold: 0,
      accumulatedExp: 0,
      accumulatedShard: 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Turn processing (same logic as battle_provider)
  // ---------------------------------------------------------------------------

  void processTurn() {
    if (state.phase != DungeonPhase.fighting) return;

    final playerTeam = _copyTeam(state.playerTeam);
    final enemyTeam  = _copyTeam(state.enemyTeam);

    final allAlive = BattleService.getTurnOrder([...playerTeam, ...enemyTeam]);
    if (allAlive.isEmpty) return;

    int slot = state.turnWithinRound;
    if (slot >= allAlive.length) slot = 0;

    final attacker = allAlive[slot];
    final bool isPlayerMonster =
        playerTeam.any((m) => m.monsterId == attacker.monsterId);

    final log = List<BattleLogEntry>.from(state.battleLog);

    // 1. Burn
    final burnEntry = BattleService.processBurn(attacker);
    if (burnEntry != null) log.add(burnEntry);

    if (!attacker.isAlive) {
      _emitState(playerTeam, enemyTeam, log, slot, allAlive.length);
      return;
    }

    // 2. Stun
    final stunEntry = BattleService.processStun(attacker);
    if (stunEntry != null) {
      log.add(stunEntry);
      BattleService.tickSkillCooldown(attacker);
      _emitState(playerTeam, enemyTeam, log, slot, allAlive.length);
      return;
    }

    // 3. Skill or normal attack
    BattleService.tickSkillCooldown(attacker);

    if (attacker.isSkillReady) {
      final skillLogs = BattleService.processSkill(
        caster: attacker,
        playerTeam: playerTeam,
        enemyTeam: enemyTeam,
        isCasterPlayer: isPlayerMonster,
      );
      log.addAll(skillLogs);
    } else {
      final opposingTeam = isPlayerMonster ? enemyTeam : playerTeam;
      final target = BattleService.selectTarget(opposingTeam);
      if (target != null) {
        final targetInList = opposingTeam.firstWhere(
          (m) => m.monsterId == target.monsterId,
        );
        final entry = BattleService.processSingleAttack(
          attacker: attacker,
          target: targetInList,
        );
        log.add(entry);
      }
    }

    _emitState(playerTeam, enemyTeam, log, slot, allAlive.length);
  }

  void _emitState(
    List<BattleMonster> playerTeam,
    List<BattleMonster> enemyTeam,
    List<BattleLogEntry> log,
    int slot,
    int roundSize,
  ) {
    final endPhase = BattleService.checkBattleEnd(playerTeam, enemyTeam);

    if (endPhase == BattlePhase.victory) {
      // Floor cleared — accumulate rewards.
      final floorReward =
          DungeonService.calculateFloorReward(state.currentFloor);

      state = state.copyWith(
        phase: DungeonPhase.floorCleared,
        playerTeam: playerTeam,
        enemyTeam: enemyTeam,
        battleLog: log,
        accumulatedGold:  state.accumulatedGold + floorReward.gold,
        accumulatedExp:   state.accumulatedExp + floorReward.exp,
        accumulatedShard: state.accumulatedShard + (floorReward.bonusShard ?? 0),
      );
      return;
    }

    if (endPhase == BattlePhase.defeat) {
      state = state.copyWith(
        phase: DungeonPhase.defeated,
        playerTeam: playerTeam,
        enemyTeam: enemyTeam,
        battleLog: log,
      );
      return;
    }

    final nextSlot = slot + 1;
    final bool roundComplete = nextSlot >= roundSize;
    final newTurn = roundComplete ? state.currentTurn + 1 : state.currentTurn;
    final newSlot = roundComplete ? 0 : nextSlot;

    state = state.copyWith(
      playerTeam: playerTeam,
      enemyTeam: enemyTeam,
      battleLog: log,
      currentTurn: newTurn,
      turnWithinRound: newSlot,
    );
  }

  // ---------------------------------------------------------------------------
  // Advance to next floor
  // ---------------------------------------------------------------------------

  void advanceFloor() {
    if (state.phase != DungeonPhase.floorCleared) return;

    final nextFloor = state.currentFloor + 1;
    final playerTeam = _copyTeam(state.playerTeam);

    // Heal 20% and reset status effects between floors.
    DungeonService.applyFloorHeal(playerTeam);

    final enemies = DungeonService.createEnemiesForFloor(nextFloor);

    state = state.copyWith(
      phase: DungeonPhase.fighting,
      currentFloor: nextFloor,
      playerTeam: playerTeam,
      enemyTeam: enemies,
      battleLog: const [],
      currentTurn: 1,
      turnWithinRound: 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Collect rewards and exit
  // ---------------------------------------------------------------------------

  Future<void> collectAndExit() async {
    final currency = ref.read(currencyProvider.notifier);
    final player = ref.read(playerProvider.notifier);

    // Apply prestige bonus multiplier to gold and exp.
    final playerData = ref.read(playerProvider).player;
    final multiplier = playerData != null
        ? PrestigeService.bonusMultiplier(playerData)
        : 1.0;

    if (state.accumulatedGold > 0) {
      await currency.addGold((state.accumulatedGold * multiplier).round());
    }
    if (state.accumulatedExp > 0) {
      await player.addPlayerExp((state.accumulatedExp * multiplier).round());
    }
    if (state.accumulatedShard > 0) {
      await currency.addShard(state.accumulatedShard);
    }

    // Drop a random relic every 5 floors.
    if (state.currentFloor >= 5 && state.currentFloor % 5 == 0) {
      final relicNotifier = ref.read(relicProvider.notifier);
      final maxRarity = (state.currentFloor / 10).ceil().clamp(1, 5);
      final relic = await relicNotifier.generateRandomRelic(maxRarity: maxRarity);
      await relicNotifier.addRelic(relic);
    }

    // Update best floor record.
    await player.updateMaxDungeonFloor(state.currentFloor);

    state = DungeonState(
      bestFloor: ref.read(playerProvider).player?.maxDungeonFloor ?? 0,
      battleSpeed: state.battleSpeed,
      isAutoMode: state.isAutoMode,
    );
  }

  // ---------------------------------------------------------------------------
  // Speed / auto mode
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

final dungeonProvider =
    StateNotifierProvider<DungeonNotifier, DungeonState>(
  (ref) => DungeonNotifier(ref),
);
