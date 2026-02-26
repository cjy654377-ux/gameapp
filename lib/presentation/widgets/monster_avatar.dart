import 'package:flutter/material.dart';

import 'package:gameapp/core/enums/monster_element.dart';
import 'package:gameapp/core/enums/monster_rarity.dart';

// =============================================================================
// MonsterAvatar — unified monster visual widget
// =============================================================================

/// A reusable, consistent monster avatar widget used across all screens.
///
/// Shows an element-based icon with rarity-colored border and optional
/// decorators (evolution badge, level text, dead overlay).
class MonsterAvatar extends StatelessWidget {
  const MonsterAvatar({
    super.key,
    required this.name,
    required this.element,
    required this.rarity,
    this.size = 48,
    this.evolutionStage = 0,
    this.showName = false,
    this.showLevel = false,
    this.level = 1,
    this.isDead = false,
    this.showRarityGlow = false,
  });

  final String name;
  final String element;
  final int rarity;
  final double size;
  final int evolutionStage;
  final bool showName;
  final bool showLevel;
  final int level;
  final bool isDead;
  final bool showRarityGlow;

  @override
  Widget build(BuildContext context) {
    final elemEnum = MonsterElement.fromName(element);
    final elemColor = elemEnum?.color ?? Colors.grey;
    final rarityEnum = MonsterRarity.fromRarity(rarity);
    final rarColor = rarityEnum.color;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar circle
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                elemColor.withValues(alpha: 0.3),
                elemColor.withValues(alpha: 0.1),
              ],
            ),
            border: Border.all(
              color: isDead ? Colors.grey.withValues(alpha: 0.3) : rarColor,
              width: rarity >= 4 ? 2.5 : 2.0,
            ),
            boxShadow: showRarityGlow && rarity >= 3 && !isDead
                ? [
                    BoxShadow(
                      color: rarColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Element icon
              Icon(
                _elementIcon(element),
                color: isDead ? Colors.grey : elemColor,
                size: size * 0.45,
              ),
              // Evolution badge
              if (evolutionStage > 0)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: size * 0.3,
                    height: size * 0.3,
                    decoration: BoxDecoration(
                      color: evolutionStage >= 2
                          ? Colors.amber
                          : Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black54,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$evolutionStage',
                        style: TextStyle(
                          fontSize: size * 0.16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              // Dead overlay
              if (isDead)
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.red.withValues(alpha: 0.7),
                    size: size * 0.4,
                  ),
                ),
            ],
          ),
        ),
        // Name
        if (showName) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: size + 16,
            child: Text(
              name,
              style: TextStyle(
                fontSize: (size * 0.22).clamp(10, 14),
                color: isDead ? Colors.grey : rarColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
        // Level
        if (showLevel) ...[
          Text(
            'Lv.$level',
            style: TextStyle(
              fontSize: (size * 0.18).clamp(9, 12),
              color: Colors.grey[500],
            ),
          ),
        ],
      ],
    );
  }

  static IconData _elementIcon(String element) {
    switch (element) {
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'water':
        return Icons.water_drop_rounded;
      case 'electric':
        return Icons.flash_on_rounded;
      case 'stone':
        return Icons.terrain_rounded;
      case 'grass':
        return Icons.eco_rounded;
      case 'ghost':
        return Icons.visibility_off_rounded;
      case 'light':
        return Icons.wb_sunny_rounded;
      case 'dark':
        return Icons.dark_mode_rounded;
      default:
        return Icons.pets_rounded;
    }
  }
}

// =============================================================================
// RarityStars — rarity star display widget
// =============================================================================

class RarityStars extends StatelessWidget {
  const RarityStars({
    super.key,
    required this.rarity,
    this.starSize = 14,
  });

  final int rarity;
  final double starSize;

  @override
  Widget build(BuildContext context) {
    final rarityEnum = MonsterRarity.fromRarity(rarity);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        rarity.clamp(1, 5),
        (_) => Icon(
          Icons.star,
          color: rarityEnum.color,
          size: starSize,
        ),
      ),
    );
  }
}

// =============================================================================
// ElementBadge — element display badge
// =============================================================================

class ElementBadge extends StatelessWidget {
  const ElementBadge({
    super.key,
    required this.element,
    this.fontSize = 11,
  });

  final String element;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final elemEnum = MonsterElement.fromName(element);
    final color = elemEnum?.color ?? Colors.grey;
    final label = elemEnum?.koreanName ?? element;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
