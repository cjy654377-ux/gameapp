import 'dart:math';
import 'package:flutter/material.dart';

/// Full-screen evolution animation overlay.
/// Shows a 3-phase animation: glow+scale → white flash → new form reveal.
class EvolutionAnimationOverlay extends StatefulWidget {
  const EvolutionAnimationOverlay({
    super.key,
    required this.oldWidget,
    required this.newWidget,
    required this.onComplete,
  });

  final Widget oldWidget;
  final Widget newWidget;
  final VoidCallback onComplete;

  static Future<void> show(
    BuildContext context, {
    required Widget oldMonster,
    required Widget newMonster,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => EvolutionAnimationOverlay(
        oldWidget: oldMonster,
        newWidget: newMonster,
        onComplete: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<EvolutionAnimationOverlay> createState() =>
      _EvolutionAnimationOverlayState();
}

class _EvolutionAnimationOverlayState extends State<EvolutionAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Phase 1 (0.0 ~ 0.3): old monster scales up + glow builds
  late Animation<double> _oldScale;
  late Animation<double> _glowIntensity;

  // Phase 2 (0.3 ~ 0.6): white flash opacity (0→1 then stays)
  late Animation<double> _flashOpacity;
  late Animation<double> _oldMonsterOpacity;

  // Phase 3 (0.6 ~ 1.0): flash fades out, new monster reveals + stars
  late Animation<double> _flashFadeOut;
  late Animation<double> _newMonsterScale;
  late Animation<double> _newMonsterOpacity;
  late Animation<double> _starProgress;

  static const int _starCount = 12;
  final _random = Random(42);
  late List<double> _starSizes;
  late List<double> _starAngles;
  late List<double> _starMaxRadius;

  @override
  void initState() {
    super.initState();

    _starSizes = List.generate(
      _starCount,
      (i) => 8.0 + _random.nextDouble() * 4.0,
    );
    _starAngles = List.generate(
      _starCount,
      (i) => (2 * pi * i) / _starCount,
    );
    _starMaxRadius = List.generate(
      _starCount,
      (i) => 80.0 + _random.nextDouble() * 40.0,
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Phase 1: 0.0 → 0.3
    _oldScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
      ),
    );

    _glowIntensity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Phase 2: 0.3 → 0.6
    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeIn),
      ),
    );

    _oldMonsterOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.5, curve: Curves.easeOut),
      ),
    );

    // Phase 3: 0.6 → 1.0
    _flashFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.8, curve: Curves.easeOut),
      ),
    );

    _newMonsterScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.9, curve: Curves.elasticOut),
      ),
    );

    _newMonsterOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.75, curve: Curves.easeIn),
      ),
    );

    _starProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skipAnimation() {
    _controller.forward(from: 0.95);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _skipAnimation,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final controllerValue = _controller.value;
            final isPhase1 = controllerValue < 0.3;
            final isPhase2 = controllerValue >= 0.3 && controllerValue < 0.6;
            final isPhase3 = controllerValue >= 0.6;

            return Stack(
              alignment: Alignment.center,
              children: [
                // Semi-transparent background
                Container(color: Colors.black54),

                // Phase 1 & 2: Old monster with glow
                if (!isPhase3)
                  Opacity(
                    opacity: _oldMonsterOpacity.value,
                    child: Transform.scale(
                      scale: isPhase1 ? _oldScale.value : 1.3,
                      child: _buildGlowContainer(
                        child: widget.oldWidget,
                        intensity: isPhase1
                            ? _glowIntensity.value
                            : isPhase2
                                ? 1.0
                                : 0.0,
                      ),
                    ),
                  ),

                // Phase 3: New monster with elastic scale
                if (isPhase3)
                  Opacity(
                    opacity: _newMonsterOpacity.value,
                    child: Transform.scale(
                      scale: _newMonsterScale.value,
                      child: widget.newWidget,
                    ),
                  ),

                // Phase 3: Star particles
                if (isPhase3) _buildStarParticles(),

                // White flash overlay (phase 2 → fades in phase 3)
                if (isPhase2 || isPhase3)
                  Opacity(
                    opacity: isPhase2
                        ? _flashOpacity.value
                        : _flashFadeOut.value,
                    child: Container(color: Colors.white),
                  ),

                // Skip hint text
                Positioned(
                  bottom: 60,
                  child: Opacity(
                    opacity: (controllerValue < 0.9) ? 0.6 : 0.0,
                    child: const Text(
                      '탭하여 건너뛰기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlowContainer({
    required Widget child,
    required double intensity,
  }) {
    if (intensity <= 0) return child;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: intensity * 0.6),
            blurRadius: 20 + intensity * 40,
            spreadRadius: intensity * 20,
          ),
          BoxShadow(
            color: Colors.amber.withValues(alpha: intensity * 0.4),
            blurRadius: 10 + intensity * 30,
            spreadRadius: intensity * 10,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildStarParticles() {
    final progress = _starProgress.value;

    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(_starCount, (i) {
          final angle = _starAngles[i];
          final radius = _starMaxRadius[i] * progress;
          final opacity = (1.0 - progress * 0.8).clamp(0.0, 1.0);

          final dx = cos(angle) * radius;
          final dy = sin(angle) * radius;

          return Transform.translate(
            offset: Offset(dx, dy),
            child: Opacity(
              opacity: opacity,
              child: Icon(
                Icons.star,
                size: _starSizes[i],
                color: Colors.amber,
              ),
            ),
          );
        }),
      ),
    );
  }
}
