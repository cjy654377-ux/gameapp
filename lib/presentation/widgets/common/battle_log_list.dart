import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/battle_entity.dart';

/// Shared battle log list widget used across dungeon, arena, event dungeon,
/// world boss, and guild screens. Renders colored log entries.
class BattleLogList extends StatelessWidget {
  const BattleLogList({
    super.key,
    required this.entries,
    this.controller,
    this.reverse = false,
  });

  final List<BattleLogEntry> entries;
  final ScrollController? controller;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      reverse: reverse,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final entry = entries[i];
        final color = entry.isSkillActivation
            ? const Color(0xFFCE93D8)
            : entry.isCritical
                ? AppColors.error
                : AppColors.textSecondary;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: Text(
            entry.description,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight:
                  entry.isCritical || entry.isSkillActivation
                      ? FontWeight.w700
                      : FontWeight.w400,
            ),
          ),
        );
      },
    );
  }
}
