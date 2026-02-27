import 'package:flutter/material.dart';

import 'package:gameapp/core/constants/app_colors.dart';

/// A reusable row widget that displays an icon, label, and value.
///
/// Used across arena, prestige, world boss, and other reward screens.
class RewardRow extends StatelessWidget {
  const RewardRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.iconSize = 18,
    this.labelFontSize = 14,
    this.valueFontSize = 14,
    this.verticalPadding = 3,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double iconSize;
  final double labelFontSize;
  final double valueFontSize;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Row(
        children: [
          Icon(icon, color: color, size: iconSize),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: labelFontSize,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
