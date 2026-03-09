# UI_SPEC.md — Battle Cats Style Mobile Game
> Claude Code는 이 문서를 항상 참조하여 Unity uGUI 구현 시 일관된 디자인을 유지할 것.

---

## 1. 전체 디자인 언어

| 속성 | 값 |
|---|---|
| 스타일 | 캐주얼 모바일 / 아이들 게임 (Battle Cats 계열) |
| 기준 해상도 | 390 × 844 (iPhone 기준), SafeArea 필수 대응 |
| 레이아웃 방향 | 세로(Portrait) 고정 |
| 폰트 | 한국어 Bold (NanumSquareRound Bold 또는 Noto Sans KR Bold) |
| 전체 톤 | 따뜻한 갈색 계열 + 포인트 그린/골드 |

---

## 2. 컬러 팔레트

### 배경
```
Background_Main     : #1E0F06   (매우 어두운 갈색, 체커보드 텍스처)
Background_Panel    : #2D1A0A   (패널 기본 배경)
Background_Dark     : #150B03   (가장 어두운 영역)
```

### 패널 / 보더
```
Panel_Border        : #8B6327   (황금빛 갈색 테두리, 2px)
Panel_Inner         : #3A2010   (패널 내부 배경)
Panel_Selected      : #4A6B1A   (선택된 아이템 테두리, 밝은 녹색)
Tab_Active          : #C8A86B   (활성 탭 배경, 크림/베이지)
Tab_Inactive        : #2D1A0A   (비활성 탭 배경)
```

### 버튼
```
Button_Green        : #4CAF50   → Gradient: #5DC054 (top) ~ #3A8C3E (bottom)
Button_Green_Border : #2E7D32
Button_Yellow       : #F5C518   → Gradient: #FFD740 (top) ~ #E6AC00 (bottom)
Button_Yellow_Border: #B8860B
Button_Gray         : #6B6B6B   (비활성/잠금 버튼)
Button_Brown        : #7B5230   → Gradient: #8B6340 (top) ~ #5C3A20 (bottom)
Button_Brown_Border : #A07845
```

### 아이템 희귀도 배경
```
Rarity_Common       : #607080   (회색-청색)
Rarity_Uncommon     : #3A7A3A   (녹색)
Rarity_Rare         : #6B3FA0   (보라색)
Rarity_Locked       : #252525   (잠금, 어두운 회색 + 자물쇠 아이콘)
```

### 텍스트
```
Text_Primary        : #FFFFFF   (흰색, 기본)
Text_Secondary      : #D4C09A   (크림색, 설명)
Text_Gold           : #FFD700   (골드, 코인/수치 강조)
Text_Green          : #7FD44C   (녹색, 증가량)
Text_Level          : #FFFFFF   (레벨 배지 텍스트)
Text_Disabled       : #888888
```

### 진행 바
```
ProgressBar_BG      : #1A1A1A
ProgressBar_Fill    : #5DC054   (녹색)
ProgressBar_Border  : #2E2E2E   (1px)
```

---

## 3. 타이포그래피

```
Header_Large    : Bold, 22pt, LetterSpacing: 0, Color: #FFFFFF
Header_Medium   : Bold, 18pt, LetterSpacing: 0, Color: #FFFFFF
Stat_Value      : Bold, 20pt, Color: #FFFFFF
Stat_Label      : Regular, 13pt, Color: #D4C09A
Button_Text     : Bold, 16pt, Color: #FFFFFF, Shadow: (0,-2) #00000080
Tab_Text        : Bold, 14pt
Level_Badge     : Bold, 11pt, Color: #FFFFFF
Cost_Text       : Bold, 13pt, Color: #FFD700
Rarity_Label    : Bold, 12pt
Small_Info      : Regular, 11pt, Color: #888888
```

---

## 4. 공통 컴포넌트 스펙 (see full spec above)
---

## 5. 애니메이션 규칙 (DOTween 사용)
---

## 6. Unity 구현 필수 규칙

1. 모든 텍스트: TextMeshPro 사용, UGUI Text 금지
2. 이미지: Image 컴포넌트, sprite는 9-slice 적용
3. 해상도: CanvasScaler → Scale With Screen Size, 390×844, Match 0.5
4. 레이아웃: 절대 MagicNumber 금지, 모든 수치는 const 또는 SerializeField
5. 색상: ColorPalette.cs ScriptableObject 에서 중앙 관리
6. 간격/크기: UIConstants.cs 에서 const로 관리
7. SafeArea: SafeAreaAdapter 컴포넌트 상/하단 Panel에 필수 적용
8. 폰트 크기: pt 기준, 최소 10pt (가독성 보장)
9. 터치 타겟: 최소 44x44dp (접근성 기준)
10. 배경 텍스처: 체커보드 패턴은 TiledBackground 컴포넌트로 처리
