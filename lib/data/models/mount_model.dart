import 'package:hive/hive.dart';

/// Stat bonus type a mount can provide.
enum MountStatType { atk, def, hp, spd }

@HiveType(typeId: 7)
class MountModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String templateId;

  @HiveField(2)
  String name;

  @HiveField(3)
  int rarity; // 1-5

  @HiveField(4)
  String statType; // atk, def, hp, spd

  @HiveField(5)
  double statValue;

  @HiveField(6)
  String? equippedMonsterId;

  @HiveField(7)
  DateTime acquiredAt;

  @HiveField(8)
  int level;

  @HiveField(9)
  int experience;

  @HiveField(10)
  String description;

  MountModel({
    required this.id,
    required this.templateId,
    required this.name,
    required this.rarity,
    required this.statType,
    required this.statValue,
    this.equippedMonsterId,
    required this.acquiredAt,
    this.level = 1,
    this.experience = 0,
    this.description = '',
  });

  bool get isEquipped => equippedMonsterId != null;

  int get maxLevel => rarity * 10; // 1★=10, 5★=50

  double get effectiveStatValue => statValue * (1.0 + (level - 1) * 0.05);

  MountStatType get mountStatType => MountStatType.values.firstWhere(
        (e) => e.name == statType,
        orElse: () => MountStatType.atk,
      );

  int get expToNextLevel => level * 100;

  bool get canLevelUp => level < maxLevel && experience >= expToNextLevel;

  MountModel copyWith({
    String? id,
    String? templateId,
    String? name,
    int? rarity,
    String? statType,
    double? statValue,
    String? equippedMonsterId,
    bool clearEquip = false,
    DateTime? acquiredAt,
    int? level,
    int? experience,
    String? description,
  }) {
    return MountModel(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      rarity: rarity ?? this.rarity,
      statType: statType ?? this.statType,
      statValue: statValue ?? this.statValue,
      equippedMonsterId:
          clearEquip ? null : (equippedMonsterId ?? this.equippedMonsterId),
      acquiredAt: acquiredAt ?? this.acquiredAt,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      description: description ?? this.description,
    );
  }
}

// =============================================================================
// Manual TypeAdapter
// =============================================================================

class MountModelAdapter extends TypeAdapter<MountModel> {
  @override
  final int typeId = 7;

  @override
  MountModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return MountModel(
      id: fields[0] as String,
      templateId: fields[1] as String,
      name: fields[2] as String,
      rarity: fields[3] as int,
      statType: fields[4] as String,
      statValue: fields[5] as double,
      equippedMonsterId: fields[6] as String?,
      acquiredAt: fields[7] as DateTime,
      level: fields[8] as int? ?? 1,
      experience: fields[9] as int? ?? 0,
      description: fields[10] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, MountModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.templateId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.rarity)
      ..writeByte(4)
      ..write(obj.statType)
      ..writeByte(5)
      ..write(obj.statValue)
      ..writeByte(6)
      ..write(obj.equippedMonsterId)
      ..writeByte(7)
      ..write(obj.acquiredAt)
      ..writeByte(8)
      ..write(obj.level)
      ..writeByte(9)
      ..write(obj.experience)
      ..writeByte(10)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MountModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
