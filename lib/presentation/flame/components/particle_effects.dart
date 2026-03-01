import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// Simple particle: a colored circle that moves, shrinks, and fades.
/// Manages its own alpha manually (PositionComponent doesn't support OpacityEffect).
class _Particle extends PositionComponent {
  final Color _color;
  final double _radius;
  double _alpha = 1.0;
  double _elapsed = 0;
  final double _lifetime;

  _Particle({
    required super.position,
    required double radius,
    required Color color,
    required Vector2 velocity,
    required double lifetime,
  })  : _color = color,
        _radius = radius,
        _lifetime = lifetime,
        super(anchor: Anchor.center, size: Vector2.all(radius * 2)) {
    add(MoveByEffect(velocity, EffectController(duration: lifetime, curve: Curves.easeOut)));
    add(RemoveEffect(delay: lifetime));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    _alpha = (1.0 - _elapsed / _lifetime).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final shrink = _alpha; // shrink with fade
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      _radius * shrink,
      Paint()..color = _color.withValues(alpha: _alpha),
    );
  }
}

/// Star-shaped particle for critical hits.
class _StarParticle extends PositionComponent {
  final Color _color;
  final double _starRadius;
  double _alpha = 1.0;
  double _elapsed = 0;
  final double _lifetime;

  _StarParticle({
    required super.position,
    required Color color,
    required double starRadius,
    required Vector2 velocity,
    required double lifetime,
  })  : _color = color,
        _starRadius = starRadius,
        _lifetime = lifetime,
        super(anchor: Anchor.center, size: Vector2.all(starRadius * 2)) {
    add(MoveByEffect(velocity, EffectController(duration: lifetime, curve: Curves.easeOut)));
    add(RemoveEffect(delay: lifetime));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    _alpha = (1.0 - _elapsed / _lifetime).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = _color.withValues(alpha: _alpha);
    final r = _starRadius * _alpha;
    final cx = size.x / 2;
    final cy = size.y / 2;
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * pi / 180;
      final innerAngle = ((i * 72) + 36 - 90) * pi / 180;
      final ox = cos(outerAngle) * r;
      final oy = sin(outerAngle) * r;
      final ix = cos(innerAngle) * r * 0.4;
      final iy = sin(innerAngle) * r * 0.4;
      if (i == 0) {
        path.moveTo(cx + ox, cy + oy);
      } else {
        path.lineTo(cx + ox, cy + oy);
      }
      path.lineTo(cx + ix, cy + iy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}

/// Ring pulse effect for skill activation.
class _RingPulse extends PositionComponent {
  final Color _color;
  double _elapsed = 0;
  final double _maxRadius;
  static const double _lifetime = 0.5;

  _RingPulse({
    required super.position,
    required Color color,
    required double maxRadius,
  })  : _color = color,
        _maxRadius = maxRadius,
        super(anchor: Anchor.center, size: Vector2.all(maxRadius * 2)) {
    add(RemoveEffect(delay: _lifetime + 0.05));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_elapsed / _lifetime).clamp(0.0, 1.0);
    final r = 4.0 + (_maxRadius - 4.0) * Curves.easeOut.transform(t);
    final alpha = (1.0 - t).clamp(0.0, 1.0) * 0.6;
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      r,
      Paint()
        ..color = _color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

// ---------------------------------------------------------------------------
// Element-specific effect components
// ---------------------------------------------------------------------------

/// Fireball that travels from [from] to [to] then bursts.
class _FireballComponent extends PositionComponent {
  final Color _color;
  final Vector2 _start;
  final Vector2 _delta;
  double _elapsed = 0;
  static const double _travelTime = 0.25;
  static const double _lifetime = 0.6;

  _FireballComponent({
    required Vector2 from,
    required Vector2 to,
    required Color color,
  })  : _color = color,
        _start = from.clone(),
        _delta = to - from,
        super(
          position: from.clone(),
          anchor: Anchor.center,
          size: Vector2.all(20),
        ) {
    add(RemoveEffect(delay: _lifetime));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed < _travelTime) {
      final t = (_elapsed / _travelTime).clamp(0.0, 1.0);
      position = _start + _delta * t;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_elapsed / _lifetime).clamp(0.0, 1.0);
    final alpha = (1.0 - t).clamp(0.0, 1.0);
    final radius = _elapsed < _travelTime ? 6.0 : 6.0 + (_elapsed - _travelTime) * 60;

    // Core glow
    final paint = Paint()
      ..color = _color.withValues(alpha: alpha * 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(const Offset(10, 10), radius.clamp(2, 20), paint);

    // Bright center
    canvas.drawCircle(
      const Offset(10, 10),
      (radius * 0.5).clamp(1, 10),
      Paint()..color = Colors.white.withValues(alpha: alpha * 0.8),
    );
  }
}

/// Lightning bolt drawn as a jagged polyline between two points.
class _LightningBolt extends PositionComponent {
  final Color _color;
  final Vector2 _from;
  double _elapsed = 0;
  static const double _lifetime = 0.35;
  final List<Offset> _pts;

  _LightningBolt({
    required Vector2 from,
    required Vector2 to,
    required Color color,
    required Random rng,
  })  : _color = color,
        _from = from,
        _pts = _buildZigzag(from, to, rng),
        super(
          position: Vector2.zero(),
          anchor: Anchor.topLeft,
          size: Vector2(
            (from.x - to.x).abs() + 30,
            (from.y - to.y).abs() + 30,
          ),
        ) {
    add(RemoveEffect(delay: _lifetime));
  }

  static List<Offset> _buildZigzag(Vector2 from, Vector2 to, Random rng) {
    final segments = 6;
    final pts = <Offset>[];
    for (var i = 0; i <= segments; i++) {
      final t = i / segments;
      final bx = from.x + (to.x - from.x) * t;
      final by = from.y + (to.y - from.y) * t;
      final jitter = i == 0 || i == segments ? 0.0 : (rng.nextDouble() - 0.5) * 20;
      pts.add(Offset(bx + jitter, by + jitter));
    }
    return pts;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_elapsed / _lifetime).clamp(0.0, 1.0);
    final alpha = (1.0 - t).clamp(0.0, 1.0);

    // Offset so drawing is in world coords
    final dx = _from.x;
    final dy = _from.y;

    final path = Path();
    path.moveTo(_pts[0].dx - dx, _pts[0].dy - dy);
    for (var i = 1; i < _pts.length; i++) {
      path.lineTo(_pts[i].dx - dx, _pts[i].dy - dy);
    }

    // Outer glow
    canvas.drawPath(
      path,
      Paint()
        ..color = _color.withValues(alpha: alpha * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // Core bolt
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}

/// Irregular rock fragment that falls with gravity.
class _RockFragment extends PositionComponent {
  final Color _color;
  final List<Offset> _shape;
  double _elapsed = 0;
  final double _lifetime;
  double _vy;
  static const double _gravity = 120.0;

  _RockFragment({
    required super.position,
    required Color color,
    required List<Offset> shape,
    required Vector2 velocity,
    required double lifetime,
  })  : _color = color,
        _shape = shape,
        _lifetime = lifetime,
        _vy = velocity.y,
        super(anchor: Anchor.center, size: Vector2.all(14)) {
    add(MoveByEffect(
      Vector2(velocity.x, 0),
      EffectController(duration: lifetime, curve: Curves.linear),
    ));
    add(RemoveEffect(delay: lifetime));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    _vy += _gravity * dt;
    position.y += _vy * dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_elapsed / _lifetime).clamp(0.0, 1.0);
    final alpha = (1.0 - t).clamp(0.0, 1.0);
    final path = Path();
    if (_shape.isNotEmpty) {
      path.moveTo(_shape[0].dx, _shape[0].dy);
      for (var i = 1; i < _shape.length; i++) {
        path.lineTo(_shape[i].dx, _shape[i].dy);
      }
      path.close();
    }
    canvas.drawPath(path, Paint()..color = _color.withValues(alpha: alpha));
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.brown.shade900.withValues(alpha: alpha * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}

/// Leaf particle that spirals outward.
class _LeafParticle extends PositionComponent {
  final Color _color;
  double _elapsed = 0;
  final double _lifetime;
  final double _spiralRadius;
  final double _spiralSpeed;
  final double _phaseOffset;
  final Vector2 _center;

  _LeafParticle({
    required Vector2 center,
    required Color color,
    required double lifetime,
    required double spiralRadius,
    required double spiralSpeed,
    required double phaseOffset,
  })  : _color = color,
        _lifetime = lifetime,
        _spiralRadius = spiralRadius,
        _spiralSpeed = spiralSpeed,
        _phaseOffset = phaseOffset,
        _center = center.clone(),
        super(anchor: Anchor.center, size: Vector2.all(10), position: center.clone()) {
    add(RemoveEffect(delay: lifetime));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    final t = _elapsed / _lifetime;
    final angle = _phaseOffset + _elapsed * _spiralSpeed;
    final r = _spiralRadius * t;
    position = _center + Vector2(cos(angle) * r, sin(angle) * r * 0.5);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_elapsed / _lifetime).clamp(0.0, 1.0);
    final alpha = (1.0 - t * t).clamp(0.0, 1.0);
    final angle = _phaseOffset + _elapsed * _spiralSpeed;

    canvas.save();
    canvas.translate(5, 5);
    canvas.rotate(angle);
    // Draw leaf as an oval
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 8, height: 4),
      Paint()..color = _color.withValues(alpha: alpha),
    );
    canvas.restore();
  }
}

/// Phantom wave: sine-distorted ring that drifts toward target.
class _PhantomWave extends PositionComponent {
  final Color _color;
  double _elapsed = 0;
  static const double _lifetime = 0.7;
  final double _maxRadius;
  final int _waveCount;

  _PhantomWave({
    required super.position,
    required Color color,
    required double maxRadius,
    int waveCount = 6,
  })  : _color = color,
        _maxRadius = maxRadius,
        _waveCount = waveCount,
        super(anchor: Anchor.center, size: Vector2.all(maxRadius * 2)) {
    add(RemoveEffect(delay: _lifetime + 0.05));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_elapsed / _lifetime).clamp(0.0, 1.0);
    final alpha = (1.0 - t).clamp(0.0, 1.0) * 0.8;
    final r = 8.0 + (_maxRadius - 8.0) * Curves.easeOut.transform(t);
    final cx = size.x / 2;
    final cy = size.y / 2;

    final path = Path();
    const steps = 60;
    for (var i = 0; i <= steps; i++) {
      final angle = i * 2 * pi / steps;
      final sineOffset = sin(angle * _waveCount + _elapsed * 8) * 5;
      final px = cx + cos(angle) * (r + sineOffset);
      final py = cy + sin(angle) * (r + sineOffset) * 0.6;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = _color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }
}

/// Holy beam: a vertical pillar of light with glow.
class _HolyBeam extends PositionComponent {
  final Color _color;
  double _elapsed = 0;
  static const double _lifetime = 0.6;

  _HolyBeam({
    required super.position,
    required Color color,
    required double beamHeight,
  })  : _color = color,
        super(anchor: Anchor.center, size: Vector2(30, beamHeight)) {
    add(RemoveEffect(delay: _lifetime));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_elapsed / _lifetime).clamp(0.0, 1.0);
    // Peak at t=0.3 then fade
    final alpha = t < 0.3
        ? (t / 0.3)
        : (1.0 - (t - 0.3) / 0.7).clamp(0.0, 1.0);

    // Outer glow
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _color.withValues(alpha: 0),
          _color.withValues(alpha: alpha * 0.6),
          _color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), glowPaint);

    // Core beam
    final corePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: alpha * 0.9),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(size.x * 0.35, 0, size.x * 0.3, size.y));
    canvas.drawRect(Rect.fromLTWH(size.x * 0.35, 0, size.x * 0.3, size.y), corePaint);
  }
}

