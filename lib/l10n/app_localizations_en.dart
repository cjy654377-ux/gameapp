// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Monster Collection';

  @override
  String get tabBattle => 'Battle';

  @override
  String get tabGacha => 'Summon';

  @override
  String get tabCollection => 'Collection';

  @override
  String get tabUpgrade => 'Upgrade';

  @override
  String get tabQuest => 'Quests';

  @override
  String get tabSettings => 'Settings';

  @override
  String get battleIdle => 'Battle Standby';

  @override
  String get battleFighting => 'Fighting...';

  @override
  String get battleVictory => 'Victory!';

  @override
  String get battleDefeat => 'Defeat';

  @override
  String get battleAutoMode => 'Auto';

  @override
  String get battleSpeed => 'Speed';

  @override
  String get battleStart => 'Start Battle';

  @override
  String get battleRetreat => 'Retreat';

  @override
  String get stageSelect => 'Stage Select';

  @override
  String get gachaSinglePull => 'Single Pull';

  @override
  String get gachaTenPull => '10x Pull';

  @override
  String gachaPity(int count) {
    return 'Pity: $count/80';
  }

  @override
  String monsterLevel(int level) {
    return 'Lv.$level';
  }

  @override
  String get upgradeLevelUp => 'Level Up';

  @override
  String get upgradeEvolution => 'Evolve';

  @override
  String get upgradeFusion => 'Fusion';

  @override
  String get upgradeAwakening => 'Awaken';

  @override
  String get questDaily => 'Daily';

  @override
  String get questWeekly => 'Weekly';

  @override
  String get questAchievement => 'Achievement';

  @override
  String get questClaim => 'Claim';

  @override
  String get questNoQuests => 'No quests available';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsSound => 'Haptic Feedback';

  @override
  String get settingsBackup => 'Backup Data';

  @override
  String get settingsRestore => 'Restore Data';

  @override
  String get settingsPrestige => 'Prestige';

  @override
  String get gold => 'Gold';

  @override
  String get diamond => 'Diamond';

  @override
  String get gachaTicket => 'Summon Ticket';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get infiniteDungeon => 'Dungeon';

  @override
  String get worldBoss => 'World Boss';

  @override
  String get arena => 'Arena';

  @override
  String get eventDungeon => 'Events';

  @override
  String get guild => 'Guild';

  @override
  String get relic => 'Relics';

  @override
  String get expedition => 'Expedition';

  @override
  String get statistics => 'Stats';

  @override
  String get affinity => 'Affinity';

  @override
  String get skill => 'Skill';

  @override
  String get equippedRelics => 'Equipped Relics';

  @override
  String get noRelics => 'No relics equipped';

  @override
  String get noSkill => 'No skill';

  @override
  String get stats => 'Stats';

  @override
  String get experience => 'Experience';

  @override
  String get teamAssigned => 'In Team';

  @override
  String get teamNotAssigned => 'Not Assigned';

  @override
  String evolutionStage(int stage) {
    return 'Evolution Stage $stage';
  }

  @override
  String acquiredDate(String date) {
    return 'Acquired $date';
  }

  @override
  String get playerInfo => 'Player';

  @override
  String get battleStats => 'Battle';

  @override
  String get monsterStats => 'Monster';

  @override
  String get gachaStats => 'Summon';

  @override
  String get resources => 'Resources';

  @override
  String get equipmentQuests => 'Equipment / Quests';
}
