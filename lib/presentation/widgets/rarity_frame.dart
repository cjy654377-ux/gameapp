import 'dart:math';

import 'package:flutter/material.dart';

/// Decorative frame widget that wraps a child with rarity-appropriate visual effects.
///
/// - 1-2 star (normal/advanced): no frame, returns child as-is
/// - 3 star (rare): static blue glow border
/// - 4 star (epic): pulsing purple border + hexagon background pattern
/// - 5 star (legendary): pulsing gold border + constellation pattern + sparkle particles
class RarityFrame extends StatefulWidget {
  const RarityFrame({
    super.key,
    required this.rarity,
    required this.child,
    this.size = 60,
    this.animate = true,
  });

  /// Monster rarity value (1-5).
  final int rarity;

  /// The widget to wrap with the frame.
  final Widget child;

  /// Size of the frame area (width and height).
  final double size;

  /// When false, skips AnimationController creation for performance.
  final bool animate;

  @override
  State<RarityFrame> createState() => _RarityFrameState();
}

class _RarityFrameState extends State<RarityFrame>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  void _initAnimation() {
    // Only create AnimationController for rarity 4+ and when animate is true.
    if (widget.animate && widget.rarity >= 4) {
      final duration = widget.rarity >= 5
          ? const Duration(milliseconds: 1200) // legendary: faster pulse
          : const Duration(milliseconds: 1800); // epic: slower pulse

      _controller = AnimationController(vsync: this, duration: duration)
        ..repeat();

      _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void didUpdateWidget(RarityFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rarity != widget.rarity || oldWidget.animate != widget.animate) {
      _controller?.dispose();
      _controller = null;
      _pulseAnimation = null;
      _initAnimation();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1-2 star: no frame decoration — return child directly.
    if (widget.rarity <= 2) {
      return widget.child;
    }

    // 3 star: static rare frame (no animation).
    if (widget.rarity == 3) {
      return RepaintBoundary(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _RarityFramePainter(rarity: 3, phase: 0.0),
              ),
              widget.child,
            ],
          ),
        ),
      );
    }

    // 4-5 star: animated frame using AnimationBuilder.
    if (_pulseAnimation != null) {
      return RepaintBoundary(
        child: AnimatedBuilder(
          animation: _pulseAnimation!,
          builder: (context, child) {
            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _RarityFramePainter(
                      rarity: widget.rarity,
                      phase: _pulseAnimation!.value,
                    ),
                  ),
                  widget.child,
                  if (widget.rarity >= 5)
                    CustomPaint(
                      painter: _SparklePainter(phase: _pulseAnimation!.value),
                    ),
                ],
              ),
            );
          },
        ),
      );
    }

    // Fallback: animate=false, rarity 4-5, render static at phase 0.5.
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _RarityFramePainter(rarity: widget.rarity, phase: 0.5),
            ),
            widget.child,
            if (widget.rarity >= 5)
              CustomPaint(
                painter: _SparklePainter(phase: 0.5),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _RarityFramePainter
// ---------------------------------------------------------------------------

/// Paints the rarity-based frame decoration behind the monster portrait.
///
/// [phase] ranges 0.0–1.0 and drives pulse animations for rarity 4+.
class _RarityFramePainter extends CustomPainter {
  const _RarityFramePainter({
    required this.rarity,
    required this.phase,
  });

  final int rarity;
  final double phase;

  static const _blueColor = Color(0xFF42A5F5);
  static const _purpleColor = Color(0xFF9C27B0);
  static const _goldColor = Color(0xFFFFD700);

  @override
  void paint(Canvas canvas, Size size) {
    switch (rarity) {
      case 3:
        _paintRareBorder(canvas, size);
      case 4:
        _paintEpicBackground(canvas, size);
        _paintEpicBorder(canvas, size);
      case 5:
        _paintLegendaryBackground(canvas, size);
        _paintLegendaryBorder(canvas, size);
    }
  }

  // --- Rare (3 star): static blue glow border ---

  void _paintRareBorder(Canvas canvas, Size size) {
    final rrect = _frameRRect(size, inset: 1.5);
    final paint = Paint()
      ..color = _blueColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(rrect, paint);

    // Solid border on top of glow.
    final solidPaint = Paint()
      ..color = _blueColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect, solidPaint);
  }

  // --- Epic (4 star): hexagon background + pulsing purple border ---

  void _paintEpicBackground(Canvas canvas, Size size) {
    // Clip to the frame area to prevent hexagons overflowing.
    canvas.save();
    canvas.clipRRect(_frameRRect(size, inset: 0));

    final hexPaint = Paint()
      ..color = _purpleColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final hexRadius = size.width * 0.18;
    final dx = hexRadius * sqrt(3);
    final dy = hexRadius * 1.5;

    // Tile hexagons across the entire area.
    var row = 0;
    for (var y = -hexRadius; y < size.height + hexRadius; y += dy) {
      final offsetX = (row % 2 == 0) ? 0.0 : dx / 2;
      for (var x = -dx + offsetX; x < size.width + dx; x += dx) {
        _drawHexagon(canvas, Offset(x, y), hexRadius, hexPaint);
      }
      row++;
    }

    canvas.restore();
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = pi / 6 + i * pi / 3; // flat-top hexagon offset
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _paintEpicBorder(Canvas canvas, Size size) {
    // Alpha pulses between 0.3 and 0.7.
    final alpha = 0.3 + 0.4 * sin(phase * 2 * pi);
    final rrect = _frameRRect(size, inset: 1.5);

    final glowPaint = Paint()
      ..color = _purpleColor.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(rrect, glowPaint);

    final solidPaint = Paint()
      ..color = _purpleColor.withValues(alpha: (alpha + 0.2).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect, solidPaint);
  }

  // --- Legendary (5 star): constellation background + pulsing gold border ---

  void _paintLegendaryBackground(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRRect(_frameRRect(size, inset: 0));

    // Generate a stable set of star positions using a fixed seed.
    const seed = 0xDEADBEEF;
    final rng = Random(seed);

    const starCount = 12;
    final stars = List.generate(starCount, (_) {
      return Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height,
      );
    });

    // Constellation lines between nearby stars.
    final linePaint = Paint()
      ..color = _goldColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (var i = 0; i < stars.length; i++) {
      for (var j = i + 1; j < stars.length; j++) {
        final dist = (stars[i] - stars[j]).distance;
        if (dist < size.width * 0.45) {
          canvas.drawLine(stars[i], stars[j], linePaint);
        }
      }
    }

    // Star dots.
    final dotPaint = Paint()
      ..color = _goldColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    for (final star in stars) {
      canvas.drawCircle(star, 1.2, dotPaint);
    }

    canvas.restore();
  }

  void _paintLegendaryBorder(Canvas canvas, Size size) {
    // Faster pulse for legendary.
    final alpha = 0.4 + 0.4 * sin(phase * 2 * pi);
    final rrect = _frameRRect(size, inset: 1.5);

    // Outer wide glow.
    final outerGlowPaint = Paint()
      ..color = _goldColor.withValues(alpha: alpha * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(rrect, outerGlowPaint);

    // Inner tighter glow.
    final innerGlowPaint = Paint()
      ..color = _goldColor.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(rrect, innerGlowPaint);

    // Crisp solid border.
    final solidPaint = Paint()
      ..color = _goldColor.withValues(alpha: (alpha + 0.2).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect, solidPaint);
  }

  // --- Helpers ---

  RRect _frameRRect(Size size, {required double inset}) {
    return RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2),
      const Radius.circular(8),
    );
  }

  @override
  bool shouldRepaint(_RarityFramePainter oldDelegate) {
    return oldDelegate.rarity != rarity || oldDelegate.phase != phase;
  }
}

