import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/data/static/stage_database.dart';
import 'package:gameapp/l10n/app_localizations.dart';
import 'package:gameapp/presentation/providers/player_provider.dart';
import 'package:gameapp/presentation/widgets/common/currency_bar.dart';
import 'package:gameapp/routing/app_router.dart';

// =============================================================================
// Area theme definitions
// =============================================================================

class _AreaTheme {
  const _AreaTheme({
    required this.icon,
    required this.color,
    required this.gradient,
    required this.emoji,
  });
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final String emoji;
}

const _areas = [
  _AreaTheme(
    icon: Icons.park,
    color: Color(0xFF4CAF50),
    gradient: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
    emoji: '🌲',
  ),
  _AreaTheme(
    icon: Icons.whatshot,
    color: Color(0xFFFF5722),
    gradient: [Color(0xFFBF360C), Color(0xFFFF8A65)],
    emoji: '🌋',
  ),
  _AreaTheme(
    icon: Icons.castle,
    color: Color(0xFF7E57C2),
    gradient: [Color(0xFF4527A0), Color(0xFFB39DDB)],
    emoji: '🏚️',
  ),
  _AreaTheme(
    icon: Icons.water,
    color: Color(0xFF29B6F6),
    gradient: [Color(0xFF01579B), Color(0xFF4FC3F7)],
    emoji: '🌊',
  ),
  _AreaTheme(
    icon: Icons.cloud,
    color: Color(0xFFFFD54F),
    gradient: [Color(0xFFF57F17), Color(0xFFFFF176)],
    emoji: '☁️',
  ),
];

// =============================================================================
// Node position layout (relative to canvas size)
// =============================================================================

// Zigzag positions: x = fraction of width, y = fraction of height (from bottom)
const _nodePositions = [
  Offset(0.30, 0.15), // area 1: left,  near bottom
  Offset(0.70, 0.30), // area 2: right
  Offset(0.30, 0.45), // area 3: left
  Offset(0.70, 0.60), // area 4: right
  Offset(0.30, 0.75), // area 5: left,  near top
];

const double _nodeRadius = 32.0;
const double _touchRadius = 40.0;

// =============================================================================
// MapHubScreen — ConsumerStatefulWidget
// =============================================================================

class MapHubScreen extends ConsumerStatefulWidget {
  const MapHubScreen({super.key});

  @override
  ConsumerState<MapHubScreen> createState() => _MapHubScreenState();
}

