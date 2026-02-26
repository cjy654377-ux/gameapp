import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/enums/monster_element.dart';
import '../../../domain/services/guild_service.dart';
import '../../providers/guild_provider.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('길드'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.groups, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          const Text(
            '길드 생성',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '길드를 만들고 동료들과 함께\n강력한 보스를 처치하세요!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: '길드 이름 입력',
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
              child: const Text(
                '길드 생성',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          'Lv.${guild.level} | 코인: ${guild.guildCoin}',
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
                '길드원 (${guild.memberNames.length + 1}명)',
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
                  _MemberChip(name: '나 (길드장)', isLeader: true),
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
                          '주간 보스: ${GuildService.weeklyBossName()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '남은 HP: ${guild.bossHpRemaining.round()} / ${bossMaxHp.round()}',
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
                    '내 기여: ${guild.playerContribution.round()}',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  Text(
                    '길드원 기여: ${guild.aiContribution.round()}',
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
                        ? '보스 처치 완료!'
                        : '보스 도전 ($attemptsLeft/${GuildService.maxDailyAttempts})',
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
            label: const Text('길드 상점'),
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
                '${boss.name} (턴 ${guildState.currentTurn}/${GuildService.maxTurns})',
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
                '이번 전투 데미지: ${guildState.damageThisFight.round()}',
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
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(8),
              itemCount: guildState.battleLog.length,
              itemBuilder: (ctx, i) {
                final entry =
                    guildState.battleLog[guildState.battleLog.length - 1 - i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Text(
                    entry.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: entry.isCritical
                          ? Colors.orange
                          : AppColors.textSecondary,
                    ),
                  ),
                );
              },
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
                child: const Text('공격'),
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
                  guildState.isAutoMode ? '자동 ON' : '자동 OFF',
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
              isVictory ? '전투 종료!' : '패배...',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isVictory ? Colors.amber : Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '총 데미지: ${guildState.damageThisFight.round()}',
              style: const TextStyle(fontSize: 16),
            ),
            if (guildState.lastRewardCoins > 0)
              Text(
                '획득 길드 코인: +${guildState.lastRewardCoins}',
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
              child: const Text('로비로 돌아가기'),
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
              const Text(
                '길드 상점',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  '코인: ${guild.guildCoin}',
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
                            '${item.cost} 코인',
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${item.name} 구매 완료!'),
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
                      child: const Text('구매'),
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
              child: const Text('돌아가기'),
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
