import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gameapp/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../providers/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    ref.read(leaderboardProvider.notifier).load();
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        ref.read(leaderboardProvider.notifier).setTab(
              LeaderboardTab.values[_tabCtrl.index],
            );
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(leaderboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.leaderboardTitle),
        backgroundColor: AppColors.surface,
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: false,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: l.leaderboardArena),
            Tab(text: l.leaderboardDungeon),
            Tab(text: l.leaderboardTower),
            Tab(text: l.leaderboardBoss),
          ],
        ),
      ),
      body: Column(
        children: [
          // Player rank summary
          _RankSummary(state: state, l: l),
          // Entries list
          Expanded(
            child: state.entries.isEmpty
                ? Center(
                    child: Text(
                      '—',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  )
                : ListView.builder(
                    cacheExtent: 600,
                    itemCount: state.entries.length,
                    itemBuilder: (_, i) => _RankTile(
                      entry: state.entries[i],
                      tab: state.activeTab,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Rank Summary
// =============================================================================

class _RankSummary extends StatelessWidget {
  const _RankSummary({required this.state, required this.l});
  final LeaderboardState state;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final playerEntry = state.entries.where((e) => e.isPlayer).firstOrNull;
    if (playerEntry == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _rankColor(playerEntry.rank).withValues(alpha: 0.2),
              border: Border.all(
                color: _rankColor(playerEntry.rank),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '#${playerEntry.rank}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _rankColor(playerEntry.rank),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.leaderboardMyRank,
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatScore(playerEntry.score, state.activeTab),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${state.entries.length} ${l.leaderboardPlayers}',
            style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Rank Tile
// =============================================================================

class _RankTile extends StatelessWidget {
  const _RankTile({required this.entry, required this.tab});
  final LeaderboardEntry entry;
  final LeaderboardTab tab;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: entry.isPlayer
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: entry.isPlayer
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
            : Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: entry.rank <= 3
                ? Icon(
                    Icons.emoji_events,
                    color: _rankColor(entry.rank),
                    size: 22,
                  )
                : Text(
                    '${entry.rank}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: entry.isPlayer
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          // Name
          Expanded(
            child: Text(
              entry.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: entry.isPlayer ? FontWeight.bold : FontWeight.w500,
                color: entry.isPlayer
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          // Score
          Text(
            _formatScore(entry.score, tab),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: entry.isPlayer ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Helpers
// =============================================================================

Color _rankColor(int rank) {
  switch (rank) {
    case 1:
      return const Color(0xFFFFD700); // Gold
    case 2:
      return const Color(0xFFC0C0C0); // Silver
    case 3:
      return const Color(0xFFCD7F32); // Bronze
    default:
      return AppColors.textSecondary;
  }
}

String _formatScore(int score, LeaderboardTab tab) {
  switch (tab) {
    case LeaderboardTab.arena:
      return '$score pts';
    case LeaderboardTab.dungeon:
      return '${score}F';
    case LeaderboardTab.tower:
      return '${score}F';
    case LeaderboardTab.worldBoss:
      if (score >= 1000000) return '${(score / 1000000).toStringAsFixed(1)}M';
      if (score >= 1000) return '${(score / 1000).toStringAsFixed(1)}K';
      return '$score';
  }
}
