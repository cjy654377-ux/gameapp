import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/domain/services/arena_service.dart';
import 'package:gameapp/domain/services/audio_service.dart';
import 'package:gameapp/domain/services/battle_service.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';
import 'package:gameapp/presentation/providers/monster_provider.dart';
import 'package:gameapp/presentation/providers/player_provider.dart';
import 'package:gameapp/presentation/providers/relic_provider.dart';

// =============================================================================
// ArenaPhase
// =============================================================================

enum ArenaPhase {
  /// Browsing opponents.
  lobby,

  /// Battle in progress.
  fighting,

  /// Won the arena battle.
  victory,

  /// Lost the arena battle.
  defeat,
}

// =============================================================================
// ArenaState
// =============================================================================

class ArenaState {
  final ArenaPhase phase;
  final List<ArenaOpponent> opponents;
  final int selectedOpponentIndex;
  final List<BattleMonster> playerTeam;
  final List<BattleMonster> enemyTeam;
  final List<BattleLogEntry> battleLog;
  final int currentTurn;
  final int turnWithinRound;
  final double battleSpeed;
  final bool isAutoMode;

  /// Player's arena rating.
  final int rating;

  /// Total arena wins.
  final int totalWins;

  /// Total arena losses.
  final int totalLosses;

  /// Attempts used today.
  final int attemptsUsed;

  /// Date of last attempt (yyyy-MM-dd).
  final String lastAttemptDate;

  /// Reward from last fight (gold, diamond, ratingChange).
  final ({int gold, int diamond, int ratingChange})? lastReward;

  const ArenaState({
    this.phase = ArenaPhase.lobby,
    this.opponents = const [],
    this.selectedOpponentIndex = -1,
    this.playerTeam = const [],
    this.enemyTeam = const [],
    this.battleLog = const [],
    this.currentTurn = 0,
    this.turnWithinRound = 0,
    this.battleSpeed = 1.0,
    this.isAutoMode = false,
    this.rating = 1000,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.attemptsUsed = 0,
    this.lastAttemptDate = '',
    this.lastReward,
  });

  bool get canAttempt {
    final today = _todayStr();
    if (lastAttemptDate != today) return true;
    return attemptsUsed < ArenaService.maxDailyAttempts;
  }

  int get remainingAttempts {
    final today = _todayStr();
    if (lastAttemptDate != today) return ArenaService.maxDailyAttempts;
    return (ArenaService.maxDailyAttempts - attemptsUsed)
        .clamp(0, ArenaService.maxDailyAttempts);
  }

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  ArenaState copyWith({
    ArenaPhase? phase,
    List<ArenaOpponent>? opponents,
    int? selectedOpponentIndex,
    List<BattleMonster>? playerTeam,
    List<BattleMonster>? enemyTeam,
    List<BattleLogEntry>? battleLog,
    int? currentTurn,
    int? turnWithinRound,
    double? battleSpeed,
    bool? isAutoMode,
    int? rating,
    int? totalWins,
    int? totalLosses,
    int? attemptsUsed,
    String? lastAttemptDate,
    ({int gold, int diamond, int ratingChange})? lastReward,
    bool clearReward = false,
  }) {
    return ArenaState(
      phase: phase ?? this.phase,
      opponents: opponents ?? this.opponents,
      selectedOpponentIndex:
          selectedOpponentIndex ?? this.selectedOpponentIndex,
      playerTeam: playerTeam ?? this.playerTeam,
      enemyTeam: enemyTeam ?? this.enemyTeam,
      battleLog: battleLog ?? this.battleLog,
      currentTurn: currentTurn ?? this.currentTurn,
      turnWithinRound: turnWithinRound ?? this.turnWithinRound,
      battleSpeed: battleSpeed ?? this.battleSpeed,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      rating: rating ?? this.rating,
      totalWins: totalWins ?? this.totalWins,
      totalLosses: totalLosses ?? this.totalLosses,
      attemptsUsed: attemptsUsed ?? this.attemptsUsed,
      lastAttemptDate: lastAttemptDate ?? this.lastAttemptDate,
      lastReward: clearReward ? null : (lastReward ?? this.lastReward),
    );
  }
}

