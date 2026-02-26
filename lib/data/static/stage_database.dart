/// Immutable data describing a single battle stage.
class StageData {
  /// Unique stage identifier, e.g. '1-1', '2-3', '5-6'.
  final String id;

  /// Display name shown in the stage-select UI (Korean).
  final String name;

  /// Monster template IDs that appear as enemies on this stage.
  final List<String> enemyTemplateIds;

  /// Levels of each enemy in [enemyTemplateIds] (parallel list).
  final List<int> enemyLevels;

  /// Gold rewarded upon stage clear.
  final int goldReward;

  /// Player experience rewarded upon stage clear.
  final int expReward;

  /// Area number (1–5). Derived from the stage ID.
  int get area => int.parse(id.split('-').first);

  /// Stage number within the area (1–6). Derived from the stage ID.
  int get stageNumber => int.parse(id.split('-').last);

  const StageData({
    required this.id,
    required this.name,
    required this.enemyTemplateIds,
    required this.enemyLevels,
    required this.goldReward,
    required this.expReward,
  });
}

// =============================================================================
// Stage Database
// =============================================================================

/// All 30 stages, organised as 5 areas × 6 stages each.
///
/// Reward scaling: each successive stage multiplies the previous stage's
/// rewards by 1.15 (rounded to the nearest integer).
///
/// Base rewards (stage 1-1): gold = 50, exp = 30.
///
/// Enemy template IDs reference [MonsterDatabase] entries:
///   slime, goblin, bat, flame_spirit,
///   silver_wolf, stone_golem, mermaid,
///   phoenix, dark_knight, ice_queen,
///   flame_dragon, archangel
class StageDatabase {
  StageDatabase._();

  // ---------------------------------------------------------------------------
  // Area 1 — 시작의 숲  (Beginner Forest)
  // ---------------------------------------------------------------------------

  static const StageData stage1_1 = StageData(
    id:               '1-1',
    name:             '1-1 시작의 숲',
    enemyTemplateIds: ['slime', 'slime'],
    enemyLevels:      [1, 1],
    goldReward:       50,
    expReward:        30,
  );

  static const StageData stage1_2 = StageData(
    id:               '1-2',
    name:             '1-2 이끼 낀 오솔길',
    enemyTemplateIds: ['slime', 'goblin'],
    enemyLevels:      [2, 1],
    goldReward:       58,
    expReward:        35,
  );

  static const StageData stage1_3 = StageData(
    id:               '1-3',
    name:             '1-3 풀숲 샛길',
    enemyTemplateIds: ['goblin', 'goblin'],
    enemyLevels:      [2, 2],
    goldReward:       66,
    expReward:        40,
  );

  static const StageData stage1_4 = StageData(
    id:               '1-4',
    name:             '1-4 으슥한 나무 아래',
    enemyTemplateIds: ['bat', 'goblin'],
    enemyLevels:      [3, 3],
    goldReward:       76,
    expReward:        46,
  );

  static const StageData stage1_5 = StageData(
    id:               '1-5',
    name:             '1-5 고블린 동굴',
    enemyTemplateIds: ['goblin', 'goblin', 'bat'],
    enemyLevels:      [4, 4, 3],
    goldReward:       87,
    expReward:        53,
  );

  static const StageData stage1_6 = StageData(
    id:               '1-6',
    name:             '1-6 숲의 수호자 (보스)',
    enemyTemplateIds: ['goblin', 'goblin', 'goblin'],
    enemyLevels:      [5, 5, 6],
    goldReward:       100,
    expReward:        61,
  );

  // ---------------------------------------------------------------------------
  // Area 2 — 불꽃 화산 (Flame Volcano)
  // ---------------------------------------------------------------------------

  static const StageData stage2_1 = StageData(
    id:               '2-1',
    name:             '2-1 용암 기슭',
    enemyTemplateIds: ['flame_spirit', 'slime'],
    enemyLevels:      [6, 6],
    goldReward:       115,
    expReward:        70,
  );

  static const StageData stage2_2 = StageData(
    id:               '2-2',
    name:             '2-2 화산재 평원',
    enemyTemplateIds: ['flame_spirit', 'flame_spirit'],
    enemyLevels:      [7, 7],
    goldReward:       132,
    expReward:        81,
  );

  static const StageData stage2_3 = StageData(
    id:               '2-3',
    name:             '2-3 끓어오르는 분화구',
    enemyTemplateIds: ['flame_spirit', 'bat', 'flame_spirit'],
    enemyLevels:      [8, 7, 8],
    goldReward:       152,
    expReward:        93,
  );

