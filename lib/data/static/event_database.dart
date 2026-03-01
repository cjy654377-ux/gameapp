// Static event definitions for the event banner system.

class EventDefinition {
  final String id;
  final String titleKo;
  final String titleEn;
  final String descKo;
  final String descEn;
  final String rewardKo;
  final String rewardEn;
  final int colorValue; // ARGB hex
  final int iconCodePoint; // Material icon

  /// Effect type: 'battleReward', 'gachaBoost', 'expBoost', or null for no effect.
  final String? effectType;

  /// Effect multiplier value (e.g. 1.5 = 50% bonus).
  final double effectValue;

  const EventDefinition({
    required this.id,
    required this.titleKo,
    required this.titleEn,
    required this.descKo,
    required this.descEn,
    required this.rewardKo,
    required this.rewardEn,
    required this.colorValue,
    required this.iconCodePoint,
    this.effectType,
    this.effectValue = 1.0,
  });
}

class EventDatabase {
  EventDatabase._();

  /// All events. Active ones are filtered by current date logic.
  /// Events cycle weekly based on weekday for perpetual content.
  static const List<EventDefinition> events = [
    // Always-active welcome event
    EventDefinition(
      id: 'welcome',
      titleKo: '환영 이벤트',
      titleEn: 'Welcome Event',
      descKo: '매일 접속하면 보상을 받으세요!',
      descEn: 'Log in daily for rewards!',
      rewardKo: '골드 x2, 소환권 1장',
      rewardEn: '2x Gold, 1 Ticket',
      colorValue: 0xFF4CAF50,
      iconCodePoint: 0xe559, // Icons.celebration
      effectType: null,
      effectValue: 1.0,
    ),
    // Weekend bonus
    EventDefinition(
      id: 'weekend_bonus',
      titleKo: '주말 보너스',
      titleEn: 'Weekend Bonus',
      descKo: '주말 전투 보상 50% 증가!',
      descEn: '50% more battle rewards on weekends!',
      rewardKo: '전투 보상 1.5배',
      rewardEn: '1.5x Battle Rewards',
      colorValue: 0xFFFF9800,
      iconCodePoint: 0xe6e1, // Icons.local_fire_department
      effectType: 'battleReward',
      effectValue: 1.5,
    ),
    // Monday-Wednesday gacha boost
    EventDefinition(
      id: 'gacha_boost',
      titleKo: '소환 확률 UP',
      titleEn: 'Summon Rate UP',
      descKo: '월~수 4성 이상 소환 확률 증가!',
      descEn: 'Mon-Wed: 4★+ summon rate increased!',
      rewardKo: '4성+ 확률 2배',
      rewardEn: '2x 4★+ Rate',
      colorValue: 0xFF9C27B0,
      iconCodePoint: 0xe25b, // Icons.auto_awesome
      effectType: 'gachaBoost',
      effectValue: 2.0,
    ),
    // Thursday exp boost
    EventDefinition(
      id: 'exp_boost',
      titleKo: '경험치 축제',
      titleEn: 'EXP Festival',
      descKo: '목~금 경험치 획득량 2배!',
      descEn: 'Thu-Fri: 2x EXP gains!',
      rewardKo: '경험치 2배',
      rewardEn: '2x EXP',
      colorValue: 0xFF2196F3,
      iconCodePoint: 0xe1db, // Icons.trending_up
      effectType: 'expBoost',
      effectValue: 2.0,
    ),
  ];

  /// Returns the multiplier for the given [effectType] from active events.
  /// Returns 1.0 if no active event matches the effect type.
  static double getMultiplier(String effectType) {
    final active = activeEvents();
    for (final e in active) {
      if (e.effectType == effectType) return e.effectValue;
    }
    return 1.0;
  }

  /// Returns currently active events based on weekday.
  static List<EventDefinition> activeEvents() {
    final weekday = DateTime.now().weekday; // 1=Mon..7=Sun
    final active = <EventDefinition>[];

    for (final e in events) {
      switch (e.id) {
        case 'welcome':
          active.add(e); // always active
        case 'weekend_bonus':
          if (weekday >= 6) active.add(e); // Sat-Sun
        case 'gacha_boost':
          if (weekday >= 1 && weekday <= 3) active.add(e); // Mon-Wed
        case 'exp_boost':
          if (weekday >= 4 && weekday <= 5) active.add(e); // Thu-Fri
      }
    }
    return active;
  }
}
