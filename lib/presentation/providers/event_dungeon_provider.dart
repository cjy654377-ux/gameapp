import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/domain/services/audio_service.dart';
import 'package:gameapp/domain/services/battle_service.dart';
import 'package:gameapp/domain/services/event_dungeon_service.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';
import 'package:gameapp/presentation/providers/monster_provider.dart';
import 'package:gameapp/presentation/providers/player_provider.dart';
import 'package:gameapp/presentation/providers/relic_provider.dart';

// =============================================================================
// EventDungeonPhase
// =============================================================================

enum EventDungeonPhase {
  lobby,
  fighting,
  waveCleared,
  victory,
  defeat,
}

// =============================================================================
// EventDungeonState
// =============================================================================

class EventDungeonState {
  final EventDungeonPhase phase;
  final List<EventDungeon> events;
  final EventDungeon? selectedEvent;
  final int currentWave;
  final List<BattleMonster> playerTeam;
  final List<BattleMonster> enemyTeam;
  final List<BattleLogEntry> battleLog;
  final int currentTurn;
  final int turnWithinRound;
  final double battleSpeed;
  final bool isAutoMode;

  /// Tracks which events have been cleared today (by event ID).
  final Set<String> clearedToday;
  final String lastClearedDate;

  const EventDungeonState({
    this.phase = EventDungeonPhase.lobby,
    this.events = const [],
    this.selectedEvent,
    this.currentWave = 0,
    this.playerTeam = const [],
    this.enemyTeam = const [],
    this.battleLog = const [],
    this.currentTurn = 0,
    this.turnWithinRound = 0,
    this.battleSpeed = 1.0,
    this.isAutoMode = false,
    this.clearedToday = const {},
    this.lastClearedDate = '',
  });

  bool canAttempt(String eventId) {
    final today = _todayStr();
    if (lastClearedDate != today) return true;
    return !clearedToday.contains(eventId);
  }

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  EventDungeonState copyWith({
    EventDungeonPhase? phase,
    List<EventDungeon>? events,
    EventDungeon? selectedEvent,
    bool clearEvent = false,
    int? currentWave,
    List<BattleMonster>? playerTeam,
    List<BattleMonster>? enemyTeam,
    List<BattleLogEntry>? battleLog,
    int? currentTurn,
    int? turnWithinRound,
    double? battleSpeed,
    bool? isAutoMode,
    Set<String>? clearedToday,
    String? lastClearedDate,
  }) {
    return EventDungeonState(
      phase: phase ?? this.phase,
      events: events ?? this.events,
      selectedEvent:
          clearEvent ? null : (selectedEvent ?? this.selectedEvent),
      currentWave: currentWave ?? this.currentWave,
      playerTeam: playerTeam ?? this.playerTeam,
      enemyTeam: enemyTeam ?? this.enemyTeam,
      battleLog: battleLog ?? this.battleLog,
      currentTurn: currentTurn ?? this.currentTurn,
      turnWithinRound: turnWithinRound ?? this.turnWithinRound,
      battleSpeed: battleSpeed ?? this.battleSpeed,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      clearedToday: clearedToday ?? this.clearedToday,
      lastClearedDate: lastClearedDate ?? this.lastClearedDate,
    );
  }
}

// =============================================================================
// EventDungeonNotifier
// =============================================================================

class EventDungeonNotifier extends StateNotifier<EventDungeonState> {
  EventDungeonNotifier(this.ref) : super(const EventDungeonState());

  final Ref ref;

  void loadEvents() {
    final events = EventDungeonService.getActiveEvents();
    state = state.copyWith(events: events);
  }

  void startEvent(EventDungeon event) {
    if (!state.canAttempt(event.id)) return;

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

    final enemies = EventDungeonService.createEnemies(
      element: event.element,
      wave: 1,
      totalWaves: event.stages,
      recommendedLevel: event.recommendedLevel,
    );

    state = state.copyWith(
      phase: EventDungeonPhase.fighting,
      selectedEvent: event,
      currentWave: 1,
      playerTeam: teamWithRelics,
      enemyTeam: enemies,
      battleLog: const [],
      currentTurn: 1,
      turnWithinRound: 0,
    );
  }

