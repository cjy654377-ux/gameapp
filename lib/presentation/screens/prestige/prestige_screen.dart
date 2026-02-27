import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gameapp/domain/services/prestige_service.dart';
import 'package:gameapp/l10n/app_localizations.dart';
import 'package:gameapp/presentation/providers/player_provider.dart';
import 'package:gameapp/presentation/providers/prestige_provider.dart';
import 'package:gameapp/presentation/widgets/common/reward_row.dart';

class PrestigeScreen extends ConsumerWidget {
  const PrestigeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final playerState = ref.watch(playerProvider);
    final player = playerState.player;
    final prestige = ref.watch(prestigeProvider);

    if (player == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.prestige)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final canPrestige = PrestigeService.canPrestige(player);
    final diamondReward = PrestigeService.prestigeDiamondReward(player);
    final ticketReward = PrestigeService.prestigeTicketReward(player);
    final currentBonus = player.prestigeBonusPercent;
    final nextBonus = PrestigeService.nextBonusPercent(player);
    final isMaxPrestige =
        player.prestigeLevel >= PrestigeService.maxPrestigeLevel;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.prestigeTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Prestige level badge
            _PrestigeBadge(level: player.prestigeLevel),
            const SizedBox(height: 20),

            // Current bonuses
            _InfoCard(
              title: l.prestigeCurrentBonus,
              children: [
                _BonusRow(
                  icon: Icons.monetization_on,
                  label: l.goldGain,
                  value: '+${currentBonus.toInt()}%',
                  color: Colors.amber,
                ),
                _BonusRow(
                  icon: Icons.auto_awesome,
                  label: l.expGain,
                  value: '+${currentBonus.toInt()}%',
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Requirements
            _InfoCard(
              title: l.prestigeCondition,
              children: [
                _RequirementRow(
                  label: l.prestigeMinLevel(PrestigeService.minLevelToPrestige),
                  met: player.playerLevel >= PrestigeService.minLevelToPrestige,
                  current: 'Lv.${player.playerLevel}',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    l.or,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                _RequirementRow(
                  label: l.prestigeMinArea(PrestigeService.minAreaToPrestige),
                  met: _clearedArea(player.maxClearedStageId) >=
                      PrestigeService.minAreaToPrestige,
                  current: player.maxClearedStageId.isEmpty
                      ? l.none
                      : player.maxClearedStageId,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // What you get / lose
            if (!isMaxPrestige) ...[
              _InfoCard(
                title: l.prestigeGains,
                color: Colors.green.withValues(alpha: 0.1),
                children: [
                  RewardRow(
                    icon: Icons.diamond,
                    label: l.diamondFull,
                    value: '+$diamondReward',
                    color: Colors.cyanAccent,
                  ),
                  RewardRow(
                    icon: Icons.confirmation_number,
                    label: l.gachaTicket,
                    value: '+$ticketReward',
                    color: Colors.purple,
                  ),
                  RewardRow(
                    icon: Icons.trending_up,
                    label: l.permanentBonus,
                    value: '${currentBonus.toInt()}% → ${nextBonus.toInt()}%',
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: l.prestigeLosses,
                color: Colors.red.withValues(alpha: 0.1),
                children: [
                  _LossRow(label: l.prestigeLossLevel),
                  _LossRow(label: l.prestigeLossStage),
                  _LossRow(label: l.prestigeLossDungeon),
                  _LossRow(label: l.prestigeLossMonster),
                  _LossRow(label: l.prestigeLossGold),
                  _LossRow(label: l.prestigeLossQuest),
                ],
              ),
            ] else
              _InfoCard(
                title: l.prestigeMaxTitle,
                color: Colors.amber.withValues(alpha: 0.15),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      l.prestigeMaxDesc(PrestigeService.maxPrestigeLevel),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Success message
            if (prestige.resultMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        prestige.resultMessage!,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Prestige button
            if (!isMaxPrestige)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: prestige.isProcessing
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: canPrestige
                            ? () => _showPrestigeConfirm(context, ref)
                            : null,
                        icon: const Icon(Icons.autorenew, size: 28),
                        label: Text(
                          canPrestige ? l.prestigeExecute : l.prestigeNotMet,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canPrestige
                              ? Colors.deepPurple
                              : Colors.grey[800],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showPrestigeConfirm(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Text(l.prestigeConfirmTitle),
          ],
        ),
        content: Text(l.prestigeConfirmDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(prestigeProvider.notifier).performPrestige();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            child: Text(l.prestigeExecute),
          ),
        ],
      ),
    );
  }

  static int _clearedArea(String stageId) {
    if (stageId.isEmpty) return 0;
    final parts = stageId.split('-');
    if (parts.isEmpty) return 0;
    return int.tryParse(parts[0]) ?? 0;
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

class _PrestigeBadge extends StatelessWidget {
  const _PrestigeBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final starCount = level.clamp(0, 20);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: level > 0
              ? [Colors.deepPurple.shade900, Colors.deepPurple.shade700]
              : [Colors.grey.shade900, Colors.grey.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: level > 0
              ? Colors.amber.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.autorenew,
            size: 48,
            color: level > 0 ? Colors.amber : Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            l.prestigeLevelN(level),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: level > 0 ? Colors.amber : Colors.grey,
            ),
          ),
          if (starCount > 0) ...[
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              children: List.generate(
                starCount,
                (_) => const Icon(Icons.star, color: Colors.amber, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.children,
    this.color,
  });

  final String title;
  final List<Widget> children;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _BonusRow extends StatelessWidget {
  const _BonusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({
    required this.label,
    required this.met,
    required this.current,
  });

  final String label;
  final bool met;
  final String current;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            color: met ? Colors.greenAccent : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: met ? Colors.white : Colors.grey,
              ),
            ),
          ),
          Text(
            current,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: met ? Colors.greenAccent : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}


class _LossRow extends StatelessWidget {
  const _LossRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.remove_circle_outline, color: Colors.redAccent,
              size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}
