/// Static mount template for gacha pool.
class MountTemplate {
  final String id;
  final String name;
  final int rarity; // 1-5
  final String statType; // atk, def, hp, spd
  final double statValue;
  final int gachaWeight;
  final String description;

  const MountTemplate({
    required this.id,
    required this.name,
    required this.rarity,
    required this.statType,
    required this.statValue,
    required this.gachaWeight,
    this.description = '',
  });
}

class MountDatabase {
  MountDatabase._();

  static const List<MountTemplate> all = [
    // ── 1★ Common ──────────────────────────────────────────────
    MountTemplate(
      id: 'donkey',
      name: '당나귀',
      rarity: 1,
      statType: 'spd',
      statValue: 3,
      gachaWeight: 30,
      description: '느리지만 묵묵한 당나귀',
    ),
    MountTemplate(
      id: 'pony',
      name: '조랑말',
      rarity: 1,
      statType: 'spd',
      statValue: 5,
      gachaWeight: 30,
      description: '쾌활한 조랑말',
    ),
    MountTemplate(
      id: 'boar',
      name: '멧돼지',
      rarity: 1,
      statType: 'atk',
      statValue: 8,
      gachaWeight: 30,
      description: '돌진하는 멧돼지',
    ),

    // ── 2★ Uncommon ────────────────────────────────────────────
    MountTemplate(
      id: 'war_horse',
      name: '군마',
      rarity: 2,
      statType: 'spd',
      statValue: 10,
      gachaWeight: 20,
      description: '전쟁터에서 단련된 군마',
    ),
    MountTemplate(
      id: 'dire_wolf',
      name: '다이어 울프',
      rarity: 2,
      statType: 'atk',
      statValue: 15,
      gachaWeight: 20,
      description: '흉포한 거대 늑대',
    ),
    MountTemplate(
      id: 'armored_bear',
      name: '장갑 곰',
      rarity: 2,
      statType: 'def',
      statValue: 12,
      gachaWeight: 20,
      description: '철갑을 두른 곰',
    ),

    // ── 3★ Rare ────────────────────────────────────────────────
    MountTemplate(
      id: 'griffin',
      name: '그리핀',
      rarity: 3,
      statType: 'spd',
      statValue: 20,
      gachaWeight: 10,
      description: '하늘을 나는 사자독수리',
    ),
    MountTemplate(
      id: 'nightmare',
      name: '나이트메어',
      rarity: 3,
      statType: 'atk',
      statValue: 30,
      gachaWeight: 10,
      description: '불꽃 말발굽의 악몽마',
    ),
    MountTemplate(
      id: 'giant_turtle',
      name: '거대 거북',
      rarity: 3,
      statType: 'hp',
      statValue: 100,
      gachaWeight: 10,
      description: '등에 요새를 짊어진 거북',
    ),

    // ── 4★ Epic ────────────────────────────────────────────────
    MountTemplate(
      id: 'wyvern',
      name: '와이번',
      rarity: 4,
      statType: 'atk',
      statValue: 50,
      gachaWeight: 4,
      description: '두 날개의 비룡',
    ),
    MountTemplate(
      id: 'unicorn',
      name: '유니콘',
      rarity: 4,
      statType: 'hp',
      statValue: 200,
      gachaWeight: 4,
      description: '치유의 뿔을 가진 환수',
    ),

    // ── 5★ Legendary ───────────────────────────────────────────
    MountTemplate(
      id: 'elder_dragon',
      name: '태고의 용',
      rarity: 5,
      statType: 'atk',
      statValue: 100,
      gachaWeight: 1,
      description: '천년을 산 최강의 용',
    ),
    MountTemplate(
      id: 'celestial_phoenix',
      name: '천상의 봉황',
      rarity: 5,
      statType: 'spd',
      statValue: 50,
      gachaWeight: 1,
      description: '불멸의 날개를 가진 봉황',
    ),
  ];

  // Pre-built weighted pool
  static final List<String> weightedPool = _buildPool();

  static List<String> _buildPool() {
    final pool = <String>[];
    for (final t in all) {
      for (int i = 0; i < t.gachaWeight; i++) {
        pool.add(t.id);
      }
    }
    return pool;
  }

  static MountTemplate? findById(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<MountTemplate> byRarity(int rarity) =>
      all.where((t) => t.rarity == rarity).toList();

  static const Map<int, double> gachaProbabilities = {
    1: 0.45,
    2: 0.30,
    3: 0.15,
    4: 0.08,
    5: 0.02,
  };
}
