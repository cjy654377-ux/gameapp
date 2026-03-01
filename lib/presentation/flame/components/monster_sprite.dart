import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart' show MoveByEffect, EffectController;
import 'package:flutter/material.dart';
import 'package:gameapp/core/enums/monster_element.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/presentation/flame/components/hp_bar_component.dart';
import 'package:gameapp/presentation/flame/components/status_indicator.dart';

/// Procedurally drawn monster component — no sprite files needed.
/// Uses templateId.hashCode as seed to generate consistent visuals.
class MonsterSpriteComponent extends PositionComponent {
  final BattleMonster monster;
  final bool isPlayerSide;
  final Color? overrideColor;

  late final int _seed;
  late Color _baseColor;
  late Color _accentColor;
  late final int _bodyType; // 0=circle, 1=triangle, 2=square, 3=diamond
  late final int _eyeCount;
  late final int _spikeCount;
  late final int _patternType; // 0=none, 1=stripes, 2=dots, 3=waves
  late final double _bodyRadius;

  late HpBarComponent _hpBar;
  StatusIndicatorComponent? _statusIndicator;

  bool _isDead = false;
  double _glowPhase = 0;
  double _idlePhase = 0;
  bool _isHero = false;

  MonsterSpriteComponent({
    required this.monster,
    required this.isPlayerSide,
    this.overrideColor,
    super.position,
  }) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _seed = monster.templateId.hashCode;
    final rng = Random(_seed);

    // Element color
    final elem = MonsterElement.fromName(monster.element);
    _baseColor = elem?.color ?? Colors.grey;
    _accentColor = Color.lerp(_baseColor, Colors.white, 0.3)!;
    if (overrideColor != null) {
      _baseColor = overrideColor!;
      _accentColor = Color.lerp(_baseColor, Colors.white, 0.3)!;
    }

    // Body type from seed
    _bodyType = rng.nextInt(4);
    _eyeCount = 1 + rng.nextInt(3); // 1-3
    _spikeCount = rng.nextInt(4); // 0-3
    _patternType = rng.nextInt(4); // 0-3

    // Size mapping
    _bodyRadius = switch (monster.size) {
      'small' => 18.0,
      'medium' => 24.0,
      'large' => 30.0,
      'extraLarge' => 36.0,
      _ => 24.0,
    };

    _isHero = monster.templateId.startsWith('hero');
    size = Vector2(_bodyRadius * 2.4, _bodyRadius * 2.4);

    // HP bar
    _hpBar = HpBarComponent(
      maxHp: monster.maxHp,
      currentHp: monster.currentHp,
      shieldHp: monster.shieldHp,
      position: Vector2(0, -_bodyRadius - 12),
      barWidth: _bodyRadius * 2,
    );
    add(_hpBar);

