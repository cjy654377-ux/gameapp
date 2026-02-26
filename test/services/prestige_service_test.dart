import 'package:flutter_test/flutter_test.dart';
import 'package:gameapp/data/models/player_model.dart';
import 'package:gameapp/domain/services/prestige_service.dart';

PlayerModel _player({
  int level = 1,
  String maxCleared = '',
  int prestigeLevel = 0,
  double prestigeBonus = 0.0,
  int maxDungeonFloor = 0,
}) {
  return PlayerModel(
    id: 'test',
    nickname: 'Test',
    playerLevel: level,
    playerExp: 0,
    currentStageId: '1-1',
    maxClearedStageId: maxCleared,
    teamMonsterIds: [],
    lastOnlineAt: DateTime.now(),
    createdAt: DateTime.now(),
    totalBattleCount: 0,
    totalGachaPullCount: 0,
    maxDungeonFloor: maxDungeonFloor,
    prestigeLevel: prestigeLevel,
    prestigeBonusPercent: prestigeBonus,
  );
}

void main() {
  // ===========================================================================
  // canPrestige
  // ===========================================================================

  group('canPrestige', () {
    test('returns false for fresh player (level 1, no cleared area)', () {
      expect(PrestigeService.canPrestige(_player()), false);
    });

    test('returns true when player level >= 30', () {
      expect(PrestigeService.canPrestige(_player(level: 30)), true);
    });

    test('returns true when cleared area >= 3', () {
      expect(PrestigeService.canPrestige(_player(maxCleared: '3-4')), true);
    });

    test('returns true when both conditions met', () {
      expect(
        PrestigeService.canPrestige(
            _player(level: 30, maxCleared: '4-1')),
        true,
      );
    });

    test('returns false at max prestige level', () {
      expect(
        PrestigeService.canPrestige(
            _player(level: 99, prestigeLevel: 20)),
        false,
      );
    });

    test('returns false at level 29 with area 2', () {
      expect(
        PrestigeService.canPrestige(
            _player(level: 29, maxCleared: '2-6')),
        false,
      );
    });
  });

  // ===========================================================================
  // prestigeDiamondReward
  // ===========================================================================

  group('prestigeDiamondReward', () {
    test('base reward is 50 for a fresh player', () {
      final reward = PrestigeService.prestigeDiamondReward(
          _player(level: 1, maxCleared: '', maxDungeonFloor: 0));
      // 50 + 1*2 + 0*15 + 0 = 52
      expect(reward, 52);
    });

    test('scales with level', () {
      final r1 = PrestigeService.prestigeDiamondReward(
          _player(level: 10));
      final r2 = PrestigeService.prestigeDiamondReward(
          _player(level: 30));
      expect(r2, greaterThan(r1));
    });

    test('scales with cleared area', () {
      final r1 = PrestigeService.prestigeDiamondReward(
          _player(maxCleared: '1-1'));
      final r2 = PrestigeService.prestigeDiamondReward(
          _player(maxCleared: '4-1'));
      expect(r2, greaterThan(r1));
    });

    test('scales with dungeon floor', () {
      final r1 = PrestigeService.prestigeDiamondReward(
          _player(maxDungeonFloor: 0));
      final r2 = PrestigeService.prestigeDiamondReward(
          _player(maxDungeonFloor: 50));
      expect(r2 - r1, 50);
    });

    test('formula: 50 + level*2 + area*15 + dungeonFloor', () {
      final player = _player(
          level: 35, maxCleared: '3-6', maxDungeonFloor: 20);
      final expected = 50 + 35 * 2 + 3 * 15 + 20;
      expect(PrestigeService.prestigeDiamondReward(player), expected);
    });
  });

  // ===========================================================================
  // prestigeTicketReward
  // ===========================================================================

  group('prestigeTicketReward', () {
    test('base is 3 + prestigeLevel', () {
      expect(
          PrestigeService.prestigeTicketReward(_player(prestigeLevel: 0)), 3);
      expect(
          PrestigeService.prestigeTicketReward(_player(prestigeLevel: 5)), 8);
      expect(
          PrestigeService.prestigeTicketReward(_player(prestigeLevel: 10)), 13);
    });
  });

  // ===========================================================================
  // nextBonusPercent
  // ===========================================================================

  group('nextBonusPercent', () {
    test('first prestige gives 10%', () {
      expect(PrestigeService.nextBonusPercent(_player(prestigeLevel: 0)), 10.0);
    });

    test('fifth prestige gives 60%', () {
      expect(PrestigeService.nextBonusPercent(_player(prestigeLevel: 5)), 60.0);
    });
  });

  // ===========================================================================
  // bonusMultiplier
  // ===========================================================================

  group('bonusMultiplier', () {
    test('0% bonus yields 1.0x', () {
      expect(
          PrestigeService.bonusMultiplier(_player(prestigeBonus: 0.0)), 1.0);
    });

    test('10% bonus yields 1.1x', () {
      expect(
          PrestigeService.bonusMultiplier(_player(prestigeBonus: 10.0)), 1.1);
    });

    test('50% bonus yields 1.5x', () {
      expect(
          PrestigeService.bonusMultiplier(_player(prestigeBonus: 50.0)), 1.5);
    });
  });

  // ===========================================================================
  // applyPrestige
  // ===========================================================================

  group('applyPrestige', () {
    test('resets level to 1 and exp to 0', () {
      final result = PrestigeService.applyPrestige(
          _player(level: 50, prestigeLevel: 0));
      expect(result.playerLevel, 1);
      expect(result.playerExp, 0);
    });

    test('resets stage to 1-1 and maxCleared to empty', () {
      final result = PrestigeService.applyPrestige(
          _player(maxCleared: '4-6', prestigeLevel: 0));
      expect(result.currentStageId, '1-1');
      expect(result.maxClearedStageId, '');
    });

    test('resets dungeon floor to 0', () {
      final result = PrestigeService.applyPrestige(
          _player(maxDungeonFloor: 100, prestigeLevel: 0));
      expect(result.maxDungeonFloor, 0);
    });

    test('increments prestige level by 1', () {
      final result = PrestigeService.applyPrestige(
          _player(prestigeLevel: 3));
      expect(result.prestigeLevel, 4);
    });

    test('sets bonus percent to (newLevel * 10)', () {
      final result = PrestigeService.applyPrestige(
          _player(prestigeLevel: 4));
      expect(result.prestigeBonusPercent, 50.0); // (4+1) * 10
    });

    test('clears team monster IDs', () {
      final result = PrestigeService.applyPrestige(
          _player(prestigeLevel: 0));
      expect(result.teamMonsterIds, isEmpty);
    });

    test('preserves nickname', () {
      final player = _player(prestigeLevel: 0);
      final result = PrestigeService.applyPrestige(player);
      expect(result.nickname, player.nickname);
    });
  });
}
