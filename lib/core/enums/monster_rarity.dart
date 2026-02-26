import 'package:flutter/material.dart';

/// Monster rarity enumeration with properties (5-tier system)
enum MonsterRarity {
  normal(rarity: 1),
  advanced(rarity: 2),
  rare(rarity: 3),
  epic(rarity: 4),
  legendary(rarity: 5);

  final int rarity;

  const MonsterRarity({required this.rarity});

  /// Get Korean display name for the rarity
  String get koreanName {
    switch (this) {
      case MonsterRarity.normal:
        return '일반';
      case MonsterRarity.advanced:
        return '고급';
      case MonsterRarity.rare:
        return '희귀';
      case MonsterRarity.epic:
        return '영웅';
      case MonsterRarity.legendary:
        return '전설';
    }
  }

  /// Get rarity color
  Color get color {
    switch (this) {
      case MonsterRarity.normal:
        return const Color(0xFF9E9E9E); // gray
      case MonsterRarity.advanced:
        return const Color(0xFF4CAF50); // green
      case MonsterRarity.rare:
        return const Color(0xFF42A5F5); // blue
      case MonsterRarity.epic:
        return const Color(0xFF9C27B0); // purple
      case MonsterRarity.legendary:
        return const Color(0xFFFFD700); // gold
    }
  }

  /// Get number of stars to display for this rarity
  int get starCount {
    switch (this) {
      case MonsterRarity.normal:
        return 1;
      case MonsterRarity.advanced:
        return 2;
      case MonsterRarity.rare:
        return 3;
      case MonsterRarity.epic:
        return 4;
      case MonsterRarity.legendary:
        return 5;
    }
  }

  /// Get stat multiplier for this rarity (base stats scaling)
  double get statMultiplier {
    switch (this) {
      case MonsterRarity.normal:
        return 1.0;
      case MonsterRarity.advanced:
        return 1.2;
      case MonsterRarity.rare:
        return 1.5;
      case MonsterRarity.epic:
        return 1.9;
      case MonsterRarity.legendary:
        return 2.5;
    }
  }

  /// Get experience multiplier for this rarity
  double get expMultiplier {
    switch (this) {
      case MonsterRarity.normal:
        return 1.0;
      case MonsterRarity.advanced:
        return 1.1;
      case MonsterRarity.rare:
        return 1.25;
      case MonsterRarity.epic:
        return 1.5;
      case MonsterRarity.legendary:
        return 2.0;
    }
  }

  /// Get evolution shards required multiplier
  double get shardsMultiplier {
    switch (this) {
      case MonsterRarity.normal:
        return 1.0;
      case MonsterRarity.advanced:
        return 1.5;
      case MonsterRarity.rare:
        return 2.5;
      case MonsterRarity.epic:
        return 4.0;
      case MonsterRarity.legendary:
        return 7.0;
    }
  }

  /// Create rarity from integer value
  static MonsterRarity fromRarity(int rarity) {
    switch (rarity) {
      case 1:
        return MonsterRarity.normal;
      case 2:
        return MonsterRarity.advanced;
      case 3:
        return MonsterRarity.rare;
      case 4:
        return MonsterRarity.epic;
      case 5:
        return MonsterRarity.legendary;
      default:
        return MonsterRarity.normal;
    }
  }

  /// Get stars display string
  String get starsDisplay {
    return '★' * starCount;
  }
}
