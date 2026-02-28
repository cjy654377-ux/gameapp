# 몬스터 수집 방치형 게임 - 미션 추적

## 현재 Phase: 7차 고도화 완료 (N1~N10) + 코드 리뷰 최적화

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
- [x] B7: 길드/클랜 시스템 (공동보스, 길드상점)
  - GuildModel (Hive typeId:5): 길드 데이터 (레벨/코인/멤버/보스HP)
  - GuildService: AI 멤버 시뮬레이션, 주간 보스 로테이션 3종, 길드 상점 5종
  - GuildProvider: 길드 생성, 보스전투, 상점 구매, 자동전투
  - GuildScreen: 로비/전투/결과/상점 UI
  - battle_screen 길드 진입 버튼, /guild 라우트
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

## 3차 고도화 (D1~F11)
### UI/UX 고급화
- [x] D1: 몬스터 상세 화면 (풀스크린 프로필, 스탯 레이더, 스킬/유물 표시)
  - CustomScrollView + SliverAppBar, 레이더 차트 CustomPainter
  - 장착 유물/스킬 표시, 도감 → 상세화면 네비게이션
- [x] D2: 전투 결과 통계 (데미지 기여도, MVP, 턴별 요약)
  - BattleStatisticsService: 전투 데이터 분석, 몬스터별 데미지/크리/스킬 통계
  - 승리 다이얼로그 토글 통계 패널, MVP 표시, 데미지 바
- [x] D3: 메인 대시보드 (일일 현황 위젯, 남은 도전횟수)
  - 플레이어 정보, 일일 도전현황 (아레나/월보/길드), 퀘스트 상태, 빠른 이동
### 콘텐츠 심화
- [x] E5: 몬스터 각성 시스템 (최종진화 이후 추가 강화)
  - awakeningStars (최대 5성), 성별 +10% 스탯 보너스
  - 각성 패널 UI: 별 표시, 스탯 미리보기, 비용 표시
- [x] E6: 원정대 시스템 (몬스터 파견 → 시간 경과 보상)
  - ExpeditionModel (Hive typeId:6), 3슬롯, 1h/4h/8h 옵션
  - 타이머 기반 UI, 몬스터 선택기, 보상 수집
- [x] E7: 주간 퀘스트 시스템
  - QuestType.weekly 추가, 주간 퀘스트 4종
  - 주간 리셋 (매주 월요일), 퀘스트 화면 3탭 (일일/주간/업적)
- [x] E8: 몬스터 친밀도 (전투 참여 → 보너스 스탯)
  - battleCount (HiveField 17), affinityLevel 0~5, +2%/레벨 스탯
### 시스템
- [x] F9: 통계 대시보드 (플레이 기록, 누적 데이터)
  - StatisticsScreen: 6섹션 (플레이어/전투/몬스터/소환/재화/장비퀘스트)
- [x] F10: 유닛 테스트 (핵심 서비스)
  - monster_model 56개, gacha_service 21개, upgrade_service 42개 (총 119 통과)
- [x] F11: 국제화 i18n (한/영)
  - ARB 파일 ~70 문자열, localeProvider (Hive persist), 설정 언어 토글

## 4차 고도화 (G1~I12)
### UI/UX 완성도
- [x] G1: l10n 전면 적용 (17개 화면 + 위젯, 300+ 키, 한/영 완전 국제화)
- [x] G2: 다크/라이트 테마 전환 (설정에서 토글, Hive persist)
- [x] G3: 전투 연출 강화 (데미지 넘버 애니메이션, 크리티컬 이펙트)
- [x] G4: 온보딩 개선 (닉네임 입력 UI 리디자인, 초기 몬스터 선택)
  - 스타터 6종 확장, 2x3 그리드, 미니 스탯 미리보기
  - 글로우 아이콘, AnimatedSwitcher, 스텝 인디케이터
### 콘텐츠 확장
- [x] H5: 몬스터 스킨/의상 시스템 (외형 커스터마이징)
  - SkinDatabase: 14종 스킨 (유니버설6+속성5+전용3), 1~5성
  - MonsterModel.equippedSkinId (HiveField 20), SkinResolver 비주얼 해석
  - SkinProvider: 소환석으로 해금, 장착/해제, Hive settings 영속화
  - monster_detail_screen 스킨 섹션 UI
