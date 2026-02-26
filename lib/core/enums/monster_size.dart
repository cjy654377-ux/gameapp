/// Monster size classification enumeration with team and stat properties
enum MonsterSize {
  small,
  medium,
  large,
  extraLarge;

  /// Get Korean display name for the size
  String get koreanName {
    switch (this) {
      case MonsterSize.small:
        return '소형';
      case MonsterSize.medium:
        return '중형';
      case MonsterSize.large:
        return '대형';
      case MonsterSize.extraLarge:
        return '초대형';
    }
  }

  /// Number of team slots this monster occupies
  int get teamSlots {
    switch (this) {
      case MonsterSize.small:
        return 1;
      case MonsterSize.medium:
        return 1;
      case MonsterSize.large:
        return 2;
      case MonsterSize.extraLarge:
        return 2;
    }
  }

  /// Stat scale multiplier applied to base stats
  double get statScale {
    switch (this) {
      case MonsterSize.small:
        return 0.85;
      case MonsterSize.medium:
        return 1.0;
      case MonsterSize.large:
        return 1.2;
      case MonsterSize.extraLarge:
        return 1.5;
    }
  }

  /// Speed bonus multiplier (smaller monsters move faster)
  double get speedBonus {
    switch (this) {
      case MonsterSize.small:
        return 1.15;
      case MonsterSize.medium:
        return 1.0;
      case MonsterSize.large:
        return 0.85;
      case MonsterSize.extraLarge:
        return 0.7;
    }
  }

  /// Maximum number of team slots available in the team composition.
  /// Kept for backward-compatible naming; delegates to [teamSlots].
  int get maxTeamSlots => teamSlots;
}
