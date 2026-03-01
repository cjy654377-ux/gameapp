import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gameapp/l10n/app_localizations.dart';
import 'package:gameapp/core/constants/app_colors.dart';

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

import 'battle/battle_view.dart';
import 'team/team_tab.dart';
import 'train/train_screen.dart';
import 'gacha/gacha_screen.dart';
import 'shop/shop_screen.dart';

/// Root scaffold that hosts the always-visible BattleView background,
/// a DraggableScrollableSheet for tab content, and a 4-tab BottomNavigationBar.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.child});

  /// GoRouter child — kept for compatibility but not rendered.
  final Widget child;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  bool _showingDialog = false;
  bool _loaded = false;

  /// Currently selected tab index. null = no tab selected (sheet minimized).
  int? _selectedTab;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  static const double _sheetMin = 0.05;
  static const double _sheetSnap = 0.50;
  static const double _sheetMax = 0.85;

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
      _loaded = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sheetController.dispose();
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
    await ref.read(playerProvider.notifier).updateLastOnline();
    await LocalStorage.instance.saveCurrency(ref.read(currencyProvider));

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
      final multiplier = PrestigeService.bonusMultiplier(player);
      final bonusGold = (reward.gold * multiplier).round();
      final bonusExp = (reward.exp * multiplier).round();
      await ref.read(currencyProvider.notifier).addGold(bonusGold);
      await ref.read(playerProvider.notifier).addPlayerExp(bonusExp);
      ref.read(offlineRewardProvider.notifier).markClaimed();
    }

    await ref.read(playerProvider.notifier).updateLastOnline();
    _showingDialog = false;

    _checkAttendance();
  }

  Future<void> _checkAttendance() async {
    if (_showingDialog) return;
    if (!mounted) return;

    final attendance = ref.read(attendanceProvider.notifier);
    attendance.refresh();
    final state = ref.read(attendanceProvider);

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
  // Tab selection
  // ---------------------------------------------------------------------------

  void _onTabTapped(int index) {
    setState(() {
      if (_selectedTab == index) {
        // Same tab tapped again → minimize sheet
        _selectedTab = null;
        _animateSheet(_sheetMin);
      } else {
        _selectedTab = index;
        _animateSheet(_sheetSnap);
      }
    });
  }

  void _animateSheet(double target) {
    if (!_sheetController.isAttached) return;
    _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
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

    // Badge counts
    final int expeditionReady =
        ref.watch(expeditionProvider.select((s) => s.completedCount));
    final arenaUsed =
        ref.watch(arenaProvider.select((s) => s.attemptsUsed));
    final int arenaLeft = (ArenaService.maxDailyAttempts - arenaUsed) > 0
        ? ArenaService.maxDailyAttempts - arenaUsed
        : 0;
    final guildGuild =
        ref.watch(guildProvider.select((s) => s.guild));
    final int guildBossLeft = guildGuild != null &&
            guildGuild.dailyBossAttempts < GuildService.maxDailyAttempts
        ? GuildService.maxDailyAttempts - guildGuild.dailyBossAttempts
        : 0;
    final int dailyTotal = arenaLeft + guildBossLeft + expeditionReady;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Always-visible battle background
          const Positioned.fill(child: BattleView()),

          // Draggable content sheet
          _ContentSheet(
            controller: _sheetController,
            selectedTab: _selectedTab,
            onSheetMinimized: () {
              if (_selectedTab != null) {
                setState(() => _selectedTab = null);
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab ?? 0,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: _selectedTab != null ? AppColors.primary : AppColors.textSecondary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: dailyTotal > 0 && _selectedTab != 0,
              label: Text('$dailyTotal'),
              child: Icon(_selectedTab == 0
                  ? Icons.groups
                  : Icons.groups_outlined),
            ),
            label: l.tabTeam,
          ),
          BottomNavigationBarItem(
            icon: Icon(_selectedTab == 1
                ? Icons.fitness_center
                : Icons.fitness_center_outlined),
            label: l.tabTrain,
          ),
          BottomNavigationBarItem(
            icon: Icon(_selectedTab == 2
                ? Icons.card_giftcard
                : Icons.card_giftcard_outlined),
            label: l.tabGacha,
          ),
          BottomNavigationBarItem(
            icon: Icon(_selectedTab == 3
                ? Icons.store
                : Icons.store_outlined),
            label: l.shopTitle,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _ContentSheet — DraggableScrollableSheet overlay
// =============================================================================

class _ContentSheet extends StatefulWidget {
  const _ContentSheet({
    required this.controller,
    required this.selectedTab,
    required this.onSheetMinimized,
  });

  final DraggableScrollableController controller;
  final int? selectedTab;
  final VoidCallback onSheetMinimized;

  @override
  State<_ContentSheet> createState() => _ContentSheetState();
}

class _ContentSheetState extends State<_ContentSheet> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSheetChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSheetChanged);
    super.dispose();
  }

  void _onSheetChanged() {
    if (!widget.controller.isAttached) return;
    // If sheet is dragged to near-minimum, notify parent
    if (widget.controller.size <= 0.08 && widget.selectedTab != null) {
      widget.onSheetMinimized();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasTab = widget.selectedTab != null;

    return DraggableScrollableSheet(
      controller: widget.controller,
      initialChildSize: hasTab ? 0.50 : _HomeScreenState._sheetMin,
      minChildSize: _HomeScreenState._sheetMin,
      maxChildSize: _HomeScreenState._sheetMax,
      snap: true,
      snapSizes: const [_HomeScreenState._sheetMin, 0.50, _HomeScreenState._sheetMax],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              // Tab content
              if (hasTab)
                Expanded(
                  child: IndexedStack(
                    index: widget.selectedTab!,
                    children: const [
                      TeamTab(),
                      _TrainTabWrapper(),
                      _GachaTabWrapper(),
                      _ShopTabWrapper(),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// Tab wrappers — strip Scaffold from existing screens for sheet embedding
// =============================================================================

/// Wraps TrainScreen content without its own Scaffold.
class _TrainTabWrapper extends ConsumerWidget {
  const _TrainTabWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const TrainScreen(embedded: true);
  }
}

class _GachaTabWrapper extends ConsumerWidget {
  const _GachaTabWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const GachaScreen(embedded: true);
  }
}

class _ShopTabWrapper extends ConsumerWidget {
  const _ShopTabWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ShopScreen(embedded: true);
  }
}
