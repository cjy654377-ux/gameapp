import 'package:flutter_test/flutter_test.dart';
import 'package:gameapp/domain/entities/synergy.dart';
import 'package:gameapp/domain/services/synergy_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a [MonsterInfo] with sensible defaults.
MonsterInfo _mon({
  String templateId = 'test_monster',
  String element = 'fire',
  String size = 'medium',
  int rarity = 1,
}) {
  return MonsterInfo(
    templateId: templateId,
    element: element,
    size: size,
    rarity: rarity,
  );
}

/// Fire-element resonance pair (2 fire → elementResonance active).
List<MonsterInfo> _firePair() => [
      _mon(element: 'fire'),
      _mon(element: 'fire'),
    ];

/// Three fire monsters (elementDominance active).
List<MonsterInfo> _fireTriple() => [
      _mon(element: 'fire'),
      _mon(element: 'fire'),
      _mon(element: 'fire'),
    ];

/// Four fire monsters (elementTranscendence active).
List<MonsterInfo> _fireQuad() => [
      _mon(element: 'fire'),
      _mon(element: 'fire'),
      _mon(element: 'fire'),
      _mon(element: 'fire'),
    ];

/// Team with all four sizes present (diverseForce active).
List<MonsterInfo> _allSizesTeam() => [
      _mon(size: 'small'),
      _mon(size: 'medium'),
      _mon(size: 'large'),
      _mon(size: 'extraLarge'),
    ];

/// Two small monsters (agileUnit active).
List<MonsterInfo> _twoSmall() => [
      _mon(size: 'small'),
      _mon(size: 'small'),
    ];

/// Two large monsters (giantWall active).
List<MonsterInfo> _twoLarge() => [
      _mon(size: 'large'),
      _mon(size: 'large'),
    ];

/// One large + one extraLarge (giantWall active).
List<MonsterInfo> _mixedLarge() => [
      _mon(size: 'large'),
      _mon(size: 'extraLarge'),
    ];

/// Two extraLarge monsters (giantWall active).
List<MonsterInfo> _twoExtraLarge() => [
      _mon(size: 'extraLarge'),
      _mon(size: 'extraLarge'),
    ];

/// Team with one legendary monster (legendaryAura active).
List<MonsterInfo> _oneLegendary() => [
      _mon(rarity: 5),
    ];

/// Two epic (heroicResolve active).
List<MonsterInfo> _twoEpic() => [
      _mon(rarity: 4),
      _mon(rarity: 4),
    ];

/// All rare-or-above (eliteSquad active).
List<MonsterInfo> _allRarePlus() => [
      _mon(rarity: 3),
      _mon(rarity: 4),
      _mon(rarity: 5),
    ];

/// All five rarities present (rainbowFormation active).
List<MonsterInfo> _rainbowTeam() => [
      _mon(rarity: 1),
      _mon(rarity: 2),
      _mon(rarity: 3),
      _mon(rarity: 4),
      _mon(rarity: 5),
    ];

/// dragon_flame special combo team.
List<MonsterInfo> _dragonFlameTeam() => [
      _mon(templateId: 'fire_dragon'),
      _mon(templateId: 'flame_spirit'),
    ];

/// light_and_dark special combo team.
List<MonsterInfo> _lightAndDarkTeam() => [
      _mon(templateId: 'archangel'),
      _mon(templateId: 'dark_knight'),
    ];

/// ice_and_fire special combo team.
List<MonsterInfo> _iceAndFireTeam() => [
      _mon(templateId: 'ice_queen'),
      _mon(templateId: 'phoenix'),
    ];

/// nature_guardian special combo team.
List<MonsterInfo> _natureGuardianTeam() => [
      _mon(templateId: 'stone_golem'),
      _mon(templateId: 'goblin'),
    ];

/// moonlight_hunter special combo team.
List<MonsterInfo> _moonlightHunterTeam() => [
      _mon(templateId: 'silver_wolf'),
      _mon(templateId: 'bat'),
    ];

