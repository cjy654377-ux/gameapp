import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/battle_entity.dart';
import '../../domain/services/battle_service.dart';
import '../../domain/services/daily_dungeon_service.dart';
import '../../domain/services/prestige_service.dart';
import '../../domain/services/audio_service.dart';
import 'currency_provider.dart';
import 'monster_provider.dart';
import 'player_provider.dart';
import 'relic_provider.dart';

// =============================================================================
// Phase
// =============================================================================

enum DailyDungeonPhase { idle, fighting, floorCleared, defeated }

// =============================================================================
// State
// =============================================================================

class DailyDungeonState {
  final DailyDungeonPhase phase;
  final int currentFloor;
  final String element;
  final int remainingAttempts;
  final List<BattleMonster> playerTeam;
  final List<BattleMonster> enemyTeam;
  final List<BattleLogEntry> battleLog;
  final int currentTurn;
  final int turnWithinRound;
  final double battleSpeed;
  final bool isAutoMode;
  final int accumulatedGold;
  final int accumulatedExp;
  final int accumulatedShard;

  const DailyDungeonState({
    this.phase = DailyDungeonPhase.idle,
    this.currentFloor = 0,
    this.element = '',
    this.remainingAttempts = DailyDungeonService.maxAttempts,
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

  DailyDungeonState copyWith({
    DailyDungeonPhase? phase,
    int? currentFloor,
    String? element,
    int? remainingAttempts,
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
    return DailyDungeonState(
      phase: phase ?? this.phase,
      currentFloor: currentFloor ?? this.currentFloor,
      element: element ?? this.element,
      remainingAttempts: remainingAttempts ?? this.remainingAttempts,
      playerTeam: playerTeam ?? this.playerTeam,
      enemyTeam: enemyTeam ?? this.enemyTeam,
      battleLog: battleLog ?? this.battleLog,
      currentTurn: currentTurn ?? this.currentTurn,
      turnWithinRound: turnWithinRound ?? this.turnWithinRound,
      battleSpeed: battleSpeed ?? this.battleSpeed,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      accumulatedGold: accumulatedGold ?? this.accumulatedGold,
      accumulatedExp: accumulatedExp ?? this.accumulatedExp,
      accumulatedShard: accumulatedShard ?? this.accumulatedShard,
    );
  }
}

// =============================================================================
// Notifier
// =============================================================================

class DailyDungeonNotifier extends StateNotifier<DailyDungeonState> {
  DailyDungeonNotifier(this.ref) : super(const DailyDungeonState()) {
    _load();
  }

  final Ref ref;

  void _load() {
    final box = Hive.box('settings');
    final raw = box.get('dailyDungeon');
    if (raw != null) {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final lastDate = data['lastDate'] as String?;
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';

      if (lastDate == todayStr) {
        state = state.copyWith(
          remainingAttempts: data['remaining'] as int? ?? DailyDungeonService.maxAttempts,
        );
      }
      // Different day → reset attempts (default value already set)
    }
  }

  Future<void> _save() async {
    final box = Hive.box('settings');
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    await box.put('dailyDungeon', jsonEncode({
      'lastDate': todayStr,
      'remaining': state.remainingAttempts,
    }));
  }

  // ---------------------------------------------------------------------------
  // Start run
  // ---------------------------------------------------------------------------

  void startRun() {
    if (state.remainingAttempts <= 0) return;

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

    final element = DailyDungeonService.todayElement;
    final enemies = DailyDungeonService.createEnemiesForFloor(1, element);

    state = DailyDungeonState(
      phase: DailyDungeonPhase.fighting,
      currentFloor: 1,
      element: element,
      remainingAttempts: state.remainingAttempts - 1,
      playerTeam: teamWithRelics,
      enemyTeam: enemies,
      battleLog: const [],
      currentTurn: 1,
      turnWithinRound: 0,
      battleSpeed: state.battleSpeed,
      isAutoMode: state.isAutoMode,
    );
    _save();
  }

  // ---------------------------------------------------------------------------
  // Turn processing
  // ---------------------------------------------------------------------------

  void processTurn() {
    if (state.phase != DailyDungeonPhase.fighting) return;

    final playerTeam = _copyTeam(state.playerTeam);
    final enemyTeam = _copyTeam(state.enemyTeam);

    final allAlive = BattleService.getTurnOrder([...playerTeam, ...enemyTeam]);
    if (allAlive.isEmpty) return;

    int slot = state.turnWithinRound;
    if (slot >= allAlive.length) slot = 0;

    final attacker = allAlive[slot];
    final bool isPlayerMonster =
        playerTeam.any((m) => m.monsterId == attacker.monsterId);

    final log = List<BattleLogEntry>.from(state.battleLog);
    if (log.length > 50) log.removeRange(0, log.length - 50);

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
      AudioService.instance.playSkillActivation();
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
        AudioService.instance.playHit();
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
      AudioService.instance.playVictory();
      final reward = DailyDungeonService.calculateFloorReward(state.currentFloor);

      state = state.copyWith(
        phase: state.currentFloor >= DailyDungeonService.maxFloors
            ? DailyDungeonPhase.defeated // Run complete (use defeated to show results)
            : DailyDungeonPhase.floorCleared,
        playerTeam: playerTeam,
        enemyTeam: enemyTeam,
        battleLog: log,
        accumulatedGold: state.accumulatedGold + reward.gold,
        accumulatedExp: state.accumulatedExp + reward.exp,
        accumulatedShard: state.accumulatedShard + (state.currentFloor % 3 == 0 ? 1 : 0),
      );
      return;
    }

    if (endPhase == BattlePhase.defeat) {
      AudioService.instance.playDefeat();
      state = state.copyWith(
        phase: DailyDungeonPhase.defeated,
        playerTeam: playerTeam,
        enemyTeam: enemyTeam,
        battleLog: log,
      );
      return;
    }

    final nextSlot = slot + 1;
    final roundComplete = nextSlot >= roundSize;
    state = state.copyWith(
      playerTeam: playerTeam,
      enemyTeam: enemyTeam,
      battleLog: log,
      currentTurn: roundComplete ? state.currentTurn + 1 : state.currentTurn,
      turnWithinRound: roundComplete ? 0 : nextSlot,
    );
  }

  // ---------------------------------------------------------------------------
  // Floor advancement
  // ---------------------------------------------------------------------------

  void advanceFloor() {
    if (state.phase != DailyDungeonPhase.floorCleared) return;

    final nextFloor = state.currentFloor + 1;
    final aliveTeam = state.playerTeam.where((m) => m.isAlive).toList();
    final healed = DailyDungeonService.applyFloorHeal(aliveTeam);
    final enemies = DailyDungeonService.createEnemiesForFloor(nextFloor, state.element);

    state = state.copyWith(
      phase: DailyDungeonPhase.fighting,
      currentFloor: nextFloor,
      playerTeam: healed,
      enemyTeam: enemies,
      battleLog: const [],
      currentTurn: 1,
      turnWithinRound: 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Collect rewards & exit
  // ---------------------------------------------------------------------------

  Future<void> collectAndExit() async {
    final playerData = ref.read(playerProvider).player;
    final multiplier = playerData != null
        ? PrestigeService.bonusMultiplier(playerData)
        : 1.0;

    final gold = (state.accumulatedGold * multiplier).round();
    final exp = (state.accumulatedExp * multiplier).round();

    final currency = ref.read(currencyProvider.notifier);
    final player = ref.read(playerProvider.notifier);

    if (gold > 0) await currency.addGold(gold);
    if (state.accumulatedShard > 0) await currency.addShard(state.accumulatedShard);
    if (exp > 0) await player.addPlayerExp(exp);

    AudioService.instance.playRewardCollect();

    state = state.copyWith(
      phase: DailyDungeonPhase.idle,
      playerTeam: const [],
      enemyTeam: const [],
      battleLog: const [],
      currentFloor: 0,
      accumulatedGold: 0,
      accumulatedExp: 0,
      accumulatedShard: 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Controls
  // ---------------------------------------------------------------------------

  void toggleSpeed() {
    const speeds = [1.0, 2.0, 3.0];
    final idx = speeds.indexWhere((s) => (s - state.battleSpeed).abs() < 0.01);
    state = state.copyWith(battleSpeed: speeds[(idx + 1) % speeds.length]);
  }

  void toggleAuto() {
    state = state.copyWith(isAutoMode: !state.isAutoMode);
  }

  void retreatRun() {
    state = state.copyWith(
      phase: DailyDungeonPhase.idle,
      playerTeam: const [],
      enemyTeam: const [],
      battleLog: const [],
      currentFloor: 0,
      accumulatedGold: 0,
      accumulatedExp: 0,
      accumulatedShard: 0,
    );
  }

  List<BattleMonster> _copyTeam(List<BattleMonster> team) =>
      team.map((m) => m.copyWith()).toList();
}

// =============================================================================
// Provider
// =============================================================================

final dailyDungeonProvider =
    StateNotifierProvider<DailyDungeonNotifier, DailyDungeonState>(
  (ref) => DailyDungeonNotifier(ref),
);
