import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local_storage.dart';
import '../../data/models/guild_model.dart';
import '../../domain/entities/battle_entity.dart';
import '../../domain/services/audio_service.dart';
import '../../domain/services/battle_service.dart';
import '../../domain/services/guild_service.dart';
import '../../data/static/skill_database.dart';
import 'currency_provider.dart';
import 'monster_provider.dart';
import 'relic_provider.dart';

// =============================================================================
// State
// =============================================================================

enum GuildPhase { noGuild, lobby, fighting, victory, defeat, shop }

class GuildState {
  final GuildPhase phase;
  final GuildModel? guild;
  final List<BattleMonster> playerTeam;
  final BattleMonster? boss;
  final List<BattleLogEntry> battleLog;
  final int currentTurn;
  final int turnWithinRound;
  final double damageThisFight;
  final double battleSpeed;
  final bool isAutoMode;
  final int lastRewardCoins;

  const GuildState({
    this.phase = GuildPhase.noGuild,
    this.guild,
    this.playerTeam = const [],
    this.boss,
    this.battleLog = const [],
    this.currentTurn = 1,
    this.turnWithinRound = 0,
    this.damageThisFight = 0,
    this.battleSpeed = 1.0,
    this.isAutoMode = false,
    this.lastRewardCoins = 0,
  });

  GuildState copyWith({
    GuildPhase? phase,
    GuildModel? guild,
    List<BattleMonster>? playerTeam,
    BattleMonster? boss,
    List<BattleLogEntry>? battleLog,
    int? currentTurn,
    int? turnWithinRound,
    double? damageThisFight,
    double? battleSpeed,
    bool? isAutoMode,
    int? lastRewardCoins,
    bool clearGuild = false,
    bool clearBoss = false,
  }) {
    return GuildState(
      phase: phase ?? this.phase,
      guild: clearGuild ? null : (guild ?? this.guild),
      playerTeam: playerTeam ?? this.playerTeam,
      boss: clearBoss ? null : (boss ?? this.boss),
      battleLog: battleLog ?? this.battleLog,
      currentTurn: currentTurn ?? this.currentTurn,
      turnWithinRound: turnWithinRound ?? this.turnWithinRound,
      damageThisFight: damageThisFight ?? this.damageThisFight,
      battleSpeed: battleSpeed ?? this.battleSpeed,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      lastRewardCoins: lastRewardCoins ?? this.lastRewardCoins,
    );
  }
}

// =============================================================================
// Notifier
// =============================================================================

class GuildNotifier extends StateNotifier<GuildState> {
  GuildNotifier(this._ref) : super(const GuildState()) {
    _loadGuild();
  }

  final Ref _ref;
  Timer? _autoTimer;

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  void _loadGuild() {
    final guild = LocalStorage.instance.getGuild();
    if (guild == null) {
      state = const GuildState(phase: GuildPhase.noGuild);
      return;
    }
    // Check weekly boss reset.
    final currentWeek = GuildService.currentWeekNumber();
    final today = GuildService.todayString();
    var updated = guild;

    if (guild.lastBossResetWeek != currentWeek) {
      // Reset boss for new week, simulate AI damage from previous period.
      updated = guild.copyWith(
        bossHpRemaining: GuildService.bossMaxHp(guildLevel: guild.level),
        playerContribution: 0,
        aiContribution: 0,
        lastBossResetWeek: currentWeek,
        dailyBossAttempts: 0,
        lastDailyResetDate: today,
        shopPurchaseBitmask: 0,
      );
    } else if (guild.lastDailyResetDate != today) {
      // Daily reset: attempts + simulate AI damage.
      final aiDmg = GuildService.simulateAiDamage(
        memberCount: guild.memberNames.length,
        guildLevel: guild.level,
      );
      final newBossHp =
          (guild.bossHpRemaining - aiDmg).clamp(0.0, double.infinity);
      updated = guild.copyWith(
        dailyBossAttempts: 0,
        lastDailyResetDate: today,
        aiContribution: guild.aiContribution + aiDmg,
        bossHpRemaining: newBossHp,
      );
    }

    if (updated != guild) {
      LocalStorage.instance.saveGuild(updated);
    }
    state = GuildState(phase: GuildPhase.lobby, guild: updated);
  }

