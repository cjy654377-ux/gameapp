import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/datasources/local_storage.dart';
import '../../domain/services/notification_service.dart';
import '../../routing/app_router.dart';
import '../dialogs/offline_reward_dialog.dart';
import '../providers/currency_provider.dart';
import '../providers/monster_provider.dart';
import '../providers/offline_reward_provider.dart';
import '../providers/player_provider.dart';
import '../../domain/services/prestige_service.dart';
import '../providers/quest_provider.dart';
import '../providers/relic_provider.dart';

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
    route: AppRoutes.quest,
    label: '퀘스트',
    icon: Icons.assignment_outlined,
    activeIcon: Icons.assignment,
  ),
  _TabItem(
    route: AppRoutes.settings,
    label: '설정',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings,
  ),
];

/// Root scaffold that hosts the [BottomNavigationBar], manages app lifecycle
/// events (pause/resume), and triggers offline reward calculations.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  bool _showingDialog = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initProviders();
    });
  }

  Future<void> _initProviders() async {
    if (_loaded) return;
    await ref.read(playerProvider.notifier).loadPlayer();
    await ref.read(currencyProvider.notifier).load();
    await ref.read(monsterListProvider.notifier).loadMonsters();
    await ref.read(questProvider.notifier).load();
    await ref.read(relicProvider.notifier).loadRelics();
    _loaded = true;
    _checkOfflineReward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _onPaused();
        break;
      case AppLifecycleState.resumed:
        _onResumed();
        break;
      default:
        break;
    }
  }

  Future<void> _onPaused() async {
    // Update lastOnlineAt (saves player internally), then save currency.
    await ref.read(playerProvider.notifier).updateLastOnline();
    await LocalStorage.instance.saveCurrency(ref.read(currencyProvider));

    // Schedule offline reminder notifications.
    final player = ref.read(playerProvider).player;
    if (player != null) {
      NotificationService.instance.scheduleOfflineReminders(player.lastOnlineAt);
    }
  }

  Future<void> _onResumed() async {
    // Cancel pending notifications since user is back.
    NotificationService.instance.cancelAll();
    _checkOfflineReward();
  }

  // ---------------------------------------------------------------------------
  // Offline reward
  // ---------------------------------------------------------------------------

  Future<void> _checkOfflineReward() async {
    if (_showingDialog) return;

    final player = ref.read(playerProvider).player;
    if (player == null) return;

    // Calculate offline rewards.
    ref.read(offlineRewardProvider.notifier).calculateRewards(
          lastOnlineAt: player.lastOnlineAt,
          stageId: player.currentStageId,
        );

    final rewardState = ref.read(offlineRewardProvider);
    if (!rewardState.hasPendingReward) return;

    _showingDialog = true;

    if (!mounted) {
      _showingDialog = false;
      return;
    }

    final claimed = await showOfflineRewardDialog(
      context,
      reward: rewardState.pendingReward!,
    );

    if (claimed) {
      final reward = rewardState.pendingReward!;
      // Apply prestige bonus multiplier to offline rewards.
      final multiplier = PrestigeService.bonusMultiplier(player);
      final bonusGold = (reward.gold * multiplier).round();
      final bonusExp = (reward.exp * multiplier).round();
      await ref.read(currencyProvider.notifier).addGold(bonusGold);
      await ref.read(playerProvider.notifier).addPlayerExp(bonusExp);
      ref.read(offlineRewardProvider.notifier).markClaimed();
    }

    // Update lastOnlineAt to now.
    await ref.read(playerProvider.notifier).updateLastOnline();
    _showingDialog = false;
  }

  // ---------------------------------------------------------------------------
  // Tab index
  // ---------------------------------------------------------------------------

  int _resolveIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].route)) {
        return i;
      }
    }
    return 0;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final currentIndex = _resolveIndex(context);

    return Scaffold(
      body: widget.child,
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
