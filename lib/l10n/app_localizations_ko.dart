// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '몬스터 수집';

  @override
  String get tabBattle => '전투';

  @override
  String get tabGacha => '소환';

  @override
  String get tabCollection => '도감';

  @override
  String get tabUpgrade => '강화';

  @override
  String get tabQuest => '퀘스트';

  @override
  String get tabSettings => '설정';

  @override
  String get battleIdle => '전투 대기';

  @override
  String get battleFighting => '전투 중...';

  @override
  String get battleVictory => '승리!';

  @override
  String get battleDefeat => '패배';

  @override
  String get battleAutoMode => '자동';

  @override
  String get battleSpeed => '속도';

  @override
  String get battleStart => '전투 시작';

  @override
  String get battleRetreat => '후퇴';

  @override
  String get stageSelect => '스테이지 선택';

  @override
  String get gachaSinglePull => '1회 소환';

  @override
  String get gachaTenPull => '10회 소환';

  @override
  String gachaPity(int count) {
    return '천장: $count/80';
  }

  @override
  String monsterLevel(int level) {
    return 'Lv.$level';
  }

  @override
  String get upgradeLevelUp => '레벨업';

  @override
  String get upgradeEvolution => '진화';

  @override
  String get upgradeFusion => '융합';

  @override
  String get upgradeAwakening => '각성';

  @override
  String get questDaily => '일일';

  @override
  String get questWeekly => '주간';

  @override
  String get questAchievement => '업적';

  @override
  String get questClaim => '수령';

  @override
  String get questNoQuests => '퀘스트가 없습니다';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsSound => '진동 효과';

  @override
  String get settingsBackup => '데이터 백업';

  @override
  String get settingsRestore => '데이터 복원';

  @override
  String get settingsPrestige => '전생';

  @override
  String get gold => '골드';

  @override
  String get diamond => '다이아';

  @override
  String get gachaTicket => '소환권';

  @override
  String get confirm => '확인';

  @override
  String get cancel => '취소';

  @override
  String get close => '닫기';

  @override
  String get infiniteDungeon => '무한 던전';

  @override
  String get worldBoss => '월드 보스';

  @override
  String get arena => '아레나';

  @override
  String get eventDungeon => '이벤트';

  @override
  String get guild => '길드';

  @override
  String get relic => '유물';

  @override
  String get expedition => '원정';

  @override
  String get statistics => '통계';

  @override
  String get affinity => '친밀도';

  @override
  String get skill => '스킬';

  @override
  String get equippedRelics => '장착 유물';

  @override
  String get noRelics => '장착된 유물이 없습니다';

  @override
  String get noSkill => '스킬 없음';

  @override
  String get stats => '스탯';

  @override
  String get experience => '경험치';

  @override
  String get teamAssigned => '팀 배치중';

  @override
  String get teamNotAssigned => '미배치';

  @override
  String evolutionStage(int stage) {
    return '진화 $stage단계';
  }

  @override
  String acquiredDate(String date) {
    return '획득 $date';
  }

  @override
  String get playerInfo => '플레이어';

  @override
  String get battleStats => '전투';

  @override
  String get monsterStats => '몬스터';

  @override
  String get gachaStats => '소환';

  @override
  String get resources => '재화';

  @override
  String get equipmentQuests => '장비/퀘스트';
}
