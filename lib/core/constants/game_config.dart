/// Game balance configuration constants
class GameConfig {
  /// Tick interval for game updates in milliseconds
  static const int tickIntervalMs = 500;

  /// Auto-save interval in seconds
  static const int autoSaveIntervalSec = 30;

  /// Maximum offline time in hours
  static const int maxOfflineHours = 12;

  /// Gold earning efficiency during offline (0.0 - 1.0)
  static const double offlineGoldEfficiency = 0.5;

  /// Experience earning efficiency during offline (0.0 - 1.0)
  static const double offlineExpEfficiency = 0.3;

  /// Assumed battles per hour while offline
  static const int offlineBattlesPerHour = 60;

  /// Minimum offline minutes before showing reward popup
  static const int minOfflineMinutes = 1;

  /// Gacha rates by rarity level: {rarity: probability}
  /// Rarity: 1=일반, 2=고급, 3=희귀, 4=영웅, 5=전설
  static const Map<int, double> gachaRates = {
    1: 0.45, // 45% 일반
    2: 0.30, // 30% 고급
    3: 0.15, // 15% 희귀
    4: 0.08, //  8% 영웅
    5: 0.02, //  2% 전설
  };

  /// Pity threshold for gacha (guarantee legendary after N pulls without one)
  static const int pityThreshold = 100;

  /// Cost in diamonds for single gacha pull
  static const int singlePullCostDiamond = 150;

  /// Cost in diamonds for 10x gacha pull
  static const int tenPullCostDiamond = 1350;

  /// Base gold reward per battle win
  static const int baseGoldPerWin = 50;

  /// Base experience reward per battle win
  static const int baseExpPerWin = 30;

  /// Stage difficulty scaling factor (multiplied per stage)
  static const double stageScalingFactor = 1.15;

  /// Base gold cost to level up a monster by 1 level
  static const int baseLevelUpGold = 100;

  /// Base shards required for evolution
  static const int baseEvolutionShards = 50;

  /// Base gold required for evolution
  static const int baseEvolutionGold = 5000;

  /// Maximum monsters in a battle team
  static const int maxTeamSize = 4;

  /// Maximum level for any monster
  static const int maxMonsterLevel = 100;

  /// Maximum evolution stage (0 = not evolved, 1 = evolved once, 2 = final form)
  static const int maxEvolutionStage = 2;

  /// Starting gold amount for new game
  static const int startingGold = 1000;

  /// Starting diamond amount for new game
  static const int startingDiamond = 500;

  /// Starting gacha tickets for new game
  static const int startingGachaTicket = 3;
}
