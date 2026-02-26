import 'package:flutter/material.dart';

import 'package:gameapp/core/constants/app_colors.dart';

/// A horizontal HP bar widget used on monster battle cards.
///
/// The bar color shifts based on the current HP percentage:
///   - > 50 % -> green ([AppColors.success])
///   - 20–50 % -> yellow/orange ([AppColors.warning])
///   - < 20 % -> red ([AppColors.error])
///
/// A text overlay always shows "currentHp / maxHp" in integer form.
class HpBar extends StatelessWidget {
  const HpBar({
    super.key,
    required this.currentHp,
    required this.maxHp,
    this.height = 14.0,
    this.showText = true,
    this.textStyle,
  });

  final double currentHp;
  final double maxHp;

  /// Height of the bar track in logical pixels.
  final double height;

  /// Whether to render the "cur / max" text overlay.
  final bool showText;

  /// Override for the HP text style; defaults to a small white label.
  final TextStyle? textStyle;

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  double get _ratio {
    if (maxHp <= 0) return 0.0;
    return (currentHp / maxHp).clamp(0.0, 1.0);
  }

  Color get _barColor {
    final pct = _ratio;
    if (pct > 0.50) return AppColors.success;
    if (pct > 0.20) return AppColors.warning;
    return AppColors.error;
  }

  String get _hpText =>
      '${currentHp.toInt()} / ${maxHp.toInt()}';

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final effectiveTextStyle = textStyle ??
        const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 9.0,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(
              color: Colors.black54,
              blurRadius: 2,
            ),
          ],
        );

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // ── Track (background) ────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.6),
              borderRadius: BorderRadius.circular(height / 2),
              border: Border.all(
                color: AppColors.border.withOpacity(0.5),
                width: 0.5,
              ),
            ),
          ),

          // ── Filled portion ────────────────────────────────────────────
          FractionallySizedBox(
            widthFactor: _ratio,
            child: Container(
              decoration: BoxDecoration(
                color: _barColor,
                borderRadius: BorderRadius.circular(height / 2),
                boxShadow: [
                  BoxShadow(
                    color: _barColor.withOpacity(0.4),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),

          // ── Text overlay ──────────────────────────────────────────────
          if (showText)
            Center(
              child: Text(
                _hpText,
                style: effectiveTextStyle,
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
            ),
        ],
      ),
    );
  }
}
