import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/core/utils/format_utils.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';

/// A top-of-screen bar that shows the player's current gold and diamond
/// balances.  Reads from [currencyProvider] automatically.
///
/// Can be used as a standalone widget on any screen:
/// ```dart
/// const CurrencyBar()
/// ```
class CurrencyBar extends ConsumerWidget {
  const CurrencyBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gold = ref.watch(currencyProvider.select((c) => c.gold));
    final diamond = ref.watch(currencyProvider.select((c) => c.diamond));
    final gachaTicket = ref.watch(currencyProvider.select((c) => c.gachaTicket));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.8),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // ── Gold ──────────────────────────────────────────────────────
            _CurrencyChip(
              icon: Icons.monetization_on_rounded,
              iconColor: AppColors.gold,
              amount: FormatUtils.formatNumber(gold),
            ),

            const SizedBox(width: 12),

            // ── Diamond ───────────────────────────────────────────────────
            _CurrencyChip(
              icon: Icons.diamond_rounded,
              iconColor: AppColors.diamond,
              amount: diamond.toString(),
            ),

            const Spacer(),

            // ── Gacha tickets (secondary) ─────────────────────────────────
            _CurrencyChip(
              icon: Icons.confirmation_number_rounded,
              iconColor: AppColors.primaryLight,
              amount: gachaTicket.toString(),
              iconSize: 14,
              fontSize: 11,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _CurrencyChip — private helper
// =============================================================================

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({
    required this.icon,
    required this.iconColor,
    required this.amount,
    this.iconSize = 16.0,
    this.fontSize = 13.0,
  });

  final IconData icon;
  final Color iconColor;
  final String amount;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha:0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: iconSize),
          const SizedBox(width: 4),
          Text(
            amount,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
