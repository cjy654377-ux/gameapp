import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gameapp/data/static/stage_database.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/domain/entities/synergy.dart';
import 'package:gameapp/domain/services/battle_service.dart';
import 'package:gameapp/data/static/quest_database.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';
import 'package:gameapp/presentation/providers/monster_provider.dart';
import 'package:gameapp/presentation/providers/player_provider.dart';
import 'package:gameapp/domain/services/prestige_service.dart';
import 'package:gameapp/presentation/providers/quest_provider.dart';
import 'package:gameapp/domain/services/audio_service.dart';
import 'package:gameapp/presentation/providers/relic_provider.dart';
import 'package:gameapp/presentation/providers/season_pass_provider.dart';
import 'package:gameapp/presentation/providers/battle_replay_provider.dart';

// ---------------------------------------------------------------------------
// Internal helpers — delegate to StageDatabase shared utilities.
// ---------------------------------------------------------------------------

String _stageIndexToKey(int stageId) => StageDatabase.linearIdToKey(stageId);
int _stageStringToIndex(String stageId) =>
    StageDatabase.linearIndex(stageId, defaultValue: 1);

// =============================================================================
// BattleState
// =============================================================================

/// Complete, immutable snapshot of the battle system at any given moment.
class BattleState {
  /// Current lifecycle phase of the battle.
  final BattlePhase phase;

  /// Player's team as battle-ready snapshots.
  final List<BattleMonster> playerTeam;

  /// Enemy team for the current stage.
  final List<BattleMonster> enemyTeam;

  /// Ordered log of attack events that have occurred so far.
  final List<BattleLogEntry> battleLog;

  /// Current round number (increments each time every surviving monster has
  /// taken one turn).
  final int currentTurn;

  /// Index into the current round's turn order — i.e. which monster is next to
  /// act within this round.
  final int turnWithinRound;

  /// Playback speed multiplier displayed to the player.
  ///
  /// Stored as a double (1.0, 2.0, or 3.0) to match what the `_SpeedButton`
  /// widget expects.  Set directly via [BattleNotifier.setBattleSpeed] (pass
  /// 1, 2 or 3) or cycled via [BattleNotifier.toggleSpeed].
  final double battleSpeed;

  /// When `true` the battle advances automatically without waiting for a
  /// manual "next turn" prompt.
  final bool isAutoMode;

  /// The 1-based linear stage index currently being fought.
  final int currentStageId;

  /// Korean display name of the current stage (e.g. `'2-3 끓어오르는 분화구'`).
  final String currentStageName;

  /// Reward snapshot set when a [BattlePhase.victory] phase is reached.
  /// Cleared (reset to `null`) after [BattleNotifier.collectReward] is called.
  final BattleReward? lastReward;

  /// Synergies active for the current player team.
  final List<SynergyEffect> activeSynergies;

  /// When `true`, after victory the battle automatically collects rewards
  /// and starts the next battle without showing the victory dialog.
  final bool isRepeatMode;

  /// Number of victories accumulated during the current repeat session.
  final int repeatCount;

  /// Accumulated gold earned during the current repeat session.
  final int repeatTotalGold;

  /// Accumulated exp earned during the current repeat session.
  final int repeatTotalExp;

  const BattleState({
    this.phase            = BattlePhase.idle,
    this.playerTeam       = const [],
    this.enemyTeam        = const [],
    this.battleLog        = const [],
    this.currentTurn      = 0,
    this.turnWithinRound  = 0,
    this.battleSpeed      = 1.0,
    this.isAutoMode       = true,
    this.currentStageId   = 1,
    this.currentStageName = '',
    this.lastReward,
    this.activeSynergies  = const [],
    this.isRepeatMode     = true,
    this.repeatCount      = 0,
    this.repeatTotalGold  = 0,
    this.repeatTotalExp   = 0,
  });

