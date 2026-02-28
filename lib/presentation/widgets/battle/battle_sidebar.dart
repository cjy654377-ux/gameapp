import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gameapp/l10n/app_localizations.dart';
import 'package:gameapp/routing/app_router.dart';

/// Left-side quick-access sidebar shown during battle.
/// Semi-transparent vertical column of icon buttons.
class BattleSidebar extends StatelessWidget {
  const BattleSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final items = [
      // ── Combat content ──
      _SidebarItem(Icons.layers, l.sidebarDungeon, AppRoutes.dungeon, const Color(0xFFCE93D8)),
      _SidebarItem(Icons.castle, l.sidebarTower, AppRoutes.tower, Colors.amber),
      _SidebarItem(Icons.whatshot, l.sidebarWorldBoss, AppRoutes.worldBoss, Colors.red),
      _SidebarItem(Icons.emoji_events, l.sidebarArena, AppRoutes.arena, Colors.amber),
      _SidebarItem(Icons.event, l.sidebarEvent, AppRoutes.eventDungeon, Colors.teal),
      _SidebarItem(Icons.groups, l.sidebarGuild, AppRoutes.guild, Colors.indigo),
      _SidebarItem(Icons.wb_sunny, l.sidebarDailyDungeon, AppRoutes.dailyDungeon, Colors.deepOrange),
      // ── Navigation ──
      _SidebarItem(Icons.map_rounded, l.sidebarMap, AppRoutes.stageSelect, Colors.cyan),
      _SidebarItem(Icons.card_giftcard, l.sidebarSeasonPass, AppRoutes.seasonPass, const Color(0xFFFFD54F)),
      _SidebarItem(Icons.leaderboard, l.sidebarLeaderboard, AppRoutes.leaderboard, const Color(0xFF4FC3F7)),
      _SidebarItem(Icons.military_tech, l.sidebarTitle, AppRoutes.title, const Color(0xFFBA68C8)),
      _SidebarItem(Icons.mail_rounded, l.sidebarMailbox, AppRoutes.mailbox, const Color(0xFF81C784)),
      _SidebarItem(Icons.replay, l.sidebarReplay, AppRoutes.battleReplay, const Color(0xFF90A4AE)),
      // ── Info / System ──
      _SidebarItem(Icons.bar_chart, l.sidebarStats, AppRoutes.statistics, const Color(0xFF4DB6AC)),
      _SidebarItem(Icons.auto_awesome, l.sidebarPrestige, AppRoutes.prestige, const Color(0xFFFF8A65)),
      _SidebarItem(Icons.inventory_2, l.sidebarRelic, AppRoutes.relic, Colors.orange),
      _SidebarItem(Icons.catching_pokemon, l.sidebarCollection, AppRoutes.collection, const Color(0xFF7986CB)),
      _SidebarItem(Icons.assignment, l.sidebarQuest, AppRoutes.quest, Colors.green),
      _SidebarItem(Icons.settings, l.sidebarSettings, AppRoutes.settings, Colors.blueGrey),
    ];

    return Container(
      width: 52,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: items
              .map((item) => _SidebarButton(item: item))
              .toList(),
        ),
      ),
    );
  }
}

class _SidebarItem {
  const _SidebarItem(this.icon, this.label, this.route, this.color);
  final IconData icon;
  final String label;
  final String route;
  final Color color;
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
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
