import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local_storage.dart';
import '../../../routing/app_router.dart';
import '../../providers/currency_provider.dart';
import '../../providers/monster_provider.dart';
import '../../providers/player_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final player = playerState.player;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Text(
              '설정',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Player info
            if (player != null) ...[
              _SectionHeader(title: '플레이어 정보'),
              _InfoTile(label: '닉네임', value: player.nickname),
              _InfoTile(label: '레벨', value: 'Lv.${player.playerLevel}'),
              _InfoTile(label: '현재 스테이지', value: player.currentStageId),
              _InfoTile(
                label: '전투 횟수',
                value: '${player.totalBattleCount}회',
              ),
              _InfoTile(
                label: '소환 횟수',
                value: '${player.totalGachaPullCount}회',
              ),
              const SizedBox(height: 24),
            ],

            // Game info
            _SectionHeader(title: '게임 정보'),
            _InfoTile(label: '버전', value: '1.0.0'),
            _InfoTile(
              label: '보유 몬스터',
              value: '${ref.watch(monsterListProvider).length}마리',
            ),
            const SizedBox(height: 24),

            // Actions
            _SectionHeader(title: '데이터'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmReset(context, ref),
                icon: Icon(Icons.delete_forever, color: AppColors.error),
                label: Text(
                  '게임 초기화',
                  style: TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          '게임 초기화',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '모든 데이터가 삭제됩니다.\n정말로 초기화하시겠습니까?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('취소', style: TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await LocalStorage.instance.clearAll();
              if (context.mounted) {
                // Reset providers
                ref.invalidate(playerProvider);
                ref.invalidate(currencyProvider);
                ref.invalidate(monsterListProvider);
                context.go(AppRoutes.onboarding);
              }
            },
            child: Text('초기화', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textTertiary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 1),
      color: AppColors.surface,
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