/// Shadow tendril drawn as a bezier curve.
class _TendrilComponent extends PositionComponent {
  final Color _color;
  final Offset _ctrl1;
  final Offset _ctrl2;
  final Offset _end;
  double _elapsed = 0;
  static const double _lifetime = 0.6;
  double _drawProgress = 0;

  _TendrilComponent({
    required super.position,
    required Color color,
    required Offset ctrl1,
    required Offset ctrl2,
    required Offset end,
  })  : _color = color,
        _ctrl1 = ctrl1,
        _ctrl2 = ctrl2,
        _end = end,
        super(anchor: Anchor.topLeft, size: Vector2.all(80)) {
    add(RemoveEffect(delay: _lifetime));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    // Grow then shrink
    _drawProgress = _elapsed < _lifetime * 0.5
        ? (_elapsed / (_lifetime * 0.5)).clamp(0, 1)
        : (1.0 - (_elapsed - _lifetime * 0.5) / (_lifetime * 0.5)).clamp(0, 1);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_elapsed / _lifetime).clamp(0.0, 1.0);
    final alpha = (1.0 - t).clamp(0.0, 1.0) * 0.9;

    // Approximate bezier by drawing up to _drawProgress
    final path = Path();
    path.moveTo(0, 0);

    final steps = 20;
    final limit = (_drawProgress * steps).round();
    for (var i = 1; i <= limit; i++) {
      final s = i / steps;
      // Cubic bezier formula
      final bx = _cubicBezier(0, _ctrl1.dx, _ctrl2.dx, _end.dx, s);
      final by = _cubicBezier(0, _ctrl1.dy, _ctrl2.dy, _end.dy, s);
      path.lineTo(bx, by);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = _color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  static double _cubicBezier(double p0, double p1, double p2, double p3, double t) {
    final mt = 1 - t;
    return mt * mt * mt * p0 +
        3 * mt * mt * t * p1 +
        3 * mt * t * t * p2 +
        t * t * t * p3;
  }
}

// ---------------------------------------------------------------------------
// Factory class
// ---------------------------------------------------------------------------

/// Factory class for creating particle effects.
class ParticleEffects {
  static final _rng = Random();

