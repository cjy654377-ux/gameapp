import 'package:hive/hive.dart';

/// Rarity constants
/// 1 = 일반 (1-star)
/// 2 = 고급 (2-star)
/// 3 = 희귀 (3-star)
/// 4 = 영웅 (4-star)
/// 5 = 전설 (5-star)

/// Element constants
/// 'fire', 'water', 'electric', 'stone', 'grass', 'ghost', 'light', 'dark'

/// Size constants
/// 'small', 'medium', 'large', 'extraLarge'

@HiveType(typeId: 0)
class MonsterModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String templateId;

  @HiveField(2)
  String name;

  /// 1 = 일반, 2 = 고급, 3 = 희귀, 4 = 영웅, 5 = 전설
  @HiveField(3)
  int rarity;

  /// 'fire', 'water', 'electric', 'stone', 'grass', 'ghost', 'light', 'dark'
  @HiveField(4)
  String element;

  @HiveField(5)
  int level;

  @HiveField(6)
  int experience;

  /// 0 = Base, 1 = First Evolution, 2 = Final Evolution
  @HiveField(7)
  int evolutionStage;

  @HiveField(8)
  double baseAtk;

  @HiveField(9)
  double baseDef;

  @HiveField(10)
  double baseHp;

  @HiveField(11)
  double baseSpd;

  @HiveField(12)
  DateTime acquiredAt;

  @HiveField(13)
  bool isInTeam;

  /// 'small', 'medium', 'large', 'extraLarge'
  @HiveField(14)
  String size;

  /// Skill display name in Korean (nullable)
  @HiveField(15)
  String? skillName;

  MonsterModel({
    required this.id,
    required this.templateId,
    required this.name,
    required this.rarity,
    required this.element,
    required this.level,
    required this.experience,
    required this.evolutionStage,
    required this.baseAtk,
    required this.baseDef,
    required this.baseHp,
    required this.baseSpd,
    required this.acquiredAt,
    required this.isInTeam,
    required this.size,
    this.skillName,
  });

  // -------------------------------------------------------------------------
  // Scaling helpers
  // -------------------------------------------------------------------------

  /// Per-level growth multiplier. Each level adds 5 % of the base stat.
  double get _levelMultiplier => 1.0 + (level - 1) * 0.05;

  /// Per-evolution-stage multiplier.
  /// Stage 0 = ×1.0, Stage 1 = ×1.25, Stage 2 = ×1.60
  double get _evolutionMultiplier {
    switch (evolutionStage) {
      case 1:
        return 1.25;
      case 2:
        return 1.60;
      default:
        return 1.0;
    }
  }

  // -------------------------------------------------------------------------
  // Computed final stats
  // -------------------------------------------------------------------------

  double get finalAtk => baseAtk * _levelMultiplier * _evolutionMultiplier;
  double get finalDef => baseDef * _levelMultiplier * _evolutionMultiplier;
  double get finalHp  => baseHp  * _levelMultiplier * _evolutionMultiplier;
  double get finalSpd => baseSpd * _levelMultiplier * _evolutionMultiplier;

  // -------------------------------------------------------------------------
  // Experience system
  // -------------------------------------------------------------------------

  /// Experience required to reach the next level.
  /// Formula: base 100 XP, scaled by 1.2^(level-1), rounded to nearest int.
  int get expToNextLevel => (100 * (1.2 * level)).round();

  // -------------------------------------------------------------------------
  // Convenience factory from template
  // -------------------------------------------------------------------------

  factory MonsterModel.fromTemplate({
    required String id,
    required String templateId,
    required String name,
    required int rarity,
    required String element,
    required double baseAtk,
    required double baseDef,
    required double baseHp,
    required double baseSpd,
    required String size,
    String? skillName,
  }) {
    return MonsterModel(
      id: id,
      templateId: templateId,
      name: name,
      rarity: rarity,
      element: element,
      level: 1,
      experience: 0,
      evolutionStage: 0,
      baseAtk: baseAtk,
      baseDef: baseDef,
      baseHp: baseHp,
      baseSpd: baseSpd,
      acquiredAt: DateTime.now(),
      isInTeam: false,
      size: size,
      skillName: skillName,
    );
  }

  // -------------------------------------------------------------------------
  // copyWith
  // -------------------------------------------------------------------------

  MonsterModel copyWith({
    String? id,
    String? templateId,
    String? name,
    int? rarity,
    String? element,
    int? level,
    int? experience,
    int? evolutionStage,
    double? baseAtk,
    double? baseDef,
    double? baseHp,
    double? baseSpd,
    DateTime? acquiredAt,
    bool? isInTeam,
    String? size,
    Object? skillName = _sentinel,
  }) {
    return MonsterModel(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      rarity: rarity ?? this.rarity,
      element: element ?? this.element,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      evolutionStage: evolutionStage ?? this.evolutionStage,
      baseAtk: baseAtk ?? this.baseAtk,
      baseDef: baseDef ?? this.baseDef,
      baseHp: baseHp ?? this.baseHp,
      baseSpd: baseSpd ?? this.baseSpd,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      isInTeam: isInTeam ?? this.isInTeam,
      size: size ?? this.size,
      skillName: skillName == _sentinel
          ? this.skillName
          : skillName as String?,
    );
  }

  @override
  String toString() {
    return 'MonsterModel(id: $id, name: $name, rarity: $rarity, '
        'element: $element, size: $size, level: $level, '
        'evolutionStage: $evolutionStage, skillName: $skillName)';
  }
}

// Sentinel object used by copyWith to distinguish "not provided" from null
// for the nullable skillName parameter.
const Object _sentinel = Object();

// =============================================================================
// Manual TypeAdapter — replaces code-generated monster_model.g.dart
// =============================================================================

class MonsterModelAdapter extends TypeAdapter<MonsterModel> {
  @override
  final int typeId = 0;

  @override
  MonsterModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return MonsterModel(
      id:             fields[0]  as String,
      templateId:     fields[1]  as String,
      name:           fields[2]  as String,
      rarity:         fields[3]  as int,
      element:        fields[4]  as String,
      level:          fields[5]  as int,
      experience:     fields[6]  as int,
      evolutionStage: fields[7]  as int,
      baseAtk:        fields[8]  as double,
      baseDef:        fields[9]  as double,
      baseHp:         fields[10] as double,
      baseSpd:        fields[11] as double,
      acquiredAt:     fields[12] as DateTime,
      isInTeam:       fields[13] as bool,
      size:           fields[14] as String? ?? 'small',
      skillName:      fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MonsterModel obj) {
    writer
      ..writeByte(16) // total number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.templateId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.rarity)
      ..writeByte(4)
      ..write(obj.element)
      ..writeByte(5)
      ..write(obj.level)
      ..writeByte(6)
      ..write(obj.experience)
      ..writeByte(7)
      ..write(obj.evolutionStage)
      ..writeByte(8)
      ..write(obj.baseAtk)
      ..writeByte(9)
      ..write(obj.baseDef)
      ..writeByte(10)
      ..write(obj.baseHp)
      ..writeByte(11)
      ..write(obj.baseSpd)
      ..writeByte(12)
      ..write(obj.acquiredAt)
      ..writeByte(13)
      ..write(obj.isInTeam)
      ..writeByte(14)
      ..write(obj.size)
      ..writeByte(15)
      ..write(obj.skillName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonsterModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
