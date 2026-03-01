import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/domain/services/battle_service.dart';
import 'package:gameapp/domain/services/tower_service.dart';
import 'package:gameapp/domain/services/prestige_service.dart';
import 'package:gameapp/domain/services/audio_service.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';
import 'package:gameapp/presentation/providers/monster_provider.dart';
import 'package:gameapp/presentation/providers/player_provider.dart';
import 'package:gameapp/presentation/providers/relic_provider.dart';

// =============================================================================
// TowerPhase
// =============================================================================

enum TowerPhase { idle, fighting, floorCleared, defeated }

// =============================================================================
// TowerState
// =============================================================================

class TowerState {
  final TowerPhase phase;
  final int currentFloor;
  final int highestCleared;
  final int weeklyAttempts;
  final List<BattleMonster> playerTeam;
  final List<BattleMonster> enemyTeam;
  final List<BattleLogEntry> battleLog;
  final int currentTurn;
  final int turnWithinRound;
  final double battleSpeed;
  final bool isAutoMode;

  // Accumulated rewards for current run
  final int accGold;
  final int accExp;
  final int accDiamond;
  final int accTicket;

  const TowerState({
    this.phase = TowerPhase.idle,
    this.currentFloor = 0,
    this.highestCleared = 0,
    this.weeklyAttempts = 0,
    this.playerTeam = const [],
    this.enemyTeam = const [],
    this.battleLog = const [],
    this.currentTurn = 0,
    this.turnWithinRound = 0,
    this.battleSpeed = 1.0,
    this.isAutoMode = false,
    this.accGold = 0,
    this.accExp = 0,
    this.accDiamond = 0,
    this.accTicket = 0,
  });

  bool get canStartRun =>
      weeklyAttempts < TowerService.maxWeeklyAttempts &&
      phase == TowerPhase.idle;

  TowerState copyWith({
    TowerPhase? phase,
    int? currentFloor,
    int? highestCleared,
    int? weeklyAttempts,
    List<BattleMonster>? playerTeam,
    List<BattleMonster>? enemyTeam,
    List<BattleLogEntry>? battleLog,
    int? currentTurn,
    int? turnWithinRound,
    double? battleSpeed,
    bool? isAutoMode,
    int? accGold,
    int? accExp,
    int? accDiamond,
    int? accTicket,
  }) {
    return TowerState(
      phase: phase ?? this.phase,
      currentFloor: currentFloor ?? this.currentFloor,
      highestCleared: highestCleared ?? this.highestCleared,
      weeklyAttempts: weeklyAttempts ?? this.weeklyAttempts,
      playerTeam: playerTeam ?? this.playerTeam,
      enemyTeam: enemyTeam ?? this.enemyTeam,
      battleLog: battleLog ?? this.battleLog,
      currentTurn: currentTurn ?? this.currentTurn,
      turnWithinRound: turnWithinRound ?? this.turnWithinRound,
      battleSpeed: battleSpeed ?? this.battleSpeed,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      accGold: accGold ?? this.accGold,
      accExp: accExp ?? this.accExp,
      accDiamond: accDiamond ?? this.accDiamond,
      accTicket: accTicket ?? this.accTicket,
    );
  }
}

// =============================================================================
// TowerNotifier
// =============================================================================

class TowerNotifier extends StateNotifier<TowerState> {
  TowerNotifier(this.ref) : super(const TowerState()) {
    _loadProgress();
  }

  final Ref ref;
  static const _boxName = 'settings';

  void _loadProgress() {
    if (!Hive.isBoxOpen(_boxName)) return;
    final box = Hive.box(_boxName);

    final lastDate = box.get('towerLastDate') as DateTime?;
    if (TowerService.shouldResetWeekly(lastDate)) {
      // Weekly reset
      box.put('towerAttempts', 0);
      box.put('towerHighest', 0);
      box.put('towerLastDate', DateTime.now());
    }

    state = TowerState(
      weeklyAttempts: box.get('towerAttempts', defaultValue: 0) as int,
      highestCleared: box.get('towerHighest', defaultValue: 0) as int,
    );
  }

  void _saveProgress() {
    if (!Hive.isBoxOpen(_boxName)) return;
    final box = Hive.box(_boxName);
    box.put('towerAttempts', state.weeklyAttempts);
    box.put('towerHighest', state.highestCleared);
    box.put('towerLastDate', DateTime.now());
  }

  // ---------------------------------------------------------------------------
  // Start run
  // ---------------------------------------------------------------------------

