import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// HP bar rendered above each monster. Green→Yellow→Red gradient.
/// Separate blue overlay for shield HP.
class HpBarComponent extends PositionComponent {
  final double maxHp;
  double _currentHp;
  double _displayHp; // smoothly interpolated
  double _shieldHp;
  final double barWidth;

  static const double barHeight = 5;

  HpBarComponent({
    required this.maxHp,
    required double currentHp,
    required double shieldHp,
    required super.position,
    this.barWidth = 48,
  })  : _currentHp = currentHp,
        _displayHp = currentHp,
        _shieldHp = shieldHp,
        super(size: Vector2(barWidth, barHeight), anchor: Anchor.center);

  void updateHp(double hp, double shield) {
    _currentHp = hp;
    _shieldHp = shield;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Smooth tween toward actual HP
    final diff = _currentHp - _displayHp;
    if (diff.abs() > 0.5) {
      _displayHp += diff * (dt * 8).clamp(0, 1);
    } else {
      _displayHp = _currentHp;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final w = barWidth;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w / 2, 0, w, barHeight),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.black54,
    );

    // HP fill
    final pct = (maxHp > 0) ? (_displayHp / maxHp).clamp(0.0, 1.0) : 0.0;
    if (pct > 0) {
      final hpColor = pct > 0.5
          ? Color.lerp(Colors.yellow, Colors.green, (pct - 0.5) * 2)!
          : Color.lerp(Colors.red, Colors.yellow, pct * 2)!;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-w / 2, 0, w * pct, barHeight),
          const Radius.circular(2),
        ),
        Paint()..color = hpColor,
      );
    }

    // Shield overlay (blue)
    if (_shieldHp > 0 && maxHp > 0) {
      final shieldPct = (_shieldHp / maxHp).clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-w / 2, 0, w * shieldPct, barHeight),
          const Radius.circular(2),
        ),
        Paint()..color = Colors.cyan.withValues(alpha: 0.5),
      );
    }

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w / 2, 0, w, barHeight),
        const Radius.circular(2),
      ),
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }
}
