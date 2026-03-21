# Task #28: 던전 전투 로직 + BattleManager 연동

**목표**: BattleManager를 던전 모드로 전환하여 StageManager와 독립적인 던전 전투 구현

---

## 현황 분석

### 기존 구조
- **BattleManager**: 아군 전멸만 체크 (Defeat), Victory는 외부(StageManager) 처리
- **DungeonManager**: 입장 횟수 관리 + 보상 지급 (Task #26 완료)
- **DungeonData**: 적 프리셋 + 난이도 배수 정의
- **StageManager**: 웨이브 진행 + 보상 처리 (독립적)

### 문제점
- BattleManager가 던전과 스테이지 양쪽을 구분하지 않음
- 던전용 적 스폰 메커니즘 없음
- 클리어 판정 로직 없음 (적 전멸 감지 필요)

---

## 설계

### 1. BattleManager 확장 (isDungeonMode)

```csharp
public class BattleManager : MonoBehaviour
{
    // 던전 모드 플래그
    private bool _isDungeonMode = false;
    private DungeonData _currentDungeonData = null;

    // 던전 시작 시 호출
    public void EnterDungeonMode(DungeonData data)
    {
        _isDungeonMode = true;
        _currentDungeonData = data;
        // 기존 적 리스트 초기화
        enemyUnits.Clear();
    }

    // Update에서 클리어 판정 추가
    void Update()
    {
        if (CurrentState != BattleState.Fighting) return;

        // 아군 전멸 체크
        if (AllAlliesDead()) { SetState(BattleState.Defeat); return; }

        // 던전 모드: 모든 적 처치 시 클리어
        if (_isDungeonMode && AllEnemiesDead())
            SetState(BattleState.Victory);
    }

    private bool AllEnemiesDead()
    {
        for (int i = 0; i < enemyUnits.Count; i++)
        {
            if (enemyUnits[i] != null && !enemyUnits[i].IsDead)
                return false;
        }
        return true;
    }

    // 던전 모드 해제
    public void ExitDungeonMode() => _isDungeonMode = false;
}
```

### 2. 적 스폰 로직

**위치**: DungeonManager 또는 별도 DungeonBattleController
**타이밍**: DungeonManager.TryEnter() 성공 → 던전 씬 진입 → BattleManager.EnterDungeonMode() → 적 스폰

```csharp
// 의사코드
void SpawnDungeonEnemies(DungeonData data)
{
    foreach (CharacterPreset preset in data.enemyPresets)
    {
        BattleUnit enemy = CharacterFactory.Create(preset);

        // 난이도별 스탯 스케일링
        enemy.maxHp = (int)(enemy.maxHp * data.DifficultyMultiplier);
        enemy.attack = (int)(enemy.attack * data.DifficultyMultiplier);

        BattleManager.Instance.enemyUnits.Add(enemy);
    }
}
```

### 3. 상태 전이 흐름

```
DungeonUI [입장 버튼]
    ↓
DungeonManager.TryEnter(data)
    ↓ (성공 시)
SceneManager.LoadScene("BattleScene")
    ↓
BattleManager.EnterDungeonMode(data)
    ↓
SpawnDungeonEnemies(data)
    ↓
BattleManager.StartBattle()

[전투 진행]

BattleManager.Update():
  - 아군 전멸? → Defeat → MainScene + 보상 없음
  - 적 전멸?  → Victory → DungeonManager.ClearDungeon() + 보상 + MainScene
```

### 4. 클리어/패배 처리

**클리어** (Victory):
```csharp
// BattleManager에서 상태 변경 감지
OnBattleStateChanged += (state) =>
{
    if (state == BattleState.Victory && _isDungeonMode)
    {
        DungeonManager.Instance.ClearDungeon(_currentDungeonData);
        // UI: 클리어 팝업 표시
        // 3초 후 MainScene 로드
    }
};
```

**패배** (Defeat):
```csharp
OnBattleStateChanged += (state) =>
{
    if (state == BattleState.Defeat && _isDungeonMode)
    {
        // UI: 패배 팝업 표시
        // 보상 없음
        // 2초 후 MainScene 로드
    }
};
```

### 5. 구현 순서

| 단계 | 작업 | 담당 | 의존 |
|------|------|------|------|
| 1 | BattleManager: isDungeonMode + EnterDungeonMode() | review-agent | - |
| 2 | BattleManager: AllEnemiesDead() + Victory 판정 | review-agent | 1 |
| 3 | 적 스폰 로직 (DungeonManager 또는 Controller) | build-agent? | 1-2 |
| 4 | UI 연동 (클리어/패배 팝업) | ui-agent | 1-3 |

---

## 기술 고려사항

1. **SceneManager vs 다중 씬 로드**
   - 현재: BattleScene 재사용 (MainHUD 숨김 고려)
   - 아니면: DungeonBattleScene 별도 생성

2. **카메라/UI 분리**
   - 던전 전용 배경? (예: 포탈 또는 어두운 배경)
   - MainHUD 숨기고 DungeonUI만 표시

3. **스테이지 업그레이드**
   - 다음 스테이지 자동 진입? (보상 수령 후)
   - 게임 오버 후 리플레이 가능한지 확인

---

## 결론

**핵심**: BattleManager의 isDungeonMode 플래그 + AllEnemiesDead() 체크 추가로 최소한의 변경으로 던전 모드 지원

**다음**: Task #26 완료 후 의존성 해결 시작 → Task #27/28/29 병렬 진행

