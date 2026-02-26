import 'dart:async';

/// Manages the game's recurring tick loop and auto-save timer.
///
/// Call [startTick] to begin the 500 ms idle-game update loop and
/// [startAutoSave] to schedule periodic save callbacks.  Both timers are
/// independent and can be started / stopped individually.
///
/// Always call [dispose] when the service owner (e.g. a Riverpod notifier or
/// a StatefulWidget) is destroyed to prevent timer leaks.
class GameTickService {
  Timer? _tickTimer;
  Timer? _saveTimer;

  /// The interval between consecutive tick callbacks.
  static const Duration tickDuration = Duration(milliseconds: 500);

  /// The interval between consecutive auto-save callbacks.
  static const Duration saveDuration = Duration(seconds: 30);

  /// Whether the tick loop is currently running.
  bool get isRunning => _tickTimer != null;

  /// Whether the auto-save timer is currently running.
  bool get isSaving => _saveTimer != null;

  // ---------------------------------------------------------------------------
  // Tick loop
  // ---------------------------------------------------------------------------

  /// Starts the game tick loop, calling [onTick] every [tickDuration].
  ///
  /// If the tick loop is already running this is a no-op (the existing timer
  /// is left untouched).  Call [stopTick] first if you need to restart with a
  /// new callback.
  void startTick(void Function() onTick) {
    if (_tickTimer != null) return; // already running
    _tickTimer = Timer.periodic(tickDuration, (_) => onTick());
  }

  /// Stops the tick loop.  Has no effect if the loop is not running.
  void stopTick() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  // ---------------------------------------------------------------------------
  // Auto-save timer
  // ---------------------------------------------------------------------------

  /// Starts the auto-save timer, calling [onSave] every [saveDuration].
  ///
  /// [onSave] is an async function; the timer fires it and awaits completion
  /// before the next save is considered.  If a save is still in progress when
  /// the next timer event fires, both will run concurrently — callers should
  /// guard against re-entrant saves if needed.
  ///
  /// If the auto-save timer is already running this is a no-op.
  void startAutoSave(Future<void> Function() onSave) {
    if (_saveTimer != null) return; // already running
    _saveTimer = Timer.periodic(saveDuration, (_) => onSave());
  }

  /// Stops the auto-save timer.  Has no effect if it is not running.
  void stopAutoSave() {
    _saveTimer?.cancel();
    _saveTimer = null;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Cancels all active timers.  Must be called when the service is no longer
  /// needed (e.g. in [State.dispose] or a Riverpod notifier's [dispose]).
  void dispose() {
    stopTick();
    stopAutoSave();
  }
}
