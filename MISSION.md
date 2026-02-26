# 몬스터 수집 방치형 게임 - 미션 추적

## 현재 Phase: 고도화 작업 진행 중 (Feature 9 다음)

## 기본 개발 (Phase 1-7) - 전체 완료
- [x] Phase 1~7 전체 완료 (자동전투, 가챠, 강화/진화, 오프라인보상, 도감, 폴리싱)

## 코드 최적화 (완료)
- [x] MonsterElement.fromName(), 배치저장, _rollDamage(), spread/lazy Iterable

## 고도화 작업 (Feature #1~#10)
- [x] Feature 1: 시너지 시스템 전투 연결
  - BattleService.createPlayerTeam() → SynergyService 호출, 스탯 배율 적용
  - BattleState.activeSynergies, battle_screen 시너지 배지 UI
- [x] Feature 2: 스테이지 선택 화면
  - StageSelectScreen: 5 Area 탭 + 6 Stage 그리드
  - 클리어/현재/잠금, 보상 미리보기, 탭하여 전투
- [x] Feature 3: 로컬 알림 시스템
  - NotificationService: 12h 오프라인 캡 + 24h 복귀 리마인더
  - flutter_local_notifications v20, HomeScreen lifecycle 연동
- [x] Feature 4: 일일퀘스트/업적 시스템
  - QuestModel (Hive typeId:3), QuestDatabase (6일일+6업적=12개)
  - QuestProvider: 트리거 기반 진행추적, 일일 리셋, 보상 수령
  - QuestScreen: 일일/업적 탭, 진행바, 수령 버튼
  - 6번째 탭 '퀘스트', 전투/가챠/강화/진화/클리어/수집 트리거 연동
- [x] Feature 5: 몬스터 스킬 시스템
  - skill_database.dart: 20개 몬스터별 고유 스킬 (데미지/쉴드/힐/화상/기절/흡수/AOE)
  - BattleMonster에 skillId/skillCooldown/shieldHp/burnTurns/stunTurns 추가
  - BattleService: processSkill(), processBurn(), processStun(), 쉴드흡수
  - battle_provider processTurn 턴플로우: 화상→기절→스킬/일반공격
  - MonsterBattleCard: 스킬준비표시, 상태이상아이콘, CD카운터
  - HpBar 쉴드오버레이, 로그 스킬발동 보라색 강조
- [x] Feature 6: 무한 던전
  - DungeonService: 층별 적 스케일링 (레벨=5+floor*2), 랜덤 구성, 층간 20% 회복
  - DungeonProvider: fighting/floorCleared/defeated 상태, 누적 보상
  - DungeonScreen: 전용 전투UI, 누적보상 바, 자동전투/속도
  - PlayerModel maxDungeonFloor (HiveField 11), 최고기록 추적
  - battle_screen 대기화면 무한던전 진입버튼, /dungeon 라우트
- [x] Feature 7: 몬스터 융합
  - UpgradeTab.fusion 추가, 같은 등급 2마리 → 상위 등급 랜덤 몬스터
  - canFuse() 검증 (같은등급, 5성이하, 팀미배치)
  - fusionGoldCost (300*rarity), _FusionPanel UI, _FusionSlot 위젯
  - 융합 실행 시 재료 삭제 + 신규 생성 + 도감/퀘스트 연동
- [x] Feature 8: 전생/프레스티지
  - PlayerModel: prestigeLevel, prestigeBonusPercent (HiveField 12,13)
  - PrestigeService: 조건검증(Lv30+ 또는 3지역+), 보상계산, 보너스배율
  - PrestigeProvider: 전생 실행 (리셋 + 다이아/소환권 보상 + 영구배율)
  - PrestigeScreen: 배지, 조건/보상/손실 표시, 확인 다이얼로그
  - 전투/던전/오프라인 보상에 프레스티지 배율 적용 (+10%/전생)
  - 설정화면 전생진입 버튼, /prestige 라우트
- [ ] Feature 9: 월드 보스
- [ ] Feature 10: 유물/장비

## 핵심 파일 (고도화에서 추가/수정)
### 추가
- lib/presentation/screens/stage_select/stage_select_screen.dart
- lib/domain/services/notification_service.dart
- lib/data/models/quest_model.dart
- lib/data/static/quest_database.dart
- lib/presentation/providers/quest_provider.dart
- lib/presentation/screens/quest/quest_screen.dart
- lib/data/static/skill_database.dart
- lib/domain/services/dungeon_service.dart
- lib/presentation/providers/dungeon_provider.dart
- lib/presentation/screens/dungeon/dungeon_screen.dart

### 수정
- lib/core/enums/monster_element.dart (fromName 추가)
- lib/domain/services/battle_service.dart (createPlayerTeam 시너지, _rollDamage 리팩터)
- lib/presentation/providers/battle_provider.dart (activeSynergies, 퀘스트 트리거)
- lib/presentation/providers/gacha_provider.dart (배치저장, 퀘스트 트리거)
- lib/presentation/providers/upgrade_provider.dart (퀘스트 트리거)
- lib/presentation/screens/battle/battle_screen.dart (시너지배지, 스테이지선택 네비)
- lib/routing/app_router.dart (스테이지선택+퀘스트 라우트)
- lib/presentation/screens/home_screen.dart (6탭, 퀘스트로드, 알림)
- lib/data/datasources/local_storage.dart (quest box 추가)
- lib/main.dart (NotificationService 초기화)
- lib/domain/entities/battle_entity.dart (스킬필드 추가)
- lib/domain/services/battle_service.dart (스킬처리/화상/기절/쉴드)
- lib/presentation/widgets/battle/monster_battle_card.dart (스킬UI)
- lib/presentation/widgets/battle/hp_bar.dart (쉴드 오버레이)
- lib/data/models/player_model.dart (maxDungeonFloor 추가)
- lib/presentation/providers/player_provider.dart (updateMaxDungeonFloor)
- lib/presentation/providers/upgrade_provider.dart (융합 상태+메서드 추가)
- lib/presentation/screens/upgrade/upgrade_screen.dart (융합 탭+_FusionPanel)
- lib/domain/services/prestige_service.dart
- lib/presentation/providers/prestige_provider.dart
- lib/presentation/screens/prestige/prestige_screen.dart