  BattleState copyWith({
    BattlePhase?        phase,
    List<BattleMonster>? playerTeam,
    List<BattleMonster>? enemyTeam,
    List<BattleLogEntry>? battleLog,
    int?                currentTurn,
    int?                turnWithinRound,
    double?             battleSpeed,
    bool?               isAutoMode,
    int?                currentStageId,
    String?             currentStageName,
    BattleReward?       lastReward,
    bool                clearReward = false,
    List<SynergyEffect>? activeSynergies,
    bool?               isRepeatMode,
    int?                repeatCount,
    int?                repeatTotalGold,
    int?                repeatTotalExp,
  }) {
    return BattleState(
      phase:            phase            ?? this.phase,
      playerTeam:       playerTeam       ?? this.playerTeam,
      enemyTeam:        enemyTeam        ?? this.enemyTeam,
      battleLog:        battleLog        ?? this.battleLog,
      currentTurn:      currentTurn      ?? this.currentTurn,
      turnWithinRound:  turnWithinRound  ?? this.turnWithinRound,
      battleSpeed:      battleSpeed      ?? this.battleSpeed,
      isAutoMode:       isAutoMode       ?? this.isAutoMode,
      currentStageId:   currentStageId   ?? this.currentStageId,
      currentStageName: currentStageName ?? this.currentStageName,
      lastReward:       clearReward ? null : (lastReward ?? this.lastReward),
      activeSynergies:  activeSynergies  ?? this.activeSynergies,
      isRepeatMode:     isRepeatMode     ?? this.isRepeatMode,
      repeatCount:      repeatCount      ?? this.repeatCount,
      repeatTotalGold:  repeatTotalGold  ?? this.repeatTotalGold,
      repeatTotalExp:   repeatTotalExp   ?? this.repeatTotalExp,
    );
  }

  @override
  String toString() =>
      'BattleState(phase: $phase, turn: $currentTurn, '
      'stageId: $currentStageId, speed: ${battleSpeed}x, '
      'auto: $isAutoMode)';
}

// =============================================================================
// BattleNotifier
// =============================================================================

/// Orchestrates the entire battle lifecycle.
///
/// Depends on [playerProvider], [monsterListProvider], and [currencyProvider]
/// through [Ref] so it can read and mutate cross-cutting concerns such as
/// adding gold, updating the player's stage progress, and applying experience
/// to the team after a victory.
class BattleNotifier extends StateNotifier<BattleState> {
  BattleNotifier(this.ref) : super(const BattleState());

  /// Reference to the Riverpod container — used to read/write other providers.
  final Ref ref;

  Timer? _autoTimer;

  @override
  void dispose() {
    _stopAutoTimer();
    super.dispose();
  }

  /// Starts a periodic timer that calls [processTurn] automatically.
  void _startAutoTimer() {
    _stopAutoTimer();
    final ms = (800 / state.battleSpeed).round();
    _autoTimer = Timer.periodic(Duration(milliseconds: ms), (_) {
      if (state.phase == BattlePhase.fighting) {
        processTurn();
      } else {
        _stopAutoTimer();
      }
    });
  }

  void _stopAutoTimer() {
    _autoTimer?.cancel();
    _autoTimer = null;
  }

  // ---------------------------------------------------------------------------
  // Battle start
  // ---------------------------------------------------------------------------

  /// Starts a battle for the given [stageId] (1-based linear index).
  ///
  /// When [stageId] is not provided (or is zero), the current stage stored in
  /// [playerProvider] is used.  This allows the UI to call
  /// `notifier.startBattle()` without knowing the stage explicitly.
  ///
  /// Reads the current team from [monsterListProvider], builds both teams via
  /// [BattleService], and transitions to [BattlePhase.fighting].
  ///
  /// Does nothing when the player has no monsters in their team.
  void startBattle([int stageId = 0]) {
    // Resolve the stage index — fall back to current state or player stage.
    int resolvedId = stageId;
    if (resolvedId <= 0) {
      // Try to use the stage already stored in BattleState.
      resolvedId = state.currentStageId > 0 ? state.currentStageId : 1;

      // Prefer the player's actual current stage when available.
      final playerState = ref.read(playerProvider);
      final playerStageStr = playerState.player?.currentStageId;
      if (playerStageStr != null && playerStageStr.isNotEmpty) {
        resolvedId = _stageStringToIndex(playerStageStr);
      }
    }

    // Resolve stage data.
    final stageKey  = _stageIndexToKey(resolvedId);
    final stageData = StageDatabase.findById(stageKey);
    if (stageData == null) return;

    // Build player team from the current roster (with synergy bonuses applied).
    final roster = ref.read(monsterListProvider);
    final result = BattleService.createPlayerTeam(
        roster.where((m) => m.isInTeam).toList());
    if (result.team.isEmpty) return;

    // Apply relic bonuses to each team member.
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

    // Build enemy team.
    final enemyTeam = BattleService.createEnemiesForStage(resolvedId);

    state = BattleState(
      phase:            BattlePhase.fighting,
      playerTeam:       teamWithRelics,
      enemyTeam:        enemyTeam,
      activeSynergies:  result.synergies,
      battleLog:        const [],
      currentTurn:      1,
      turnWithinRound:  0,
      battleSpeed:      state.battleSpeed,
      isAutoMode:       state.isAutoMode,
      isRepeatMode:     state.isRepeatMode,
      currentStageId:   resolvedId,
      currentStageName: stageData.name,
      lastReward:       null,
    );

    // Auto-battle: always start the timer (idle game).
    _startAutoTimer();
  }