// ---------------------------------------------------------------------------
// _SparklePainter
// ---------------------------------------------------------------------------

/// Paints up to 5 sparkling star particles that slowly drift around the frame.
///
/// Used exclusively for 5-star (legendary) rarity. Positions are derived
/// deterministically from [phase] so they animate smoothly.
class _SparklePainter extends CustomPainter {
  const _SparklePainter({required this.phase});

  final double phase;

  static const _goldColor = Color(0xFFFFD700);
  static const _sparkleCount = 5;

  // Fixed base positions as fractional offsets (0.0–1.0) within the frame.
  // Chosen to cluster near the border edges.
  static const _basePositions = [
    Offset(0.1, 0.15),
    Offset(0.85, 0.1),
    Offset(0.92, 0.75),
    Offset(0.15, 0.88),
    Offset(0.5, 0.05),
  ];

  // Each sparkle drifts with a unique frequency offset.
  static const _driftOffsets = [0.0, 0.2, 0.4, 0.6, 0.8];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _sparkleCount; i++) {
      final driftPhase = (phase + _driftOffsets[i]) % 1.0;

      // Brightness pulses per sparkle.
      final brightness = (0.4 + 0.6 * sin(driftPhase * 2 * pi)).clamp(0.0, 1.0);
      if (brightness < 0.1) continue; // skip nearly-invisible sparkles

      // Subtle drift: ±3% of size.
      final driftX = sin(driftPhase * 2 * pi + i) * size.width * 0.03;
      final driftY = cos(driftPhase * 2 * pi + i) * size.height * 0.03;

      final center = Offset(
        _basePositions[i].dx * size.width + driftX,
        _basePositions[i].dy * size.height + driftY,
      );

      final sparkleRadius = 3.0 + 2.0 * brightness;

      _drawStar(
        canvas,
        center: center,
        radius: sparkleRadius,
        innerRadius: sparkleRadius * 0.4,
        points: 4,
        color: _goldColor.withValues(alpha: brightness),
      );
    }
  }

  void _drawStar(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double innerRadius,
    required int points,
    required Color color,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final angleStep = pi / points; // angle between outer and inner point
    final startAngle = -pi / 2; // start from top

    for (var i = 0; i < points * 2; i++) {
      final angle = startAngle + i * angleStep;
      final r = (i % 2 == 0) ? radius : innerRadius;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Add a small glow behind the star.
    final glowPaint = Paint()
      ..color = color.withValues(alpha: (color.a * 0.5).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, radius * 0.6, glowPaint);
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}
