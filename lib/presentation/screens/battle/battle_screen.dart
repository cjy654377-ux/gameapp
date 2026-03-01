import 'package:flutter/material.dart';

import 'package:gameapp/core/constants/app_colors.dart';
import 'battle_view.dart';

/// Standalone battle screen (used as a GoRouter fallback).
/// The primary battle UI lives in [BattleView], always mounted inside HomeScreen.
class BattleScreen extends StatelessWidget {
  const BattleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: BattleView(),
    );
  }
}
