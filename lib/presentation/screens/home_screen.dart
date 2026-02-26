import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/app_router.dart';

/// Tab configuration used by [HomeScreen].
class _TabItem {
  const _TabItem({
    required this.route,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const List<_TabItem> _tabs = [
  _TabItem(
    route: AppRoutes.battle,
    label: '전투',
    icon: Icons.shield_outlined,
    activeIcon: Icons.shield,
  ),
  _TabItem(
    route: AppRoutes.gacha,
    label: '소환',
    icon: Icons.card_giftcard_outlined,
    activeIcon: Icons.card_giftcard,
  ),
  _TabItem(
    route: AppRoutes.collection,
    label: '도감',
    icon: Icons.collections_bookmark_outlined,
    activeIcon: Icons.collections_bookmark,
  ),
  _TabItem(
    route: AppRoutes.upgrade,
    label: '강화',
    icon: Icons.upgrade_outlined,
    activeIcon: Icons.upgrade,
  ),
  _TabItem(
    route: AppRoutes.settings,
    label: '설정',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings,
  ),
];

/// Root scaffold that hosts the [BottomNavigationBar] and delegates the body
/// to the currently active GoRouter shell route child.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.child});

  /// The currently active route's page widget provided by [ShellRoute].
  final Widget child;

  /// Resolves the [BottomNavigationBar] index from the current route location.
  int _resolveIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].route)) {
        return i;
      }
    }
    return 0; // default to 전투
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _resolveIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index != currentIndex) {
            context.go(_tabs[index].route);
          }
        },
        items: _tabs.map((tab) {
          final isSelected = _tabs.indexOf(tab) == currentIndex;
          return BottomNavigationBarItem(
            icon: Icon(isSelected ? tab.activeIcon : tab.icon),
            label: tab.label,
          );
        }).toList(),
      ),
    );
  }
}
