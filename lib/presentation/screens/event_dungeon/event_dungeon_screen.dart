import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/l10n/app_localizations.dart';
import 'package:gameapp/core/enums/monster_element.dart';
import 'package:gameapp/domain/services/event_dungeon_service.dart';
import 'package:gameapp/presentation/providers/event_dungeon_provider.dart';
import 'package:gameapp/presentation/widgets/battle/monster_battle_card.dart';

class EventDungeonScreen extends ConsumerStatefulWidget {
  const EventDungeonScreen({super.key});

  @override
  ConsumerState<EventDungeonScreen> createState() =>
      _EventDungeonScreenState();
}

class _EventDungeonScreenState extends ConsumerState<EventDungeonScreen> {
  Timer? _battleTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ed = ref.read(eventDungeonProvider);
      if (ed.events.isEmpty) {
        ref.read(eventDungeonProvider.notifier).loadEvents();
      }
    });
  }

  @override
  void dispose() {
    _battleTimer?.cancel();
    super.dispose();
  }

  void _startBattleTimer() {
    _battleTimer?.cancel();
    _battleTimer = Timer.periodic(
      Duration(
          milliseconds:
              (500 / ref.read(eventDungeonProvider).battleSpeed).round()),
      (_) {
        final phase = ref.read(eventDungeonProvider).phase;
        if (phase == EventDungeonPhase.fighting) {
          ref.read(eventDungeonProvider.notifier).processTurn();
        } else {
          _battleTimer?.cancel();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final phase = ref.watch(eventDungeonProvider.select((s) => s.phase));

    ref.listen(eventDungeonProvider.select((s) => s.battleSpeed), (_, __) {
      if (ref.read(eventDungeonProvider).phase ==
          EventDungeonPhase.fighting) {
        _startBattleTimer();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _battleTimer?.cancel();
            context.pop();
          },
        ),
        title: Text(AppLocalizations.of(context)!.eventDungeon),
        centerTitle: true,
      ),
      body: switch (phase) {
        EventDungeonPhase.lobby => const _LobbyView(),
        EventDungeonPhase.fighting =>
          _FightView(onStart: _startBattleTimer),
        EventDungeonPhase.waveCleared =>
          _WaveClearedView(onAdvance: _startBattleTimer),
        EventDungeonPhase.victory => const _ResultView(isVictory: true),
        EventDungeonPhase.defeat => const _ResultView(isVictory: false),
      },
    );
  }
}

// =============================================================================
// _LobbyView
// =============================================================================

class _LobbyView extends ConsumerWidget {
  const _LobbyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final events = ref.watch(eventDungeonProvider.select((s) => s.events));
    final clearedToday = ref.watch(eventDungeonProvider.select((s) => s.clearedToday));
    final lastClearedDate = ref.watch(eventDungeonProvider.select((s) => s.lastClearedDate));

    if (events.isEmpty) {
      return Center(child: Text(l.eventLoading));
    }

    bool canAttempt(String eventId) {
      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      if (lastClearedDate != today) return true;
      return !clearedToday.contains(eventId);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l.eventLimited,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.eventWeeklyDesc,
          style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 16),
        ...events.map((event) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _EventCard(
                event: event,
                canAttempt: canAttempt(event.id),
                onStart: () => ref
                    .read(eventDungeonProvider.notifier)
                    .startEvent(event),
              ),
            )),
      ],
    );
  }
}