  // ---------------------------------------------------------------------------
  // Turn processing
  // ---------------------------------------------------------------------------

  /// Processes exactly one action for the current acting monster.
  ///
  /// Turn flow:
  /// 1. Apply burn damage (DoT) at the start of the monster's turn.
  /// 2. Check stun — if stunned, skip the action.
  /// 3. Tick skill cooldown, then either activate skill or do a normal attack.
  /// 4. Check win conditions.
  ///
  /// Call this method from a periodic timer (e.g. every [1 / battleSpeed]
  /// seconds in auto mode, or on a manual "Next" button press).
  void processTurn() {
    if (state.phase != BattlePhase.fighting) return;

    // Deep-copy team lists so we can mutate without aliasing issues.
    final playerTeam = _copyTeam(state.playerTeam);
    final enemyTeam  = _copyTeam(state.enemyTeam);

    // Build the full speed-sorted turn order for this round.
    final allAlive = BattleService.getTurnOrder([...playerTeam, ...enemyTeam]);
    if (allAlive.isEmpty) return;

    // Determine which slot in the round we are at, wrapping if necessary.
    int slot = state.turnWithinRound;
    if (slot >= allAlive.length) slot = 0;

    final attacker = allAlive[slot];

    // Determine whether this monster belongs to the player or enemy team.
    final bool isPlayerMonster =
        playerTeam.any((m) => m.monsterId == attacker.monsterId);

    final log = List<BattleLogEntry>.from(state.battleLog);
    // Trim log to prevent unbounded memory growth.
    if (log.length > 50) log.removeRange(0, log.length - 50);

    // -- 1. Passive: turn-start (HP regen) ------------------------------------
    final passiveEntry = BattleService.processPassiveTurnStart(attacker);
    if (passiveEntry != null) log.add(passiveEntry);

    // -- 2. Burn damage (DoT) at turn start -----------------------------------
    final burnEntry = BattleService.processBurn(attacker);
    if (burnEntry != null) log.add(burnEntry);

    // Check if burn killed the monster before it can act.
    if (!attacker.isAlive) {
      _emitState(playerTeam, enemyTeam, log, slot, allAlive.length);
      return;
    }

    // -- 3. Stun check --------------------------------------------------------
    final stunEntry = BattleService.processStun(attacker);
    if (stunEntry != null) {
      log.add(stunEntry);
      // Tick cooldown even when stunned.
      BattleService.tickSkillCooldown(attacker);
      _emitState(playerTeam, enemyTeam, log, slot, allAlive.length);
      return;
    }

    // -- 4. Tick cooldown, then act -------------------------------------------
    BattleService.tickSkillCooldown(attacker);

    // Check ultimate first (highest priority)
    if (attacker.isUltimateReady) {
      AudioService.instance.playSkillActivation();
      final ultLogs = BattleService.processUltimate(
        caster: attacker,
        playerTeam: playerTeam,
        enemyTeam: enemyTeam,
        isCasterPlayer: isPlayerMonster,
      );
      log.addAll(ultLogs);
    } else if (attacker.isSkillReady) {
      // Skill activation.
      AudioService.instance.playSkillActivation();
      final skillLogs = BattleService.processSkill(
        caster: attacker,
        playerTeam: playerTeam,
        enemyTeam: enemyTeam,
        isCasterPlayer: isPlayerMonster,
      );
      log.addAll(skillLogs);
      // Charge ultimate from skill damage
      final totalDmg = skillLogs.fold<double>(0, (s, e) => s + e.damage);
      BattleService.chargeUltimate(attacker, totalDmg);
    } else {
      // Normal attack.
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
        // Charge ultimate from normal attack damage
        BattleService.chargeUltimate(attacker, entry.damage);
        // Passive counter-attack
        final counterEntry = BattleService.processPassiveCounter(targetInList, attacker);
        if (counterEntry != null) log.add(counterEntry);
      }
    }

