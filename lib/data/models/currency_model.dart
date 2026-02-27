import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class CurrencyModel extends HiveObject {
  /// Soft currency — earned from battles and stages.
  @HiveField(0)
  int gold;

  /// Premium currency — purchased or earned from special events.
  @HiveField(1)
  int diamond;

  /// Upgrade material — used to evolve monsters.
  @HiveField(2)
  int monsterShard;

  /// Item — grants experience to a monster when used.
  @HiveField(3)
  int expPotion;

  /// Item — used to perform one monster gacha pull.
  @HiveField(4)
  int gachaTicket;

  /// Ticket for skill gacha pulls.
  @HiveField(5)
  int skillTicket;

  /// Ticket for relic/item gacha pulls.
  @HiveField(6)
  int relicTicket;

  /// Gem for mount gacha pulls.
  @HiveField(7)
  int mountGem;

  CurrencyModel({
    required this.gold,
    required this.diamond,
    required this.monsterShard,
    required this.expPotion,
    required this.gachaTicket,
    this.skillTicket = 0,
    this.relicTicket = 0,
    this.mountGem = 0,
  });

  // -------------------------------------------------------------------------
  // Convenience factory for new players
  // -------------------------------------------------------------------------

  factory CurrencyModel.initial() {
    return CurrencyModel(
      gold: 500,
      diamond: 50,
      monsterShard: 0,
      expPotion: 5,
      gachaTicket: 3,
    );
  }

  // -------------------------------------------------------------------------
  // Arithmetic helpers
  // -------------------------------------------------------------------------

  /// Returns true if the player can afford the given cost.
  bool canAfford({
    int gold = 0,
    int diamond = 0,
    int monsterShard = 0,
    int expPotion = 0,
    int gachaTicket = 0,
    int skillTicket = 0,
    int relicTicket = 0,
    int mountGem = 0,
  }) {
    return this.gold >= gold &&
        this.diamond >= diamond &&
        this.monsterShard >= monsterShard &&
        this.expPotion >= expPotion &&
        this.gachaTicket >= gachaTicket &&
        this.skillTicket >= skillTicket &&
        this.relicTicket >= relicTicket &&
        this.mountGem >= mountGem;
  }

  /// Returns a new [CurrencyModel] with the given amounts added (use negative
  /// values to subtract / spend currency).
  CurrencyModel add({
    int gold = 0,
    int diamond = 0,
    int monsterShard = 0,
    int expPotion = 0,
    int gachaTicket = 0,
    int skillTicket = 0,
    int relicTicket = 0,
    int mountGem = 0,
  }) {
    return CurrencyModel(
      gold: (this.gold + gold).clamp(0, 9999999),
      diamond: (this.diamond + diamond).clamp(0, 9999999),
      monsterShard: (this.monsterShard + monsterShard).clamp(0, 9999999),
      expPotion: (this.expPotion + expPotion).clamp(0, 9999999),
      gachaTicket: (this.gachaTicket + gachaTicket).clamp(0, 9999999),
      skillTicket: (this.skillTicket + skillTicket).clamp(0, 9999999),
      relicTicket: (this.relicTicket + relicTicket).clamp(0, 9999999),
      mountGem: (this.mountGem + mountGem).clamp(0, 9999999),
    );
  }

  // -------------------------------------------------------------------------
  // copyWith
  // -------------------------------------------------------------------------

  CurrencyModel copyWith({
    int? gold,
    int? diamond,
    int? monsterShard,
    int? expPotion,
    int? gachaTicket,
    int? skillTicket,
    int? relicTicket,
    int? mountGem,
  }) {
    return CurrencyModel(
      gold: gold ?? this.gold,
      diamond: diamond ?? this.diamond,
      monsterShard: monsterShard ?? this.monsterShard,
      expPotion: expPotion ?? this.expPotion,
      gachaTicket: gachaTicket ?? this.gachaTicket,
      skillTicket: skillTicket ?? this.skillTicket,
      relicTicket: relicTicket ?? this.relicTicket,
      mountGem: mountGem ?? this.mountGem,
    );
  }

  @override
  String toString() {
    return 'CurrencyModel(gold: $gold, diamond: $diamond, '
        'monsterShard: $monsterShard, expPotion: $expPotion, '
        'gachaTicket: $gachaTicket, skillTicket: $skillTicket, '
        'relicTicket: $relicTicket, mountGem: $mountGem)';
  }
}

// =============================================================================
// Manual TypeAdapter — replaces code-generated currency_model.g.dart
// =============================================================================

class CurrencyModelAdapter extends TypeAdapter<CurrencyModel> {
  @override
  final int typeId = 2;

  @override
  CurrencyModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return CurrencyModel(
      gold:         fields[0] as int,
      diamond:      fields[1] as int,
      monsterShard: fields[2] as int,
      expPotion:    fields[3] as int,
      gachaTicket:  fields[4] as int,
      skillTicket:  fields[5] as int? ?? 0,
      relicTicket:  fields[6] as int? ?? 0,
      mountGem:     fields[7] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, CurrencyModel obj) {
    writer
      ..writeByte(8) // number of fields
      ..writeByte(0)
      ..write(obj.gold)
      ..writeByte(1)
      ..write(obj.diamond)
      ..writeByte(2)
      ..write(obj.monsterShard)
      ..writeByte(3)
      ..write(obj.expPotion)
      ..writeByte(4)
      ..write(obj.gachaTicket)
      ..writeByte(5)
      ..write(obj.skillTicket)
      ..writeByte(6)
      ..write(obj.relicTicket)
      ..writeByte(7)
      ..write(obj.mountGem);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