- [x] H6: 도전의 탑 (주간 리셋 고난이도 컨텐츠, 층별 고정 보상)
  - TowerService: 30층, 보스(10/20/30층), 하드 스케일링(x2.5), 주간 리셋 3회
  - TowerProvider: 층간 회복 없음, 상태이펙트만 리셋, 누적 보상
  - TowerScreen: 전용 전투 UI, 마일스톤 다이아/소환권 보상
  - 전투 대기화면 빠른이동, /tower 라우트, ko/en l10n
- [x] H7: 몬스터 조합 레시피 (특정 조합 → 히든 몬스터 해금)
  - 히든 몬스터 5종 (화염골렘/숲의수호자/수정피닉스/그림자용/번개인어)
  - RecipeDatabase 5개 레시피, 크로스 레어리티 허용
  - 가챠/일반융합에서 히든 제외 (gachaWeight 필터)
- [x] H8: 일일 출석 보상 (7일 주기 누적 보상)
  - PlayerModel 3필드 추가 (lastCheckInDate/checkInStreak/totalCheckInDays)
  - AttendanceProvider: 7일 주기 출석, 연속/리셋 판정, 보상 지급
  - AttendanceDialog: 7일 그리드 UI, 완료/오늘/미래 상태 표시
  - HomeScreen 앱 진입시 자동 출석 팝업, ko/en l10n
### 시스템 안정성
- [x] I9: 에러 핸들링 강화 (home_screen init try/catch, 전역 에러바운더리)
  - _initProviders() try/catch로 Hive 초기화 크래시 방지
  - _completeOnboarding() try/catch + 에러 SnackBar
  - firstWhere orElse 폴백 추가
- [x] I10: 추가 유닛 테스트 (provider/service 계층 커버리지 확대)
  - battle_service: 속성상성/데미지/턴순서/전투종료/화상/기절/쿨다운 (47개)
  - prestige_service: 전생자격/보상/적용효과 (19개)
  - dungeon_service: 적생성/층보상/누적보상/층간회복 (23개)
  - tower_service: 적생성/보스/보상/주간리셋 (18개)
  - battle_statistics: MVP/몬스터별통계/데미지비율 (12개)
  - 총 246개 테스트 (기존 119 + 신규 127)
- [x] I11: 접근성 개선 (Semantics, 텍스트 크기 대응)
  - GestureDetector → Semantics 래퍼 (gacha _PullButton/_OverlayButton, collection _MonsterCard)
  - Icon semanticLabel 추가 (battle_screen 플레이어, collection 미발견몬스터)
  - _IdleBanner/.select() + TutorialOverlay/.select() (I10에서 동시 적용)
- [x] I12: 성능 프로파일링 (빌드 최적화)
  - DamageNumberOverlay RepaintBoundary 적용 (전투 중 불필요한 리페인트 방지)
  - _IdleBanner .select() 4개 provider 최적화 (I10에서 적용)
  - TutorialOverlay .select() 최적화 (I10에서 적용)
  - _ControlBar .select() 최적화 (이전 세션에서 적용)

## 코드 최적화 (3차)
- [x] MonsterElement.icon 공유 getter (4곳 중복 제거)
- [x] StageDatabase 공유 유틸 (3곳 중복 제거)
- [x] MonsterModel compositeMultiplier 캐시
- [x] CurrencyBar select() 적용
- [x] PlayerModel.expForLevel() static 함수
- [x] QuestState 사전 계산 + 개별 저장 최적화
- [x] claimReward/claimMilestone addReward() 단일 호출
- [x] HomeScreen indexOf → indexed loop

## 코드 최적화 (4차)
- [x] G3 데미지 넘버 race condition 수정 (oldLen 캡처)
- [x] mounted 체크 추가 (dispose 후 콜백 방지)
- [x] _ControlBar .select() 적용 (불필요한 리빌드 방지)
- [x] 린트 이슈 7개 수정 (unnecessary_brace_in_string_interps)
- [x] 출석 다이얼로그 isClaimed 삼항 로직 단순화
- [x] _IdleBanner .select() 적용 (arena/worldBoss/guild/quest 4개 provider)
- [x] TutorialOverlay .select() 적용 (tutorialStep만 구독)

