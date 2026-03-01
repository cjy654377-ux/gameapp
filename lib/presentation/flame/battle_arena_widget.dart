import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/l10n/app_localizations.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/presentation/flame/battle_game.dart';
import 'package:gameapp/presentation/providers/battle_provider.dart';
import 'package:gameapp/presentation/widgets/procedural_background_painter.dart';

/// Bridge widget: Riverpod state → BattleGame (Flame).
/// Renders Flutter background image underneath transparent Flame canvas.
class BattleArenaWidget extends ConsumerStatefulWidget {
  const BattleArenaWidget({super.key});

  @override
  ConsumerState<BattleArenaWidget> createState() => _BattleArenaWidgetState();
}

class _BattleArenaWidgetState extends ConsumerState<BattleArenaWidget> {
  late final BattleGame _game;
  bool _autoStarted = false;

  @override
  void initState() {
    super.initState();
    _game = BattleGame();

    // Listen to full battle state changes and forward to Flame game.
    ref.listenManual(battleProvider, (prev, next) {
      if (!mounted) return;
      _game.updateBattleState(next);
    });

    // Auto-restart listener: when phase goes to idle, start a new battle.
    ref.listenManual(battleProvider.select((s) => s.phase), (prev, next) {
      if (!mounted) return;
      if (next == BattlePhase.idle && !_autoStarted) {
        _autoStarted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _autoStarted = false;
          ref.read(battleProvider.notifier).startBattle();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final phase = ref.watch(battleProvider.select((s) => s.phase));

    // Show loading spinner when idle (auto-restart in progress)
    if (phase == BattlePhase.idle) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              l.preparingBattle,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Compute background path from stageId
    final stageId = ref.watch(battleProvider.select((s) => s.currentStageId));
    final areaIndex = ((stageId - 1) ~/ 6 + 1).clamp(1, 6);
    const areaNames = ['forest', 'volcano', 'dungeon', 'ocean', 'sky', 'abyss'];
    final areaName = areaNames[areaIndex - 1];

    return Stack(
      children: [
        // Procedural background (Flutter layer)
        Positioned.fill(
          child: CustomPaint(
            painter: ProceduralBackgroundPainter(areaName: areaName),
          ),
        ),
        // Dark overlay
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.45)),
        ),
        // Flame game canvas (transparent)
        Positioned.fill(
          child: GameWidget(game: _game),
        ),
      ],
    );
  }
}
