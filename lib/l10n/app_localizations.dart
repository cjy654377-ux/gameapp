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
  /// **'후퇴'**
  String get battleRetreat;

  /// No description provided for @stageSelect.
  ///
  /// In ko, this message translates to:
  /// **'스테이지 선택'**
  String get stageSelect;

  /// No description provided for @gachaSinglePull.
  ///
  /// In ko, this message translates to:
  /// **'1회 소환'**
  String get gachaSinglePull;

  /// No description provided for @gachaTenPull.
  ///
  /// In ko, this message translates to:
  /// **'10회 소환'**
  String get gachaTenPull;

  /// No description provided for @gachaPity.
  ///
  /// In ko, this message translates to:
  /// **'천장: {count}/80'**
  String gachaPity(int count);

  /// No description provided for @monsterLevel.
  ///
  /// In ko, this message translates to:
  /// **'Lv.{level}'**
  String monsterLevel(int level);

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
  /// **'언어'**
  String get settingsLanguage;

  /// No description provided for @settingsSound.
  ///
  /// In ko, this message translates to:
  /// **'진동 효과'**
  String get settingsSound;

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
  /// **'전생'**
  String get settingsPrestige;

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

  /// No description provided for @gachaTicket.
  ///
  /// In ko, this message translates to:
  /// **'소환권'**
  String get gachaTicket;

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

  /// No description provided for @infiniteDungeon.
  ///
  /// In ko, this message translates to:
  /// **'무한 던전'**
  String get infiniteDungeon;

  /// No description provided for @worldBoss.
  ///
  /// In ko, this message translates to:
  /// **'월드 보스'**
  String get worldBoss;

  /// No description provided for @arena.
  ///
  /// In ko, this message translates to:
  /// **'아레나'**
  String get arena;

  /// No description provided for @eventDungeon.
  ///
  /// In ko, this message translates to:
  /// **'이벤트'**
  String get eventDungeon;

  /// No description provided for @guild.
  ///
  /// In ko, this message translates to:
  /// **'길드'**
  String get guild;

  /// No description provided for @relic.
  ///
  /// In ko, this message translates to:
  /// **'유물'**
  String get relic;

  /// No description provided for @expedition.
  ///
  /// In ko, this message translates to:
  /// **'원정'**
  String get expedition;

  /// No description provided for @statistics.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get statistics;

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
