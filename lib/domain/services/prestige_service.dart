import 'package:gameapp/data/models/player_model.dart';

// =============================================================================
// PrestigeService — static utility for prestige/rebirth calculations
// =============================================================================

class PrestigeService {
  PrestigeService._();

  /// Minimum player level required to prestige.
  static const int minLevelToPrestige = 30;

  /// Minimum cleared stage area required to prestige (area 3+).
  static const int minAreaToPrestige = 3;

  /// Bonus percent gained per prestige level (cumulative).
  static const double bonusPerPrestige = 10.0;

  /// Maximum prestige level.
  static const int maxPrestigeLevel = 20;

  // ---------------------------------------------------------------------------
  // Eligibility
  // ---------------------------------------------------------------------------

  /// Whether the player meets the requirements to prestige.
  static bool canPrestige(PlayerModel player) {
    if (player.prestigeLevel >= maxPrestigeLevel) return false;
    // Must meet at least one condition: level 30+ OR cleared area 3+.
    return player.playerLevel >= minLevelToPrestige ||
        _clearedArea(player) >= minAreaToPrestige;
  }

  // ---------------------------------------------------------------------------
  // Reward calculations
  // ---------------------------------------------------------------------------

  /// Diamonds awarded for this prestige (scales with level and cleared stage).
  static int prestigeDiamondReward(PlayerModel player) {
    final levelBonus = player.playerLevel * 2;
    final areaBonus = _clearedArea(player) * 15;
    final floorBonus = player.maxDungeonFloor;
    return 50 + levelBonus + areaBonus + floorBonus;
  }

  /// Gacha tickets awarded for this prestige.
  static int prestigeTicketReward(PlayerModel player) {
    return 3 + player.prestigeLevel;
  }

  /// The new bonus percent after this prestige.
  static double nextBonusPercent(PlayerModel player) {
    return (player.prestigeLevel + 1) * bonusPerPrestige;
  }

  /// Gold/EXP multiplier from prestige bonus (e.g. 1.1 = +10%).
  static double bonusMultiplier(PlayerModel player) {
    return 1.0 + (player.prestigeBonusPercent / 100.0);
  }

  // ---------------------------------------------------------------------------
  // Prestige effect — returns the reset player model
  // ---------------------------------------------------------------------------

  /// Returns a new [PlayerModel] with prestige applied:
  /// - Level → 1, Exp → 0
  /// - Stage → '1-1', maxCleared → ''
  /// - maxDungeonFloor → 0
  /// - prestigeLevel + 1, bonusPercent updated
  /// - Keeps: id, nickname, createdAt, totalBattleCount, totalGachaPullCount
  static PlayerModel applyPrestige(PlayerModel player) {
    final newPrestigeLevel = player.prestigeLevel + 1;
    return player.copyWith(
      playerLevel: 1,
      playerExp: 0,
      currentStageId: '1-1',
      maxClearedStageId: '',
      teamMonsterIds: <String>[],
      maxDungeonFloor: 0,
      prestigeLevel: newPrestigeLevel,
      prestigeBonusPercent: newPrestigeLevel * bonusPerPrestige,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Extracts the area number from maxClearedStageId (e.g. '3-4' → 3).
  static int _clearedArea(PlayerModel player) {
    if (player.maxClearedStageId.isEmpty) return 0;
    final parts = player.maxClearedStageId.split('-');
    if (parts.isEmpty) return 0;
    return int.tryParse(parts[0]) ?? 0;
  }
}
