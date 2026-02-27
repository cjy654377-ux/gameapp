import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/data/static/stage_database.dart';
import 'package:gameapp/presentation/providers/player_provider.dart';
import 'package:gameapp/presentation/widgets/common/currency_bar.dart';
import 'package:gameapp/routing/app_router.dart';

// =============================================================================
// Area theme definitions
// =============================================================================

class _AreaTheme {
  const _AreaTheme({
    required this.name,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.emoji,
  });
  final String name;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final String emoji;
}

const _areas = [
  _AreaTheme(
    name: '시작의 숲',
    icon: Icons.park,
    color: Color(0xFF4CAF50),
    gradient: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
    emoji: '🌲',
  ),
  _AreaTheme(
    name: '불꽃 화산',
    icon: Icons.whatshot,
    color: Color(0xFFFF5722),
    gradient: [Color(0xFFBF360C), Color(0xFFFF8A65)],
    emoji: '🌋',
  ),
  _AreaTheme(
    name: '암흑 던전',
    icon: Icons.castle,
    color: Color(0xFF7E57C2),
    gradient: [Color(0xFF4527A0), Color(0xFFB39DDB)],
    emoji: '🏚️',
  ),
  _AreaTheme(
    name: '심해 신전',
    icon: Icons.water,
    color: Color(0xFF29B6F6),
    gradient: [Color(0xFF01579B), Color(0xFF4FC3F7)],
    emoji: '🌊',
  ),
  _AreaTheme(
    name: '천공 성역',
    icon: Icons.cloud,
    color: Color(0xFFFFD54F),
    gradient: [Color(0xFFF57F17), Color(0xFFFFF176)],
    emoji: '☁️',
  ),
];

// =============================================================================
// MapHubScreen
// =============================================================================

class MapHubScreen extends ConsumerWidget {
  const MapHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider).player;
    if (player == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final maxIdx = StageDatabase.linearIndex(player.maxClearedStageId);
    final currentArea = (player.currentStageId.isNotEmpty)
        ? int.tryParse(player.currentStageId.split('-').first) ?? 1
        : 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const CurrencyBar(),
          // Header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => context.pop(),
                ),
                const Icon(Icons.map, color: AppColors.primaryLight, size: 24),
                const SizedBox(width: 8),
                const Text('월드맵',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const Spacer(),
                // Total progress
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$maxIdx / ${StageDatabase.count}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Map area list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              itemCount: StageDatabase.areaCount,
              itemBuilder: (context, index) {
                final area = index + 1;
                final theme = _areas[index];
                final stages = StageDatabase.byArea(area);
                final clearedInArea = stages.where((s) {
                  return StageDatabase.linearIndex(s.id) <= maxIdx;
                }).length;
                final isCurrentArea = area == currentArea;
                final isUnlocked = _isAreaUnlocked(area, maxIdx);

                return _AreaNode(
                  area: area,
                  theme: theme,
                  clearedCount: clearedInArea,
                  totalCount: stages.length,
                  isCurrent: isCurrentArea,
                  isUnlocked: isUnlocked,
                  isLast: index == StageDatabase.areaCount - 1,
                  onTap: isUnlocked
                      ? () => context.push(AppRoutes.stageSelect)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isAreaUnlocked(int area, int maxClearedIdx) {
    if (area == 1) return true;
    // Area N is unlocked if previous area's first stage is cleared
    final prevAreaFirstIdx = (area - 2) * StageDatabase.stagesPerArea + 1;
    return maxClearedIdx >= prevAreaFirstIdx;
  }
}

// =============================================================================
// Area Node — visual map node
// =============================================================================

class _AreaNode extends StatelessWidget {
  const _AreaNode({
    required this.area,
    required this.theme,
    required this.clearedCount,
    required this.totalCount,
    required this.isCurrent,
    required this.isUnlocked,
    required this.isLast,
    this.onTap,
  });
  final int area;
  final _AreaTheme theme;
  final int clearedCount;
  final int totalCount;
  final bool isCurrent;
  final bool isUnlocked;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCompleted = clearedCount >= totalCount;

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isUnlocked
                  ? LinearGradient(
                      colors: [
                        theme.gradient[0].withValues(alpha: isCurrent ? 0.4 : 0.2),
                        theme.gradient[1].withValues(alpha: isCurrent ? 0.25 : 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isUnlocked ? null : AppColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrent
                    ? theme.color
                    : isUnlocked
                        ? theme.color.withValues(alpha: 0.4)
                        : AppColors.border,
                width: isCurrent ? 2.5 : 1.5,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: theme.color.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Area icon circle
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isUnlocked
                        ? LinearGradient(colors: theme.gradient)
                        : null,
                    color: isUnlocked ? null : AppColors.disabled,
                  ),
                  child: Center(
                    child: isUnlocked
                        ? Text(theme.emoji, style: const TextStyle(fontSize: 24))
                        : const Icon(Icons.lock, color: AppColors.disabledText, size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                // Area info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Area $area',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? theme.color : AppColors.disabledText,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: theme.color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('현재',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: theme.color)),
                            ),
                          ],
                          if (isCompleted) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle, color: AppColors.success, size: 14),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        theme.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isUnlocked ? AppColors.textPrimary : AppColors.disabledText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Progress bar
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: totalCount > 0 ? clearedCount / totalCount : 0,
                                minHeight: 6,
                                backgroundColor: AppColors.border,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isUnlocked ? theme.color : AppColors.disabled,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$clearedCount/$totalCount',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? AppColors.textSecondary : AppColors.disabledText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow
                if (isUnlocked)
                  Icon(Icons.chevron_right, color: theme.color.withValues(alpha: 0.7), size: 24),
              ],
            ),
          ),
        ),
        // Connector line between areas
        if (!isLast)
          Container(
            width: 3,
            height: 24,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isUnlocked ? theme.color.withValues(alpha: 0.3) : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}