  void startRun() {
    if (!state.canStartRun) return;

    final roster = ref.read(monsterListProvider);
    final result = BattleService.createPlayerTeam(
        roster.where((m) => m.isInTeam).toList());
    if (result.team.isEmpty) return;

    // Apply relic bonuses
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

    final enemies = TowerService.createEnemiesForFloor(1);

    state = state.copyWith(
      phase: TowerPhase.fighting,
      currentFloor: 1,
      weeklyAttempts: state.weeklyAttempts + 1,
      playerTeam: teamWithRelics,
      enemyTeam: enemies,
      battleLog: const [],
      currentTurn: 1,
      turnWithinRound: 0,
      accGold: 0,
      accExp: 0,
      accDiamond: 0,
      accTicket: 0,
    );
    _saveProgress();
  }

  // ---------------------------------------------------------------------------
  // Turn processing
  // ---------------------------------------------------------------------------

  void processTurn() {
    if (state.phase != TowerPhase.fighting) return;

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
        final targetInList = opposingTeam.cast<BattleMonster?>().firstWhere(
          (m) => m!.monsterId == target.monsterId,
          orElse: () => null,
        );
        if (targetInList != null) {
          final entry = BattleService.processSingleAttack(
            attacker: attacker,
            target: targetInList,
          );
          log.add(entry);
          AudioService.instance.playHit();
        }
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
      final reward = TowerService.getFloorReward(state.currentFloor);

      state = state.copyWith(
        phase: TowerPhase.floorCleared,
        playerTeam: playerTeam,
        enemyTeam: enemyTeam,
        battleLog: log,
        accGold: state.accGold + reward.gold,
        accExp: state.accExp + reward.exp,
        accDiamond: state.accDiamond + reward.diamond,
        accTicket: state.accTicket + reward.gachaTicket,
        highestCleared: state.currentFloor > state.highestCleared
            ? state.currentFloor
            : state.highestCleared,
      );
      _saveProgress();
      return;
    }

    if (endPhase == BattlePhase.defeat) {
      AudioService.instance.playDefeat();
      state = state.copyWith(
        phase: TowerPhase.defeated,
        playerTeam: playerTeam,
        enemyTeam: enemyTeam,
        battleLog: log,
      );
      return;
    }

    final nextSlot = slot + 1;
    final bool roundComplete = nextSlot >= roundSize;

    state = state.copyWith(
      playerTeam: playerTeam,
      enemyTeam: enemyTeam,
      battleLog: log,
      currentTurn: roundComplete ? state.currentTurn + 1 : state.currentTurn,
      turnWithinRound: roundComplete ? 0 : nextSlot,
    );
  }

  // ---------------------------------------------------------------------------
  // Advance floor (NO healing between floors!)
  // ---------------------------------------------------------------------------

  void advanceFloor() {
    if (state.phase != TowerPhase.floorCleared) return;
    if (state.currentFloor >= TowerService.maxFloor) {
      // Tower completed!
      return;
    }

    final nextFloor = state.currentFloor + 1;
    final playerTeam = _copyTeam(state.playerTeam);

    // NO healing between floors — only reset status effects
    for (final m in playerTeam) {
      if (m.isAlive) {
        m.burnTurns = 0;
        m.burnDamagePerTurn = 0;
        m.stunTurns = 0;
        m.skillCooldown = m.skillMaxCooldown;
      }
    }

    final enemies = TowerService.createEnemiesForFloor(nextFloor);

    state = state.copyWith(
      phase: TowerPhase.fighting,
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

    final playerData = ref.read(playerProvider).player;
    final multiplier = playerData != null
        ? PrestigeService.bonusMultiplier(playerData)
        : 1.0;

    if (state.accGold > 0) {
      await currency.addGold((state.accGold * multiplier).round());
    }
    if (state.accExp > 0) {
      await player.addPlayerExp((state.accExp * multiplier).round());
    }
    if (state.accDiamond > 0) {
      await currency.addDiamond(state.accDiamond);
    }
    if (state.accTicket > 0) {
      await currency.addGachaTicket(state.accTicket);
    }

    AudioService.instance.playRewardCollect();

    state = TowerState(
      weeklyAttempts: state.weeklyAttempts,
      highestCleared: state.highestCleared,
      battleSpeed: state.battleSpeed,
      isAutoMode: state.isAutoMode,
    );
    _saveProgress();
  }

  // ---------------------------------------------------------------------------
  // Speed / auto
  // ---------------------------------------------------------------------------

  void toggleSpeed() {
    const speeds = [1.0, 2.0, 3.0];
    final idx = speeds.indexWhere((s) => (s - state.battleSpeed).abs() < 0.01);
    state = state.copyWith(battleSpeed: speeds[(idx + 1) % speeds.length]);
  }

  void toggleAutoMode() {
    state = state.copyWith(isAutoMode: !state.isAutoMode);
  }

  List<BattleMonster> _copyTeam(List<BattleMonster> team) {
    return team.map((m) => m.copyWith()).toList();
  }
}

// =============================================================================
// Provider
// =============================================================================

final towerProvider =
    StateNotifierProvider<TowerNotifier, TowerState>(
  (ref) => TowerNotifier(ref),
);
