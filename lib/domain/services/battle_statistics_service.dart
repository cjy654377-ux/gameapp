import '../entities/battle_entity.dart';

/// Aggregated battle statistics computed from battle log entries.
class BattleStatistics {
  final double totalDamage;
  final int totalTurns;
  final int totalCriticals;
  final int totalSkillUses;
  final int totalElementAdvantages;
  final List<MonsterBattleStats> monsterStats; // sorted by damage desc
  final String mvpName;

  const BattleStatistics({
    required this.totalDamage,
    required this.totalTurns,
    required this.totalCriticals,
    required this.totalSkillUses,
    required this.totalElementAdvantages,
    required this.monsterStats,
    required this.mvpName,
  });
}

/// Per-monster damage/performance stats.
class MonsterBattleStats {
  final String name;
  final double totalDamage;
  final double damagePercent; // 0.0~1.0
  final int attacks;
  final int criticals;
  final int skillUses;

  const MonsterBattleStats({
    required this.name,
    required this.totalDamage,
    required this.damagePercent,
    required this.attacks,
    required this.criticals,
    required this.skillUses,
  });
}

/// Computes battle statistics from a battle log and player team.
class BattleStatisticsService {
  BattleStatisticsService._();

  static BattleStatistics calculate({
    required List<BattleLogEntry> log,
    required List<BattleMonster> playerTeam,
    required int turnCount,
  }) {
    final playerNames = playerTeam.map((m) => m.name).toSet();
    // Filter to only player attacks
    final playerLogs = log.where((e) => playerNames.contains(e.attackerName));

    // Aggregate per monster
    final Map<String, _Accumulator> accum = {};
    for (final name in playerNames) {
      accum[name] = _Accumulator();
    }

    double totalDamage = 0;
    int totalCriticals = 0;
    int totalSkillUses = 0;
    int totalElementAdv = 0;

    for (final entry in playerLogs) {
      final a = accum[entry.attackerName];
      if (a == null) continue;
      a.damage += entry.damage;
      a.attacks++;
      if (entry.isCritical) {
        a.criticals++;
        totalCriticals++;
      }
      if (entry.isSkillActivation) {
        a.skillUses++;
        totalSkillUses++;
      }
      if (entry.isElementAdvantage) totalElementAdv++;
      totalDamage += entry.damage;
    }

    // Build sorted list
    final monsterStats = accum.entries.map((e) {
      final pct = totalDamage > 0 ? e.value.damage / totalDamage : 0.0;
      return MonsterBattleStats(
        name: e.key,
        totalDamage: e.value.damage,
        damagePercent: pct,
        attacks: e.value.attacks,
        criticals: e.value.criticals,
        skillUses: e.value.skillUses,
      );
    }).toList()
      ..sort((a, b) => b.totalDamage.compareTo(a.totalDamage));

    final mvpName = monsterStats.isNotEmpty ? monsterStats.first.name : '';

    return BattleStatistics(
      totalDamage: totalDamage,
      totalTurns: turnCount,
      totalCriticals: totalCriticals,
      totalSkillUses: totalSkillUses,
      totalElementAdvantages: totalElementAdv,
      monsterStats: monsterStats,
      mvpName: mvpName,
    );
  }
}

class _Accumulator {
  double damage = 0;
  int attacks = 0;
  int criticals = 0;
  int skillUses = 0;
}
