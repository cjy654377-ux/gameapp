import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/l10n/app_localizations.dart';
import 'package:gameapp/routing/app_router.dart';
import 'package:gameapp/presentation/providers/expedition_provider.dart';

class TrainScreen extends ConsumerWidget {
  const TrainScreen({super.key, this.embedded = false});

  /// When true, renders without Scaffold/AppBar for bottom sheet embedding.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final expeditionCompleted = ref.watch(
      expeditionProvider.select((s) => s.completedCount),
    );

    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (embedded)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.trainTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        _NavCard(
          icon: Icons.upgrade,
          iconColor: AppColors.primary,
          title: l10n.trainUpgradeCard,
          description: l10n.trainUpgradeDesc,
          badge: null,
          onTap: () => context.push(AppRoutes.upgrade),
        ),
        const SizedBox(height: 12),
        _NavCard(
          icon: Icons.fitness_center,
          iconColor: Colors.orange,
          title: l10n.trainTrainingCard,
          description: l10n.trainTrainingDesc,
          badge: null,
          onTap: () => context.push(AppRoutes.training),
        ),
        const SizedBox(height: 12),
        _NavCard(
          icon: Icons.explore,
          iconColor: Colors.lightBlue,
          title: l10n.trainExpeditionCard,
          description: l10n.trainExpeditionDesc,
          badge: expeditionCompleted > 0 ? expeditionCompleted : null,
          onTap: () => context.push(AppRoutes.expedition),
        ),
      ],
    );

    if (embedded) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          l10n.trainTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: content,
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