  static const StageData stage2_4 = StageData(
    id:               '2-4',
    name:             '2-4 화염 미로',
    enemyTemplateIds: ['flame_spirit', 'flame_spirit', 'goblin'],
    enemyLevels:      [9, 9, 8],
    goldReward:       175,
    expReward:        107,
  );

  static const StageData stage2_5 = StageData(
    id:               '2-5',
    name:             '2-5 마그마 동굴',
    enemyTemplateIds: ['flame_spirit', 'flame_spirit', 'flame_spirit'],
    enemyLevels:      [10, 10, 9],
    goldReward:       201,
    expReward:        123,
  );

  static const StageData stage2_6 = StageData(
    id:               '2-6',
    name:             '2-6 화산의 지배자 (보스)',
    enemyTemplateIds: ['flame_spirit', 'flame_spirit', 'silver_wolf'],
    enemyLevels:      [12, 11, 10],
    goldReward:       231,
    expReward:        141,
  );

  // ---------------------------------------------------------------------------
  // Area 3 — 암흑 던전 (Dark Dungeon)
  // ---------------------------------------------------------------------------

  static const StageData stage3_1 = StageData(
    id:               '3-1',
    name:             '3-1 어둠의 문 앞',
    enemyTemplateIds: ['bat', 'bat', 'goblin'],
    enemyLevels:      [12, 12, 11],
    goldReward:       266,
    expReward:        162,
  );

  static const StageData stage3_2 = StageData(
    id:               '3-2',
    name:             '3-2 지하 통로',
    enemyTemplateIds: ['bat', 'bat', 'bat'],
    enemyLevels:      [13, 13, 12],
    goldReward:       306,
    expReward:        187,
  );

  static const StageData stage3_3 = StageData(
    id:               '3-3',
    name:             '3-3 저주받은 홀',
    enemyTemplateIds: ['bat', 'stone_golem'],
    enemyLevels:      [14, 13],
    goldReward:       352,
    expReward:        215,
  );

  static const StageData stage3_4 = StageData(
    id:               '3-4',
    name:             '3-4 검은 제단',
    enemyTemplateIds: ['stone_golem', 'bat', 'bat'],
    enemyLevels:      [15, 14, 14],
    goldReward:       404,
    expReward:        247,
  );

  static const StageData stage3_5 = StageData(
    id:               '3-5',
    name:             '3-5 어둠의 심장부',
    enemyTemplateIds: ['stone_golem', 'stone_golem', 'bat'],
    enemyLevels:      [16, 15, 15],
    goldReward:       465,
    expReward:        284,
  );

  static const StageData stage3_6 = StageData(
    id:               '3-6',
    name:             '3-6 암흑 군주 (보스)',
    enemyTemplateIds: ['dark_knight', 'stone_golem', 'bat'],
    enemyLevels:      [18, 16, 15],
    goldReward:       535,
    expReward:        327,
  );

  // ---------------------------------------------------------------------------
  // Area 4 — 심해 신전 (Deep Sea Temple)
  // ---------------------------------------------------------------------------

  static const StageData stage4_1 = StageData(
    id:               '4-1',
    name:             '4-1 산호초 입구',
    enemyTemplateIds: ['slime', 'mermaid'],
    enemyLevels:      [18, 17],
    goldReward:       615,
    expReward:        376,
  );

  static const StageData stage4_2 = StageData(
    id:               '4-2',
    name:             '4-2 조류 통로',
    enemyTemplateIds: ['mermaid', 'mermaid'],
    enemyLevels:      [19, 18],
    goldReward:       707,
    expReward:        432,
  );

  static const StageData stage4_3 = StageData(
    id:               '4-3',
    name:             '4-3 수몰된 유적',
    enemyTemplateIds: ['mermaid', 'stone_golem', 'slime'],
    enemyLevels:      [20, 19, 18],
    goldReward:       813,
    expReward:        497,
  );

  static const StageData stage4_4 = StageData(
    id:               '4-4',
    name:             '4-4 해저 광장',
    enemyTemplateIds: ['mermaid', 'mermaid', 'dark_knight'],
    enemyLevels:      [21, 21, 19],
    goldReward:       935,
    expReward:        571,
  );

  static const StageData stage4_5 = StageData(
    id:               '4-5',
    name:             '4-5 심해 미로',
    enemyTemplateIds: ['ice_queen', 'mermaid', 'mermaid'],
    enemyLevels:      [22, 21, 21],
    goldReward:       1075,
    expReward:        657,
  );

  static const StageData stage4_6 = StageData(
    id:               '4-6',
    name:             '4-6 해신의 분노 (보스)',
    enemyTemplateIds: ['ice_queen', 'mermaid', 'dark_knight'],
    enemyLevels:      [24, 22, 22],
    goldReward:       1237,
    expReward:        756,
  );

