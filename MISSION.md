# 몬스터 수집 방치형 게임 - 미션 추적

## 현재 Phase: 고도화 작업 진행 중

## 기본 개발 (Phase 1-7) - 전체 완료
- [x] Phase 1: 프로젝트 기반 셋업
- [x] Phase 2: 자동 전투 시스템
- [x] Phase 3: 가챠 시스템
- [x] Phase 4: 강화/진화 시스템
- [x] Phase 5: 오프라인 보상 + 저장
- [x] Phase 6: 도감 + 팀편성
- [x] Phase 7: 폴리싱

## 코드 최적화 (완료)
- [x] MonsterElement.fromName() - O(1) Map lookup (6곳 중복 제거)
- [x] addMonsters() 배치 Hive write (가챠 10연 10→1회)
- [x] _rollDamage() 추출 (데미지 계산 중복 통합)
- [x] List.from() → spread, collection filter lazy Iterable

## 고도화 작업 (Feature #1~#10)
- [x] Feature 1: 시너지 시스템 전투 연결
  - BattleService.createPlayerTeam()에서 SynergyService 호출
  - BattleState에 activeSynergies 필드 추가
  - battle_screen _StageHeader에 시너지 배지 UI
- [x] Feature 2: 스테이지 선택 화면
  - StageSelectScreen: 5 Area 탭 + 6 Stage 그리드
  - 클리어/현재/잠금 상태 표시, 보상 미리보기
  - battle_screen에서 탭하여 접근
- [x] Feature 3: 로컬 알림 시스템
  - NotificationService: 12h 오프라인 캡 + 24h 복귀 리마인더
  - flutter_local_notifications v20 + timezone
  - HomeScreen lifecycle 연동 (paused→스케줄, resumed→취소)
- [ ] Feature 4: 일일퀘스트/업적 시스템
  - quest_model.dart (Hive typeId:3), quest_database.dart
  - QuestService, QuestProvider, QuestScreen
  - 6번째 탭 또는 별도 라우트
- [ ] Feature 5: 몬스터 스킬 시스템
- [ ] Feature 6: 무한 던전
- [ ] Feature 7: 몬스터 융합
- [ ] Feature 8: 전생/프레스티지
- [ ] Feature 9: 월드 보스
- [ ] Feature 10: 유물/장비

## 신규 파일 (고도화)
- lib/presentation/screens/stage_select/stage_select_screen.dart
- lib/domain/services/notification_service.dart
