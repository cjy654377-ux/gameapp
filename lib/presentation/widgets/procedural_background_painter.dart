import 'dart:math';
import 'package:flutter/material.dart';

/// Procedural background painter for battle arenas.
/// Renders themed backgrounds based on area name using Canvas drawing.
class ProceduralBackgroundPainter extends CustomPainter {
  ProceduralBackgroundPainter({required this.areaName});

  final String areaName;

  @override
  void paint(Canvas canvas, Size size) {
    switch (areaName) {
      case 'forest':
        _paintForest(canvas, size);
      case 'volcano':
        _paintVolcano(canvas, size);
      case 'dungeon':
        _paintDungeon(canvas, size);
      case 'ocean':
        _paintOcean(canvas, size);
      case 'sky':
        _paintSky(canvas, size);
      default:
        _paintForest(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant ProceduralBackgroundPainter oldDelegate) => false;

  // ---------------------------------------------------------------------------
  // Forest
  // ---------------------------------------------------------------------------
  void _paintForest(Canvas canvas, Size size) {
    // Sky gradient: light blue → deep blue top to bottom
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF87CEEB), Color(0xFF2D5F8A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // Bottom 30% green ground
    final groundPaint = Paint()..color = const Color(0xFF2D5A1E);
    final groundTop = size.height * 0.70;
    canvas.drawRect(
      Rect.fromLTWH(0, groundTop, size.width, size.height - groundTop),
      groundPaint,
    );

    // Trees: brown trunk + green canopy
    final trunkPaint = Paint()..color = const Color(0xFF5C3317);
    final canopyPaint = Paint()..color = const Color(0xFF228B22);

    const treeXRatios = [0.10, 0.25, 0.50, 0.72, 0.88];
    for (final xRatio in treeXRatios) {
      final cx = size.width * xRatio;
      final trunkW = size.width * 0.025;
      final trunkH = size.height * 0.18;
      final trunkTop = groundTop - trunkH;

      // Trunk
      canvas.drawRect(
        Rect.fromLTWH(cx - trunkW / 2, trunkTop, trunkW, trunkH),
        trunkPaint,
      );

      // Canopy circle
      final canopyRadius = size.width * 0.07;
      canvas.drawCircle(
        Offset(cx, trunkTop - canopyRadius * 0.6),
        canopyRadius,
        canopyPaint,
      );
    }

    // Grass tufts along ground line
    final grassPaint = Paint()
      ..color = const Color(0xFF3A7A28)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final rng = Random(42);
    for (int i = 0; i < 20; i++) {
      final gx = rng.nextDouble() * size.width;
      final gh = 4.0 + rng.nextDouble() * 6.0;
      canvas.drawLine(
        Offset(gx, groundTop),
        Offset(gx, groundTop - gh),
        grassPaint,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Volcano
  // ---------------------------------------------------------------------------
  void _paintVolcano(Canvas canvas, Size size) {
    // Gradient: deep red → orange
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF8B0000), Color(0xFFFF4500)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Mountain silhouettes (dark triangles)
    final mountainPaint = Paint()..color = const Color(0xFF2B0000);
    final mountains = [
      [0.0, 0.55, 0.35, 0.20, 0.70, 0.55],
      [0.30, 0.65, 0.60, 0.15, 0.90, 0.65],
      [0.60, 0.70, 0.80, 0.30, 1.00, 0.70],
    ];
    for (final m in mountains) {
      final path = Path()
        ..moveTo(size.width * m[0], size.height * m[1])
        ..lineTo(size.width * m[2], size.height * m[3])
        ..lineTo(size.width * m[4], size.height * m[5])
        ..close();
      canvas.drawPath(path, mountainPaint);
    }

    // Lava pool at bottom (orange-yellow ellipse)
    final lavaPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFFFD700), Color(0xFFFF4500)],
      ).createShader(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.88),
          width: size.width * 0.7,
          height: size.height * 0.14,
        ),
      );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.88),
        width: size.width * 0.7,
        height: size.height * 0.14,
      ),
      lavaPaint,
    );

    // Fire sparks: ~15 small yellow/orange circles
    final sparkColors = [const Color(0xFFFFD700), const Color(0xFFFF8C00)];
    final rng = Random(7);
    for (int i = 0; i < 15; i++) {
      final sx = rng.nextDouble() * size.width;
      final sy = size.height * 0.3 + rng.nextDouble() * size.height * 0.55;
      final sr = 2.0 + rng.nextDouble() * 4.0;
      final sparkPaint = Paint()
        ..color = sparkColors[i % 2].withValues(alpha: 0.7 + rng.nextDouble() * 0.3);
      canvas.drawCircle(Offset(sx, sy), sr, sparkPaint);
    }
  }

  // ---------------------------------------------------------------------------
  // Dungeon
  // ---------------------------------------------------------------------------
  void _paintDungeon(Canvas canvas, Size size) {
    // Gradient: dark grey → black
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF1A1A2E), Colors.black],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Brick pattern
    final brickPaint = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const brickH = 24.0;
    const brickW = 48.0;
    int row = 0;
    for (double y = 0; y < size.height; y += brickH) {
      final offsetX = (row % 2 == 0) ? 0.0 : brickW / 2;
      for (double x = -brickW + offsetX; x < size.width + brickW; x += brickW) {
        canvas.drawRect(Rect.fromLTWH(x, y, brickW, brickH), brickPaint);
      }
      row++;
    }

    // Torches: yellow circles with blur glow
    final torchPositions = [
      Offset(size.width * 0.15, size.height * 0.35),
      Offset(size.width * 0.85, size.height * 0.35),
    ];
    for (final pos in torchPositions) {
      final glowPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawCircle(pos, 22, glowPaint);

      final torchPaint = Paint()..color = const Color(0xFFFFD700);
      canvas.drawCircle(pos, 6, torchPaint);
    }

    // Cobblestone ground: scattered small grey circles at bottom
    final cobblePaint = Paint()..color = const Color(0xFF555555);
    final rng = Random(13);
    for (int i = 0; i < 25; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = size.height * 0.80 + rng.nextDouble() * size.height * 0.18;
      final cr = 4.0 + rng.nextDouble() * 8.0;
      canvas.drawCircle(Offset(cx, cy), cr, cobblePaint);
    }
  }

  // ---------------------------------------------------------------------------
  // Ocean
  // ---------------------------------------------------------------------------
  void _paintOcean(Canvas canvas, Size size) {
    // Gradient: deep blue → teal
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF0D1B2A), Color(0xFF1B4332)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2 sine wave lines in light blue across middle area
    final wavePaint = Paint()
      ..color = const Color(0xFF87CEEB).withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int w = 0; w < 2; w++) {
      final waveY = size.height * (0.45 + w * 0.10);
      final path = Path();
      path.moveTo(0, waveY);
      for (double x = 0; x <= size.width; x += 1) {
        final y = waveY + sin((x / size.width) * 4 * pi + w * pi) * size.height * 0.025;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, wavePaint);
    }

    // Bubble circles (white, alpha 0.3) scattered
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.30)
      ..style = PaintingStyle.fill;
    final rng = Random(21);
    for (int i = 0; i < 18; i++) {
      final bx = rng.nextDouble() * size.width;
      final by = rng.nextDouble() * size.height * 0.75;
      final br = 3.0 + rng.nextDouble() * 7.0;
      canvas.drawCircle(Offset(bx, by), br, bubblePaint);
    }

    // Sand at bottom 15%
    final sandPaint = Paint()..color = const Color(0xFFC2B280);
    final sandTop = size.height * 0.85;
    canvas.drawRect(
      Rect.fromLTWH(0, sandTop, size.width, size.height - sandTop),
      sandPaint,
    );
  }

  // ---------------------------------------------------------------------------
  // Sky
  // ---------------------------------------------------------------------------
  void _paintSky(Canvas canvas, Size size) {
    // Gradient: deep navy → purple
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF0B0B3B), Color(0xFF2D1B69)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Stars: ~30 small white circles at seeded random positions
    final starPaint = Paint()..color = Colors.white;
    final rng = Random(99);
    for (int i = 0; i < 30; i++) {
      final sx = rng.nextDouble() * size.width;
      final sy = rng.nextDouble() * size.height * 0.65;
      final sr = 0.8 + rng.nextDouble() * 1.8;
      canvas.drawCircle(Offset(sx, sy), sr, starPaint);
    }

    // Clouds: 2-3 white ellipses (alpha 0.15)
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.15);
    final clouds = [
      [0.20, 0.20, 0.18, 0.06],
      [0.60, 0.14, 0.22, 0.05],
      [0.80, 0.28, 0.15, 0.05],
    ];
    for (final c in clouds) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * c[0], size.height * c[1]),
          width: size.width * c[2],
          height: size.height * c[3],
        ),
        cloudPaint,
      );
    }

    // Aurora arc: curved path with green (alpha 0.15)
    final auroraPaint = Paint()
      ..color = const Color(0xFF00FF88).withValues(alpha: 0.15)
      ..strokeWidth = 16.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final auroraPath = Path();
    auroraPath.moveTo(0, size.height * 0.38);
    auroraPath.cubicTo(
      size.width * 0.25, size.height * 0.22,
      size.width * 0.75, size.height * 0.22,
      size.width, size.height * 0.38,
    );
    canvas.drawPath(auroraPath, auroraPaint);
  }
}