  // ---------------------------------------------------------------------------
  // Area 5 — 천공 성역 (Sky Sanctuary)
  // ---------------------------------------------------------------------------

  static const StageData stage5_1 = StageData(
    id:               '5-1',
    name:             '5-1 구름 위 계단',
    enemyTemplateIds: ['silver_wolf', 'phoenix'],
    enemyLevels:      [24, 23],
    goldReward:       1422,
    expReward:        869,
  );

  static const StageData stage5_2 = StageData(
    id:               '5-2',
    name:             '5-2 신성한 회랑',
    enemyTemplateIds: ['phoenix', 'silver_wolf', 'silver_wolf'],
    enemyLevels:      [25, 24, 24],
    goldReward:       1636,
    expReward:        999,
  );

  static const StageData stage5_3 = StageData(
    id:               '5-3',
    name:             '5-3 황금빛 광장',
    enemyTemplateIds: ['phoenix', 'phoenix', 'silver_wolf'],
    enemyLevels:      [26, 26, 25],
    goldReward:       1881,
    expReward:        1149,
  );

  static const StageData stage5_4 = StageData(
    id:               '5-4',
    name:             '5-4 성역의 심판대',
    enemyTemplateIds: ['archangel', 'phoenix', 'silver_wolf'],
    enemyLevels:      [28, 26, 26],
    goldReward:       2163,
    expReward:        1321,
  );

  static const StageData stage5_5 = StageData(
    id:               '5-5',
    name:             '5-5 대천사의 시험',
    enemyTemplateIds: ['archangel', 'archangel', 'phoenix'],
    enemyLevels:      [29, 28, 27],
    goldReward:       2488,
    expReward:        1520,
  );

  static const StageData stage5_6 = StageData(
    id:               '5-6',
    name:             '5-6 천공의 주인 (최종 보스)',
    enemyTemplateIds: ['flame_dragon', 'archangel', 'phoenix'],
    enemyLevels:      [32, 30, 28],
    goldReward:       2861,
    expReward:        1748,
  );

  // ---------------------------------------------------------------------------
  // Master list and lookup helpers
  // ---------------------------------------------------------------------------

  /// All 30 stages in order.
  static const List<StageData> all = [
    // Area 1
    stage1_1, stage1_2, stage1_3, stage1_4, stage1_5, stage1_6,
    // Area 2
    stage2_1, stage2_2, stage2_3, stage2_4, stage2_5, stage2_6,
    // Area 3
    stage3_1, stage3_2, stage3_3, stage3_4, stage3_5, stage3_6,
    // Area 4
    stage4_1, stage4_2, stage4_3, stage4_4, stage4_5, stage4_6,
    // Area 5
    stage5_1, stage5_2, stage5_3, stage5_4, stage5_5, stage5_6,
  ];

  /// Returns all stages in a given [area] (1–5).
  static List<StageData> byArea(int area) =>
      all.where((s) => s.area == area).toList();

  /// Finds a stage by its [id] string (e.g. '2-4').  Returns null if not found.
  static StageData? findById(String id) {
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Returns the stage that comes after [currentId], or null if [currentId] is
  /// the last stage.
  static StageData? nextStage(String currentId) {
    final index = all.indexWhere((s) => s.id == currentId);
    if (index < 0 || index >= all.length - 1) return null;
    return all[index + 1];
  }

  /// Total number of stages.
  static int get count => all.length;

  /// Number of distinct areas.
  static int get areaCount => 5;

  /// Number of stages per area.
  static int get stagesPerArea => 6;

  /// Converts a 1-based linear stage index to the `'area-num'` key.
  /// Stage layout: 5 areas × 6 stages (index 1 → '1-1', index 30 → '5-6').
  static String linearIdToKey(int stageId) {
    final int idx  = (stageId - 1).clamp(0, 29);
    final int area = idx ~/ 6 + 1;
    final int num  = idx % 6 + 1;
    return '$area-$num';
  }

  /// Converts a stage string ID (e.g. '2-3') to a 1-based linear index.
  /// Returns [defaultValue] for empty / malformed inputs.
  static int linearIndex(String stageId, {int defaultValue = 0}) {
    if (stageId.isEmpty) return defaultValue;
    final parts = stageId.split('-');
    if (parts.length != 2) return defaultValue;
    final area  = int.tryParse(parts[0]) ?? 0;
    final stage = int.tryParse(parts[1]) ?? 0;
    return (area - 1) * 6 + stage;
  }
}
