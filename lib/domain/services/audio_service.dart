import 'package:flutter/services.dart';

// =============================================================================
// AudioService — haptic and system sound feedback
// =============================================================================

/// Provides haptic feedback and system sounds for game events.
///
/// Uses [HapticFeedback] for tactile responses since actual audio playback
/// requires additional packages (audioplayers, etc.). This provides
/// satisfying feedback without extra dependencies.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  bool _enabled = true;

  bool get isEnabled => _enabled;

  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  // ---------------------------------------------------------------------------
  // Battle sounds (haptic feedback)
  // ---------------------------------------------------------------------------

  /// Normal attack hit.
  void playHit() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Critical hit.
  void playCriticalHit() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Skill activation.
  void playSkillActivation() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Monster defeated.
  void playDefeat() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Victory.
  void playVictory() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  // ---------------------------------------------------------------------------
  // UI sounds
  // ---------------------------------------------------------------------------

  /// Button tap.
  void playTap() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Gacha pull.
  void playGachaPull() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Card reveal.
  void playCardReveal() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// High rarity gacha result (4-5 star).
  void playHighRarityReveal() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Level up.
  void playLevelUp() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Evolution success.
  void playEvolution() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Reward collected.
  void playRewardCollect() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Error / failure.
  void playError() {
    if (!_enabled) return;
    HapticFeedback.vibrate();
  }

  /// Prestige reset.
  void playPrestige() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }
}