## 코드 최적화 (5차)
- [x] _RadarPainter.shouldRepaint() 값 비교 (항상 true → 변경시만)
- [x] battle_screen _MonsterGrid RepaintBoundary 적용 (양팀)
- [x] gacha_screen 결과 GridView RepaintBoundary 적용
- [x] season_pass/relic/collection ListView cacheExtent 추가

## 5차 고도화 (J1~)
### 콘텐츠 확장
- [x] J3: 시즌 패스/배틀패스 (30레벨 보상 트랙)
  - SeasonPassDatabase: 30레벨 무료/프리미엄 보상 테이블
  - SeasonPassProvider: XP 획득, 자동레벨업, 보상수령, 시즌리셋(30일)
  - SeasonPassScreen: 레벨/XP바, 30단계 보상목록, 프리미엄토글
  - 전투 승리 XP 트리거 (+20/승리, +50/첫클리어)
  - /season-pass 라우트, battle_screen 빠른이동, ko/en l10n
- [x] J5: 몬스터 트레이닝 (자동 레벨업 슬롯)
  - TrainingService: 3슬롯, 1h/4h/8h, 레벨 기반 XP 스케일링
  - TrainingProvider: 슬롯 시작/수집/취소, Hive settings 영속화
  - TrainingScreen: 활성/빈 슬롯 카드, 몬스터 선택 시트, 시간 선택
  - 시간 기반 XP → 몬스터 직접 적용 (multi-level-up 지원)
  - /training 라우트, battle_screen 빠른이동, ko/en l10n
- [x] K7: 랭킹 리더보드
  - LeaderboardProvider: 4카테고리 (아레나/던전/탑/월드보스)
  - AI 30명 시뮬레이션 + 플레이어 실제 기록 순위
  - LeaderboardScreen: 4탭, 순위요약 헤더, 1~3위 메달
  - /leaderboard 라우트, battle_screen 빠른이동, ko/en l10n
- [x] K8: 도전 과제 확장 (숨은 업적, 칭호)
  - TitleDatabase: 12종 칭호 (전투/수집/소환/던전/전생/출석)
  - TitleProvider: 칭호 해금/장착/해제, 조건 자동 체크
  - TitleScreen: 현재 칭호, 해금/미해금 카드 목록, 장착 토글
  - PlayerModel.currentTitle (HiveField 19), updatePlayer() 범용 메서드
  - /title 라우트, battle_screen 빠른이동, ko/en l10n
- [x] K6: 추가 스킬 (패시브 스킬, 궁극기)
  - PassiveDefinition: 20종 패시브 (턴시작HP회복/공격크리/피격반격/전투시작버프)
  - UltimateDefinition: 5종 궁극기 (4-5성 전용, 데미지충전→대규모 효과)
  - BattleMonster: passiveId/ultimateId/ultimateCharge 필드 추가
  - BattleService: processPassiveTurnStart/processPassiveCounter/chargeUltimate/processUltimate
  - battle_provider processTurn 통합: 패시브→화상→기절→궁극기→스킬→일반공격
  - monster_battle_card: 궁극기 차지% / ULT READY 표시
- [x] L9: 추가 유닛 테스트 (트레이닝 서비스)
  - training_service: 상수/XP계산/레벨업적용/시간라벨 (16개)
  - 총 262개 테스트 (기존 246 + 신규 16)
- [x] J4: 우편함/메시지 시스템
  - MailItem: 제목/본문/보상/만료일/읽음/수령 상태
  - MailboxProvider: 우편 생성/수령/삭제, 자동 시스템 우편 (환영/일일/주간)
  - MailboxScreen: 우편 카드 리스트, 보상 칩, 전체 수령
  - 일일 접속 보상 + 주간 보너스 자동 발송
  - /mailbox 라우트, battle_screen 빠른이동, ko/en l10n

