import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/core/enums/monster_element.dart';
import 'package:gameapp/core/enums/monster_rarity.dart';
import 'package:gameapp/core/utils/format_utils.dart';
import 'package:gameapp/data/models/monster_model.dart';
import 'package:gameapp/l10n/app_localizations.dart';
import 'package:gameapp/presentation/providers/monster_provider.dart';
import 'package:gameapp/presentation/providers/battle_provider.dart';
import 'package:gameapp/presentation/widgets/monster_avatar.dart';
import 'package:gameapp/routing/app_router.dart';

// =============================================================================
// TeamTab — unified team management tab for bottom sheet
// =============================================================================

class TeamTab extends ConsumerWidget {
  const TeamTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final team = ref.watch(teamMonstersProvider);
    final battleState = ref.watch(battleProvider);

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          // Sub-tab bar
          Container(
            color: AppColors.surface,
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              tabs: [
                Tab(text: l.teamEdit),
                Tab(text: l.heroTabEquipment),
                Tab(text: l.heroTabInventory),
                Tab(text: l.tabCollection),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // 전투원 탭
                _TeamMembersTab(team: team, battleState: battleState),
                // 장비 탭 — 히어로 화면으로 이동
                _EquipmentNavTab(),
                // 아이템 탭
                _ItemNavTab(),
                // 도감 탭
                _CollectionNavTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 전투원 탭 — 현재 팀 편성 + 전투 중 몬스터 정보
// =============================================================================

class _TeamMembersTab extends StatelessWidget {
  const _TeamMembersTab({required this.team, required this.battleState});

  final List<MonsterModel> team;
  final BattleState battleState;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final totalPower = team.fold<int>(0, (sum, m) => sum + m.powerScore);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Team power header
        Row(
          children: [
            const Icon(Icons.groups, color: AppColors.primaryLight, size: 22),
            const SizedBox(width: 8),
            Text(
              l.totalPower(FormatUtils.formatNumber(totalPower)),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.teamEdit),
              icon: const Icon(Icons.edit, size: 16),
              label: Text(l.teamEdit),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Team member cards
        if (team.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  const Icon(Icons.group_add, color: AppColors.textTertiary, size: 48),
                  const SizedBox(height: 8),
                  Text(l.noMonsterOwned,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(l.getMonsterFromGacha,
                      style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ],
              ),
            ),
          )
        else
          ...team.map((m) => _TeamMemberCard(monster: m)),

        const SizedBox(height: 16),

        // Quick actions
        _QuickActionRow(
          children: [
            _QuickActionButton(
              icon: Icons.compare_arrows,
              label: l.compareTitle,
              onTap: () => context.push(AppRoutes.monsterCompare),
            ),
            _QuickActionButton(
              icon: Icons.auto_stories,
              label: l.monsterCollection,
              onTap: () => context.push(AppRoutes.collection),
            ),
            _QuickActionButton(
              icon: Icons.upgrade,
              label: l.upgradeEvolution,
              onTap: () => context.push(AppRoutes.upgrade),
            ),
          ],
        ),
      ],
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  const _TeamMemberCard({required this.monster});
  final MonsterModel monster;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rarityEnum = MonsterRarity.fromRarity(monster.rarity);
    final elementEnum = MonsterElement.fromName(monster.element);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rarityEnum.color.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        onTap: () => context.push(AppRoutes.monsterDetail, extra: monster),
        child: Row(
          children: [
            // Monster avatar
            MonsterAvatar(
              name: monster.name,
              element: monster.element,
              rarity: monster.rarity,
              templateId: monster.templateId,
              size: 48,
              evolutionStage: monster.evolutionStage,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        monster.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: rarityEnum.color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (elementEnum != null) _ElementBadge(element: elementEnum),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.monsterLevelInfo(monster.level, monster.evolutionStage),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            // Power score
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  FormatUtils.formatNumber(monster.powerScore),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
                Text(
                  rarityEnum.starsDisplay,
                  style: TextStyle(
                    fontSize: 10,
                    color: rarityEnum.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ElementBadge extends StatelessWidget {
  const _ElementBadge({required this.element});
  final MonsterElement element;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: element.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        element.emoji,
        style: const TextStyle(fontSize: 10),
      ),
    );
  }
}

// =============================================================================
// 장비 탭 — 히어로 화면으로 네비게이트
// =============================================================================

class _EquipmentNavTab extends StatelessWidget {
  const _EquipmentNavTab();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _NavCard(
          icon: Icons.person,
          iconColor: AppColors.primaryLight,
          title: l.heroHeader,
          description: l.heroBattleStats,
          onTap: () => context.push(AppRoutes.hero),
        ),
        const SizedBox(height: 12),
        _NavCard(
          icon: Icons.shield,
          iconColor: Colors.blue,
          title: l.relic,
          description: l.settingsRelicManage,
          onTap: () => context.push(AppRoutes.relic),
        ),
        const SizedBox(height: 12),
        _NavCard(
          icon: Icons.checkroom,
          iconColor: Colors.pink,
          title: l.skinTitle,
          description: l.skinEquip,
          onTap: () => context.push(AppRoutes.hero),
        ),
      ],
    );
  }
}

// =============================================================================
// 아이템 탭 — 인벤토리, 합성/분해
// =============================================================================

class _ItemNavTab extends StatelessWidget {
  const _ItemNavTab();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _NavCard(
          icon: Icons.auto_awesome,
          iconColor: Colors.purple,
          title: l.heroSkillLabel,
          description: l.heroSelectSkill,
          onTap: () => context.push(AppRoutes.hero),
        ),
        const SizedBox(height: 12),
        _NavCard(
          icon: Icons.pets,
          iconColor: Colors.orange,
          title: l.heroMountLabel,
          description: l.heroSelectMount,
          onTap: () => context.push(AppRoutes.hero),
        ),
        const SizedBox(height: 12),
        _NavCard(
          icon: Icons.merge_type,
          iconColor: Colors.teal,
          title: l.heroTabFusion,
          description: l.heroFusionDesc,
          onTap: () => context.push(AppRoutes.hero),
        ),
      ],
    );
  }
}

// =============================================================================
// 도감 탭
// =============================================================================

class _CollectionNavTab extends ConsumerWidget {
  const _CollectionNavTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final monsters = ref.watch(monsterListProvider);
    final ownedCount = monsters.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const Icon(Icons.auto_stories, color: AppColors.primaryLight, size: 32),
              const SizedBox(height: 8),
              Text(
                l.monsterCollection,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.ownedCount(ownedCount),
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _NavCard(
          icon: Icons.auto_stories,
          iconColor: Colors.indigo,
          title: l.monsterCollection,
          description: l.ownedCount(ownedCount),
          onTap: () => context.push(AppRoutes.collection),
        ),
        const SizedBox(height: 12),
        _NavCard(
          icon: Icons.bar_chart,
          iconColor: Colors.teal,
          title: l.statistics,
          description: l.battleStats,
          onTap: () => context.push(AppRoutes.statistics),
        ),
        const SizedBox(height: 12),
        _NavCard(
          icon: Icons.replay,
          iconColor: Colors.deepOrange,
          title: l.replayTitle,
          description: l.replayEmpty,
          onTap: () => context.push(AppRoutes.battleReplay),
        ),
      ],
    );
  }
}

// =============================================================================
// Shared widgets
// =============================================================================

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: children
          .expand((w) => [Expanded(child: w), const SizedBox(width: 8)])
          .toList()
        ..removeLast(),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
