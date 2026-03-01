import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// Floating damage number that rises and fades out.
/// Uses manual alpha tracking instead of OpacityEffect (TextComponent
/// doesn't implement OpacityProvider).
class DamageTextComponent extends PositionComponent {
  final String _text;
  final Color _color;
  final double _fontSize;
  final bool _isCritical;

  double _alpha = 1.0;
  double _elapsed = 0;
  static const double _lifetime = 0.9;

  DamageTextComponent({
    required int damage,
    required bool isCritical,
    required bool isSkill,
    required bool isElementAdvantage,
    required Vector2 spawnPosition,
  })  : _text = '${isCritical ? "!" : ""}$damage',
        _color = _pickColor(isCritical, isSkill, isElementAdvantage),
        _fontSize = isCritical ? 18.0 : 14.0,
        _isCritical = isCritical,
        super(position: spawnPosition, anchor: Anchor.center);

  static Color _pickColor(bool isCritical, bool isSkill, bool isElementAdvantage) {
    if (isCritical) return const Color(0xFFFF4444);
    if (isSkill) return const Color(0xFFBB66FF);
    if (isElementAdvantage) return const Color(0xFF00E5FF);
    return Colors.white;
  }

  @override
  Future<void> onLoad() async {
    // Rise upward
    add(MoveByEffect(
      Vector2(0, -40),
      EffectController(duration: 0.8, curve: Curves.easeOut),
    ));

    // Scale pop for criticals
    if (_isCritical) {
      add(ScaleEffect.by(
        Vector2.all(1.4),
        EffectController(duration: 0.15, reverseDuration: 0.15),
      ));
    }

    // Self-remove after animation
    add(RemoveEffect(delay: _lifetime));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    // Fade out over lifetime
    _alpha = (1.0 - (_elapsed / _lifetime)).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final tp = TextPainter(
      text: TextSpan(
        text: _text,
        style: TextStyle(
          color: _color.withValues(alpha: _alpha),
          fontSize: _fontSize * scale.x,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: _alpha),
              blurRadius: 3,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }
}
