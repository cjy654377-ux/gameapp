import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'몬스터 수집'**
  String get appTitle;

  /// No description provided for @tabBattle.
  ///
  /// In ko, this message translates to:
  /// **'전투'**
  String get tabBattle;

  /// No description provided for @tabGacha.
  ///
  /// In ko, this message translates to:
  /// **'소환'**
  String get tabGacha;

  /// No description provided for @tabCollection.
  ///
  /// In ko, this message translates to:
  /// **'도감'**
  String get tabCollection;

  /// No description provided for @tabUpgrade.
  ///
  /// In ko, this message translates to:
  /// **'강화'**
  String get tabUpgrade;

  /// No description provided for @tabQuest.
  ///
  /// In ko, this message translates to:
  /// **'퀘스트'**
  String get tabQuest;

  /// No description provided for @tabSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get tabSettings;

  /// No description provided for @battleIdle.
  ///
  /// In ko, this message translates to:
  /// **'전투 대기'**
  String get battleIdle;

  /// No description provided for @battleFighting.
  ///
  /// In ko, this message translates to:
  /// **'전투 중...'**
  String get battleFighting;

  /// No description provided for @battleVictory.
  ///
  /// In ko, this message translates to:
  /// **'승리!'**
  String get battleVictory;

  /// No description provided for @battleDefeat.
  ///
  /// In ko, this message translates to:
  /// **'패배'**
  String get battleDefeat;

  /// No description provided for @battleAutoMode.
  ///
  /// In ko, this message translates to:
  /// **'자동'**
  String get battleAutoMode;

  /// No description provided for @battleSpeed.
  ///
  /// In ko, this message translates to:
  /// **'속도'**
  String get battleSpeed;

  /// No description provided for @battleStart.
  ///
  /// In ko, this message translates to:
  /// **'전투 시작'**
  String get battleStart;

  /// No description provided for @battleRetreat.
  ///
  /// In ko, this message translates to:
  /// **'철수'**
  String get battleRetreat;

  /// No description provided for @retreatConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'전투 철수'**
  String get retreatConfirmTitle;

  /// No description provided for @retreatConfirmBody.
  ///
  /// In ko, this message translates to:
  /// **'전투를 포기하고 돌아갑니다.\n보상은 지급되지 않습니다.'**
  String get retreatConfirmBody;

  /// No description provided for @retreatConfirmCancel.
  ///
  /// In ko, this message translates to:
  /// **'계속하기'**
  String get retreatConfirmCancel;

  /// No description provided for @battleStageId.
  ///
  /// In ko, this message translates to:
  /// **'스테이지 {id}'**
  String battleStageId(String id);

  /// No description provided for @battleStandby.
  ///
  /// In ko, this message translates to:
  /// **'전투 대기중'**
  String get battleStandby;

  /// No description provided for @ourTeam.
  ///
  /// In ko, this message translates to:
  /// **'우리 팀'**
  String get ourTeam;

  /// No description provided for @enemyTeam.
  ///
  /// In ko, this message translates to:
  /// **'적 팀'**
  String get enemyTeam;

  /// No description provided for @turnN.
  ///
  /// In ko, this message translates to:
  /// **'턴 {n}'**
  String turnN(int n);

  /// No description provided for @battleLog.
  ///
  /// In ko, this message translates to:
  /// **'전투 로그'**
  String get battleLog;

  /// No description provided for @battleLogCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String battleLogCount(int count);

  /// No description provided for @noBattleLog.
  ///
  /// In ko, this message translates to:
  /// **'전투 기록이 없습니다'**
  String get noBattleLog;

  /// No description provided for @criticalHit.
  ///
  /// In ko, this message translates to:
  /// **'[치명타] '**
  String get criticalHit;

  /// No description provided for @elementAdvantage.
  ///
  /// In ko, this message translates to:
  /// **'[속성유리] '**
  String get elementAdvantage;

  /// No description provided for @autoOn.
  ///
  /// In ko, this message translates to:
  /// **'자동전투 ON'**
  String get autoOn;

  /// No description provided for @autoOff.
  ///
  /// In ko, this message translates to:
  /// **'자동전투 OFF'**
  String get autoOff;

  /// No description provided for @autoShortOn.
  ///
  /// In ko, this message translates to:
  /// **'자동 ON'**
  String get autoShortOn;

  /// No description provided for @autoShortOff.
  ///
  /// In ko, this message translates to:
  /// **'자동 OFF'**
  String get autoShortOff;

  /// No description provided for @preparing.
  ///
  /// In ko, this message translates to:
  /// **'준비중'**
  String get preparing;

  /// No description provided for @fighting.
  ///
  /// In ko, this message translates to:
  /// **'전투중'**
  String get fighting;

  /// No description provided for @reward.
  ///
  /// In ko, this message translates to:
  /// **'보상 받기'**
  String get reward;

  /// No description provided for @retry.
  ///
  /// In ko, this message translates to:
  /// **'재도전'**
  String get retry;

  /// No description provided for @preparingBattle.
  ///
  /// In ko, this message translates to:
  /// **'준비 중...'**
  String get preparingBattle;

  /// No description provided for @collectingReward.
  ///
  /// In ko, this message translates to:
  /// **'보상을 집계 중입니다...'**
  String get collectingReward;

  /// No description provided for @showStats.
  ///
  /// In ko, this message translates to:
  /// **'전투 통계 보기'**
  String get showStats;

  /// No description provided for @hideStats.
  ///
  /// In ko, this message translates to:
  /// **'통계 접기'**
  String get hideStats;

  /// No description provided for @earnedReward.
  ///
  /// In ko, this message translates to:
  /// **'획득 보상'**
  String get earnedReward;

  /// No description provided for @totalDamage.
  ///
  /// In ko, this message translates to:
  /// **'총 데미지'**
  String get totalDamage;

  /// No description provided for @critCount.
  ///
  /// In ko, this message translates to:
  /// **'치명타'**
  String get critCount;

  /// No description provided for @skillCount.
  ///
  /// In ko, this message translates to:
  /// **'스킬'**
  String get skillCount;

  /// No description provided for @standby.
  ///
  /// In ko, this message translates to:
  /// **'대기'**
  String get standby;

  /// No description provided for @stageSelect.
  ///
  /// In ko, this message translates to:
  /// **'스테이지 선택'**
  String get stageSelect;

  /// No description provided for @areaForest.
  ///
  /// In ko, this message translates to:
  /// **'시작의 숲'**
  String get areaForest;

  /// No description provided for @areaVolcano.
  ///
  /// In ko, this message translates to:
  /// **'불꽃 화산'**
  String get areaVolcano;

  /// No description provided for @areaDungeon.
  ///
  /// In ko, this message translates to:
  /// **'암흑 던전'**
  String get areaDungeon;

  /// No description provided for @areaTemple.
  ///
  /// In ko, this message translates to:
  /// **'심해 신전'**
  String get areaTemple;

  /// No description provided for @areaSky.
  ///
  /// In ko, this message translates to:
  /// **'천공 성역'**
  String get areaSky;

  /// No description provided for @gachaSinglePull.
  ///
  /// In ko, this message translates to:
  /// **'1회 소환'**
  String get gachaSinglePull;

  /// No description provided for @gachaTenPull.
  ///
  /// In ko, this message translates to:
  /// **'10연 소환'**
  String get gachaTenPull;

  /// No description provided for @gachaPity.
  ///
  /// In ko, this message translates to:
  /// **'천장: {count}/80'**
  String gachaPity(int count);

  /// No description provided for @gachaTitle.
  ///
  /// In ko, this message translates to:
  /// **'몬스터 소환'**
  String get gachaTitle;

  /// No description provided for @gachaDesc.
  ///
  /// In ko, this message translates to:
  /// **'강력한 몬스터를 소환하여 팀을 강화하세요!'**
  String get gachaDesc;

  /// No description provided for @gachaLegendaryUp.
  ///
  /// In ko, this message translates to:
  /// **'★ 전설 등급 확률 UP ★'**
  String get gachaLegendaryUp;

  /// No description provided for @gachaUntilLegend.
  ///
  /// In ko, this message translates to:
  /// **'전설 확정까지'**
  String get gachaUntilLegend;

  /// No description provided for @gachaRemainingCount.
  ///
  /// In ko, this message translates to:
  /// **'남은 횟수: {count}회'**
  String gachaRemainingCount(int count);

  /// No description provided for @gachaNextGuaranteed.
  ///
  /// In ko, this message translates to:
  /// **'다음 소환 시 전설 확정!'**
  String get gachaNextGuaranteed;

  /// No description provided for @gachaRates.
  ///
  /// In ko, this message translates to:
  /// **'소환 확률'**
  String get gachaRates;

  /// No description provided for @gachaThreeStarGuarantee.
  ///
  /// In ko, this message translates to:
  /// **'3★ 이상 1회 보장'**
  String get gachaThreeStarGuarantee;

  /// No description provided for @gachaDiamondShort.
  ///
  /// In ko, this message translates to:
  /// **'다이아가 부족합니다'**
  String get gachaDiamondShort;

  /// No description provided for @gachaTicketShort.
  ///
  /// In ko, this message translates to:
  /// **'소환권이 부족합니다'**
  String get gachaTicketShort;

  /// No description provided for @gachaUseTicket.
  ///
  /// In ko, this message translates to:
  /// **'소환권 사용'**
  String get gachaUseTicket;

  /// No description provided for @gachaTicketCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}장'**
  String gachaTicketCount(int count);

  /// No description provided for @gachaResultSingle.
  ///
  /// In ko, this message translates to:
  /// **'소환 결과'**
  String get gachaResultSingle;

  /// No description provided for @gachaResultTen.
  ///
  /// In ko, this message translates to:
  /// **'10연 소환 결과'**
  String get gachaResultTen;

  /// No description provided for @gachaRevealAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 공개'**
  String get gachaRevealAll;

  /// No description provided for @gachaGuaranteed.
  ///
  /// In ko, this message translates to:
  /// **'확정!'**
  String get gachaGuaranteed;

  /// No description provided for @monsterLevel.
  ///
  /// In ko, this message translates to:
  /// **'Lv.{level}'**
  String monsterLevel(int level);

  /// No description provided for @monsterCollection.
  ///
  /// In ko, this message translates to:
  /// **'몬스터 도감'**
  String get monsterCollection;

  /// No description provided for @ownedOnly.
  ///
  /// In ko, this message translates to:
  /// **'보유만'**
  String get ownedOnly;

  /// No description provided for @reset.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get reset;

  /// No description provided for @noMatchingMonster.
  ///
  /// In ko, this message translates to:
  /// **'조건에 맞는 몬스터가 없습니다'**
  String get noMatchingMonster;

  /// No description provided for @ownedCount.
  ///
  /// In ko, this message translates to:
  /// **'보유: {count}마리'**
  String ownedCount(int count);

  /// No description provided for @bestUnit.
  ///
  /// In ko, this message translates to:
  /// **'최고 개체 (Lv.{level})'**
  String bestUnit(int level);

  /// No description provided for @unownedMonster.
  ///
  /// In ko, this message translates to:
  /// **'미획득 몬스터'**
  String get unownedMonster;

  /// No description provided for @teamEdit.
  ///
  /// In ko, this message translates to:
  /// **'팀 편성'**
  String get teamEdit;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @totalPower.
  ///
  /// In ko, this message translates to:
  /// **'총 전투력: {power}'**
  String totalPower(String power);

  /// No description provided for @noMonsterOwned.
  ///
  /// In ko, this message translates to:
  /// **'보유한 몬스터가 없습니다'**
  String get noMonsterOwned;

  /// No description provided for @getMonsterFromGacha.
  ///
  /// In ko, this message translates to:
  /// **'소환에서 몬스터를 획득하세요'**
  String get getMonsterFromGacha;

  /// No description provided for @milestoneReward.
  ///
  /// In ko, this message translates to:
  /// **'{label} 보상 수령! 골드 +{gold}, 다이아 +{diamond}'**
  String milestoneReward(String label, int gold, int diamond);

  /// No description provided for @upgradeLevelUp.
  ///
  /// In ko, this message translates to:
  /// **'레벨업'**
  String get upgradeLevelUp;

  /// No description provided for @upgradeEvolution.
  ///
  /// In ko, this message translates to:
  /// **'진화'**
  String get upgradeEvolution;

  /// No description provided for @upgradeFusion.
  ///
  /// In ko, this message translates to:
  /// **'융합'**
  String get upgradeFusion;

  /// No description provided for @upgradeAwakening.
  ///
  /// In ko, this message translates to:
  /// **'각성'**
  String get upgradeAwakening;

  /// No description provided for @selectMonsterToUpgrade.
  ///
  /// In ko, this message translates to:
  /// **'강화할 몬스터 선택'**
  String get selectMonsterToUpgrade;

  /// No description provided for @maxLevelReached.
  ///
  /// In ko, this message translates to:
  /// **'최대 레벨 도달! (Lv.{level})'**
  String maxLevelReached(int level);

  /// No description provided for @levelUpPreview.
  ///
  /// In ko, this message translates to:
  /// **'레벨 업 시'**
  String get levelUpPreview;

  /// No description provided for @levelUpWithGold.
  ///
  /// In ko, this message translates to:
  /// **'골드로 레벨 업'**
  String get levelUpWithGold;

  /// No description provided for @goldShort.
  ///
  /// In ko, this message translates to:
  /// **'골드가 부족합니다'**
  String get goldShort;

  /// No description provided for @expPotion.
  ///
  /// In ko, this message translates to:
  /// **'경험치 물약'**
  String get expPotion;

  /// No description provided for @expPotionOwned.
  ///
  /// In ko, this message translates to:
  /// **'보유: {count}개  (개당 {exp} EXP)'**
  String expPotionOwned(int count, int exp);

  /// No description provided for @potionUse1.
  ///
  /// In ko, this message translates to:
  /// **'1개'**
  String get potionUse1;

  /// No description provided for @potionUse5.
  ///
  /// In ko, this message translates to:
  /// **'5개'**
  String get potionUse5;

  /// No description provided for @potionUse10.
  ///
  /// In ko, this message translates to:
  /// **'10개'**
  String get potionUse10;

  /// No description provided for @potionUseAll.
  ///
  /// In ko, this message translates to:
  /// **'전부'**
  String get potionUseAll;

  /// No description provided for @expPotionShort.
  ///
  /// In ko, this message translates to:
  /// **'경험치 물약이 부족합니다'**
  String get expPotionShort;

  /// No description provided for @finalEvolutionDone.
  ///
  /// In ko, this message translates to:
  /// **'최종 진화 완료!'**
  String get finalEvolutionDone;

  /// No description provided for @evolutionPreview.
  ///
  /// In ko, this message translates to:
  /// **'진화 시'**
  String get evolutionPreview;

  /// No description provided for @firstEvolution.
  ///
  /// In ko, this message translates to:
  /// **'1차 진화'**
  String get firstEvolution;

  /// No description provided for @finalEvolution.
  ///
  /// In ko, this message translates to:
  /// **'최종 진화'**
  String get finalEvolution;

  /// No description provided for @evolve.
  ///
  /// In ko, this message translates to:
  /// **'진화하기'**
  String get evolve;

  /// No description provided for @materialShort.
  ///
  /// In ko, this message translates to:
  /// **'재료가 부족합니다'**
  String get materialShort;

  /// No description provided for @fusionLegendaryLimit.
  ///
  /// In ko, this message translates to:
  /// **'전설 등급은 융합할 수 없습니다'**
  String get fusionLegendaryLimit;

  /// No description provided for @fusionTeamLimit.
  ///
  /// In ko, this message translates to:
  /// **'팀에 배치된 몬스터는 융합할 수 없습니다'**
  String get fusionTeamLimit;

  /// No description provided for @fusionDesc.
  ///
  /// In ko, this message translates to:
  /// **'같은 등급 몬스터 2마리를 융합하여\n{stars} {rarity} 등급 몬스터를 획득합니다'**
  String fusionDesc(String stars, String rarity);

  /// No description provided for @material1.
  ///
  /// In ko, this message translates to:
  /// **'소재 1'**
  String get material1;

  /// No description provided for @material2.
  ///
  /// In ko, this message translates to:
  /// **'소재 2'**
  String get material2;

  /// No description provided for @selectMaterial2.
  ///
  /// In ko, this message translates to:
  /// **'소재 2 선택'**
  String get selectMaterial2;

  /// No description provided for @fusionCost.
  ///
  /// In ko, this message translates to:
  /// **'융합 비용'**
  String get fusionCost;

  /// No description provided for @fusionExecute.
  ///
  /// In ko, this message translates to:
  /// **'융합하기'**
  String get fusionExecute;

  /// No description provided for @fusionFormula.
  ///
  /// In ko, this message translates to:
  /// **'{from}성 + {from}성 → {to}성'**
  String fusionFormula(int from, int to);

  /// No description provided for @fusionCheckCondition.
  ///
  /// In ko, this message translates to:
  /// **'융합 조건을 확인하세요'**
  String get fusionCheckCondition;

  /// No description provided for @noFusionMaterial.
  ///
  /// In ko, this message translates to:
  /// **'같은 등급의 융합 가능한 몬스터가 없습니다'**
  String get noFusionMaterial;

  /// No description provided for @selectFusionMaterial.
  ///
  /// In ko, this message translates to:
  /// **'융합 소재 선택'**
  String get selectFusionMaterial;

  /// No description provided for @basic.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get basic;

  /// No description provided for @firstEvo.
  ///
  /// In ko, this message translates to:
  /// **'1차 진화'**
  String get firstEvo;

  /// No description provided for @finalEvo.
  ///
  /// In ko, this message translates to:
  /// **'최종 진화'**
  String get finalEvo;

  /// No description provided for @evolutionMaterial.
  ///
  /// In ko, this message translates to:
  /// **'진화 재료'**
  String get evolutionMaterial;

  /// No description provided for @evolutionStone.
  ///
  /// In ko, this message translates to:
  /// **'진화석'**
  String get evolutionStone;

  /// No description provided for @awakeningRequireEvo.
  ///
  /// In ko, this message translates to:
  /// **'최종 진화 후 각성할 수 있습니다'**
  String get awakeningRequireEvo;

  /// No description provided for @awakeningMaxDone.
  ///
  /// In ko, this message translates to:
  /// **'최대 각성 완료!'**
  String get awakeningMaxDone;

  /// No description provided for @awakeningCostTitle.
  ///
  /// In ko, this message translates to:
  /// **'각성 {star}성 비용'**
  String awakeningCostTitle(int star);

  /// No description provided for @shardCost.
  ///
  /// In ko, this message translates to:
  /// **'{count} 진화석'**
  String shardCost(int count);

  /// No description provided for @awakening.
  ///
  /// In ko, this message translates to:
  /// **'각성하기'**
  String get awakening;

  /// No description provided for @awakeningInProgress.
  ///
  /// In ko, this message translates to:
  /// **'각성 중...'**
  String get awakeningInProgress;

  /// No description provided for @currentAwakeningBonus.
  ///
  /// In ko, this message translates to:
  /// **'현재 각성 보너스: +{bonus}%'**
  String currentAwakeningBonus(int bonus);

  /// No description provided for @nextAwakeningBonus.
  ///
  /// In ko, this message translates to:
  /// **'다음 각성 보너스: +{bonus}%'**
  String nextAwakeningBonus(int bonus);

  /// No description provided for @questDaily.
  ///
  /// In ko, this message translates to:
  /// **'일일'**
  String get questDaily;

  /// No description provided for @questWeekly.
  ///
  /// In ko, this message translates to:
  /// **'주간'**
  String get questWeekly;

  /// No description provided for @questAchievement.
  ///
  /// In ko, this message translates to:
  /// **'업적'**
  String get questAchievement;

  /// No description provided for @questClaim.
  ///
  /// In ko, this message translates to:
  /// **'수령'**
  String get questClaim;

  /// No description provided for @questNoQuests.
  ///
  /// In ko, this message translates to:
  /// **'퀘스트가 없습니다'**
  String get questNoQuests;

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어 / Language'**
  String get settingsLanguage;

  /// No description provided for @settingsSound.
  ///
  /// In ko, this message translates to:
  /// **'진동 효과'**
  String get settingsSound;

  /// No description provided for @settingsEffects.
  ///
  /// In ko, this message translates to:
  /// **'효과'**
  String get settingsEffects;

  /// No description provided for @settingsBackup.
  ///
  /// In ko, this message translates to:
  /// **'데이터 백업'**
  String get settingsBackup;

  /// No description provided for @settingsRestore.
  ///
  /// In ko, this message translates to:
  /// **'데이터 복원'**
  String get settingsRestore;

  /// No description provided for @settingsPrestige.
  ///
  /// In ko, this message translates to:
  /// **'전생 (프레스티지)'**
  String get settingsPrestige;

  /// No description provided for @settingsPlayerInfo.
  ///
  /// In ko, this message translates to:
  /// **'플레이어 정보'**
  String get settingsPlayerInfo;

  /// No description provided for @settingsNickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get settingsNickname;

  /// No description provided for @settingsLevel.
  ///
  /// In ko, this message translates to:
  /// **'레벨'**
  String get settingsLevel;

  /// No description provided for @settingsCurrentStage.
  ///
  /// In ko, this message translates to:
  /// **'현재 스테이지'**
  String get settingsCurrentStage;

  /// No description provided for @settingsBattleCount.
  ///
  /// In ko, this message translates to:
  /// **'전투 횟수'**
  String get settingsBattleCount;

  /// No description provided for @settingsGachaCount.
  ///
  /// In ko, this message translates to:
  /// **'소환 횟수'**
  String get settingsGachaCount;

  /// No description provided for @settingsPrestigeLevel.
  ///
  /// In ko, this message translates to:
  /// **'전생 레벨'**
  String get settingsPrestigeLevel;

  /// No description provided for @settingsGameInfo.
  ///
  /// In ko, this message translates to:
  /// **'게임 정보'**
  String get settingsGameInfo;

  /// No description provided for @settingsVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전'**
  String get settingsVersion;

  /// No description provided for @settingsOwnedMonster.
  ///
  /// In ko, this message translates to:
  /// **'보유 몬스터'**
  String get settingsOwnedMonster;

  /// No description provided for @settingsRelicEquip.
  ///
  /// In ko, this message translates to:
  /// **'유물/장비'**
  String get settingsRelicEquip;

  /// No description provided for @settingsRelicManage.
  ///
  /// In ko, this message translates to:
  /// **'유물 관리'**
  String get settingsRelicManage;

  /// No description provided for @settingsPrestigeGo.
  ///
  /// In ko, this message translates to:
  /// **'전생 화면으로'**
  String get settingsPrestigeGo;

  /// No description provided for @settingsBackupRestore.
  ///
  /// In ko, this message translates to:
  /// **'백업 / 복원'**
  String get settingsBackupRestore;

  /// No description provided for @settingsBackupCopy.
  ///
  /// In ko, this message translates to:
  /// **'백업 (복사)'**
  String get settingsBackupCopy;

  /// No description provided for @settingsRestorePaste.
  ///
  /// In ko, this message translates to:
  /// **'복원 (붙여넣기)'**
  String get settingsRestorePaste;

  /// No description provided for @settingsData.
  ///
  /// In ko, this message translates to:
  /// **'데이터'**
  String get settingsData;

  /// No description provided for @settingsGameReset.
  ///
  /// In ko, this message translates to:
  /// **'게임 초기화'**
  String get settingsGameReset;

  /// No description provided for @settingsBackupDone.
  ///
  /// In ko, this message translates to:
  /// **'게임 데이터가 클립보드에 복사되었습니다'**
  String get settingsBackupDone;

  /// No description provided for @settingsRestoreTitle.
  ///
  /// In ko, this message translates to:
  /// **'데이터 복원'**
  String get settingsRestoreTitle;

  /// No description provided for @settingsRestoreDesc.
  ///
  /// In ko, this message translates to:
  /// **'클립보드의 백업 데이터로 복원합니다.\n현재 데이터는 모두 덮어씌워집니다.\n계속하시겠습니까?'**
  String get settingsRestoreDesc;

  /// No description provided for @settingsNoClipboard.
  ///
  /// In ko, this message translates to:
  /// **'클립보드에 데이터가 없습니다'**
  String get settingsNoClipboard;

  /// No description provided for @settingsRestoreDone.
  ///
  /// In ko, this message translates to:
  /// **'데이터 복원 완료!'**
  String get settingsRestoreDone;

  /// No description provided for @settingsRestoreFail.
  ///
  /// In ko, this message translates to:
  /// **'복원 실패: 올바른 백업 데이터가 아닙니다'**
  String get settingsRestoreFail;

  /// No description provided for @settingsResetTitle.
  ///
  /// In ko, this message translates to:
  /// **'게임 초기화'**
  String get settingsResetTitle;

  /// No description provided for @settingsResetDesc.
  ///
  /// In ko, this message translates to:
  /// **'모든 데이터가 삭제됩니다.\n정말로 초기화하시겠습니까?'**
  String get settingsResetDesc;

  /// No description provided for @settingsResetConfirm.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get settingsResetConfirm;

  /// No description provided for @restore.
  ///
  /// In ko, this message translates to:
  /// **'복원'**
  String get restore;

  /// No description provided for @gold.
  ///
  /// In ko, this message translates to:
  /// **'골드'**
  String get gold;

  /// No description provided for @diamond.
  ///
  /// In ko, this message translates to:
  /// **'다이아'**
  String get diamond;

  /// No description provided for @diamondFull.
  ///
  /// In ko, this message translates to:
  /// **'다이아몬드'**
  String get diamondFull;

  /// No description provided for @gachaTicket.
  ///
  /// In ko, this message translates to:
  /// **'소환권'**
  String get gachaTicket;

  /// No description provided for @monsterShard.
  ///
  /// In ko, this message translates to:
  /// **'몬스터 파편'**
  String get monsterShard;

  /// No description provided for @confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// No description provided for @back.
  ///
  /// In ko, this message translates to:
  /// **'뒤로'**
  String get back;

  /// No description provided for @next.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get next;

  /// No description provided for @infiniteDungeon.
  ///
  /// In ko, this message translates to:
  /// **'무한 던전'**
  String get infiniteDungeon;

  /// No description provided for @dungeonFloor.
  ///
  /// In ko, this message translates to:
  /// **'{floor}층'**
  String dungeonFloor(int floor);

  /// No description provided for @dungeonBest.
  ///
  /// In ko, this message translates to:
  /// **'최고 {floor}층'**
  String dungeonBest(int floor);

  /// No description provided for @dungeonPreparing.
  ///
  /// In ko, this message translates to:
  /// **'던전을 준비 중...'**
  String get dungeonPreparing;

  /// No description provided for @dungeonLog.
  ///
  /// In ko, this message translates to:
  /// **'던전 로그'**
  String get dungeonLog;

  /// No description provided for @dungeonStart.
  ///
  /// In ko, this message translates to:
  /// **'던전 시작'**
  String get dungeonStart;

  /// No description provided for @dungeonNextFloor.
  ///
  /// In ko, this message translates to:
  /// **'다음 층'**
  String get dungeonNextFloor;

  /// No description provided for @dungeonCollect.
  ///
  /// In ko, this message translates to:
  /// **'보상 수령'**
  String get dungeonCollect;

  /// No description provided for @dungeonCollectFloor.
  ///
  /// In ko, this message translates to:
  /// **'보상 수령 ({floor}층 도달)'**
  String dungeonCollectFloor(int floor);

  /// No description provided for @floorCleared.
  ///
  /// In ko, this message translates to:
  /// **'클리어!'**
  String get floorCleared;

  /// No description provided for @worldBoss.
  ///
  /// In ko, this message translates to:
  /// **'월드 보스'**
  String get worldBoss;

  /// No description provided for @worldBossName.
  ///
  /// In ko, this message translates to:
  /// **'월드 보스 - {name}'**
  String worldBossName(String name);

  /// No description provided for @worldBossElement.
  ///
  /// In ko, this message translates to:
  /// **'속성: {element}'**
  String worldBossElement(String element);

  /// No description provided for @remainingAttempts.
  ///
  /// In ko, this message translates to:
  /// **'남은 도전 횟수'**
  String get remainingAttempts;

  /// No description provided for @turnLimit.
  ///
  /// In ko, this message translates to:
  /// **'턴 제한'**
  String get turnLimit;

  /// No description provided for @turnCount.
  ///
  /// In ko, this message translates to:
  /// **'{n}턴'**
  String turnCount(int n);

  /// No description provided for @bestDamage.
  ///
  /// In ko, this message translates to:
  /// **'최고 데미지'**
  String get bestDamage;

  /// No description provided for @challenge.
  ///
  /// In ko, this message translates to:
  /// **'도전하기'**
  String get challenge;

  /// No description provided for @challengeDone.
  ///
  /// In ko, this message translates to:
  /// **'오늘 도전 완료'**
  String get challengeDone;

  /// No description provided for @turnProgress.
  ///
  /// In ko, this message translates to:
  /// **'턴 {current}/{max}'**
  String turnProgress(int current, int max);

  /// No description provided for @totalDamageAmount.
  ///
  /// In ko, this message translates to:
  /// **'총 데미지: {damage}'**
  String totalDamageAmount(String damage);

  /// No description provided for @nextTurn.
  ///
  /// In ko, this message translates to:
  /// **'다음 턴'**
  String get nextTurn;

  /// No description provided for @bossKilled.
  ///
  /// In ko, this message translates to:
  /// **'보스 처치!'**
  String get bossKilled;

  /// No description provided for @battleEnd.
  ///
  /// In ko, this message translates to:
  /// **'전투 종료!'**
  String get battleEnd;

  /// No description provided for @rewardSection.
  ///
  /// In ko, this message translates to:
  /// **'보상'**
  String get rewardSection;

  /// No description provided for @collectReward.
  ///
  /// In ko, this message translates to:
  /// **'보상 수령'**
  String get collectReward;

  /// No description provided for @goBack.
  ///
  /// In ko, this message translates to:
  /// **'돌아가기'**
  String get goBack;

  /// No description provided for @arena.
  ///
  /// In ko, this message translates to:
  /// **'PvP 아레나'**
  String get arena;

  /// No description provided for @arenaShort.
  ///
  /// In ko, this message translates to:
  /// **'아레나'**
  String get arenaShort;

  /// No description provided for @arenaEasy.
  ///
  /// In ko, this message translates to:
  /// **'쉬움'**
  String get arenaEasy;

  /// No description provided for @arenaNormal.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get arenaNormal;

  /// No description provided for @arenaHard.
  ///
  /// In ko, this message translates to:
  /// **'어려움'**
  String get arenaHard;

  /// No description provided for @arenaRefresh.
  ///
  /// In ko, this message translates to:
  /// **'상대 갱신'**
  String get arenaRefresh;

  /// No description provided for @arenaChampion.
  ///
  /// In ko, this message translates to:
  /// **'챔피언'**
  String get arenaChampion;

  /// No description provided for @arenaDiamond.
  ///
  /// In ko, this message translates to:
  /// **'다이아몬드'**
  String get arenaDiamond;

  /// No description provided for @arenaGold.
  ///
  /// In ko, this message translates to:
  /// **'골드'**
  String get arenaGold;

  /// No description provided for @arenaSilver.
  ///
  /// In ko, this message translates to:
  /// **'실버'**
  String get arenaSilver;

  /// No description provided for @arenaBronze.
  ///
  /// In ko, this message translates to:
  /// **'브론즈'**
  String get arenaBronze;

  /// No description provided for @arenaRankScore.
  ///
  /// In ko, this message translates to:
  /// **'{rank} · {score}점'**
  String arenaRankScore(String rank, int score);

  /// No description provided for @arenaRecord.
  ///
  /// In ko, this message translates to:
  /// **'{wins}승 {losses}패'**
  String arenaRecord(int wins, int losses);

  /// No description provided for @arenaRemaining.
  ///
  /// In ko, this message translates to:
  /// **'남은 도전: {remaining}/{max}'**
  String arenaRemaining(int remaining, int max);

  /// No description provided for @arenaRating.
  ///
  /// In ko, this message translates to:
  /// **'레이팅 {rating}'**
  String arenaRating(int rating);

  /// No description provided for @arenaChallenge.
  ///
  /// In ko, this message translates to:
  /// **'도전'**
  String get arenaChallenge;

  /// No description provided for @me.
  ///
  /// In ko, this message translates to:
  /// **'나'**
  String get me;

  /// No description provided for @opponent.
  ///
  /// In ko, this message translates to:
  /// **'상대'**
  String get opponent;

  /// No description provided for @battleWaiting.
  ///
  /// In ko, this message translates to:
  /// **'전투 대기 중...'**
  String get battleWaiting;

  /// No description provided for @ratingLabel.
  ///
  /// In ko, this message translates to:
  /// **'레이팅'**
  String get ratingLabel;

  /// No description provided for @eventDungeon.
  ///
  /// In ko, this message translates to:
  /// **'이벤트 던전'**
  String get eventDungeon;

  /// No description provided for @eventDungeonShort.
  ///
  /// In ko, this message translates to:
  /// **'이벤트'**
  String get eventDungeonShort;

  /// No description provided for @eventLoading.
  ///
  /// In ko, this message translates to:
  /// **'이벤트 로딩 중...'**
  String get eventLoading;

  /// No description provided for @eventLimited.
  ///
  /// In ko, this message translates to:
  /// **'기간 한정 이벤트'**
  String get eventLimited;

  /// No description provided for @eventWeeklyDesc.
  ///
  /// In ko, this message translates to:
  /// **'매주 새로운 이벤트가 열립니다!'**
  String get eventWeeklyDesc;

  /// No description provided for @eventRecommendLevel.
  ///
  /// In ko, this message translates to:
  /// **'추천 Lv.{level}'**
  String eventRecommendLevel(int level);

  /// No description provided for @eventWaves.
  ///
  /// In ko, this message translates to:
  /// **'{count}웨이브'**
  String eventWaves(int count);

  /// No description provided for @eventTimeRemain.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 {mins}분 남음'**
  String eventTimeRemain(int hours, int mins);

  /// No description provided for @eventChallenge.
  ///
  /// In ko, this message translates to:
  /// **'도전'**
  String get eventChallenge;

  /// No description provided for @eventCleared.
  ///
  /// In ko, this message translates to:
  /// **'클리어 완료'**
  String get eventCleared;

  /// No description provided for @eventWaveProgress.
  ///
  /// In ko, this message translates to:
  /// **'{name} - 웨이브 {current}/{total}'**
  String eventWaveProgress(String name, int current, int total);

  /// No description provided for @waveCleared.
  ///
  /// In ko, this message translates to:
  /// **'웨이브 {wave} 클리어!'**
  String waveCleared(int wave);

  /// No description provided for @nextWave.
  ///
  /// In ko, this message translates to:
  /// **'다음 웨이브: {current}/{total}'**
  String nextWave(int current, int total);

  /// No description provided for @nextWaveBtn.
  ///
  /// In ko, this message translates to:
  /// **'다음 웨이브'**
  String get nextWaveBtn;

  /// No description provided for @eventClear.
  ///
  /// In ko, this message translates to:
  /// **'이벤트 클리어!'**
  String get eventClear;

  /// No description provided for @guild.
  ///
  /// In ko, this message translates to:
  /// **'길드'**
  String get guild;

  /// No description provided for @guildCreate.
  ///
  /// In ko, this message translates to:
  /// **'길드 생성'**
  String get guildCreate;

  /// No description provided for @guildCreateDesc.
  ///
  /// In ko, this message translates to:
  /// **'길드를 만들고 동료들과 함께\n강력한 보스를 처치하세요!'**
  String get guildCreateDesc;

  /// No description provided for @guildNameHint.
  ///
  /// In ko, this message translates to:
  /// **'길드 이름 입력'**
  String get guildNameHint;

  /// No description provided for @guildLevelCoin.
  ///
  /// In ko, this message translates to:
  /// **'Lv.{level} | 코인: {coin}'**
  String guildLevelCoin(int level, int coin);

  /// No description provided for @guildMembers.
  ///
  /// In ko, this message translates to:
  /// **'길드원 ({count}명)'**
  String guildMembers(int count);

  /// No description provided for @guildLeader.
  ///
  /// In ko, this message translates to:
  /// **'나 (길드장)'**
  String get guildLeader;

  /// No description provided for @guildWeeklyBoss.
  ///
  /// In ko, this message translates to:
  /// **'주간 보스: {name}'**
  String guildWeeklyBoss(String name);

  /// No description provided for @guildBossHp.
  ///
  /// In ko, this message translates to:
  /// **'남은 HP: {current} / {max}'**
  String guildBossHp(String current, String max);

  /// No description provided for @guildMyContrib.
  ///
  /// In ko, this message translates to:
  /// **'내 기여: {damage}'**
  String guildMyContrib(String damage);

  /// No description provided for @guildAiContrib.
  ///
  /// In ko, this message translates to:
  /// **'길드원 기여: {damage}'**
  String guildAiContrib(String damage);

  /// No description provided for @guildBossDefeated.
  ///
  /// In ko, this message translates to:
  /// **'보스 처치 완료!'**
  String get guildBossDefeated;

  /// No description provided for @guildBossChallenge.
  ///
  /// In ko, this message translates to:
  /// **'보스 도전 ({remaining}/{max})'**
  String guildBossChallenge(int remaining, int max);

  /// No description provided for @guildShop.
  ///
  /// In ko, this message translates to:
  /// **'길드 상점'**
  String get guildShop;

  /// No description provided for @guildBossTurn.
  ///
  /// In ko, this message translates to:
  /// **'{name} (턴 {current}/{max})'**
  String guildBossTurn(String name, int current, int max);

  /// No description provided for @guildFightDamage.
  ///
  /// In ko, this message translates to:
  /// **'이번 전투 데미지: {damage}'**
  String guildFightDamage(String damage);

  /// No description provided for @attack.
  ///
  /// In ko, this message translates to:
  /// **'공격'**
  String get attack;

  /// No description provided for @guildBattleEnd.
  ///
  /// In ko, this message translates to:
  /// **'전투 종료!'**
  String get guildBattleEnd;

  /// No description provided for @guildDefeat.
  ///
  /// In ko, this message translates to:
  /// **'패배...'**
  String get guildDefeat;

  /// No description provided for @guildTotalDamage.
  ///
  /// In ko, this message translates to:
  /// **'총 데미지: {damage}'**
  String guildTotalDamage(String damage);

  /// No description provided for @guildEarnedCoin.
  ///
  /// In ko, this message translates to:
  /// **'획득 길드 코인: +{coin}'**
  String guildEarnedCoin(int coin);

  /// No description provided for @guildReturnLobby.
  ///
  /// In ko, this message translates to:
  /// **'로비로 돌아가기'**
  String get guildReturnLobby;

  /// No description provided for @guildCoinLabel.
  ///
  /// In ko, this message translates to:
  /// **'코인: {coin}'**
  String guildCoinLabel(int coin);

  /// No description provided for @guildItemCost.
  ///
  /// In ko, this message translates to:
  /// **'{cost} 코인'**
  String guildItemCost(int cost);

  /// No description provided for @guildPurchaseDone.
  ///
  /// In ko, this message translates to:
  /// **'{name} 구매 완료!'**
  String guildPurchaseDone(String name);

  /// No description provided for @purchase.
  ///
  /// In ko, this message translates to:
  /// **'구매'**
  String get purchase;

  /// No description provided for @expedition.
  ///
  /// In ko, this message translates to:
  /// **'원정대'**
  String get expedition;

  /// No description provided for @expeditionSlots.
  ///
  /// In ko, this message translates to:
  /// **'슬롯 {active}/{max}'**
  String expeditionSlots(int active, int max);

  /// No description provided for @expeditionActive.
  ///
  /// In ko, this message translates to:
  /// **'진행중 원정'**
  String get expeditionActive;

  /// No description provided for @expeditionNew.
  ///
  /// In ko, this message translates to:
  /// **'새 원정 시작'**
  String get expeditionNew;

  /// No description provided for @expeditionAllUsed.
  ///
  /// In ko, this message translates to:
  /// **'모든 원정 슬롯 사용 중 ({count}/{max})'**
  String expeditionAllUsed(int count, int max);

  /// No description provided for @expeditionCollect.
  ///
  /// In ko, this message translates to:
  /// **'보상 수령'**
  String get expeditionCollect;

  /// No description provided for @expeditionDepart.
  ///
  /// In ko, this message translates to:
  /// **'출발 ({count}마리)'**
  String expeditionDepart(int count);

  /// No description provided for @expeditionNoMonster.
  ///
  /// In ko, this message translates to:
  /// **'파견 가능한 몬스터가 없습니다\n(팀 배치 중이거나 이미 원정 중)'**
  String get expeditionNoMonster;

  /// No description provided for @relic.
  ///
  /// In ko, this message translates to:
  /// **'유물'**
  String get relic;

  /// No description provided for @relicCount.
  ///
  /// In ko, this message translates to:
  /// **'유물 ({count}개)'**
  String relicCount(int count);

  /// No description provided for @relicAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get relicAll;

  /// No description provided for @relicWeapon.
  ///
  /// In ko, this message translates to:
  /// **'무기'**
  String get relicWeapon;

  /// No description provided for @relicArmor.
  ///
  /// In ko, this message translates to:
  /// **'방어구'**
  String get relicArmor;

  /// No description provided for @relicAccessory.
  ///
  /// In ko, this message translates to:
  /// **'악세서리'**
  String get relicAccessory;

  /// No description provided for @relicEquipped.
  ///
  /// In ko, this message translates to:
  /// **'장착됨'**
  String get relicEquipped;

  /// No description provided for @noRelic.
  ///
  /// In ko, this message translates to:
  /// **'유물이 없습니다'**
  String get noRelic;

  /// No description provided for @getRelicFromBattle.
  ///
  /// In ko, this message translates to:
  /// **'전투와 던전에서 유물을 획득하세요'**
  String get getRelicFromBattle;

  /// No description provided for @relicStarRarity.
  ///
  /// In ko, this message translates to:
  /// **'{rarity}성'**
  String relicStarRarity(int rarity);

  /// No description provided for @relicEquippedTo.
  ///
  /// In ko, this message translates to:
  /// **'장착: {name}'**
  String relicEquippedTo(String name);

  /// No description provided for @unequip.
  ///
  /// In ko, this message translates to:
  /// **'해제'**
  String get unequip;

  /// No description provided for @selectMonsterToEquip.
  ///
  /// In ko, this message translates to:
  /// **'장착할 몬스터 선택:'**
  String get selectMonsterToEquip;

  /// No description provided for @replace.
  ///
  /// In ko, this message translates to:
  /// **'교체'**
  String get replace;

  /// No description provided for @relicDisassemble.
  ///
  /// In ko, this message translates to:
  /// **'유물 분해'**
  String get relicDisassemble;

  /// No description provided for @statAttack.
  ///
  /// In ko, this message translates to:
  /// **'공격력'**
  String get statAttack;

  /// No description provided for @statDefense.
  ///
  /// In ko, this message translates to:
  /// **'방어력'**
  String get statDefense;

  /// No description provided for @statHp.
  ///
  /// In ko, this message translates to:
  /// **'체력'**
  String get statHp;

  /// No description provided for @statSpeed.
  ///
  /// In ko, this message translates to:
  /// **'속도'**
  String get statSpeed;

  /// No description provided for @prestige.
  ///
  /// In ko, this message translates to:
  /// **'전생'**
  String get prestige;

  /// No description provided for @prestigeTitle.
  ///
  /// In ko, this message translates to:
  /// **'전생 (프레스티지)'**
  String get prestigeTitle;

  /// No description provided for @prestigeCurrentBonus.
  ///
  /// In ko, this message translates to:
  /// **'현재 전생 보너스'**
  String get prestigeCurrentBonus;

  /// No description provided for @goldGain.
  ///
  /// In ko, this message translates to:
  /// **'골드 획득량'**
  String get goldGain;

  /// No description provided for @expGain.
  ///
  /// In ko, this message translates to:
  /// **'경험치 획득량'**
  String get expGain;

  /// No description provided for @prestigeCondition.
  ///
  /// In ko, this message translates to:
  /// **'전생 조건'**
  String get prestigeCondition;

  /// No description provided for @prestigeMinLevel.
  ///
  /// In ko, this message translates to:
  /// **'플레이어 레벨 {level}+'**
  String prestigeMinLevel(int level);

  /// No description provided for @or.
  ///
  /// In ko, this message translates to:
  /// **'또는'**
  String get or;

  /// No description provided for @prestigeMinArea.
  ///
  /// In ko, this message translates to:
  /// **'{area}지역 이상 클리어'**
  String prestigeMinArea(int area);

  /// No description provided for @none.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get none;

  /// No description provided for @prestigeGains.
  ///
  /// In ko, this message translates to:
  /// **'전생 시 얻는 것'**
  String get prestigeGains;

  /// No description provided for @prestigeLosses.
  ///
  /// In ko, this message translates to:
  /// **'전생 시 초기화되는 것'**
  String get prestigeLosses;

  /// No description provided for @prestigeLossLevel.
  ///
  /// In ko, this message translates to:
  /// **'플레이어 레벨 → Lv.1'**
  String get prestigeLossLevel;

  /// No description provided for @prestigeLossStage.
  ///
  /// In ko, this message translates to:
  /// **'스테이지 진행 → 1-1'**
  String get prestigeLossStage;

  /// No description provided for @prestigeLossDungeon.
  ///
  /// In ko, this message translates to:
  /// **'던전 기록 초기화'**
  String get prestigeLossDungeon;

  /// No description provided for @prestigeLossMonster.
  ///
  /// In ko, this message translates to:
  /// **'보유 몬스터 전체 삭제'**
  String get prestigeLossMonster;

  /// No description provided for @prestigeLossGold.
  ///
  /// In ko, this message translates to:
  /// **'골드/파편/포션 초기화'**
  String get prestigeLossGold;

  /// No description provided for @prestigeLossQuest.
  ///
  /// In ko, this message translates to:
  /// **'퀘스트 진행 초기화'**
  String get prestigeLossQuest;

  /// No description provided for @prestigeMaxTitle.
  ///
  /// In ko, this message translates to:
  /// **'최대 전생 달성!'**
  String get prestigeMaxTitle;

  /// No description provided for @prestigeMaxDesc.
  ///
  /// In ko, this message translates to:
  /// **'최대 전생 레벨 {level}에 도달했습니다!'**
  String prestigeMaxDesc(int level);

  /// No description provided for @prestigeExecute.
  ///
  /// In ko, this message translates to:
  /// **'전생하기'**
  String get prestigeExecute;

  /// No description provided for @prestigeNotMet.
  ///
  /// In ko, this message translates to:
  /// **'조건 미달'**
  String get prestigeNotMet;

  /// No description provided for @prestigeConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'전생 확인'**
  String get prestigeConfirmTitle;

  /// No description provided for @prestigeConfirmDesc.
  ///
  /// In ko, this message translates to:
  /// **'전생하면 레벨, 스테이지, 몬스터, 재화가 모두 초기화됩니다.\n\n대신 다이아몬드와 소환권, 영구 전투 보너스를 받습니다.\n\n정말 전생하시겠습니까?'**
  String get prestigeConfirmDesc;

  /// No description provided for @prestigeLevelN.
  ///
  /// In ko, this message translates to:
  /// **'전생 Lv.{level}'**
  String prestigeLevelN(int level);

  /// No description provided for @permanentBonus.
  ///
  /// In ko, this message translates to:
  /// **'영구 보너스'**
  String get permanentBonus;

  /// No description provided for @statistics.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get statistics;

  /// No description provided for @equippedRelics.
  ///
  /// In ko, this message translates to:
  /// **'장착 유물'**
  String get equippedRelics;

  /// No description provided for @noRelics.
  ///
  /// In ko, this message translates to:
  /// **'장착된 유물이 없습니다'**
  String get noRelics;

  /// No description provided for @noSkill.
  ///
  /// In ko, this message translates to:
  /// **'스킬 없음'**
  String get noSkill;

  /// No description provided for @stats.
  ///
  /// In ko, this message translates to:
  /// **'스탯'**
  String get stats;

  /// No description provided for @experience.
  ///
  /// In ko, this message translates to:
  /// **'경험치'**
  String get experience;

  /// No description provided for @affinity.
  ///
  /// In ko, this message translates to:
  /// **'친밀도'**
  String get affinity;

  /// No description provided for @skill.
  ///
  /// In ko, this message translates to:
  /// **'스킬'**
  String get skill;

  /// No description provided for @teamAssigned.
  ///
  /// In ko, this message translates to:
  /// **'팀 배치중'**
  String get teamAssigned;

  /// No description provided for @teamNotAssigned.
  ///
  /// In ko, this message translates to:
  /// **'미배치'**
  String get teamNotAssigned;

  /// No description provided for @evolutionStage.
  ///
  /// In ko, this message translates to:
  /// **'진화 {stage}단계'**
  String evolutionStage(int stage);

  /// No description provided for @acquiredDate.
  ///
  /// In ko, this message translates to:
  /// **'획득 {date}'**
  String acquiredDate(String date);

  /// No description provided for @playerInfo.
  ///
  /// In ko, this message translates to:
  /// **'플레이어'**
  String get playerInfo;

  /// No description provided for @battleStats.
  ///
  /// In ko, this message translates to:
  /// **'전투'**
  String get battleStats;

  /// No description provided for @monsterStats.
  ///
  /// In ko, this message translates to:
  /// **'몬스터'**
  String get monsterStats;

  /// No description provided for @gachaStats.
  ///
  /// In ko, this message translates to:
  /// **'소환'**
  String get gachaStats;

  /// No description provided for @resources.
  ///
  /// In ko, this message translates to:
  /// **'재화'**
  String get resources;

  /// No description provided for @equipmentQuests.
  ///
  /// In ko, this message translates to:
  /// **'장비/퀘스트'**
  String get equipmentQuests;

  /// No description provided for @statNickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get statNickname;

  /// No description provided for @statLevel.
  ///
  /// In ko, this message translates to:
  /// **'레벨'**
  String get statLevel;

  /// No description provided for @statPrestigeCount.
  ///
  /// In ko, this message translates to:
  /// **'전생 횟수'**
  String get statPrestigeCount;

  /// No description provided for @statPrestigeBonus.
  ///
  /// In ko, this message translates to:
  /// **'전생 보너스'**
  String get statPrestigeBonus;

  /// No description provided for @statJoinDate.
  ///
  /// In ko, this message translates to:
  /// **'가입일'**
  String get statJoinDate;

  /// No description provided for @statPlayDays.
  ///
  /// In ko, this message translates to:
  /// **'플레이 일수'**
  String get statPlayDays;

  /// No description provided for @statTotalBattle.
  ///
  /// In ko, this message translates to:
  /// **'총 스테이지 전투'**
  String get statTotalBattle;

  /// No description provided for @statTeamBattle.
  ///
  /// In ko, this message translates to:
  /// **'팀 누적 전투'**
  String get statTeamBattle;

  /// No description provided for @statStageProgress.
  ///
  /// In ko, this message translates to:
  /// **'스테이지 진행'**
  String get statStageProgress;

  /// No description provided for @statBestClear.
  ///
  /// In ko, this message translates to:
  /// **'최고 클리어'**
  String get statBestClear;

  /// No description provided for @statDungeonBest.
  ///
  /// In ko, this message translates to:
  /// **'무한던전 최고층'**
  String get statDungeonBest;

  /// No description provided for @statOwnedMonster.
  ///
  /// In ko, this message translates to:
  /// **'보유 몬스터'**
  String get statOwnedMonster;

  /// No description provided for @statCollection.
  ///
  /// In ko, this message translates to:
  /// **'도감 수집'**
  String get statCollection;

  /// No description provided for @statBestLevel.
  ///
  /// In ko, this message translates to:
  /// **'최고 레벨'**
  String get statBestLevel;

  /// No description provided for @statTeamComp.
  ///
  /// In ko, this message translates to:
  /// **'팀 편성'**
  String get statTeamComp;

  /// No description provided for @statAvgLevel.
  ///
  /// In ko, this message translates to:
  /// **'평균 레벨'**
  String get statAvgLevel;

  /// No description provided for @statTotalGacha.
  ///
  /// In ko, this message translates to:
  /// **'총 소환 횟수'**
  String get statTotalGacha;

  /// No description provided for @statCurrentPity.
  ///
  /// In ko, this message translates to:
  /// **'현재 천장'**
  String get statCurrentPity;

  /// No description provided for @statFiveStarGuarantee.
  ///
  /// In ko, this message translates to:
  /// **'5성 보장'**
  String get statFiveStarGuarantee;

  /// No description provided for @statGuaranteeImminent.
  ///
  /// In ko, this message translates to:
  /// **'보장 임박!'**
  String get statGuaranteeImminent;

  /// No description provided for @statGuaranteeRemain.
  ///
  /// In ko, this message translates to:
  /// **'{count}회 남음'**
  String statGuaranteeRemain(int count);

  /// No description provided for @statOwnedRelic.
  ///
  /// In ko, this message translates to:
  /// **'보유 유물'**
  String get statOwnedRelic;

  /// No description provided for @statEquippedRelic.
  ///
  /// In ko, this message translates to:
  /// **'장착 유물'**
  String get statEquippedRelic;

  /// No description provided for @statCompletedQuest.
  ///
  /// In ko, this message translates to:
  /// **'완료 퀘스트'**
  String get statCompletedQuest;

  /// No description provided for @statClaimable.
  ///
  /// In ko, this message translates to:
  /// **'수령 가능'**
  String get statClaimable;

  /// No description provided for @countUnit.
  ///
  /// In ko, this message translates to:
  /// **'{count}회'**
  String countUnit(String count);

  /// No description provided for @countMonster.
  ///
  /// In ko, this message translates to:
  /// **'{count}마리'**
  String countMonster(int count);

  /// No description provided for @countItem.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String countItem(int count);

  /// No description provided for @countDay.
  ///
  /// In ko, this message translates to:
  /// **'{count}일'**
  String countDay(int count);

  /// No description provided for @countFloor.
  ///
  /// In ko, this message translates to:
  /// **'{floor}층'**
  String countFloor(int floor);

  /// No description provided for @onboardingWelcome.
  ///
  /// In ko, this message translates to:
  /// **'몬스터 컬렉터에 오신 걸 환영합니다!'**
  String get onboardingWelcome;

  /// No description provided for @onboardingEnterName.
  ///
  /// In ko, this message translates to:
  /// **'모험가의 이름을 입력해주세요'**
  String get onboardingEnterName;

  /// No description provided for @onboardingNameHint.
  ///
  /// In ko, this message translates to:
  /// **'닉네임 (2-12자)'**
  String get onboardingNameHint;

  /// No description provided for @onboardingChooseMonster.
  ///
  /// In ko, this message translates to:
  /// **'{name}님,\n첫 번째 동료를 선택하세요!'**
  String onboardingChooseMonster(String name);

  /// No description provided for @onboardingStart.
  ///
  /// In ko, this message translates to:
  /// **'모험 시작!'**
  String get onboardingStart;

  /// No description provided for @tutorialStep1Title.
  ///
  /// In ko, this message translates to:
  /// **'첫 전투를 시작하세요!'**
  String get tutorialStep1Title;

  /// No description provided for @tutorialStep1Msg.
  ///
  /// In ko, this message translates to:
  /// **'아래 \"전투 시작\" 버튼을 눌러\n첫 번째 전투를 시작해보세요.\n자동전투와 배속 기능도 있어요!'**
  String get tutorialStep1Msg;

  /// No description provided for @tutorialStep2Title.
  ///
  /// In ko, this message translates to:
  /// **'승리를 축하합니다!'**
  String get tutorialStep2Title;

  /// No description provided for @tutorialStep2Msg.
  ///
  /// In ko, this message translates to:
  /// **'보상을 받은 후\n하단의 \"소환\" 탭에서\n새로운 몬스터를 소환해보세요!'**
  String get tutorialStep2Msg;

  /// No description provided for @tutorialStep3Title.
  ///
  /// In ko, this message translates to:
  /// **'몬스터를 소환하세요!'**
  String get tutorialStep3Title;

  /// No description provided for @tutorialStep3Msg.
  ///
  /// In ko, this message translates to:
  /// **'다이아몬드나 소환권으로\n몬스터를 소환할 수 있어요.\n높은 등급 몬스터를 노려보세요!'**
  String get tutorialStep3Msg;

  /// No description provided for @tutorialStep4Title.
  ///
  /// In ko, this message translates to:
  /// **'몬스터를 강화하세요!'**
  String get tutorialStep4Title;

  /// No description provided for @tutorialStep4Msg.
  ///
  /// In ko, this message translates to:
  /// **'\"강화\" 탭에서 몬스터를 선택하고\n골드로 레벨업하거나\n진화시킬 수 있어요!'**
  String get tutorialStep4Msg;

  /// No description provided for @tutorialStep5Title.
  ///
  /// In ko, this message translates to:
  /// **'팀을 편성하세요!'**
  String get tutorialStep5Title;

  /// No description provided for @tutorialStep5Msg.
  ///
  /// In ko, this message translates to:
  /// **'\"도감\" 탭에서 팀 편성 버튼을 눌러\n최대 4마리 몬스터로\n최강 팀을 구성해보세요!'**
  String get tutorialStep5Msg;

  /// No description provided for @affinityNames.
  ///
  /// In ko, this message translates to:
  /// **'없음,Lv.1 관심,Lv.2 신뢰,Lv.3 우정,Lv.4 유대,Lv.5 최대'**
  String get affinityNames;

  /// No description provided for @affinityBattleCount.
  ///
  /// In ko, this message translates to:
  /// **'전투 {count}회'**
  String affinityBattleCount(int count);

  /// No description provided for @affinityBonus.
  ///
  /// In ko, this message translates to:
  /// **'보너스: 전 스탯 +{percent}%'**
  String affinityBonus(int percent);

  /// No description provided for @elementFire.
  ///
  /// In ko, this message translates to:
  /// **'화염'**
  String get elementFire;

  /// No description provided for @elementWater.
  ///
  /// In ko, this message translates to:
  /// **'물'**
  String get elementWater;

  /// No description provided for @elementElectric.
  ///
  /// In ko, this message translates to:
  /// **'전기'**
  String get elementElectric;

  /// No description provided for @elementRock.
  ///
  /// In ko, this message translates to:
  /// **'바위'**
  String get elementRock;

  /// No description provided for @elementGrass.
  ///
  /// In ko, this message translates to:
  /// **'풀'**
  String get elementGrass;

  /// No description provided for @elementGhost.
  ///
  /// In ko, this message translates to:
  /// **'유령'**
  String get elementGhost;

  /// No description provided for @elementLight.
  ///
  /// In ko, this message translates to:
  /// **'빛'**
  String get elementLight;

  /// No description provided for @elementDark.
  ///
  /// In ko, this message translates to:
  /// **'어둠'**
  String get elementDark;

  /// No description provided for @playerLevelStage.
  ///
  /// In ko, this message translates to:
  /// **'Lv.{level}  |  스테이지 {stage}'**
  String playerLevelStage(int level, String stage);

  /// No description provided for @dailyStatus.
  ///
  /// In ko, this message translates to:
  /// **'일일 현황'**
  String get dailyStatus;

  /// No description provided for @questRewardAvailable.
  ///
  /// In ko, this message translates to:
  /// **'퀘스트 보상 {count}개 수령 가능!'**
  String questRewardAvailable(int count);

  /// No description provided for @questInProgress.
  ///
  /// In ko, this message translates to:
  /// **'진행중 퀘스트 {count}개'**
  String questInProgress(int count);

  /// No description provided for @shortcut.
  ///
  /// In ko, this message translates to:
  /// **'바로가기'**
  String get shortcut;

  /// No description provided for @prestigeN.
  ///
  /// In ko, this message translates to:
  /// **'전생 {level}'**
  String prestigeN(int level);

  /// No description provided for @attendanceTitle.
  ///
  /// In ko, this message translates to:
  /// **'일일 출석 보상'**
  String get attendanceTitle;

  /// No description provided for @attendanceDesc.
  ///
  /// In ko, this message translates to:
  /// **'누적 출석 {days}일째'**
  String attendanceDesc(int days);

  /// No description provided for @attendanceCheckIn.
  ///
  /// In ko, this message translates to:
  /// **'출석 체크!'**
  String get attendanceCheckIn;

  /// No description provided for @attendanceDay.
  ///
  /// In ko, this message translates to:
  /// **'Day {day}'**
  String attendanceDay(int day);

  /// No description provided for @attendanceRewardGold.
  ///
  /// In ko, this message translates to:
  /// **'골드 {amount}'**
  String attendanceRewardGold(int amount);

  /// No description provided for @attendanceRewardDiamond.
  ///
  /// In ko, this message translates to:
  /// **'다이아 {amount}'**
  String attendanceRewardDiamond(int amount);

  /// No description provided for @attendanceRewardTicket.
  ///
  /// In ko, this message translates to:
  /// **'소환권 {amount}'**
  String attendanceRewardTicket(int amount);

  /// No description provided for @attendanceRewardPotion.
  ///
  /// In ko, this message translates to:
  /// **'경험치 물약 {amount}'**
  String attendanceRewardPotion(int amount);

  /// No description provided for @attendanceClaimed.
  ///
  /// In ko, this message translates to:
  /// **'출석 보상을 받았습니다!'**
  String get attendanceClaimed;

  /// No description provided for @attendanceAlreadyClaimed.
  ///
  /// In ko, this message translates to:
  /// **'오늘은 이미 출석했습니다'**
  String get attendanceAlreadyClaimed;

  /// No description provided for @towerTitle.
  ///
  /// In ko, this message translates to:
  /// **'도전의 탑'**
  String get towerTitle;

  /// No description provided for @towerStart.
  ///
  /// In ko, this message translates to:
  /// **'도전 시작'**
  String get towerStart;

  /// No description provided for @towerReady.
  ///
  /// In ko, this message translates to:
  /// **'도전 준비 완료!'**
  String get towerReady;

  /// No description provided for @towerNoAttempts.
  ///
  /// In ko, this message translates to:
  /// **'이번 주 도전 횟수 소진'**
  String get towerNoAttempts;

  /// No description provided for @towerAttempts.
  ///
  /// In ko, this message translates to:
  /// **'남은 도전: {remaining}/{max}'**
  String towerAttempts(int remaining, int max);

  /// No description provided for @towerBest.
  ///
  /// In ko, this message translates to:
  /// **'최고 {floor}층'**
  String towerBest(int floor);

  /// No description provided for @towerNextFloor.
  ///
  /// In ko, this message translates to:
  /// **'다음 층'**
  String get towerNextFloor;

  /// No description provided for @towerCollect.
  ///
  /// In ko, this message translates to:
  /// **'보상 수집'**
  String get towerCollect;

  /// No description provided for @towerComplete.
  ///
  /// In ko, this message translates to:
  /// **'탑 정복 완료!'**
  String get towerComplete;

  /// No description provided for @towerNoHeal.
  ///
  /// In ko, this message translates to:
  /// **'층 사이 회복 없음!'**
  String get towerNoHeal;

  /// No description provided for @recipeTitle.
  ///
  /// In ko, this message translates to:
  /// **'조합 레시피'**
  String get recipeTitle;

  /// No description provided for @recipeHidden.
  ///
  /// In ko, this message translates to:
  /// **'히든 몬스터'**
  String get recipeHidden;

  /// No description provided for @recipeUnlocked.
  ///
  /// In ko, this message translates to:
  /// **'해금됨'**
  String get recipeUnlocked;

  /// No description provided for @recipeLocked.
  ///
  /// In ko, this message translates to:
  /// **'???'**
  String get recipeLocked;

  /// No description provided for @recipeHint.
  ///
  /// In ko, this message translates to:
  /// **'특정 몬스터 조합으로 히든 몬스터를 해금하세요!'**
  String get recipeHint;

  /// No description provided for @recipeMatch.
  ///
  /// In ko, this message translates to:
  /// **'레시피 발견!'**
  String get recipeMatch;

  /// No description provided for @seasonPassTitle.
  ///
  /// In ko, this message translates to:
  /// **'시즌 패스'**
  String get seasonPassTitle;

  /// No description provided for @seasonPassLevel.
  ///
  /// In ko, this message translates to:
  /// **'Lv.{level}'**
  String seasonPassLevel(int level);

  /// No description provided for @seasonPassDaysLeft.
  ///
  /// In ko, this message translates to:
  /// **'남은 기간: {days}일'**
  String seasonPassDaysLeft(int days);

  /// No description provided for @seasonPassFree.
  ///
  /// In ko, this message translates to:
  /// **'수령'**
  String get seasonPassFree;

  /// No description provided for @seasonPassPremium.
  ///
  /// In ko, this message translates to:
  /// **'수령'**
  String get seasonPassPremium;

  /// No description provided for @seasonPassPremiumActive.
  ///
  /// In ko, this message translates to:
  /// **'프리미엄'**
  String get seasonPassPremiumActive;

  /// No description provided for @seasonPassPremiumBuy.
  ///
  /// In ko, this message translates to:
  /// **'프리미엄 잠금'**
  String get seasonPassPremiumBuy;

  /// No description provided for @seasonPassPremiumBadge.
  ///
  /// In ko, this message translates to:
  /// **'PREMIUM'**
  String get seasonPassPremiumBadge;

  /// No description provided for @trainingTitle.
  ///
  /// In ko, this message translates to:
  /// **'트레이닝'**
  String get trainingTitle;

  /// No description provided for @trainingDesc.
  ///
  /// In ko, this message translates to:
  /// **'몬스터를 배치하면 시간 경과 후 자동으로 경험치를 획득합니다'**
  String get trainingDesc;

  /// No description provided for @trainingEmpty.
  ///
  /// In ko, this message translates to:
  /// **'몬스터 배치하기'**
  String get trainingEmpty;

  /// No description provided for @trainingSelectMonster.
  ///
  /// In ko, this message translates to:
  /// **'트레이닝할 몬스터 선택'**
  String get trainingSelectMonster;

  /// No description provided for @trainingDuration.
  ///
  /// In ko, this message translates to:
  /// **'트레이닝 시간 선택'**
  String get trainingDuration;

  /// No description provided for @trainingComplete.
  ///
  /// In ko, this message translates to:
  /// **'완료!'**
  String get trainingComplete;

  /// No description provided for @trainingRemaining.
  ///
  /// In ko, this message translates to:
  /// **'남음'**
  String get trainingRemaining;

  /// No description provided for @trainingCollect.
  ///
  /// In ko, this message translates to:
  /// **'수집'**
  String get trainingCollect;

  /// No description provided for @trainingCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get trainingCancel;

  /// No description provided for @trainingNoMonsters.
  ///
  /// In ko, this message translates to:
  /// **'배치 가능한 몬스터가 없습니다'**
  String get trainingNoMonsters;

  /// No description provided for @leaderboardTitle.
  ///
  /// In ko, this message translates to:
  /// **'랭킹'**
  String get leaderboardTitle;

  /// No description provided for @leaderboardArena.
  ///
  /// In ko, this message translates to:
  /// **'아레나'**
  String get leaderboardArena;

  /// No description provided for @leaderboardDungeon.
  ///
  /// In ko, this message translates to:
  /// **'던전'**
  String get leaderboardDungeon;

  /// No description provided for @leaderboardTower.
  ///
  /// In ko, this message translates to:
  /// **'탑'**
  String get leaderboardTower;

  /// No description provided for @leaderboardBoss.
  ///
  /// In ko, this message translates to:
  /// **'월드보스'**
  String get leaderboardBoss;

  /// No description provided for @leaderboardMyRank.
  ///
  /// In ko, this message translates to:
  /// **'내 순위'**
  String get leaderboardMyRank;

  /// No description provided for @leaderboardPlayers.
  ///
  /// In ko, this message translates to:
  /// **'명 참여'**
  String get leaderboardPlayers;

  /// No description provided for @titleScreenTitle.
  ///
  /// In ko, this message translates to:
  /// **'칭호'**
  String get titleScreenTitle;

  /// No description provided for @titleCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재 칭호'**
  String get titleCurrent;

  /// No description provided for @titleNone.
  ///
  /// In ko, this message translates to:
  /// **'칭호 없음'**
  String get titleNone;

  /// No description provided for @titleHidden.
  ///
  /// In ko, this message translates to:
  /// **'숨겨진 업적을 달성하면 해금됩니다'**
  String get titleHidden;

  /// No description provided for @titleEquip.
  ///
  /// In ko, this message translates to:
  /// **'장착'**
  String get titleEquip;

  /// No description provided for @titleUnequip.
  ///
  /// In ko, this message translates to:
  /// **'해제'**
  String get titleUnequip;

  /// No description provided for @mailboxTitle.
  ///
  /// In ko, this message translates to:
  /// **'우편함'**
  String get mailboxTitle;

  /// No description provided for @mailboxEmpty.
  ///
  /// In ko, this message translates to:
  /// **'우편이 없습니다'**
  String get mailboxEmpty;

  /// No description provided for @mailboxClaim.
  ///
  /// In ko, this message translates to:
  /// **'수령'**
  String get mailboxClaim;

  /// No description provided for @mailboxClaimed.
  ///
  /// In ko, this message translates to:
  /// **'수령 완료'**
  String get mailboxClaimed;

  /// No description provided for @mailboxClaimAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 수령'**
  String get mailboxClaimAll;

  /// No description provided for @shopTitle.
  ///
  /// In ko, this message translates to:
  /// **'상점'**
  String get shopTitle;

  /// No description provided for @shopExchange.
  ///
  /// In ko, this message translates to:
  /// **'재화 교환'**
  String get shopExchange;

  /// No description provided for @shopItems.
  ///
  /// In ko, this message translates to:
  /// **'아이템 구매'**
  String get shopItems;

  /// No description provided for @shopBuy.
  ///
  /// In ko, this message translates to:
  /// **'구매'**
  String get shopBuy;

  /// No description provided for @shopBuyGold.
  ///
  /// In ko, this message translates to:
  /// **'골드 구매'**
  String get shopBuyGold;

  /// No description provided for @shopBuyDiamond.
  ///
  /// In ko, this message translates to:
  /// **'다이아 구매'**
  String get shopBuyDiamond;

  /// No description provided for @shopBuyTicket.
  ///
  /// In ko, this message translates to:
  /// **'소환권 x1'**
  String get shopBuyTicket;

  /// No description provided for @shopBuyTicketDesc.
  ///
  /// In ko, this message translates to:
  /// **'다이아 30개로 소환권 1장 구매'**
  String get shopBuyTicketDesc;

  /// No description provided for @shopBuyTicket10.
  ///
  /// In ko, this message translates to:
  /// **'소환권 x10'**
  String get shopBuyTicket10;

  /// No description provided for @shopBuyTicket10Desc.
  ///
  /// In ko, this message translates to:
  /// **'다이아 250개로 소환권 10장 (17% 할인)'**
  String get shopBuyTicket10Desc;

  /// No description provided for @shopBuyExpPotion.
  ///
  /// In ko, this message translates to:
  /// **'경험치 물약 x1'**
  String get shopBuyExpPotion;

  /// No description provided for @shopBuyExpPotionDesc.
  ///
  /// In ko, this message translates to:
  /// **'골드 500으로 경험치 물약 1개 구매'**
  String get shopBuyExpPotionDesc;

  /// No description provided for @shopBuyExpPotion10.
  ///
  /// In ko, this message translates to:
  /// **'경험치 물약 x10'**
  String get shopBuyExpPotion10;

  /// No description provided for @shopBuyExpPotion10Desc.
  ///
  /// In ko, this message translates to:
  /// **'골드 4,000으로 경험치 물약 10개 (20% 할인)'**
  String get shopBuyExpPotion10Desc;

  /// No description provided for @shopBuyShard.
  ///
  /// In ko, this message translates to:
  /// **'소환석 x5'**
  String get shopBuyShard;

  /// No description provided for @shopBuyShardDesc.
  ///
  /// In ko, this message translates to:
  /// **'다이아 20개로 소환석 5개 구매'**
  String get shopBuyShardDesc;

  /// No description provided for @shopBuyShard10.
  ///
  /// In ko, this message translates to:
  /// **'소환석 x20'**
  String get shopBuyShard10;

  /// No description provided for @shopBuyShard10Desc.
  ///
  /// In ko, this message translates to:
  /// **'다이아 70개로 소환석 20개 (13% 할인)'**
  String get shopBuyShard10Desc;

  /// No description provided for @shopInsufficient.
  ///
  /// In ko, this message translates to:
  /// **'재화가 부족합니다'**
  String get shopInsufficient;

  /// No description provided for @shopPurchaseSuccess.
  ///
  /// In ko, this message translates to:
  /// **'구매 완료!'**
  String get shopPurchaseSuccess;

  /// No description provided for @repeatBattle.
  ///
  /// In ko, this message translates to:
  /// **'반복'**
  String get repeatBattle;

  /// No description provided for @nicknameTitle.
  ///
  /// In ko, this message translates to:
  /// **'닉네임 설정'**
  String get nicknameTitle;

  /// No description provided for @nicknameReset.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get nicknameReset;

  /// No description provided for @dailyDungeonTitle.
  ///
  /// In ko, this message translates to:
  /// **'일일 던전'**
  String get dailyDungeonTitle;

  /// No description provided for @dailyDungeonTheme.
  ///
  /// In ko, this message translates to:
  /// **'던전'**
  String get dailyDungeonTheme;

  /// No description provided for @dailyDungeonDesc.
  ///
  /// In ko, this message translates to:
  /// **'요일별 속성 테마 던전. 보상 1.5배!'**
  String get dailyDungeonDesc;

  /// No description provided for @dailyDungeonRemaining.
  ///
  /// In ko, this message translates to:
  /// **'남은 도전'**
  String get dailyDungeonRemaining;

  /// No description provided for @dailyDungeonStart.
  ///
  /// In ko, this message translates to:
  /// **'던전 입장'**
  String get dailyDungeonStart;

  /// No description provided for @dailyDungeonCleared.
  ///
  /// In ko, this message translates to:
  /// **'클리어!'**
  String get dailyDungeonCleared;

  /// No description provided for @dailyDungeonNext.
  ///
  /// In ko, this message translates to:
  /// **'다음 층'**
  String get dailyDungeonNext;

  /// No description provided for @dailyDungeonComplete.
  ///
  /// In ko, this message translates to:
  /// **'던전 완료!'**
  String get dailyDungeonComplete;

  /// No description provided for @dailyDungeonDefeated.
  ///
  /// In ko, this message translates to:
  /// **'패배'**
  String get dailyDungeonDefeated;

  /// No description provided for @dailyDungeonCollect.
  ///
  /// In ko, this message translates to:
  /// **'보상 수령'**
  String get dailyDungeonCollect;

  /// No description provided for @dailyDungeonExitConfirm.
  ///
  /// In ko, this message translates to:
  /// **'현재까지 획득한 보상을 수령하고 나가시겠습니까?'**
  String get dailyDungeonExitConfirm;

  /// No description provided for @elementMatchup.
  ///
  /// In ko, this message translates to:
  /// **'속성 상성표'**
  String get elementMatchup;

  /// No description provided for @elementMatchupDesc.
  ///
  /// In ko, this message translates to:
  /// **'공격 시 상성 배율 (🔼1.3x 유리 / 🔽0.7x 불리)'**
  String get elementMatchupDesc;

  /// No description provided for @superEffective.
  ///
  /// In ko, this message translates to:
  /// **'유리'**
  String get superEffective;

  /// No description provided for @notEffective.
  ///
  /// In ko, this message translates to:
  /// **'불리'**
  String get notEffective;

  /// No description provided for @passiveSkill.
  ///
  /// In ko, this message translates to:
  /// **'패시브 스킬'**
  String get passiveSkill;

  /// No description provided for @ultimateSkill.
  ///
  /// In ko, this message translates to:
  /// **'궁극기'**
  String get ultimateSkill;

  /// No description provided for @ultCharge.
  ///
  /// In ko, this message translates to:
  /// **'차지: {charge}'**
  String ultCharge(int charge);

  /// No description provided for @evolutionTree.
  ///
  /// In ko, this message translates to:
  /// **'진화 트리'**
  String get evolutionTree;

  /// No description provided for @evoStageBase.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get evoStageBase;

  /// No description provided for @evoStageFirst.
  ///
  /// In ko, this message translates to:
  /// **'1차 진화'**
  String get evoStageFirst;

  /// No description provided for @evoStageFinal.
  ///
  /// In ko, this message translates to:
  /// **'최종 진화'**
  String get evoStageFinal;

  /// No description provided for @evoCurrentMark.
  ///
  /// In ko, this message translates to:
  /// **'현재'**
  String get evoCurrentMark;

  /// No description provided for @triggerOnTurnStart.
  ///
  /// In ko, this message translates to:
  /// **'턴 시작'**
  String get triggerOnTurnStart;

  /// No description provided for @triggerOnAttack.
  ///
  /// In ko, this message translates to:
  /// **'공격 시'**
  String get triggerOnAttack;

  /// No description provided for @triggerOnDamaged.
  ///
  /// In ko, this message translates to:
  /// **'피격 시'**
  String get triggerOnDamaged;

  /// No description provided for @triggerBattleStart.
  ///
  /// In ko, this message translates to:
  /// **'전투 시작'**
  String get triggerBattleStart;

  /// No description provided for @achievementPoints.
  ///
  /// In ko, this message translates to:
  /// **'업적 포인트: {points}P'**
  String achievementPoints(int points);

  /// No description provided for @replayTitle.
  ///
  /// In ko, this message translates to:
  /// **'전투 기록'**
  String get replayTitle;

  /// No description provided for @replayEmpty.
  ///
  /// In ko, this message translates to:
  /// **'전투 기록이 없습니다'**
  String get replayEmpty;

  /// No description provided for @replayClear.
  ///
  /// In ko, this message translates to:
  /// **'기록 삭제'**
  String get replayClear;

  /// No description provided for @replayClearConfirm.
  ///
  /// In ko, this message translates to:
  /// **'모든 전투 기록을 삭제하시겠습니까?'**
  String get replayClearConfirm;

  /// No description provided for @replayVictory.
  ///
  /// In ko, this message translates to:
  /// **'승리'**
  String get replayVictory;

  /// No description provided for @replayDefeat.
  ///
  /// In ko, this message translates to:
  /// **'패배'**
  String get replayDefeat;

  /// No description provided for @replayTurns.
  ///
  /// In ko, this message translates to:
  /// **'턴'**
  String get replayTurns;

  /// No description provided for @replayActions.
  ///
  /// In ko, this message translates to:
  /// **'액션'**
  String get replayActions;

  /// No description provided for @replayMyTeam.
  ///
  /// In ko, this message translates to:
  /// **'아군'**
  String get replayMyTeam;

  /// No description provided for @replayEnemyTeam.
  ///
  /// In ko, this message translates to:
  /// **'적군'**
  String get replayEnemyTeam;

  /// No description provided for @relicEnhance.
  ///
  /// In ko, this message translates to:
  /// **'강화'**
  String get relicEnhance;

  /// No description provided for @teamPreset.
  ///
  /// In ko, this message translates to:
  /// **'팀 프리셋'**
  String get teamPreset;

  /// No description provided for @presetSlot.
  ///
  /// In ko, this message translates to:
  /// **'슬롯 {index}'**
  String presetSlot(int index);

  /// No description provided for @presetEmpty.
  ///
  /// In ko, this message translates to:
  /// **'비어있음'**
  String get presetEmpty;

  /// No description provided for @presetSave.
  ///
  /// In ko, this message translates to:
  /// **'현재 팀 저장'**
  String get presetSave;

  /// No description provided for @presetLoad.
  ///
  /// In ko, this message translates to:
  /// **'불러오기'**
  String get presetLoad;

  /// No description provided for @presetDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get presetDelete;

  /// No description provided for @presetRename.
  ///
  /// In ko, this message translates to:
  /// **'이름 변경'**
  String get presetRename;

  /// No description provided for @presetNameHint.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 이름 (최대 10자)'**
  String get presetNameHint;

  /// No description provided for @presetSaved.
  ///
  /// In ko, this message translates to:
  /// **'프리셋이 저장되었습니다'**
  String get presetSaved;

  /// No description provided for @presetLoaded.
  ///
  /// In ko, this message translates to:
  /// **'프리셋을 불러왔습니다'**
  String get presetLoaded;

  /// No description provided for @presetDeleted.
  ///
  /// In ko, this message translates to:
  /// **'프리셋이 삭제되었습니다'**
  String get presetDeleted;

  /// No description provided for @presetDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 프리셋을 삭제하시겠습니까?'**
  String get presetDeleteConfirm;

  /// No description provided for @presetMissing.
  ///
  /// In ko, this message translates to:
  /// **'일부 몬스터가 없어 불러올 수 없습니다'**
  String get presetMissing;

  /// No description provided for @compareTitle.
  ///
  /// In ko, this message translates to:
  /// **'몬스터 비교'**
  String get compareTitle;

  /// No description provided for @compareSelectTwo.
  ///
  /// In ko, this message translates to:
  /// **'비교할 몬스터 2마리를 선택하세요'**
  String get compareSelectTwo;

  /// No description provided for @compareSelectMonster.
  ///
  /// In ko, this message translates to:
  /// **'몬스터 선택'**
  String get compareSelectMonster;

  /// No description provided for @sortDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get sortDefault;

  /// No description provided for @sortName.
  ///
  /// In ko, this message translates to:
  /// **'이름순'**
  String get sortName;

  /// No description provided for @sortRarity.
  ///
  /// In ko, this message translates to:
  /// **'등급순'**
  String get sortRarity;

  /// No description provided for @sortLevel.
  ///
  /// In ko, this message translates to:
  /// **'레벨순'**
  String get sortLevel;

  /// No description provided for @sortPower.
  ///
  /// In ko, this message translates to:
  /// **'전투력순'**
  String get sortPower;

  /// No description provided for @gachaHistoryTitle.
  ///
  /// In ko, this message translates to:
  /// **'소환 기록'**
  String get gachaHistoryTitle;

  /// No description provided for @gachaHistoryEmpty.
  ///
  /// In ko, this message translates to:
  /// **'소환 기록이 없습니다'**
  String get gachaHistoryEmpty;

  /// No description provided for @gachaHistoryTotal.
  ///
  /// In ko, this message translates to:
  /// **'총 {count}회 소환'**
  String gachaHistoryTotal(int count);

  /// No description provided for @gachaHistoryClearConfirm.
  ///
  /// In ko, this message translates to:
  /// **'모든 소환 기록을 삭제하시겠습니까?'**
  String get gachaHistoryClearConfirm;

  /// No description provided for @achievementToast.
  ///
  /// In ko, this message translates to:
  /// **'업적 달성! {name}'**
  String achievementToast(String name);

  /// No description provided for @achievementTapToView.
  ///
  /// In ko, this message translates to:
  /// **'탭하여 확인'**
  String get achievementTapToView;

  /// No description provided for @settingsNotification.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get settingsNotification;

  /// No description provided for @settingsNotificationToggle.
  ///
  /// In ko, this message translates to:
  /// **'푸시 알림'**
  String get settingsNotificationToggle;

  /// No description provided for @stageSkip.
  ///
  /// In ko, this message translates to:
  /// **'스킵'**
  String get stageSkip;

  /// No description provided for @stageSkipResult.
  ///
  /// In ko, this message translates to:
  /// **'스테이지 스킵 완료!'**
  String get stageSkipResult;

  /// No description provided for @stageSkipGold.
  ///
  /// In ko, this message translates to:
  /// **'골드 +{gold}'**
  String stageSkipGold(int gold);

  /// No description provided for @stageSkipExp.
  ///
  /// In ko, this message translates to:
  /// **'경험치 +{exp}'**
  String stageSkipExp(int exp);

  /// No description provided for @favorite.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기'**
  String get favorite;

  /// No description provided for @favoriteOnly.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기만'**
  String get favoriteOnly;

  /// No description provided for @settingsTheme.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get settingsTheme;

  /// No description provided for @settingsThemeDark.
  ///
  /// In ko, this message translates to:
  /// **'다크'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In ko, this message translates to:
  /// **'라이트'**
  String get settingsThemeLight;

  /// No description provided for @onboardingSetupError.
  ///
  /// In ko, this message translates to:
  /// **'설정 중 오류가 발생했습니다. 다시 시도해주세요.'**
  String get onboardingSetupError;

  /// No description provided for @gachaPityLabel.
  ///
  /// In ko, this message translates to:
  /// **'천장'**
  String get gachaPityLabel;

  /// No description provided for @collectionUnknownMonster.
  ///
  /// In ko, this message translates to:
  /// **'미발견 몬스터'**
  String get collectionUnknownMonster;

  /// No description provided for @semanticPlayer.
  ///
  /// In ko, this message translates to:
  /// **'플레이어'**
  String get semanticPlayer;

  /// No description provided for @waveProgress.
  ///
  /// In ko, this message translates to:
  /// **'{name} - 웨이브 {current}/{total}'**
  String waveProgress(String name, int current, int total);

  /// No description provided for @turnLabel.
  ///
  /// In ko, this message translates to:
  /// **'턴'**
  String get turnLabel;

  /// No description provided for @skinTitle.
  ///
  /// In ko, this message translates to:
  /// **'스킨'**
  String get skinTitle;

  /// No description provided for @skinEquipped.
  ///
  /// In ko, this message translates to:
  /// **'장착 중'**
  String get skinEquipped;

  /// No description provided for @skinEquip.
  ///
  /// In ko, this message translates to:
  /// **'장착'**
  String get skinEquip;

  /// No description provided for @skinUnequip.
  ///
  /// In ko, this message translates to:
  /// **'해제'**
  String get skinUnequip;

  /// No description provided for @skinUnlock.
  ///
  /// In ko, this message translates to:
  /// **'해금'**
  String get skinUnlock;

  /// No description provided for @skinUnlocked.
  ///
  /// In ko, this message translates to:
  /// **'해금 완료'**
  String get skinUnlocked;

  /// No description provided for @skinLocked.
  ///
  /// In ko, this message translates to:
  /// **'잠김'**
  String get skinLocked;

  /// No description provided for @skinCost.
  ///
  /// In ko, this message translates to:
  /// **'소환석 {cost}개'**
  String skinCost(int cost);

  /// No description provided for @skinUnlockSuccess.
  ///
  /// In ko, this message translates to:
  /// **'스킨을 해금했습니다!'**
  String get skinUnlockSuccess;

  /// No description provided for @skinEquipSuccess.
  ///
  /// In ko, this message translates to:
  /// **'스킨을 장착했습니다!'**
  String get skinEquipSuccess;

  /// No description provided for @skinUnequipSuccess.
  ///
  /// In ko, this message translates to:
  /// **'스킨을 해제했습니다.'**
  String get skinUnequipSuccess;

  /// No description provided for @skinInsufficientShards.
  ///
  /// In ko, this message translates to:
  /// **'소환석이 부족합니다.'**
  String get skinInsufficientShards;

  /// No description provided for @skinNone.
  ///
  /// In ko, this message translates to:
  /// **'장착된 스킨이 없습니다'**
  String get skinNone;

  /// No description provided for @skinUniversal.
  ///
  /// In ko, this message translates to:
  /// **'모든 몬스터'**
  String get skinUniversal;

  /// No description provided for @skinElementOnly.
  ///
  /// In ko, this message translates to:
  /// **'{element} 속성 전용'**
  String skinElementOnly(String element);

  /// No description provided for @skinExclusive.
  ///
  /// In ko, this message translates to:
  /// **'전용 스킨'**
  String get skinExclusive;

  /// No description provided for @offlineRewardTitle.
  ///
  /// In ko, this message translates to:
  /// **'오프라인 보상'**
  String get offlineRewardTitle;

  /// No description provided for @offlineRewardTime.
  ///
  /// In ko, this message translates to:
  /// **'{time} 동안 모은 보상'**
  String offlineRewardTime(String time);

  /// No description provided for @offlineHoursMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{h}시간 {m}분'**
  String offlineHoursMinutes(int h, int m);

  /// No description provided for @offlineHours.
  ///
  /// In ko, this message translates to:
  /// **'{h}시간'**
  String offlineHours(int h);

  /// No description provided for @offlineMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{m}분'**
  String offlineMinutes(int m);

  /// No description provided for @offlineMaxReward.
  ///
  /// In ko, this message translates to:
  /// **'최대 보상 시간에 도달했습니다'**
  String get offlineMaxReward;

  /// No description provided for @offlineClaim.
  ///
  /// In ko, this message translates to:
  /// **'보상 받기'**
  String get offlineClaim;

  /// No description provided for @msgLevelUp.
  ///
  /// In ko, this message translates to:
  /// **'Lv.{level} 달성!'**
  String msgLevelUp(int level);

  /// No description provided for @msgExpPotionLevelUp.
  ///
  /// In ko, this message translates to:
  /// **'Lv.{level} 달성! (+{gained})'**
  String msgExpPotionLevelUp(int level, int gained);

  /// No description provided for @msgExpGained.
  ///
  /// In ko, this message translates to:
  /// **'경험치 획득!'**
  String get msgExpGained;

  /// No description provided for @msgEvolution1.
  ///
  /// In ko, this message translates to:
  /// **'1차 진화 성공!'**
  String get msgEvolution1;

  /// No description provided for @msgEvolution2.
  ///
  /// In ko, this message translates to:
  /// **'최종 진화 성공!'**
  String get msgEvolution2;

  /// No description provided for @msgFusionHidden.
  ///
  /// In ko, this message translates to:
  /// **'{name} 해금! ({rarity}성 히든)'**
  String msgFusionHidden(String name, int rarity);

  /// No description provided for @msgFusionNormal.
  ///
  /// In ko, this message translates to:
  /// **'{name} 획득! ({rarity}성)'**
  String msgFusionNormal(String name, int rarity);

  /// No description provided for @msgAwakening.
  ///
  /// In ko, this message translates to:
  /// **'각성 {stars}성 달성! (+10% 스탯)'**
  String msgAwakening(int stars);

  /// No description provided for @msgTrainingStart.
  ///
  /// In ko, this message translates to:
  /// **'{name} 트레이닝 시작!'**
  String msgTrainingStart(String name);

  /// No description provided for @msgTrainingCollect.
  ///
  /// In ko, this message translates to:
  /// **'{name} +{xp}XP'**
  String msgTrainingCollect(String name, int xp);

  /// No description provided for @msgTrainingCollectLevelUp.
  ///
  /// In ko, this message translates to:
  /// **'{name} +{xp}XP (Lv.{oldLv}→{newLv})'**
  String msgTrainingCollectLevelUp(String name, int xp, int oldLv, int newLv);

  /// No description provided for @msgTrainingCancel.
  ///
  /// In ko, this message translates to:
  /// **'트레이닝 취소'**
  String get msgTrainingCancel;

  /// No description provided for @msgExpeditionStart.
  ///
  /// In ko, this message translates to:
  /// **'원정 출발! ({hours}시간)'**
  String msgExpeditionStart(int hours);

  /// No description provided for @msgRewardSummary.
  ///
  /// In ko, this message translates to:
  /// **'보상 수령: {rewards}'**
  String msgRewardSummary(String rewards);

  /// No description provided for @rewardGold.
  ///
  /// In ko, this message translates to:
  /// **'골드 +{amount}'**
  String rewardGold(int amount);

  /// No description provided for @rewardExpPotion.
  ///
  /// In ko, this message translates to:
  /// **'경험치포션 +{amount}'**
  String rewardExpPotion(int amount);

  /// No description provided for @rewardShard.
  ///
  /// In ko, this message translates to:
  /// **'진화석 +{amount}'**
  String rewardShard(int amount);

  /// No description provided for @rewardDiamond.
  ///
  /// In ko, this message translates to:
  /// **'다이아 +{amount}'**
  String rewardDiamond(int amount);

  /// No description provided for @rewardGachaTicket.
  ///
  /// In ko, this message translates to:
  /// **'소환권 +{amount}'**
  String rewardGachaTicket(int amount);

  /// No description provided for @msgPrestige.
  ///
  /// In ko, this message translates to:
  /// **'전생 {level}회 완료! 보너스 +{bonus}%, 다이아 +{diamonds}, 소환권 +{tickets}'**
  String msgPrestige(int level, int bonus, int diamonds, int tickets);

  /// No description provided for @mailWelcomeTitle.
  ///
  /// In ko, this message translates to:
  /// **'환영합니다!'**
  String get mailWelcomeTitle;

  /// No description provided for @mailWelcomeBody.
  ///
  /// In ko, this message translates to:
  /// **'몬스터 수집 게임에 오신 것을 환영합니다! 시작 선물을 받아주세요.'**
  String get mailWelcomeBody;

  /// No description provided for @mailDailyTitle.
  ///
  /// In ko, this message translates to:
  /// **'일일 접속 보상'**
  String get mailDailyTitle;

  /// No description provided for @mailDailyBody.
  ///
  /// In ko, this message translates to:
  /// **'매일 접속해 주셔서 감사합니다! 오늘의 보상입니다.'**
  String get mailDailyBody;

  /// No description provided for @mailWeeklyTitle.
  ///
  /// In ko, this message translates to:
  /// **'주간 보너스'**
  String get mailWeeklyTitle;

  /// No description provided for @mailWeeklyBody.
  ///
  /// In ko, this message translates to:
  /// **'이번 주도 화이팅! 주간 보너스 보상입니다.'**
  String get mailWeeklyBody;

  /// No description provided for @milestoneCollect.
  ///
  /// In ko, this message translates to:
  /// **'{count}종 수집'**
  String milestoneCollect(int count);

  /// No description provided for @milestoneComplete.
  ///
  /// In ko, this message translates to:
  /// **'도감 완성!'**
  String get milestoneComplete;

  /// No description provided for @skillCd.
  ///
  /// In ko, this message translates to:
  /// **'CD: {cd}턴'**
  String skillCd(int cd);

  /// No description provided for @tagAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get tagAll;

  /// No description provided for @tagSingle.
  ///
  /// In ko, this message translates to:
  /// **'단일'**
  String get tagSingle;

  /// No description provided for @tagShield.
  ///
  /// In ko, this message translates to:
  /// **'방패 {pct}%'**
  String tagShield(int pct);

  /// No description provided for @tagHeal.
  ///
  /// In ko, this message translates to:
  /// **'힐 {pct}%'**
  String tagHeal(int pct);

  /// No description provided for @tagDrain.
  ///
  /// In ko, this message translates to:
  /// **'흡수 {pct}%'**
  String tagDrain(int pct);

  /// No description provided for @tagBurn.
  ///
  /// In ko, this message translates to:
  /// **'화상 {turns}턴'**
  String tagBurn(int turns);

  /// No description provided for @tagStun.
  ///
  /// In ko, this message translates to:
  /// **'기절 {pct}%'**
  String tagStun(int pct);

  /// No description provided for @tagHpRegen.
  ///
  /// In ko, this message translates to:
  /// **'HP회복 {pct}%'**
  String tagHpRegen(int pct);

  /// No description provided for @tagCounter.
  ///
  /// In ko, this message translates to:
  /// **'반격 {pct}%'**
  String tagCounter(int pct);

  /// No description provided for @tagCrit.
  ///
  /// In ko, this message translates to:
  /// **'크리 +{pct}%'**
  String tagCrit(int pct);

  /// No description provided for @affinityNext.
  ///
  /// In ko, this message translates to:
  /// **'다음 레벨까지 {battles}회 (보너스: +{bonus}%)'**
  String affinityNext(int battles, int bonus);

  /// No description provided for @relicInfo.
  ///
  /// In ko, this message translates to:
  /// **'{stat} +{value} | {rarity}성'**
  String relicInfo(String stat, int value, int rarity);

  /// No description provided for @teamSummary.
  ///
  /// In ko, this message translates to:
  /// **'전투력 {power}  |  팀 {count}/4  |  도감 {owned}/{total}'**
  String teamSummary(String power, int count, int owned, int total);

  /// No description provided for @monsterLevelInfo.
  ///
  /// In ko, this message translates to:
  /// **'Lv.{level}  |  진화 {stage}단계'**
  String monsterLevelInfo(int level, int stage);

  /// No description provided for @timerHMS.
  ///
  /// In ko, this message translates to:
  /// **'{h}시간 {m}분 {s}초'**
  String timerHMS(int h, int m, int s);

  /// No description provided for @timerMS.
  ///
  /// In ko, this message translates to:
  /// **'{m}분 {s}초'**
  String timerMS(int m, int s);

  /// No description provided for @timerS.
  ///
  /// In ko, this message translates to:
  /// **'{s}초'**
  String timerS(int s);

  /// No description provided for @notifCapTitle.
  ///
  /// In ko, this message translates to:
  /// **'오프라인 보상 최대치 도달!'**
  String get notifCapTitle;

  /// No description provided for @notifCapBody.
  ///
  /// In ko, this message translates to:
  /// **'보상이 더 쌓이지 않아요. 접속해서 수령하세요!'**
  String get notifCapBody;

  /// No description provided for @notifComeBackTitle.
  ///
  /// In ko, this message translates to:
  /// **'몬스터들이 기다리고 있어요!'**
  String get notifComeBackTitle;

  /// No description provided for @notifComeBackBody.
  ///
  /// In ko, this message translates to:
  /// **'오프라인 보상이 가득 찼어요. 지금 접속하세요!'**
  String get notifComeBackBody;

  /// No description provided for @notifChannelName.
  ///
  /// In ko, this message translates to:
  /// **'게임 알림'**
  String get notifChannelName;

  /// No description provided for @notifChannelDesc.
  ///
  /// In ko, this message translates to:
  /// **'오프라인 보상 및 리마인더 알림'**
  String get notifChannelDesc;

  /// No description provided for @expeditionOptionLabel.
  ///
  /// In ko, this message translates to:
  /// **'{h}시간 원정'**
  String expeditionOptionLabel(int h);

  /// No description provided for @synergyNone.
  ///
  /// In ko, this message translates to:
  /// **'활성 시너지 없음'**
  String get synergyNone;

  /// No description provided for @tabMonster.
  ///
  /// In ko, this message translates to:
  /// **'몬스터'**
  String get tabMonster;

  /// No description provided for @tabSkillSummon.
  ///
  /// In ko, this message translates to:
  /// **'스킬'**
  String get tabSkillSummon;

  /// No description provided for @tabRelicSummon.
  ///
  /// In ko, this message translates to:
  /// **'장비'**
  String get tabRelicSummon;

  /// No description provided for @tabMountSummon.
  ///
  /// In ko, this message translates to:
  /// **'탈것'**
  String get tabMountSummon;

  /// No description provided for @skillSummonTitle.
  ///
  /// In ko, this message translates to:
  /// **'스킬 소환'**
  String get skillSummonTitle;

  /// No description provided for @skillSummonDesc.
  ///
  /// In ko, this message translates to:
  /// **'강력한 스킬을 획득하세요'**
  String get skillSummonDesc;

  /// No description provided for @relicSummonTitle.
  ///
  /// In ko, this message translates to:
  /// **'장비 소환'**
  String get relicSummonTitle;

  /// No description provided for @relicSummonDesc.
  ///
  /// In ko, this message translates to:
  /// **'희귀한 장비를 획득하세요'**
  String get relicSummonDesc;

  /// No description provided for @mountSummonTitle.
  ///
  /// In ko, this message translates to:
  /// **'탈것 소환'**
  String get mountSummonTitle;

  /// No description provided for @mountSummonDesc.
  ///
  /// In ko, this message translates to:
  /// **'전설의 탈것을 획득하세요'**
  String get mountSummonDesc;

  /// No description provided for @pull1.
  ///
  /// In ko, this message translates to:
  /// **'1회 소환'**
  String get pull1;

  /// No description provided for @pull10.
  ///
  /// In ko, this message translates to:
  /// **'10회 소환'**
  String get pull10;

  /// No description provided for @pull100.
  ///
  /// In ko, this message translates to:
  /// **'100회 소환'**
  String get pull100;

  /// No description provided for @shopTabGeneral.
  ///
  /// In ko, this message translates to:
  /// **'일반'**
  String get shopTabGeneral;

  /// No description provided for @shopTabSummon.
  ///
  /// In ko, this message translates to:
  /// **'소환'**
  String get shopTabSummon;

  /// No description provided for @shopTabCurrency.
  ///
  /// In ko, this message translates to:
  /// **'재화'**
  String get shopTabCurrency;

  /// No description provided for @shopHeader.
  ///
  /// In ko, this message translates to:
  /// **'상점'**
  String get shopHeader;

  /// No description provided for @shopSkillTicket.
  ///
  /// In ko, this message translates to:
  /// **'스킬 티켓'**
  String get shopSkillTicket;

  /// No description provided for @shopSkillTicket1.
  ///
  /// In ko, this message translates to:
  /// **'스킬 티켓 x1'**
  String get shopSkillTicket1;

  /// No description provided for @shopSkillTicket1Desc.
  ///
  /// In ko, this message translates to:
  /// **'스킬 소환에 사용'**
  String get shopSkillTicket1Desc;

  /// No description provided for @shopSkillTicket10.
  ///
  /// In ko, this message translates to:
  /// **'스킬 티켓 x10'**
  String get shopSkillTicket10;

  /// No description provided for @shopRelicTicket.
  ///
  /// In ko, this message translates to:
  /// **'장비 티켓'**
  String get shopRelicTicket;

  /// No description provided for @shopRelicTicket1.
  ///
  /// In ko, this message translates to:
  /// **'장비 티켓 x1'**
  String get shopRelicTicket1;

  /// No description provided for @shopRelicTicket1Desc.
  ///
  /// In ko, this message translates to:
  /// **'장비 소환에 사용'**
  String get shopRelicTicket1Desc;

  /// No description provided for @shopRelicTicket10.
  ///
  /// In ko, this message translates to:
  /// **'장비 티켓 x10'**
  String get shopRelicTicket10;

  /// No description provided for @shopMountGem.
  ///
  /// In ko, this message translates to:
  /// **'탈것 젬'**
  String get shopMountGem;

  /// No description provided for @shopMountGem300.
  ///
  /// In ko, this message translates to:
  /// **'탈것 젬 x300'**
  String get shopMountGem300;

  /// No description provided for @shopMountGem300Desc.
  ///
  /// In ko, this message translates to:
  /// **'탈것 소환 1회분'**
  String get shopMountGem300Desc;

  /// No description provided for @shopMountGem3000.
  ///
  /// In ko, this message translates to:
  /// **'탈것 젬 x3000'**
  String get shopMountGem3000;

  /// No description provided for @shopMountGem3000Desc.
  ///
  /// In ko, this message translates to:
  /// **'탈것 소환 10회분 + 보너스'**
  String get shopMountGem3000Desc;

  /// No description provided for @shopCurrencyExchange.
  ///
  /// In ko, this message translates to:
  /// **'재화 교환'**
  String get shopCurrencyExchange;

  /// No description provided for @shopBulkGold.
  ///
  /// In ko, this message translates to:
  /// **'골드 대량 구매'**
  String get shopBulkGold;

  /// No description provided for @mapHubTitle.
  ///
  /// In ko, this message translates to:
  /// **'월드맵'**
  String get mapHubTitle;

  /// No description provided for @mapHubCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재'**
  String get mapHubCurrent;

  /// No description provided for @mapArea1.
  ///
  /// In ko, this message translates to:
  /// **'시작의 숲'**
  String get mapArea1;

  /// No description provided for @mapArea2.
  ///
  /// In ko, this message translates to:
  /// **'불꽃 화산'**
  String get mapArea2;

  /// No description provided for @mapArea3.
  ///
  /// In ko, this message translates to:
  /// **'암흑 던전'**
  String get mapArea3;

  /// No description provided for @mapArea4.
  ///
  /// In ko, this message translates to:
  /// **'심해 신전'**
  String get mapArea4;

  /// No description provided for @mapArea5.
  ///
  /// In ko, this message translates to:
  /// **'천공 성역'**
  String get mapArea5;

  /// No description provided for @heroHeader.
  ///
  /// In ko, this message translates to:
  /// **'영웅'**
  String get heroHeader;

  /// No description provided for @heroTabEquipment.
  ///
  /// In ko, this message translates to:
  /// **'장비'**
  String get heroTabEquipment;

  /// No description provided for @heroTabInventory.
  ///
  /// In ko, this message translates to:
  /// **'인벤토리'**
  String get heroTabInventory;

  /// No description provided for @heroTabFusion.
  ///
  /// In ko, this message translates to:
  /// **'합성/분해'**
  String get heroTabFusion;

  /// No description provided for @heroSkillLabel.
  ///
  /// In ko, this message translates to:
  /// **'스킬'**
  String get heroSkillLabel;

  /// No description provided for @heroMountLabel.
  ///
  /// In ko, this message translates to:
  /// **'탈것'**
  String get heroMountLabel;

  /// No description provided for @heroNoSkill.
  ///
  /// In ko, this message translates to:
  /// **'장착된 스킬 없음'**
  String get heroNoSkill;

  /// No description provided for @heroNoMount.
  ///
  /// In ko, this message translates to:
  /// **'장착된 탈것 없음'**
  String get heroNoMount;

  /// No description provided for @heroNoSkillOwned.
  ///
  /// In ko, this message translates to:
  /// **'보유한 스킬이 없습니다. 소환에서 획득하세요!'**
  String get heroNoSkillOwned;

  /// No description provided for @heroNoMountOwned.
  ///
  /// In ko, this message translates to:
  /// **'보유한 탈것이 없습니다. 소환에서 획득하세요!'**
  String get heroNoMountOwned;

  /// No description provided for @heroNoEquipment.
  ///
  /// In ko, this message translates to:
  /// **'보유한 장비가 없습니다'**
  String get heroNoEquipment;

  /// No description provided for @heroGetFromSummon.
  ///
  /// In ko, this message translates to:
  /// **'소환에서 스킬과 탈것을 획득하세요!'**
  String get heroGetFromSummon;

  /// No description provided for @heroEquipped.
  ///
  /// In ko, this message translates to:
  /// **'장착중'**
  String get heroEquipped;

  /// No description provided for @heroGoldInsufficient.
  ///
  /// In ko, this message translates to:
  /// **'골드가 부족합니다'**
  String get heroGoldInsufficient;

  /// No description provided for @heroBattleStats.
  ///
  /// In ko, this message translates to:
  /// **'전투 능력치'**
  String get heroBattleStats;

  /// No description provided for @heroTraining.
  ///
  /// In ko, this message translates to:
  /// **'훈련'**
  String get heroTraining;

  /// No description provided for @heroEnhanceComplete.
  ///
  /// In ko, this message translates to:
  /// **'{name} Lv.{level} 강화 완료!'**
  String heroEnhanceComplete(String name, int level);

  /// No description provided for @heroNextValue.
  ///
  /// In ko, this message translates to:
  /// **'다음: {value}'**
  String heroNextValue(String value);

  /// No description provided for @heroLevelHero.
  ///
  /// In ko, this message translates to:
  /// **'Lv.{level} 영웅'**
  String heroLevelHero(int level);

  /// No description provided for @heroFusionComplete.
  ///
  /// In ko, this message translates to:
  /// **'{name} 합성! Lv.{level}'**
  String heroFusionComplete(String name, int level);

  /// No description provided for @heroDismantleComplete.
  ///
  /// In ko, this message translates to:
  /// **'{name} 분해! +{gold}G, +{shard}샤드'**
  String heroDismantleComplete(String name, int gold, int shard);

  /// No description provided for @heroDismantleReward.
  ///
  /// In ko, this message translates to:
  /// **'+{gold}G · +{shard}샤드'**
  String heroDismantleReward(int gold, int shard);

  /// No description provided for @heroSkillTypeHpRegen.
  ///
  /// In ko, this message translates to:
  /// **'HP 회복'**
  String get heroSkillTypeHpRegen;

  /// No description provided for @heroUnequip.
  ///
  /// In ko, this message translates to:
  /// **'해제'**
  String get heroUnequip;

  /// No description provided for @heroTapToEquip.
  ///
  /// In ko, this message translates to:
  /// **'탭하여 장착'**
  String get heroTapToEquip;

  /// No description provided for @heroSelectSkill.
  ///
  /// In ko, this message translates to:
  /// **'스킬 선택'**
  String get heroSelectSkill;

  /// No description provided for @heroSelectMount.
  ///
  /// In ko, this message translates to:
  /// **'탈것 선택'**
  String get heroSelectMount;

  /// No description provided for @heroOwned.
  ///
  /// In ko, this message translates to:
  /// **'보유: {count}개'**
  String heroOwned(int count);

  /// No description provided for @heroFusion.
  ///
  /// In ko, this message translates to:
  /// **'합성'**
  String get heroFusion;

  /// No description provided for @heroDismantle.
  ///
  /// In ko, this message translates to:
  /// **'분해'**
  String get heroDismantle;

  /// No description provided for @heroFusionDesc.
  ///
  /// In ko, this message translates to:
  /// **'동일 장비 2개 → 레벨 +1 합성'**
  String get heroFusionDesc;

  /// No description provided for @heroDismantleDesc.
  ///
  /// In ko, this message translates to:
  /// **'장비 분해 → 골드 + 샤드 획득 (장착중 불가)'**
  String get heroDismantleDesc;

  /// No description provided for @heroNoFusible.
  ///
  /// In ko, this message translates to:
  /// **'합성 가능한 중복 장비가 없습니다'**
  String get heroNoFusible;

  /// No description provided for @heroNoDismantleable.
  ///
  /// In ko, this message translates to:
  /// **'분해 가능한 장비가 없습니다'**
  String get heroNoDismantleable;

  /// No description provided for @heroNoFusionItems.
  ///
  /// In ko, this message translates to:
  /// **'합성/분해할 장비가 없습니다'**
  String get heroNoFusionItems;

  /// No description provided for @heroMaxLevel.
  ///
  /// In ko, this message translates to:
  /// **'이미 최대 레벨입니다'**
  String get heroMaxLevel;

  /// No description provided for @heroOwnedCount.
  ///
  /// In ko, this message translates to:
  /// **'보유 {count}개'**
  String heroOwnedCount(int count);

  /// No description provided for @heroTotal.
  ///
  /// In ko, this message translates to:
  /// **'합계'**
  String get heroTotal;

  /// No description provided for @heroSkillTypeDamage.
  ///
  /// In ko, this message translates to:
  /// **'피해'**
  String get heroSkillTypeDamage;

  /// No description provided for @heroSkillTypeDefBuff.
  ///
  /// In ko, this message translates to:
  /// **'방어 버프'**
  String get heroSkillTypeDefBuff;

  /// No description provided for @heroSkillTypeAtkBuff.
  ///
  /// In ko, this message translates to:
  /// **'공격 버프'**
  String get heroSkillTypeAtkBuff;

  /// No description provided for @heroSkillTypeSpeedBuff.
  ///
  /// In ko, this message translates to:
  /// **'속도 버프'**
  String get heroSkillTypeSpeedBuff;

  /// No description provided for @heroSkillTypeCritBoost.
  ///
  /// In ko, this message translates to:
  /// **'치명타 강화'**
  String get heroSkillTypeCritBoost;

  /// No description provided for @quickNavHero.
  ///
  /// In ko, this message translates to:
  /// **'영웅'**
  String get quickNavHero;

  /// No description provided for @quickNavWorldMap.
  ///
  /// In ko, this message translates to:
  /// **'월드맵'**
  String get quickNavWorldMap;

  /// No description provided for @battleSkip.
  ///
  /// In ko, this message translates to:
  /// **'스킵'**
  String get battleSkip;

  /// No description provided for @statTowerHighest.
  ///
  /// In ko, this message translates to:
  /// **'탑 최고층'**
  String get statTowerHighest;

  /// No description provided for @statArenaRating.
  ///
  /// In ko, this message translates to:
  /// **'아레나 레이팅'**
  String get statArenaRating;

  /// No description provided for @statGuildContrib.
  ///
  /// In ko, this message translates to:
  /// **'길드 기여도'**
  String get statGuildContrib;

  /// No description provided for @statExpeditionGold.
  ///
  /// In ko, this message translates to:
  /// **'원정대 누적 수익'**
  String get statExpeditionGold;

  /// No description provided for @ownedSkillTicket.
  ///
  /// In ko, this message translates to:
  /// **'보유 스킬 티켓'**
  String get ownedSkillTicket;

  /// No description provided for @ownedRelicTicket.
  ///
  /// In ko, this message translates to:
  /// **'보유 장비 티켓'**
  String get ownedRelicTicket;

  /// No description provided for @ownedMountGem.
  ///
  /// In ko, this message translates to:
  /// **'보유 탈것 젬'**
  String get ownedMountGem;

  /// No description provided for @pityUntil.
  ///
  /// In ko, this message translates to:
  /// **'천장까지'**
  String get pityUntil;

  /// No description provided for @pityRemaining.
  ///
  /// In ko, this message translates to:
  /// **'{count}회 남음'**
  String pityRemaining(int count);

  /// No description provided for @tabTrain.
  ///
  /// In ko, this message translates to:
  /// **'훈련/연구'**
  String get tabTrain;

  /// No description provided for @tabHero.
  ///
  /// In ko, this message translates to:
  /// **'히어로'**
  String get tabHero;

  /// No description provided for @trainTitle.
  ///
  /// In ko, this message translates to:
  /// **'훈련/연구'**
  String get trainTitle;

  /// No description provided for @trainUpgradeCard.
  ///
  /// In ko, this message translates to:
  /// **'몬스터 강화'**
  String get trainUpgradeCard;

  /// No description provided for @trainUpgradeDesc.
  ///
  /// In ko, this message translates to:
  /// **'레벨업, 진화, 각성, 융합'**
  String get trainUpgradeDesc;

  /// No description provided for @trainTrainingCard.
  ///
  /// In ko, this message translates to:
  /// **'트레이닝'**
  String get trainTrainingCard;

  /// No description provided for @trainTrainingDesc.
  ///
  /// In ko, this message translates to:
  /// **'몬스터를 훈련시켜 경험치 획득'**
  String get trainTrainingDesc;

  /// No description provided for @trainExpeditionCard.
  ///
  /// In ko, this message translates to:
  /// **'원정대'**
  String get trainExpeditionCard;

  /// No description provided for @trainExpeditionDesc.
  ///
  /// In ko, this message translates to:
  /// **'몬스터를 파견하여 보상 획득'**
  String get trainExpeditionDesc;

  /// No description provided for @sidebarDungeon.
  ///
  /// In ko, this message translates to:
  /// **'던전'**
  String get sidebarDungeon;

  /// No description provided for @sidebarTower.
  ///
  /// In ko, this message translates to:
  /// **'타워'**
  String get sidebarTower;

  /// No description provided for @sidebarWorldBoss.
  ///
  /// In ko, this message translates to:
  /// **'월보'**
  String get sidebarWorldBoss;

  /// No description provided for @sidebarArena.
  ///
  /// In ko, this message translates to:
  /// **'아레나'**
  String get sidebarArena;

  /// No description provided for @sidebarEvent.
  ///
  /// In ko, this message translates to:
  /// **'이벤트'**
  String get sidebarEvent;

  /// No description provided for @sidebarGuild.
  ///
  /// In ko, this message translates to:
  /// **'길드'**
  String get sidebarGuild;

  /// No description provided for @sidebarQuest.
  ///
  /// In ko, this message translates to:
  /// **'퀘스트'**
  String get sidebarQuest;

  /// No description provided for @sidebarSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get sidebarSettings;

  /// No description provided for @sidebarRelic.
  ///
  /// In ko, this message translates to:
  /// **'유물'**
  String get sidebarRelic;

  /// No description provided for @sidebarDailyDungeon.
  ///
  /// In ko, this message translates to:
  /// **'일일'**
  String get sidebarDailyDungeon;

  /// No description provided for @sidebarMap.
  ///
  /// In ko, this message translates to:
  /// **'지도'**
  String get sidebarMap;

  /// No description provided for @sidebarSeasonPass.
  ///
  /// In ko, this message translates to:
  /// **'시즌'**
  String get sidebarSeasonPass;

  /// No description provided for @sidebarLeaderboard.
  ///
  /// In ko, this message translates to:
  /// **'랭킹'**
  String get sidebarLeaderboard;

  /// No description provided for @sidebarTitle.
  ///
  /// In ko, this message translates to:
  /// **'칭호'**
  String get sidebarTitle;

  /// No description provided for @sidebarMailbox.
  ///
  /// In ko, this message translates to:
  /// **'우편'**
  String get sidebarMailbox;

  /// No description provided for @sidebarReplay.
  ///
  /// In ko, this message translates to:
  /// **'리플레이'**
  String get sidebarReplay;

  /// No description provided for @sidebarStats.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get sidebarStats;

  /// No description provided for @sidebarPrestige.
  ///
  /// In ko, this message translates to:
  /// **'전생'**
  String get sidebarPrestige;

  /// No description provided for @sidebarCollection.
  ///
  /// In ko, this message translates to:
  /// **'도감'**
  String get sidebarCollection;

  /// No description provided for @stageProgress.
  ///
  /// In ko, this message translates to:
  /// **'{defeated}/{total}'**
  String stageProgress(Object defeated, Object total);

  /// No description provided for @autoRepeat.
  ///
  /// In ko, this message translates to:
  /// **'자동 반복'**
  String get autoRepeat;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
