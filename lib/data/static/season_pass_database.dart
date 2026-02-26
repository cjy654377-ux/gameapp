// Static reward definitions for the Season Pass (배틀패스).
// 30 levels, each with a free-track and premium-track reward.
// Season duration: 30 days.

class SeasonPassReward {
  final int level;
  final String freeType;   // 'gold', 'expPotion', 'shard', 'gachaTicket', 'diamond'
  final int freeAmount;
  final String premiumType;
  final int premiumAmount;

  const SeasonPassReward({
    required this.level,
    required this.freeType,
    required this.freeAmount,
    required this.premiumType,
    required this.premiumAmount,
  });
}

class SeasonPassDatabase {
  SeasonPassDatabase._();

  /// XP required to reach each level (cumulative from level 0).
  /// Level 1 = 100 XP, Level 2 = 200 XP, ... scales linearly.
  static int xpForLevel(int level) => 100 * level;

  /// Total XP needed from 0 to reach [level].
  static int totalXpForLevel(int level) {
    int total = 0;
    for (int i = 1; i <= level; i++) {
      total += xpForLevel(i);
    }
    return total;
  }

  static const int maxLevel = 30;
  static const int seasonDurationDays = 30;

  /// All 30 levels of rewards.
  static const List<SeasonPassReward> rewards = [
    // Level 1-5: Early rewards
    SeasonPassReward(level: 1,  freeType: 'gold',       freeAmount: 500,   premiumType: 'diamond',     premiumAmount: 20),
    SeasonPassReward(level: 2,  freeType: 'expPotion',  freeAmount: 3,     premiumType: 'gold',        premiumAmount: 1000),
    SeasonPassReward(level: 3,  freeType: 'gold',       freeAmount: 800,   premiumType: 'expPotion',   premiumAmount: 5),
    SeasonPassReward(level: 4,  freeType: 'shard',      freeAmount: 5,     premiumType: 'diamond',     premiumAmount: 30),
    SeasonPassReward(level: 5,  freeType: 'gachaTicket', freeAmount: 1,    premiumType: 'gachaTicket', premiumAmount: 2),

    // Level 6-10
    SeasonPassReward(level: 6,  freeType: 'gold',       freeAmount: 1000,  premiumType: 'diamond',     premiumAmount: 30),
    SeasonPassReward(level: 7,  freeType: 'expPotion',  freeAmount: 5,     premiumType: 'shard',       premiumAmount: 10),
    SeasonPassReward(level: 8,  freeType: 'gold',       freeAmount: 1200,  premiumType: 'gold',        premiumAmount: 2000),
    SeasonPassReward(level: 9,  freeType: 'shard',      freeAmount: 8,     premiumType: 'expPotion',   premiumAmount: 8),
    SeasonPassReward(level: 10, freeType: 'gachaTicket', freeAmount: 1,    premiumType: 'gachaTicket', premiumAmount: 3),

    // Level 11-15
    SeasonPassReward(level: 11, freeType: 'gold',       freeAmount: 1500,  premiumType: 'diamond',     premiumAmount: 40),
    SeasonPassReward(level: 12, freeType: 'expPotion',  freeAmount: 6,     premiumType: 'shard',       premiumAmount: 15),
    SeasonPassReward(level: 13, freeType: 'gold',       freeAmount: 1800,  premiumType: 'gold',        premiumAmount: 3000),
    SeasonPassReward(level: 14, freeType: 'shard',      freeAmount: 10,    premiumType: 'expPotion',   premiumAmount: 10),
    SeasonPassReward(level: 15, freeType: 'gachaTicket', freeAmount: 2,    premiumType: 'gachaTicket', premiumAmount: 3),

    // Level 16-20
    SeasonPassReward(level: 16, freeType: 'gold',       freeAmount: 2000,  premiumType: 'diamond',     premiumAmount: 50),
    SeasonPassReward(level: 17, freeType: 'expPotion',  freeAmount: 8,     premiumType: 'shard',       premiumAmount: 20),
    SeasonPassReward(level: 18, freeType: 'gold',       freeAmount: 2500,  premiumType: 'gold',        premiumAmount: 4000),
    SeasonPassReward(level: 19, freeType: 'shard',      freeAmount: 12,    premiumType: 'expPotion',   premiumAmount: 12),
    SeasonPassReward(level: 20, freeType: 'gachaTicket', freeAmount: 2,    premiumType: 'gachaTicket', premiumAmount: 4),

    // Level 21-25
    SeasonPassReward(level: 21, freeType: 'gold',       freeAmount: 3000,  premiumType: 'diamond',     premiumAmount: 60),
    SeasonPassReward(level: 22, freeType: 'expPotion',  freeAmount: 10,    premiumType: 'shard',       premiumAmount: 25),
    SeasonPassReward(level: 23, freeType: 'gold',       freeAmount: 3500,  premiumType: 'gold',        premiumAmount: 5000),
    SeasonPassReward(level: 24, freeType: 'shard',      freeAmount: 15,    premiumType: 'expPotion',   premiumAmount: 15),
    SeasonPassReward(level: 25, freeType: 'gachaTicket', freeAmount: 3,    premiumType: 'gachaTicket', premiumAmount: 5),

    // Level 26-30: Grand rewards
    SeasonPassReward(level: 26, freeType: 'gold',       freeAmount: 4000,  premiumType: 'diamond',     premiumAmount: 80),
    SeasonPassReward(level: 27, freeType: 'expPotion',  freeAmount: 12,    premiumType: 'shard',       premiumAmount: 30),
    SeasonPassReward(level: 28, freeType: 'gold',       freeAmount: 5000,  premiumType: 'gold',        premiumAmount: 8000),
    SeasonPassReward(level: 29, freeType: 'shard',      freeAmount: 20,    premiumType: 'diamond',     premiumAmount: 100),
    SeasonPassReward(level: 30, freeType: 'gachaTicket', freeAmount: 5,    premiumType: 'gachaTicket', premiumAmount: 10),
  ];

  static SeasonPassReward? getReward(int level) {
    if (level < 1 || level > maxLevel) return null;
    return rewards[level - 1];
  }
}
