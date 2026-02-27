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
  String battleStageId(String id) {
    return 'Stage $id';
  }

  @override
  String get battleStandby => 'Battle Standby';

  @override
  String get ourTeam => 'Our Team';

  @override
  String get enemyTeam => 'Enemy Team';

  @override
  String turnN(int n) {
    return 'Turn $n';
  }

  @override
  String get battleLog => 'Battle Log';

  @override
  String battleLogCount(int count) {
    return '$count entries';
  }

  @override
  String get noBattleLog => 'No battle records';

  @override
  String get criticalHit => '[CRIT] ';

  @override
  String get elementAdvantage => '[ADVANTAGE] ';

  @override
  String get autoOn => 'Auto Battle ON';

  @override
  String get autoOff => 'Auto Battle OFF';

  @override
  String get autoShortOn => 'Auto ON';

  @override
  String get autoShortOff => 'Auto OFF';

  @override
  String get preparing => 'Preparing';

  @override
  String get fighting => 'Fighting';

  @override
  String get reward => 'Collect Reward';

  @override
  String get retry => 'Retry';

  @override
  String get preparingBattle => 'Preparing...';

  @override
  String get collectingReward => 'Calculating rewards...';

  @override
  String get showStats => 'View Battle Stats';

  @override
  String get hideStats => 'Hide Stats';

  @override
  String get earnedReward => 'Earned Rewards';

  @override
  String get totalDamage => 'Total Damage';

  @override
  String get critCount => 'Criticals';

  @override
  String get skillCount => 'Skills';

  @override
  String get standby => 'Standby';

  @override
  String get stageSelect => 'Stage Select';

  @override
  String get areaForest => 'Beginner Forest';

  @override
  String get areaVolcano => 'Flame Volcano';

  @override
  String get areaDungeon => 'Dark Dungeon';

  @override
  String get areaTemple => 'Deep Sea Temple';

  @override
  String get areaSky => 'Sky Sanctuary';

  @override
  String get gachaSinglePull => 'Single Pull';

  @override
  String get gachaTenPull => '10x Pull';

  @override
  String gachaPity(int count) {
    return 'Pity: $count/80';
  }

  @override
  String get gachaTitle => 'Monster Summon';

  @override
  String get gachaDesc => 'Summon powerful monsters to strengthen your team!';

  @override
  String get gachaLegendaryUp => '★ Legendary Rate UP ★';

  @override
  String get gachaUntilLegend => 'Until Legendary';

  @override
  String gachaRemainingCount(int count) {
    return 'Remaining: $count pulls';
  }

  @override
  String get gachaNextGuaranteed => 'Next pull guaranteed legendary!';

  @override
  String get gachaRates => 'Summon Rates';

  @override
  String get gachaThreeStarGuarantee => '3★+ guaranteed once';

  @override
  String get gachaDiamondShort => 'Not enough diamonds';

  @override
  String get gachaTicketShort => 'Not enough tickets';

  @override
  String get gachaUseTicket => 'Use Ticket';

  @override
  String gachaTicketCount(int count) {
    return '$count tickets';
  }

  @override
  String get gachaResultSingle => 'Summon Result';

  @override
  String get gachaResultTen => '10x Summon Result';

  @override
  String get gachaRevealAll => 'Reveal All';

  @override
  String get gachaGuaranteed => 'Guaranteed!';

  @override
  String monsterLevel(int level) {
    return 'Lv.$level';
  }

  @override
  String get monsterCollection => 'Monster Collection';

  @override
  String get ownedOnly => 'Owned';

  @override
  String get reset => 'Reset';

  @override
  String get noMatchingMonster => 'No matching monsters';

  @override
  String ownedCount(int count) {
    return 'Owned: $count';
  }

  @override
  String bestUnit(int level) {
    return 'Best (Lv.$level)';
  }

  @override
  String get unownedMonster => 'Unowned Monster';

  @override
  String get teamEdit => 'Team Edit';

  @override
  String get save => 'Save';

  @override
  String totalPower(String power) {
    return 'Total Power: $power';
  }

  @override
  String get noMonsterOwned => 'No monsters owned';

  @override
  String get getMonsterFromGacha => 'Get monsters from Summon';

  @override
  String milestoneReward(String label, int gold, int diamond) {
    return '$label reward claimed! Gold +$gold, Diamond +$diamond';
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
  String get selectMonsterToUpgrade => 'Select Monster to Upgrade';

  @override
  String maxLevelReached(int level) {
    return 'Max Level Reached! (Lv.$level)';
  }

  @override
  String get levelUpPreview => 'After Level Up';

  @override
  String get levelUpWithGold => 'Level Up with Gold';

  @override
  String get goldShort => 'Not enough gold';

  @override
  String get expPotion => 'EXP Potion';

  @override
  String expPotionOwned(int count, int exp) {
    return 'Owned: $count  ($exp EXP each)';
  }

  @override
  String get potionUse1 => 'x1';

  @override
  String get potionUse5 => 'x5';

  @override
  String get potionUse10 => 'x10';

  @override
  String get potionUseAll => 'All';

  @override
  String get expPotionShort => 'Not enough EXP potions';

  @override
  String get finalEvolutionDone => 'Final Evolution Complete!';

  @override
  String get evolutionPreview => 'After Evolution';

  @override
  String get firstEvolution => '1st Evolution';

  @override
  String get finalEvolution => 'Final Evolution';

  @override
  String get evolve => 'Evolve';

  @override
  String get materialShort => 'Not enough materials';

  @override
  String get fusionLegendaryLimit => 'Legendary grade cannot be fused';

  @override
  String get fusionTeamLimit => 'Team members cannot be fused';

  @override
  String fusionDesc(String stars, String rarity) {
    return 'Fuse 2 same-grade monsters to get\na $stars $rarity grade monster';
  }

  @override
  String get material1 => 'Material 1';

  @override
  String get material2 => 'Material 2';

  @override
  String get selectMaterial2 => 'Select Material 2';

  @override
  String get fusionCost => 'Fusion Cost';

  @override
  String get fusionExecute => 'Fuse';

  @override
  String fusionFormula(int from, int to) {
    return '$from★ + $from★ → $to★';
  }

  @override
  String get fusionCheckCondition => 'Check fusion conditions';

  @override
  String get noFusionMaterial => 'No fusable monsters of same grade';

  @override
  String get selectFusionMaterial => 'Select Fusion Material';

  @override
  String get basic => 'Basic';

  @override
  String get firstEvo => '1st Evo';

  @override
  String get finalEvo => 'Final Evo';

  @override
  String get evolutionMaterial => 'Evolution Materials';

  @override
  String get evolutionStone => 'Evo Stone';

  @override
  String get awakeningRequireEvo => 'Final evolution required for awakening';

  @override
  String get awakeningMaxDone => 'Max Awakening Complete!';

  @override
  String awakeningCostTitle(int star) {
    return 'Awakening $star★ Cost';
  }

  @override
  String shardCost(int count) {
    return '$count Evo Stones';
  }

  @override
  String get awakening => 'Awaken';

  @override
  String get awakeningInProgress => 'Awakening...';

  @override
  String currentAwakeningBonus(int bonus) {
    return 'Current Awakening Bonus: +$bonus%';
  }

  @override
  String nextAwakeningBonus(int bonus) {
    return 'Next Awakening Bonus: +$bonus%';
  }

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
  String get settingsEffects => 'Effects';

  @override
  String get settingsBackup => 'Backup Data';

  @override
  String get settingsRestore => 'Restore Data';

  @override
  String get settingsPrestige => 'Prestige';

  @override
  String get settingsPlayerInfo => 'Player Info';

  @override
  String get settingsNickname => 'Nickname';

  @override
  String get settingsLevel => 'Level';

  @override
  String get settingsCurrentStage => 'Current Stage';

  @override
  String get settingsBattleCount => 'Battle Count';

  @override
  String get settingsGachaCount => 'Summon Count';

  @override
  String get settingsPrestigeLevel => 'Prestige Level';

  @override
  String get settingsGameInfo => 'Game Info';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsOwnedMonster => 'Owned Monsters';

  @override
  String get settingsRelicEquip => 'Relics/Equipment';

  @override
  String get settingsRelicManage => 'Relic Management';

  @override
  String get settingsPrestigeGo => 'Go to Prestige';

  @override
  String get settingsBackupRestore => 'Backup / Restore';

  @override
  String get settingsBackupCopy => 'Backup (Copy)';

  @override
  String get settingsRestorePaste => 'Restore (Paste)';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsGameReset => 'Reset Game';

  @override
  String get settingsBackupDone => 'Game data copied to clipboard';

  @override
  String get settingsRestoreTitle => 'Restore Data';

  @override
  String get settingsRestoreDesc =>
      'Restore from clipboard backup data.\nAll current data will be overwritten.\nContinue?';

  @override
  String get settingsNoClipboard => 'No data in clipboard';

  @override
  String get settingsRestoreDone => 'Data restored!';

  @override
  String get settingsRestoreFail => 'Restore failed: Invalid backup data';

  @override
  String get settingsResetTitle => 'Reset Game';

  @override
  String get settingsResetDesc => 'All data will be deleted.\nAre you sure?';

  @override
  String get settingsResetConfirm => 'Reset';

  @override
  String get restore => 'Restore';

  @override
  String get gold => 'Gold';

  @override
  String get diamond => 'Diamond';

  @override
  String get diamondFull => 'Diamond';

  @override
  String get gachaTicket => 'Summon Ticket';

  @override
  String get monsterShard => 'Monster Shard';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get infiniteDungeon => 'Infinite Dungeon';

  @override
  String dungeonFloor(int floor) {
    return 'Floor $floor';
  }

  @override
  String dungeonBest(int floor) {
    return 'Best: Floor $floor';
  }

  @override
  String get dungeonPreparing => 'Preparing dungeon...';

  @override
  String get dungeonLog => 'Dungeon Log';

  @override
  String get dungeonStart => 'Start Dungeon';

  @override
  String get dungeonNextFloor => 'Next Floor';

  @override
  String get dungeonCollect => 'Collect Reward';

  @override
  String dungeonCollectFloor(int floor) {
    return 'Collect Reward (Floor $floor)';
  }

  @override
  String get floorCleared => 'Cleared!';

  @override
  String get worldBoss => 'World Boss';

  @override
  String worldBossName(String name) {
    return 'World Boss - $name';
  }

  @override
  String worldBossElement(String element) {
    return 'Element: $element';
  }

  @override
  String get remainingAttempts => 'Remaining Attempts';

  @override
  String get turnLimit => 'Turn Limit';

  @override
  String turnCount(int n) {
    return '$n Turns';
  }

  @override
  String get bestDamage => 'Best Damage';

  @override
  String get challenge => 'Challenge';

  @override
  String get challengeDone => 'Completed Today';

  @override
  String turnProgress(int current, int max) {
    return 'Turn $current/$max';
  }

  @override
  String totalDamageAmount(String damage) {
    return 'Total Damage: $damage';
  }

  @override
  String get nextTurn => 'Next Turn';

  @override
  String get bossKilled => 'Boss Defeated!';

  @override
  String get battleEnd => 'Battle End!';

  @override
  String get rewardSection => 'Rewards';

  @override
  String get collectReward => 'Collect Reward';

  @override
  String get goBack => 'Go Back';

  @override
  String get arena => 'PvP Arena';

  @override
  String get arenaShort => 'Arena';

  @override
  String get arenaEasy => 'Easy';

  @override
  String get arenaNormal => 'Normal';

  @override
  String get arenaHard => 'Hard';

  @override
  String get arenaRefresh => 'Refresh';

  @override
  String get arenaChampion => 'Champion';

  @override
  String get arenaDiamond => 'Diamond';

  @override
  String get arenaGold => 'Gold';

  @override
  String get arenaSilver => 'Silver';

  @override
  String get arenaBronze => 'Bronze';

  @override
  String arenaRankScore(String rank, int score) {
    return '$rank · ${score}pts';
  }

  @override
  String arenaRecord(int wins, int losses) {
    return '${wins}W ${losses}L';
  }

  @override
  String arenaRemaining(int remaining, int max) {
    return 'Remaining: $remaining/$max';
  }

  @override
  String arenaRating(int rating) {
    return 'Rating $rating';
  }

  @override
  String get arenaChallenge => 'Challenge';

  @override
  String get me => 'Me';

  @override
  String get opponent => 'Opponent';

  @override
  String get battleWaiting => 'Waiting for battle...';

  @override
  String get ratingLabel => 'Rating';

  @override
  String get eventDungeon => 'Event Dungeon';

  @override
  String get eventDungeonShort => 'Events';

  @override
  String get eventLoading => 'Loading events...';

  @override
  String get eventLimited => 'Limited Time Events';

  @override
  String get eventWeeklyDesc => 'New events every week!';

  @override
  String eventRecommendLevel(int level) {
    return 'Rec. Lv.$level';
  }

  @override
  String eventWaves(int count) {
    return '$count Waves';
  }

  @override
  String eventTimeRemain(int hours, int mins) {
    return '${hours}h ${mins}m remaining';
  }

  @override
  String get eventChallenge => 'Challenge';

  @override
  String get eventCleared => 'Cleared';

  @override
  String eventWaveProgress(String name, int current, int total) {
    return '$name - Wave $current/$total';
  }

  @override
  String waveCleared(int wave) {
    return 'Wave $wave Cleared!';
  }

  @override
  String nextWave(int current, int total) {
    return 'Next Wave: $current/$total';
  }

  @override
  String get nextWaveBtn => 'Next Wave';

  @override
  String get eventClear => 'Event Cleared!';

  @override
  String get guild => 'Guild';

  @override
  String get guildCreate => 'Create Guild';

  @override
  String get guildCreateDesc =>
      'Create a guild and defeat\npowerful bosses with allies!';

  @override
  String get guildNameHint => 'Enter guild name';

  @override
  String guildLevelCoin(int level, int coin) {
    return 'Lv.$level | Coins: $coin';
  }

  @override
  String guildMembers(int count) {
    return 'Members ($count)';
  }

  @override
  String get guildLeader => 'Me (Leader)';

  @override
  String guildWeeklyBoss(String name) {
    return 'Weekly Boss: $name';
  }

  @override
  String guildBossHp(String current, String max) {
    return 'HP: $current / $max';
  }

  @override
  String guildMyContrib(String damage) {
    return 'My Contribution: $damage';
  }

  @override
  String guildAiContrib(String damage) {
    return 'Members: $damage';
  }

  @override
  String get guildBossDefeated => 'Boss Defeated!';

  @override
  String guildBossChallenge(int remaining, int max) {
    return 'Boss Fight ($remaining/$max)';
  }

  @override
  String get guildShop => 'Guild Shop';

  @override
  String guildBossTurn(String name, int current, int max) {
    return '$name (Turn $current/$max)';
  }

  @override
  String guildFightDamage(String damage) {
    return 'Fight Damage: $damage';
  }

  @override
  String get attack => 'Attack';

  @override
  String get guildBattleEnd => 'Battle End!';

  @override
  String get guildDefeat => 'Defeat...';

  @override
  String guildTotalDamage(String damage) {
    return 'Total Damage: $damage';
  }

  @override
  String guildEarnedCoin(int coin) {
    return 'Earned Guild Coins: +$coin';
  }

  @override
  String get guildReturnLobby => 'Return to Lobby';

  @override
  String guildCoinLabel(int coin) {
    return 'Coins: $coin';
  }

  @override
  String guildItemCost(int cost) {
    return '$cost Coins';
  }

  @override
  String guildPurchaseDone(String name) {
    return '$name purchased!';
  }

  @override
  String get purchase => 'Purchase';

  @override
  String get expedition => 'Expedition';

  @override
  String expeditionSlots(int active, int max) {
    return 'Slots $active/$max';
  }

  @override
  String get expeditionActive => 'Active Expeditions';

  @override
  String get expeditionNew => 'Start New Expedition';

  @override
  String expeditionAllUsed(int count, int max) {
    return 'All slots in use ($count/$max)';
  }

  @override
  String get expeditionCollect => 'Collect Reward';

  @override
  String expeditionDepart(int count) {
    return 'Depart ($count monsters)';
  }

  @override
  String get expeditionNoMonster =>
      'No available monsters\n(In team or already on expedition)';

  @override
  String get relic => 'Relics';

  @override
  String relicCount(int count) {
    return 'Relics ($count)';
  }

  @override
  String get relicAll => 'All';

  @override
  String get relicWeapon => 'Weapon';

  @override
  String get relicArmor => 'Armor';

  @override
  String get relicAccessory => 'Accessory';

  @override
  String get relicEquipped => 'Equipped';

  @override
  String get noRelic => 'No relics';

  @override
  String get getRelicFromBattle => 'Get relics from battles and dungeons';

  @override
  String relicStarRarity(int rarity) {
    return '$rarity★';
  }

  @override
  String relicEquippedTo(String name) {
    return 'Equipped: $name';
  }

  @override
  String get unequip => 'Unequip';

  @override
  String get selectMonsterToEquip => 'Select monster to equip:';

  @override
  String get replace => 'Replace';

  @override
  String get relicDisassemble => 'Disassemble Relic';

  @override
  String get statAttack => 'Attack';

  @override
  String get statDefense => 'Defense';

  @override
  String get statHp => 'HP';

  @override
  String get statSpeed => 'Speed';

  @override
  String get prestige => 'Prestige';

  @override
  String get prestigeTitle => 'Prestige';

  @override
  String get prestigeCurrentBonus => 'Current Prestige Bonus';

  @override
  String get goldGain => 'Gold Gain';

  @override
  String get expGain => 'EXP Gain';

  @override
  String get prestigeCondition => 'Prestige Conditions';

  @override
  String prestigeMinLevel(int level) {
    return 'Player Level $level+';
  }

  @override
  String get or => 'OR';

  @override
  String prestigeMinArea(int area) {
    return '$area+ Areas Cleared';
  }

  @override
  String get none => 'None';

  @override
  String get prestigeGains => 'Prestige Rewards';

  @override
  String get prestigeLosses => 'Reset on Prestige';

  @override
  String get prestigeLossLevel => 'Player Level → Lv.1';

  @override
  String get prestigeLossStage => 'Stage Progress → 1-1';

  @override
  String get prestigeLossDungeon => 'Dungeon Records Reset';

  @override
  String get prestigeLossMonster => 'All Monsters Deleted';

  @override
  String get prestigeLossGold => 'Gold/Shards/Potions Reset';

  @override
  String get prestigeLossQuest => 'Quest Progress Reset';

  @override
  String get prestigeMaxTitle => 'Max Prestige Reached!';

  @override
  String prestigeMaxDesc(int level) {
    return 'You\'ve reached max prestige level $level!';
  }

  @override
  String get prestigeExecute => 'Prestige';

  @override
  String get prestigeNotMet => 'Conditions Not Met';

  @override
  String get prestigeConfirmTitle => 'Confirm Prestige';

  @override
  String get prestigeConfirmDesc =>
      'Prestige will reset your level, stages, monsters, and resources.\n\nYou\'ll receive diamonds, tickets, and a permanent battle bonus.\n\nAre you sure?';

  @override
  String prestigeLevelN(int level) {
    return 'Prestige Lv.$level';
  }

  @override
  String get permanentBonus => 'Permanent Bonus';

  @override
  String get statistics => 'Stats';

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
  String get affinity => 'Affinity';

  @override
  String get skill => 'Skill';

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

  @override
  String get statNickname => 'Nickname';

  @override
  String get statLevel => 'Level';

  @override
  String get statPrestigeCount => 'Prestige Count';

  @override
  String get statPrestigeBonus => 'Prestige Bonus';

  @override
  String get statJoinDate => 'Join Date';

  @override
  String get statPlayDays => 'Play Days';

  @override
  String get statTotalBattle => 'Total Stage Battles';

  @override
  String get statTeamBattle => 'Team Total Battles';

  @override
  String get statStageProgress => 'Stage Progress';

  @override
  String get statBestClear => 'Best Clear';

  @override
  String get statDungeonBest => 'Dungeon Best';

  @override
  String get statOwnedMonster => 'Owned Monsters';

  @override
  String get statCollection => 'Collection';

  @override
  String get statBestLevel => 'Highest Level';

  @override
  String get statTeamComp => 'Team Composition';

  @override
  String get statAvgLevel => 'Average Level';

  @override
  String get statTotalGacha => 'Total Summons';

  @override
  String get statCurrentPity => 'Current Pity';

  @override
  String get statFiveStarGuarantee => '5★ Guarantee';

  @override
  String get statGuaranteeImminent => 'Almost guaranteed!';

  @override
  String statGuaranteeRemain(int count) {
    return '$count pulls left';
  }

  @override
  String get statOwnedRelic => 'Owned Relics';

  @override
  String get statEquippedRelic => 'Equipped Relics';

  @override
  String get statCompletedQuest => 'Completed Quests';

  @override
  String get statClaimable => 'Claimable';

  @override
  String countUnit(String count) {
    return '${count}x';
  }

  @override
  String countMonster(int count) {
    return '$count';
  }

  @override
  String countItem(int count) {
    return '$count';
  }

  @override
  String countDay(int count) {
    return '$count days';
  }

  @override
  String countFloor(int floor) {
    return 'Floor $floor';
  }

  @override
  String get onboardingWelcome => 'Welcome to Monster Collector!';

  @override
  String get onboardingEnterName => 'Enter your adventurer name';

  @override
  String get onboardingNameHint => 'Nickname (2-12 chars)';

  @override
  String onboardingChooseMonster(String name) {
    return '$name,\nchoose your first companion!';
  }

  @override
  String get onboardingStart => 'Start Adventure!';

  @override
  String get tutorialStep1Title => 'Start your first battle!';

  @override
  String get tutorialStep1Msg =>
      'Press the \"Start Battle\" button below\nto begin your first fight.\nAuto battle and speed options available!';

  @override
  String get tutorialStep2Title => 'Congratulations on your victory!';

  @override
  String get tutorialStep2Msg =>
      'After collecting rewards,\ngo to the \"Summon\" tab\nto summon new monsters!';

  @override
  String get tutorialStep3Title => 'Summon monsters!';

  @override
  String get tutorialStep3Msg =>
      'Use diamonds or tickets\nto summon monsters.\nAim for high-grade monsters!';

  @override
  String get tutorialStep4Title => 'Upgrade your monsters!';

  @override
  String get tutorialStep4Msg =>
      'Select a monster in the \"Upgrade\" tab\nto level up with gold\nor evolve it!';

  @override
  String get tutorialStep5Title => 'Build your team!';

  @override
  String get tutorialStep5Msg =>
      'Press the team edit button in\nthe \"Collection\" tab to build\nyour ultimate team of 4!';

  @override
  String get affinityNames =>
      'None,Lv.1 Interest,Lv.2 Trust,Lv.3 Friendship,Lv.4 Bond,Lv.5 Max';

  @override
  String affinityBattleCount(int count) {
    return '$count Battles';
  }

  @override
  String affinityBonus(int percent) {
    return 'Bonus: All Stats +$percent%';
  }

  @override
  String get elementFire => 'Fire';

  @override
  String get elementWater => 'Water';

  @override
  String get elementElectric => 'Electric';

  @override
  String get elementRock => 'Rock';

  @override
  String get elementGrass => 'Grass';

  @override
  String get elementGhost => 'Ghost';

  @override
  String get elementLight => 'Light';

  @override
  String get elementDark => 'Dark';

  @override
  String playerLevelStage(int level, String stage) {
    return 'Lv.$level  |  Stage $stage';
  }

  @override
  String get dailyStatus => 'Daily Status';

  @override
  String questRewardAvailable(int count) {
    return '$count quest rewards available!';
  }

  @override
  String questInProgress(int count) {
    return '$count quests in progress';
  }

  @override
  String get shortcut => 'Shortcuts';

  @override
  String prestigeN(int level) {
    return 'Prestige $level';
  }

  @override
  String get attendanceTitle => 'Daily Check-in';

  @override
  String attendanceDesc(int days) {
    return 'Total $days days checked in';
  }

  @override
  String get attendanceCheckIn => 'Check In!';

  @override
  String attendanceDay(int day) {
    return 'Day $day';
  }

  @override
  String attendanceRewardGold(int amount) {
    return 'Gold $amount';
  }

  @override
  String attendanceRewardDiamond(int amount) {
    return 'Diamond $amount';
  }

  @override
  String attendanceRewardTicket(int amount) {
    return 'Ticket $amount';
  }

  @override
  String attendanceRewardPotion(int amount) {
    return 'EXP Potion $amount';
  }

  @override
  String get attendanceClaimed => 'Check-in reward claimed!';

  @override
  String get attendanceAlreadyClaimed => 'Already checked in today';

  @override
  String get towerTitle => 'Tower of Challenge';

  @override
  String get towerStart => 'Start Challenge';

  @override
  String get towerReady => 'Ready to challenge!';

  @override
  String get towerNoAttempts => 'No attempts left this week';

  @override
  String towerAttempts(int remaining, int max) {
    return 'Remaining: $remaining/$max';
  }

  @override
  String towerBest(int floor) {
    return 'Best: ${floor}F';
  }

  @override
  String get towerNextFloor => 'Next Floor';

  @override
  String get towerCollect => 'Collect Rewards';

  @override
  String get towerComplete => 'Tower Conquered!';

  @override
  String get towerNoHeal => 'No healing between floors!';

  @override
  String get recipeTitle => 'Recipes';

  @override
  String get recipeHidden => 'Hidden Monster';

  @override
  String get recipeUnlocked => 'Unlocked';

  @override
  String get recipeLocked => '???';

  @override
  String get recipeHint => 'Combine specific monsters to unlock hidden ones!';

  @override
  String get recipeMatch => 'Recipe found!';

  @override
  String get seasonPassTitle => 'Season Pass';

  @override
  String seasonPassLevel(int level) {
    return 'Lv.$level';
  }

  @override
  String seasonPassDaysLeft(int days) {
    return '$days days left';
  }

  @override
  String get seasonPassFree => 'Claim';

  @override
  String get seasonPassPremium => 'Claim';

  @override
  String get seasonPassPremiumActive => 'Premium';

  @override
  String get seasonPassPremiumBuy => 'Premium Locked';

  @override
  String get seasonPassPremiumBadge => 'PREMIUM';

  @override
  String get trainingTitle => 'Training';

  @override
  String get trainingDesc =>
      'Place monsters to gain XP automatically over time';

  @override
  String get trainingEmpty => 'Place a monster';

  @override
  String get trainingSelectMonster => 'Select monster to train';

  @override
  String get trainingDuration => 'Select training duration';

  @override
  String get trainingComplete => 'Complete!';

  @override
  String get trainingRemaining => 'remaining';

  @override
  String get trainingCollect => 'Collect';

  @override
  String get trainingCancel => 'Cancel';

  @override
  String get trainingNoMonsters => 'No available monsters';

  @override
  String get leaderboardTitle => 'Ranking';

  @override
  String get leaderboardArena => 'Arena';

  @override
  String get leaderboardDungeon => 'Dungeon';

  @override
  String get leaderboardTower => 'Tower';

  @override
  String get leaderboardBoss => 'World Boss';

  @override
  String get leaderboardMyRank => 'My Rank';

  @override
  String get leaderboardPlayers => 'players';

  @override
  String get titleScreenTitle => 'Titles';

  @override
  String get titleCurrent => 'Current Title';

  @override
  String get titleNone => 'No Title';

  @override
  String get titleHidden => 'Complete hidden achievements to unlock';

  @override
  String get titleEquip => 'Equip';

  @override
  String get titleUnequip => 'Unequip';

  @override
  String get mailboxTitle => 'Mailbox';

  @override
  String get mailboxEmpty => 'No mail';

  @override
  String get mailboxClaim => 'Claim';

  @override
  String get mailboxClaimed => 'Claimed';

  @override
  String get mailboxClaimAll => 'Claim All';

  @override
  String get shopTitle => 'Shop';

  @override
  String get shopExchange => 'Currency Exchange';

  @override
  String get shopItems => 'Buy Items';

  @override
  String get shopBuy => 'Buy';

  @override
  String get shopBuyGold => 'Buy Gold';

  @override
  String get shopBuyDiamond => 'Buy Diamond';

  @override
  String get shopBuyTicket => 'Summon Ticket x1';

  @override
  String get shopBuyTicketDesc => 'Buy 1 ticket for 30 diamonds';

  @override
  String get shopBuyTicket10 => 'Summon Ticket x10';

  @override
  String get shopBuyTicket10Desc => 'Buy 10 tickets for 250 diamonds (17% off)';

  @override
  String get shopBuyExpPotion => 'EXP Potion x1';

  @override
  String get shopBuyExpPotionDesc => 'Buy 1 potion for 500 gold';

  @override
  String get shopBuyExpPotion10 => 'EXP Potion x10';

  @override
  String get shopBuyExpPotion10Desc =>
      'Buy 10 potions for 4,000 gold (20% off)';

  @override
  String get shopInsufficient => 'Not enough currency';

  @override
  String get shopPurchaseSuccess => 'Purchase complete!';

  @override
  String get repeatBattle => 'Repeat';

  @override
  String get nicknameTitle => 'Set Nickname';

  @override
  String get nicknameReset => 'Reset';

  @override
  String get dailyDungeonTitle => 'Daily Dungeon';

  @override
  String get dailyDungeonTheme => 'Dungeon';

  @override
  String get dailyDungeonDesc => 'Element-themed daily dungeon. 1.5x rewards!';

  @override
  String get dailyDungeonRemaining => 'Attempts left';

  @override
  String get dailyDungeonStart => 'Enter Dungeon';

  @override
  String get dailyDungeonCleared => 'Cleared!';

  @override
  String get dailyDungeonNext => 'Next Floor';

  @override
  String get dailyDungeonComplete => 'Dungeon Complete!';

  @override
  String get dailyDungeonDefeated => 'Defeated';

  @override
  String get dailyDungeonCollect => 'Collect Rewards';

  @override
  String get dailyDungeonExitConfirm => 'Collect current rewards and exit?';
}