## 코드 최적화 (6차)
- [x] 중복 RewardChip 위젯 공용화 (tower/dungeon → common/reward_chip.dart)
- [x] 중복 formatDate 유틸 공용화 (FormatUtils.formatDate/formatDateTime)

## 6차 고도화 (M1~)
### 완료
- [x] M1: 재화 상점 시스템
  - 금화↔다이아 환전, 가챠권/경험포션 구매 (10묶음 할인)
  - /shop 라우트, ko/en l10n
- [x] M2: 자동 반복 전투
  - 반복 모드 토글, 승리시 자동수집+재시작, 패배시 자동정지
  - 누적 보상 카운터 오버레이
- [x] M3: 몬스터 닉네임
  - MonsterModel.nickname (HiveField 18), displayName getter
  - 몬스터 상세 탭→닉네임 편집 다이얼로그 (최대 10자)
- [x] M4: 도감 도전 (컬렉션 챌린지)
  - 12종 챌린지 (속성7+희귀도3+개수2), 도감 화면 스크롤 바
- [x] M5: 일일 보너스 던전
  - 요일별 속성 로테이션, 10층, 일일 2회, 1.5배 보상
  - 층별 25% HP회복, 3층마다 소환석

- [x] M6: 몬스터 도감 상세 강화
  - 속성 상성표 (유리/불리 시각적 표시), 패시브/궁극기 카드, 진화 트리 시각화
- [x] M7: 업적 포인트 마일스톤 보상
  - 칭호별 포인트 (5~30P), 6단계 마일스톤 보상 (골드/다이아/소환권/소환석)
- [x] M8: 배틀 리플레이
  - 승리/패배 자동 기록 (최대 10개), 상세 로그 보기, 팀 구성 표시
- [x] M9: 장비 강화 시스템
  - enhanceLevel (HiveField 9), 강화당 +10%, 비용 = 500×(레벨+1)×희귀도
- [x] M10: 이벤트 배너 시스템
  - 요일별 이벤트 로테이션, 전투 화면 PageView 캐러셀

## 7차 고도화 (N1~N10)
### 계획
- [x] N1: 팀 프리셋 저장/로드
  - 5개 슬롯, 팀 구성 저장/불러오기/삭제, 프리셋 이름 편집
- [x] N2: 전투 속도 조절 (기존 구현 확인 - 이미 1x/2x/3x 완료)
- [x] N3: 통계 대시보드 (기존 statistics_screen이 이미 충분히 상세)
- [x] N4: 몬스터 비교
  - MonsterCompareScreen: 2마리 선택→스탯 바 비교, 속성 상성, 총 전투력
  - 도감 헤더에 비교 아이콘 버튼, /monster-compare 라우트
- [x] N5: 도감 필터/정렬 강화
  - CollectionSort enum: 기본/이름/등급/레벨/전투력 정렬
  - 도감 필터바에 정렬 PopupMenu 추가
- [x] N6: 소환 히스토리
  - GachaHistoryProvider: 최근 100회 기록, 희귀도별 통계
  - GachaHistoryScreen: 기록 리스트+통계 요약+삭제
  - gacha_provider에 히스토리 기록 연동 (1회/10연)
  - /gacha-history 라우트, gacha_screen 히스토리 버튼 추가
- [x] N7: 업적 알림 토스트
  - QuestState.newlyCompletedIds 추가, onTrigger에서 완료 감지
  - home_screen ref.listen → SnackBar 토스트 (탭→퀘스트화면)
- [x] N8: 설정 화면 확장
  - NotificationService: isEnabled/setEnabled (Hive persist)
  - 설정화면 알림 토글 섹션 추가
- [x] N9: 전투 스킵 (클리어 스테이지)
  - BattleNotifier.skipBattle(): 즉시 보상 지급+퀘스트/시즌패스 연동
  - stage_select_screen: 클리어 스테이지 ⚡ 스킵 버튼
- [x] N10: 몬스터 즐겨찾기
  - MonsterModel.isFavorite (HiveField 19), toggleFavorite
  - 도감 즐겨찾기 필터+하트 오버레이, 팀편성 즐겨찾기 우선 정렬

