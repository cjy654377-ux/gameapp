import 'package:flutter_test/flutter_test.dart';
import 'package:gameapp/domain/services/tower_service.dart';

void main() {
  // ===========================================================================
  // Constants
  // ===========================================================================

  group('Tower constants', () {
    test('max floor is 30', () {
      expect(TowerService.maxFloor, 30);
    });

    test('max weekly attempts is 3', () {
      expect(TowerService.maxWeeklyAttempts, 3);
    });
  });

  // ===========================================================================
  // createEnemiesForFloor
  // ===========================================================================

  group('createEnemiesForFloor', () {
    test('floor 1-10 creates 2 enemies (non-boss)', () {
      for (int f = 1; f <= 9; f++) {
        final enemies = TowerService.createEnemiesForFloor(f);
        expect(enemies.length, 2, reason: 'Floor $f should have 2 enemies');
      }
    });

    test('boss floor 10 creates 1 enemy', () {
      final enemies = TowerService.createEnemiesForFloor(10);
      expect(enemies.length, 1);
    });

    test('boss floor 20 creates 1 enemy', () {
      final enemies = TowerService.createEnemiesForFloor(20);
      expect(enemies.length, 1);
    });

    test('boss floor 30 creates 1 enemy', () {
      final enemies = TowerService.createEnemiesForFloor(30);
      expect(enemies.length, 1);
    });

    test('floor 11-19 creates 3 enemies', () {
      for (int f = 11; f <= 19; f++) {
        final enemies = TowerService.createEnemiesForFloor(f);
        expect(enemies.length, 3, reason: 'Floor $f should have 3 enemies');
      }
    });

    test('boss enemies have BOSS prefix in name', () {
      final enemies = TowerService.createEnemiesForFloor(10);
      expect(enemies.first.name, startsWith('BOSS'));
    });

    test('non-boss enemies do not have BOSS prefix', () {
      final enemies = TowerService.createEnemiesForFloor(5);
      for (final e in enemies) {
        expect(e.name, isNot(startsWith('BOSS')));
      }
    });

    test('boss enemies have higher HP than non-boss at nearby floor', () {
      // Compare floor 10 (boss) with floor 9 (non-boss)
      final bossEnemies = TowerService.createEnemiesForFloor(10);
      final normalEnemies = TowerService.createEnemiesForFloor(9);

      final bossHp = bossEnemies.first.maxHp;
      final avgNormalHp = normalEnemies.map((e) => e.maxHp).reduce((a, b) => a + b) / normalEnemies.length;

      expect(bossHp, greaterThan(avgNormalHp),
          reason: 'Boss should have significantly more HP than normal enemies');
    });
  });

  // ===========================================================================
  // getFloorReward
  // ===========================================================================

  group('getFloorReward', () {
    test('floor 10 gives 2000 gold, 10 diamonds', () {
      final reward = TowerService.getFloorReward(10);
      expect(reward.gold, 2000);
      expect(reward.diamond, 10);
      expect(reward.gachaTicket, 0);
    });

    test('floor 20 gives 3000 gold, 15 diamonds, 1 ticket', () {
      final reward = TowerService.getFloorReward(20);
      expect(reward.gold, 3000);
      expect(reward.diamond, 15);
      expect(reward.gachaTicket, 1);
    });

    test('floor 30 gives 5000 gold, 30 diamonds, 3 tickets', () {
      final reward = TowerService.getFloorReward(30);
      expect(reward.gold, 5000);
      expect(reward.diamond, 30);
      expect(reward.gachaTicket, 3);
    });

    test('floor 5 (non-milestone but divisible by 5) gives scaled rewards', () {
      final reward = TowerService.getFloorReward(5);
      expect(reward.gold, 500); // 500 * (5/5)
      expect(reward.diamond, 5);
      expect(reward.gachaTicket, 0);
    });

    test('floor 15 (divisible by 5) gives scaled rewards', () {
      final reward = TowerService.getFloorReward(15);
      expect(reward.gold, 1500); // 500 * 3
      expect(reward.diamond, 5);
    });

    test('regular floor 1 gives gold and exp only', () {
      final reward = TowerService.getFloorReward(1);
      expect(reward.gold, 100); // 100 * 1
      expect(reward.exp, 50);   // 50 * 1
      expect(reward.diamond, 0);
      expect(reward.gachaTicket, 0);
    });

    test('regular floor 7 gives scaled gold and exp', () {
      final reward = TowerService.getFloorReward(7);
      expect(reward.gold, 700);  // 100 * 7
      expect(reward.exp, 350);   // 50 * 7
    });
  });

  // ===========================================================================
  // shouldResetWeekly
  // ===========================================================================

  group('shouldResetWeekly', () {
    test('returns true when lastDate is null', () {
      expect(TowerService.shouldResetWeekly(null), true);
    });

    test('returns false when lastDate is today', () {
      expect(TowerService.shouldResetWeekly(DateTime.now()), false);
    });

    test('returns true when lastDate is last week', () {
      final lastWeek = DateTime.now().subtract(const Duration(days: 8));
      expect(TowerService.shouldResetWeekly(lastWeek), true);
    });

    test('returns false when lastDate is earlier this week', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final monday = today.subtract(Duration(days: today.weekday - 1));

      // If today is Monday, test with today (same week).
      // Otherwise, test with Monday of this week.
      if (now.weekday > 1) {
        // Monday of this week at noon
        final thisMonday =
            monday.add(const Duration(hours: 12));
        expect(TowerService.shouldResetWeekly(thisMonday), false);
      }
    });
  });
}
