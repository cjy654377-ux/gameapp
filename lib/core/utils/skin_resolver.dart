import 'package:flutter/material.dart';

import '../../data/models/monster_model.dart';
import '../../data/static/skin_database.dart';
import '../enums/monster_element.dart';

/// Resolves the visual properties (emoji, color) for a monster,
/// applying skin overrides when a skin is equipped.
class SkinResolver {
  SkinResolver._();

  /// Returns the emoji to display for a monster (skin override or default).
  static String emoji(MonsterModel monster) {
    if (monster.equippedSkinId != null) {
      final skin = SkinDatabase.findById(monster.equippedSkinId!);
      if (skin?.overrideEmoji != null) return skin!.overrideEmoji!;
    }
    final element = MonsterElement.fromName(monster.element);
    return element?.emoji ?? '❓';
  }

  /// Returns the color to display for a monster (skin override or default).
  static Color color(MonsterModel monster) {
    if (monster.equippedSkinId != null) {
      final skin = SkinDatabase.findById(monster.equippedSkinId!);
      if (skin?.overrideColor != null) return skin!.overrideColor!;
    }
    final element = MonsterElement.fromName(monster.element);
    return element?.color ?? Colors.grey;
  }
}
