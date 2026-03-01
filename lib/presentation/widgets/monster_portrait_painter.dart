import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gameapp/core/enums/monster_element.dart';

/// Procedural monster portrait painter — ports Flame's MonsterSpriteComponent
/// rendering to Flutter CustomPainter for use in UI widgets.
///
/// Uses [templateId.hashCode] as seed to generate consistent visuals:
/// bodyType(4), eyeCount(1-3), spikeCount(0-3), patternType(4).
class MonsterPortraitPainter extends CustomPainter {
  MonsterPortraitPainter({
    required this.templateId,
    required this.element,
    required this.rarity,
    this.isDead = false,
    this.evolutionStage = 0,
    this.glowPhase = 0,
    this.overrideColor,
    this.skinRarity = 0,
  }) {
    // Cache seed-derived values — stable per templateId, avoids
    // allocating Random on every paint() call.
    final seed = templateId.hashCode;
    final rng = Random(seed);
    _bodyType = rng.nextInt(4);
    _eyeCount = 1 + rng.nextInt(3);
    _spikeCount = rng.nextInt(4);
    _patternType = rng.nextInt(4);

    final elemEnum = MonsterElement.fromName(element);
    _baseColor = elemEnum?.color ?? Colors.grey;
    _accentColor = Color.lerp(_baseColor, Colors.white, 0.3)!;
    if (overrideColor != null) {
      _baseColor = overrideColor!;
      _accentColor = Color.lerp(_baseColor, Colors.white, 0.3)!;
    }
  }

  final String templateId;
  final String element;
  final int rarity;
  final bool isDead;
  final int evolutionStage;
  final double glowPhase;
  final Color? overrideColor;
  final int skinRarity;

  // Cached seed-derived values
  late final int _bodyType;
  late final int _eyeCount;
  late final int _spikeCount;
  late final int _patternType;
  late Color _baseColor;
  late Color _accentColor;

