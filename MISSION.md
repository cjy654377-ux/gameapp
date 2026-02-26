# 몬스터 수집 방치형 게임 - 미션 추적

## 현재 Phase: 고도화 작업 진행 중 (Feature 5 다음)

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
- [ ] Feature 5: 몬스터 스킬 시스템
  - skill_database.dart, skill_entity.dart
  - BattleMonster에 shieldHp/burnTurns/stunTurns/skillCooldown 추가
  - BattleService에 processSkillIfReady() 추가
  - monster_battle_card에 스킬 아이콘 + 발동 표시
- [ ] Feature 6: 무한 던전
- [ ] Feature 7: 몬스터 융합
- [ ] Feature 8: 전생/프레스티지
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
