import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/screens/home_screen.dart';
import '../presentation/screens/gacha/gacha_screen.dart';
import '../presentation/screens/collection/collection_screen.dart';
import '../presentation/screens/collection/team_edit_screen.dart';
import '../presentation/screens/upgrade/upgrade_screen.dart';

// ---------------------------------------------------------------------------
// Route path constants
// ---------------------------------------------------------------------------

class AppRoutes {
  const AppRoutes._();

  static const battle = '/battle';
  static const gacha = '/gacha';
  static const collection = '/collection';
  static const teamEdit = '/collection/team';
  static const upgrade = '/upgrade';
  static const settings = '/settings';
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.battle,
    debugLogDiagnostics: false,
    routes: [
      // Full-screen routes (no bottom nav)
      GoRoute(
        path: AppRoutes.teamEdit,
        builder: (context, state) => const TeamEditScreen(),
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return HomeScreen(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.battle,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _BattlePlaceholder(),
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
            path: AppRoutes.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _SettingsPlaceholder(),
            ),
          ),
        ],
      ),
    ],
  );
});

// ---------------------------------------------------------------------------
// Placeholder widgets (replaced by real screens as they are implemented)
// ---------------------------------------------------------------------------

class _BattlePlaceholder extends StatelessWidget {
  const _BattlePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _TabPlaceholder(label: '전투', icon: Icons.shield);
  }
}

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _TabPlaceholder(label: '설정', icon: Icons.settings);
  }
}

class _TabPlaceholder extends StatelessWidget {
  const _TabPlaceholder({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            label,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '준비 중입니다.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
