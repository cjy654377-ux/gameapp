import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local_storage.dart';
import '../../../domain/services/audio_service.dart';
import '../../../routing/app_router.dart';
import '../../providers/currency_provider.dart';
import '../../providers/locale_provider.dart';
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
              _InfoTile(
                label: '전생 레벨',
                value: '${player.prestigeLevel}회 (+${player.prestigeBonusPercent.toInt()}%)',
              ),
              const SizedBox(height: 24),
            ],

            // Language toggle
            _SectionHeader(title: '언어 / Language'),
            _LanguageToggleTile(),
            const SizedBox(height: 24),

            // Sound / Haptic toggle
            _SectionHeader(title: '효과'),
            _SoundToggleTile(),
            const SizedBox(height: 24),

            // Game info
            _SectionHeader(title: '게임 정보'),
            _InfoTile(label: '버전', value: '1.0.0'),
            _InfoTile(
              label: '보유 몬스터',
              value: '${ref.watch(monsterListProvider).length}마리',
            ),
            const SizedBox(height: 24),

            // Relic
            _SectionHeader(title: '유물/장비'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.relic),
                icon: const Icon(Icons.inventory, size: 22),
                label: const Text(
                  '유물 관리',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Prestige
            _SectionHeader(title: '전생 (프레스티지)'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.prestige),
                icon: const Icon(Icons.autorenew, size: 22),
                label: const Text(
                  '전생 화면으로',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Backup / Restore
            _SectionHeader(title: '백업 / 복원'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportData(context),
                    icon: const Icon(Icons.upload, size: 20),
                    label: const Text('백업 (복사)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _importData(context, ref),
                    icon: const Icon(Icons.download, size: 20),
                    label: const Text('복원 (붙여넣기)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
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

  void _exportData(BuildContext context) {
    final json = LocalStorage.instance.exportToJson();
    Clipboard.setData(ClipboardData(text: json));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('게임 데이터가 클립보드에 복사되었습니다'),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _importData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          '데이터 복원',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '클립보드의 백업 데이터로 복원합니다.\n현재 데이터는 모두 덮어씌워집니다.\n계속하시겠습니까?',
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
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data?.text == null || data!.text!.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('클립보드에 데이터가 없습니다'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                return;
              }
              final success =
                  await LocalStorage.instance.importFromJson(data.text!);
              if (context.mounted) {
                if (success) {
                  ref.invalidate(playerProvider);
                  ref.invalidate(currencyProvider);
                  ref.invalidate(monsterListProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('데이터 복원 완료!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('복원 실패: 올바른 백업 데이터가 아닙니다'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('복원', style: TextStyle(color: Colors.indigo)),
          ),
        ],
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

class _SoundToggleTile extends StatefulWidget {
  @override
  State<_SoundToggleTile> createState() => _SoundToggleTileState();
}

class _SoundToggleTileState extends State<_SoundToggleTile> {
  @override
  Widget build(BuildContext context) {
    final enabled = AudioService.instance.isEnabled;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: Row(
        children: [
          Icon(
            enabled ? Icons.vibration : Icons.notifications_off,
            color: enabled ? Colors.amber : AppColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            '진동 효과',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Switch(
            value: enabled,
            activeTrackColor: Colors.amber.withValues(alpha: 0.5),
            activeThumbColor: Colors.amber,
            onChanged: (v) {
              AudioService.instance.setEnabled(v);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

class _LanguageToggleTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isKorean = locale.languageCode == 'ko';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: Row(
        children: [
          Icon(Icons.language, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Text(
            isKorean ? '한국어' : 'English',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Switch(
            value: !isKorean,
            activeTrackColor: Colors.blue.withValues(alpha: 0.5),
            activeThumbColor: Colors.blue,
            onChanged: (_) {
              ref.read(localeProvider.notifier).toggle();
            },
          ),
        ],
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
