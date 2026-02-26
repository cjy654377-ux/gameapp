import 'package:flutter/material.dart';

/// A floating damage number that animates upward and fades out.
class DamageNumber extends StatefulWidget {
  const DamageNumber({
    super.key,
    required this.damage,
    required this.isCritical,
    required this.isSkill,
    required this.isElementAdvantage,
    this.onComplete,
  });

  final int damage;
  final bool isCritical;
  final bool isSkill;
  final bool isElementAdvantage;
  final VoidCallback? onComplete;

  @override
  State<DamageNumber> createState() => _DamageNumberState();
}

class _DamageNumberState extends State<DamageNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offsetY;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _offsetY = Tween<double>(begin: 0, end: -40).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _scale = widget.isCritical
        ? TweenSequence<double>([
            TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.4), weight: 20),
            TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 20),
            TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
          ]).animate(_controller)
        : Tween<double>(begin: 0.6, end: 1.0).animate(
            CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
            ),
          );

    _controller.forward().then((_) {
      if (mounted) widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isCritical
        ? const Color(0xFFFF4444)
        : widget.isSkill
            ? const Color(0xFFBB86FC)
            : widget.isElementAdvantage
                ? const Color(0xFF4FC3F7)
                : Colors.white;

    final fontSize = widget.isCritical ? 18.0 : 14.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _offsetY.value),
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isCritical)
            Text(
              'CRITICAL!',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFFD740),
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          Text(
            '${widget.damage}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: color,
              shadows: [
                Shadow(color: Colors.black, blurRadius: 4),
                if (widget.isCritical)
                  Shadow(color: const Color(0xFFFF4444), blurRadius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Manages a stack of floating damage numbers.
class DamageNumberOverlay extends StatefulWidget {
  const DamageNumberOverlay({super.key});

  @override
  State<DamageNumberOverlay> createState() => DamageNumberOverlayState();
}

class DamageNumberOverlayState extends State<DamageNumberOverlay> {
  final List<_DamageEntry> _entries = [];
  int _nextId = 0;

  void addDamage({
    required int damage,
    required bool isCritical,
    bool isSkill = false,
    bool isElementAdvantage = false,
    bool isEnemy = false,
  }) {
    setState(() {
      _entries.add(_DamageEntry(
        id: _nextId++,
        damage: damage,
        isCritical: isCritical,
        isSkill: isSkill,
        isElementAdvantage: isElementAdvantage,
        isEnemy: isEnemy,
      ));
    });
  }

  void _removeEntry(int id) {
    setState(() {
      _entries.removeWhere((e) => e.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: _entries.map((e) {
          final xOffset = e.isEnemy ? 0.7 : 0.3;
          final yBase = 0.3 + (e.id % 3) * 0.1;
          return Align(
            alignment: Alignment(xOffset * 2 - 1, yBase * 2 - 1),
            child: DamageNumber(
              key: ValueKey(e.id),
              damage: e.damage,
              isCritical: e.isCritical,
              isSkill: e.isSkill,
              isElementAdvantage: e.isElementAdvantage,
              onComplete: () => _removeEntry(e.id),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DamageEntry {
  final int id;
  final int damage;
  final bool isCritical;
  final bool isSkill;
  final bool isElementAdvantage;
  final bool isEnemy;

  const _DamageEntry({
    required this.id,
    required this.damage,
    required this.isCritical,
    required this.isSkill,
    required this.isElementAdvantage,
    required this.isEnemy,
  });
}
