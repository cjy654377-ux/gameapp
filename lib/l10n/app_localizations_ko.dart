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
  String get battleRetreat => '철수';

  @override
  String get retreatConfirmTitle => '전투 철수';

  @override
  String get retreatConfirmBody => '전투를 포기하고 돌아갑니다.\n보상은 지급되지 않습니다.';

  @override
  String get retreatConfirmCancel => '계속하기';

  @override
  String battleStageId(String id) {
    return '스테이지 $id';
  }

  @override
  String get battleStandby => '전투 대기중';

  @override
  String get ourTeam => '우리 팀';

  @override
  String get enemyTeam => '적 팀';

  @override
  String turnN(int n) {
    return '턴 $n';
  }

  @override
  String get battleLog => '전투 로그';

  @override
  String battleLogCount(int count) {
    return '$count건';
  }

  @override
  String get noBattleLog => '전투 기록이 없습니다';

  @override
  String get criticalHit => '[치명타] ';

  @override
  String get elementAdvantage => '[속성유리] ';

  @override
  String get autoOn => '자동전투 ON';

  @override
  String get autoOff => '자동전투 OFF';

  @override
  String get autoShortOn => '자동 ON';

  @override
  String get autoShortOff => '자동 OFF';

  @override
  String get preparing => '준비중';

  @override
  String get fighting => '전투중';

  @override
  String get reward => '보상 받기';

  @override
  String get retry => '재도전';

  @override
  String get preparingBattle => '준비 중...';

  @override
  String get collectingReward => '보상을 집계 중입니다...';

  @override
  String get showStats => '전투 통계 보기';

  @override
  String get hideStats => '통계 접기';

  @override
  String get earnedReward => '획득 보상';

  @override
  String get totalDamage => '총 데미지';

  @override
  String get critCount => '치명타';

  @override
  String get skillCount => '스킬';

  @override
  String get standby => '대기';

  @override
  String get stageSelect => '스테이지 선택';

  @override
  String get areaForest => '시작의 숲';

  @override
  String get areaVolcano => '불꽃 화산';

  @override
  String get areaDungeon => '암흑 던전';

  @override
  String get areaTemple => '심해 신전';

  @override
  String get areaSky => '천공 성역';

  @override
  String get gachaSinglePull => '1회 소환';

  @override
  String get gachaTenPull => '10연 소환';

  @override
  String gachaPity(int count) {
    return '천장: $count/80';
  }

  @override
  String get gachaTitle => '몬스터 소환';

  @override
  String get gachaDesc => '강력한 몬스터를 소환하여 팀을 강화하세요!';

  @override
  String get gachaLegendaryUp => '★ 전설 등급 확률 UP ★';

  @override
  String get gachaUntilLegend => '전설 확정까지';

  @override
  String gachaRemainingCount(int count) {
    return '남은 횟수: $count회';
  }

  @override
  String get gachaNextGuaranteed => '다음 소환 시 전설 확정!';

  @override
  String get gachaRates => '소환 확률';

  @override
  String get gachaThreeStarGuarantee => '3★ 이상 1회 보장';

  @override
  String get gachaDiamondShort => '다이아가 부족합니다';

  @override
  String get gachaTicketShort => '소환권이 부족합니다';

  @override
  String get gachaUseTicket => '소환권 사용';

  @override
  String gachaTicketCount(int count) {
    return '$count장';
  }

  @override
  String get gachaResultSingle => '소환 결과';

  @override
  String get gachaResultTen => '10연 소환 결과';

  @override
  String get gachaRevealAll => '전체 공개';

  @override
  String get gachaGuaranteed => '확정!';

  @override
  String monsterLevel(int level) {
    return 'Lv.$level';
  }

  @override
  String get monsterCollection => '몬스터 도감';

  @override
  String get ownedOnly => '보유만';

  @override
  String get reset => '초기화';

  @override
  String get noMatchingMonster => '조건에 맞는 몬스터가 없습니다';

  @override
  String ownedCount(int count) {
    return '보유: $count마리';
  }

  @override
  String bestUnit(int level) {
    return '최고 개체 (Lv.$level)';
  }

  @override
  String get unownedMonster => '미획득 몬스터';

  @override
  String get teamEdit => '팀 편성';

  @override
  String get save => '저장';

  @override
  String totalPower(String power) {
    return '총 전투력: $power';
  }

  @override
  String get noMonsterOwned => '보유한 몬스터가 없습니다';

  @override
  String get getMonsterFromGacha => '소환에서 몬스터를 획득하세요';

  @override
  String milestoneReward(String label, int gold, int diamond) {
    return '$label 보상 수령! 골드 +$gold, 다이아 +$diamond';
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
  String get selectMonsterToUpgrade => '강화할 몬스터 선택';

  @override
  String maxLevelReached(int level) {
    return '최대 레벨 도달! (Lv.$level)';
  }

  @override
  String get levelUpPreview => '레벨 업 시';

  @override
  String get levelUpWithGold => '골드로 레벨 업';

  @override
  String get goldShort => '골드가 부족합니다';

  @override
  String get expPotion => '경험치 물약';

  @override
  String expPotionOwned(int count, int exp) {
    return '보유: $count개  (개당 $exp EXP)';
  }

  @override
  String get potionUse1 => '1개';

  @override
  String get potionUse5 => '5개';

  @override
  String get potionUse10 => '10개';

  @override
  String get potionUseAll => '전부';

  @override
  String get expPotionShort => '경험치 물약이 부족합니다';

  @override
  String get finalEvolutionDone => '최종 진화 완료!';

  @override
  String get evolutionPreview => '진화 시';

  @override
  String get firstEvolution => '1차 진화';

  @override
  String get finalEvolution => '최종 진화';

  @override
  String get evolve => '진화하기';

  @override
  String get materialShort => '재료가 부족합니다';

  @override
  String get fusionLegendaryLimit => '전설 등급은 융합할 수 없습니다';

  @override
  String get fusionTeamLimit => '팀에 배치된 몬스터는 융합할 수 없습니다';

  @override
  String fusionDesc(String stars, String rarity) {
    return '같은 등급 몬스터 2마리를 융합하여\n$stars $rarity 등급 몬스터를 획득합니다';
  }

  @override
  String get material1 => '소재 1';

  @override
  String get material2 => '소재 2';

  @override
  String get selectMaterial2 => '소재 2 선택';

  @override
  String get fusionCost => '융합 비용';

  @override
  String get fusionExecute => '융합하기';

  @override
  String fusionFormula(int from, int to) {
    return '$from성 + $from성 → $to성';
  }

  @override
  String get fusionCheckCondition => '융합 조건을 확인하세요';

  @override
  String get noFusionMaterial => '같은 등급의 융합 가능한 몬스터가 없습니다';

  @override
  String get selectFusionMaterial => '융합 소재 선택';

  @override
  String get basic => '기본';

  @override
  String get firstEvo => '1차 진화';

  @override
  String get finalEvo => '최종 진화';

  @override
  String get evolutionMaterial => '진화 재료';

  @override
  String get evolutionStone => '진화석';

  @override
  String get awakeningRequireEvo => '최종 진화 후 각성할 수 있습니다';

  @override
  String get awakeningMaxDone => '최대 각성 완료!';

  @override
  String awakeningCostTitle(int star) {
    return '각성 $star성 비용';
  }

  @override
  String shardCost(int count) {
    return '$count 진화석';
  }

  @override
  String get awakening => '각성하기';

  @override
  String get awakeningInProgress => '각성 중...';

  @override
  String currentAwakeningBonus(int bonus) {
    return '현재 각성 보너스: +$bonus%';
  }

  @override
  String nextAwakeningBonus(int bonus) {
    return '다음 각성 보너스: +$bonus%';
  }

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
  String get settingsLanguage => '언어 / Language';

  @override
  String get settingsSound => '진동 효과';

  @override
  String get settingsEffects => '효과';

  @override
  String get settingsBackup => '데이터 백업';

  @override
  String get settingsRestore => '데이터 복원';

  @override
  String get settingsPrestige => '전생 (프레스티지)';

  @override
  String get settingsPlayerInfo => '플레이어 정보';

  @override
  String get settingsNickname => '닉네임';

  @override
  String get settingsLevel => '레벨';

  @override
  String get settingsCurrentStage => '현재 스테이지';

  @override
  String get settingsBattleCount => '전투 횟수';

  @override
  String get settingsGachaCount => '소환 횟수';

  @override
  String get settingsPrestigeLevel => '전생 레벨';

  @override
  String get settingsGameInfo => '게임 정보';

  @override
  String get settingsVersion => '버전';

  @override
  String get settingsOwnedMonster => '보유 몬스터';

  @override
  String get settingsRelicEquip => '유물/장비';

  @override
  String get settingsRelicManage => '유물 관리';

  @override
  String get settingsPrestigeGo => '전생 화면으로';

  @override
  String get settingsBackupRestore => '백업 / 복원';

  @override
  String get settingsBackupCopy => '백업 (복사)';

  @override
  String get settingsRestorePaste => '복원 (붙여넣기)';

  @override
  String get settingsData => '데이터';

  @override
  String get settingsGameReset => '게임 초기화';

  @override
  String get settingsBackupDone => '게임 데이터가 클립보드에 복사되었습니다';

  @override
  String get settingsRestoreTitle => '데이터 복원';

  @override
  String get settingsRestoreDesc =>
      '클립보드의 백업 데이터로 복원합니다.\n현재 데이터는 모두 덮어씌워집니다.\n계속하시겠습니까?';

  @override
  String get settingsNoClipboard => '클립보드에 데이터가 없습니다';

  @override
  String get settingsRestoreDone => '데이터 복원 완료!';

  @override
  String get settingsRestoreFail => '복원 실패: 올바른 백업 데이터가 아닙니다';

  @override
  String get settingsResetTitle => '게임 초기화';

  @override
  String get settingsResetDesc => '모든 데이터가 삭제됩니다.\n정말로 초기화하시겠습니까?';

  @override
  String get settingsResetConfirm => '초기화';

  @override
  String get restore => '복원';

  @override
  String get gold => '골드';

  @override
  String get diamond => '다이아';

  @override
  String get diamondFull => '다이아몬드';

  @override
  String get gachaTicket => '소환권';

  @override
  String get monsterShard => '몬스터 파편';

  @override
  String get confirm => '확인';

  @override
  String get cancel => '취소';

  @override
  String get close => '닫기';

  @override
  String get back => '뒤로';

  @override
  String get next => '다음';

  @override
  String get infiniteDungeon => '무한 던전';

  @override
  String dungeonFloor(int floor) {
    return '$floor층';
  }

  @override
  String dungeonBest(int floor) {
    return '최고 $floor층';
  }

  @override
  String get dungeonPreparing => '던전을 준비 중...';

  @override
  String get dungeonLog => '던전 로그';

  @override
  String get dungeonStart => '던전 시작';

  @override
  String get dungeonNextFloor => '다음 층';

  @override
  String get dungeonCollect => '보상 수령';

  @override
  String dungeonCollectFloor(int floor) {
    return '보상 수령 ($floor층 도달)';
  }

  @override
  String get floorCleared => '클리어!';

  @override
  String get worldBoss => '월드 보스';

  @override
  String worldBossName(String name) {
    return '월드 보스 - $name';
  }

  @override
  String worldBossElement(String element) {
    return '속성: $element';
  }

  @override
  String get remainingAttempts => '남은 도전 횟수';

  @override
  String get turnLimit => '턴 제한';

  @override
  String turnCount(int n) {
    return '$n턴';
  }

  @override
  String get bestDamage => '최고 데미지';

  @override
  String get challenge => '도전하기';

  @override
  String get challengeDone => '오늘 도전 완료';

  @override
  String turnProgress(int current, int max) {
    return '턴 $current/$max';
  }

  @override
  String totalDamageAmount(String damage) {
    return '총 데미지: $damage';
  }

  @override
  String get nextTurn => '다음 턴';

  @override
  String get bossKilled => '보스 처치!';

  @override
  String get battleEnd => '전투 종료!';

  @override
  String get rewardSection => '보상';

  @override
  String get collectReward => '보상 수령';

  @override
  String get goBack => '돌아가기';

  @override
  String get arena => 'PvP 아레나';

  @override
  String get arenaShort => '아레나';

  @override
  String get arenaEasy => '쉬움';

  @override
  String get arenaNormal => '보통';

  @override
  String get arenaHard => '어려움';

  @override
  String get arenaRefresh => '상대 갱신';

  @override
  String get arenaChampion => '챔피언';

  @override
  String get arenaDiamond => '다이아몬드';

  @override
  String get arenaGold => '골드';

  @override
  String get arenaSilver => '실버';

  @override
  String get arenaBronze => '브론즈';

  @override
  String arenaRankScore(String rank, int score) {
    return '$rank · $score점';
  }

  @override
  String arenaRecord(int wins, int losses) {
    return '$wins승 $losses패';
  }

  @override
  String arenaRemaining(int remaining, int max) {
    return '남은 도전: $remaining/$max';
  }

  @override
  String arenaRating(int rating) {
    return '레이팅 $rating';
  }

  @override
  String get arenaChallenge => '도전';

  @override
  String get me => '나';

  @override
  String get opponent => '상대';

  @override
  String get battleWaiting => '전투 대기 중...';

  @override
  String get ratingLabel => '레이팅';

  @override
  String get eventDungeon => '이벤트 던전';

  @override
  String get eventDungeonShort => '이벤트';

  @override
  String get eventLoading => '이벤트 로딩 중...';

  @override
  String get eventLimited => '기간 한정 이벤트';

  @override
  String get eventWeeklyDesc => '매주 새로운 이벤트가 열립니다!';

  @override
  String eventRecommendLevel(int level) {
    return '추천 Lv.$level';
  }

  @override
  String eventWaves(int count) {
    return '$count웨이브';
  }

  @override
  String eventTimeRemain(int hours, int mins) {
    return '$hours시간 $mins분 남음';
  }

  @override
  String get eventChallenge => '도전';

  @override
  String get eventCleared => '클리어 완료';

  @override
  String eventWaveProgress(String name, int current, int total) {
    return '$name - 웨이브 $current/$total';
  }

  @override
  String waveCleared(int wave) {
    return '웨이브 $wave 클리어!';
  }

  @override
  String nextWave(int current, int total) {
    return '다음 웨이브: $current/$total';
  }

  @override
  String get nextWaveBtn => '다음 웨이브';

  @override
  String get eventClear => '이벤트 클리어!';

  @override
  String get guild => '길드';

  @override
  String get guildCreate => '길드 생성';

  @override
  String get guildCreateDesc => '길드를 만들고 동료들과 함께\n강력한 보스를 처치하세요!';

  @override
  String get guildNameHint => '길드 이름 입력';

  @override
  String guildLevelCoin(int level, int coin) {
    return 'Lv.$level | 코인: $coin';
  }

  @override
  String guildMembers(int count) {
    return '길드원 ($count명)';
  }

  @override
  String get guildLeader => '나 (길드장)';

  @override
  String guildWeeklyBoss(String name) {
    return '주간 보스: $name';
  }

  @override
  String guildBossHp(String current, String max) {
    return '남은 HP: $current / $max';
  }

  @override
  String guildMyContrib(String damage) {
    return '내 기여: $damage';
  }

  @override
  String guildAiContrib(String damage) {
    return '길드원 기여: $damage';
  }

  @override
  String get guildBossDefeated => '보스 처치 완료!';

  @override
  String guildBossChallenge(int remaining, int max) {
    return '보스 도전 ($remaining/$max)';
  }

  @override
  String get guildShop => '길드 상점';

  @override
  String guildBossTurn(String name, int current, int max) {
    return '$name (턴 $current/$max)';
  }

  @override
  String guildFightDamage(String damage) {
    return '이번 전투 데미지: $damage';
  }

  @override
  String get attack => '공격';

  @override
  String get guildBattleEnd => '전투 종료!';

  @override
  String get guildDefeat => '패배...';

  @override
  String guildTotalDamage(String damage) {
    return '총 데미지: $damage';
  }

  @override
  String guildEarnedCoin(int coin) {
    return '획득 길드 코인: +$coin';
  }

  @override
  String get guildReturnLobby => '로비로 돌아가기';

  @override
  String guildCoinLabel(int coin) {
    return '코인: $coin';
  }

  @override
  String guildItemCost(int cost) {
    return '$cost 코인';
  }

  @override
  String guildPurchaseDone(String name) {
    return '$name 구매 완료!';
  }

  @override
  String get purchase => '구매';

  @override
  String get expedition => '원정대';

  @override
  String expeditionSlots(int active, int max) {
    return '슬롯 $active/$max';
  }

  @override
  String get expeditionActive => '진행중 원정';

  @override
  String get expeditionNew => '새 원정 시작';

  @override
  String expeditionAllUsed(int count, int max) {
    return '모든 원정 슬롯 사용 중 ($count/$max)';
  }

  @override
  String get expeditionCollect => '보상 수령';

  @override
  String expeditionDepart(int count) {
    return '출발 ($count마리)';
  }

  @override
  String get expeditionNoMonster => '파견 가능한 몬스터가 없습니다\n(팀 배치 중이거나 이미 원정 중)';

  @override
  String get relic => '유물';

  @override
  String relicCount(int count) {
    return '유물 ($count개)';
  }

  @override
  String get relicAll => '전체';

  @override
  String get relicWeapon => '무기';

  @override
  String get relicArmor => '방어구';

  @override
  String get relicAccessory => '악세서리';

  @override
  String get relicEquipped => '장착됨';

  @override
  String get noRelic => '유물이 없습니다';

  @override
  String get getRelicFromBattle => '전투와 던전에서 유물을 획득하세요';

  @override
  String relicStarRarity(int rarity) {
    return '$rarity성';
  }

  @override
  String relicEquippedTo(String name) {
    return '장착: $name';
  }

  @override
  String get unequip => '해제';

  @override
  String get selectMonsterToEquip => '장착할 몬스터 선택:';

  @override
  String get replace => '교체';

  @override
  String get relicDisassemble => '유물 분해';

  @override
  String get statAttack => '공격력';

  @override
  String get statDefense => '방어력';

  @override
  String get statHp => '체력';

  @override
  String get statSpeed => '속도';

  @override
  String get prestige => '전생';

  @override
  String get prestigeTitle => '전생 (프레스티지)';

  @override
  String get prestigeCurrentBonus => '현재 전생 보너스';

  @override
  String get goldGain => '골드 획득량';

  @override
  String get expGain => '경험치 획득량';

  @override
  String get prestigeCondition => '전생 조건';

  @override
  String prestigeMinLevel(int level) {
    return '플레이어 레벨 $level+';
  }

  @override
  String get or => '또는';

  @override
  String prestigeMinArea(int area) {
    return '$area지역 이상 클리어';
  }

  @override
  String get none => '없음';

  @override
  String get prestigeGains => '전생 시 얻는 것';

  @override
  String get prestigeLosses => '전생 시 초기화되는 것';

  @override
  String get prestigeLossLevel => '플레이어 레벨 → Lv.1';

  @override
  String get prestigeLossStage => '스테이지 진행 → 1-1';

  @override
  String get prestigeLossDungeon => '던전 기록 초기화';

  @override
  String get prestigeLossMonster => '보유 몬스터 전체 삭제';

  @override
  String get prestigeLossGold => '골드/파편/포션 초기화';

  @override
  String get prestigeLossQuest => '퀘스트 진행 초기화';

  @override
  String get prestigeMaxTitle => '최대 전생 달성!';

  @override
  String prestigeMaxDesc(int level) {
    return '최대 전생 레벨 $level에 도달했습니다!';
  }

  @override
  String get prestigeExecute => '전생하기';

  @override
  String get prestigeNotMet => '조건 미달';

  @override
  String get prestigeConfirmTitle => '전생 확인';

  @override
  String get prestigeConfirmDesc =>
      '전생하면 레벨, 스테이지, 몬스터, 재화가 모두 초기화됩니다.\n\n대신 다이아몬드와 소환권, 영구 전투 보너스를 받습니다.\n\n정말 전생하시겠습니까?';

  @override
  String prestigeLevelN(int level) {
    return '전생 Lv.$level';
  }

  @override
  String get permanentBonus => '영구 보너스';

  @override
  String get statistics => '통계';

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
  String get affinity => '친밀도';

  @override
  String get skill => '스킬';

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

  @override
  String get statNickname => '닉네임';

  @override
  String get statLevel => '레벨';

  @override
  String get statPrestigeCount => '전생 횟수';

  @override
  String get statPrestigeBonus => '전생 보너스';

  @override
  String get statJoinDate => '가입일';

  @override
  String get statPlayDays => '플레이 일수';

  @override
  String get statTotalBattle => '총 스테이지 전투';

  @override
  String get statTeamBattle => '팀 누적 전투';

  @override
  String get statStageProgress => '스테이지 진행';

  @override
  String get statBestClear => '최고 클리어';

  @override
  String get statDungeonBest => '무한던전 최고층';

  @override
  String get statOwnedMonster => '보유 몬스터';

  @override
  String get statCollection => '도감 수집';

  @override
  String get statBestLevel => '최고 레벨';

  @override
  String get statTeamComp => '팀 편성';

  @override
  String get statAvgLevel => '평균 레벨';

  @override
  String get statTotalGacha => '총 소환 횟수';

  @override
  String get statCurrentPity => '현재 천장';

  @override
  String get statFiveStarGuarantee => '5성 보장';

  @override
  String get statGuaranteeImminent => '보장 임박!';

  @override
  String statGuaranteeRemain(int count) {
    return '$count회 남음';
  }

  @override
  String get statOwnedRelic => '보유 유물';

  @override
  String get statEquippedRelic => '장착 유물';

  @override
  String get statCompletedQuest => '완료 퀘스트';

  @override
  String get statClaimable => '수령 가능';

  @override
  String countUnit(String count) {
    return '$count회';
  }

  @override
  String countMonster(int count) {
    return '$count마리';
  }

  @override
  String countItem(int count) {
    return '$count개';
  }

  @override
  String countDay(int count) {
    return '$count일';
  }

  @override
  String countFloor(int floor) {
    return '$floor층';
  }

  @override
  String get onboardingWelcome => '몬스터 컬렉터에 오신 걸 환영합니다!';

  @override
  String get onboardingEnterName => '모험가의 이름을 입력해주세요';

  @override
  String get onboardingNameHint => '닉네임 (2-12자)';

  @override
  String onboardingChooseMonster(String name) {
    return '$name님,\n첫 번째 동료를 선택하세요!';
  }

  @override
  String get onboardingStart => '모험 시작!';

  @override
  String get tutorialStep1Title => '첫 전투를 시작하세요!';

  @override
  String get tutorialStep1Msg =>
      '아래 \"전투 시작\" 버튼을 눌러\n첫 번째 전투를 시작해보세요.\n자동전투와 배속 기능도 있어요!';

  @override
  String get tutorialStep2Title => '승리를 축하합니다!';

  @override
  String get tutorialStep2Msg => '보상을 받은 후\n하단의 \"소환\" 탭에서\n새로운 몬스터를 소환해보세요!';

  @override
  String get tutorialStep3Title => '몬스터를 소환하세요!';

  @override
  String get tutorialStep3Msg =>
      '다이아몬드나 소환권으로\n몬스터를 소환할 수 있어요.\n높은 등급 몬스터를 노려보세요!';

  @override
  String get tutorialStep4Title => '몬스터를 강화하세요!';

  @override
  String get tutorialStep4Msg =>
      '\"강화\" 탭에서 몬스터를 선택하고\n골드로 레벨업하거나\n진화시킬 수 있어요!';

  @override
  String get tutorialStep5Title => '팀을 편성하세요!';

  @override
  String get tutorialStep5Msg =>
      '\"도감\" 탭에서 팀 편성 버튼을 눌러\n최대 4마리 몬스터로\n최강 팀을 구성해보세요!';

  @override
  String get affinityNames => '없음,Lv.1 관심,Lv.2 신뢰,Lv.3 우정,Lv.4 유대,Lv.5 최대';

  @override
  String affinityBattleCount(int count) {
    return '전투 $count회';
  }

  @override
  String affinityBonus(int percent) {
    return '보너스: 전 스탯 +$percent%';
  }

  @override
  String get elementFire => '화염';

  @override
  String get elementWater => '물';

  @override
  String get elementElectric => '전기';

  @override
  String get elementRock => '바위';

  @override
  String get elementGrass => '풀';

  @override
  String get elementGhost => '유령';

  @override
  String get elementLight => '빛';

  @override
  String get elementDark => '어둠';

  @override
  String playerLevelStage(int level, String stage) {
    return 'Lv.$level  |  스테이지 $stage';
  }

  @override
  String get dailyStatus => '일일 현황';

  @override
  String questRewardAvailable(int count) {
    return '퀘스트 보상 $count개 수령 가능!';
  }

  @override
  String questInProgress(int count) {
    return '진행중 퀘스트 $count개';
  }

  @override
  String get shortcut => '바로가기';

  @override
  String prestigeN(int level) {
    return '전생 $level';
  }

  @override
  String get attendanceTitle => '일일 출석 보상';

  @override
  String attendanceDesc(int days) {
    return '누적 출석 $days일째';
  }

  @override
  String get attendanceCheckIn => '출석 체크!';

  @override
  String attendanceDay(int day) {
    return 'Day $day';
  }

  @override
  String attendanceRewardGold(int amount) {
    return '골드 $amount';
  }

  @override
  String attendanceRewardDiamond(int amount) {
    return '다이아 $amount';
  }

  @override
  String attendanceRewardTicket(int amount) {
    return '소환권 $amount';
  }

  @override
  String attendanceRewardPotion(int amount) {
    return '경험치 물약 $amount';
  }

  @override
  String get attendanceClaimed => '출석 보상을 받았습니다!';

  @override
  String get attendanceAlreadyClaimed => '오늘은 이미 출석했습니다';

  @override
  String get towerTitle => '도전의 탑';

  @override
  String get towerStart => '도전 시작';

  @override
  String get towerReady => '도전 준비 완료!';

  @override
  String get towerNoAttempts => '이번 주 도전 횟수 소진';

  @override
  String towerAttempts(int remaining, int max) {
    return '남은 도전: $remaining/$max';
  }

  @override
  String towerBest(int floor) {
    return '최고 $floor층';
  }

  @override
  String get towerNextFloor => '다음 층';

  @override
  String get towerCollect => '보상 수집';

  @override
  String get towerComplete => '탑 정복 완료!';

  @override
  String get towerNoHeal => '층 사이 회복 없음!';

  @override
  String get recipeTitle => '조합 레시피';

  @override
  String get recipeHidden => '히든 몬스터';

  @override
  String get recipeUnlocked => '해금됨';

  @override
  String get recipeLocked => '???';

  @override
  String get recipeHint => '특정 몬스터 조합으로 히든 몬스터를 해금하세요!';

  @override
  String get recipeMatch => '레시피 발견!';

  @override
  String get seasonPassTitle => '시즌 패스';

  @override
  String seasonPassLevel(int level) {
    return 'Lv.$level';
  }

  @override
  String seasonPassDaysLeft(int days) {
    return '남은 기간: $days일';
  }

  @override
  String get seasonPassFree => '수령';

  @override
  String get seasonPassPremium => '수령';

  @override
  String get seasonPassPremiumActive => '프리미엄';

  @override
  String get seasonPassPremiumBuy => '프리미엄 잠금';

  @override
  String get seasonPassPremiumBadge => 'PREMIUM';

  @override
  String get trainingTitle => '트레이닝';

  @override
  String get trainingDesc => '몬스터를 배치하면 시간 경과 후 자동으로 경험치를 획득합니다';

  @override
  String get trainingEmpty => '몬스터 배치하기';

  @override
  String get trainingSelectMonster => '트레이닝할 몬스터 선택';

  @override
  String get trainingDuration => '트레이닝 시간 선택';

  @override
  String get trainingComplete => '완료!';

  @override
  String get trainingRemaining => '남음';

  @override
  String get trainingCollect => '수집';

  @override
  String get trainingCancel => '취소';

  @override
  String get trainingNoMonsters => '배치 가능한 몬스터가 없습니다';

  @override
  String get leaderboardTitle => '랭킹';

  @override
  String get leaderboardArena => '아레나';

  @override
  String get leaderboardDungeon => '던전';

  @override
  String get leaderboardTower => '탑';

  @override
  String get leaderboardBoss => '월드보스';

  @override
  String get leaderboardMyRank => '내 순위';

  @override
  String get leaderboardPlayers => '명 참여';

  @override
  String get titleScreenTitle => '칭호';

  @override
  String get titleCurrent => '현재 칭호';

  @override
  String get titleNone => '칭호 없음';

  @override
  String get titleHidden => '숨겨진 업적을 달성하면 해금됩니다';

  @override
  String get titleEquip => '장착';

  @override
  String get titleUnequip => '해제';

  @override
  String get mailboxTitle => '우편함';

  @override
  String get mailboxEmpty => '우편이 없습니다';

  @override
  String get mailboxClaim => '수령';

  @override
  String get mailboxClaimed => '수령 완료';

  @override
  String get mailboxClaimAll => '모두 수령';

  @override
  String get shopTitle => '상점';

  @override
  String get shopExchange => '재화 교환';

  @override
  String get shopItems => '아이템 구매';

  @override
  String get shopBuy => '구매';

  @override
  String get shopBuyGold => '골드 구매';

  @override
  String get shopBuyDiamond => '다이아 구매';

  @override
  String get shopBuyTicket => '소환권 x1';

  @override
  String get shopBuyTicketDesc => '다이아 30개로 소환권 1장 구매';

  @override
  String get shopBuyTicket10 => '소환권 x10';

  @override
  String get shopBuyTicket10Desc => '다이아 250개로 소환권 10장 (17% 할인)';

  @override
  String get shopBuyExpPotion => '경험치 물약 x1';

  @override
  String get shopBuyExpPotionDesc => '골드 500으로 경험치 물약 1개 구매';

  @override
  String get shopBuyExpPotion10 => '경험치 물약 x10';

  @override
  String get shopBuyExpPotion10Desc => '골드 4,000으로 경험치 물약 10개 (20% 할인)';

  @override
  String get shopBuyShard => '소환석 x5';

  @override
  String get shopBuyShardDesc => '다이아 20개로 소환석 5개 구매';

  @override
  String get shopBuyShard10 => '소환석 x20';

  @override
  String get shopBuyShard10Desc => '다이아 70개로 소환석 20개 (13% 할인)';

  @override
  String get shopInsufficient => '재화가 부족합니다';

  @override
  String get shopPurchaseSuccess => '구매 완료!';

  @override
  String get repeatBattle => '반복';

  @override
  String get nicknameTitle => '닉네임 설정';

  @override
  String get nicknameReset => '초기화';

  @override
  String get dailyDungeonTitle => '일일 던전';

  @override
  String get dailyDungeonTheme => '던전';

  @override
  String get dailyDungeonDesc => '요일별 속성 테마 던전. 보상 1.5배!';

  @override
  String get dailyDungeonRemaining => '남은 도전';

  @override
  String get dailyDungeonStart => '던전 입장';

  @override
  String get dailyDungeonCleared => '클리어!';

  @override
  String get dailyDungeonNext => '다음 층';

  @override
  String get dailyDungeonComplete => '던전 완료!';

  @override
  String get dailyDungeonDefeated => '패배';

  @override
  String get dailyDungeonCollect => '보상 수령';

  @override
  String get dailyDungeonExitConfirm => '현재까지 획득한 보상을 수령하고 나가시겠습니까?';

  @override
  String get elementMatchup => '속성 상성표';

  @override
  String get elementMatchupDesc => '공격 시 상성 배율 (🔼1.3x 유리 / 🔽0.7x 불리)';

  @override
  String get superEffective => '유리';

  @override
  String get notEffective => '불리';

  @override
  String get passiveSkill => '패시브 스킬';

  @override
  String get ultimateSkill => '궁극기';

  @override
  String ultCharge(int charge) {
    return '차지: $charge';
  }

  @override
  String get evolutionTree => '진화 트리';

  @override
  String get evoStageBase => '기본';

  @override
  String get evoStageFirst => '1차 진화';

  @override
  String get evoStageFinal => '최종 진화';

  @override
  String get evoCurrentMark => '현재';

  @override
  String get triggerOnTurnStart => '턴 시작';

  @override
  String get triggerOnAttack => '공격 시';

  @override
  String get triggerOnDamaged => '피격 시';

  @override
  String get triggerBattleStart => '전투 시작';

  @override
  String achievementPoints(int points) {
    return '업적 포인트: ${points}P';
  }

  @override
  String get replayTitle => '전투 기록';

  @override
  String get replayEmpty => '전투 기록이 없습니다';

  @override
  String get replayClear => '기록 삭제';

  @override
  String get replayClearConfirm => '모든 전투 기록을 삭제하시겠습니까?';

  @override
  String get replayVictory => '승리';

  @override
  String get replayDefeat => '패배';

  @override
  String get replayTurns => '턴';

  @override
  String get replayActions => '액션';

  @override
  String get replayMyTeam => '아군';

  @override
  String get replayEnemyTeam => '적군';

  @override
  String get relicEnhance => '강화';

  @override
  String get teamPreset => '팀 프리셋';

  @override
  String presetSlot(int index) {
    return '슬롯 $index';
  }

  @override
  String get presetEmpty => '비어있음';

  @override
  String get presetSave => '현재 팀 저장';

  @override
  String get presetLoad => '불러오기';

  @override
  String get presetDelete => '삭제';

  @override
  String get presetRename => '이름 변경';

  @override
  String get presetNameHint => '프리셋 이름 (최대 10자)';

  @override
  String get presetSaved => '프리셋이 저장되었습니다';

  @override
  String get presetLoaded => '프리셋을 불러왔습니다';

  @override
  String get presetDeleted => '프리셋이 삭제되었습니다';

  @override
  String get presetDeleteConfirm => '이 프리셋을 삭제하시겠습니까?';

  @override
  String get presetMissing => '일부 몬스터가 없어 불러올 수 없습니다';

  @override
  String get compareTitle => '몬스터 비교';

  @override
  String get compareSelectTwo => '비교할 몬스터 2마리를 선택하세요';

  @override
  String get compareSelectMonster => '몬스터 선택';

  @override
  String get sortDefault => '기본';

  @override
  String get sortName => '이름순';

  @override
  String get sortRarity => '등급순';

  @override
  String get sortLevel => '레벨순';

  @override
  String get sortPower => '전투력순';

  @override
  String get gachaHistoryTitle => '소환 기록';

  @override
  String get gachaHistoryEmpty => '소환 기록이 없습니다';

  @override
  String gachaHistoryTotal(int count) {
    return '총 $count회 소환';
  }

  @override
  String get gachaHistoryClearConfirm => '모든 소환 기록을 삭제하시겠습니까?';

  @override
  String achievementToast(String name) {
    return '업적 달성! $name';
  }

  @override
  String get achievementTapToView => '탭하여 확인';

  @override
  String get settingsNotification => '알림';

  @override
  String get settingsNotificationToggle => '푸시 알림';

  @override
  String get stageSkip => '스킵';

  @override
  String get stageSkipResult => '스테이지 스킵 완료!';

  @override
  String stageSkipGold(int gold) {
    return '골드 +$gold';
  }

  @override
  String stageSkipExp(int exp) {
    return '경험치 +$exp';
  }

  @override
  String get favorite => '즐겨찾기';

  @override
  String get favoriteOnly => '즐겨찾기만';

  @override
  String get settingsTheme => '테마';

  @override
  String get settingsThemeDark => '다크';

  @override
  String get settingsThemeLight => '라이트';

  @override
  String get onboardingSetupError => '설정 중 오류가 발생했습니다. 다시 시도해주세요.';

  @override
  String get gachaPityLabel => '천장';

  @override
  String get collectionUnknownMonster => '미발견 몬스터';

  @override
  String get semanticPlayer => '플레이어';

  @override
  String waveProgress(String name, int current, int total) {
    return '$name - 웨이브 $current/$total';
  }

  @override
  String get turnLabel => '턴';

  @override
  String get skinTitle => '스킨';

  @override
  String get skinEquipped => '장착 중';

  @override
  String get skinEquip => '장착';

  @override
  String get skinUnequip => '해제';

  @override
  String get skinUnlock => '해금';

  @override
  String get skinUnlocked => '해금 완료';

  @override
  String get skinLocked => '잠김';

  @override
  String skinCost(int cost) {
    return '소환석 $cost개';
  }

  @override
  String get skinUnlockSuccess => '스킨을 해금했습니다!';

  @override
  String get skinEquipSuccess => '스킨을 장착했습니다!';

  @override
  String get skinUnequipSuccess => '스킨을 해제했습니다.';

  @override
  String get skinInsufficientShards => '소환석이 부족합니다.';

  @override
  String get skinNone => '장착된 스킨이 없습니다';

  @override
  String get skinUniversal => '모든 몬스터';

  @override
  String skinElementOnly(String element) {
    return '$element 속성 전용';
  }

  @override
  String get skinExclusive => '전용 스킨';

  @override
  String get offlineRewardTitle => '오프라인 보상';

  @override
  String offlineRewardTime(String time) {
    return '$time 동안 모은 보상';
  }

  @override
  String offlineHoursMinutes(int h, int m) {
    return '$h시간 $m분';
  }

  @override
  String offlineHours(int h) {
    return '$h시간';
  }

  @override
  String offlineMinutes(int m) {
    return '$m분';
  }

  @override
  String get offlineMaxReward => '최대 보상 시간에 도달했습니다';

  @override
  String get offlineClaim => '보상 받기';

  @override
  String msgLevelUp(int level) {
    return 'Lv.$level 달성!';
  }

  @override
  String msgExpPotionLevelUp(int level, int gained) {
    return 'Lv.$level 달성! (+$gained)';
  }

  @override
  String get msgExpGained => '경험치 획득!';

  @override
  String get msgEvolution1 => '1차 진화 성공!';

  @override
  String get msgEvolution2 => '최종 진화 성공!';

  @override
  String msgFusionHidden(String name, int rarity) {
    return '$name 해금! ($rarity성 히든)';
  }

  @override
  String msgFusionNormal(String name, int rarity) {
    return '$name 획득! ($rarity성)';
  }

  @override
  String msgAwakening(int stars) {
    return '각성 $stars성 달성! (+10% 스탯)';
  }

  @override
  String msgTrainingStart(String name) {
    return '$name 트레이닝 시작!';
  }

  @override
  String msgTrainingCollect(String name, int xp) {
    return '$name +${xp}XP';
  }

  @override
  String msgTrainingCollectLevelUp(String name, int xp, int oldLv, int newLv) {
    return '$name +${xp}XP (Lv.$oldLv→$newLv)';
  }

  @override
  String get msgTrainingCancel => '트레이닝 취소';

  @override
  String msgExpeditionStart(int hours) {
    return '원정 출발! ($hours시간)';
  }

  @override
  String msgRewardSummary(String rewards) {
    return '보상 수령: $rewards';
  }

  @override
  String rewardGold(int amount) {
    return '골드 +$amount';
  }

  @override
  String rewardExpPotion(int amount) {
    return '경험치포션 +$amount';
  }

  @override
  String rewardShard(int amount) {
    return '진화석 +$amount';
  }

  @override
  String rewardDiamond(int amount) {
    return '다이아 +$amount';
  }

  @override
  String rewardGachaTicket(int amount) {
    return '소환권 +$amount';
  }

  @override
  String msgPrestige(int level, int bonus, int diamonds, int tickets) {
    return '전생 $level회 완료! 보너스 +$bonus%, 다이아 +$diamonds, 소환권 +$tickets';
  }

  @override
  String get mailWelcomeTitle => '환영합니다!';

  @override
  String get mailWelcomeBody => '몬스터 수집 게임에 오신 것을 환영합니다! 시작 선물을 받아주세요.';

  @override
  String get mailDailyTitle => '일일 접속 보상';

  @override
  String get mailDailyBody => '매일 접속해 주셔서 감사합니다! 오늘의 보상입니다.';

  @override
  String get mailWeeklyTitle => '주간 보너스';

  @override
  String get mailWeeklyBody => '이번 주도 화이팅! 주간 보너스 보상입니다.';

  @override
  String milestoneCollect(int count) {
    return '$count종 수집';
  }

  @override
  String get milestoneComplete => '도감 완성!';

  @override
  String skillCd(int cd) {
    return 'CD: $cd턴';
  }

  @override
  String get tagAll => '전체';

  @override
  String get tagSingle => '단일';

  @override
  String tagShield(int pct) {
    return '방패 $pct%';
  }

  @override
  String tagHeal(int pct) {
    return '힐 $pct%';
  }

  @override
  String tagDrain(int pct) {
    return '흡수 $pct%';
  }

  @override
  String tagBurn(int turns) {
    return '화상 $turns턴';
  }

  @override
  String tagStun(int pct) {
    return '기절 $pct%';
  }

  @override
  String tagHpRegen(int pct) {
    return 'HP회복 $pct%';
  }

  @override
  String tagCounter(int pct) {
    return '반격 $pct%';
  }

  @override
  String tagCrit(int pct) {
    return '크리 +$pct%';
  }

  @override
  String affinityNext(int battles, int bonus) {
    return '다음 레벨까지 $battles회 (보너스: +$bonus%)';
  }

  @override
  String relicInfo(String stat, int value, int rarity) {
    return '$stat +$value | $rarity성';
  }

  @override
  String teamSummary(String power, int count, int owned, int total) {
    return '전투력 $power  |  팀 $count/4  |  도감 $owned/$total';
  }

  @override
  String monsterLevelInfo(int level, int stage) {
    return 'Lv.$level  |  진화 $stage단계';
  }

  @override
  String timerHMS(int h, int m, int s) {
    return '$h시간 $m분 $s초';
  }

  @override
  String timerMS(int m, int s) {
    return '$m분 $s초';
  }

  @override
  String timerS(int s) {
    return '$s초';
  }

  @override
  String get notifCapTitle => '오프라인 보상 최대치 도달!';

  @override
  String get notifCapBody => '보상이 더 쌓이지 않아요. 접속해서 수령하세요!';

  @override
  String get notifComeBackTitle => '몬스터들이 기다리고 있어요!';

  @override
  String get notifComeBackBody => '오프라인 보상이 가득 찼어요. 지금 접속하세요!';

  @override
  String get notifChannelName => '게임 알림';

  @override
  String get notifChannelDesc => '오프라인 보상 및 리마인더 알림';

  @override
  String expeditionOptionLabel(int h) {
    return '$h시간 원정';
  }

  @override
  String get synergyNone => '활성 시너지 없음';

  @override
  String get tabMonster => '몬스터';

  @override
  String get tabSkillSummon => '스킬';

  @override
  String get tabRelicSummon => '장비';

  @override
  String get tabMountSummon => '탈것';

  @override
  String get skillSummonTitle => '스킬 소환';

  @override
  String get skillSummonDesc => '강력한 스킬을 획득하세요';

  @override
  String get relicSummonTitle => '장비 소환';

  @override
  String get relicSummonDesc => '희귀한 장비를 획득하세요';

  @override
  String get mountSummonTitle => '탈것 소환';

  @override
  String get mountSummonDesc => '전설의 탈것을 획득하세요';

  @override
  String get pull1 => '1회 소환';

  @override
  String get pull10 => '10회 소환';

  @override
  String get pull100 => '100회 소환';

  @override
  String get shopTabGeneral => '일반';

  @override
  String get shopTabSummon => '소환';

  @override
  String get shopTabCurrency => '재화';

  @override
  String get shopHeader => '상점';

  @override
  String get shopSkillTicket => '스킬 티켓';

  @override
  String get shopSkillTicket1 => '스킬 티켓 x1';

  @override
  String get shopSkillTicket1Desc => '스킬 소환에 사용';

  @override
  String get shopSkillTicket10 => '스킬 티켓 x10';

  @override
  String get shopRelicTicket => '장비 티켓';

  @override
  String get shopRelicTicket1 => '장비 티켓 x1';

  @override
  String get shopRelicTicket1Desc => '장비 소환에 사용';

  @override
  String get shopRelicTicket10 => '장비 티켓 x10';

  @override
  String get shopMountGem => '탈것 젬';

  @override
  String get shopMountGem300 => '탈것 젬 x300';

  @override
  String get shopMountGem300Desc => '탈것 소환 1회분';

  @override
  String get shopMountGem3000 => '탈것 젬 x3000';

  @override
  String get shopMountGem3000Desc => '탈것 소환 10회분 + 보너스';

  @override
  String get shopCurrencyExchange => '재화 교환';

  @override
  String get shopBulkGold => '골드 대량 구매';

  @override
  String get mapHubTitle => '월드맵';

  @override
  String get mapHubCurrent => '현재';

  @override
  String get mapArea1 => '시작의 숲';

  @override
  String get mapArea2 => '불꽃 화산';

  @override
  String get mapArea3 => '암흑 던전';

  @override
  String get mapArea4 => '심해 신전';

  @override
  String get mapArea5 => '천공 성역';

  @override
  String get heroHeader => '영웅';

  @override
  String get heroTabEquipment => '장비';

  @override
  String get heroTabInventory => '인벤토리';

  @override
  String get heroTabFusion => '합성/분해';

  @override
  String get heroSkillLabel => '스킬';

  @override
  String get heroMountLabel => '탈것';

  @override
  String get heroNoSkill => '장착된 스킬 없음';

  @override
  String get heroNoMount => '장착된 탈것 없음';

  @override
  String get heroNoSkillOwned => '보유한 스킬이 없습니다. 소환에서 획득하세요!';

  @override
  String get heroNoMountOwned => '보유한 탈것이 없습니다. 소환에서 획득하세요!';

  @override
  String get heroNoEquipment => '보유한 장비가 없습니다';

  @override
  String get heroGetFromSummon => '소환에서 스킬과 탈것을 획득하세요!';

  @override
  String get heroEquipped => '장착중';

  @override
  String get heroGoldInsufficient => '골드가 부족합니다';

  @override
  String get heroBattleStats => '전투 능력치';

  @override
  String get heroTraining => '훈련';

  @override
  String heroEnhanceComplete(String name, int level) {
    return '$name Lv.$level 강화 완료!';
  }

  @override
  String heroNextValue(String value) {
    return '다음: $value';
  }

  @override
  String heroLevelHero(int level) {
    return 'Lv.$level 영웅';
  }

  @override
  String heroFusionComplete(String name, int level) {
    return '$name 합성! Lv.$level';
  }

  @override
  String heroDismantleComplete(String name, int gold, int shard) {
    return '$name 분해! +${gold}G, +$shard샤드';
  }

  @override
  String heroDismantleReward(int gold, int shard) {
    return '+${gold}G · +$shard샤드';
  }

  @override
  String get heroSkillTypeHpRegen => 'HP 회복';

  @override
  String get heroUnequip => '해제';

  @override
  String get heroTapToEquip => '탭하여 장착';

  @override
  String get heroSelectSkill => '스킬 선택';

  @override
  String get heroSelectMount => '탈것 선택';

  @override
  String heroOwned(int count) {
    return '보유: $count개';
  }

  @override
  String get heroFusion => '합성';

  @override
  String get heroDismantle => '분해';

  @override
  String get heroFusionDesc => '동일 장비 2개 → 레벨 +1 합성';

  @override
  String get heroDismantleDesc => '장비 분해 → 골드 + 샤드 획득 (장착중 불가)';

  @override
  String get heroNoFusible => '합성 가능한 중복 장비가 없습니다';

  @override
  String get heroNoDismantleable => '분해 가능한 장비가 없습니다';

  @override
  String get heroNoFusionItems => '합성/분해할 장비가 없습니다';

  @override
  String get heroMaxLevel => '이미 최대 레벨입니다';

  @override
  String heroOwnedCount(int count) {
    return '보유 $count개';
  }

  @override
  String get heroTotal => '합계';

  @override
  String get heroSkillTypeDamage => '피해';

  @override
  String get heroSkillTypeDefBuff => '방어 버프';

  @override
  String get heroSkillTypeAtkBuff => '공격 버프';

  @override
  String get heroSkillTypeSpeedBuff => '속도 버프';

  @override
  String get heroSkillTypeCritBoost => '치명타 강화';

  @override
  String get quickNavHero => '영웅';

  @override
  String get quickNavWorldMap => '월드맵';

  @override
  String get battleSkip => '스킵';

  @override
  String get statTowerHighest => '탑 최고층';

  @override
  String get statArenaRating => '아레나 레이팅';

  @override
  String get statGuildContrib => '길드 기여도';

  @override
  String get statExpeditionGold => '원정대 누적 수익';

  @override
  String get ownedSkillTicket => '보유 스킬 티켓';

  @override
  String get ownedRelicTicket => '보유 장비 티켓';

  @override
  String get ownedMountGem => '보유 탈것 젬';

  @override
  String get pityUntil => '천장까지';

  @override
  String pityRemaining(int count) {
    return '$count회 남음';
  }

  @override
  String get tabTrain => '훈련/연구';

  @override
  String get tabHero => '히어로';

  @override
  String get trainTitle => '훈련/연구';

  @override
  String get trainUpgradeCard => '몬스터 강화';

  @override
  String get trainUpgradeDesc => '레벨업, 진화, 각성, 융합';

  @override
  String get trainTrainingCard => '트레이닝';

  @override
  String get trainTrainingDesc => '몬스터를 훈련시켜 경험치 획득';

  @override
  String get trainExpeditionCard => '원정대';

  @override
  String get trainExpeditionDesc => '몬스터를 파견하여 보상 획득';

  @override
  String get sidebarDungeon => '던전';

  @override
  String get sidebarTower => '타워';

  @override
  String get sidebarWorldBoss => '월보';

  @override
  String get sidebarArena => '아레나';

  @override
  String get sidebarEvent => '이벤트';

  @override
  String get sidebarGuild => '길드';

  @override
  String get sidebarQuest => '퀘스트';

  @override
  String get sidebarSettings => '설정';

  @override
  String get sidebarRelic => '유물';

  @override
  String get sidebarDailyDungeon => '일일';

  @override
  String get sidebarMap => '지도';

  @override
  String get sidebarSeasonPass => '시즌';

  @override
  String get sidebarLeaderboard => '랭킹';

  @override
  String get sidebarTitle => '칭호';

  @override
  String get sidebarMailbox => '우편';

  @override
  String get sidebarReplay => '리플레이';

  @override
  String get sidebarStats => '통계';

  @override
  String get sidebarPrestige => '전생';

  @override
  String get sidebarCollection => '도감';

  @override
  String stageProgress(Object defeated, Object total) {
    return '$defeated/$total';
  }

  @override
  String get autoRepeat => '자동 반복';

  @override
  String get shopBulkDiscount => '17% 할인';

  @override
  String get shopExchangeGoldDesc => '10 💎 → 1,000 골드';

  @override
  String get shopExchangeBulkGoldDesc => '90 💎 → 10,000 골드';

  @override
  String sweepAll(Object count) {
    return '⚡ 전체 소탕 ($count스테이지)';
  }

  @override
  String sweepComplete(Object count) {
    return '$count스테이지 소탕 완료!';
  }

  @override
  String get fusionPreviewHint => '탭하여 미리보기';

  @override
  String fusionPreviewTitle(Object stars) {
    return '$stars 가능한 결과';
  }

  @override
  String fusionPreviewDesc(Object count) {
    return '총 $count종의 몬스터 중 랜덤';
  }

  @override
  String get teamRecommend => '최강 팀 추천';

  @override
  String get relicFuse => '유물 융합';

  @override
  String get relicFuseDesc => '같은 등급 유물 2개 → 상위 등급 랜덤 유물';

  @override
  String get relicFuseExecute => '융합 실행';

  @override
  String get relicFuseSuccess => '융합 성공!';

  @override
  String get newRecord => '신기록!';

  @override
  String hpDisplay(String current, String max) {
    return 'HP: $current / $max';
  }

  @override
  String mvpLabel(String name) {
    return 'MVP: $name';
  }

  @override
  String guildExpDisplay(int current, int max) {
    return 'EXP: $current/$max';
  }

  @override
  String get challengeTitle => '도전 모드';

  @override
  String get challengeDesc => '특별 조건으로 추가 보상을 획득하세요';

  @override
  String get challengeName_turnLimit => '턴 제한';

  @override
  String get challengeName_noHealing => '회복 불가';

  @override
  String get challengeName_bossRush => '보스 러쉬';

  @override
  String get challengeName_speedRun => '스피드 런';

  @override
  String challengeName(String name) {
    return '$name';
  }

  @override
  String challengeReward(int percent) {
    return '+$percent% 보상';
  }

  @override
  String get challengeTurnLimit => '15턴 내에 클리어';

  @override
  String get relicDismantle => '유물 일괄 분해';

  @override
  String relicDismantleDesc(int count) {
    return '미장착 유물 $count개';
  }

  @override
  String relicDismantleConfirm(int rarity) {
    return '$rarity성 이하 미장착 유물을 모두 분해하시겠습니까?';
  }

  @override
  String relicDismantleResult(int gold) {
    return '분해 완료! +$gold G';
  }

  @override
  String get bannerFlameDragon => '화염드래곤 픽업';

  @override
  String get bannerFlameDragonDesc => '화염드래곤 & 피닉스 확률 대폭 UP!';

  @override
  String get bannerArchangel => '대천사 픽업';

  @override
  String get bannerArchangelDesc => '대천사 & 얼음여왕 확률 대폭 UP!';

  @override
  String get bannerDarkKnight => '암흑기사 픽업';

  @override
  String get bannerDarkKnightDesc => '암흑기사 & 피닉스 확률 대폭 UP!';

  @override
  String get bannerIceQueen => '얼음여왕 픽업';

  @override
  String get bannerIceQueenDesc => '얼음여왕 & 피닉스 확률 대폭 UP!';

  @override
  String get bannerPickupLabel => '★ PICK UP ★';

  @override
  String get bannerRateUp => '확률UP';

  @override
  String bannerTimeRemaining(int hours) {
    return '$hours시간 남음';
  }

  @override
  String get bannerPickupTag => 'PICK UP!';
}