// =============================================================================
// _EventCard
// =============================================================================

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.canAttempt,
    required this.onStart,
  });

  final EventDungeon event;
  final bool canAttempt;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final element =
        MonsterElement.fromName(event.element) ?? MonsterElement.fire;
    final remaining = event.remainingTime;
    final hours = remaining.inHours;
    final mins = remaining.inMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: element.color.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: element.color.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Text(element.emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      event.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Info row.
          Row(
            children: [
              _InfoChip(
                icon: Icons.flash_on,
                label: l.eventRecommendLevel(event.recommendedLevel),
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.layers,
                label: l.eventWaves(event.stages),
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.timer,
                label: l.eventTimeRemain(hours, mins),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Rewards preview.
          Row(
            children: [
              Icon(Icons.monetization_on, size: 14, color: Colors.amber),
              Text(' ${event.rewardGold}',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              Icon(Icons.diamond, size: 14, color: Colors.cyan),
              Text(' ${event.rewardDiamond}',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              if (event.rewardGachaTickets > 0) ...[
                const SizedBox(width: 8),
                Icon(Icons.confirmation_number, size: 14, color: Colors.green),
                Text(' ${event.rewardGachaTickets}',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: canAttempt ? onStart : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: element.color,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.disabled,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  canAttempt ? l.eventChallenge : l.eventCleared,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _FightView
// =============================================================================

class _FightView extends ConsumerStatefulWidget {
  const _FightView({required this.onStart});
  final VoidCallback onStart;

  @override
  ConsumerState<_FightView> createState() => _FightViewState();
}

class _FightViewState extends ConsumerState<_FightView> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_started) {
        _started = true;
        widget.onStart();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final ed = ref.watch(eventDungeonProvider);
    final event = ed.selectedEvent;

    return Column(
      children: [
        // Wave indicator.
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            l.waveProgress(event?.name ?? '', ed.currentWave, event?.stages ?? 0),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        // Teams.
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    physics: const NeverScrollableScrollPhysics(),
                    children: ed.playerTeam
                        .map<Widget>((m) => MonsterBattleCard(monster: m))
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('VS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textTertiary,
                      )),
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    physics: const NeverScrollableScrollPhysics(),
                    children: ed.enemyTeam
                        .map<Widget>((m) => MonsterBattleCard(monster: m))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(height: 1, color: AppColors.border),
        // Log.
        Expanded(
          flex: 3,
          child: ed.battleLog.isEmpty
              ? Center(
                  child: Text(l.battleWaiting,
                      style: TextStyle(color: AppColors.textTertiary)))
              : ListView.builder(
                  reverse: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: ed.battleLog.length,
                  itemBuilder: (ctx, i) {
                    final entry = ed.battleLog[ed.battleLog.length - 1 - i];
                    return Text(
                      entry.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: entry.isSkillActivation
                            ? Colors.purple[300]
                            : AppColors.textSecondary,
                      ),
                    );
                  },
                ),
        ),
        // Speed.
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () =>
                      ref.read(eventDungeonProvider.notifier).toggleSpeed(),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${ed.battleSpeed.toStringAsFixed(0)}x',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(l.turnN(ed.currentTurn),
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textTertiary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _WaveClearedView
// =============================================================================

class _WaveClearedView extends ConsumerWidget {
  const _WaveClearedView({required this.onAdvance});
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final ed = ref.watch(eventDungeonProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 56, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              l.waveCleared(ed.currentWave),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.nextWave(ed.currentWave + 1, ed.selectedEvent?.stages ?? 0),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(eventDungeonProvider.notifier).advanceWave();
                  onAdvance();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l.nextWaveBtn,
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
// _ResultView
// =============================================================================

class _ResultView extends ConsumerWidget {
  const _ResultView({required this.isVictory});
  final bool isVictory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final event = ref.watch(
        eventDungeonProvider.select((s) => s.selectedEvent));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVictory ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              size: 64,
              color: isVictory ? Colors.amber : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isVictory ? l.eventClear : l.battleDefeat,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isVictory ? Colors.amber : AppColors.error,
              ),
            ),
            if (isVictory && event != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _RewardLine(
                      icon: Icons.monetization_on,
                      label: l.gold,
                      value: '+${event.rewardGold}',
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 6),
                    _RewardLine(
                      icon: Icons.diamond,
                      label: l.diamond,
                      value: '+${event.rewardDiamond}',
                      color: Colors.cyan,
                    ),
                    if (event.rewardExpPotions > 0) ...[
                      const SizedBox(height: 6),
                      _RewardLine(
                        icon: Icons.science,
                        label: l.expPotion,
                        value: '+${event.rewardExpPotions}',
                        color: Colors.green,
                      ),
                    ],
                    if (event.rewardGachaTickets > 0) ...[
                      const SizedBox(height: 6),
                      _RewardLine(
                        icon: Icons.confirmation_number,
                        label: l.gachaTicket,
                        value: '+${event.rewardGachaTickets}',
                        color: Colors.purple,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (isVictory) {
                    ref.read(eventDungeonProvider.notifier).collectReward();
                  } else {
                    ref.read(eventDungeonProvider.notifier).returnToLobby();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isVictory ? Colors.amber : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isVictory ? l.reward : l.goBack,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

class _RewardLine extends StatelessWidget {
  const _RewardLine({
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
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
