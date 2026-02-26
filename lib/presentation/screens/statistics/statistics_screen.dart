import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/core/utils/format_utils.dart';
import 'package:gameapp/data/static/stage_database.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';
import 'package:gameapp/presentation/providers/collection_provider.dart';
import 'package:gameapp/presentation/providers/gacha_provider.dart';
import 'package:gameapp/presentation/providers/monster_provider.dart';
import 'package:gameapp/presentation/providers/player_provider.dart';
import 'package:gameapp/presentation/providers/quest_provider.dart';
import 'package:gameapp/presentation/providers/relic_provider.dart';
import 'package:gameapp/l10n/app_localizations.dart';

// =============================================================================
// StatisticsScreen
// =============================================================================

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider).player;
    if (player == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final currency = ref.watch(currencyProvider);
    final monsters = ref.watch(monsterListProvider);
    final stats = ref.watch(collectionStatsProvider);
    final questState = ref.watch(questProvider);
    final relics = ref.watch(relicProvider);

    // Computed stats
    final daysSinceCreation = DateTime.now().difference(player.createdAt).inDays;
    final teamMonsters = monsters.where((m) => m.isInTeam).toList();
    final maxLevelMonster = monsters.isEmpty
        ? null
        : monsters.reduce((a, b) => a.level > b.level ? a : b);
    final totalBattleCount = monsters.fold<int>(0, (sum, m) => sum + m.battleCount);
    final completedQuests = questState.quests.where((q) => q.isCompleted).length;
    final stageProgress = StageDatabase.linearIndex(player.maxClearedStageId);

    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.statistics, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Player ────────────────────────────────────────────────
          _StatSection(
            title: l.playerInfo,
            icon: Icons.person,
            color: AppColors.primary,
            children: [
              _StatItem(label: '닉네임', value: player.nickname),
              _StatItem(label: '레벨', value: 'Lv.${player.playerLevel}'),
              _StatItem(label: '전생 횟수', value: '${player.prestigeLevel}회'),
              _StatItem(label: '전생 보너스', value: '+${player.prestigeBonusPercent.toInt()}%'),
              _StatItem(label: '가입일', value: _formatDate(player.createdAt)),
              _StatItem(label: '플레이 일수', value: '${daysSinceCreation + 1}일'),
            ],
          ),

          const SizedBox(height: 12),

          // ── Battle ────────────────────────────────────────────────
          _StatSection(
            title: l.battleStats,
            icon: Icons.sports_mma,
            color: Colors.red,
            children: [
              _StatItem(label: '총 스테이지 전투', value: '${player.totalBattleCount}회'),
              _StatItem(label: '팀 누적 전투', value: '${FormatUtils.formatNumber(totalBattleCount)}회'),
              _StatItem(
                label: '스테이지 진행',
                value: '$stageProgress / ${StageDatabase.count}',
              ),
              _StatItem(label: '최고 클리어', value: player.maxClearedStageId.isEmpty ? '-' : player.maxClearedStageId),
              _StatItem(label: '무한던전 최고층', value: player.maxDungeonFloor > 0 ? '${player.maxDungeonFloor}층' : '-'),
            ],
          ),

          const SizedBox(height: 12),

          // ── Monster ───────────────────────────────────────────────
          _StatSection(
            title: l.monsterStats,
            icon: Icons.catching_pokemon,
            color: Colors.orange,
            children: [
              _StatItem(label: '보유 몬스터', value: '${monsters.length}마리'),
              _StatItem(label: '도감 수집', value: '${stats.owned} / ${stats.total}종'),
              _StatItem(
                label: '최고 레벨',
                value: maxLevelMonster != null
                    ? '${maxLevelMonster.name} Lv.${maxLevelMonster.level}'
                    : '-',
              ),
              _StatItem(label: '팀 편성', value: '${teamMonsters.length} / 4'),
              _StatItem(
                label: '평균 레벨',
                value: monsters.isEmpty
                    ? '-'
                    : 'Lv.${(monsters.fold<int>(0, (s, m) => s + m.level) / monsters.length).round()}',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Gacha ─────────────────────────────────────────────────
          _StatSection(
            title: l.gachaStats,
            icon: Icons.auto_awesome,
            color: Colors.purple,
            children: [
              _StatItem(label: '총 소환 횟수', value: '${player.totalGachaPullCount}회'),
              Builder(builder: (context) {
                final pity = ref.watch(gachaProvider.select((s) => s.pityCount));
                return Column(
                  children: [
                    _StatItem(label: '현재 천장', value: '$pity / 80'),
                    _StatItem(
                      label: '5성 보장',
                      value: pity >= 70 ? '보장 임박!' : '${80 - pity}회 남음',
                    ),
                  ],
                );
              }),
            ],
          ),

          const SizedBox(height: 12),

          // ── Resources ─────────────────────────────────────────────
          _StatSection(
            title: l.resources,
            icon: Icons.account_balance_wallet,
            color: AppColors.gold,
            children: [
              _StatItem(label: '골드', value: FormatUtils.formatNumber(currency.gold)),
              _StatItem(label: '다이아', value: FormatUtils.formatNumber(currency.diamond)),
              _StatItem(label: '소환권', value: '${currency.gachaTicket}장'),
              _StatItem(label: '경험치 물약', value: '${currency.expPotion}개'),
              _StatItem(label: '몬스터 파편', value: '${currency.monsterShard}개'),
            ],
          ),

          const SizedBox(height: 12),

          // ── Equipment ─────────────────────────────────────────────
          _StatSection(
            title: l.equipmentQuests,
            icon: Icons.shield,
            color: Colors.teal,
            children: [
              _StatItem(label: '보유 유물', value: '${relics.length}개'),
              _StatItem(
                label: '장착 유물',
                value: '${relics.where((r) => r.equippedMonsterId != null).length}개',
              ),
              _StatItem(label: '완료 퀘스트', value: '${completedQuests}개'),
              _StatItem(
                label: '수령 가능',
                value: '${questState.claimableCount}개',
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }
}

// =============================================================================
// _StatSection
// =============================================================================

class _StatSection extends StatelessWidget {
  const _StatSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _StatItem
// =============================================================================

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