  // Reusable Paint objects
  static final _fillPaint = Paint()..style = PaintingStyle.fill;
  static final _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final _eyeWhitePaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  static final _eyePupilPaint = Paint()
    ..color = Colors.black87
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyRadius = size.width * 0.38;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);

    if (isDead) {
      _renderDead(canvas, bodyRadius);
    } else {
      _renderMonster(canvas, bodyRadius);
    }

    if (evolutionStage > 0 && !isDead) {
      _renderEvolutionBadge(canvas, bodyRadius);
    }

    canvas.restore();
  }

  void _renderMonster(Canvas canvas, double bodyRadius) {
    // Skin rarity 3+: outer aura ring
    if (skinRarity >= 3) {
      canvas.drawCircle(
        Offset.zero,
        bodyRadius + 8,
        Paint()
          ..color = _baseColor.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Skin rarity 4+: rotating diamonds (3)
    if (skinRarity >= 4) {
      final diamondPaint = Paint()
        ..color = _accentColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      for (int i = 0; i < 3; i++) {
        final angle = glowPhase + i * pi * 2 / 3;
        final dx = cos(angle) * (bodyRadius + 14);
        final dy = sin(angle) * (bodyRadius + 14);
        final path = Path()
          ..moveTo(dx, dy - 4)
          ..lineTo(dx + 3, dy)
          ..lineTo(dx, dy + 4)
          ..lineTo(dx - 3, dy)
          ..close();
        canvas.drawPath(path, diamondPaint);
      }
    }

    // Glow ring for rarity 3+
    if (rarity >= 3) {
      final glowAlpha = (0.3 + 0.2 * sin(glowPhase)).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset.zero,
        bodyRadius + 4,
        Paint()
          ..color = _baseColor.withValues(alpha: glowAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    _fillPaint.color = _baseColor;
    _strokePaint.color = _accentColor;

    _drawBody(canvas, _bodyType, bodyRadius);
    _drawPattern(canvas, _patternType, bodyRadius);
    _drawSpikes(canvas, _spikeCount, bodyRadius);
    _drawEyes(canvas, _eyeCount, bodyRadius);
  }

  void _drawBody(Canvas canvas, int bodyType, double r) {
    switch (bodyType) {
      case 0: // Circle
        canvas.drawCircle(Offset.zero, r, _fillPaint);
        canvas.drawCircle(Offset.zero, r, _strokePaint);
      case 1: // Triangle
        final path = Path()
          ..moveTo(0, -r)
          ..lineTo(-r, r * 0.8)
          ..lineTo(r, r * 0.8)
          ..close();
        canvas.drawPath(path, _fillPaint);
        canvas.drawPath(path, _strokePaint);
      case 2: // Rounded square
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: r * 1.8, height: r * 1.8),
          Radius.circular(r * 0.3),
        );
        canvas.drawRRect(rect, _fillPaint);
        canvas.drawRRect(rect, _strokePaint);
      case 3: // Diamond
        final path = Path()
          ..moveTo(0, -r)
          ..lineTo(r, 0)
          ..lineTo(0, r)
          ..lineTo(-r, 0)
          ..close();
        canvas.drawPath(path, _fillPaint);
        canvas.drawPath(path, _strokePaint);
    }
  }

  void _drawPattern(Canvas canvas, int patternType, double r) {
    final patternPaint = Paint()
      ..color = _accentColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    switch (patternType) {
      case 1: // Stripes
        for (var i = -2; i <= 2; i++) {
          canvas.drawLine(
            Offset(-r * 0.5, i * r * 0.3),
            Offset(r * 0.5, i * r * 0.3),
            patternPaint,
          );
        }
      case 2: // Dots
        final dotPaint = Paint()
          ..color = _accentColor.withValues(alpha: 0.4)
          ..style = PaintingStyle.fill;
        for (var i = 0; i < 5; i++) {
          final angle = i * pi * 2 / 5;
          canvas.drawCircle(
            Offset(cos(angle) * r * 0.4, sin(angle) * r * 0.4),
            2.5,
            dotPaint,
          );
        }
      case 3: // Waves
        final wavePath = Path();
        for (var x = -r * 0.6; x <= r * 0.6; x += 2) {
          final y = sin(x * 0.3) * 4;
          if (x == -r * 0.6) {
            wavePath.moveTo(x, y);
          } else {
            wavePath.lineTo(x, y);
          }
        }
        canvas.drawPath(wavePath, patternPaint);
    }
  }

  void _drawSpikes(Canvas canvas, int spikeCount, double r) {
    if (spikeCount == 0) return;
    final spikePaint = Paint()
      ..color = _accentColor
      ..style = PaintingStyle.fill;

    for (var i = 0; i < spikeCount; i++) {
      final angle = (i * pi * 2 / spikeCount) - pi / 2;
      final baseX = cos(angle) * r;
      final baseY = sin(angle) * r;
      final tipX = cos(angle) * (r + 8);
      final tipY = sin(angle) * (r + 8);

      final path = Path()
        ..moveTo(baseX - cos(angle + pi / 2) * 3, baseY - sin(angle + pi / 2) * 3)
        ..lineTo(tipX, tipY)
        ..lineTo(baseX + cos(angle + pi / 2) * 3, baseY + sin(angle + pi / 2) * 3)
        ..close();
      canvas.drawPath(path, spikePaint);
    }
  }

  void _drawEyes(Canvas canvas, int eyeCount, double r) {
    final eyeY = -r * 0.15;
    final spacing = r * 0.35;
    final eyeW = (r * 0.22).clamp(5.0, 10.0);
    final eyeH = eyeW * 1.25;
    final pupilR = eyeW * 0.35;

    for (var i = 0; i < eyeCount; i++) {
      final xOffset = (i - (eyeCount - 1) / 2) * spacing;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(xOffset, eyeY), width: eyeW, height: eyeH),
        _eyeWhitePaint,
      );
      canvas.drawCircle(Offset(xOffset + 1, eyeY + 1), pupilR, _eyePupilPaint);
    }
  }

  void _renderDead(Canvas canvas, double bodyRadius) {
    final grey = Color.fromARGB(
      150,
      (_baseColor.r * 255 * 0.3 + 128 * 0.7).round(),
      (_baseColor.g * 255 * 0.3 + 128 * 0.7).round(),
      (_baseColor.b * 255 * 0.3 + 128 * 0.7).round(),
    );
    canvas.drawCircle(Offset.zero, bodyRadius * 0.8, Paint()..color = grey);

    final xPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final d = bodyRadius * 0.5;
    canvas.drawLine(Offset(-d, -d), Offset(d, d), xPaint);
    canvas.drawLine(Offset(d, -d), Offset(-d, d), xPaint);
  }

  void _renderEvolutionBadge(Canvas canvas, double bodyRadius) {
    final badgeRadius = bodyRadius * 0.28;
    final badgeCenter = Offset(bodyRadius * 0.7, bodyRadius * 0.7);

    canvas.drawCircle(
      badgeCenter,
      badgeRadius,
      Paint()..color = evolutionStage >= 2 ? Colors.amber : Colors.orange,
    );
    canvas.drawCircle(
      badgeCenter,
      badgeRadius,
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$evolutionStage',
        style: TextStyle(
          fontSize: badgeRadius * 1.1,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        badgeCenter.dx - textPainter.width / 2,
        badgeCenter.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(MonsterPortraitPainter oldDelegate) {
    return oldDelegate.templateId != templateId ||
        oldDelegate.element != element ||
        oldDelegate.rarity != rarity ||
        oldDelegate.isDead != isDead ||
        oldDelegate.evolutionStage != evolutionStage ||
        oldDelegate.glowPhase != glowPhase ||
        oldDelegate.overrideColor != overrideColor ||
        oldDelegate.skinRarity != skinRarity;
  }
}