    _isDead = !monster.isAlive;
  }

  void updateMonster(BattleMonster updated) {
    _hpBar.updateHp(updated.currentHp, updated.shieldHp);

    // Status effects
    final hasBurn = updated.burnTurns > 0;
    final hasStun = updated.stunTurns > 0;
    final hasShield = updated.shieldHp > 0;

    if (hasBurn || hasStun || hasShield) {
      if (_statusIndicator == null) {
        _statusIndicator = StatusIndicatorComponent(
          hasBurn: hasBurn,
          hasStun: hasStun,
          hasShield: hasShield,
          radius: _bodyRadius,
          position: Vector2.zero(),
        );
        add(_statusIndicator!);
      } else {
        _statusIndicator!.updateStatus(
          hasBurn: hasBurn,
          hasStun: hasStun,
          hasShield: hasShield,
        );
      }
    } else if (_statusIndicator != null) {
      _statusIndicator!.removeFromParent();
      _statusIndicator = null;
    }

    if (!updated.isAlive && !_isDead) {
      _isDead = true;
    }
  }

  /// Shake effect when hit.
  void playHitShake() {
    add(
      MoveByEffect(
        Vector2(6, 0),
        EffectController(
          duration: 0.05,
          reverseDuration: 0.05,
          repeatCount: 3,
        ),
      ),
    );
  }

  /// Flash white briefly (manual flag, rendered in render()).
  double _flashTimer = 0;

  void playFlash() {
    _flashTimer = 0.2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _glowPhase += dt * 2;
    _idlePhase += dt * 1.5;
    if (_flashTimer > 0) _flashTimer -= dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    // Idle bobbing
    final bobOffset = sin(_idlePhase) * 2;
    canvas.translate(0, bobOffset);

    if (_isDead) {
      _renderDead(canvas);
    } else if (_isHero) {
      _renderHero(canvas);
    } else {
      _renderMonster(canvas);
    }

    // White flash overlay
    if (_flashTimer > 0) {
      final flashAlpha = (_flashTimer / 0.2).clamp(0.0, 1.0) * 0.7;
      canvas.drawCircle(
        Offset.zero,
        _bodyRadius + 2,
        Paint()..color = Colors.white.withValues(alpha: flashAlpha),
      );
    }

    canvas.restore();
  }

  void _renderMonster(Canvas canvas) {
    final paint = Paint()
      ..color = _baseColor
      ..style = PaintingStyle.fill;

    // Glow ring for rarity 3+
    if (monster.rarity >= 3) {
      final glowAlpha = (0.3 + 0.2 * sin(_glowPhase)).clamp(0.0, 1.0);
      final glowPaint = Paint()
        ..color = _baseColor.withValues(alpha: glowAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset.zero, _bodyRadius + 4, glowPaint);
    }

    // Body shape
    switch (_bodyType) {
      case 0: // Circle
        canvas.drawCircle(Offset.zero, _bodyRadius, paint);
        // Outline
        canvas.drawCircle(
          Offset.zero,
          _bodyRadius,
          Paint()
            ..color = _accentColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        break;
      case 1: // Triangle
        final path = Path();
        path.moveTo(0, -_bodyRadius);
        path.lineTo(-_bodyRadius, _bodyRadius * 0.8);
        path.lineTo(_bodyRadius, _bodyRadius * 0.8);
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawPath(
          path,
          Paint()
            ..color = _accentColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        break;
      case 2: // Rounded square
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: _bodyRadius * 1.8, height: _bodyRadius * 1.8),
          Radius.circular(_bodyRadius * 0.3),
        );
        canvas.drawRRect(rect, paint);
        canvas.drawRRect(
          rect,
          Paint()
            ..color = _accentColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        break;
      case 3: // Diamond
        final path = Path();
        path.moveTo(0, -_bodyRadius);
        path.lineTo(_bodyRadius, 0);
        path.lineTo(0, _bodyRadius);
        path.lineTo(-_bodyRadius, 0);
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawPath(
          path,
          Paint()
            ..color = _accentColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        break;
    }

    // Pattern overlay
    _renderPattern(canvas);

    // Spikes
    _renderSpikes(canvas);

    // Eyes
    _renderEyes(canvas);
  }

  void _renderPattern(Canvas canvas) {
    final patternPaint = Paint()
      ..color = _accentColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    switch (_patternType) {
      case 1: // Stripes
        for (var i = -2; i <= 2; i++) {
          canvas.drawLine(
            Offset(-_bodyRadius * 0.5, i * _bodyRadius * 0.3),
            Offset(_bodyRadius * 0.5, i * _bodyRadius * 0.3),
            patternPaint,
          );
        }
        break;
      case 2: // Dots
        final dotPaint = Paint()
          ..color = _accentColor.withValues(alpha: 0.4)
          ..style = PaintingStyle.fill;
        for (var i = 0; i < 5; i++) {
          final angle = i * pi * 2 / 5;
          canvas.drawCircle(
            Offset(cos(angle) * _bodyRadius * 0.4, sin(angle) * _bodyRadius * 0.4),
            2.5,
            dotPaint,
          );
        }
        break;
      case 3: // Waves
        final wavePath = Path();
        for (var x = -_bodyRadius * 0.6; x <= _bodyRadius * 0.6; x += 2) {
          final y = sin(x * 0.3) * 4;
          if (x == -_bodyRadius * 0.6) {
            wavePath.moveTo(x, y);
          } else {
            wavePath.lineTo(x, y);
          }
        }
        canvas.drawPath(wavePath, patternPaint);
        break;
    }
  }

  void _renderSpikes(Canvas canvas) {
    if (_spikeCount == 0) return;
    final spikePaint = Paint()
      ..color = _accentColor
      ..style = PaintingStyle.fill;

    for (var i = 0; i < _spikeCount; i++) {
      final angle = (i * pi * 2 / _spikeCount) - pi / 2;
      final baseX = cos(angle) * _bodyRadius;
      final baseY = sin(angle) * _bodyRadius;
      final tipX = cos(angle) * (_bodyRadius + 8);
      final tipY = sin(angle) * (_bodyRadius + 8);

      final path = Path();
      path.moveTo(baseX - cos(angle + pi / 2) * 3, baseY - sin(angle + pi / 2) * 3);
      path.lineTo(tipX, tipY);
      path.lineTo(baseX + cos(angle + pi / 2) * 3, baseY + sin(angle + pi / 2) * 3);
      path.close();
      canvas.drawPath(path, spikePaint);
    }
  }

  void _renderEyes(Canvas canvas) {
    final eyeWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final eyePupil = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final eyeY = -_bodyRadius * 0.15;
    final spacing = _bodyRadius * 0.35;

    for (var i = 0; i < _eyeCount; i++) {
      final xOffset = (i - (_eyeCount - 1) / 2) * spacing;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(xOffset, eyeY), width: 8, height: 10),
        eyeWhite,
      );
      canvas.drawCircle(Offset(xOffset + 1, eyeY + 1), 3, eyePupil);
    }
  }

  void _renderHero(Canvas canvas) {
    final paint = Paint()
      ..color = _baseColor
      ..style = PaintingStyle.fill;

    // Head (circle)
    canvas.drawCircle(Offset(0, -_bodyRadius * 0.5), _bodyRadius * 0.4, paint);

    // Body (trapezoid)
    final bodyPath = Path();
    bodyPath.moveTo(-_bodyRadius * 0.35, -_bodyRadius * 0.15);
    bodyPath.lineTo(_bodyRadius * 0.35, -_bodyRadius * 0.15);
    bodyPath.lineTo(_bodyRadius * 0.5, _bodyRadius * 0.7);
    bodyPath.lineTo(-_bodyRadius * 0.5, _bodyRadius * 0.7);
    bodyPath.close();
    canvas.drawPath(bodyPath, paint);

    // Outline
    canvas.drawCircle(
      Offset(0, -_bodyRadius * 0.5),
      _bodyRadius * 0.4,
      Paint()
        ..color = _accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = _accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Eyes on head
    final eyeY = -_bodyRadius * 0.55;
    final eyeWhite = Paint()..color = Colors.white;
    final eyePupil = Paint()..color = Colors.black87;
    canvas.drawOval(Rect.fromCenter(center: Offset(-5, eyeY), width: 6, height: 8), eyeWhite);
    canvas.drawOval(Rect.fromCenter(center: Offset(5, eyeY), width: 6, height: 8), eyeWhite);
    canvas.drawCircle(Offset(-4, eyeY + 1), 2, eyePupil);
    canvas.drawCircle(Offset(6, eyeY + 1), 2, eyePupil);
  }

  void _renderDead(Canvas canvas) {
    // Greyscale body
    final greyColor = Color.fromARGB(
      150,
      (_baseColor.r * 255 * 0.3 + 128 * 0.7).round(),
      (_baseColor.g * 255 * 0.3 + 128 * 0.7).round(),
      (_baseColor.b * 255 * 0.3 + 128 * 0.7).round(),
    );
    final paint = Paint()..color = greyColor;

    canvas.drawCircle(Offset.zero, _bodyRadius * 0.8, paint);

    // X overlay
    final xPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final d = _bodyRadius * 0.5;
    canvas.drawLine(Offset(-d, -d), Offset(d, d), xPaint);
    canvas.drawLine(Offset(d, -d), Offset(-d, d), xPaint);
  }
}
