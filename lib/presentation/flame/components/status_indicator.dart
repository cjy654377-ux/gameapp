import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Renders persistent status effect visuals around a monster.
class StatusIndicatorComponent extends PositionComponent {
  bool _hasBurn;
  bool _hasStun;
  bool _hasShield;
  final double radius;

  double _phase = 0;
  final _rng = Random();

  // Burn flame particles (persistent)
  final List<_FlameParticle> _flames = [];

  StatusIndicatorComponent({
    required bool hasBurn,
    required bool hasStun,
    required bool hasShield,
    required this.radius,
    super.position,
  })  : _hasBurn = hasBurn,
        _hasStun = hasStun,
        _hasShield = hasShield,
        super(anchor: Anchor.center);

  void updateStatus({
    required bool hasBurn,
    required bool hasStun,
    required bool hasShield,
  }) {
    _hasBurn = hasBurn;
    _hasStun = hasStun;
    _hasShield = hasShield;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * 3;

    // Update burn flames
    if (_hasBurn) {
      // Spawn new flame particles
      if (_flames.length < 4 && _rng.nextDouble() < dt * 8) {
        _flames.add(_FlameParticle(
          x: (_rng.nextDouble() - 0.5) * radius,
          y: radius * 0.3,
          life: 1.0,
        ));
      }
      // Update existing
      for (final f in _flames) {
        f.y -= dt * 30;
        f.life -= dt * 2;
      }
      _flames.removeWhere((f) => f.life <= 0);
    } else {
      _flames.clear();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Shield: translucent blue glow
    if (_hasShield) {
      final shieldAlpha = (0.15 + 0.08 * sin(_phase)).clamp(0.0, 1.0);
      final shieldPaint = Paint()
        ..color = Colors.cyan.withValues(alpha: shieldAlpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, radius + 6, shieldPaint);

      final borderPaint = Paint()
        ..color = Colors.cyan.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset.zero, radius + 6, borderPaint);
    }

    // Burn: rising flame particles
    if (_hasBurn) {
      for (final f in _flames) {
        final alpha = (f.life).clamp(0.0, 1.0);
        final fireSize = 3.0 + f.life * 3;
        final paint = Paint()
          ..color = Color.lerp(
            Colors.red,
            Colors.orange,
            f.life,
          )!.withValues(alpha: alpha);
        canvas.drawCircle(Offset(f.x, f.y), fireSize, paint);
      }
    }

    // Stun: rotating lightning bolt icon above head
    if (_hasStun) {
      canvas.save();
      canvas.translate(0, -radius - 14);
      canvas.rotate(sin(_phase * 2) * 0.3);

      final boltPaint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(-3, -6);
      path.lineTo(2, -1);
      path.lineTo(-1, 0);
      path.lineTo(3, 6);
      path.lineTo(-2, 1);
      path.lineTo(1, 0);
      path.close();
      canvas.drawPath(path, boltPaint);

      canvas.restore();
    }
  }
}

class _FlameParticle {
  double x;
  double y;
  double life;

  _FlameParticle({required this.x, required this.y, required this.life});
}
