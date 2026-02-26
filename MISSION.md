# 몬스터 수집 방치형 게임 - 미션 추적

## 현재 Phase: 7 완료 (전체 완료)

## 진행 상황
- [x] Phase 1: 프로젝트 기반 셋업
- [x] Phase 2: 자동 전투 시스템
- [x] Phase 3: 가챠 시스템
- [x] Phase 4: 강화/진화 시스템
- [x] Phase 5: 오프라인 보상 + 저장
- [x] Phase 6: 도감 + 팀편성
- [x] Phase 7: 폴리싱

## Phase 1 세부 (완료)
- [x] Flutter 프로젝트 생성 + pubspec.yaml
- [x] 폴더 구조 생성
- [x] 데이터 모델 (Monster, Player, Currency) + 수동 Hive TypeAdapter
- [x] Hive 초기화 + 테마 + GoRouter + BottomNav
- [x] 몬스터 템플릿 데이터 20종 (5등급)
- [x] 기본 홈 화면 (5탭 네비게이션)
- [x] 분류 시스템: 등급5(일반/고급/희귀/영웅/전설), 크기4(소/중/대/초대), 속성8
- [x] 시너지 시스템 15종 (속성/크기/등급/특수조합)
- [x] 스테이지 데이터 30종
- [x] 이미지 플레이스홀더 65개 + Planimg.md

## Phase 2 세부 (완료)
- [x] BattleService (데미지계산, 속성상성, 크리티컬, 턴처리)
- [x] GameTickService (Timer 0.5초 틱 + 30초 자동저장)
- [x] BattleEntity (BattleMonster, BattleLogEntry, BattleReward, StageInfo)
- [x] BattleProvider (StateNotifier, 전투상태 관리)
- [x] PlayerProvider, CurrencyProvider, MonsterProvider
- [x] BattleScreen UI (전투장면, HP바, 전투로그, 배속, 자동전투)
- [x] CurrencyBar, HpBar, MonsterBattleCard 위젯

## Phase 3 세부 (완료)
- [x] GachaService (가중치 랜덤뽑기, 천장100회 시스템, 10연 3★보장)
- [x] GachaProvider (StateNotifier, 천장추적, 결과관리, 카드공개 애니메이션 상태)
- [x] GachaScreen UI (배너, 천장진행바, 확률표, 1회/10연/소환권 버튼)
- [x] 뽑기 결과 오버레이 (카드 자동공개 애니메이션, 등급별 연출)
- [x] PlayerNotifier.addGachaPullCount 메서드 추가
- [x] app_router.dart 가챠 플레이스홀더 → 실제 GachaScreen 교체

## Phase 4 세부 (완료)
- [x] UpgradeService (레벨업 골드비용, 경험치물약, 진화 샤드+골드, 스탯 미리보기)
- [x] UpgradeProvider (StateNotifier, 몬스터선택, 탭전환, 레벨업/물약/진화 실행)
- [x] UpgradeScreen UI (몬스터 그리드, 레벨업/진화 탭, 스탯비교, 진화단계 인디케이터)
- [x] app_router.dart 강화 플레이스홀더 → 실제 UpgradeScreen 교체

## Phase 5 세부 (완료)
- [x] OfflineRewardService (최대12시간, 골드50%/경험치30% 효율, 스테이지별 스케일링)
- [x] OfflineRewardProvider (StateNotifier, 보상계산/수령 상태관리)
- [x] 오프라인 보상 팝업 UI (시간표시, 골드/경험치, 애니메이션 전환)
- [x] AppLifecycle 관리 (HomeScreen에 WidgetsBindingObserver)
- [x] paused→즉시저장+lastOnlineAt 갱신, resumed→보상계산+팝업
- [x] GameConfig에 offlineBattlesPerHour(60), minOfflineMinutes(1) 추가

## Phase 6 세부 (완료)
- [x] CollectionProvider (필터상태, 템플릿+보유몬스터 결합, 도감통계)
- [x] CollectionScreen (그리드뷰, 등급/속성/보유 필터, 미획득 실루엣, 상세 바텀시트)
- [x] TeamEditScreen (4슬롯 편성, 전투력합계, 저장)
- [x] app_router.dart 도감 플레이스홀더 → CollectionScreen 교체 + /collection/team 라우트 추가

## Phase 7 세부 (완료)
- [x] OnboardingScreen (닉네임 입력 + 스타터 몬스터 3종 선택)
- [x] SettingsScreen (플레이어 정보, 게임 정보, 초기화 기능)
- [x] BattleScreen 라우터 연결 (placeholder 제거)
- [x] GoRouter redirect 로직 (플레이어 없으면 → 온보딩)
- [x] 모든 placeholder 제거 (전투, 도감, 설정 모두 실제 화면)

## 완료된 파일 목록 (50개 .dart + 65 이미지)
### Core
- lib/main.dart, lib/app.dart, lib/routing/app_router.dart
- lib/core/constants/{app_colors,game_config,strings_ko}.dart
- lib/core/enums/{monster_element,monster_rarity,monster_size}.dart
- lib/core/theme/app_theme.dart
- lib/core/utils/format_utils.dart

### Data
- lib/data/models/{monster,player,currency}_model.dart + .g.dart
- lib/data/datasources/local_storage.dart
- lib/data/static/{monster_database,stage_database}.dart

### Domain
- lib/domain/entities/{synergy,battle_entity}.dart
- lib/domain/services/{synergy_service,battle_service,game_tick_service,gacha_service,upgrade_service,offline_reward_service}.dart

### Presentation
- lib/presentation/providers/{game_state,player,currency,monster,battle,gacha,upgrade,offline_reward,collection}_provider.dart
- lib/presentation/dialogs/offline_reward_dialog.dart
- lib/presentation/screens/home_screen.dart
- lib/presentation/screens/battle/battle_screen.dart
- lib/presentation/widgets/common/currency_bar.dart
- lib/presentation/widgets/battle/{hp_bar,monster_battle_card}.dart
- lib/presentation/screens/gacha/gacha_screen.dart
- lib/presentation/screens/upgrade/upgrade_screen.dart
- lib/presentation/screens/collection/{collection_screen,team_edit_screen}.dart
- lib/presentation/screens/onboarding/onboarding_screen.dart
- lib/presentation/screens/settings/settings_screen.dart