// =============================================================================
// ArenaNotifier
// =============================================================================

class ArenaNotifier extends StateNotifier<ArenaState> {
  ArenaNotifier(this.ref) : super(const ArenaState());

  final Ref ref;

  // ---------------------------------------------------------------------------
  // Refresh opponents
  // ---------------------------------------------------------------------------

  void refreshOpponents() {
    final playerLevel =
        ref.read(playerProvider).player?.playerLevel ?? 1;
    final opponents = ArenaService.generateOpponents(
      playerLevel: playerLevel,
      playerRating: state.rating,
    );
    state = state.copyWith(
      opponents: opponents,
      phase: ArenaPhase.lobby,
    );
  }

  // ---------------------------------------------------------------------------
  // Start fight
  // ---------------------------------------------------------------------------

  void startFight(int opponentIndex) {
    if (!state.canAttempt) return;
    if (opponentIndex < 0 || opponentIndex >= state.opponents.length) return;

    final opponent = state.opponents[opponentIndex];

    // Build player team.
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

    final today = ArenaState._todayStr();
    final attemptsUsed =
        state.lastAttemptDate == today ? state.attemptsUsed + 1 : 1;

    state = state.copyWith(
      phase: ArenaPhase.fighting,
      selectedOpponentIndex: opponentIndex,
      playerTeam: teamWithRelics,
      enemyTeam: List.from(opponent.team),
      battleLog: const [],
      currentTurn: 1,
      turnWithinRound: 0,
      attemptsUsed: attemptsUsed,
      lastAttemptDate: today,
    );
  }

  // ---------------------------------------------------------------------------
  // Turn processing
  // ---------------------------------------------------------------------------

  void processTurn() {
    if (state.phase != ArenaPhase.fighting) return;

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

    // Skill or attack.
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
      final idx = state.selectedOpponentIndex;
      if (idx < 0 || idx >= state.opponents.length) return;
      final opponent = state.opponents[idx];
      final newRating = state.rating + opponent.ratingGain;
      state = state.copyWith(
        phase: ArenaPhase.victory,
        playerTeam: playerTeam,
        enemyTeam: enemyTeam,
        battleLog: log,
        rating: newRating,
        totalWins: state.totalWins + 1,
        lastReward: (
          gold: opponent.rewardGold,
          diamond: opponent.rewardDiamond,
          ratingChange: opponent.ratingGain,
        ),
      );
      return;
    }

    if (endPhase == BattlePhase.defeat) {
      AudioService.instance.playDefeat();
      final defeatIdx = state.selectedOpponentIndex.clamp(0, 2);
      final loss = ArenaService.ratingLoss(defeatIdx);
      final newRating = (state.rating + loss).clamp(0, 99999);
      state = state.copyWith(
        phase: ArenaPhase.defeat,
        playerTeam: playerTeam,
        enemyTeam: enemyTeam,
        battleLog: log,
        rating: newRating,
        totalLosses: state.totalLosses + 1,
        lastReward: (gold: 0, diamond: 0, ratingChange: loss),
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

  // ---------------------------------------------------------------------------
  // Collect reward and return to lobby
  // ---------------------------------------------------------------------------

  Future<void> collectAndReturn() async {
    final reward = state.lastReward;
    if (reward != null && reward.gold > 0) {
      await ref.read(currencyProvider.notifier).addGold(reward.gold);
    }
    if (reward != null && reward.diamond > 0) {
      await ref.read(currencyProvider.notifier).addDiamond(reward.diamond);
    }
    AudioService.instance.playRewardCollect();

    // Refresh opponents and return to lobby.
    refreshOpponents();
  }

  /// Return to lobby after defeat.
  void returnToLobby() {
    refreshOpponents();
  }

  // ---------------------------------------------------------------------------
  // Speed / auto
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

final arenaProvider =
    StateNotifierProvider<ArenaNotifier, ArenaState>(
  (ref) => ArenaNotifier(ref),
);