## 코드 리뷰 최적화 (7차)
- [x] C-01: app_router monsterDetail 안전한 타입 체크 (is! → fallback Scaffold)
- [x] H-03: _IdleBanner monsterListProvider → teamMonstersProvider
- [x] H-04: upgrade_screen _UpgradePanel .select() 적용 (특정 몬스터만)
- [x] M-08: settings_screen Theme/Dark/Light 하드코딩 → l10n
- [x] M-14: gacha_provider _incrementPlayerPullCount async/await
- [x] RewardRow 공용 위젯 추출 (arena/prestige/world_boss ~70줄 중복 제거)
- [x] _elementColor 제거 → MonsterElement.fromName().color 통일
- [x] PageController 릭 수정 (_EventBannerCarousel → StatefulWidget)
- [x] statistics_screen .select() 최적화 (player/quest provider)
- [x] Navigator.pop → context.pop 통일 (6개 화면)
- [x] event_dungeon .select() 중복 full watch 제거
- [x] l10n: 10+ 하드코딩 문자열 제거 (settingsTheme, onboardingSetupError, gachaPityLabel 등)

## 코드 리뷰 최적화 (8차)
- [x] BattleLogList 공용 위젯 추출 (6개 화면 ~120줄 중복 제거)
- [x] leaderboard_screen empty state 추가
- [x] team_edit_screen context.mounted 체크 3곳 추가
- [x] arena_screen List → List<BattleLogEntry> 타입 안전성
- [x] 상점 소환석 구매 추가 (x5 20💎, x20 70💎)
- [x] 추가 테스트 388개 (guild 133 + daily_dungeon 96 + synergy 100 + skin 59)
- [x] 총 845개 테스트 (기존 457 + 신규 388)

## 코드 리뷰 최적화 (9차 - l10n 대규모 전환)
- [x] AppMessage 시스템 도입: provider 메시지를 String? → AppMessage? 구조화
- [x] 5개 provider l10n 전환 (upgrade, training, expedition, prestige, mailbox)
- [x] 5개 화면 SnackBar/inline 리스너 AppMessage.resolve(l) 적용
- [x] monster_detail_screen: 스킬/패시브/궁극기 태그 17개 l10n
- [x] battle_screen: 팀 요약, upgrade_screen: 몬스터 정보, expedition_screen: 타이머
- [x] offline_reward_dialog: 5개 하드코딩 문자열 l10n
- [x] collection 마일스톤: label 제거 → localizedLabel(l) 메서드
- [x] mailbox_screen: 시스템 메일 제목/본문 ID 기반 l10n resolve
- [x] notification_service: 알림 텍스트 파라미터화
- [x] ExpeditionOption: label 제거 → hours getter + UI에서 l10n
- [x] 총 ~60개 l10n 키 추가 (한국어/영어)
- [x] 845개 테스트 전부 통과, flutter analyze 0 issues

## 8차 UI 리뉴얼 (냥코대전쟁 스타일)
- [x] battle_provider: initialEnemyCount 필드 추가 (프로그레스 바용)
- [x] StageProgressBar 위젯 생성 (스테이지명+적 처치 프로그레스+철수)
- [x] BattleSidebar 위젯 생성 (좌측 10개 아이콘 퀵 네비)
- [x] battle_screen: _IdleBanner/_ControlBar/_StageHeader 삭제, 자동전투 시작
- [x] battle_screen: StageProgressBar + BattleSidebar 오버레이 적용
- [x] battle_screen: _DefeatBanner 추가 (패배시 재시도 오버레이)
- [x] TrainScreen 생성 (강화/트레이닝/원정대 허브)
- [x] app_router: ShellRoute 5탭 (battle/train/hero/gacha/shop)
- [x] home_screen: 5탭 재구성 (전투/훈련/히어로/소환/상점)
- [x] l10n: ~23개 키 추가 (sidebar/train/tab)
- [ ] 추가 사이드바 아이콘: 지도/시즌패스/리더보드/칭호/우편/리플레이/통계/전생/도감
- [ ] 시너지 배지를 프로그레스 바 하단에 표시

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
