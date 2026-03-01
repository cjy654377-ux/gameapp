import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gameapp/l10n/app_localizations.dart';
import 'package:gameapp/routing/app_router.dart';
import 'package:gameapp/presentation/providers/quest_provider.dart';
import 'package:gameapp/presentation/providers/lucky_box_provider.dart';

/// Left-side quick-access sidebar shown during battle.
/// Grouped by category with badges for actionable items.
class BattleSidebar extends ConsumerWidget {
  const BattleSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;

    // Badge data
    final questClaimable = ref.watch(
      questProvider.select((s) => s.claimableCount),
    );
    final luckyBoxReady = ref.watch(
      luckyBoxProvider.select((s) => !s.claimedToday),
    );

    final groups = <_SidebarGroup>[
      _SidebarGroup(label: l.sidebarCatCombat, items: [
        _SidebarItem(Icons.layers, l.sidebarDungeon, AppRoutes.dungeon, const Color(0xFFCE93D8)),
        _SidebarItem(Icons.castle, l.sidebarTower, AppRoutes.tower, Colors.amber),
        _SidebarItem(Icons.whatshot, l.sidebarWorldBoss, AppRoutes.worldBoss, Colors.red),
        _SidebarItem(Icons.emoji_events, l.sidebarArena, AppRoutes.arena, Colors.amber),
        _SidebarItem(Icons.event, l.sidebarEvent, AppRoutes.eventDungeon, Colors.teal),
        _SidebarItem(Icons.wb_sunny, l.sidebarDailyDungeon, AppRoutes.dailyDungeon, Colors.deepOrange),
      ]),
      _SidebarGroup(label: l.sidebarCatContent, items: [
        _SidebarItem(Icons.map_rounded, l.sidebarMap, AppRoutes.stageSelect, Colors.cyan),
        _SidebarItem(Icons.groups, l.sidebarGuild, AppRoutes.guild, Colors.indigo),
        _SidebarItem(Icons.card_giftcard, l.sidebarSeasonPass, AppRoutes.seasonPass, const Color(0xFFFFD54F)),
        _SidebarItem(Icons.redeem, l.sidebarLuckyBox, AppRoutes.luckyBox, const Color(0xFFFFB300), badge: luckyBoxReady ? 1 : 0),
      ]),
      _SidebarGroup(label: l.sidebarCatProgress, items: [
        _SidebarItem(Icons.auto_awesome, l.sidebarPrestige, AppRoutes.prestige, const Color(0xFFFF8A65)),
        _SidebarItem(Icons.inventory_2, l.sidebarRelic, AppRoutes.relic, Colors.orange),
        _SidebarItem(Icons.catching_pokemon, l.sidebarCollection, AppRoutes.collection, const Color(0xFF7986CB)),
        _SidebarItem(Icons.assignment, l.sidebarQuest, AppRoutes.quest, Colors.green, badge: questClaimable),
      ]),
      _SidebarGroup(label: l.sidebarCatSystem, items: [
        _SidebarItem(Icons.leaderboard, l.sidebarLeaderboard, AppRoutes.leaderboard, const Color(0xFF4FC3F7)),
        _SidebarItem(Icons.military_tech, l.sidebarTitle, AppRoutes.title, const Color(0xFFBA68C8)),
        _SidebarItem(Icons.mail_rounded, l.sidebarMailbox, AppRoutes.mailbox, const Color(0xFF81C784)),
        _SidebarItem(Icons.replay, l.sidebarReplay, AppRoutes.battleReplay, const Color(0xFF90A4AE)),
        _SidebarItem(Icons.bar_chart, l.sidebarStats, AppRoutes.statistics, const Color(0xFF4DB6AC)),
        _SidebarItem(Icons.settings, l.sidebarSettings, AppRoutes.settings, Colors.blueGrey),
      ]),
    ];

    return Container(
      width: 54,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int g = 0; g < groups.length; g++) ...[
              if (g > 0) _CategoryDivider(),
              _CategoryHeader(label: groups[g].label),
              for (final item in groups[g].items)
                _SidebarButton(item: item),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Models
// =============================================================================

class _SidebarGroup {
  const _SidebarGroup({required this.label, required this.items});
  final String label;
  final List<_SidebarItem> items;
}

class _SidebarItem {
  const _SidebarItem(this.icon, this.label, this.route, this.color, {this.badge = 0});
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  final int badge;
}

// =============================================================================
// Widgets
// =============================================================================

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 7,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _CategoryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      height: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  const _SidebarButton({required this.item});
  final _SidebarItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(item.route),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, size: 18, color: item.color),
                ),
                if (item.badge > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          item.badge > 9 ? '!' : '${item.badge}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