    // -- 4. Emit new state & check end conditions -----------------------------
    _emitState(playerTeam, enemyTeam, log, slot, allAlive.length);
  }

  /// Shared helper to emit a new state after a turn action, checking end
  /// conditions and advancing the slot/round counter.
  void _emitState(
    List<BattleMonster> playerTeam,
    List<BattleMonster> enemyTeam,
    List<BattleLogEntry> log,
    int slot,
    int roundSize,
  ) {
    // Check end conditions.
    final endPhase = BattleService.checkBattleEnd(playerTeam, enemyTeam);

    if (endPhase == BattlePhase.victory) {
      AudioService.instance.playVictory();
      final reward = BattleService.calculateReward(state.currentStageId);
      state = state.copyWith(
        phase:      BattlePhase.victory,
        playerTeam: playerTeam,
        enemyTeam:  enemyTeam,
        battleLog:  log,
        lastReward: reward,
      );

      // Save replay record.
      _saveReplay(log, true);

      // Auto-collect and restart in repeat mode.
      if (state.isRepeatMode) {
        Future.delayed(const Duration(milliseconds: 300), () {
          // Guard: only auto-collect if still in victory with uncollected reward.
          if (state.phase == BattlePhase.victory &&
              state.isRepeatMode &&
              state.lastReward != null) {
            collectReward();
          }
        });
      }
      return;
    }

    if (endPhase == BattlePhase.defeat) {
      AudioService.instance.playDefeat();
      state = state.copyWith(
        phase:      BattlePhase.defeat,
        playerTeam: playerTeam,
        enemyTeam:  enemyTeam,
        battleLog:  log,
        isRepeatMode: false, // Stop repeat on defeat.
      );

      // Save replay record.
      _saveReplay(log, false);
      return;
    }

    // Advance slot / round.
    final nextSlot = slot + 1;
    final bool roundComplete = nextSlot >= roundSize;
    final int  newTurn = roundComplete
        ? state.currentTurn + 1
        : state.currentTurn;
    final int  newSlot = roundComplete ? 0 : nextSlot;

    state = state.copyWith(
      playerTeam:      playerTeam,
      enemyTeam:       enemyTeam,
      battleLog:       log,
      currentTurn:     newTurn,
      turnWithinRound: newSlot,
    );
  }

  // ---------------------------------------------------------------------------
  // Speed & auto mode controls
  // ---------------------------------------------------------------------------

  /// Sets the battle speed.  [speed] should be 1, 2, or 3 (int or double).
  ///
  /// The value is stored as a `double` (1.0 / 2.0 / 3.0) to match what the
  /// speed button widget compares against.  Values outside [1, 3] are clamped.
  void setBattleSpeed(num speed) {
    final clamped = speed.clamp(1, 3).toDouble();
    state = state.copyWith(battleSpeed: clamped);
    if (state.phase == BattlePhase.fighting) _startAutoTimer();
  }

  /// Cycles the speed multiplier: 1.0 → 2.0 → 3.0 → 1.0.
  void toggleSpeed() {
    const speeds  = [1.0, 2.0, 3.0];
    final current = state.battleSpeed;
    final idx = speeds.indexWhere((s) => (s - current).abs() < 0.01);
    final nextIdx = (idx + 1) % speeds.length;
    state = state.copyWith(battleSpeed: speeds[nextIdx]);
    if (state.phase == BattlePhase.fighting) _startAutoTimer();
  }

  /// Flips [BattleState.isAutoMode] between `true` and `false`.
  void toggleAutoMode() {
    state = state.copyWith(isAutoMode: !state.isAutoMode);
  }

  /// Alias kept for backwards compatibility.
  void toggleAuto() => toggleAutoMode();

  /// Toggles repeat mode: auto-collect rewards + restart battle after victory.
  void toggleRepeatMode() {
    final newRepeat = !state.isRepeatMode;
    state = state.copyWith(
      isRepeatMode: newRepeat,
      // Enable auto mode too when repeat is on.
      isAutoMode: newRepeat ? true : state.isAutoMode,
      // Reset counters when enabling.
      repeatCount: newRepeat ? 0 : state.repeatCount,
      repeatTotalGold: newRepeat ? 0 : state.repeatTotalGold,
      repeatTotalExp: newRepeat ? 0 : state.repeatTotalExp,
    );
  }

  /// Stops repeat mode.
  void stopRepeat() {
    state = state.copyWith(isRepeatMode: false);
  }

  // ---------------------------------------------------------------------------
  // Reward collection
  // ---------------------------------------------------------------------------

  /// Distributes [BattleState.lastReward] to the player and transitions to the
  /// next stage.
  ///
  /// * Adds gold to [currencyProvider].
  /// * Adds any bonus shard to [currencyProvider].
  /// * Adds player experience via [playerProvider].
  /// * Advances [playerProvider] current stage.
  /// * Clears the reward from state.
  ///
  /// If [isAutoMode] is enabled the next battle starts immediately via
  /// [_advanceToNextStage]; otherwise the phase returns to [BattlePhase.idle].
  Future<void> collectReward() async {
    final reward = state.lastReward;
    if (reward == null) return;

    final currency = ref.read(currencyProvider.notifier);
    final player   = ref.read(playerProvider.notifier);

    // Apply prestige bonus multiplier to gold and exp.
    final playerData = ref.read(playerProvider).player;
    final multiplier = playerData != null
        ? PrestigeService.bonusMultiplier(playerData)
        : 1.0;
    final bonusGold = (reward.gold * multiplier).round();
    final bonusExp = (reward.exp * multiplier).round();

    // Award gold (with prestige bonus).
    await currency.addGold(bonusGold);

    // Award bonus shard (if any).
    if (reward.bonusShard != null) {
      await currency.addShard(reward.bonusShard!);
    }

    // Award player experience (with prestige bonus).
    await player.addPlayerExp(bonusExp);

    // Mark stage as cleared and advance to next.
    final clearedStageKey = _stageIndexToKey(state.currentStageId);
    final currentPlayer = ref.read(playerProvider).player;
    final wasNewClear = currentPlayer != null &&
        _stageStringToIndex(clearedStageKey) >
            _stageStringToIndex(currentPlayer.maxClearedStageId);
    await player.updateStage(clearedStageKey);
    await player.addBattleCount();

    // Increment affinity (battle count) for team monsters.
    final teamIds = ref.read(monsterListProvider)
        .where((m) => m.isInTeam)
        .map((m) => m.id)
        .toList();
    await ref.read(monsterListProvider.notifier).incrementBattleCounts(teamIds);

    // Quest triggers: battleWin + stageFirstClear.
    final questNotifier = ref.read(questProvider.notifier);
    await questNotifier.onTrigger(QuestTrigger.battleWin);
    if (wasNewClear) {
      await questNotifier.onTrigger(QuestTrigger.stageFirstClear);
    }

    // Season pass XP: +20 per battle win, +50 for first clear.
    ref.read(seasonPassProvider.notifier).addXp(wasNewClear ? 50 : 20);

    AudioService.instance.playRewardCollect();

    // Advance tutorial: after first reward → show gacha hint.
    final tutorialStep = playerData?.tutorialStep ?? 0;
    if (tutorialStep <= 1) {
      await player.advanceTutorial(2); // → gachaIntro
    }

    // Track repeat rewards.
    final newRepeatCount = state.repeatCount + (state.isRepeatMode ? 1 : 0);
    final newRepeatGold = state.repeatTotalGold + (state.isRepeatMode ? bonusGold : 0);
    final newRepeatExp = state.repeatTotalExp + (state.isRepeatMode ? bonusExp : 0);

    // Clear reward from state.
    state = state.copyWith(
      clearReward: true,
      repeatCount: newRepeatCount,
      repeatTotalGold: newRepeatGold,
      repeatTotalExp: newRepeatExp,
    );

    // Auto-advance or return to idle.
    if (state.isRepeatMode || state.isAutoMode) {
      _advanceToNextStage();
    } else {
      state = state.copyWith(phase: BattlePhase.idle);
    }
  }

  // ---------------------------------------------------------------------------
  // Skip battle (cleared stages only)
  // ---------------------------------------------------------------------------

  /// Skips battle for an already-cleared stage and directly awards rewards.
  /// Returns the reward if successful, null otherwise.
  Future<BattleReward?> skipBattle(int stageIdx) async {
    final playerData = ref.read(playerProvider).player;
    if (playerData == null) return null;

    // Only cleared stages can be skipped.
    final maxClearedIdx = _stageStringToIndex(playerData.maxClearedStageId);
    if (stageIdx > maxClearedIdx || stageIdx <= 0) return null;

    // Calculate reward.
    final reward = BattleService.calculateReward(stageIdx);

    final currency = ref.read(currencyProvider.notifier);
    final player = ref.read(playerProvider.notifier);

    // Apply prestige bonus.
    final multiplier = PrestigeService.bonusMultiplier(playerData);
    final bonusGold = (reward.gold * multiplier).round();
    final bonusExp = (reward.exp * multiplier).round();

    await currency.addGold(bonusGold);
    if (reward.bonusShard != null) {
      await currency.addShard(reward.bonusShard!);
    }
    await player.addPlayerExp(bonusExp);
    await player.addBattleCount();

    // Increment affinity for team monsters.
    final teamIds = ref.read(monsterListProvider)
        .where((m) => m.isInTeam)
        .map((m) => m.id)
        .toList();
    await ref.read(monsterListProvider.notifier).incrementBattleCounts(teamIds);

    // Quest + season pass triggers.
    final questNotifier = ref.read(questProvider.notifier);
    await questNotifier.onTrigger(QuestTrigger.battleWin);
    ref.read(seasonPassProvider.notifier).addXp(20);

    AudioService.instance.playRewardCollect();

    return BattleReward(
      gold: bonusGold,
      exp: bonusExp,
      bonusShard: reward.bonusShard,
    );
  }

  // ---------------------------------------------------------------------------
  // Retreat
  // ---------------------------------------------------------------------------

  /// Aborts the current battle and returns to [BattlePhase.idle].
  ///
  /// No reward is granted and no counters are updated.
  void retreatBattle() {
    _stopAutoTimer();
    state = state.copyWith(
      phase:      BattlePhase.idle,
      playerTeam: const [],
      enemyTeam:  const [],
      battleLog:  const [],
      clearReward: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Starts the next battle in auto-mode after a victory.
  ///
  /// If the current stage is the last one, loops back to stage 1-1 (index 1).
  void _advanceToNextStage() {
    final nextId = state.currentStageId < StageDatabase.count
        ? state.currentStageId + 1
        : 1; // loop from the beginning after the final stage
    startBattle(nextId);
  }

  /// Creates mutable deep-copies of [BattleMonster] objects so that HP
  /// mutations inside [processTurn] do not affect the previous state reference.
  List<BattleMonster> _copyTeam(List<BattleMonster> team) {
    return team.map((m) => m.copyWith()).toList();
  }

  void _saveReplay(List<BattleLogEntry> log, bool isVictory) {
    final stageKey = _stageIndexToKey(state.currentStageId);
    final record = BattleRecord(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      label: 'Stage $stageKey',
      isVictory: isVictory,
      totalTurns: state.currentTurn,
      playerNames: state.playerTeam.map((m) => m.name).toList(),
      enemyNames: state.enemyTeam.map((m) => m.name).toList(),
      logLines: log.map((e) => e.description).toList(),
    );
    ref.read(battleReplayProvider.notifier).addRecord(record);
  }
}

// =============================================================================
// Provider
// =============================================================================

/// Global battle provider.  Access via `ref.watch(battleProvider)` or
/// `ref.read(battleProvider.notifier)`.
final battleProvider =
    StateNotifierProvider<BattleNotifier, BattleState>(
  (ref) => BattleNotifier(ref),
);
