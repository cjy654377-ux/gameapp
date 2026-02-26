import 'package:hive/hive.dart';

// =============================================================================
// Relic type enum
// =============================================================================

enum RelicType { weapon, armor, accessory }

enum RelicStat { atk, def, hp, spd }

// =============================================================================
// RelicModel
// =============================================================================

@HiveType(typeId: 4)
class RelicModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String templateId;

  @HiveField(2)
  String name;

  /// 'weapon', 'armor', 'accessory'
  @HiveField(3)
  String type;

  /// 1-5 rarity
  @HiveField(4)
  int rarity;

  /// 'atk', 'def', 'hp', 'spd'
  @HiveField(5)
  String statType;

  /// Flat stat bonus value.
  @HiveField(6)
  double statValue;

  /// Monster ID this relic is equipped to (null = unequipped).
  @HiveField(7)
  String? equippedMonsterId;

  @HiveField(8)
  DateTime acquiredAt;

  RelicModel({
    required this.id,
    required this.templateId,
    required this.name,
    required this.type,
    required this.rarity,
    required this.statType,
    required this.statValue,
    this.equippedMonsterId,
    required this.acquiredAt,
  });

  bool get isEquipped => equippedMonsterId != null;

  RelicType get relicType {
    switch (type) {
      case 'weapon':
        return RelicType.weapon;
      case 'armor':
        return RelicType.armor;
      default:
        return RelicType.accessory;
    }
  }

  RelicStat get relicStat {
    switch (statType) {
      case 'atk':
        return RelicStat.atk;
      case 'def':
        return RelicStat.def;
      case 'hp':
        return RelicStat.hp;
      default:
        return RelicStat.spd;
    }
  }

  RelicModel copyWith({
    String? id,
    String? templateId,
    String? name,
    String? type,
    int? rarity,
    String? statType,
    double? statValue,
    String? equippedMonsterId,
    bool clearEquip = false,
    DateTime? acquiredAt,
  }) {
    return RelicModel(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      statType: statType ?? this.statType,
      statValue: statValue ?? this.statValue,
      equippedMonsterId:
          clearEquip ? null : (equippedMonsterId ?? this.equippedMonsterId),
      acquiredAt: acquiredAt ?? this.acquiredAt,
    );
  }

  @override
  String toString() =>
      'RelicModel($name, $type, $statType+$statValue, rarity:$rarity)';
}

// =============================================================================
// Manual TypeAdapter
// =============================================================================

class RelicModelAdapter extends TypeAdapter<RelicModel> {
  @override
  final int typeId = 4;

  @override
  RelicModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return RelicModel(
      id:                fields[0] as String,
      templateId:        fields[1] as String,
      name:              fields[2] as String,
      type:              fields[3] as String,
      rarity:            fields[4] as int,
      statType:          fields[5] as String,
      statValue:         (fields[6] as num).toDouble(),
      equippedMonsterId: fields[7] as String?,
      acquiredAt:        fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RelicModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.templateId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.rarity)
      ..writeByte(5)
      ..write(obj.statType)
      ..writeByte(6)
      ..write(obj.statValue)
      ..writeByte(7)
      ..write(obj.equippedMonsterId)
      ..writeByte(8)
      ..write(obj.acquiredAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelicModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