  /// Burst of element-colored circles on hit.
  static List<Component> hitExplosion(Vector2 pos, Color elementColor) {
    return List.generate(10, (_) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 30 + _rng.nextDouble() * 50;
      return _Particle(
        position: pos.clone(),
        radius: 2 + _rng.nextDouble() * 2,
        color: Color.lerp(elementColor, Colors.white, _rng.nextDouble() * 0.3)!,
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        lifetime: 0.3 + _rng.nextDouble() * 0.2,
      );
    });
  }

  /// Gold/white star burst on critical.
  static List<Component> criticalSparkle(Vector2 pos) {
    return List.generate(12, (i) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 40 + _rng.nextDouble() * 60;
      final isGold = _rng.nextBool();
      return _StarParticle(
        position: pos.clone(),
        color: isGold ? const Color(0xFFFFD700) : Colors.white,
        starRadius: 3 + _rng.nextDouble() * 3,
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        lifetime: 0.4 + _rng.nextDouble() * 0.3,
      );
    });
  }

  /// Fragments scattering on death.
  static List<Component> deathDissolve(Vector2 pos, Color monsterColor) {
    return List.generate(20, (_) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 20 + _rng.nextDouble() * 80;
      return _Particle(
        position: pos.clone(),
        radius: 2 + _rng.nextDouble() * 4,
        color: Color.lerp(monsterColor, Colors.grey, _rng.nextDouble() * 0.5)!,
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed - 20),
        lifetime: 0.5 + _rng.nextDouble() * 0.5,
      );
    });
  }

  /// Ring pulse for skill activation.
  static Component skillRing(Vector2 pos, Color elementColor) {
    return _RingPulse(
      position: pos.clone(),
      color: elementColor,
      maxRadius: 40,
    );
  }

  /// Element-specific attack effect from [from] position to [to] position.
  ///
  /// [element] should be the MonsterElement name string: fire, water, electric,
  /// stone, grass, ghost, light, dark.
  static List<Component> elementAttack(String element, Vector2 from, Vector2 to) {
    switch (element) {
      case 'fire':
        return _fireEffect(from, to);
      case 'water':
        return _waterEffect(to);
      case 'electric':
        return _electricEffect(from, to);
      case 'stone':
        return _stoneEffect(to);
      case 'grass':
        return _grassEffect(to);
      case 'ghost':
        return _ghostEffect(from, to);
      case 'light':
        return _lightEffect(to);
      case 'dark':
        return _darkEffect(from, to);
      default:
        return [];
    }
  }

  // --- fire: fireball trajectory + 15 burst particles ---
  static List<Component> _fireEffect(Vector2 from, Vector2 to) {
    const fireColor = Color(0xFFFF6B5B);
    final components = <Component>[];

    // Fireball that travels from attacker to target
    components.add(_FireballComponent(from: from, to: to, color: fireColor));

    // Burst particles at target after fireball arrives (~0.25s travel)
    for (var i = 0; i < 15; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 40 + _rng.nextDouble() * 60;
      final isOrange = _rng.nextBool();
      components.add(_Particle(
        position: to.clone(),
        radius: 3 + _rng.nextDouble() * 4,
        color: isOrange ? const Color(0xFFFF8C00) : fireColor,
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed - 20),
        lifetime: 0.35 + _rng.nextDouble() * 0.25,
      ));
    }
    return components;
  }

  // --- water: triple ring pulse + 8 droplets ---
  static List<Component> _waterEffect(Vector2 to) {
    const waterColor = Color(0xFF42A5F5);
    final components = <Component>[];

    // 3 concentric ring pulses with delay
    for (var i = 0; i < 3; i++) {
      components.add(_RingPulse(
        position: to.clone(),
        color: waterColor,
        maxRadius: 20.0 + i * 15,
      ));
    }

    // 8 water droplets
    for (var i = 0; i < 8; i++) {
      final angle = i * pi * 2 / 8 + _rng.nextDouble() * 0.3;
      final speed = 30 + _rng.nextDouble() * 30;
      components.add(_Particle(
        position: to.clone(),
        radius: 2 + _rng.nextDouble() * 2,
        color: Color.lerp(waterColor, Colors.white, 0.3)!,
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        lifetime: 0.4 + _rng.nextDouble() * 0.2,
      ));
    }
    return components;
  }

  // --- electric: lightning bolt + 4 spark particles ---
  static List<Component> _electricEffect(Vector2 from, Vector2 to) {
    const electricColor = Color(0xFFFFEB3B);
    final components = <Component>[];

    components.add(_LightningBolt(from: from, to: to, color: electricColor, rng: _rng));

    // 4 spark bursts at target
    for (var i = 0; i < 4; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 50 + _rng.nextDouble() * 50;
      components.add(_StarParticle(
        position: to.clone(),
        color: electricColor,
        starRadius: 4 + _rng.nextDouble() * 3,
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        lifetime: 0.3 + _rng.nextDouble() * 0.2,
      ));
    }
    return components;
  }

  // --- stone: 8-12 rock fragments with gravity ---
  static List<Component> _stoneEffect(Vector2 to) {
    const stoneColor = Color(0xFF8D6E63);
    final components = <Component>[];
    final count = 8 + _rng.nextInt(5); // 8-12

    for (var i = 0; i < count; i++) {
      // Build irregular polygon (4-6 vertices)
      final verts = 4 + _rng.nextInt(3);
      final shape = <Offset>[];
      for (var v = 0; v < verts; v++) {
        final a = v * 2 * pi / verts + _rng.nextDouble() * 0.5;
        final r = 3.0 + _rng.nextDouble() * 4;
        shape.add(Offset(7 + cos(a) * r, 7 + sin(a) * r));
      }

      final angle = _rng.nextDouble() * pi * 2;
      final speed = 30 + _rng.nextDouble() * 50;
      components.add(_RockFragment(
        position: to.clone(),
        color: Color.lerp(stoneColor, Colors.grey.shade700, _rng.nextDouble() * 0.4)!,
        shape: shape,
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed - 30),
        lifetime: 0.5 + _rng.nextDouble() * 0.3,
      ));
    }
    return components;
  }

  // --- grass: 6-8 leaf particles in a spiral ---
  static List<Component> _grassEffect(Vector2 to) {
    const grassColor = Color(0xFF66BB6A);
    final components = <Component>[];
    final count = 6 + _rng.nextInt(3); // 6-8

    for (var i = 0; i < count; i++) {
      final phaseOffset = i * 2 * pi / count;
      components.add(_LeafParticle(
        center: to.clone(),
        color: Color.lerp(grassColor, const Color(0xFF2E7D32), _rng.nextDouble() * 0.5)!,
        lifetime: 0.7 + _rng.nextDouble() * 0.3,
        spiralRadius: 30 + _rng.nextDouble() * 20,
        spiralSpeed: 4 + _rng.nextDouble() * 2,
        phaseOffset: phaseOffset,
      ));
    }
    return components;
  }

  // --- ghost: phantom wave + trail particles ---
  static List<Component> _ghostEffect(Vector2 from, Vector2 to) {
    const ghostColor = Color(0xFF7E57C2);
    final components = <Component>[];

    // Sine-wave ring at target
    components.add(_PhantomWave(
      position: to.clone(),
      color: ghostColor,
      maxRadius: 45,
      waveCount: 5,
    ));

    // Trail particles along the path
    final steps = 6;
    for (var i = 0; i < steps; i++) {
      final t = (i + 1) / (steps + 1);
      final trailPos = Vector2(
        from.x + (to.x - from.x) * t,
        from.y + (to.y - from.y) * t,
      );
      components.add(_Particle(
        position: trailPos,
        radius: 4 + _rng.nextDouble() * 3,
        color: ghostColor.withValues(alpha: 0.6),
        velocity: Vector2(
          (to.x - from.x).sign * _rng.nextDouble() * 10,
          (_rng.nextDouble() - 0.5) * 15,
        ),
        lifetime: 0.3 + _rng.nextDouble() * 0.2,
      ));
    }
    return components;
  }

  // --- light: holy beam + 6 gold stars ---
  static List<Component> _lightEffect(Vector2 to) {
    const lightColor = Color(0xFFFFD54F);
    final components = <Component>[];

    // Vertical holy beam centered on target
    components.add(_HolyBeam(
      position: to.clone(),
      color: lightColor,
      beamHeight: 80,
    ));

    // 6 gold star particles
    for (var i = 0; i < 6; i++) {
      final angle = i * pi / 3 + _rng.nextDouble() * 0.4;
      final speed = 35 + _rng.nextDouble() * 30;
      components.add(_StarParticle(
        position: to.clone(),
        color: i % 2 == 0 ? lightColor : Colors.white,
        starRadius: 4 + _rng.nextDouble() * 4,
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed - 10),
        lifetime: 0.5 + _rng.nextDouble() * 0.3,
      ));
    }
    return components;
  }

  // --- dark: 4-6 shadow tendrils (bezier curves) ---
  static List<Component> _darkEffect(Vector2 from, Vector2 to) {
    const darkColor = Color(0xFF5C6BC0);
    final components = <Component>[];
    final count = 4 + _rng.nextInt(3); // 4-6

    for (var i = 0; i < count; i++) {
      final spread = (i - count / 2) * 12.0;
      // Random bezier control points relative to target
      final ctrl1 = Offset(
        (to.x - from.x) * 0.3 + (_rng.nextDouble() - 0.5) * 40,
        (to.y - from.y) * 0.3 + spread + (_rng.nextDouble() - 0.5) * 20,
      );
      final ctrl2 = Offset(
        (to.x - from.x) * 0.7 + (_rng.nextDouble() - 0.5) * 40,
        (to.y - from.y) * 0.7 + spread + (_rng.nextDouble() - 0.5) * 20,
      );
      final endPt = Offset(
        to.x - from.x + (_rng.nextDouble() - 0.5) * 20,
        to.y - from.y + spread,
      );

      components.add(_TendrilComponent(
        position: from.clone(),
        color: Color.lerp(darkColor, Colors.purple.shade900, _rng.nextDouble() * 0.5)!,
        ctrl1: ctrl1,
        ctrl2: ctrl2,
        end: endPt,
      ));
    }
    return components;
  }
}
