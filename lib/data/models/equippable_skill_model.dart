import 'package:hive/hive.dart';

@HiveType(typeId: 8)
class EquippableSkillModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String templateId;

  @HiveField(2)
  String name;

  @HiveField(3)
  int rarity;

  @HiveField(4)
  String skillType;

  @HiveField(5)
  double value;

  @HiveField(6)
  int cooldown;

  @HiveField(7)
  String? equippedMonsterId;

  @HiveField(8)
  DateTime acquiredAt;

  @HiveField(9)
  int level;

  @HiveField(10)
  String description;

  EquippableSkillModel({
    required this.id,
    required this.templateId,
    required this.name,
    required this.rarity,
    required this.skillType,
    required this.value,
    required this.cooldown,
    this.equippedMonsterId,
    required this.acquiredAt,
    this.level = 1,
    this.description = '',
  });

  bool get isEquipped => equippedMonsterId != null;

  int get maxLevel => rarity * 5;

  double get effectiveValue => value * (1.0 + (level - 1) * 0.1);

  bool get canLevelUp => level < maxLevel;

  EquippableSkillModel copyWith({
    String? id,
    String? templateId,
    String? name,
    int? rarity,
    String? skillType,
    double? value,
    int? cooldown,
    String? equippedMonsterId,
    bool clearEquip = false,
    DateTime? acquiredAt,
    int? level,
    String? description,
  }) {
    return EquippableSkillModel(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      rarity: rarity ?? this.rarity,
      skillType: skillType ?? this.skillType,
      value: value ?? this.value,
      cooldown: cooldown ?? this.cooldown,
      equippedMonsterId: clearEquip ? null : (equippedMonsterId ?? this.equippedMonsterId),
      acquiredAt: acquiredAt ?? this.acquiredAt,
      level: level ?? this.level,
      description: description ?? this.description,
    );
  }
}

// =============================================================================
// Manual TypeAdapter
// =============================================================================

class EquippableSkillModelAdapter extends TypeAdapter<EquippableSkillModel> {
  @override
  final int typeId = 8;

  @override
  EquippableSkillModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return EquippableSkillModel(
      id: fields[0] as String,
      templateId: fields[1] as String,
      name: fields[2] as String,
      rarity: fields[3] as int,
      skillType: fields[4] as String,
      value: (fields[5] as num).toDouble(),
      cooldown: fields[6] as int,
      equippedMonsterId: fields[7] as String?,
      acquiredAt: fields[8] as DateTime,
      level: fields[9] as int? ?? 1,
      description: fields[10] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, EquippableSkillModel obj) {
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
      ..write(obj.skillType)
      ..writeByte(5)
      ..write(obj.value)
      ..writeByte(6)
      ..write(obj.cooldown)
      ..writeByte(7)
      ..write(obj.equippedMonsterId)
      ..writeByte(8)
      ..write(obj.acquiredAt)
      ..writeByte(9)
      ..write(obj.level)
      ..writeByte(10)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquippableSkillModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
