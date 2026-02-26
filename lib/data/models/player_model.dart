import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class PlayerModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nickname;

  @HiveField(2)
  int playerLevel;

  @HiveField(3)
  int playerExp;

  /// The stage the player is currently attempting / last played.
  @HiveField(4)
  String currentStageId;

  /// The highest stage the player has cleared successfully.
  @HiveField(5)
  String maxClearedStageId;

  /// Ordered list of monster IDs currently placed in the battle team (max 4).
  @HiveField(6)
  List<String> teamMonsterIds;

  @HiveField(7)
  DateTime lastOnlineAt;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  int totalBattleCount;

  @HiveField(10)
  int totalGachaPullCount;

  /// Highest floor reached in the infinite dungeon (0 = never attempted).
  @HiveField(11)
  int maxDungeonFloor;

  /// Number of prestige resets performed.
  @HiveField(12)
  int prestigeLevel;

  /// Cumulative prestige bonus percent (e.g. 10.0 = +10% gold/exp).
  @HiveField(13)
  double prestigeBonusPercent;

  /// Current tutorial step (0 = not started, 99 = completed).
  @HiveField(14)
  int tutorialStep;

  /// Bitmask of claimed collection milestones (bit 0 = first milestone, etc.).
  @HiveField(15)
  int collectionRewardsClaimed;

  /// Last daily check-in date (null = never checked in).
  @HiveField(16)
  DateTime? lastCheckInDate;

  /// Current consecutive check-in streak (1-7, resets after day 7).
  @HiveField(17)
  int checkInStreak;

  /// Total check-in days ever.
  @HiveField(18)
  int totalCheckInDays;

  PlayerModel({
    required this.id,
    required this.nickname,
    required this.playerLevel,
    required this.playerExp,
    required this.currentStageId,
    required this.maxClearedStageId,
    required this.teamMonsterIds,
    required this.lastOnlineAt,
    required this.createdAt,
    required this.totalBattleCount,
    required this.totalGachaPullCount,
    this.maxDungeonFloor = 0,
    this.prestigeLevel = 0,
    this.prestigeBonusPercent = 0.0,
    this.tutorialStep = 0,
    this.collectionRewardsClaimed = 0,
    this.lastCheckInDate,
    this.checkInStreak = 0,
    this.totalCheckInDays = 0,
  });

  // -------------------------------------------------------------------------
  // Experience system
  // -------------------------------------------------------------------------

  /// Experience required to advance from current playerLevel to the next.
  int get expToNextLevel => expForLevel(playerLevel);

  /// Pure formula: experience required to advance from [level] to level+1.
  static int expForLevel(int level) => (200 * (1.15 * level)).round();

  // -------------------------------------------------------------------------
  // Convenience factory for new players
  // -------------------------------------------------------------------------

  factory PlayerModel.newPlayer({
    required String id,
    required String nickname,
  }) {
    final now = DateTime.now();
    return PlayerModel(
      id: id,
      nickname: nickname,
      playerLevel: 1,
      playerExp: 0,
      currentStageId: '1-1',
      maxClearedStageId: '',
      teamMonsterIds: [],
      lastOnlineAt: now,
      createdAt: now,
      totalBattleCount: 0,
      totalGachaPullCount: 0,
      maxDungeonFloor: 0,
      prestigeLevel: 0,
      prestigeBonusPercent: 0.0,
      tutorialStep: 0,
      collectionRewardsClaimed: 0,
      lastCheckInDate: null,
      checkInStreak: 0,
      totalCheckInDays: 0,
    );
  }

  // -------------------------------------------------------------------------
  // copyWith
  // -------------------------------------------------------------------------

  PlayerModel copyWith({
    String? id,
    String? nickname,
    int? playerLevel,
    int? playerExp,
    String? currentStageId,
    String? maxClearedStageId,
    List<String>? teamMonsterIds,
    DateTime? lastOnlineAt,
    DateTime? createdAt,
    int? totalBattleCount,
    int? totalGachaPullCount,
    int? maxDungeonFloor,
    int? prestigeLevel,
    double? prestigeBonusPercent,
    int? tutorialStep,
    int? collectionRewardsClaimed,
    DateTime? lastCheckInDate,
    int? checkInStreak,
    int? totalCheckInDays,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      playerLevel: playerLevel ?? this.playerLevel,
      playerExp: playerExp ?? this.playerExp,
      currentStageId: currentStageId ?? this.currentStageId,
      maxClearedStageId: maxClearedStageId ?? this.maxClearedStageId,
      teamMonsterIds: teamMonsterIds ?? List<String>.from(this.teamMonsterIds),
      lastOnlineAt: lastOnlineAt ?? this.lastOnlineAt,
      createdAt: createdAt ?? this.createdAt,
      totalBattleCount: totalBattleCount ?? this.totalBattleCount,
      totalGachaPullCount: totalGachaPullCount ?? this.totalGachaPullCount,
      maxDungeonFloor: maxDungeonFloor ?? this.maxDungeonFloor,
      prestigeLevel: prestigeLevel ?? this.prestigeLevel,
      prestigeBonusPercent: prestigeBonusPercent ?? this.prestigeBonusPercent,
      tutorialStep: tutorialStep ?? this.tutorialStep,
      collectionRewardsClaimed:
          collectionRewardsClaimed ?? this.collectionRewardsClaimed,
      lastCheckInDate: lastCheckInDate ?? this.lastCheckInDate,
      checkInStreak: checkInStreak ?? this.checkInStreak,
      totalCheckInDays: totalCheckInDays ?? this.totalCheckInDays,
    );
  }

  @override
  String toString() {
    return 'PlayerModel(id: $id, nickname: $nickname, '
        'playerLevel: $playerLevel, currentStageId: $currentStageId)';
  }
}