  void processTurn() {
    if (state.phase != EventDungeonPhase.fighting) return;

    final playerTeam = _copyTeam(state.playerTeam);
    final enemyTeam = _copyTeam(state.enemyTeam);

    final allAlive =
        BattleService.getTurnOrder([...playerTeam, ...enemyTeam]);
    if (allAlive.isEmpty) return;

    int slot = state.turnWithinRound;
    if (slot >= allAlive.length) slot = 0;

    final attacker = allAlive[slot];
    final bool isPlayerMonster =
        playerTeam.any((m) => m.monsterId == attacker.monsterId);

    final log = List<BattleLogEntry>.from(state.battleLog);
    if (log.length > 50) log.removeRange(0, log.length - 50);

    // Burn.
    final burnEntry = BattleService.processBurn(attacker);
    if (burnEntry != null) log.add(burnEntry);
    if (!attacker.isAlive) {
      _emitState(playerTeam, enemyTeam, log, slot, allAlive.length);
      return;
    }

    // Stun.
    final stunEntry = BattleService.processStun(attacker);
    if (stunEntry != null) {
      log.add(stunEntry);
      BattleService.tickSkillCooldown(attacker);
      _emitState(playerTeam, enemyTeam, log, slot, allAlive.length);
      return;
    }

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
    final event = state.selectedEvent;
    if (event == null) return;

    if (endPhase == BattlePhase.victory) {
      AudioService.instance.playVictory();
      if (state.currentWave >= event.stages) {
        // All waves cleared!
        state = state.copyWith(
          phase: EventDungeonPhase.victory,
          playerTeam: playerTeam,
          enemyTeam: enemyTeam,
          battleLog: log,
        );
      } else {
        // Wave cleared, more to go.
        state = state.copyWith(
          phase: EventDungeonPhase.waveCleared,
          playerTeam: playerTeam,
          enemyTeam: enemyTeam,
          battleLog: log,
        );
      }
      return;
    }

    if (endPhase == BattlePhase.defeat) {
      AudioService.instance.playDefeat();
      state = state.copyWith(
        phase: EventDungeonPhase.defeat,
        playerTeam: playerTeam,
        enemyTeam: enemyTeam,
        battleLog: log,
      );
      return;
    }

    final nextSlot = slot + 1;
    final roundComplete = nextSlot >= roundSize;
    final newTurn =
        roundComplete ? state.currentTurn + 1 : state.currentTurn;
    final newSlot = roundComplete ? 0 : nextSlot;

    state = state.copyWith(
      playerTeam: playerTeam,
      enemyTeam: enemyTeam,
      battleLog: log,
      currentTurn: newTurn,
      turnWithinRound: newSlot,
    );
  }

  void advanceWave() {
    if (state.phase != EventDungeonPhase.waveCleared) return;
    final event = state.selectedEvent;
    if (event == null) return;
    final nextWave = state.currentWave + 1;

    // Heal 15% between waves.
    final playerTeam = _copyTeam(state.playerTeam);
    for (final m in playerTeam) {
      if (m.isAlive) {
        final heal = m.maxHp * 0.15;
        m.currentHp = (m.currentHp + heal).clamp(0, m.maxHp);
        // Reset status effects.
        m.burnTurns = 0;
        m.stunTurns = 0;
      }
    }

    final enemies = EventDungeonService.createEnemies(
      element: event.element,
      wave: nextWave,
      totalWaves: event.stages,
      recommendedLevel: event.recommendedLevel,
    );

    state = state.copyWith(
      phase: EventDungeonPhase.fighting,
      currentWave: nextWave,
      playerTeam: playerTeam,
      enemyTeam: enemies,
      battleLog: const [],
      currentTurn: 1,
      turnWithinRound: 0,
    );
  }

  Future<void> collectReward() async {
    final event = state.selectedEvent;
    if (event == null) return;

    final currency = ref.read(currencyProvider.notifier);
    final player = ref.read(playerProvider.notifier);

    if (event.rewardGold > 0) await currency.addGold(event.rewardGold);
    if (event.rewardDiamond > 0) {
      await currency.addDiamond(event.rewardDiamond);
    }
    if (event.rewardExpPotions > 0) {
      await currency.addExpPotion(event.rewardExpPotions);
    }
    if (event.rewardGachaTickets > 0) {
      await currency.addGachaTicket(event.rewardGachaTickets);
    }
    // Player exp based on event difficulty (gold reward as proxy, scaled down).
    final playerExp = (event.rewardGold * 0.3).round();
    if (playerExp > 0) await player.addPlayerExp(playerExp);

    AudioService.instance.playRewardCollect();

    // Mark as cleared today.
    final today = EventDungeonState._todayStr();
    final newCleared = state.lastClearedDate == today
        ? {...state.clearedToday, event.id}
        : {event.id};

    state = state.copyWith(
      phase: EventDungeonPhase.lobby,
      clearEvent: true,
      clearedToday: newCleared,
      lastClearedDate: today,
    );
  }

  void returnToLobby() {
    state = state.copyWith(
      phase: EventDungeonPhase.lobby,
      clearEvent: true,
    );
  }

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

  List<BattleMonster> _copyTeam(List<BattleMonster> team) {
    return team.map((m) => m.copyWith()).toList();
  }
}

// =============================================================================
// Provider
// =============================================================================

final eventDungeonProvider =
    StateNotifierProvider<EventDungeonNotifier, EventDungeonState>(
  (ref) => EventDungeonNotifier(ref),
);