void main() {
  // =========================================================================
  // MonsterInfo — data class behaviour
  // =========================================================================

  group('MonsterInfo', () {
    test('stores all fields correctly', () {
      const info = MonsterInfo(
        templateId: 'fire_dragon',
        element: 'fire',
        size: 'large',
        rarity: 5,
      );
      expect(info.templateId, 'fire_dragon');
      expect(info.element, 'fire');
      expect(info.size, 'large');
      expect(info.rarity, 5);
    });

    test('is const-constructible', () {
      const a = MonsterInfo(
        templateId: 'a',
        element: 'water',
        size: 'small',
        rarity: 1,
      );
      const b = MonsterInfo(
        templateId: 'a',
        element: 'water',
        size: 'small',
        rarity: 1,
      );
      // const objects with identical values are identical at the type level;
      // at minimum both fields are readable without error.
      expect(a.templateId, b.templateId);
      expect(a.element, b.element);
    });

    test('helper _mon creates MonsterInfo with given overrides', () {
      final m = _mon(templateId: 'ice_queen', element: 'water', size: 'large', rarity: 4);
      expect(m.templateId, 'ice_queen');
      expect(m.element, 'water');
      expect(m.size, 'large');
      expect(m.rarity, 4);
    });
  });

  // =========================================================================
  // SynergyEffect — properties
  // =========================================================================

  group('SynergyEffect properties', () {
    test('elementResonance has correct metadata', () {
      final s = SynergyDefinitions.elementResonance;
      expect(s.id, 'element_resonance');
      expect(s.type, SynergyType.element);
      expect(s.statBonuses['atk'], closeTo(0.10, 0.0001));
      expect(s.statBonuses.containsKey('def'), isFalse);
    });

    test('elementDominance has correct metadata', () {
      final s = SynergyDefinitions.elementDominance;
      expect(s.id, 'element_dominance');
      expect(s.type, SynergyType.element);
      expect(s.statBonuses['atk'], closeTo(0.20, 0.0001));
      expect(s.statBonuses['def'], closeTo(0.10, 0.0001));
    });

    test('elementTranscendence has correct metadata', () {
      final s = SynergyDefinitions.elementTranscendence;
      expect(s.id, 'element_transcendence');
      expect(s.type, SynergyType.element);
      expect(s.statBonuses['atk'], closeTo(0.30, 0.0001));
      expect(s.statBonuses['def'], closeTo(0.15, 0.0001));
      expect(s.statBonuses['hp'], closeTo(0.10, 0.0001));
    });

    test('diverseForce has correct metadata', () {
      final s = SynergyDefinitions.diverseForce;
      expect(s.id, 'diverse_force');
      expect(s.type, SynergyType.size);
      expect(s.statBonuses['spd'], closeTo(0.15, 0.0001));
    });

    test('agileUnit has correct metadata', () {
      final s = SynergyDefinitions.agileUnit;
      expect(s.id, 'agile_unit');
      expect(s.type, SynergyType.size);
      expect(s.statBonuses['spd'], closeTo(0.20, 0.0001));
    });

    test('giantWall has correct metadata', () {
      final s = SynergyDefinitions.giantWall;
      expect(s.id, 'giant_wall');
      expect(s.type, SynergyType.size);
      expect(s.statBonuses['def'], closeTo(0.20, 0.0001));
      expect(s.statBonuses['hp'], closeTo(0.15, 0.0001));
    });

    test('legendaryAura has correct metadata', () {
      final s = SynergyDefinitions.legendaryAura;
      expect(s.id, 'legendary_aura');
      expect(s.type, SynergyType.rarity);
      expect(s.statBonuses['atk'], closeTo(0.05, 0.0001));
    });

    test('heroicResolve has correct metadata', () {
      final s = SynergyDefinitions.heroicResolve;
      expect(s.id, 'heroic_resolve');
      expect(s.type, SynergyType.rarity);
      expect(s.statBonuses['def'], closeTo(0.10, 0.0001));
    });

    test('eliteSquad has correct metadata', () {
      final s = SynergyDefinitions.eliteSquad;
      expect(s.id, 'elite_squad');
      expect(s.type, SynergyType.rarity);
      expect(s.statBonuses['atk'], closeTo(0.08, 0.0001));
      expect(s.statBonuses['def'], closeTo(0.08, 0.0001));
      expect(s.statBonuses['hp'], closeTo(0.08, 0.0001));
      expect(s.statBonuses['spd'], closeTo(0.08, 0.0001));
    });

    test('rainbowFormation has correct metadata', () {
      final s = SynergyDefinitions.rainbowFormation;
      expect(s.id, 'rainbow_formation');
      expect(s.type, SynergyType.rarity);
      expect(s.statBonuses['atk'], closeTo(0.12, 0.0001));
      expect(s.statBonuses['def'], closeTo(0.12, 0.0001));
      expect(s.statBonuses['hp'], closeTo(0.12, 0.0001));
      expect(s.statBonuses['spd'], closeTo(0.12, 0.0001));
    });

    test('dragonFlame has correct metadata', () {
      final s = SynergyDefinitions.dragonFlame;
      expect(s.id, 'dragon_flame');
      expect(s.type, SynergyType.special);
      expect(s.statBonuses['atk'], closeTo(0.25, 0.0001));
    });

    test('lightAndDark has correct metadata', () {
      final s = SynergyDefinitions.lightAndDark;
      expect(s.id, 'light_and_dark');
      expect(s.type, SynergyType.special);
      expect(s.statBonuses['atk'], closeTo(0.15, 0.0001));
      expect(s.statBonuses['def'], closeTo(0.15, 0.0001));
      expect(s.statBonuses['hp'], closeTo(0.15, 0.0001));
      expect(s.statBonuses['spd'], closeTo(0.15, 0.0001));
    });

    test('iceAndFire has correct metadata', () {
      final s = SynergyDefinitions.iceAndFire;
      expect(s.id, 'ice_and_fire');
      expect(s.type, SynergyType.special);
      expect(s.statBonuses['atk'], closeTo(0.20, 0.0001));
      expect(s.statBonuses['def'], closeTo(0.20, 0.0001));
    });

    test('natureGuardian has correct metadata', () {
      final s = SynergyDefinitions.natureGuardian;
      expect(s.id, 'nature_guardian');
      expect(s.type, SynergyType.special);
      expect(s.statBonuses['def'], closeTo(0.25, 0.0001));
      expect(s.statBonuses['hp'], closeTo(0.15, 0.0001));
    });

    test('moonlightHunter has correct metadata', () {
      final s = SynergyDefinitions.moonlightHunter;
      expect(s.id, 'moonlight_hunter');
      expect(s.type, SynergyType.special);
      expect(s.statBonuses['spd'], closeTo(0.25, 0.0001));
      expect(s.statBonuses['atk'], closeTo(0.10, 0.0001));
    });
  });

  // =========================================================================
  // getAllSynergies
  // =========================================================================

  group('getAllSynergies', () {
    test('returns the full catalogue (15 synergies)', () {
      expect(SynergyService.getAllSynergies().length, 15);
    });

    test('list is in display order: element → size → rarity → special', () {
      final all = SynergyService.getAllSynergies();
      final types = all.map((s) => s.type).toList();
      // Element synergies come first.
      expect(types[0], SynergyType.element);
      expect(types[1], SynergyType.element);
      expect(types[2], SynergyType.element);
      // Size synergies follow.
      expect(types[3], SynergyType.size);
      expect(types[4], SynergyType.size);
      expect(types[5], SynergyType.size);
      // Rarity synergies next.
      expect(types[6], SynergyType.rarity);
      expect(types[7], SynergyType.rarity);
      expect(types[8], SynergyType.rarity);
      expect(types[9], SynergyType.rarity);
      // Special combos last.
      expect(types[10], SynergyType.special);
      expect(types[11], SynergyType.special);
      expect(types[12], SynergyType.special);
      expect(types[13], SynergyType.special);
      expect(types[14], SynergyType.special);
    });

    test('all synergy ids are unique', () {
      final ids = SynergyService.getAllSynergies().map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  // =========================================================================
  // getSynergiesByType
  // =========================================================================

  group('getSynergiesByType', () {
    test('returns only element synergies', () {
      final result = SynergyService.getSynergiesByType(SynergyType.element);
      expect(result.length, 3);
      expect(result.every((s) => s.type == SynergyType.element), isTrue);
    });

    test('returns only size synergies', () {
      final result = SynergyService.getSynergiesByType(SynergyType.size);
      expect(result.length, 3);
      expect(result.every((s) => s.type == SynergyType.size), isTrue);
    });

    test('returns only rarity synergies', () {
      final result = SynergyService.getSynergiesByType(SynergyType.rarity);
      expect(result.length, 4);
      expect(result.every((s) => s.type == SynergyType.rarity), isTrue);
    });

    test('returns only special synergies', () {
      final result = SynergyService.getSynergiesByType(SynergyType.special);
      expect(result.length, 5);
      expect(result.every((s) => s.type == SynergyType.special), isTrue);
    });
  });

  // =========================================================================
  // getActiveSynergies — edge cases
  // =========================================================================

  group('getActiveSynergies — edge cases', () {
    test('empty team returns empty list', () {
      expect(SynergyService.getActiveSynergies([]), isEmpty);
    });

    test('single monster with no matching synergy returns empty list', () {
      final team = [_mon(element: 'fire', size: 'medium', rarity: 1)];
      final active = SynergyService.getActiveSynergies(team);
      // No synergy needs only 1 random monster.
      expect(active, isEmpty);
    });

    test('two monsters with different elements trigger no element synergy', () {
      final team = [
        _mon(element: 'fire'),
        _mon(element: 'water'),
      ];
      final active = SynergyService.getActiveSynergies(team);
      expect(active.any((s) => s.type == SynergyType.element), isFalse);
    });

    test('duplicate templateIds do NOT block synergy evaluation', () {
      // Two identical templateIds still count as 2 fire monsters.
      final team = [
        _mon(templateId: 'fire_a', element: 'fire'),
        _mon(templateId: 'fire_a', element: 'fire'),
      ];
      final active = SynergyService.getActiveSynergies(team);
      expect(active.any((s) => s.id == 'element_resonance'), isTrue);
    });
  });

  // =========================================================================
  // getActiveSynergies — element synergies
  // =========================================================================

  group('getActiveSynergies — element synergies', () {
    test('two same-element monsters activate elementResonance', () {
      final active = SynergyService.getActiveSynergies(_firePair());
      expect(active.any((s) => s.id == 'element_resonance'), isTrue);
    });

    test('two same-element monsters do NOT activate elementDominance', () {
      final active = SynergyService.getActiveSynergies(_firePair());
      expect(active.any((s) => s.id == 'element_dominance'), isFalse);
    });

    test('three same-element monsters activate both resonance and dominance', () {
      final active = SynergyService.getActiveSynergies(_fireTriple());
      final ids = active.map((s) => s.id).toList();
      expect(ids, contains('element_resonance'));
      expect(ids, contains('element_dominance'));
    });

    test('three same-element monsters do NOT activate elementTranscendence', () {
      final active = SynergyService.getActiveSynergies(_fireTriple());
      expect(active.any((s) => s.id == 'element_transcendence'), isFalse);
    });

    test('four same-element monsters activate resonance, dominance, and transcendence', () {
      final active = SynergyService.getActiveSynergies(_fireQuad());
      final ids = active.map((s) => s.id).toList();
      expect(ids, contains('element_resonance'));
      expect(ids, contains('element_dominance'));
      expect(ids, contains('element_transcendence'));
    });

    test('water pair activates elementResonance (element-agnostic)', () {
      final team = [_mon(element: 'water'), _mon(element: 'water')];
      final active = SynergyService.getActiveSynergies(team);
      expect(active.any((s) => s.id == 'element_resonance'), isTrue);
    });

    test('mixed 3-fire + 1-water: fire triple synergies activate', () {
      final team = [
        _mon(element: 'fire'),
        _mon(element: 'fire'),
        _mon(element: 'fire'),
        _mon(element: 'water'),
      ];
      final active = SynergyService.getActiveSynergies(team);
      final ids = active.map((s) => s.id).toList();
      expect(ids, contains('element_resonance'));
      expect(ids, contains('element_dominance'));
      // transcendence requires 4 of same element — not met.
      expect(ids, isNot(contains('element_transcendence')));
    });

    test('all different elements trigger no element synergy', () {
      final team = [
        _mon(element: 'fire'),
        _mon(element: 'water'),
        _mon(element: 'earth'),
        _mon(element: 'wind'),
      ];
      final active = SynergyService.getActiveSynergies(team);
      expect(active.any((s) => s.type == SynergyType.element), isFalse);
    });
  });

  // =========================================================================
  // getActiveSynergies — size synergies
  // =========================================================================

  group('getActiveSynergies — size synergies', () {
    test('all four sizes present activates diverseForce', () {
      final active = SynergyService.getActiveSynergies(_allSizesTeam());
      expect(active.any((s) => s.id == 'diverse_force'), isTrue);
    });

    test('only three sizes present does NOT activate diverseForce', () {
      final team = [
        _mon(size: 'small'),
        _mon(size: 'medium'),
        _mon(size: 'large'),
      ];
      final active = SynergyService.getActiveSynergies(team);
      expect(active.any((s) => s.id == 'diverse_force'), isFalse);
    });

    test('two small monsters activate agileUnit', () {
      final active = SynergyService.getActiveSynergies(_twoSmall());
      expect(active.any((s) => s.id == 'agile_unit'), isTrue);
    });

    test('one small monster does NOT activate agileUnit', () {
      final team = [_mon(size: 'small')];
      final active = SynergyService.getActiveSynergies(team);
      expect(active.any((s) => s.id == 'agile_unit'), isFalse);
    });

    test('two large monsters activate giantWall', () {
      final active = SynergyService.getActiveSynergies(_twoLarge());
      expect(active.any((s) => s.id == 'giant_wall'), isTrue);
    });

    test('one large + one extraLarge activates giantWall', () {
      final active = SynergyService.getActiveSynergies(_mixedLarge());
      expect(active.any((s) => s.id == 'giant_wall'), isTrue);
    });

    test('two extraLarge monsters activate giantWall', () {
      final active = SynergyService.getActiveSynergies(_twoExtraLarge());
      expect(active.any((s) => s.id == 'giant_wall'), isTrue);
    });

    test('one large monster does NOT activate giantWall', () {
      final team = [_mon(size: 'large')];
      final active = SynergyService.getActiveSynergies(team);
      expect(active.any((s) => s.id == 'giant_wall'), isFalse);
    });

    test('medium monsters do not count toward giantWall', () {
      final team = [_mon(size: 'medium'), _mon(size: 'medium')];
      final active = SynergyService.getActiveSynergies(team);
      expect(active.any((s) => s.id == 'giant_wall'), isFalse);
    });
  });

  // =========================================================================
  // getActiveSynergies — rarity synergies
  // =========================================================================

  group('getActiveSynergies — rarity synergies', () {
    test('one legendary activates legendaryAura', () {
      final active = SynergyService.getActiveSynergies(_oneLegendary());
      expect(active.any((s) => s.id == 'legendary_aura'), isTrue);
    });

    test('no legendary does NOT activate legendaryAura', () {
      final team = [_mon(rarity: 4), _mon(rarity: 3)];
      final active = SynergyService.getActiveSynergies(team);
      expect(active.any((s) => s.id == 'legendary_aura'), isFalse);
    });

    test('two epic monsters activate heroicResolve', () {
      final active = SynergyService.getActiveSynergies(_twoEpic());
      expect(active.any((s) => s.id == 'heroic_resolve'), isTrue);
    });

    test('one epic does NOT activate heroicResolve', () {
      final team = [_mon(rarity: 4)];
      final active = SynergyService.getActiveSynergies(team);
      expect(active.any((s) => s.id == 'heroic_resolve'), isFalse);
    });

    test('all rare+ activates eliteSquad', () {
      final active = SynergyService.getActiveSynergies(_allRarePlus());
      expect(active.any((s) => s.id == 'elite_squad'), isTrue);
    });

    test('team with one common does NOT activate eliteSquad', () {
      final team = [_mon(rarity: 1), _mon(rarity: 3), _mon(rarity: 5)];
      final active = SynergyService.getActiveSynergies(team);
      expect(active.any((s) => s.id == 'elite_squad'), isFalse);
    });

    test('team with one uncommon does NOT activate eliteSquad', () {
      final team = [_mon(rarity: 2), _mon(rarity: 3), _mon(rarity: 4)];
      final active = SynergyService.getActiveSynergies(team);
      expect(active.any((s) => s.id == 'elite_squad'), isFalse);
    });

    test('all five rarities present activates rainbowFormation', () {
      final active = SynergyService.getActiveSynergies(_rainbowTeam());
      expect(active.any((s) => s.id == 'rainbow_formation'), isTrue);
    });

    test('only four distinct rarities do NOT activate rainbowFormation', () {
      final team = [
        _mon(rarity: 1),
        _mon(rarity: 2),
        _mon(rarity: 3),
        _mon(rarity: 4),
      ];
      final active = SynergyService.getActiveSynergies(team);
      expect(active.any((s) => s.id == 'rainbow_formation'), isFalse);
    });
  });

  // =========================================================================
  // getActiveSynergies — special combo synergies
  // =========================================================================

  group('getActiveSynergies — special synergies', () {
    test('fire_dragon + flame_spirit activates dragonFlame', () {
      final active = SynergyService.getActiveSynergies(_dragonFlameTeam());
      expect(active.any((s) => s.id == 'dragon_flame'), isTrue);
    });

    test('fire_dragon alone does NOT activate dragonFlame', () {
      final team = [_mon(templateId: 'fire_dragon')];
      final active = SynergyService.getActiveSynergies(team);
      expect(active.any((s) => s.id == 'dragon_flame'), isFalse);
    });

    test('archangel + dark_knight activates lightAndDark', () {
      final active = SynergyService.getActiveSynergies(_lightAndDarkTeam());
      expect(active.any((s) => s.id == 'light_and_dark'), isTrue);
    });

    test('archangel alone does NOT activate lightAndDark', () {
      final team = [_mon(templateId: 'archangel')];
      final active = SynergyService.getActiveSynergies(team);
      expect(active.any((s) => s.id == 'light_and_dark'), isFalse);
    });

    test('ice_queen + phoenix activates iceAndFire', () {
      final active = SynergyService.getActiveSynergies(_iceAndFireTeam());
      expect(active.any((s) => s.id == 'ice_and_fire'), isTrue);
    });

    test('stone_golem + goblin activates natureGuardian', () {
      final active = SynergyService.getActiveSynergies(_natureGuardianTeam());
      expect(active.any((s) => s.id == 'nature_guardian'), isTrue);
    });

    test('silver_wolf + bat activates moonlightHunter', () {
      final active = SynergyService.getActiveSynergies(_moonlightHunterTeam());
      expect(active.any((s) => s.id == 'moonlight_hunter'), isTrue);
    });

    test('silver_wolf without bat does NOT activate moonlightHunter', () {
      final team = [_mon(templateId: 'silver_wolf')];
      final active = SynergyService.getActiveSynergies(team);
      expect(active.any((s) => s.id == 'moonlight_hunter'), isFalse);
    });

    test('extra monsters in team still allow special combo', () {
      final team = [
        _mon(templateId: 'fire_dragon'),
        _mon(templateId: 'flame_spirit'),
        _mon(templateId: 'unrelated'),
      ];
      final active = SynergyService.getActiveSynergies(team);
      expect(active.any((s) => s.id == 'dragon_flame'), isTrue);
    });
  });

  // =========================================================================
  // getActiveSynergies — stacking / multiple simultaneous synergies
  // =========================================================================

  group('getActiveSynergies — synergy stacking', () {
    test('element + size synergies both active simultaneously', () {
      // Fire pair (element_resonance) + two small (agile_unit).
      final team = [
        _mon(element: 'fire', size: 'small'),
        _mon(element: 'fire', size: 'small'),
      ];
      final active = SynergyService.getActiveSynergies(team);
      final ids = active.map((s) => s.id).toList();
      expect(ids, contains('element_resonance'));
      expect(ids, contains('agile_unit'));
    });

    test('element + rarity synergies both active simultaneously', () {
      // Fire pair + one legendary.
      final team = [
        _mon(element: 'fire', rarity: 5),
        _mon(element: 'fire', rarity: 3),
      ];
      final active = SynergyService.getActiveSynergies(team);
      final ids = active.map((s) => s.id).toList();
      expect(ids, contains('element_resonance'));
      expect(ids, contains('legendary_aura'));
    });

    test('special + element synergies both active simultaneously', () {
      // dragon_flame combo where both monsters happen to share fire element.
      final team = [
        _mon(templateId: 'fire_dragon', element: 'fire'),
        _mon(templateId: 'flame_spirit', element: 'fire'),
      ];
      final active = SynergyService.getActiveSynergies(team);
      final ids = active.map((s) => s.id).toList();
      expect(ids, contains('dragon_flame'));
      expect(ids, contains('element_resonance'));
    });

    test('large team can trigger many synergies at once', () {
      // Five-monster team designed to trigger as many synergies as possible:
      // - 3 fire → resonance + dominance
      // - 2 epic → heroicResolve
      // - rarity 3+ on all → eliteSquad
      final team = [
        _mon(element: 'fire', size: 'medium', rarity: 3),
        _mon(element: 'fire', size: 'medium', rarity: 4),
        _mon(element: 'fire', size: 'medium', rarity: 4),
      ];
      final active = SynergyService.getActiveSynergies(team);
      final ids = active.map((s) => s.id).toList();
      expect(ids, contains('element_resonance'));
      expect(ids, contains('element_dominance'));
      expect(ids, contains('heroic_resolve'));
      expect(ids, contains('elite_squad'));
    });

    test('rainbow team does not accidentally trigger rainbowFormation with only 4 rarities', () {
      final team = [
        _mon(rarity: 1),
        _mon(rarity: 2),
        _mon(rarity: 3),
        _mon(rarity: 5),
      ];
      final active = SynergyService.getActiveSynergies(team);
      // rarity 4 is missing → no rainbow.
      expect(active.any((s) => s.id == 'rainbow_formation'), isFalse);
    });
  });

  // =========================================================================
  // getTotalBonuses — correctness
  // =========================================================================

  group('getTotalBonuses', () {
    test('empty team returns empty map', () {
      expect(SynergyService.getTotalBonuses([]), isEmpty);
    });

    test('team with no active synergies returns empty map', () {
      final team = [_mon(element: 'fire', size: 'medium', rarity: 1)];
      expect(SynergyService.getTotalBonuses(team), isEmpty);
    });

    test('elementResonance only: atk +0.10', () {
      final bonuses = SynergyService.getTotalBonuses(_firePair());
      expect(bonuses['atk'], closeTo(0.10, 0.0001));
      expect(bonuses.containsKey('def'), isFalse);
      expect(bonuses.containsKey('hp'), isFalse);
      expect(bonuses.containsKey('spd'), isFalse);
    });

    test('elementDominance + elementResonance: atk accumulated correctly', () {
      // Three fire → resonance (atk+0.10) + dominance (atk+0.20, def+0.10)
      // Expected totals: atk = 0.30, def = 0.10
      final bonuses = SynergyService.getTotalBonuses(_fireTriple());
      expect(bonuses['atk'], closeTo(0.30, 0.0001));
      expect(bonuses['def'], closeTo(0.10, 0.0001));
    });

    test('all three element synergies stack: atk = 0.60, def = 0.25, hp = 0.10', () {
      // Four fire → resonance (atk+0.10) + dominance (atk+0.20, def+0.10)
      //           + transcendence (atk+0.30, def+0.15, hp+0.10)
      // Totals: atk=0.60, def=0.25, hp=0.10
      final bonuses = SynergyService.getTotalBonuses(_fireQuad());
      expect(bonuses['atk'], closeTo(0.60, 0.0001));
      expect(bonuses['def'], closeTo(0.25, 0.0001));
      expect(bonuses['hp'], closeTo(0.10, 0.0001));
    });

    test('agileUnit: spd at least +0.20', () {
      // _twoSmall has default rarity=1 and default element so no other size or
      // rarity synergy fires, but element_resonance may if elements match.
      // We only assert spd is present and at least the agileUnit contribution.
      final bonuses = SynergyService.getTotalBonuses(_twoSmall());
      expect(bonuses['spd'], greaterThanOrEqualTo(0.20));
    });

    test('giantWall only: def +0.20, hp +0.15', () {
      final bonuses = SynergyService.getTotalBonuses(_twoLarge());
      expect(bonuses['def'], closeTo(0.20, 0.0001));
      expect(bonuses['hp'], closeTo(0.15, 0.0001));
    });

    test('diverseForce only: spd +0.15', () {
      final bonuses = SynergyService.getTotalBonuses(_allSizesTeam());
      expect(bonuses['spd'], closeTo(0.15, 0.0001));
    });

    test('legendaryAura: atk at least +0.05 (eliteSquad also fires for all-rare+ team)', () {
      // A single legendary triggers both legendaryAura (atk+0.05) and
      // eliteSquad because every member is rarity >= 3 (atk+0.08).
      final bonuses = SynergyService.getTotalBonuses(_oneLegendary());
      expect(bonuses['atk'], greaterThanOrEqualTo(0.05));
    });

    test('legendaryAura: atk isolated — common+legendary with distinct elements prevents extra synergies', () {
      // Different elements (no element_resonance), rarity 1 prevents eliteSquad.
      // Only legendaryAura fires → atk+0.05.
      final team = [
        _mon(element: 'fire', rarity: 1),
        _mon(element: 'water', rarity: 5),
      ];
      final bonuses = SynergyService.getTotalBonuses(team);
      expect(bonuses['atk'], closeTo(0.05, 0.0001));
      expect(bonuses.containsKey('def'), isFalse);
    });

    test('heroicResolve: def at least +0.10 (eliteSquad also fires for all-epic team)', () {
      // Two epics also satisfy eliteSquad (all members rarity >= 3),
      // so def total is at least heroicResolve 0.10.
      final bonuses = SynergyService.getTotalBonuses(_twoEpic());
      expect(bonuses['def'], greaterThanOrEqualTo(0.10));
    });

    test('heroicResolve: def isolated — common+two epics with distinct elements', () {
      // Three distinct elements (no element_resonance), rarity 1 prevents eliteSquad.
      // Only heroicResolve fires → def+0.10.
      final team = [
        _mon(element: 'fire', rarity: 1),
        _mon(element: 'water', rarity: 4),
        _mon(element: 'earth', rarity: 4),
      ];
      final bonuses = SynergyService.getTotalBonuses(team);
      expect(bonuses['def'], closeTo(0.10, 0.0001));
    });

    test('eliteSquad gives all four stats +0.08', () {
      // Need all-rare-plus team that triggers no other synergy.
      final team = [
        _mon(element: 'fire', size: 'medium', rarity: 3),
        _mon(element: 'water', size: 'large', rarity: 4),
        _mon(element: 'earth', size: 'small', rarity: 5),
      ];
      final bonuses = SynergyService.getTotalBonuses(team);
      // legendaryAura also triggers (rarity 5 present).
      expect(bonuses['atk'], closeTo(0.08 + 0.05, 0.0001));
      expect(bonuses['def'], closeTo(0.08, 0.0001));
      expect(bonuses['hp'], closeTo(0.08, 0.0001));
      expect(bonuses['spd'], closeTo(0.08, 0.0001));
    });

    test('rainbowFormation: all four stats +0.12', () {
      // Rainbow team: rarities 1-5.  Also triggers legendaryAura + eliteSquad.
      // Let's use pure rainbow team and just check rainbow values stack.
      final bonuses = SynergyService.getTotalBonuses(_rainbowTeam());
      // At minimum rainbow contributes 0.12 to each stat.
      expect(bonuses['atk'], greaterThanOrEqualTo(0.12));
      expect(bonuses['def'], greaterThanOrEqualTo(0.12));
      expect(bonuses['hp'], greaterThanOrEqualTo(0.12));
      expect(bonuses['spd'], greaterThanOrEqualTo(0.12));
    });

    test('dragonFlame only: atk +0.25', () {
      final bonuses = SynergyService.getTotalBonuses(_dragonFlameTeam());
      expect(bonuses['atk'], greaterThanOrEqualTo(0.25));
    });

    test('lightAndDark: all four stats +0.15', () {
      final bonuses = SynergyService.getTotalBonuses(_lightAndDarkTeam());
      expect(bonuses['atk'], greaterThanOrEqualTo(0.15));
      expect(bonuses['def'], greaterThanOrEqualTo(0.15));
      expect(bonuses['hp'], greaterThanOrEqualTo(0.15));
      expect(bonuses['spd'], greaterThanOrEqualTo(0.15));
    });

    test('stacked synergies accumulate additively across stats', () {
      // Two fire + two small:
      // elementResonance → atk+0.10
      // agileUnit → spd+0.20
      final team = [
        _mon(element: 'fire', size: 'small'),
        _mon(element: 'fire', size: 'small'),
      ];
      final bonuses = SynergyService.getTotalBonuses(team);
      expect(bonuses['atk'], closeTo(0.10, 0.0001));
      expect(bonuses['spd'], closeTo(0.20, 0.0001));
    });

    test('stat keys in bonuses only contain recognised stat names', () {
      final bonuses = SynergyService.getTotalBonuses(_rainbowTeam());
      for (final key in bonuses.keys) {
        expect(['atk', 'def', 'hp', 'spd'], contains(key));
      }
    });

    test('all bonus values are positive', () {
      final bonuses = SynergyService.getTotalBonuses(_rainbowTeam());
      for (final value in bonuses.values) {
        expect(value, greaterThan(0.0));
      }
    });
  });

  // =========================================================================
  // hasActiveSynergyOfType
  // =========================================================================

  group('hasActiveSynergyOfType', () {
    test('returns true when matching type is active', () {
      expect(
        SynergyService.hasActiveSynergyOfType(_firePair(), SynergyType.element),
        isTrue,
      );
    });

    test('returns false when matching type is not active', () {
      expect(
        SynergyService.hasActiveSynergyOfType(_firePair(), SynergyType.size),
        isFalse,
      );
    });

    test('returns false for empty team', () {
      expect(
        SynergyService.hasActiveSynergyOfType([], SynergyType.element),
        isFalse,
      );
    });

    test('correctly identifies special type', () {
      expect(
        SynergyService.hasActiveSynergyOfType(
            _dragonFlameTeam(), SynergyType.special),
        isTrue,
      );
    });

    test('correctly identifies rarity type', () {
      expect(
        SynergyService.hasActiveSynergyOfType(
            _oneLegendary(), SynergyType.rarity),
        isTrue,
      );
    });
  });

  // =========================================================================
  // debugSummary
  // =========================================================================

  group('debugSummary', () {
    test('returns fallback string for empty team', () {
      expect(SynergyService.debugSummary([]), '활성 시너지 없음');
    });

    test('returns fallback string when no synergy is active', () {
      final team = [_mon(element: 'fire', rarity: 1)];
      expect(SynergyService.debugSummary(team), '활성 시너지 없음');
    });

    test('output includes synergy id', () {
      final summary = SynergyService.debugSummary(_firePair());
      expect(summary, contains('element_resonance'));
    });

    test('output includes synergy name', () {
      final summary = SynergyService.debugSummary(_firePair());
      expect(summary, contains('속성 공명'));
    });

    test('output includes stat bonus with percent sign', () {
      final summary = SynergyService.debugSummary(_firePair());
      // elementResonance grants atk+10%
      expect(summary, contains('%'));
      expect(summary, contains('atk'));
    });

    test('output does not end with a trailing newline', () {
      final summary = SynergyService.debugSummary(_firePair());
      expect(summary.endsWith('\n'), isFalse);
    });

    test('multiple active synergies are each represented on separate lines', () {
      // Fire triple → resonance + dominance (2 synergies).
      final summary = SynergyService.debugSummary(_fireTriple());
      expect(summary, contains('element_resonance'));
      expect(summary, contains('element_dominance'));
    });
  });
}
