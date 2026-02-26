import 'package:hive/hive.dart';

@HiveType(typeId: 5)
class GuildModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int level;

  @HiveField(3)
  int exp;

  /// Guild currency earned from boss contributions.
  @HiveField(4)
  int guildCoin;

  /// Simulated AI member names.
  @HiveField(5)
  List<String> memberNames;

  /// Guild boss HP remaining (resets weekly).
  @HiveField(6)
  double bossHpRemaining;

  /// Total damage dealt by player to current boss.
  @HiveField(7)
  double playerContribution;

  /// Total damage dealt by AI members to current boss.
  @HiveField(8)
  double aiContribution;

  /// Week number when boss was last reset.
  @HiveField(9)
  int lastBossResetWeek;

  /// Daily guild boss attempts used.
  @HiveField(10)
  int dailyBossAttempts;

  /// Date string of last daily reset (YYYY-MM-DD).
  @HiveField(11)
  String lastDailyResetDate;

  /// Items purchased from guild shop (bitmask).
  @HiveField(12)
  int shopPurchaseBitmask;

  GuildModel({
    required this.id,
    required this.name,
    this.level = 1,
    this.exp = 0,
    this.guildCoin = 0,
    required this.memberNames,
    this.bossHpRemaining = 0,
    this.playerContribution = 0,
    this.aiContribution = 0,
    this.lastBossResetWeek = 0,
    this.dailyBossAttempts = 0,
    this.lastDailyResetDate = '',
    this.shopPurchaseBitmask = 0,
  });

  int get expToNextLevel => (500 * level * 1.2).round();

  GuildModel copyWith({
    String? id,
    String? name,
    int? level,
    int? exp,
    int? guildCoin,
    List<String>? memberNames,
    double? bossHpRemaining,
    double? playerContribution,
    double? aiContribution,
    int? lastBossResetWeek,
    int? dailyBossAttempts,
    String? lastDailyResetDate,
    int? shopPurchaseBitmask,
  }) {
    return GuildModel(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      exp: exp ?? this.exp,
      guildCoin: guildCoin ?? this.guildCoin,
      memberNames: memberNames ?? List<String>.from(this.memberNames),
      bossHpRemaining: bossHpRemaining ?? this.bossHpRemaining,
      playerContribution: playerContribution ?? this.playerContribution,
      aiContribution: aiContribution ?? this.aiContribution,
      lastBossResetWeek: lastBossResetWeek ?? this.lastBossResetWeek,
      dailyBossAttempts: dailyBossAttempts ?? this.dailyBossAttempts,
      lastDailyResetDate: lastDailyResetDate ?? this.lastDailyResetDate,
      shopPurchaseBitmask: shopPurchaseBitmask ?? this.shopPurchaseBitmask,
    );
  }

  @override
  String toString() => 'GuildModel($name, Lv.$level, coins:$guildCoin)';
}

// Manual TypeAdapter
class GuildModelAdapter extends TypeAdapter<GuildModel> {
  @override
  final int typeId = 5;

  @override
  GuildModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return GuildModel(
      id: fields[0] as String,
      name: fields[1] as String,
      level: fields[2] as int? ?? 1,
      exp: fields[3] as int? ?? 0,
      guildCoin: fields[4] as int? ?? 0,
      memberNames: (fields[5] as List?)?.cast<String>() ?? [],
      bossHpRemaining: (fields[6] as num?)?.toDouble() ?? 0,
      playerContribution: (fields[7] as num?)?.toDouble() ?? 0,
      aiContribution: (fields[8] as num?)?.toDouble() ?? 0,
      lastBossResetWeek: fields[9] as int? ?? 0,
      dailyBossAttempts: fields[10] as int? ?? 0,
      lastDailyResetDate: fields[11] as String? ?? '',
      shopPurchaseBitmask: fields[12] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, GuildModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.level)
      ..writeByte(3)..write(obj.exp)
      ..writeByte(4)..write(obj.guildCoin)
      ..writeByte(5)..write(obj.memberNames)
      ..writeByte(6)..write(obj.bossHpRemaining)
      ..writeByte(7)..write(obj.playerContribution)
      ..writeByte(8)..write(obj.aiContribution)
      ..writeByte(9)..write(obj.lastBossResetWeek)
      ..writeByte(10)..write(obj.dailyBossAttempts)
      ..writeByte(11)..write(obj.lastDailyResetDate)
      ..writeByte(12)..write(obj.shopPurchaseBitmask);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuildModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
