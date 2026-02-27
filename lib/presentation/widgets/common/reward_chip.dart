import 'package:flutter/material.dart';

/// Compact reward chip: icon + text in a row.
/// Used in tower, dungeon, and other reward displays.
class RewardChip extends StatelessWidget {
  const RewardChip({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
