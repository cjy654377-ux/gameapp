import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/datasources/local_storage.dart';
import '../data/models/monster_model.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/battle/battle_screen.dart';
import '../presentation/screens/gacha/gacha_screen.dart';
import '../presentation/screens/collection/collection_screen.dart';
import '../presentation/screens/collection/team_edit_screen.dart';
import '../presentation/screens/upgrade/upgrade_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/quest/quest_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/dungeon/dungeon_screen.dart';
import '../presentation/screens/tower/tower_screen.dart';
import '../presentation/screens/prestige/prestige_screen.dart';
import '../presentation/screens/relic/relic_screen.dart';
import '../presentation/screens/stage_select/stage_select_screen.dart';
import '../presentation/screens/arena/arena_screen.dart';
import '../presentation/screens/event_dungeon/event_dungeon_screen.dart';
import '../presentation/screens/guild/guild_screen.dart';
import '../presentation/screens/expedition/expedition_screen.dart';
import '../presentation/screens/monster_detail/monster_detail_screen.dart';
import '../presentation/screens/statistics/statistics_screen.dart';
import '../presentation/screens/world_boss/world_boss_screen.dart';

// ---------------------------------------------------------------------------
// Route path constants
// ---------------------------------------------------------------------------

class AppRoutes {
  const AppRoutes._();

  static const onboarding = '/onboarding';
  static const battle = '/battle';
  static const gacha = '/gacha';
  static const collection = '/collection';
  static const teamEdit = '/collection/team';
  static const upgrade = '/upgrade';
  static const quest = '/quest';
  static const settings = '/settings';
  static const stageSelect = '/stage-select';
  static const dungeon = '/dungeon';
  static const prestige = '/prestige';
  static const worldBoss = '/world-boss';
  static const relic = '/relic';
  static const arena = '/arena';
  static const eventDungeon = '/event-dungeon';
  static const guild = '/guild';
  static const monsterDetail = '/monster-detail';
  static const expedition = '/expedition';
  static const statistics = '/statistics';
  static const tower = '/tower';
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.battle,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isOnboarding = state.uri.toString() == AppRoutes.onboarding;
      final hasPlayer = LocalStorage.instance.getPlayer() != null;

      // No player yet → force onboarding
      if (!hasPlayer && !isOnboarding) return AppRoutes.onboarding;
      // Has player but on onboarding → go to battle
      if (hasPlayer && isOnboarding) return AppRoutes.battle;
      return null;
    },
    routes: [
      // Full-screen routes (no bottom nav)
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.teamEdit,
        builder: (context, state) => const TeamEditScreen(),
      ),
      GoRoute(
        path: AppRoutes.stageSelect,
        builder: (context, state) => const StageSelectScreen(),
      ),
      GoRoute(
        path: AppRoutes.dungeon,
        builder: (context, state) => const DungeonScreen(),
      ),
      GoRoute(
        path: AppRoutes.tower,
        builder: (context, state) => const TowerScreen(),
      ),
      GoRoute(
        path: AppRoutes.prestige,
        builder: (context, state) => const PrestigeScreen(),
      ),
      GoRoute(
        path: AppRoutes.worldBoss,
        builder: (context, state) => const WorldBossScreen(),
      ),
      GoRoute(
        path: AppRoutes.relic,
        builder: (context, state) => const RelicScreen(),
      ),
      GoRoute(
        path: AppRoutes.arena,
        builder: (context, state) => const ArenaScreen(),
      ),
      GoRoute(
        path: AppRoutes.eventDungeon,
        builder: (context, state) => const EventDungeonScreen(),
      ),
      GoRoute(
        path: AppRoutes.guild,
        builder: (context, state) => const GuildScreen(),
      ),
      GoRoute(
        path: AppRoutes.expedition,
        builder: (context, state) => const ExpeditionScreen(),
      ),
      GoRoute(
        path: AppRoutes.statistics,
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.monsterDetail,
        builder: (context, state) {
          final monster = state.extra as MonsterModel;
          return MonsterDetailScreen(monster: monster);
        },
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return HomeScreen(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.battle,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BattleScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.gacha,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: GachaScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.collection,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CollectionScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.upgrade,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: UpgradeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.quest,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: QuestScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
