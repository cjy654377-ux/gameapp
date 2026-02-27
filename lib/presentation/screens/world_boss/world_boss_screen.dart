import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/domain/services/world_boss_service.dart';
import 'package:gameapp/l10n/app_localizations.dart';
import 'package:gameapp/presentation/providers/world_boss_provider.dart';
import 'package:gameapp/presentation/widgets/battle/hp_bar.dart';

class WorldBossScreen extends ConsumerStatefulWidget {
  const WorldBossScreen({super.key});

  @override
  ConsumerState<WorldBossScreen> createState() => _WorldBossScreenState();
}

class _WorldBossScreenState extends ConsumerState<WorldBossScreen> {
  Timer? _autoTimer;

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoTurn() {
    _autoTimer?.cancel();
    final wbState = ref.read(worldBossProvider);
    if (wbState.phase != WorldBossPhase.fighting) return;
    if (!wbState.isAutoMode) return;

    final ms = (800 / wbState.battleSpeed).round();
    _autoTimer = Timer(Duration(milliseconds: ms), () {
      if (!mounted) return;
      final current = ref.read(worldBossProvider);
      if (current.phase == WorldBossPhase.fighting && current.isAutoMode) {
        ref.read(worldBossProvider.notifier).processTurn();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wbState = ref.watch(worldBossProvider);

    // Schedule auto turn after state update.
    ref.listen<WorldBossState>(worldBossProvider, (prev, next) {
      if (next.phase == WorldBossPhase.fighting && next.isAutoMode) {
        _scheduleAutoTurn();
      } else {
        _autoTimer?.cancel();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.worldBossName(WorldBossService.todayBossName())),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _autoTimer?.cancel();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _buildBody(wbState),
    );
  }

  Widget _buildBody(WorldBossState wbState) {
    switch (wbState.phase) {
      case WorldBossPhase.idle:
        return _IdleView(wbState: wbState);
      case WorldBossPhase.fighting:
        return _FightingView(wbState: wbState);
      case WorldBossPhase.finished:
        return _FinishedView(wbState: wbState);
    }
  }
}

// =============================================================================
// Idle View
// =============================================================================

class _IdleView extends ConsumerWidget {
  const _IdleView({required this.wbState});
  final WorldBossState wbState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final bossName = WorldBossService.todayBossName();
    final bossElement = WorldBossService.todayBossElement();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Boss icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _elementColor(bossElement).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _elementColor(bossElement),
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.whatshot,
                size: 60,
                color: _elementColor(bossElement),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              bossName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.worldBossElement(_elementName(context, bossElement)),
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),

            // Attempt info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    label: l.remainingAttempts,
                    value: '${wbState.remainingAttempts}/${WorldBossService.maxAttempts}',
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: l.turnLimit,
                    value: l.turnCount(WorldBossService.maxTurns),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: l.bestDamage,
                    value: _formatDamage(wbState.bestDamage),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Start button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: wbState.canAttempt
                    ? () => ref.read(worldBossProvider.notifier).startFight()
                    : null,
                icon: const Icon(Icons.sports_mma, size: 28),
                label: Text(
                  wbState.canAttempt ? l.challenge : l.challengeDone,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Fighting View
// =============================================================================

class _FightingView extends ConsumerWidget {
  const _FightingView({required this.wbState});
  final WorldBossState wbState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final boss = wbState.boss;
    if (boss == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Boss HP bar + info
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.red.withValues(alpha: 0.1),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.whatshot,
                      color: _elementColor(boss.element), size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      boss.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    l.turnProgress(wbState.currentTurn, WorldBossService.maxTurns),
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              HpBar(
                currentHp: boss.currentHp,
                maxHp: boss.maxHp,
                shieldHp: boss.shieldHp,
                height: 20,
              ),
              const SizedBox(height: 4),
              Text(
                'HP: ${boss.currentHp.toInt()} / ${boss.maxHp.toInt()}',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ],
          ),
        ),

        // Damage counter
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.amber.withValues(alpha: 0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department,
                  color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                l.totalDamageAmount(_formatDamage(wbState.totalDamageDealt)),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ),

        // Player team
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: wbState.playerTeam.length,
            itemBuilder: (ctx, i) {
              final m = wbState.playerTeam[i];
              return Container(
                width: 70,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: m.isAlive
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      m.name,
                      style: TextStyle(
                        fontSize: 11,
                        color: m.isAlive ? Colors.white : Colors.red[300],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 56,
                      child: HpBar(
                        currentHp: m.currentHp,
                        maxHp: m.maxHp,
                        height: 6,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Battle log
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: wbState.battleLog.length,
            itemBuilder: (ctx, i) {
              final entry =
                  wbState.battleLog[wbState.battleLog.length - 1 - i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  entry.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: entry.isSkillActivation
                        ? const Color(0xFFCE93D8)
                        : entry.isCritical
                            ? Colors.amber
                            : Colors.grey[400],
                    fontWeight: entry.isSkillActivation || entry.isCritical
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),

        // Controls
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Speed button
              OutlinedButton(
                onPressed: () =>
                    ref.read(worldBossProvider.notifier).toggleSpeed(),
                child: Text('x${wbState.battleSpeed.toInt()}'),
              ),
              const SizedBox(width: 8),
              // Auto button
              OutlinedButton(
                onPressed: () =>
                    ref.read(worldBossProvider.notifier).toggleAutoMode(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: wbState.isAutoMode ? Colors.amber : Colors.grey,
                  ),
                ),
                child: Text(
                  l.battleAutoMode,
                  style: TextStyle(
                    color: wbState.isAutoMode ? Colors.amber : Colors.grey,
                  ),
                ),
              ),
              const Spacer(),
              // Manual turn button
              if (!wbState.isAutoMode)
                ElevatedButton(
                  onPressed: () =>
                      ref.read(worldBossProvider.notifier).processTurn(),
                  child: Text(l.nextTurn),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Finished View
// =============================================================================

class _FinishedView extends ConsumerWidget {
  const _FinishedView({required this.wbState});
  final WorldBossState wbState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final reward = wbState.lastReward;
    final boss = wbState.boss;
    final bossKilled = boss != null && !boss.isAlive;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              bossKilled ? Icons.emoji_events : Icons.timer_off,
              size: 64,
              color: bossKilled ? Colors.amber : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              bossKilled ? l.bossKilled : l.battleEnd,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: bossKilled ? Colors.amber : Colors.orange,
              ),
            ),
            const SizedBox(height: 24),

            // Damage result
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    l.totalDamage,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDamage(wbState.totalDamageDealt),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  if (wbState.totalDamageDealt >= wbState.bestDamage &&
                      wbState.totalDamageDealt > 0)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'NEW RECORD!',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rewards
            if (reward != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.rewardSection,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _RewardRow(
                      icon: Icons.monetization_on,
                      label: l.gold,
                      value: '+${reward.gold}',
                      color: Colors.amber,
                    ),
                    _RewardRow(
                      icon: Icons.auto_awesome,
                      label: l.experience,
                      value: '+${reward.exp}',
                      color: Colors.green,
                    ),
                    _RewardRow(
                      icon: Icons.diamond,
                      label: l.diamondFull,
                      value: '+${reward.diamond}',
                      color: Colors.cyanAccent,
                    ),
                    if (reward.shard > 0)
                      _RewardRow(
                        icon: Icons.auto_fix_high,
                        label: l.monsterShard,
                        value: '+${reward.shard}',
                        color: Colors.purple,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () =>
                    ref.read(worldBossProvider.notifier).collectReward(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l.collectReward,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Shared widgets
// =============================================================================

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Helpers
// =============================================================================

String _formatDamage(double damage) {
  if (damage >= 1000000) {
    return '${(damage / 1000000).toStringAsFixed(1)}M';
  }
  if (damage >= 1000) {
    return '${(damage / 1000).toStringAsFixed(1)}K';
  }
  return damage.toInt().toString();
}

Color _elementColor(String element) {
  switch (element) {
    case 'fire':
      return Colors.red;
    case 'water':
      return Colors.blue;
    case 'electric':
      return Colors.yellow;
    case 'stone':
      return Colors.brown;
    case 'grass':
      return Colors.green;
    case 'ghost':
      return Colors.purple;
    case 'light':
      return Colors.amber;
    case 'dark':
      return Colors.grey;
    default:
      return Colors.white;
  }
}

String _elementName(BuildContext context, String element) {
  final l = AppLocalizations.of(context)!;
  switch (element) {
    case 'fire':
      return l.elementFire;
    case 'water':
      return l.elementWater;
    case 'electric':
      return l.elementElectric;
    case 'stone':
      return l.elementRock;
    case 'grass':
      return l.elementGrass;
    case 'ghost':
      return l.elementGhost;
    case 'light':
      return l.elementLight;
    case 'dark':
      return l.elementDark;
    default:
      return element;
  }
}
