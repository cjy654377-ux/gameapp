import '../entities/synergy.dart';

/// Service that evaluates synergies for a given team composition.
///
/// All methods are static — no instantiation required.
/// Internally it delegates evaluation to the [SynergyDefinitions] catalogue
/// defined in `synergy.dart`.
class SynergyService {
  SynergyService._();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns every [SynergyEffect] whose [condition] is satisfied by [team].
  ///
  /// The list preserves the canonical display order defined in
  /// [SynergyDefinitions.all] (element → size → rarity → special).
  ///
  /// If [team] is empty the returned list is empty.
  static List<SynergyEffect> getActiveSynergies(List<MonsterInfo> team) {
    if (team.isEmpty) return const [];
    return SynergyDefinitions.all
        .where((synergy) => synergy.condition(team))
        .toList(growable: false);
  }

  /// Aggregates all stat bonuses from every active synergy into a single map.
  ///
  /// Bonuses for the same stat are **added together** (not multiplicative).
  /// Returned keys: 'atk', 'def', 'hp', 'spd'.
  ///
  /// Example: two synergies each granting {'atk': 0.10} yields {'atk': 0.20}.
  ///
  /// Returns an empty map when [team] is empty or no synergy is active.
  static Map<String, double> getTotalBonuses(List<MonsterInfo> team) {
    final active = getActiveSynergies(team);
    if (active.isEmpty) return const {};

    final totals = <String, double>{};
    for (final synergy in active) {
      for (final entry in synergy.statBonuses.entries) {
        totals[entry.key] = (totals[entry.key] ?? 0.0) + entry.value;
      }
    }
    return totals;
  }

  /// Returns all synergies defined in the game, regardless of current team.
  ///
  /// Useful for displaying the full synergy guide in the UI so players can
  /// plan which monsters to collect.
  static List<SynergyEffect> getAllSynergies() => SynergyDefinitions.all;

  // ---------------------------------------------------------------------------
  // Convenience helpers
  // ---------------------------------------------------------------------------

  /// Filters [getAllSynergies] by [type].
  static List<SynergyEffect> getSynergiesByType(SynergyType type) =>
      SynergyDefinitions.all
          .where((s) => s.type == type)
          .toList(growable: false);

  /// Returns true when any synergy of [type] is currently active for [team].
  static bool hasActiveSynergyOfType(List<MonsterInfo> team, SynergyType type) =>
      getActiveSynergies(team).any((s) => s.type == type);

  /// Returns a human-readable summary of active synergies for debugging.
  ///
  /// Format per line: `[id] name → atk+10%, def+5%, ...`
  static String debugSummary(List<MonsterInfo> team) {
    final active = getActiveSynergies(team);
    if (active.isEmpty) return '활성 시너지 없음';

    final buffer = StringBuffer();
    for (final s in active) {
      buffer.write('[${s.id}] ${s.name} → ');
      final bonusParts = s.statBonuses.entries
          .map((e) => '${e.key}+${(e.value * 100).toStringAsFixed(0)}%')
          .join(', ');
      buffer.writeln(bonusParts);
    }
    return buffer.toString().trimRight();
  }
}