// =============================================================================
// Manual TypeAdapter — replaces code-generated player_model.g.dart
// =============================================================================

class PlayerModelAdapter extends TypeAdapter<PlayerModel> {
  @override
  final int typeId = 1;

  @override
  PlayerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return PlayerModel(
      id:                 fields[0]  as String,
      nickname:           fields[1]  as String,
      playerLevel:        fields[2]  as int,
      playerExp:          fields[3]  as int,
      currentStageId:     fields[4]  as String,
      maxClearedStageId:  fields[5]  as String,
      teamMonsterIds:     (fields[6] as List).cast<String>(),
      lastOnlineAt:       fields[7]  as DateTime,
      createdAt:          fields[8]  as DateTime,
      totalBattleCount:   fields[9]  as int,
      totalGachaPullCount: fields[10] as int,
      maxDungeonFloor:    fields[11] as int? ?? 0,
      prestigeLevel:      fields[12] as int? ?? 0,
      prestigeBonusPercent: (fields[13] as num?)?.toDouble() ?? 0.0,
      tutorialStep:       fields[14] as int? ?? 0,
      collectionRewardsClaimed: fields[15] as int? ?? 0,
      lastCheckInDate: fields[16] as DateTime?,
      checkInStreak: fields[17] as int? ?? 0,
      totalCheckInDays: fields[18] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerModel obj) {
    writer
      ..writeByte(19) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nickname)
      ..writeByte(2)
      ..write(obj.playerLevel)
      ..writeByte(3)
      ..write(obj.playerExp)
      ..writeByte(4)
      ..write(obj.currentStageId)
      ..writeByte(5)
      ..write(obj.maxClearedStageId)
      ..writeByte(6)
      ..write(obj.teamMonsterIds)
      ..writeByte(7)
      ..write(obj.lastOnlineAt)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.totalBattleCount)
      ..writeByte(10)
      ..write(obj.totalGachaPullCount)
      ..writeByte(11)
      ..write(obj.maxDungeonFloor)
      ..writeByte(12)
      ..write(obj.prestigeLevel)
      ..writeByte(13)
      ..write(obj.prestigeBonusPercent)
      ..writeByte(14)
      ..write(obj.tutorialStep)
      ..writeByte(15)
      ..write(obj.collectionRewardsClaimed)
      ..writeByte(16)
      ..write(obj.lastCheckInDate)
      ..writeByte(17)
      ..write(obj.checkInStreak)
      ..writeByte(18)
      ..write(obj.totalCheckInDays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
