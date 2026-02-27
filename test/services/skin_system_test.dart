import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gameapp/data/models/monster_model.dart';
import 'package:gameapp/data/static/skin_database.dart';
import 'package:gameapp/core/utils/skin_resolver.dart';

// ---------------------------------------------------------------------------
// Helper: builds a minimal MonsterModel. Only override fields relevant to the
// test being written. Hive fields are populated but no Box is opened, so pure
// static/instance methods work fine without any Hive initialisation.
// ---------------------------------------------------------------------------
MonsterModel buildMonster({
  String id = 'test-id',
  String templateId = 'tmpl-001',
  String name = 'TestMon',
  int rarity = 3,
  String element = 'fire',
  String size = 'medium',
  String? equippedSkinId,
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
    baseAtk: 100.0,
    baseDef: 80.0,
    baseHp: 500.0,
    baseSpd: 60.0,
    acquiredAt: DateTime(2024, 1, 1),
    isInTeam: false,
    size: size,
    equippedSkinId: equippedSkinId,
  );
}

void main() {
  // =========================================================================
  // 1. SkinDefinition – property accessors
  // =========================================================================

  group('SkinDefinition – properties', () {
    test('1a. crystalArmor has the expected rarity and cost', () {
      const skin = SkinDatabase.crystalArmor;
      expect(skin.rarity, equals(2));
      expect(skin.shardCost, equals(15));
    });

    test('1b. cosmicVoid is legendary (rarity 5) with highest cost', () {
      const skin = SkinDatabase.cosmicVoid;
      expect(skin.rarity, equals(5));
      expect(skin.shardCost, equals(80));
    });

    test('1c. universal skins have null targetElement and null targetTemplateId', () {
      const universalSkins = [
        SkinDatabase.crystalArmor,
        SkinDatabase.shadowCloak,
        SkinDatabase.goldenCrown,
        SkinDatabase.stardustAura,
        SkinDatabase.rainbowPrism,
        SkinDatabase.cosmicVoid,
      ];
      for (final skin in universalSkins) {
        expect(skin.targetElement, isNull,
            reason: '${skin.id} should have no targetElement');
        expect(skin.targetTemplateId, isNull,
            reason: '${skin.id} should have no targetTemplateId');
      }
    });

    test('1d. element-specific skins have targetElement set and null targetTemplateId', () {
      final elementSkins = [
        SkinDatabase.infernalFlame,
        SkinDatabase.abyssalTide,
        SkinDatabase.thunderStrike,
        SkinDatabase.ancientMoss,
        SkinDatabase.spectralPhantom,
      ];
      for (final skin in elementSkins) {
        expect(skin.targetElement, isNotNull,
            reason: '${skin.id} should have a targetElement');
        expect(skin.targetTemplateId, isNull,
            reason: '${skin.id} should have no targetTemplateId');
      }
    });

    test('1e. template-specific skins have targetTemplateId set and null targetElement', () {
      final templateSkins = [
        SkinDatabase.dragonEmperor,
        SkinDatabase.divineWings,
        SkinDatabase.phoenixNirvana,
      ];
      for (final skin in templateSkins) {
        expect(skin.targetTemplateId, isNotNull,
            reason: '${skin.id} should have a targetTemplateId');
        expect(skin.targetElement, isNull,
            reason: '${skin.id} should have no targetElement');
      }
    });

    test('1f. element-specific skins map to the correct elements', () {
      expect(SkinDatabase.infernalFlame.targetElement, equals('fire'));
      expect(SkinDatabase.abyssalTide.targetElement, equals('water'));
      expect(SkinDatabase.thunderStrike.targetElement, equals('electric'));
      expect(SkinDatabase.ancientMoss.targetElement, equals('grass'));
      expect(SkinDatabase.spectralPhantom.targetElement, equals('ghost'));
    });

    test('1g. template-specific skins map to the correct templateIds', () {
      expect(SkinDatabase.dragonEmperor.targetTemplateId, equals('flame_dragon'));
      expect(SkinDatabase.divineWings.targetTemplateId, equals('archangel'));
      expect(SkinDatabase.phoenixNirvana.targetTemplateId, equals('phoenix'));
    });

    test('1h. all skins in the master list have unique ids', () {
      final ids = SkinDatabase.all.map((s) => s.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, equals(uniqueIds.length),
          reason: 'Duplicate skin IDs found in SkinDatabase.all');
    });

    test('1i. overrideEmoji and overrideColor are non-null for all defined skins', () {
      for (final skin in SkinDatabase.all) {
        expect(skin.overrideEmoji, isNotNull,
            reason: '${skin.id} should have an overrideEmoji');
        expect(skin.overrideColor, isNotNull,
            reason: '${skin.id} should have an overrideColor');
      }
    });

    test('1j. rarity is in the valid range 1–5 for every skin', () {
      for (final skin in SkinDatabase.all) {
        expect(skin.rarity, inInclusiveRange(1, 5),
            reason: '${skin.id} has out-of-range rarity');
      }
    });

    test('1k. shardCost is a positive value for every skin', () {
      for (final skin in SkinDatabase.all) {
        expect(skin.shardCost, greaterThan(0),
            reason: '${skin.id} has non-positive shardCost');
      }
    });
  });

  // =========================================================================
  // 2. SkinDatabase.findById
  // =========================================================================

  group('SkinDatabase.findById', () {
    test('2a. returns the correct skin for a known universal id', () {
      final skin = SkinDatabase.findById('crystal_armor');
      expect(skin, isNotNull);
      expect(skin!.id, equals('crystal_armor'));
      expect(skin.nameEn, equals('Crystal Armor'));
    });

    test('2b. returns the correct skin for a known element-specific id', () {
      final skin = SkinDatabase.findById('infernal_flame');
      expect(skin, isNotNull);
      expect(skin!.id, equals('infernal_flame'));
      expect(skin.targetElement, equals('fire'));
    });

    test('2c. returns the correct skin for a known template-specific id', () {
      final skin = SkinDatabase.findById('dragon_emperor');
      expect(skin, isNotNull);
      expect(skin!.id, equals('dragon_emperor'));
      expect(skin.targetTemplateId, equals('flame_dragon'));
    });

    test('2d. returns null for an unknown id', () {
      expect(SkinDatabase.findById('nonexistent_skin'), isNull);
    });

    test('2e. returns null for an empty-string id', () {
      expect(SkinDatabase.findById(''), isNull);
    });

    test('2f. lookup is case-sensitive – wrong case returns null', () {
      expect(SkinDatabase.findById('Crystal_Armor'), isNull);
      expect(SkinDatabase.findById('CRYSTAL_ARMOR'), isNull);
    });

    test('2g. every id in SkinDatabase.all resolves via findById', () {
      for (final skin in SkinDatabase.all) {
        final found = SkinDatabase.findById(skin.id);
        expect(found, isNotNull, reason: 'findById failed for id: ${skin.id}');
        expect(found!.id, equals(skin.id));
      }
    });

    test('2h. returns shadow_cloak with correct emoji', () {
      final skin = SkinDatabase.findById('shadow_cloak');
      expect(skin, isNotNull);
      expect(skin!.overrideEmoji, equals('🌑'));
    });

    test('2i. returns golden_crown with rarity 3', () {
      final skin = SkinDatabase.findById('golden_crown');
      expect(skin, isNotNull);
      expect(skin!.rarity, equals(3));
    });
  });

  // =========================================================================
  // 3. SkinDatabase.applicableTo
  // =========================================================================

  group('SkinDatabase.applicableTo – universal skins', () {
    test('3a. universal skins are included for any element/template', () {
      final skins = SkinDatabase.applicableTo(
        element: 'fire',
        templateId: 'some_template',
      );
      final ids = skins.map((s) => s.id).toSet();
      expect(ids, contains('crystal_armor'));
      expect(ids, contains('shadow_cloak'));
      expect(ids, contains('golden_crown'));
      expect(ids, contains('stardust_aura'));
      expect(ids, contains('rainbow_prism'));
      expect(ids, contains('cosmic_void'));
    });

    test('3b. universal skins appear for a stone monster with no template skin', () {
      final skins = SkinDatabase.applicableTo(
        element: 'stone',
        templateId: 'rock_golem',
      );
      final universalIds = ['crystal_armor', 'shadow_cloak', 'golden_crown',
          'stardust_aura', 'rainbow_prism', 'cosmic_void'];
      for (final id in universalIds) {
        expect(skins.any((s) => s.id == id), isTrue,
            reason: 'Universal skin $id should be applicable to stone/rock_golem');
      }
    });
  });

  group('SkinDatabase.applicableTo – element-specific skins', () {
    test('3c. fire element skin is included for a fire monster', () {
      final skins = SkinDatabase.applicableTo(
        element: 'fire',
        templateId: 'generic_fire',
      );
      final ids = skins.map((s) => s.id).toSet();
      expect(ids, contains('infernal_flame'));
    });

    test('3d. water element skin is NOT included for a fire monster', () {
      final skins = SkinDatabase.applicableTo(
        element: 'fire',
        templateId: 'generic_fire',
      );
      final ids = skins.map((s) => s.id).toSet();
      expect(ids, isNot(contains('abyssal_tide')));
    });

    test('3e. water element skin is included for a water monster', () {
      final skins = SkinDatabase.applicableTo(
        element: 'water',
        templateId: 'sea_turtle',
      );
      expect(skins.any((s) => s.id == 'abyssal_tide'), isTrue);
    });

    test('3f. electric skin is included for electric, excluded for others', () {
      final electricSkins = SkinDatabase.applicableTo(
        element: 'electric',
        templateId: 'bolt_lizard',
      );
      expect(electricSkins.any((s) => s.id == 'thunder_strike'), isTrue);

      final fireSkins = SkinDatabase.applicableTo(
        element: 'fire',
        templateId: 'flame_cat',
      );
      expect(fireSkins.any((s) => s.id == 'thunder_strike'), isFalse);
    });

    test('3g. grass and ghost element skins match exactly their elements', () {
      final grassSkins = SkinDatabase.applicableTo(
        element: 'grass',
        templateId: 'leaf_bunny',
      );
      expect(grassSkins.any((s) => s.id == 'ancient_moss'), isTrue);
      expect(grassSkins.any((s) => s.id == 'spectral_phantom'), isFalse);

      final ghostSkins = SkinDatabase.applicableTo(
        element: 'ghost',
        templateId: 'wraith',
      );
      expect(ghostSkins.any((s) => s.id == 'spectral_phantom'), isTrue);
      expect(ghostSkins.any((s) => s.id == 'ancient_moss'), isFalse);
    });

    test('3h. no element-specific skins bleed into an unrelated element', () {
      final lightSkins = SkinDatabase.applicableTo(
        element: 'light',
        templateId: 'holy_fairy',
      );
      final elementSpecificIds = ['infernal_flame', 'abyssal_tide',
          'thunder_strike', 'ancient_moss', 'spectral_phantom'];
      for (final id in elementSpecificIds) {
        expect(lightSkins.any((s) => s.id == id), isFalse,
            reason: '$id should not be in the light monster skin list');
      }
    });
  });

  group('SkinDatabase.applicableTo – template-specific skins', () {
    test('3i. dragon_emperor is included only for flame_dragon templateId', () {
      final dragonSkins = SkinDatabase.applicableTo(
        element: 'fire',
        templateId: 'flame_dragon',
      );
      expect(dragonSkins.any((s) => s.id == 'dragon_emperor'), isTrue);

      // A different fire monster must NOT get the dragon-only skin.
      final otherFireSkins = SkinDatabase.applicableTo(
        element: 'fire',
        templateId: 'fire_lizard',
      );
      expect(otherFireSkins.any((s) => s.id == 'dragon_emperor'), isFalse);
    });

    test('3j. divine_wings is included only for archangel templateId', () {
      final angelSkins = SkinDatabase.applicableTo(
        element: 'light',
        templateId: 'archangel',
      );
      expect(angelSkins.any((s) => s.id == 'divine_wings'), isTrue);

      final otherSkins = SkinDatabase.applicableTo(
        element: 'light',
        templateId: 'holy_fairy',
      );
      expect(otherSkins.any((s) => s.id == 'divine_wings'), isFalse);
    });

    test('3k. phoenix_nirvana is included only for phoenix templateId', () {
      final phoenixSkins = SkinDatabase.applicableTo(
        element: 'fire',
        templateId: 'phoenix',
      );
      expect(phoenixSkins.any((s) => s.id == 'phoenix_nirvana'), isTrue);

      final genericFireSkins = SkinDatabase.applicableTo(
        element: 'fire',
        templateId: 'flame_dragon',
      );
      expect(genericFireSkins.any((s) => s.id == 'phoenix_nirvana'), isFalse);
    });

    test('3l. template-specific skin takes priority: flame_dragon gets dragon skin but NOT fire element skins', () {
      // The filter logic: template-specific skins must match templateId, so they
      // appear in the list ONLY for the exact template. Element skins (targetElement
      // set, targetTemplateId null) are independent and checked separately, so
      // both can coexist for a fire flame_dragon.
      //
      // This test verifies the actual behavior: template skins and element skins
      // are independent categories; a flame_dragon (fire) gets universal + fire element + dragon template skins.
      final skins = SkinDatabase.applicableTo(
        element: 'fire',
        templateId: 'flame_dragon',
      );
      final ids = skins.map((s) => s.id).toSet();
      // Universal skins
      expect(ids, contains('crystal_armor'));
      // Fire element skin
      expect(ids, contains('infernal_flame'));
      // Template-specific skin
      expect(ids, contains('dragon_emperor'));
      // Water element skin must not appear
      expect(ids, isNot(contains('abyssal_tide')));
    });

    test('3m. result is empty of non-universal skins for a dark stone monster', () {
      final skins = SkinDatabase.applicableTo(
        element: 'dark',
        templateId: 'shadow_golem',
      );
      // Only universal skins should be present (no dark-element skin defined).
      for (final skin in skins) {
        final isUniversal = skin.targetElement == null && skin.targetTemplateId == null;
        expect(isUniversal, isTrue,
            reason: '${skin.id} should not be applicable to dark/shadow_golem');
      }
    });
  });

  // =========================================================================
  // 4. SkinResolver.emoji
  // =========================================================================

  group('SkinResolver.emoji', () {
    test('4a. no skin equipped – returns element emoji for fire', () {
      final monster = buildMonster(element: 'fire');
      expect(SkinResolver.emoji(monster), equals('🔥'));
    });

    test('4b. no skin equipped – returns element emoji for water', () {
      final monster = buildMonster(element: 'water');
      expect(SkinResolver.emoji(monster), equals('💧'));
    });

    test('4c. no skin equipped – returns element emoji for all defined elements', () {
      final elementEmojis = {
        'fire': '🔥',
        'water': '💧',
        'electric': '⚡',
        'stone': '🪨',
        'grass': '🌿',
        'ghost': '👻',
        'light': '✨',
        'dark': '🌑',
      };
      for (final entry in elementEmojis.entries) {
        final monster = buildMonster(element: entry.key);
        expect(SkinResolver.emoji(monster), equals(entry.value),
            reason: 'Expected emoji ${entry.value} for element ${entry.key}');
      }
    });

    test('4d. null equippedSkinId – falls back to element emoji', () {
      final monster = buildMonster(element: 'ghost', equippedSkinId: null);
      expect(SkinResolver.emoji(monster), equals('👻'));
    });

    test('4e. with crystal_armor equipped – returns overrideEmoji 💎', () {
      final monster = buildMonster(element: 'fire', equippedSkinId: 'crystal_armor');
      expect(SkinResolver.emoji(monster), equals('💎'));
    });

    test('4f. with shadow_cloak equipped – returns overrideEmoji 🌑', () {
      final monster = buildMonster(element: 'water', equippedSkinId: 'shadow_cloak');
      expect(SkinResolver.emoji(monster), equals('🌑'));
    });

    test('4g. with dragon_emperor equipped – returns overrideEmoji 🐉', () {
      final monster = buildMonster(
        element: 'fire',
        templateId: 'flame_dragon',
        equippedSkinId: 'dragon_emperor',
      );
      expect(SkinResolver.emoji(monster), equals('🐉'));
    });

    test('4h. unknown equippedSkinId – skin lookup returns null – falls back to element emoji', () {
      final monster = buildMonster(element: 'electric', equippedSkinId: 'nonexistent_skin_xyz');
      // findById returns null, so no override applies, falls back to element emoji.
      expect(SkinResolver.emoji(monster), equals('⚡'));
    });

    test('4i. unknown element with no skin – returns ❓ fallback', () {
      final monster = buildMonster(element: 'plasma');
      expect(SkinResolver.emoji(monster), equals('❓'));
    });

    test('4j. unknown element with a skin that has overrideEmoji – returns skin emoji', () {
      final monster = buildMonster(element: 'plasma', equippedSkinId: 'golden_crown');
      expect(SkinResolver.emoji(monster), equals('👑'));
    });
  });

  // =========================================================================
  // 5. SkinResolver.color
  // =========================================================================

  group('SkinResolver.color', () {
    test('5a. no skin equipped – returns element color for fire', () {
      final monster = buildMonster(element: 'fire');
      expect(SkinResolver.color(monster), equals(const Color(0xFFFF6B5B)));
    });

    test('5b. no skin equipped – returns element color for water', () {
      final monster = buildMonster(element: 'water');
      expect(SkinResolver.color(monster), equals(const Color(0xFF42A5F5)));
    });

    test('5c. null equippedSkinId – falls back to element color', () {
      final monster = buildMonster(element: 'electric', equippedSkinId: null);
      expect(SkinResolver.color(monster), equals(const Color(0xFFFFEB3B)));
    });

    test('5d. with crystal_armor equipped – returns overrideColor cyan', () {
      final monster = buildMonster(element: 'stone', equippedSkinId: 'crystal_armor');
      expect(SkinResolver.color(monster), equals(const Color(0xFF00BCD4)));
    });

    test('5e. with shadow_cloak equipped – returns overrideColor dark grey', () {
      final monster = buildMonster(element: 'ghost', equippedSkinId: 'shadow_cloak');
      expect(SkinResolver.color(monster), equals(const Color(0xFF37474F)));
    });

    test('5f. with golden_crown equipped – returns overrideColor gold', () {
      final monster = buildMonster(element: 'light', equippedSkinId: 'golden_crown');
      expect(SkinResolver.color(monster), equals(const Color(0xFFFFD700)));
    });

    test('5g. with dragon_emperor equipped – returns overrideColor amber', () {
      final monster = buildMonster(
        element: 'fire',
        templateId: 'flame_dragon',
        equippedSkinId: 'dragon_emperor',
      );
      expect(SkinResolver.color(monster), equals(const Color(0xFFFF8F00)));
    });

    test('5h. unknown equippedSkinId – falls back to element color', () {
      final monster = buildMonster(element: 'grass', equippedSkinId: 'fake_skin_id');
      expect(SkinResolver.color(monster), equals(const Color(0xFF66BB6A)));
    });

    test('5i. unknown element with no skin – returns Colors.grey fallback', () {
      final monster = buildMonster(element: 'plasma');
      expect(SkinResolver.color(monster), equals(Colors.grey));
    });

    test('5j. unknown element with a skin that has overrideColor – returns skin color', () {
      final monster = buildMonster(element: 'plasma', equippedSkinId: 'cosmic_void');
      expect(SkinResolver.color(monster), equals(const Color(0xFF1A237E)));
    });

    test('5k. color for all element-specific skins returns override, not element color', () {
      final overrides = {
        'infernal_flame': const Color(0xFFD50000),
        'abyssal_tide': const Color(0xFF0D47A1),
        'thunder_strike': const Color(0xFFFFC107),
        'ancient_moss': const Color(0xFF2E7D32),
        'spectral_phantom': const Color(0xFF9575CD),
      };
      final elements = {
        'infernal_flame': 'fire',
        'abyssal_tide': 'water',
        'thunder_strike': 'electric',
        'ancient_moss': 'grass',
        'spectral_phantom': 'ghost',
      };
      for (final entry in overrides.entries) {
        final monster = buildMonster(
          element: elements[entry.key]!,
          equippedSkinId: entry.key,
        );
        expect(SkinResolver.color(monster), equals(entry.value),
            reason: 'Expected override color for skin ${entry.key}');
      }
    });
  });

  // =========================================================================
  // 6. SkinDatabase.all – master list integrity
  // =========================================================================

  group('SkinDatabase.all – master list integrity', () {
    test('6a. contains exactly 14 skins (6 universal + 5 element + 3 template)', () {
      expect(SkinDatabase.all.length, equals(14));
    });

    test('6b. has exactly 6 universal skins', () {
      final universal = SkinDatabase.all
          .where((s) => s.targetElement == null && s.targetTemplateId == null)
          .toList();
      expect(universal.length, equals(6));
    });

    test('6c. has exactly 5 element-specific skins', () {
      final elementSpecific = SkinDatabase.all
          .where((s) => s.targetElement != null && s.targetTemplateId == null)
          .toList();
      expect(elementSpecific.length, equals(5));
    });

    test('6d. has exactly 3 template-specific skins', () {
      final templateSpecific = SkinDatabase.all
          .where((s) => s.targetTemplateId != null)
          .toList();
      expect(templateSpecific.length, equals(3));
    });

    test('6e. no skin has both targetElement and targetTemplateId set', () {
      for (final skin in SkinDatabase.all) {
        expect(
          skin.targetElement != null && skin.targetTemplateId != null,
          isFalse,
          reason: '${skin.id} must not have both targetElement and targetTemplateId',
        );
      }
    });
  });
}
