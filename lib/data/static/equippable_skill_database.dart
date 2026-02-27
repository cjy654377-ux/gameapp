/// Static templates for equippable skills obtained via skill gacha.
class EquippableSkillTemplate {
  final String id;
  final String name;
  final int rarity; // 1-5
  final String skillType; // 'atk_buff', 'def_buff', 'hp_regen', 'crit_boost', 'speed_buff', 'damage'
  final double value;
  final int cooldown;
  final int gachaWeight;
  final String description;

  const EquippableSkillTemplate({
    required this.id,
    required this.name,
    required this.rarity,
    required this.skillType,
    required this.value,
    required this.cooldown,
    required this.gachaWeight,
    this.description = '',
  });
}

class EquippableSkillDatabase {
  EquippableSkillDatabase._();

  static const List<EquippableSkillTemplate> all = [
    // ── 1★ Common ──
    EquippableSkillTemplate(
      id: 'minor_strike',
      name: '약한 일격',
      rarity: 1,
      skillType: 'damage',
      value: 1.2,
      cooldown: 2,
      gachaWeight: 30,
      description: '적에게 120% 데미지',
    ),
    EquippableSkillTemplate(
      id: 'minor_guard',
      name: '방어 자세',
      rarity: 1,
      skillType: 'def_buff',
      value: 10,
      cooldown: 3,
      gachaWeight: 30,
      description: '방어력 +10% (3턴)',
    ),
    EquippableSkillTemplate(
      id: 'minor_heal',
      name: '응급 치료',
      rarity: 1,
      skillType: 'hp_regen',
      value: 5,
      cooldown: 3,
      gachaWeight: 30,
      description: 'HP 5% 회복',
    ),

    // ── 2★ Uncommon ──
    EquippableSkillTemplate(
      id: 'power_slash',
      name: '파워 슬래시',
      rarity: 2,
      skillType: 'damage',
      value: 1.5,
      cooldown: 3,
      gachaWeight: 20,
      description: '적에게 150% 데미지',
    ),
    EquippableSkillTemplate(
      id: 'iron_wall',
      name: '철벽 방어',
      rarity: 2,
      skillType: 'def_buff',
      value: 20,
      cooldown: 4,
      gachaWeight: 20,
      description: '방어력 +20% (3턴)',
    ),
    EquippableSkillTemplate(
      id: 'quick_step',
      name: '재빠른 발걸음',
      rarity: 2,
      skillType: 'speed_buff',
      value: 15,
      cooldown: 3,
      gachaWeight: 20,
      description: '속도 +15% (3턴)',
    ),

    // ── 3★ Rare ──
    EquippableSkillTemplate(
      id: 'flame_burst',
      name: '화염 폭발',
      rarity: 3,
      skillType: 'damage',
      value: 2.0,
      cooldown: 4,
      gachaWeight: 10,
      description: '적에게 200% 화염 데미지',
    ),
    EquippableSkillTemplate(
      id: 'battle_cry',
      name: '전투 함성',
      rarity: 3,
      skillType: 'atk_buff',
      value: 25,
      cooldown: 4,
      gachaWeight: 10,
      description: '공격력 +25% (3턴)',
    ),
    EquippableSkillTemplate(
      id: 'healing_light',
      name: '치유의 빛',
      rarity: 3,
      skillType: 'hp_regen',
      value: 15,
      cooldown: 4,
      gachaWeight: 10,
      description: 'HP 15% 회복',
    ),

    // ── 4★ Epic ──
    EquippableSkillTemplate(
      id: 'thunder_god',
      name: '뇌신의 일격',
      rarity: 4,
      skillType: 'damage',
      value: 3.0,
      cooldown: 5,
      gachaWeight: 4,
      description: '적에게 300% 번개 데미지',
    ),
    EquippableSkillTemplate(
      id: 'critical_eye',
      name: '필살의 눈',
      rarity: 4,
      skillType: 'crit_boost',
      value: 30,
      cooldown: 4,
      gachaWeight: 4,
      description: '크리티컬 확률 +30% (3턴)',
    ),

    // ── 5★ Legendary ──
    EquippableSkillTemplate(
      id: 'apocalypse',
      name: '아포칼립스',
      rarity: 5,
      skillType: 'damage',
      value: 5.0,
      cooldown: 6,
      gachaWeight: 1,
      description: '적 전체에게 500% 데미지',
    ),
    EquippableSkillTemplate(
      id: 'divine_blessing',
      name: '신의 축복',
      rarity: 5,
      skillType: 'hp_regen',
      value: 40,
      cooldown: 6,
      gachaWeight: 1,
      description: '아군 전체 HP 40% 회복',
    ),
  ];

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

  static EquippableSkillTemplate? findById(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<EquippableSkillTemplate> byRarity(int rarity) =>
      all.where((t) => t.rarity == rarity).toList();
}
