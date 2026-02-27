import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gameapp/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/enums/monster_element.dart';
import '../../../domain/services/guild_service.dart';
import '../../providers/guild_provider.dart';
import '../../widgets/common/battle_log_list.dart';

class GuildScreen extends ConsumerStatefulWidget {
  const GuildScreen({super.key});

  @override
  ConsumerState<GuildScreen> createState() => _GuildScreenState();
}

class _GuildScreenState extends ConsumerState<GuildScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, ) {
    final guildState = ref.watch(guildProvider);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.guild),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: switch (guildState.phase) {
        GuildPhase.noGuild => _buildCreateGuild(context),
        GuildPhase.lobby => _buildLobby(context, guildState),
        GuildPhase.fighting => _buildFight(context, guildState),
        GuildPhase.victory || GuildPhase.defeat => _buildResult(context, guildState),
        GuildPhase.shop => _buildShop(context, guildState),
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Create guild
  // ---------------------------------------------------------------------------

  Widget _buildCreateGuild(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.groups, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            l.guildCreate,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l.guildCreateDesc,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: l.guildNameHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.surface,
            ),
            maxLength: 12,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final name = _nameController.text.trim();
                if (name.isNotEmpty) {
                  ref.read(guildProvider.notifier).createGuild(name);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l.guildCreate,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Lobby
  // ---------------------------------------------------------------------------

  Widget _buildLobby(BuildContext context, GuildState guildState) {
    final l = AppLocalizations.of(context)!;
    final guild = guildState.guild!;
    final bossMaxHp = GuildService.bossMaxHp(guildLevel: guild.level);
    final bossHpPercent =
        bossMaxHp > 0 ? (guild.bossHpRemaining / bossMaxHp).clamp(0.0, 1.0) : 0.0;
    final bossElement =
        MonsterElement.fromName(GuildService.weeklyBossElement()) ?? MonsterElement.fire;
    final attemptsLeft =
        GuildService.maxDailyAttempts - guild.dailyBossAttempts;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Guild info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.shield, color: Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guild.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          l.guildLevelCoin(guild.level, guild.guildCoin),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Guild EXP bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: guild.expToNextLevel > 0
                      ? (guild.exp / guild.expToNextLevel).clamp(0.0, 1.0)
                      : 0,
                  backgroundColor: AppColors.surfaceVariant,
                  color: Colors.amber,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'EXP: ${guild.exp}/${guild.expToNextLevel}',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Members
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.guildMembers(guild.memberNames.length + 1),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _MemberChip(name: l.guildLeader, isLeader: true),
                  ...guild.memberNames.map(
                    (n) => _MemberChip(name: n, isLeader: false),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Boss card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: bossElement.color.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    bossElement.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.guildWeeklyBoss(GuildService.weeklyBossName()),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          l.guildBossHp(guild.bossHpRemaining.round().toString(), bossMaxHp.round().toString()),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: bossHpPercent,
                  backgroundColor: AppColors.surfaceVariant,
                  color: Colors.red,
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    l.guildMyContrib(guild.playerContribution.round().toString()),
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  Text(
                    l.guildAiContrib(guild.aiContribution.round().toString()),
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: attemptsLeft > 0 && guild.bossHpRemaining > 0
                      ? () =>
                          ref.read(guildProvider.notifier).startBossFight()
                      : null,
                  icon: const Icon(Icons.flash_on, size: 20),
                  label: Text(
                    guild.bossHpRemaining <= 0
                        ? l.guildBossDefeated
                        : l.guildBossChallenge(attemptsLeft, GuildService.maxDailyAttempts),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Shop button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => ref.read(guildProvider.notifier).openShop(),
            icon: const Icon(Icons.store, size: 20),
            label: Text(l.guildShop),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Fight view
  // ---------------------------------------------------------------------------

  Widget _buildFight(BuildContext context, GuildState guildState) {
    final l = AppLocalizations.of(context)!;
    final boss = guildState.boss;
    if (boss == null) return const SizedBox();
    final bossHpPercent =
        (boss.currentHp / boss.maxHp).clamp(0.0, 1.0);

    return Column(
      children: [
        // Boss HP
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                l.guildBossTurn(boss.name, guildState.currentTurn, GuildService.maxTurns),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: bossHpPercent,
                  backgroundColor: AppColors.surfaceVariant,
                  color: Colors.red,
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${boss.currentHp.round()} / ${boss.maxHp.round()}',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                l.guildFightDamage(guildState.damageThisFight.round().toString()),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ),

        // Battle log
        Expanded(
          child: Container(
            color: AppColors.surface,
            child: BattleLogList(
              entries: guildState.battleLog,
              reverse: true,
            ),
          ),
        ),

        // Controls
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () =>
                    ref.read(guildProvider.notifier).processTurn(),
                child: Text(l.attack),
              ),
              OutlinedButton(
                onPressed: () =>
                    ref.read(guildProvider.notifier).toggleSpeed(),
                child: Text('x${guildState.battleSpeed.toInt()}'),
              ),
              OutlinedButton(
                onPressed: () =>
                    ref.read(guildProvider.notifier).toggleAuto(),
                style: guildState.isAutoMode
                    ? OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.amber))
                    : null,
                child: Text(
                  guildState.isAutoMode ? l.autoShortOn : l.autoShortOff,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Result
  // ---------------------------------------------------------------------------

  Widget _buildResult(BuildContext context, GuildState guildState) {
    final l = AppLocalizations.of(context)!;
    final isVictory = guildState.phase == GuildPhase.victory;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVictory ? Icons.emoji_events : Icons.close,
              size: 64,
              color: isVictory ? Colors.amber : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              isVictory ? l.guildBattleEnd : l.guildDefeat,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isVictory ? Colors.amber : Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.guildTotalDamage(guildState.damageThisFight.round().toString()),
              style: const TextStyle(fontSize: 16),
            ),
            if (guildState.lastRewardCoins > 0)
              Text(
                l.guildEarnedCoin(guildState.lastRewardCoins),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  ref.read(guildProvider.notifier).returnToLobby(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: Text(l.guildReturnLobby),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shop
  // ---------------------------------------------------------------------------

  Widget _buildShop(BuildContext context, GuildState guildState) {
    final l = AppLocalizations.of(context)!;
    final guild = guildState.guild;
    if (guild == null) return const SizedBox();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.store, color: Colors.teal, size: 24),
              const SizedBox(width: 8),
              Text(
                l.guildShop,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l.guildCoinLabel(guild.guildCoin),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: GuildService.shopItems.length,
            itemBuilder: (ctx, i) {
              final item = GuildService.shopItems[i];
              final canAfford = guild.guildCoin >= item.cost;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: canAfford
                        ? Colors.teal.withValues(alpha: 0.3)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _shopItemIcon(item.type),
                      color: canAfford ? Colors.teal : AppColors.disabled,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: canAfford
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                            ),
                          ),
                          Text(
                            l.guildItemCost(item.cost),
                            style: TextStyle(
                              fontSize: 12,
                              color: canAfford ? Colors.amber : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: canAfford
                          ? () async {
                              await ref
                                  .read(guildProvider.notifier)
                                  .purchaseItem(i);
                              if (context.mounted) {
                                final l2 = AppLocalizations.of(context)!;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l2.guildPurchaseDone(item.name)),
                                    backgroundColor: Colors.teal,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l.purchase),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () =>
                  ref.read(guildProvider.notifier).returnToLobby(),
              child: Text(l.goBack),
            ),
          ),
        ),
      ],
    );
  }

  IconData _shopItemIcon(String type) {
    switch (type) {
      case 'gachaTicket':
        return Icons.confirmation_number;
      case 'expPotion':
        return Icons.science;
      case 'gold':
        return Icons.monetization_on;
      case 'diamond':
        return Icons.diamond;
      case 'monsterShard':
        return Icons.auto_awesome;
      default:
        return Icons.inventory;
    }
  }
}

// =============================================================================
// Member chip
// =============================================================================

class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.name, required this.isLeader});
  final String name;
  final bool isLeader;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        isLeader ? Icons.star : Icons.person,
        size: 16,
        color: isLeader ? Colors.amber : AppColors.textTertiary,
      ),
      label: Text(
        name,
        style: TextStyle(
          fontSize: 12,
          color: isLeader ? Colors.amber : AppColors.textSecondary,
        ),
      ),
      backgroundColor: AppColors.surfaceVariant,
      side: BorderSide(
        color: isLeader
            ? Colors.amber.withValues(alpha: 0.3)
            : AppColors.border,
      ),
    );
  }
}
