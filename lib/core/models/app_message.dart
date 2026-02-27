import 'package:gameapp/l10n/app_localizations.dart';

/// A structured message that can be resolved to a localized string.
///
/// Providers store [AppMessage] instead of raw Korean strings,
/// allowing the UI layer to call [resolve] with the current locale.
class AppMessage {
  final String Function(AppLocalizations l) _resolver;

  AppMessage._(this._resolver);

  String resolve(AppLocalizations l) => _resolver(l);

  // ── Upgrade ──────────────────────────────────────────────────────────────

  factory AppMessage.levelUp(int level) =>
      AppMessage._((l) => l.msgLevelUp(level));

  factory AppMessage.expPotionLevelUp(int level, int gained) =>
      AppMessage._((l) => l.msgExpPotionLevelUp(level, gained));

  factory AppMessage.expGained() =>
      AppMessage._((l) => l.msgExpGained);

  factory AppMessage.evolution(int stage) =>
      AppMessage._((l) => stage == 1 ? l.msgEvolution1 : l.msgEvolution2);

  factory AppMessage.fusionHidden(String name, int rarity) =>
      AppMessage._((l) => l.msgFusionHidden(name, rarity));

  factory AppMessage.fusionNormal(String name, int rarity) =>
      AppMessage._((l) => l.msgFusionNormal(name, rarity));

  factory AppMessage.awakening(int stars) =>
      AppMessage._((l) => l.msgAwakening(stars));

  // ── Training ─────────────────────────────────────────────────────────────

  factory AppMessage.trainingStart(String name) =>
      AppMessage._((l) => l.msgTrainingStart(name));

  factory AppMessage.trainingCollect(String name, int xp) =>
      AppMessage._((l) => l.msgTrainingCollect(name, xp));

  factory AppMessage.trainingCollectLevelUp(
    String name, int xp, int oldLv, int newLv,
  ) =>
      AppMessage._((l) => l.msgTrainingCollectLevelUp(name, xp, oldLv, newLv));

  factory AppMessage.trainingCancel() =>
      AppMessage._((l) => l.msgTrainingCancel);

  // ── Expedition ───────────────────────────────────────────────────────────

  factory AppMessage.expeditionStart(int hours) =>
      AppMessage._((l) => l.msgExpeditionStart(hours));

  factory AppMessage.rewardSummary({
    int gold = 0,
    int expPotions = 0,
    int shards = 0,
    int diamonds = 0,
    int gachaTickets = 0,
  }) =>
      AppMessage._((l) {
        final parts = <String>[];
        if (gold > 0) parts.add(l.rewardGold(gold));
        if (expPotions > 0) parts.add(l.rewardExpPotion(expPotions));
        if (shards > 0) parts.add(l.rewardShard(shards));
        if (diamonds > 0) parts.add(l.rewardDiamond(diamonds));
        if (gachaTickets > 0) parts.add(l.rewardGachaTicket(gachaTickets));
        return l.msgRewardSummary(parts.join(', '));
      });

  // ── Prestige ─────────────────────────────────────────────────────────────

  factory AppMessage.prestige(int level, int bonus, int diamonds, int tickets) =>
      AppMessage._((l) => l.msgPrestige(level, bonus, diamonds, tickets));

  // ── Mailbox ──────────────────────────────────────────────────────────────

  factory AppMessage.mailReward({
    int gold = 0,
    int diamond = 0,
    int expPotion = 0,
    int gachaTicket = 0,
  }) =>
      AppMessage._((l) {
        final parts = <String>[];
        if (gold > 0) parts.add(l.rewardGold(gold));
        if (diamond > 0) parts.add(l.rewardDiamond(diamond));
        if (expPotion > 0) parts.add(l.rewardExpPotion(expPotion));
        if (gachaTicket > 0) parts.add(l.rewardGachaTicket(gachaTicket));
        return parts.join(', ');
      });
}
