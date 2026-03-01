import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local_storage.dart';
import '../../../domain/services/audio_service.dart';
import '../../../domain/services/notification_service.dart';
import '../../../routing/app_router.dart';
import '../../providers/currency_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import 'package:gameapp/l10n/app_localizations.dart';
import '../../providers/monster_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/relic_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final player = playerState.player;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Text(
              l.settingsTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Player info
            if (player != null) ...[
              _SectionHeader(title: l.settingsPlayerInfo),
              _InfoTile(label: l.settingsNickname, value: player.nickname),
              _InfoTile(label: l.settingsLevel, value: 'Lv.${player.playerLevel}'),
              _InfoTile(label: l.settingsCurrentStage, value: player.currentStageId),
              _InfoTile(
                label: l.settingsBattleCount,
                value: '${player.totalBattleCount}',
              ),
              _InfoTile(
                label: l.settingsGachaCount,
                value: '${player.totalGachaPullCount}',
              ),
              _InfoTile(
                label: l.settingsPrestigeLevel,
                value: '${player.prestigeLevel} (+${player.prestigeBonusPercent.toInt()}%)',
              ),
              const SizedBox(height: 24),
            ],

            // Language toggle
            _SectionHeader(title: l.settingsLanguage),
            _LanguageToggleTile(),
            const SizedBox(height: 24),

            // Theme toggle
            _SectionHeader(title: l.settingsTheme),
            _ThemeToggleTile(),
            const SizedBox(height: 24),

            // Sound / Haptic toggle
            _SectionHeader(title: l.settingsEffects),
            _SoundToggleTile(),
            const SizedBox(height: 24),

            // Notification toggle
            _SectionHeader(title: l.settingsNotification),
            _NotificationToggleTile(),
            const SizedBox(height: 24),

            // Game info
            _SectionHeader(title: l.settingsGameInfo),
            _InfoTile(label: l.settingsVersion, value: '1.0.0'),
            _InfoTile(
              label: l.settingsOwnedMonster,
              value: '${ref.watch(monsterListProvider.select((list) => list.length))}',
            ),
            const SizedBox(height: 24),

            // Default battle speed
            _SectionHeader(title: l.settingsDefaultSpeed),
            _DefaultSpeedTile(),
            const SizedBox(height: 24),

            // Auto battle default
            _SectionHeader(title: l.settingsAutoDefault),
            _AutoBattleDefaultTile(),
            const SizedBox(height: 24),

            // Data usage
            _SectionHeader(title: l.settingsDataUsage),
            _InfoTile(
              label: l.settingsMonsterCount,
              value: '${ref.watch(monsterListProvider.select((list) => list.length))}',
            ),
            _InfoTile(
              label: l.settingsRelicCount,
              value: '${ref.watch(relicProvider.select((list) => list.length))}',
            ),
            const SizedBox(height: 24),

            // Relic
            _SectionHeader(title: l.settingsRelicEquip),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.relic),
                icon: const Icon(Icons.inventory, size: 22),
                label: Text(
                  l.settingsRelicManage,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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

            // Relic auto-dismantle
            _RelicDismantleTile(),
            const SizedBox(height: 24),

            // Prestige
            _SectionHeader(title: l.settingsPrestige),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.prestige),
                icon: const Icon(Icons.autorenew, size: 22),
                label: Text(
                  l.settingsPrestigeGo,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
            _SectionHeader(title: l.settingsBackupRestore),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportData(context),
                    icon: const Icon(Icons.upload, size: 20),
                    label: Text(l.settingsBackupCopy),
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
                    label: Text(l.settingsRestorePaste),
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
            _SectionHeader(title: l.settingsData),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmReset(context, ref),
                icon: Icon(Icons.delete_forever, color: AppColors.error),
                label: Text(
                  l.settingsGameReset,
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

            // Credits
            _SectionHeader(title: l.settingsCredits),
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.settingsCreditsTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.settingsCreditsBody,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _exportData(BuildContext context) {
    final json = LocalStorage.instance.exportToJson();
    Clipboard.setData(ClipboardData(text: json));
    if (context.mounted) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.settingsBackupDone),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _importData(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l.settingsRestoreTitle,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l.settingsRestoreDesc,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.cancel, style: TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data?.text == null || data!.text!.isEmpty) {
                if (context.mounted) {
                  final lInner = AppLocalizations.of(context)!;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(lInner.settingsNoClipboard),
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
                final lInner = AppLocalizations.of(context)!;
                if (success) {
                  ref.invalidate(playerProvider);
                  ref.invalidate(currencyProvider);
                  ref.invalidate(monsterListProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(lInner.settingsRestoreDone),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(lInner.settingsRestoreFail),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(l.restore, style: const TextStyle(color: Colors.indigo)),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l.settingsResetTitle,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l.settingsResetDesc,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.cancel, style: TextStyle(color: AppColors.textTertiary)),
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
            child: Text(l.settingsResetConfirm, style: TextStyle(color: AppColors.error)),
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
    final l = AppLocalizations.of(context)!;
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
            l.settingsSound,
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

class _ThemeToggleTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: Row(
        children: [
          Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: isDark ? Colors.indigo : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            isDark ? l.settingsThemeDark : l.settingsThemeLight,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Switch(
            value: !isDark,
            activeTrackColor: Colors.orange.withValues(alpha: 0.5),
            activeThumbColor: Colors.orange,
            onChanged: (_) {
              ref.read(themeModeProvider.notifier).toggle();
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

class _NotificationToggleTile extends StatefulWidget {
  @override
  State<_NotificationToggleTile> createState() => _NotificationToggleTileState();
}

class _NotificationToggleTileState extends State<_NotificationToggleTile> {
  @override
  Widget build(BuildContext context) {
    final enabled = NotificationService.instance.isEnabled;
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: Row(
        children: [
          Icon(
            enabled ? Icons.notifications_active : Icons.notifications_off,
            color: enabled ? Colors.blue : AppColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            l.settingsNotificationToggle,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Switch(
            value: enabled,
            activeTrackColor: Colors.blue.withValues(alpha: 0.5),
            activeThumbColor: Colors.blue,
            onChanged: (v) {
              NotificationService.instance.setEnabled(v);
              setState(() {});
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

// =============================================================================
// Relic dismantle tile
// =============================================================================

class _RelicDismantleTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final relics = ref.watch(relicProvider);
    final unequippedCount = relics.where((r) => !r.isEquipped).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: l.relicDismantle),
        const SizedBox(height: 8),
        Text(
          l.relicDismantleDesc(unequippedCount),
          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int rarity = 1; rarity <= 3; rarity++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: rarity < 3 ? 8 : 0),
                  child: ElevatedButton(
                    onPressed: () => _dismantle(context, ref, rarity),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _rarityColor(rarity).withValues(alpha: 0.2),
                      foregroundColor: _rarityColor(rarity),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: _rarityColor(rarity).withValues(alpha: 0.4)),
                      ),
                    ),
                    child: Text(
                      '${'⭐' * rarity}↓',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Color _rarityColor(int rarity) => switch (rarity) {
    1 => Colors.grey,
    2 => Colors.green,
    3 => Colors.blue,
    _ => Colors.white,
  };

  void _dismantle(BuildContext context, WidgetRef ref, int maxRarity) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.relicDismantle),
        content: Text(l.relicDismantleConfirm(maxRarity)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () {
              final gold = ref.read(relicProvider.notifier).dismantleByRarity(maxRarity);
              if (gold > 0) {
                ref.read(currencyProvider.notifier).addGold(gold);
              }
              Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l.relicDismantleResult(gold)),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(l.confirm),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Default speed tile
// =============================================================================

class _DefaultSpeedTile extends StatefulWidget {
  @override
  State<_DefaultSpeedTile> createState() => _DefaultSpeedTileState();
}

class _DefaultSpeedTileState extends State<_DefaultSpeedTile> {
  double _speed = 2.0;

  @override
  void initState() {
    super.initState();
    _speed = LocalStorage.instance.getSetting('defaultBattleSpeed') ?? 2.0;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: [
          Icon(Icons.speed, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Text(
            l.settingsSpeedLabel,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const Spacer(),
          SegmentedButton<double>(
            segments: const [
              ButtonSegment(value: 1.0, label: Text('1x')),
              ButtonSegment(value: 2.0, label: Text('2x')),
              ButtonSegment(value: 3.0, label: Text('3x')),
            ],
            selected: {_speed},
            onSelectionChanged: (v) {
              setState(() => _speed = v.first);
              LocalStorage.instance.setSetting('defaultBattleSpeed', _speed);
            },
            style: ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Auto battle default tile
// =============================================================================

class _AutoBattleDefaultTile extends StatefulWidget {
  @override
  State<_AutoBattleDefaultTile> createState() => _AutoBattleDefaultTileState();
}

class _AutoBattleDefaultTileState extends State<_AutoBattleDefaultTile> {
  bool _autoDefault = true;

  @override
  void initState() {
    super.initState();
    _autoDefault = LocalStorage.instance.getSetting('defaultAutoMode') ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: Row(
        children: [
          Icon(
            _autoDefault ? Icons.autorenew : Icons.touch_app,
            color: _autoDefault ? Colors.green : AppColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            l.settingsAutoLabel,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Switch(
            value: _autoDefault,
            activeTrackColor: Colors.green.withValues(alpha: 0.5),
            activeThumbColor: Colors.green,
            onChanged: (v) {
              setState(() => _autoDefault = v);
              LocalStorage.instance.setSetting('defaultAutoMode', v);
            },
          ),
        ],
      ),
    );
  }
}
