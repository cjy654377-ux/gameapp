import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gameapp/l10n/app_localizations.dart';

import '../../data/datasources/local_storage.dart';
import '../../domain/services/notification_service.dart';
import '../../routing/app_router.dart';
import '../dialogs/offline_reward_dialog.dart';
import '../providers/currency_provider.dart';
import '../providers/expedition_provider.dart';
import '../providers/guild_provider.dart';
import '../providers/monster_provider.dart';
import '../providers/offline_reward_provider.dart';
import '../providers/player_provider.dart';
import '../../domain/services/prestige_service.dart';
import '../providers/attendance_provider.dart';
import 'package:gameapp/data/static/quest_database.dart';
import '../providers/quest_provider.dart';
import '../providers/arena_provider.dart';
import '../providers/relic_provider.dart';
import '../providers/skin_provider.dart';
import '../dialogs/attendance_dialog.dart';
import '../../domain/services/arena_service.dart';
import '../../domain/services/guild_service.dart';

/// Tab configuration used by [HomeScreen].
class _TabItem {
  const _TabItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
  });

  final String route;
  final IconData icon;
  final IconData activeIcon;
}

const List<_TabItem> _tabs = [
  _TabItem(
    route: AppRoutes.battle,
    icon: Icons.shield_outlined,
    activeIcon: Icons.shield,
  ),
  _TabItem(
    route: AppRoutes.train,
    icon: Icons.fitness_center_outlined,
    activeIcon: Icons.fitness_center,
  ),
  _TabItem(
    route: AppRoutes.hero,
    icon: Icons.person_outlined,
    activeIcon: Icons.person,
  ),
  _TabItem(
    route: AppRoutes.gacha,
    icon: Icons.card_giftcard_outlined,
    activeIcon: Icons.card_giftcard,
  ),
  _TabItem(
    route: AppRoutes.shop,
    icon: Icons.store_outlined,
    activeIcon: Icons.store,
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
    try {
      await ref.read(playerProvider.notifier).loadPlayer();
      await ref.read(currencyProvider.notifier).load();
      await ref.read(monsterListProvider.notifier).loadMonsters();
      await ref.read(questProvider.notifier).load();
      await ref.read(relicProvider.notifier).loadRelics();
      ref.read(expeditionProvider.notifier).load();
      ref.read(guildProvider.notifier).loadGuild();
      ref.read(skinProvider.notifier).load();
      _loaded = true;
      _checkOfflineReward();
    } catch (e) {
      debugPrint('[HomeScreen] _initProviders error: $e');
      _loaded = true; // prevent infinite retry
    }
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
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    // Update lastOnlineAt (saves player internally), then save currency.
    await ref.read(playerProvider.notifier).updateLastOnline();
    await LocalStorage.instance.saveCurrency(ref.read(currencyProvider));

    // Schedule offline reminder notifications.
    final player = ref.read(playerProvider).player;
    if (player != null) {
      NotificationService.instance.scheduleOfflineReminders(
        player.lastOnlineAt,
        capTitle: l.notifCapTitle,
        capBody: l.notifCapBody,
        comeBackTitle: l.notifComeBackTitle,
        comeBackBody: l.notifComeBackBody,
        channelName: l.notifChannelName,
        channelDesc: l.notifChannelDesc,
      );
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

    // Check daily attendance after offline reward
    _checkAttendance();
  }

  Future<void> _checkAttendance() async {
    if (_showingDialog) return;
    if (!mounted) return;

    final attendance = ref.read(attendanceProvider.notifier);
    attendance.refresh();
    final state = ref.read(attendanceProvider);

    // Show milestone dialog even if already checked in today
    if (!state.canCheckIn && state.claimableMilestones.isNotEmpty) {
      _showingDialog = true;
      try {
        await _showAndClaimMilestones(state);
      } finally {
        _showingDialog = false;
      }
      return;
    }

    if (!state.canCheckIn) return;

    _showingDialog = true;
    try {
      final claimed = await showAttendanceDialog(context, attendance: state);

      if (claimed && mounted) {
        final reward = await ref.read(attendanceProvider.notifier).checkIn();
        if (reward != null && mounted) {
          final l = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.attendanceClaimed),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Show milestone dialog if any claimable
          final updatedState = ref.read(attendanceProvider);
          if (updatedState.claimableMilestones.isNotEmpty && mounted) {
            await _showAndClaimMilestones(updatedState);
          }
        }
      }
    } finally {
      _showingDialog = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Tab index
  // ---------------------------------------------------------------------------

  /// Returns badge count for bottom nav tab at [index].
  /// Tabs: 0=battle, 1=train, 2=hero, 3=gacha, 4=shop
  int _badgeCount(int index, int dailyTotal) {
    switch (index) {
      case 0: return dailyTotal; // battle tab: daily content remaining
      default: return 0;
    }
  }

  int _resolveIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].route)) {
        return i;
      }
    }
    return 0;
  }

  Future<void> _showAndClaimMilestones(AttendanceState attendance) async {
    final claimedDays = await showMilestoneDialog(
      context,
      attendance: attendance,
    );
    if (!mounted) return;
    for (final days in claimedDays) {
      await ref.read(attendanceProvider.notifier).claimMilestone(days);
    }
    if (claimedDays.isNotEmpty && mounted) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.milestoneClaimed),
          backgroundColor: Colors.amber,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Listen for newly completed quests → show achievement toast.
    ref.listen<QuestState>(questProvider, (prev, next) {
      if (next.newlyCompletedIds.isEmpty) return;
      final l = AppLocalizations.of(context)!;
      for (final questId in next.newlyCompletedIds) {
        final def = QuestDatabase.findById(questId);
        if (def == null) continue;
        final name = def.name;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                context.go(AppRoutes.quest);
              },
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.achievementToast(name),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          l.achievementTapToView,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.deepPurple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      ref.read(questProvider.notifier).clearNewlyCompleted();
    });

    final l = AppLocalizations.of(context)!;
    final currentIndex = _resolveIndex(context);
    final tabLabels = [
      l.tabBattle,
      l.tabTrain,
      l.tabHero,
      l.tabGacha,
      l.shopTitle,
    ];

    // Badge counts for bottom nav
    final int expeditionReady = ref.watch(expeditionProvider.select((s) => s.completedCount));
    final arenaUsed = ref.watch(arenaProvider.select((s) => s.attemptsUsed));
    final int arenaLeft = (ArenaService.maxDailyAttempts - arenaUsed) > 0
        ? ArenaService.maxDailyAttempts - arenaUsed : 0;
    final guildGuild = ref.watch(guildProvider.select((s) => s.guild));
    final int guildBossLeft = guildGuild != null && guildGuild.dailyBossAttempts < GuildService.maxDailyAttempts
        ? GuildService.maxDailyAttempts - guildGuild.dailyBossAttempts : 0;
    final int dailyTotal = arenaLeft + guildBossLeft + expeditionReady;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index != currentIndex) {
            context.go(_tabs[index].route);
          }
        },
        items: [
          for (int i = 0; i < _tabs.length; i++)
            () {
              final count = _badgeCount(i, dailyTotal);
              return BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: Icon(i == currentIndex ? _tabs[i].activeIcon : _tabs[i].icon),
                ),
                label: tabLabels[i],
              );
            }(),
        ],
      ),
    );
  }
}
