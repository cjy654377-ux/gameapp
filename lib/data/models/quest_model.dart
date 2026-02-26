import 'package:hive/hive.dart';

import '../static/quest_database.dart';

@HiveType(typeId: 3)
class QuestModel extends HiveObject {
  /// Matches [QuestDefinition.id] in [QuestDatabase].
  @HiveField(0)
  String questId;

  /// How many times the quest trigger has fired so far.
  @HiveField(1)
  int currentProgress;

  /// true once the player has claimed the reward (quest is done).
  @HiveField(2)
  bool isCompleted;

  /// null for achievements (they never reset).
  /// Set to the next reset time for daily quests.
  @HiveField(3)
  DateTime? resetAt;

  QuestModel({
    required this.questId,
    required this.currentProgress,
    required this.isCompleted,
    this.resetAt,
  });

  // -------------------------------------------------------------------------
  // Convenience factory — creates a fresh, zero-progress quest instance
  // -------------------------------------------------------------------------

  factory QuestModel.fromDefinition(QuestDefinition def) {
    DateTime? resetAt;
    if (def.type == QuestType.daily) {
      resetAt = _nextDailyReset();
    } else if (def.type == QuestType.weekly) {
      resetAt = _nextWeeklyReset();
    }
    return QuestModel(
      questId:         def.id,
      currentProgress: 0,
      isCompleted:     false,
      resetAt:         resetAt,
    );
  }

  // -------------------------------------------------------------------------
  // copyWith
  // -------------------------------------------------------------------------

  QuestModel copyWith({
    String?   questId,
    int?      currentProgress,
    bool?     isCompleted,
    Object?   resetAt = _sentinel,
  }) {
    return QuestModel(
      questId:         questId         ?? this.questId,
      currentProgress: currentProgress ?? this.currentProgress,
      isCompleted:     isCompleted     ?? this.isCompleted,
      resetAt:         resetAt == _sentinel
          ? this.resetAt
          : resetAt as DateTime?,
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Returns the UTC timestamp for the next daily-reset boundary (midnight UTC).
  static DateTime _nextDailyReset() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day + 1);
  }

  /// Returns the UTC timestamp for the next Monday midnight.
  static DateTime _nextWeeklyReset() {
    final now = DateTime.now().toUtc();
    final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
    final nextMonday = daysUntilMonday == 0 ? 7 : daysUntilMonday;
    return DateTime.utc(now.year, now.month, now.day + nextMonday);
  }

  @override
  String toString() {
    return 'QuestModel(questId: $questId, currentProgress: $currentProgress, '
        'isCompleted: $isCompleted, resetAt: $resetAt)';
  }
}

// Sentinel used by copyWith to distinguish "not provided" from explicit null.
const Object _sentinel = Object();

// =============================================================================
// Manual TypeAdapter — replaces code-generated quest_model.g.dart
// =============================================================================

class QuestModelAdapter extends TypeAdapter<QuestModel> {
  @override
  final int typeId = 3;

  @override
  QuestModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return QuestModel(
      questId:         fields[0] as String,
      currentProgress: fields[1] as int,
      isCompleted:     fields[2] as bool,
      resetAt:         fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, QuestModel obj) {
    writer
      ..writeByte(4) // total number of fields
      ..writeByte(0)
      ..write(obj.questId)
      ..writeByte(1)
      ..write(obj.currentProgress)
      ..writeByte(2)
      ..write(obj.isCompleted)
      ..writeByte(3)
      ..write(obj.resetAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