  // ---------------------------------------------------------------------------
  // Create guild
  // ---------------------------------------------------------------------------

  Future<void> createGuild(String name) async {
    final guild = GuildModel(
      id: 'guild_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      level: 1,
      memberNames: GuildService.generateMembers(),
      bossHpRemaining: GuildService.bossMaxHp(guildLevel: 1),
      lastBossResetWeek: GuildService.currentWeekNumber(),
      lastDailyResetDate: GuildService.todayString(),
    );
    await LocalStorage.instance.saveGuild(guild);
    state = GuildState(phase: GuildPhase.lobby, guild: guild);
  }

  // ---------------------------------------------------------------------------
  // Start boss fight
  // ---------------------------------------------------------------------------

  void startBossFight() {
    final guild = state.guild;
    if (guild == null) return;
    if (guild.dailyBossAttempts >= GuildService.maxDailyAttempts) return;
    if (guild.bossHpRemaining <= 0) return;

    // Create player team.
    final monsters = _ref.read(monsterListProvider);
    final team = monsters.where((m) => m.isInTeam).toList();
    if (team.isEmpty) return;

    final relicNotifier = _ref.read(relicProvider.notifier);

    final playerTeam = team.map((m) {
      final bonus = relicNotifier.relicBonuses(m.id);
      final skill = SkillDatabase.findByTemplateId(m.templateId);
      return BattleMonster(
        monsterId: m.id,
        templateId: m.templateId,
        name: m.name,
        element: m.element,
        size: m.size,
        rarity: m.rarity,
        maxHp: m.finalHp + bonus.hp,
        currentHp: m.finalHp + bonus.hp,
        atk: m.finalAtk + bonus.atk,
        def: m.finalDef + bonus.def,
        spd: m.finalSpd + bonus.spd,
        skillId: skill?.id,
        skillName: skill?.name,
        skillCooldown: skill?.cooldown ?? 0,
        skillMaxCooldown: skill?.cooldown ?? 0,
      );
    }).toList();

    final boss = GuildService.createBoss(
      guildLevel: guild.level,
      currentHp: guild.bossHpRemaining,
    );

    state = state.copyWith(
      phase: GuildPhase.fighting,
      playerTeam: playerTeam,
      boss: boss,
      battleLog: [],
      currentTurn: 1,
      turnWithinRound: 0,
      damageThisFight: 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Process turn
  // ---------------------------------------------------------------------------

  void processTurn() {
    if (state.phase != GuildPhase.fighting) return;
    final currentBoss = state.boss;
    if (currentBoss == null) return;

    if (state.currentTurn > GuildService.maxTurns) {
      _finishFight();
      return;
    }

    final playerTeam = _copyTeam(state.playerTeam);
    final boss = currentBoss.copyWith();

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
    double dmgThisFight = state.damageThisFight;

    final isBoss = attacker.monsterId == boss.monsterId;

    if (isBoss) {
      // Boss attacks player.
      final entry = GuildService.bossAttackRandom(boss, playerTeam);
      if (entry != null) {
        AudioService.instance.playHit();
        log.add(entry);
      }
    } else {
      // Player attacks boss.
      final entry = BattleService.processSingleAttack(
        attacker: attacker,
        target: boss,
      );
      AudioService.instance.playHit();
      log.add(entry);
      dmgThisFight += entry.damage;
    }

    // Trim log.
    if (log.length > 50) log.removeRange(0, log.length - 50);

    // Check end conditions.
    final allPlayerDead = playerTeam.every((m) => !m.isAlive);

    if (boss.currentHp <= 0 || allPlayerDead ||
        state.currentTurn >= GuildService.maxTurns) {
      // Fight over.
      final phase = allPlayerDead ? GuildPhase.defeat : GuildPhase.victory;
      if (allPlayerDead) {
        AudioService.instance.playDefeat();
      } else {
        AudioService.instance.playVictory();
      }

      state = state.copyWith(
        phase: phase,
        playerTeam: playerTeam,
        boss: boss,
        battleLog: log,
        damageThisFight: dmgThisFight,
      );
      return;
    }

    final nextSlot = slot + 1;
    final roundComplete = nextSlot >= allUnits.length;
    final newTurn = roundComplete ? state.currentTurn + 1 : state.currentTurn;
    final newSlot = roundComplete ? 0 : nextSlot;

    state = state.copyWith(
      playerTeam: playerTeam,
      boss: boss,
      battleLog: log,
      currentTurn: newTurn,
      turnWithinRound: newSlot,
      damageThisFight: dmgThisFight,
    );
  }

  void _finishFight() {
    final guild = state.guild;
    if (guild == null) return;

    final coins = GuildService.calculateGuildCoins(state.damageThisFight);
    final guildExp = GuildService.calculateGuildExp(state.damageThisFight);
    final newBossHp =
        (guild.bossHpRemaining - state.damageThisFight).clamp(0.0, double.infinity);

    int newLevel = guild.level;
    int newExp = guild.exp + guildExp;
    while (newExp >= (500 * newLevel * 1.2).round()) {
      newExp -= (500 * newLevel * 1.2).round();
      newLevel++;
    }

    final updated = guild.copyWith(
      bossHpRemaining: newBossHp,
      playerContribution: guild.playerContribution + state.damageThisFight,
      dailyBossAttempts: guild.dailyBossAttempts + 1,
      guildCoin: guild.guildCoin + coins,
      level: newLevel,
      exp: newExp,
    );
    LocalStorage.instance.saveGuild(updated);

    AudioService.instance.playRewardCollect();
    state = state.copyWith(
      phase: GuildPhase.victory,
      guild: updated,
      lastRewardCoins: coins,
    );
  }

  // ---------------------------------------------------------------------------
  // Collect reward & return to lobby
  // ---------------------------------------------------------------------------

  void returnToLobby() {
    state = GuildState(
      phase: GuildPhase.lobby,
      guild: state.guild,
      battleSpeed: state.battleSpeed,
      isAutoMode: state.isAutoMode,
    );
  }

  // ---------------------------------------------------------------------------
  // Guild shop
  // ---------------------------------------------------------------------------

  void openShop() {
    state = state.copyWith(phase: GuildPhase.shop);
  }

  Future<void> purchaseItem(int itemIndex) async {
    final guild = state.guild;
    if (guild == null) return;

    final item = GuildService.shopItems[itemIndex];
    if (guild.guildCoin < item.cost) return;

    // Deduct guild coins.
    final updated = guild.copyWith(
      guildCoin: guild.guildCoin - item.cost,
    );
    await LocalStorage.instance.saveGuild(updated);

    // Grant reward.
    final currency = _ref.read(currencyProvider.notifier);
    switch (item.type) {
      case 'gold':
        await currency.addGold(item.amount);
      case 'diamond':
        await currency.addDiamond(item.amount);
      case 'gachaTicket':
        await currency.addGachaTicket(item.amount);
      case 'expPotion':
        await currency.addExpPotion(item.amount);
      case 'monsterShard':
        await currency.addShard(item.amount);
    }

    AudioService.instance.playRewardCollect();
    state = state.copyWith(guild: updated);
  }

  // ---------------------------------------------------------------------------
  // Battle controls
  // ---------------------------------------------------------------------------

  void toggleSpeed() {
    final current = state.battleSpeed;
    final next = current == 1.0 ? 2.0 : (current == 2.0 ? 3.0 : 1.0);
    state = state.copyWith(battleSpeed: next);
  }

  void toggleAuto() {
    final newAuto = !state.isAutoMode;
    state = state.copyWith(isAutoMode: newAuto);
    if (newAuto && state.phase == GuildPhase.fighting) {
      _startAutoTimer();
    } else {
      _stopAutoTimer();
    }
  }

  void _startAutoTimer() {
    _stopAutoTimer();
    final ms = (600 / state.battleSpeed).round();
    _autoTimer = Timer.periodic(Duration(milliseconds: ms), (_) {
      if (state.phase == GuildPhase.fighting) {
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
  // Helpers
  // ---------------------------------------------------------------------------

  List<BattleMonster> _copyTeam(List<BattleMonster> team) {
    return team.map((m) => m.copyWith()).toList();
  }

  @override
  void dispose() {
    _stopAutoTimer();
    super.dispose();
  }
}

// =============================================================================
// Provider
// =============================================================================

final guildProvider = StateNotifierProvider<GuildNotifier, GuildState>(
  (ref) => GuildNotifier(ref),
);
