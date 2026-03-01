import 'package:flutter/material.dart';

import 'package:gameapp/core/enums/monster_element.dart';
import 'package:gameapp/core/enums/monster_rarity.dart';
import 'package:gameapp/data/static/skin_database.dart';
import 'package:gameapp/presentation/widgets/monster_portrait_painter.dart';

// =============================================================================
// MonsterAvatar — procedural monster visual widget
// =============================================================================

/// A reusable, consistent monster avatar widget used across all screens.
///
/// Renders a procedurally generated monster using [MonsterPortraitPainter]
/// based on [templateId] seed. Falls back to element icon if no templateId.
/// Rarity 3+ gets animated glow ring.
class MonsterAvatar extends StatefulWidget {
  const MonsterAvatar({
    super.key,
    required this.name,
    required this.element,
    required this.rarity,
    this.templateId,
    this.size = 48,
    this.evolutionStage = 0,
    this.showName = false,
    this.showLevel = false,
    this.level = 1,
    this.isDead = false,
    this.showRarityGlow = false,
    this.equippedSkinId,
  });

  final String name;
  final String element;
  final int rarity;
  final String? templateId;
  final double size;
  final int evolutionStage;
  final bool showName;
  final bool showLevel;
  final int level;
  final bool isDead;
  final bool showRarityGlow;
  final String? equippedSkinId;

  @override
  State<MonsterAvatar> createState() => _MonsterAvatarState();
}

class _MonsterAvatarState extends State<MonsterAvatar>
    with SingleTickerProviderStateMixin {
  AnimationController? _glowController;

  @override
  void initState() {
    super.initState();
    _initGlow();
  }

  @override
  void didUpdateWidget(MonsterAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rarity != widget.rarity || oldWidget.isDead != widget.isDead) {
      _initGlow();
    }
  }

  void _initGlow() {
    if (widget.rarity >= 3 && !widget.isDead) {
      _glowController ??= AnimationController(
        vsync: this,
        duration: const Duration(seconds: 3),
      )..repeat();
    } else {
      _glowController?.dispose();
      _glowController = null;
    }
  }

  @override
  void dispose() {
    _glowController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rarityEnum = MonsterRarity.fromRarity(widget.rarity);
    final rarColor = rarityEnum.color;

    Color? skinColor;
    int skinRarity = 0;
    if (widget.equippedSkinId != null) {
      final skin = SkinDatabase.findById(widget.equippedSkinId!);
      if (skin != null) {
        skinColor = skin.overrideColor;
        skinRarity = skin.rarity;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Procedural avatar
        RepaintBoundary(
          child: widget.templateId != null
              ? _buildProceduralAvatar(rarColor, skinColor, skinRarity)
              : _buildFallbackAvatar(rarColor),
        ),
        // Name
        if (widget.showName) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: widget.size + 16,
            child: Text(
              widget.name,
              style: TextStyle(
                fontSize: (widget.size * 0.22).clamp(10, 14),
                color: widget.isDead ? Colors.grey : rarColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
        // Level
        if (widget.showLevel) ...[
          Text(
            'Lv.${widget.level}',
            style: TextStyle(
              fontSize: (widget.size * 0.18).clamp(9, 12),
              color: Colors.grey[500],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProceduralAvatar(Color rarColor, Color? skinColor, int skinRarity) {
    Widget paintWidget;
    if (_glowController != null) {
      paintWidget = AnimatedBuilder(
        animation: _glowController!,
        builder: (context, _) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: MonsterPortraitPainter(
              templateId: widget.templateId!,
              element: widget.element,
              rarity: widget.rarity,
              isDead: widget.isDead,
              evolutionStage: widget.evolutionStage,
              glowPhase: _glowController!.value * 6.283,
              overrideColor: skinColor,
              skinRarity: skinRarity,
            ),
          );
        },
      );
    } else {
      paintWidget = CustomPaint(
        size: Size(widget.size, widget.size),
        painter: MonsterPortraitPainter(
          templateId: widget.templateId!,
          element: widget.element,
          rarity: widget.rarity,
          isDead: widget.isDead,
          evolutionStage: widget.evolutionStage,
          overrideColor: skinColor,
          skinRarity: skinRarity,
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        paintWidget,
        if (widget.equippedSkinId != null)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: widget.size * 0.22,
              height: widget.size * 0.22,
              decoration: BoxDecoration(
                color: skinRarity >= 4 ? Colors.purple : Colors.cyan,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Icon(
                Icons.diamond,
                size: widget.size * 0.13,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFallbackAvatar(Color rarColor) {
    final elemEnum = MonsterElement.fromName(widget.element);
    final elemColor = elemEnum?.color ?? Colors.grey;

    return Container(
      width: widget.size,
      height: widget.size,
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
          color: widget.isDead ? Colors.grey.withValues(alpha: 0.3) : rarColor,
          width: widget.rarity >= 4 ? 2.5 : 2.0,
        ),
        boxShadow: widget.showRarityGlow && widget.rarity >= 3 && !widget.isDead
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
          Icon(
            elemEnum?.icon ?? Icons.pets_rounded,
            color: widget.isDead ? Colors.grey : elemColor,
            size: widget.size * 0.45,
          ),
          if (widget.evolutionStage > 0)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: widget.size * 0.3,
                height: widget.size * 0.3,
                decoration: BoxDecoration(
                  color: widget.evolutionStage >= 2 ? Colors.amber : Colors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black54, width: 1),
                ),
                child: Center(
                  child: Text(
                    '${widget.evolutionStage}',
                    style: TextStyle(
                      fontSize: widget.size * 0.16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          if (widget.isDead)
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.5),
              ),
              child: Icon(
                Icons.close,
                color: Colors.red.withValues(alpha: 0.7),
                size: widget.size * 0.4,
              ),
            ),
        ],
      ),
    );
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
