import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/core/models/app_message.dart';
import 'package:gameapp/data/datasources/local_storage.dart';
import 'package:gameapp/domain/services/prestige_service.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';
import 'package:gameapp/presentation/providers/monster_provider.dart';
import 'package:gameapp/presentation/providers/player_provider.dart';
import 'package:gameapp/presentation/providers/quest_provider.dart';
import 'package:gameapp/presentation/providers/relic_provider.dart';

// =============================================================================
// PrestigeState
// =============================================================================

class PrestigeState {
  final bool isProcessing;
  final bool showConfirmation;
  final AppMessage? resultMessage;

  const PrestigeState({
    this.isProcessing = false,
    this.showConfirmation = false,
    this.resultMessage,
  });

  PrestigeState copyWith({
    bool? isProcessing,
    bool? showConfirmation,
    AppMessage? resultMessage,
    bool clearMessage = false,
  }) {
    return PrestigeState(
      isProcessing: isProcessing ?? this.isProcessing,
      showConfirmation: showConfirmation ?? this.showConfirmation,
      resultMessage: clearMessage ? null : (resultMessage ?? this.resultMessage),
    );
  }
}

// =============================================================================
// PrestigeNotifier
// =============================================================================

class PrestigeNotifier extends StateNotifier<PrestigeState> {
  PrestigeNotifier(this.ref) : super(const PrestigeState());

  final Ref ref;

  void showConfirm() {
    state = state.copyWith(showConfirmation: true, clearMessage: true);
  }

  void hideConfirm() {
    state = state.copyWith(showConfirmation: false);
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }

  /// Performs the prestige reset:
  /// 1. Reset player (level, stage, dungeon floor)
  /// 2. Remove all monsters
  /// 3. Reset currencies (keep diamonds + give prestige reward)
  /// 4. Clear quests
  /// 5. Increment prestige level + bonus
  Future<bool> performPrestige() async {
    final playerState = ref.read(playerProvider);
    final player = playerState.player;
    if (player == null) return false;
    if (!PrestigeService.canPrestige(player)) return false;
    if (state.isProcessing) return false;

    state = state.copyWith(isProcessing: true, showConfirmation: false);

    // Calculate rewards before reset.
    final diamondReward = PrestigeService.prestigeDiamondReward(player);
    final ticketReward = PrestigeService.prestigeTicketReward(player);
    final newBonusPercent = PrestigeService.nextBonusPercent(player);
    final newPrestigeLevel = player.prestigeLevel + 1;

    // 1. Apply prestige to player model.
    final prestigedPlayer = PrestigeService.applyPrestige(player);
    await LocalStorage.instance.savePlayer(prestigedPlayer);
    await ref.read(playerProvider.notifier).loadPlayer();

    // 2. Remove all monsters.
    final monsters = ref.read(monsterListProvider);
    final monsterIds = monsters.map((m) => m.id).toList();
    await LocalStorage.instance.deleteMonsters(monsterIds);
    await ref.read(monsterListProvider.notifier).loadMonsters();

    // 3. Reset currencies, then add prestige rewards.
    await ref.read(currencyProvider.notifier).reset();
    // Give prestige diamond reward on top of initial diamonds.
    await ref.read(currencyProvider.notifier).addDiamond(diamondReward);
    await ref.read(currencyProvider.notifier).addGachaTicket(ticketReward);

    // 4. Clear quest progress.
    await LocalStorage.instance.clearQuests();
    await ref.read(questProvider.notifier).load();

    // 5. Clear relics.
    await LocalStorage.instance.clearRelics();
    await ref.read(relicProvider.notifier).loadRelics();

    state = PrestigeState(
      isProcessing: false,
      showConfirmation: false,
      resultMessage: AppMessage.prestige(
        newPrestigeLevel, newBonusPercent.toInt(), diamondReward, ticketReward),
    );
    return true;
  }
}

// =============================================================================
// Provider
// =============================================================================

final prestigeProvider =
    StateNotifierProvider<PrestigeNotifier, PrestigeState>(
  (ref) => PrestigeNotifier(ref),
);
