# 몬스터 수집 방치형 게임 - 미션 추적

## 현재 Phase: 2 완료

## 진행 상황
- [x] Phase 1: 프로젝트 기반 셋업
- [x] Phase 2: 자동 전투 시스템
- [ ] Phase 3: 가챠 시스템
- [ ] Phase 4: 강화/진화 시스템
- [ ] Phase 5: 오프라인 보상 + 저장
- [ ] Phase 6: 도감 + 팀편성
- [ ] Phase 7: 폴리싱

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

## 완료된 파일 목록 (33개 .dart + 65 이미지)
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
- lib/domain/services/{synergy_service,battle_service,game_tick_service}.dart

### Presentation
- lib/presentation/providers/{game_state,player,currency,monster,battle}_provider.dart
- lib/presentation/screens/home_screen.dart
- lib/presentation/screens/battle/battle_screen.dart
- lib/presentation/widgets/common/currency_bar.dart
- lib/presentation/widgets/battle/{hp_bar,monster_battle_card}.dart

## 다음 작업: Phase 3 - 가챠 시스템
- [ ] GachaService (확률뽑기, 천장시스템)
- [ ] GachaProvider (상태관리)
- [ ] GachaScreen UI (배너, 뽑기버튼, 확률표시)
- [ ] 뽑기 결과 애니메이션
