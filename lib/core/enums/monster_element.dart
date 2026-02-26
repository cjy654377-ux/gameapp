import 'package:flutter/material.dart';

/// Monster element type enumeration with properties (8-element system)
enum MonsterElement {
  fire,
  water,
  electric,
  stone,
  grass,
  ghost,
  light,
  dark;

  /// Get Korean display name for the element
  String get koreanName {
    switch (this) {
      case MonsterElement.fire:
        return '화염';
      case MonsterElement.water:
        return '물';
      case MonsterElement.electric:
        return '전기';
      case MonsterElement.stone:
        return '스톤';
      case MonsterElement.grass:
        return '풀';
      case MonsterElement.ghost:
        return '고스트';
      case MonsterElement.light:
        return '빛';
      case MonsterElement.dark:
        return '어둠';
    }
  }

  /// Get element color
  Color get color {
    switch (this) {
      case MonsterElement.fire:
        return const Color(0xFFFF6B5B);
      case MonsterElement.water:
        return const Color(0xFF42A5F5);
      case MonsterElement.electric:
        return const Color(0xFFFFEB3B);
      case MonsterElement.stone:
        return const Color(0xFF8D6E63);
      case MonsterElement.grass:
        return const Color(0xFF66BB6A);
      case MonsterElement.ghost:
        return const Color(0xFF7E57C2);
      case MonsterElement.light:
        return const Color(0xFFFFD54F);
      case MonsterElement.dark:
        return const Color(0xFF5C6BC0);
    }
  }

  /// Get type advantage multiplier when this element attacks the [target] element.
  ///
  /// Advantage chart (1.3x = super effective, 0.7x = not very effective, 1.0 = neutral):
  ///
  /// Triangle:
  ///   fire    > grass  > water  > fire
  ///
  /// Electric:
  ///   electric > water
  ///   stone    > electric > ghost
  ///
  /// Ghost triangle:
  ///   ghost > light > dark > ghost
  ///
  /// Fire vs Stone:
  ///   stone resists fire (fire is 0.7x vs stone)
  double getAdvantage(MonsterElement target) {
    switch (this) {
      case MonsterElement.fire:
        // fire > grass, fire < water, stone resists fire
        if (target == MonsterElement.grass) return 1.3;
        if (target == MonsterElement.water) return 0.7;
        if (target == MonsterElement.stone) return 0.7;
        return 1.0;

      case MonsterElement.water:
        // water > fire, water < grass, water < electric
        if (target == MonsterElement.fire) return 1.3;
        if (target == MonsterElement.grass) return 0.7;
        if (target == MonsterElement.electric) return 0.7;
        return 1.0;

      case MonsterElement.electric:
        // electric > water, electric > ghost, electric < stone
        if (target == MonsterElement.water) return 1.3;
        if (target == MonsterElement.ghost) return 1.3;
        if (target == MonsterElement.stone) return 0.7;
        return 1.0;

      case MonsterElement.stone:
        // stone > electric, stone resists fire (stone attacks fire normally)
        if (target == MonsterElement.electric) return 1.3;
        return 1.0;

      case MonsterElement.grass:
        // grass > water, grass < fire
        if (target == MonsterElement.water) return 1.3;
        if (target == MonsterElement.fire) return 0.7;
        return 1.0;

      case MonsterElement.ghost:
        // ghost > light, ghost < electric
        if (target == MonsterElement.light) return 1.3;
        if (target == MonsterElement.electric) return 0.7;
        return 1.0;

      case MonsterElement.light:
        // light > dark, light < ghost
        if (target == MonsterElement.dark) return 1.3;
        if (target == MonsterElement.ghost) return 0.7;
        return 1.0;

      case MonsterElement.dark:
        // dark > ghost, dark < light
        if (target == MonsterElement.ghost) return 1.3;
        if (target == MonsterElement.light) return 0.7;
        return 1.0;
    }
  }

  /// Look up a [MonsterElement] by its [name] string (e.g. `'fire'`).
  ///
  /// Returns `null` when no match is found.
  static MonsterElement? fromName(String name) => _byName[name];

  static final Map<String, MonsterElement> _byName = {
    for (final e in values) e.name: e,
  };

  /// Get element emoji representation
  String get emoji {
    switch (this) {
      case MonsterElement.fire:
        return '🔥';
      case MonsterElement.water:
        return '💧';
      case MonsterElement.electric:
        return '⚡';
      case MonsterElement.stone:
        return '🪨';
      case MonsterElement.grass:
        return '🌿';
      case MonsterElement.ghost:
        return '👻';
      case MonsterElement.light:
        return '✨';
      case MonsterElement.dark:
        return '🌑';
    }
  }
}
