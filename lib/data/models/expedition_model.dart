import 'package:hive/hive.dart';

/// Represents a single expedition slot.
@HiveType(typeId: 6)
class ExpeditionModel extends HiveObject {
  @HiveField(0)
  String id;

  /// Duration in seconds (3600=1h, 14400=4h, 28800=8h).
  @HiveField(1)
  int durationSeconds;

  /// When the expedition was started.
  @HiveField(2)
  DateTime startedAt;

  /// Monster IDs dispatched on this expedition.
  @HiveField(3)
  List<String> monsterIds;

  /// Monster names (for display even if monsters change).
  @HiveField(4)
  List<String> monsterNames;

  /// Sum of dispatched monster levels (for reward scaling).
  @HiveField(5)
  int totalMonsterLevel;

  /// Whether rewards have been collected.
  @HiveField(6)
  bool isCollected;

  ExpeditionModel({
    required this.id,
    required this.durationSeconds,
    required this.startedAt,
    required this.monsterIds,
    required this.monsterNames,
    required this.totalMonsterLevel,
    this.isCollected = false,
  });

  DateTime get completesAt =>
      startedAt.add(Duration(seconds: durationSeconds));

  bool get isComplete => DateTime.now().isAfter(completesAt);

  Duration get remainingTime {
    final diff = completesAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  double get progress {
    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    return (elapsed / durationSeconds).clamp(0.0, 1.0);
  }

  String get durationLabel {
    final hours = durationSeconds ~/ 3600;
    return '$hours시간';
  }

  ExpeditionModel copyWith({
    String? id,
    int? durationSeconds,
    DateTime? startedAt,
    List<String>? monsterIds,
    List<String>? monsterNames,
    int? totalMonsterLevel,
    bool? isCollected,
  }) {
    return ExpeditionModel(
      id: id ?? this.id,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      startedAt: startedAt ?? this.startedAt,
      monsterIds: monsterIds ?? this.monsterIds,
      monsterNames: monsterNames ?? this.monsterNames,
      totalMonsterLevel: totalMonsterLevel ?? this.totalMonsterLevel,
      isCollected: isCollected ?? this.isCollected,
    );
  }
}

// =============================================================================
// Manual TypeAdapter
// =============================================================================

class ExpeditionModelAdapter extends TypeAdapter<ExpeditionModel> {
  @override
  final int typeId = 6;

  @override
  ExpeditionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExpeditionModel(
      id: fields[0] as String,
      durationSeconds: fields[1] as int,
      startedAt: fields[2] as DateTime,
      monsterIds: (fields[3] as List).cast<String>(),
      monsterNames: (fields[4] as List).cast<String>(),
      totalMonsterLevel: fields[5] as int? ?? 1,
      isCollected: fields[6] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, ExpeditionModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.durationSeconds)
      ..writeByte(2)
      ..write(obj.startedAt)
      ..writeByte(3)
      ..write(obj.monsterIds)
      ..writeByte(4)
      ..write(obj.monsterNames)
      ..writeByte(5)
      ..write(obj.totalMonsterLevel)
      ..writeByte(6)
      ..write(obj.isCollected);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpeditionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