class _MapHubScreenState extends ConsumerState<MapHubScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _bounceCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  bool _isAreaUnlocked(int area, int maxClearedIdx) {
    if (area == 1) return true;
    final prevAreaFirstIdx = (area - 2) * StageDatabase.stagesPerArea + 1;
    return maxClearedIdx >= prevAreaFirstIdx;
  }

  void _onTapDown(TapDownDetails details, Size canvasSize, int maxIdx) {
    final tapPos = details.localPosition;
    for (int i = 0; i < _nodePositions.length; i++) {
      final frac = _nodePositions[i];
      // y fraction is from-bottom, so invert for canvas coordinates
      final nodePos = Offset(
        frac.dx * canvasSize.width,
        canvasSize.height - frac.dy * canvasSize.height,
      );
      final dist = (tapPos - nodePos).distance;
      if (dist <= _touchRadius) {
        final area = i + 1;
        if (_isAreaUnlocked(area, maxIdx)) {
          context.push('${AppRoutes.stageSelect}?area=$area');
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final player = ref.watch(playerProvider).player;
    if (player == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final maxIdx = StageDatabase.linearIndex(player.maxClearedStageId);
    final currentArea = (player.currentStageId.isNotEmpty)
        ? int.tryParse(player.currentStageId.split('-').first) ?? 1
        : 1;

    final areaNames = [
      l.mapArea1,
      l.mapArea2,
      l.mapArea3,
      l.mapArea4,
      l.mapArea5,
    ];

    // Per-area cleared counts
    final List<int> clearedCounts = List.generate(StageDatabase.areaCount, (i) {
      final stages = StageDatabase.byArea(i + 1);
      return stages.where((s) => StageDatabase.linearIndex(s.id) <= maxIdx).length;
    });
    final List<int> totalCounts = List.generate(
        StageDatabase.areaCount, (i) => StageDatabase.byArea(i + 1).length);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const CurrencyBar(),
          // Header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => context.pop(),
                ),
                const Icon(Icons.map, color: AppColors.primaryLight, size: 24),
                const SizedBox(width: 8),
                Text(l.mapHubTitle,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$maxIdx / ${StageDatabase.count}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // World map canvas
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  onTapDown: (d) => _onTapDown(d, canvasSize, maxIdx),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_pulseCtrl, _bounceCtrl]),
                    builder: (context, _) {
                      return CustomPaint(
                        size: canvasSize,
                        painter: _WorldMapPainter(
                          maxIdx: maxIdx,
                          currentArea: currentArea,
                          areaNames: areaNames,
                          clearedCounts: clearedCounts,
                          totalCounts: totalCounts,
                          pulsePhase: _pulseCtrl.value,
                          bouncePhase: _bounceCtrl.value,
                          isAreaUnlocked: _isAreaUnlocked,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _WorldMapPainter — CustomPainter
// =============================================================================

class _WorldMapPainter extends CustomPainter {
  _WorldMapPainter({
    required this.maxIdx,
    required this.currentArea,
    required this.areaNames,
    required this.clearedCounts,
    required this.totalCounts,
    required this.pulsePhase,
    required this.bouncePhase,
    required this.isAreaUnlocked,
  });

  final int maxIdx;
  final int currentArea;
  final List<String> areaNames;
  final List<int> clearedCounts;
  final List<int> totalCounts;
  final double pulsePhase;
  final double bouncePhase;
  final bool Function(int area, int maxIdx) isAreaUnlocked;

  // Convert fractional position (x from left, y from bottom) to canvas Offset
  Offset _nodeOffset(int index, Size size) {
    final frac = _nodePositions[index];
    return Offset(
      frac.dx * size.width,
      size.height - frac.dy * size.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background gradient
    _drawBackground(canvas, size);

    // Draw connecting paths between nodes
    for (int i = 0; i < _nodePositions.length - 1; i++) {
      final fromPos = _nodeOffset(i, size);
      final toPos = _nodeOffset(i + 1, size);
      final unlocked = isAreaUnlocked(i + 2, maxIdx);
      _drawConnectionPath(canvas, fromPos, toPos, _areas[i].color, unlocked);
    }

    // Draw area decorations
    for (int i = 0; i < _areas.length; i++) {
      final pos = _nodeOffset(i, size);
      _drawAreaDecoration(canvas, i, pos);
    }

    // Draw nodes
    for (int i = 0; i < _areas.length; i++) {
      final pos = _nodeOffset(i, size);
      final area = i + 1;
      final theme = _areas[i];
      final unlocked = isAreaUnlocked(area, maxIdx);
      final isCompleted = clearedCounts[i] >= totalCounts[i] && unlocked;
      final isCurrent = area == currentArea && unlocked;

      _drawNode(canvas, size, pos, theme, area, unlocked, isCompleted, isCurrent);
    }

    // Draw area labels
    for (int i = 0; i < _areas.length; i++) {
      final pos = _nodeOffset(i, size);
      final area = i + 1;
      final unlocked = isAreaUnlocked(area, maxIdx);
      _drawAreaLabel(canvas, size, pos, i, areaNames[i], unlocked,
          clearedCounts[i], totalCounts[i]);
    }

    // Draw bouncing arrow on current node
    _drawBouncingArrow(canvas, size);

    // Draw overall progress bar at bottom
    _drawProgressBar(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0D1B2A),
          const Color(0xFF0F0F23),
          const Color(0xFF1A1A2E),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle star dots
    final starPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final rng = math.Random(42);
    for (int i = 0; i < 60; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), rng.nextDouble() * 1.2 + 0.3, starPaint);
    }
  }

  void _drawConnectionPath(
      Canvas canvas, Offset from, Offset to, Color color, bool unlocked) {
    // Bezier control point: offset perpendicular to midpoint
    final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
    final ctrl = Offset(mid.dx + (from.dx < to.dx ? 30 : -30), mid.dy);

    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, to.dx, to.dy);

    if (unlocked) {
      final paint = Paint()
        ..color = color.withValues(alpha: 0.7)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, paint);
    } else {
      final paint = Paint()
        ..color = AppColors.border.withValues(alpha: 0.6)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      _drawDashedPath(canvas, path, paint, 8.0, 5.0);
    }
  }

  void _drawDashedPath(
      Canvas canvas, Path path, Paint paint, double dashWidth, double dashGap) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final len = math.min(dashWidth, metric.length - distance);
        final extractedPath = metric.extractPath(distance, distance + len);
        canvas.drawPath(extractedPath, paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  void _drawNode(Canvas canvas, Size size, Offset pos, _AreaTheme theme,
      int area, bool unlocked, bool isCompleted, bool isCurrent) {
    // Pulse ring for current node
    if (isCurrent) {
      final pulseRadius = _nodeRadius + 8 + math.sin(pulsePhase * 2 * math.pi) * 6;
      final pulsePaint = Paint()
        ..color = theme.color.withValues(alpha: 0.25 - pulsePhase * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(pos, pulseRadius, pulsePaint);

      final innerPulsePaint = Paint()
        ..color = theme.color.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, pulseRadius, innerPulsePaint);
    }

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(pos + const Offset(0, 4), _nodeRadius, shadowPaint);

    // Node circle fill
    final fillPaint = Paint()..style = PaintingStyle.fill;
    if (unlocked) {
      fillPaint.shader = RadialGradient(
        colors: theme.gradient,
        center: const Alignment(-0.3, -0.3),
      ).createShader(Rect.fromCircle(center: pos, radius: _nodeRadius));
    } else {
      fillPaint.color = const Color(0xFF2A2A3E);
    }
    canvas.drawCircle(pos, _nodeRadius, fillPaint);

    // Border ring
    final borderPaint = Paint()
      ..color = unlocked ? theme.color : AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCurrent ? 3 : 2;
    canvas.drawCircle(pos, _nodeRadius, borderPaint);

    // Icon inside node
    if (isCompleted) {
      _drawCheckMark(canvas, pos);
    } else if (!unlocked) {
      _drawLockIcon(canvas, pos);
    } else {
      _drawEmojiText(canvas, pos, theme.emoji);
    }
  }

  void _drawCheckMark(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = AppColors.success
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(center.dx - 10, center.dy)
      ..lineTo(center.dx - 3, center.dy + 8)
      ..lineTo(center.dx + 12, center.dy - 10);
    canvas.drawPath(path, paint);
  }

  void _drawLockIcon(Canvas canvas, Offset center) {
    final bodyPaint = Paint()
      ..color = AppColors.disabledText
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = AppColors.disabledText
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Shackle arc
    final shacklePath = Path()
      ..moveTo(center.dx - 6, center.dy - 4)
      ..arcToPoint(Offset(center.dx + 6, center.dy - 4),
          radius: const Radius.circular(7), clockwise: false);
    canvas.drawPath(shacklePath, strokePaint);

    // Body rect
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy + 5), width: 16, height: 12),
        const Radius.circular(3),
      ),
      bodyPaint,
    );
    // Keyhole dot
    canvas.drawCircle(Offset(center.dx, center.dy + 5), 2.5,
        Paint()..color = const Color(0xFF2A2A3E));
  }

  void _drawEmojiText(Canvas canvas, Offset center, String emoji) {
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: const TextStyle(fontSize: 22)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawAreaLabel(Canvas canvas, Size size, Offset nodePos, int index,
      String name, bool unlocked, int cleared, int total) {
    final isLeft = _nodePositions[index].dx < 0.5;
    // Place label on opposite side of the zigzag
    final labelX = isLeft
        ? nodePos.dx + _nodeRadius + 12
        : nodePos.dx - _nodeRadius - 12;

    final color = unlocked ? _areas[index].color : AppColors.disabledText;

    // Area name
    final nameTp = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          color: AppColors.textPrimary.withValues(alpha: unlocked ? 1.0 : 0.4),
          fontSize: 13,
          fontWeight: FontWeight.w800,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 4,
            )
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 100);

    final nameOffset = isLeft
        ? Offset(labelX, nodePos.dy - nameTp.height - 4)
        : Offset(labelX - nameTp.width, nodePos.dy - nameTp.height - 4);
    nameTp.paint(canvas, nameOffset);

    // Progress fraction
    final progTp = TextPainter(
      text: TextSpan(
        text: '$cleared/$total',
        style: TextStyle(
          color: color.withValues(alpha: unlocked ? 0.9 : 0.4),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 3)
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final progOffset = isLeft
        ? Offset(labelX, nodePos.dy + 4)
        : Offset(labelX - progTp.width, nodePos.dy + 4);
    progTp.paint(canvas, progOffset);

    // Mini progress bar
    const barWidth = 72.0;
    const barHeight = 4.0;
    final barLeft = isLeft ? labelX : labelX - barWidth;
    final barTop = progOffset.dy + progTp.height + 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
        const Radius.circular(2),
      ),
      Paint()..color = AppColors.border,
    );

    final fillWidth = total > 0 ? (cleared / total) * barWidth : 0.0;
    if (fillWidth > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barLeft, barTop, fillWidth, barHeight),
          const Radius.circular(2),
        ),
        Paint()..color = color.withValues(alpha: unlocked ? 0.9 : 0.4),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Area decorations
  // ---------------------------------------------------------------------------

  void _drawAreaDecoration(Canvas canvas, int areaIndex, Offset nodePos) {
    switch (areaIndex) {
      case 0:
        _drawForestDecoration(canvas, nodePos);
      case 1:
        _drawVolcanoDecoration(canvas, nodePos);
      case 2:
        _drawDungeonDecoration(canvas, nodePos);
      case 3:
        _drawOceanDecoration(canvas, nodePos);
      case 4:
        _drawSkyDecoration(canvas, nodePos);
    }
  }

  void _drawForestDecoration(Canvas canvas, Offset center) {
    final treePaint = Paint()..style = PaintingStyle.fill;
    final trunkPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.fill;

    final offsets = [
      Offset(center.dx - 60, center.dy - 10),
      Offset(center.dx - 75, center.dy + 10),
      Offset(center.dx - 50, center.dy + 15),
    ];

    for (int i = 0; i < offsets.length; i++) {
      final treeBase = offsets[i];
      final h = 22.0 - i * 3;
      final w = 14.0 - i * 1;

      treePaint.color = Color.lerp(
              const Color(0xFF2E7D32), const Color(0xFF66BB6A), i / 3.0)!
          .withValues(alpha: 0.7);

      // Trunk
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset(treeBase.dx, treeBase.dy + h / 2 + 3),
              width: 4,
              height: 6),
          trunkPaint);
      // Canopy triangle
      final path = Path()
        ..moveTo(treeBase.dx - w / 2, treeBase.dy + h / 2)
        ..lineTo(treeBase.dx + w / 2, treeBase.dy + h / 2)
        ..lineTo(treeBase.dx, treeBase.dy - h / 2)
        ..close();
      canvas.drawPath(path, treePaint);
    }
  }

  void _drawVolcanoDecoration(Canvas canvas, Offset center) {
    final colors = [
      const Color(0xFFFF6D00),
      const Color(0xFFDD2C00),
      const Color(0xFFFFAB40),
      const Color(0xFFFF3D00),
    ];
    final offsets = [
      Offset(center.dx + 55, center.dy - 20),
      Offset(center.dx + 70, center.dy - 5),
      Offset(center.dx + 62, center.dy + 10),
      Offset(center.dx + 50, center.dy),
    ];
    for (int i = 0; i < offsets.length; i++) {
      canvas.drawCircle(
          offsets[i],
          5.0 + i * 1.5,
          Paint()
            ..color = colors[i % colors.length].withValues(alpha: 0.65)
            ..style = PaintingStyle.fill);
    }
  }

  void _drawDungeonDecoration(Canvas canvas, Offset center) {
    final brickPaint = Paint()
      ..color = const Color(0xFF5E35B1).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF4527A0).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const brickW = 14.0;
    const brickH = 7.0;
    const cols = 3;
    const rows = 2;
    final startX = center.dx + 55;
    final startY = center.dy - 12;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final offsetX = (r % 2 == 0) ? 0.0 : brickW / 2;
        final rect = Rect.fromLTWH(
          startX + c * (brickW + 2) + offsetX,
          startY + r * (brickH + 2),
          brickW,
          brickH,
        );
        canvas.drawRect(rect, brickPaint);
        canvas.drawRect(rect, borderPaint);
      }
    }
  }

  void _drawOceanDecoration(Canvas canvas, Offset center) {
    final startX = center.dx - 80;
    for (int w = 0; w < 3; w++) {
      final yBase = center.dy - 10 + w * 12;
      final path = Path();
      path.moveTo(startX, yBase);
      for (double x = startX; x < startX + 40; x += 8) {
        path.relativeQuadraticBezierTo(4, -6, 8, 0);
      }
      final wPaint = Paint()
        ..color = const Color(0xFF29B6F6).withValues(alpha: 0.55 - w * 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, wPaint);
    }
  }

  void _drawSkyDecoration(Canvas canvas, Offset center) {
    // Cloud = 3 overlapping ellipses
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final cloudCenter = Offset(center.dx + 58, center.dy - 18);
    canvas.drawOval(
        Rect.fromCenter(center: cloudCenter, width: 32, height: 16), cloudPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cloudCenter.dx - 12, cloudCenter.dy + 4),
            width: 22,
            height: 14),
        cloudPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cloudCenter.dx + 12, cloudCenter.dy + 4),
            width: 22,
            height: 14),
        cloudPaint);
  }

  // ---------------------------------------------------------------------------
  // Bouncing arrow on current node
  // ---------------------------------------------------------------------------

  void _drawBouncingArrow(Canvas canvas, Size size) {
    final currentIdx = currentArea - 1;
    if (currentIdx < 0 || currentIdx >= _nodePositions.length) return;

    final nodePos = _nodeOffset(currentIdx, size);
    final bounceOffset = bouncePhase * 8.0;
    final arrowCenter = Offset(nodePos.dx, nodePos.dy + _nodeRadius + 14 + bounceOffset);

    final paint = Paint()
      ..color = _areas[currentIdx].color.withValues(alpha: 0.85)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(arrowCenter.dx - 8, arrowCenter.dy - 5)
      ..lineTo(arrowCenter.dx, arrowCenter.dy + 5)
      ..lineTo(arrowCenter.dx + 8, arrowCenter.dy - 5);
    canvas.drawPath(path, paint);
  }

  // ---------------------------------------------------------------------------
  // Overall progress bar at bottom
  // ---------------------------------------------------------------------------

  void _drawProgressBar(Canvas canvas, Size size) {
    const barMarginH = 24.0;
    const barHeight = 8.0;
    const barBottom = 18.0;
    final barTop = size.height - barBottom - barHeight;
    final barLeft = barMarginH;
    final barWidth = size.width - barMarginH * 2;

    // Background track
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
        const Radius.circular(4),
      ),
      Paint()..color = AppColors.border,
    );

    // Fill
    final totalStages = StageDatabase.count;
    final fillFraction = totalStages > 0 ? maxIdx / totalStages : 0.0;
    final fillWidth = fillFraction.clamp(0.0, 1.0) * barWidth;

    if (fillWidth > 0) {
      final fillPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF29B6F6), Color(0xFFFFD54F)],
        ).createShader(Rect.fromLTWH(barLeft, barTop, barWidth, barHeight));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barLeft, barTop, fillWidth, barHeight),
          const Radius.circular(4),
        ),
        fillPaint,
      );
    }

    // Label
    final labelTp = TextPainter(
      text: TextSpan(
        text: '$maxIdx / $totalStages',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelTp.paint(
      canvas,
      Offset(barLeft + barWidth / 2 - labelTp.width / 2, barTop - labelTp.height - 2),
    );
  }

  @override
  bool shouldRepaint(_WorldMapPainter old) =>
      old.pulsePhase != pulsePhase ||
      old.bouncePhase != bouncePhase ||
      old.maxIdx != maxIdx ||
      old.currentArea != currentArea;
}
