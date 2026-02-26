# 몬스터 수집 방치형 게임 - 미션 추적

## 현재 Phase: 2차 고도화 진행 중 (A1부터)

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
- [x] Feature 9: 월드 보스
  - WorldBossService: 5종 보스 일일 로테이션, 레벨 스케일링, 턴제한 30턴
  - WorldBossProvider: 하루 3회 도전, 최고 데미지 추적, 딜량 기반 보상
  - WorldBossScreen: 대기/전투/결과 UI, 보스HP바, 데미지카운터
  - battle_screen에 월드보스 진입 버튼, /world-boss 라우트
- [x] Feature 10: 유물/장비
  - RelicModel (Hive typeId:4): 유물 인스턴스 (타입/등급/스탯/장착상태)
  - RelicDatabase: 15종 유물 템플릿 (무기5/방어구5/악세서리5)
  - RelicProvider: 인벤토리 CRUD, 장착/해제, 랜덤 생성, 스탯 보너스
  - RelicScreen: 필터, 유물카드, 상세시트 (장착/해제/분해)
  - 전투/던전/월드보스에 유물 스탯 적용, 던전5층+월드보스 유물 드롭

## 2차 고도화 (A1~C11)
### UI/UX 폴리싱
- [x] A1: 몬스터 비주얼 개선 (속성별 색상+아이콘 시스템)
- [x] A2: 애니메이션 강화 (히트이펙트, 스킬연출, 화면전환)
- [x] A3: 사운드 효과 (진동 피드백 시스템)
  - AudioService: 싱글턴, 전투/가챠/강화/진화 햅틱 피드백
  - battle/dungeon/world_boss_provider: 공격/스킬/승리/패배 피드백
  - gacha_provider: 풀/카드공개/고레어 피드백
  - upgrade_provider: 레벨업/진화/융합 피드백
  - settings_screen: 진동 효과 ON/OFF 토글
- [x] A4: 튜토리얼 (첫 플레이어 단계별 가이드)
  - PlayerModel.tutorialStep (HiveField 14): 단계 추적
  - TutorialOverlay 위젯: 단계별 힌트 오버레이
  - 5단계 흐름: 전투소개→승리→소환→강화→팀편성→완료
  - battle/gacha/upgrade/collection_screen 통합
### 콘텐츠 확장
- [x] B5: PvP 아레나 (AI 대전, 랭킹)
  - ArenaService: AI 상대 생성 (3난이도), 레이팅 시스템
  - ArenaProvider: 로비/전투/결과 상태, 일일 5회 도전
  - ArenaScreen: 상대선택/전투/결과 UI, 랭크 배지
  - battle_screen 아레나 진입 버튼, /arena 라우트
- [x] B6: 이벤트 던전 (기간한정 스테이지)
  - EventDungeonService: 주간 로테이션 2개 이벤트, 속성별 테마
  - EventDungeonProvider: 로비/전투/웨이브클리어/결과 상태
  - EventDungeonScreen: 이벤트목록/전투/보상 UI
  - battle_screen 이벤트던전 진입, /event-dungeon 라우트
- [ ] B7: 길드/클랜 시스템 (공동보스, 길드상점)
- [x] B8: 몬스터 도감 보상 (완성도 보너스)
  - 4단계 마일스톤 (5/10/15/20종), 골드+다이아+소환권 보상
  - PlayerModel.collectionRewardsClaimed(HiveField 15) 비트마스크
  - collectionMilestoneProvider: 달성/수령 상태 추적
  - collection_screen 마일스톤 보상 바 UI
### 시스템 안정성
- [x] C9: 데이터 백업/복원 (JSON export/import)
  - LocalStorage: exportToJson(), importFromJson() 전체 데이터 직렬화
  - settings_screen: 백업(클립보드 복사)/복원(클립보드 붙여넣기) UI
  - Player, Currency, Monster, Quest, Relic 전체 지원
- [x] C10: 밸런스 조정 (난이도, 보상, 스킬 수치)
  - 가챠 천장: 100→80회, 오프라인 경험치 효율: 30%→40%
  - 던전 레벨 스케일링 완화: floor*2→floor*1.8, 회복 20%→25%
  - 스킬: 암흑참격 3.0→2.5×, 번개폭풍 1.2→1.4× AoE, 심판의빛 1.5→1.6×+15%힐, 치유의노래 15→18%힐
  - 월드보스 다이아 보상: damage/5000→damage/4000
- [x] C11: 성능 최적화 + 코드리뷰 버그 수정
  - relic_screen: O(n) 몬스터 룩업 → O(1) 맵 기반 최적화
  - team_edit_screen: 팀 슬롯 룩업 맵 최적화
  - arena_provider: 배열 인덱스 바운드 체크 추가 (HIGH 버그)
  - event_dungeon_provider: nullable force unwrap → null guard (HIGH 버그)
  - world_boss_provider: boss null safety 개선 (HIGH 버그)

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
- lib/domain/services/world_boss_service.dart
- lib/presentation/providers/world_boss_provider.dart
- lib/presentation/screens/world_boss/world_boss_screen.dart
- lib/data/models/relic_model.dart
- lib/data/static/relic_database.dart
- lib/presentation/providers/relic_provider.dart
- lib/presentation/screens/relic/relic_screen.dart
