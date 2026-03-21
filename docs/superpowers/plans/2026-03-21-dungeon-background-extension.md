# Task #30: 에리어2 배경 확장 + 전환 연출

**목표**: BattleBackground를 5에리어로 확장하고 색조(tint) 차별화

**의존성**: Task #29 (GameArea enum 5개 확장) 완료 후 진행

---

## 현황 분석

### 기존 구조 (BattleBackground.cs)
```csharp
static readonly string[] AreaBackgrounds = {
    "Backgrounds/bg_grass_field",       // Area 1
    "Backgrounds/bg_medieval",          // Area 2
    "Backgrounds/bg_dungeon"            // Area 3
};
```

- SetArea(int area): 배경 교체 + 타일링
- StageManager.OnAreaChanged 이벤트로 자동 전환
- 카메라 위치에 따라 타일 자동 스크롤

### 문제점
- 2개 배경만 미구현 (volcano, abyss)
- 색조 차별화 없음 (모든 배경이 원본 색상)

---

## 설계

### 1. 배경 확장 (5에리어)

```csharp
public class BattleBackground : MonoBehaviour
{
    // 배경 경로 (Task #29: GameArea enum 순서와 동일)
    static readonly string[] AreaBackgrounds = {
        "Backgrounds/bg_grass_field",    // GameArea.Grass (1)
        "Backgrounds/bg_medieval",       // GameArea.Desert (2)
        "Backgrounds/bg_dungeon",        // GameArea.Cave (3)
        "Backgrounds/bg_volcano",        // GameArea.Volcano (4) ← NEW
        "Backgrounds/bg_abyss"           // GameArea.Abyss (5)  ← NEW
    };
}
```

### 2. 색조 차별화 추가

```csharp
// 에리어별 색조 정의
static readonly Color[] AreaTintColors = {
    Color.white,                         // Grass: 원본
    new Color(1f, 0.95f, 0.85f),        // Desert: 따뜻한 갈색
    new Color(0.7f, 0.7f, 0.8f),        // Cave: 어두운 파랑
    new Color(1f, 0.6f, 0.4f),          // Volcano: 주황/빨강
    new Color(0.4f, 0.3f, 0.6f)         // Abyss: 진한 보라
};

void SetArea(int area)
{
    // ... 기존 로직 ...

    // NEW: 색조 적용
    int idx = Mathf.Clamp(area - 1, 0, AreaTintColors.Length - 1);
    Color tintColor = AreaTintColors[idx];

    foreach (SpriteRenderer tile in tiles)
        tile.color = tintColor;
}
```

### 3. 전환 연출 (선택)

**Fade-in 연출** (자연스러운 전환):
```csharp
// SetArea 호출 직후
Sequence seq = DOTween.Sequence();
// 1. 현재 배경 페이드 아웃 (0.5초)
// 2. 새 배경 로드 및 설정
// 3. 새 배경 페이드 인 (0.5초)
```

**현재**: 즉시 교체 (연출 없음) - 일단 이것으로 구현

---

## 구현 체크리스트

### 1. 배경 에셋 준비
- [ ] volcano 배경 이미지: ComfyUI 생성 또는 기존 에셋 사용
- [ ] abyss 배경 이미지: ComfyUI 생성 또는 기존 에셋 사용
- [ ] 경로: `Assets/Resources/Backgrounds/`
  - `bg_volcano.png`
  - `bg_abyss.png`

### 2. BattleBackground.cs 수정
- [ ] AreaBackgrounds 배열 확장 (3개 → 5개)
- [ ] AreaTintColors 배열 추가
- [ ] SetArea()에서 tint color 적용
- [ ] 각 tile의 color 업데이트

### 3. 테스트
- [ ] StageManager.cs에서 GameArea enum이 1~5로 정의되었는지 확인
- [ ] BattleScene에서 에리어 전환 시 배경 + 색조 자동 변경 확인
- [ ] 각 배경 색조가 시각적으로 구분되는지 확인

### 4. 선택사항 (나중에)
- [ ] 페이드 연출 (DOTween)
- [ ] 추가 분위기 연출 (파티클, 음향)

---

## 기술 고려사항

1. **SpriteRenderer.color vs material color**
   - `tile.color` 사용 (간단하고 효율적)
   - material 생성 불필요

2. **색조 적용 시점**
   - SetArea() → tiles 생성 → 색상 적용
   - 순서 중요: 타일 생성 후 색상 설정

3. **ComfyUI 배경 생성**
   - 용도: volcano, abyss 배경 이미지
   - 크기: 기존 배경과 유사 (픽셀아트, 1024x768 또는 유사 비율)
   - 스타일: Battle Cats 스타일 픽셀아트
   - 명령어: mcp-comfyui (txt2img 워크플로우)

---

## 결론

**핵심**: 배열 확장 + 색조 배열 추가 + SetArea()에서 tint color 적용 = 최소 변경

**예상 줄수**: BattleBackground.cs에 ~15줄 추가

**다음**: Task #29 완료 후 → Task #30 구현 시작 → ComfyUI로 배경 생성

