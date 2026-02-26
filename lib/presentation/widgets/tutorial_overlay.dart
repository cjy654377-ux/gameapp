import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../providers/player_provider.dart';
import 'package:gameapp/l10n/app_localizations.dart';

// =============================================================================
// Tutorial step definitions
// =============================================================================

/// Tutorial steps (stored in PlayerModel.tutorialStep).
///
/// 0 = fresh player (show battle intro)
/// 1 = first battle started (show victory hint after win)
/// 2 = first victory collected (show gacha hint)
/// 3 = first gacha done (show upgrade hint)
/// 4 = first upgrade done (show team hint)
/// 5 = team editing done → tutorial complete (set to 99)
/// 99 = completed
class TutorialSteps {
  static const int battleIntro = 0;
  static const int afterFirstVictory = 1;
  static const int gachaIntro = 2;
  static const int upgradeIntro = 3;
  static const int teamIntro = 4;
  static const int completed = 99;
}

// =============================================================================
// Tutorial data per step
// =============================================================================

class _StepData {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const _StepData({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });
}

Map<int, _StepData> _buildStepDataMap(AppLocalizations l) => {
  TutorialSteps.battleIntro: _StepData(
    title: l.tutorialStep1Title,
    message: l.tutorialStep1Msg,
    icon: Icons.sports_mma,
    color: Colors.red,
  ),
  TutorialSteps.afterFirstVictory: _StepData(
    title: l.tutorialStep2Title,
    message: l.tutorialStep2Msg,
    icon: Icons.auto_awesome,
    color: Colors.amber,
  ),
  TutorialSteps.gachaIntro: _StepData(
    title: l.tutorialStep3Title,
    message: l.tutorialStep3Msg,
    icon: Icons.catching_pokemon,
    color: Colors.purple,
  ),
  TutorialSteps.upgradeIntro: _StepData(
    title: l.tutorialStep4Title,
    message: l.tutorialStep4Msg,
    icon: Icons.upgrade,
    color: Colors.green,
  ),
  TutorialSteps.teamIntro: _StepData(
    title: l.tutorialStep5Title,
    message: l.tutorialStep5Msg,
    icon: Icons.groups,
    color: Colors.blue,
  ),
};

// =============================================================================
// TutorialOverlay widget
// =============================================================================

/// Shows a contextual tutorial hint overlay for the given [forStep].
///
/// Only renders when the player's current tutorialStep matches [forStep].
/// Tapping "확인" advances to the next step.
class TutorialOverlay extends ConsumerWidget {
  const TutorialOverlay({
    super.key,
    required this.forStep,
    required this.child,
    this.nextStep,
  });

  /// The tutorial step this overlay corresponds to.
  final int forStep;

  /// The widget to show beneath the overlay.
  final Widget child;

  /// Override next step value (defaults to forStep + 1).
  final int? nextStep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final playerState = ref.watch(playerProvider);
    final player = playerState.player;

    // Don't show overlay if no player or tutorial already past this step.
    if (player == null || player.tutorialStep != forStep) {
      return child;
    }

    final stepData = _buildStepDataMap(l)[forStep];
    if (stepData == null) return child;

    return Stack(
      children: [
        child,
        // Semi-transparent backdrop.
        Positioned.fill(
          child: GestureDetector(
            onTap: () => _advance(ref),
            child: Container(
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ),
        // Tutorial card.
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: stepData.color.withValues(alpha: 0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: stepData.color.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stepData.color.withValues(alpha: 0.2),
                      ),
                      child: Icon(
                        stepData.icon,
                        color: stepData.color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      stepData.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      stepData.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _advance(ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: stepData.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l.confirm,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _advance(WidgetRef ref) {
    final next = nextStep ?? (forStep + 1);
    ref.read(playerProvider.notifier).advanceTutorial(next);
  }
}
