import 'package:flutter/material.dart';

import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/core/enums/monster_element.dart';
import 'package:gameapp/core/enums/monster_rarity.dart';
import 'package:gameapp/domain/entities/battle_entity.dart';
import 'package:gameapp/presentation/widgets/battle/hp_bar.dart';

/// A compact card representing a single [BattleMonster] during combat.
///
/// Features:
/// - Coloured circular avatar using the first character of the monster name
///   (sprite placeholder).
/// - Element colour ring around the avatar.
/// - Rarity stars row.
/// - HP bar with numeric overlay.
/// - Full grayscale + dim overlay when the monster is dead.
class MonsterBattleCard extends StatelessWidget {
  const MonsterBattleCard({
    super.key,
    required this.monster,
    this.width = 84.0,
  });

  final BattleMonster monster;

  /// Desired card width; height is derived proportionally.
  final double width;

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  MonsterElement get _element =>
      MonsterElement.fromName(monster.element) ?? MonsterElement.fire;

  MonsterRarity get _rarity => MonsterRarity.fromRarity(monster.rarity);

  Color get _elementColor => _element.color;
  Color get _rarityColor => _rarity.color;

  String get _avatarChar {
    final n = monster.name.trim();
    return n.isNotEmpty ? n.characters.first : '?';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final avatarSize = width * 0.52;
    final isDead = !monster.isAlive;

    Widget card = Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha:0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _rarityColor.withValues(alpha:isDead ? 0.2 : 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _elementColor.withValues(alpha:isDead ? 0.0 : 0.18),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Avatar circle ──────────────────────────────────────────────
          Stack(
            alignment: Alignment.center,
            children: [
              // Element ring
              Container(
                width: avatarSize + 4,
                height: avatarSize + 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _elementColor.withValues(alpha:isDead ? 0.2 : 0.8),
                    width: 2,
                  ),
                ),
              ),
              // Avatar background
              CircleAvatar(
                radius: avatarSize / 2,
                backgroundColor:
                    _elementColor.withValues(alpha:isDead ? 0.15 : 0.28),
                child: Text(
                  _avatarChar,
                  style: TextStyle(
                    fontSize: avatarSize * 0.42,
                    fontWeight: FontWeight.bold,
                    color: isDead
                        ? AppColors.disabledText
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              // Dead skull overlay on avatar
              if (isDead)
                CircleAvatar(
                  radius: avatarSize / 2,
                  backgroundColor: Colors.black.withValues(alpha:0.55),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.error.withValues(alpha:0.7),
                    size: avatarSize * 0.45,
                  ),
                ),
              // Skill ready indicator (top-right)
              if (!isDead && monster.isSkillReady)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD740),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black54, width: 0.8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 9,
                      color: Colors.black87,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 4),

          // ── Monster name ───────────────────────────────────────────────
          Text(
            monster.name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color:
                  isDead ? AppColors.disabledText : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 2),

          // ── Element badge ──────────────────────────────────────────────
          _ElementBadge(element: _element, isDead: isDead),

          const SizedBox(height: 3),

          // ── Status icons (burn / stun / shield) ────────────────────────
          if (!isDead) _StatusIcons(monster: monster),

          const SizedBox(height: 2),

          // ── Rarity stars ───────────────────────────────────────────────
          _RarityStars(rarity: _rarity, isDead: isDead),

          const SizedBox(height: 4),

          // ── HP bar (with shield) ────────────────────────────────────────
          HpBar(
            currentHp: monster.currentHp.clamp(0, monster.maxHp),
            maxHp: monster.maxHp,
            shieldHp: monster.shieldHp,
            height: 12,
          ),

          // ── Skill cooldown indicator ───────────────────────────────────
          if (!isDead && monster.skillId != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                monster.skillCooldown > 0
                    ? 'CD ${monster.skillCooldown}'
                    : 'READY',
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  color: monster.skillCooldown > 0
                      ? AppColors.textTertiary
                      : const Color(0xFFFFD740),
                ),
              ),
            ),
        ],
      ),
    );

    // Apply grayscale filter when dead
    if (isDead) {
      card = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0, //
          0.2126, 0.7152, 0.0722, 0, 0, //
          0.2126, 0.7152, 0.0722, 0, 0, //
          0,      0,      0,      0.5, 0, //
        ]),
        child: card,
      );
    }

    return card;
  }
}

// =============================================================================
// _ElementBadge
// =============================================================================

class _ElementBadge extends StatelessWidget {
  const _ElementBadge({required this.element, required this.isDead});

  final MonsterElement element;
  final bool isDead;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: element.color.withValues(alpha:isDead ? 0.1 : 0.22),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: element.color.withValues(alpha:isDead ? 0.15 : 0.5),
          width: 0.7,
        ),
      ),
      child: Text(
        element.koreanName,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: isDead
              ? AppColors.disabledText
              : element.color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// =============================================================================
// _RarityStars
// =============================================================================

class _RarityStars extends StatelessWidget {
  const _RarityStars({required this.rarity, required this.isDead});

  final MonsterRarity rarity;
  final bool isDead;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(rarity.starCount, (_) {
        return Icon(
          Icons.star_rounded,
          size: 8,
          color: isDead
              ? AppColors.disabledText
              : rarity.color,
        );
      }),
    );
  }
}

// =============================================================================
// _StatusIcons — burn / stun / shield indicators
// =============================================================================

class _StatusIcons extends StatelessWidget {
  const _StatusIcons({required this.monster});

  final BattleMonster monster;

  @override
  Widget build(BuildContext context) {
    final icons = <Widget>[];

    if (monster.burnTurns > 0) {
      icons.add(_StatusChip(
        icon: Icons.local_fire_department,
        color: const Color(0xFFFF7043),
        label: '${monster.burnTurns}',
      ));
    }

    if (monster.stunTurns > 0) {
      icons.add(_StatusChip(
        icon: Icons.flash_on,
        color: const Color(0xFFFFEE58),
        label: '${monster.stunTurns}',
      ));
    }

    if (monster.shieldHp > 0) {
      icons.add(_StatusChip(
        icon: Icons.shield,
        color: const Color(0xFF42A5F5),
        label: '${monster.shieldHp.round()}',
      ));
    }

    if (icons.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: icons,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8, color: color),
          Text(
            label,
            style: TextStyle(fontSize: 7, color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
