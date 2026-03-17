# 성급 시스템 + 시너지 + 탈것 + 던전 구현 계획

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 기존 4단계 등급 체계를 5성급으로 통일하고, 스킬 시너지/탈것/던전 시스템을 추가한다.

**Architecture:** StarGrade enum을 공통 기반으로, 기존 HeroRarity/SkillRarity/Rarity를 모두 StarGrade로 마이그레이션. 신규 시스템(탈것/던전/재화)은 기존 싱글톤+이벤트 패턴을 따른다.

**Tech Stack:** Unity 6000.3.10f1, C#, SPUM, PlayerPrefs JSON

---

## Chunk 1: 성급 체계 통일 (Foundation)

### Task 1: StarGrade enum 생성 + 기존 enum 마이그레이션

**Files:**
- Create: `Assets/Scripts/Data/StarGrade.cs`
- Modify: `Assets/Scripts/Data/CharacterPreset.cs`
- Modify: `Assets/Scripts/Data/SkillData.cs`
- Modify: `Assets/Scripts/Data/EquipmentData.cs`

- [ ] **Step 1: StarGrade enum 파일 생성**

```csharp
// Assets/Scripts/Data/StarGrade.cs
public enum StarGrade
{
    Star1 = 1,
    Star2 = 2,
    Star3 = 3,
    Star4 = 4,
    Star5 = 5
}
```

- [ ] **Step 2: CharacterPreset에 StarGrade 적용**

`Assets/Scripts/Data/CharacterPreset.cs`에서:
- `HeroRarity rarity` → `StarGrade starGrade = StarGrade.Star1` 로 교체
- `HeroRarity` enum 삭제 (CharacterPreset.cs 상단)

```csharp
// 기존:
// public enum HeroRarity { Common, Rare, Epic, Legendary }
// public HeroRarity rarity = HeroRarity.Common;

// 변경:
public StarGrade starGrade = StarGrade.Star1;
```

- [ ] **Step 3: SkillData에 StarGrade 적용 + element/tags 필드 추가**

`Assets/Scripts/Data/SkillData.cs`에서:
- `SkillRarity rarity` → `StarGrade starGrade = StarGrade.Star1`
- `SkillRarity` enum 삭제
- `element`와 `tags` 필드 추가

```csharp
// 기존 SkillRarity enum 삭제

// 추가 enum
public enum SkillElement
{
    None,
    Fire,
    Ice,
    Lightning,
    Poison,
    Holy,
    Dark
}

// SkillData 클래스에 추가:
public StarGrade starGrade = StarGrade.Star1;

[Header("Synergy")]
public SkillElement element = SkillElement.None;
public string[] tags = new string[0]; // "공격", "방어", "지원", "디버프" 등
```

- [ ] **Step 4: EquipmentData Rarity enum 정리**

`Assets/Scripts/Data/EquipmentData.cs`에서:
- 기존 `Rarity` enum은 삭제 (EquipmentItem.rarity는 이미 int 1~5)
- `EquipmentData.rarity`를 `StarGrade starGrade`로 교체

```csharp
// 기존 Rarity enum 삭제
// public Rarity rarity; →
public StarGrade starGrade = StarGrade.Star1;
```

- [ ] **Step 5: 컴파일 오류 해결 — GachaManager**

`Assets/Scripts/Battle/GachaManager.cs`에서:
- `HeroRarity` 참조를 모두 `StarGrade`로 교체
- 풀 이름 변경: `commonPool` → `star1Pool` 등
- 확률을 새 값으로 교체 (60/30/9/0.97/0.03)
- Pity 시스템 제거 (천장 없음)

```csharp
// 풀 변경
readonly List<CharacterPreset> star1Pool = new();
readonly List<CharacterPreset> star2Pool = new();
readonly List<CharacterPreset> star3Pool = new();
readonly List<CharacterPreset> star4Pool = new();
readonly List<CharacterPreset> star5Pool = new();

void RebuildRarityPools()
{
    star1Pool.Clear(); star2Pool.Clear(); star3Pool.Clear();
    star4Pool.Clear(); star5Pool.Clear();

    for (int i = 0; i < allHeroes.Length; i++)
    {
        var hero = allHeroes[i];
        if (hero == null) continue;
        switch (hero.starGrade)
        {
            case StarGrade.Star1: star1Pool.Add(hero); break;
            case StarGrade.Star2: star2Pool.Add(hero); break;
            case StarGrade.Star3: star3Pool.Add(hero); break;
            case StarGrade.Star4: star4Pool.Add(hero); break;
            case StarGrade.Star5: star5Pool.Add(hero); break;
        }
    }
}

// PullOne: 천장 없음, 새 확률
CharacterPreset PullOne()
{
    if (allHeroes.Length == 0) return null;

    float roll = UnityEngine.Random.Range(0f, 100f);
    StarGrade selectedGrade;

    if (roll < 0.03f)
        selectedGrade = StarGrade.Star5;
    else if (roll < 1f) // 0.03 + 0.97
        selectedGrade = StarGrade.Star4;
    else if (roll < 10f) // 1 + 9
        selectedGrade = StarGrade.Star3;
    else if (roll < 40f) // 10 + 30
        selectedGrade = StarGrade.Star2;
    else
        selectedGrade = StarGrade.Star1;

    var pool = GetPool(selectedGrade);
    if (pool.Count > 0)
        return pool[UnityEngine.Random.Range(0, pool.Count)];

    // Fallback: 낮은 성급부터 탐색
    for (int r = (int)selectedGrade - 1; r >= 1; r--)
    {
        var fallback = GetPool((StarGrade)r);
        if (fallback.Count > 0)
            return fallback[UnityEngine.Random.Range(0, fallback.Count)];
    }
    return allHeroes[UnityEngine.Random.Range(0, allHeroes.Length)];
}

List<CharacterPreset> GetPool(StarGrade grade)
{
    return grade switch
    {
        StarGrade.Star1 => star1Pool,
        StarGrade.Star2 => star2Pool,
        StarGrade.Star3 => star3Pool,
        StarGrade.Star4 => star4Pool,
        StarGrade.Star5 => star5Pool,
        _ => star1Pool
    };
}
```

- [ ] **Step 6: 컴파일 오류 해결 — 나머지 파일**

`HeroRarity` / `SkillRarity` / `Rarity` 참조하는 모든 파일에서 `StarGrade`로 교체:
- `PresetCreator.cs`: `rarity = HeroRarity.Common` → `starGrade = StarGrade.Star1` 등
- `SkillDataCreator.cs`: `rarity = SkillRarity.Common` → `starGrade = StarGrade.Star1` 등
- `HeroLevelManager.cs`: StarRank 로직은 유지 (영웅 성장 시스템은 별개)
- `MainHUD.cs`: rarity 참조 부분 교체
- `DeckUI.cs`: rarity 참조 부분 교체

Grep으로 `HeroRarity`, `SkillRarity`, `\.rarity` 검색하여 누락 없이 처리.

- [ ] **Step 7: PresetCreator 성급 재배정**

기존 아군 7명의 성급 재배정:
```
Ally_Swordsman: Star1 (검사)
Ally_Archer: Star1 (궁수)
Ally_Healer: Star2 (사제)
Ally_Mage: Star2 (마법사)
Ally_Knight: Star3 (기사)
Ally_Bard: Star3 (음유시인)
Ally_Lancer: Star4 (창기사)
```

기존 적 13명의 성급 배정:
```
일반몹 (Star1): OrcWarrior, Skeleton, Demon, CaveBat
일반몹 (Star2): OrcArcher, SkeletonMage, DarkKnight, SandScorpion, DesertMage, PoisonSpider
중간보스 (Star3): CaveGolem, RedRider
보스 (Star4): OrcChief
```

- [ ] **Step 8: SkillDataCreator 성급 재배정**

```
Star1: Skill_HealingLight, Skill_GuardShield, Skill_SlowMist
Star2: Skill_Fireball, Skill_PoisonFog, Skill_FrostBite
Star3: Skill_LightningStorm, Skill_FireWall, Skill_WarCry
Star4: (없음 - 추후 추가)
Star5: Skill_DivineBolt, Skill_NatureBlessing
```

각 스킬에 element와 tags도 설정:
```
Skill_Fireball: element=Fire, tags=["공격"]
Skill_HealingLight: element=Holy, tags=["지원"]
Skill_LightningStorm: element=Lightning, tags=["공격"]
Skill_PoisonFog: element=Poison, tags=["디버프", "공격"]
Skill_FrostBite: element=Ice, tags=["디버프"]
Skill_FireWall: element=Fire, tags=["공격", "디버프"]
Skill_WarCry: element=None, tags=["지원"]
Skill_GuardShield: element=None, tags=["방어"]
Skill_SlowMist: element=Ice, tags=["디버프"]
Skill_DivineBolt: element=Holy, tags=["공격"]
Skill_NatureBlessing: element=Holy, tags=["지원"]
```

- [ ] **Step 9: 컴파일 확인 + 커밋**

```bash
# Unity 컴파일 확인 (mcp-unity recompile)
git add Assets/Scripts/Data/StarGrade.cs Assets/Scripts/Data/CharacterPreset.cs Assets/Scripts/Data/SkillData.cs Assets/Scripts/Data/EquipmentData.cs Assets/Scripts/Battle/GachaManager.cs Assets/Scripts/Editor/PresetCreator.cs Assets/Scripts/Editor/SkillDataCreator.cs
git commit -m "refactor: HeroRarity/SkillRarity/Rarity → StarGrade 5성급 통일"
```

### Task 2: 몬스터 성급 크기 스케일링

**Files:**
- Modify: `Assets/Scripts/Battle/CharacterFactory.cs:140-144`

- [ ] **Step 1: CharacterFactory에 성급 기반 크기 스케일 적용**

`CreateCharacter` 메서드에서 기존 고정 스케일(0.8f) 대신 성급 기반 스케일:

```csharp
// 기존: unitObj.transform.localScale = Vector3.one * 0.8f;
// 변경:
float baseScale = 0.8f;
float starScale = preset.starGrade switch
{
    StarGrade.Star3 => 1.4f,
    StarGrade.Star4 => 1.7f,
    StarGrade.Star5 => 2.0f,
    _ => 1.0f
};
unitObj.transform.localScale = Vector3.one * baseScale * starScale;
```

- [ ] **Step 2: 몬스터 스탯 배율 적용**

`CreateCharacter`에서 적 유닛 생성 시 성급 스탯 배율 적용:

```csharp
// 적 유닛 성급 스탯 배율 (CreateCharacter 내, battleUnit 초기화 후)
if (team == BattleUnit.Team.Enemy)
{
    float statMult = preset.starGrade switch
    {
        StarGrade.Star2 => 1.3f,
        StarGrade.Star3 => 2.0f,
        StarGrade.Star4 => 3.5f,
        StarGrade.Star5 => 6.0f,
        _ => 1.0f
    };
    battleUnit.maxHp *= statMult;
    battleUnit.atk *= statMult;
    battleUnit.def *= statMult;
}
```

- [ ] **Step 3: 커밋**

```bash
git add Assets/Scripts/Battle/CharacterFactory.cs
git commit -m "feat: 몬스터 성급 기반 크기/스탯 스케일링"
```

---

## Chunk 2: 스킬 시너지 시스템

### Task 3: 스킬 시너지 데이터 + 매니저

**Files:**
- Create: `Assets/Scripts/Data/SkillSynergyData.cs`
- Create: `Assets/Scripts/Battle/SkillSynergyManager.cs`

- [ ] **Step 1: 시너지 데이터 정의**

```csharp
// Assets/Scripts/Data/SkillSynergyData.cs
using UnityEngine;

/// <summary>
/// 스킬 시너지 타입
/// </summary>
public enum SynergyType
{
    Combo,      // 특정 스킬 2개 조합
    Element,    // 같은 속성 N개
    Tag         // 같은 태그 N개
}

/// <summary>
/// 시너지 보너스 효과
/// </summary>
[System.Serializable]
public class SynergyBonus
{
    public float bonusAtkPercent;    // 공격력 % 증가
    public float bonusDefPercent;    // 방어력 % 증가
    public float bonusHpPercent;     // HP % 증가
    public float bonusDmgPercent;    // 스킬 데미지 % 증가
    public float cooldownReduction;  // 쿨타임 % 감소
}

/// <summary>
/// 개별 시너지 정의 (ScriptableObject)
/// </summary>
[CreateAssetMenu(fileName = "NewSynergy", menuName = "Game/Skill Synergy")]
public class SkillSynergyData : ScriptableObject
{
    public string synergyName;
    [TextArea] public string description;
    public SynergyType type;

    [Header("Combo Type - 필요 스킬 이름")]
    public string[] requiredSkillNames;

    [Header("Element Type - 필요 속성 + 수량")]
    public SkillElement requiredElement;
    public int requiredElementCount = 2;

    [Header("Tag Type - 필요 태그 + 수량")]
    public string requiredTag;
    public int requiredTagCount = 2;

    [Header("보너스")]
    public SynergyBonus bonus;
}
```

- [ ] **Step 2: SkillSynergyManager 구현**

```csharp
// Assets/Scripts/Battle/SkillSynergyManager.cs
using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// 장착된 스킬 조합에 따른 시너지 효과 계산
/// </summary>
public class SkillSynergyManager : MonoBehaviour
{
    public static SkillSynergyManager Instance { get; private set; }

    SkillSynergyData[] allSynergies;
    readonly List<SkillSynergyData> activeSynergies = new();

    // 현재 활성 시너지 보너스 (캐시)
    float cachedAtkPercent;
    float cachedDefPercent;
    float cachedHpPercent;
    float cachedDmgPercent;
    float cachedCooldownReduction;

    public event System.Action OnSynergyChanged;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        allSynergies = Resources.LoadAll<SkillSynergyData>("Synergies");
    }

    /// <summary>
    /// 장착 스킬이 변경될 때마다 호출
    /// </summary>
    public void RecalculateSynergies(List<SkillData> equippedSkills)
    {
        activeSynergies.Clear();
        cachedAtkPercent = 0f;
        cachedDefPercent = 0f;
        cachedHpPercent = 0f;
        cachedDmgPercent = 0f;
        cachedCooldownReduction = 0f;

        if (allSynergies == null || equippedSkills == null || equippedSkills.Count == 0)
        {
            OnSynergyChanged?.Invoke();
            return;
        }

        for (int i = 0; i < allSynergies.Length; i++)
        {
            if (CheckSynergy(allSynergies[i], equippedSkills))
            {
                activeSynergies.Add(allSynergies[i]);
                var b = allSynergies[i].bonus;
                cachedAtkPercent += b.bonusAtkPercent;
                cachedDefPercent += b.bonusDefPercent;
                cachedHpPercent += b.bonusHpPercent;
                cachedDmgPercent += b.bonusDmgPercent;
                cachedCooldownReduction += b.cooldownReduction;
            }
        }

        OnSynergyChanged?.Invoke();
    }

    bool CheckSynergy(SkillSynergyData synergy, List<SkillData> skills)
    {
        switch (synergy.type)
        {
            case SynergyType.Combo:
                return CheckCombo(synergy, skills);
            case SynergyType.Element:
                return CheckElement(synergy, skills);
            case SynergyType.Tag:
                return CheckTag(synergy, skills);
            default:
                return false;
        }
    }

    bool CheckCombo(SkillSynergyData synergy, List<SkillData> skills)
    {
        if (synergy.requiredSkillNames == null) return false;
        for (int i = 0; i < synergy.requiredSkillNames.Length; i++)
        {
            bool found = false;
            for (int j = 0; j < skills.Count; j++)
            {
                if (skills[j] != null && skills[j].skillName == synergy.requiredSkillNames[i])
                {
                    found = true;
                    break;
                }
            }
            if (!found) return false;
        }
        return true;
    }

    bool CheckElement(SkillSynergyData synergy, List<SkillData> skills)
    {
        int count = 0;
        for (int i = 0; i < skills.Count; i++)
        {
            if (skills[i] != null && skills[i].element == synergy.requiredElement)
                count++;
        }
        return count >= synergy.requiredElementCount;
    }

    bool CheckTag(SkillSynergyData synergy, List<SkillData> skills)
    {
        int count = 0;
        for (int i = 0; i < skills.Count; i++)
        {
            if (skills[i] == null || skills[i].tags == null) continue;
            for (int j = 0; j < skills[i].tags.Length; j++)
            {
                if (skills[i].tags[j] == synergy.requiredTag)
                {
                    count++;
                    break;
                }
            }
        }
        return count >= synergy.requiredTagCount;
    }

    // 외부에서 보너스 조회
    public float GetAtkPercent() => cachedAtkPercent;
    public float GetDefPercent() => cachedDefPercent;
    public float GetHpPercent() => cachedHpPercent;
    public float GetDmgPercent() => cachedDmgPercent;
    public float GetCooldownReduction() => cachedCooldownReduction;
    public IReadOnlyList<SkillSynergyData> ActiveSynergies => activeSynergies;
}
```

- [ ] **Step 3: SkillManager에 시너지 연동**

`Assets/Scripts/Battle/SkillManager.cs`에서:
- 스킬 장착/해제 시 `SkillSynergyManager.RecalculateSynergies()` 호출
- `UseSkill`에서 시너지 데미지 보너스 적용

```csharp
// SaveEquippedSkills() 끝에 추가:
SkillSynergyManager.Instance?.RecalculateSynergies(equippedSkills);

// UseSkill()에서 dmgMult 계산 부분:
float synergyDmgMult = SkillSynergyManager.Instance != null
    ? 1f + SkillSynergyManager.Instance.GetDmgPercent() / 100f : 1f;
float synergyCdMult = SkillSynergyManager.Instance != null
    ? 1f - SkillSynergyManager.Instance.GetCooldownReduction() / 100f : 1f;

// ApplySkillEffect에 synergyDmgMult 곱하기
for (int i = 0; i < targets.Count; i++)
    ApplySkillEffect(skill, targets[i], dmgMult * synergyDmgMult);

cooldownTimers[slotIndex] = skill.cooldown * cdMult * synergyCdMult;
```

- [ ] **Step 4: UpgradeManager에 시너지 스탯 보너스 연동**

`Assets/Scripts/Battle/UpgradeManager.cs`의 `ApplyAllBonuses()`에서:

```csharp
// 시너지 보너스 (퍼센트 기반)
var ssm = SkillSynergyManager.Instance;
if (ssm != null)
{
    float atkPct = ssm.GetAtkPercent() / 100f;
    float defPct = ssm.GetDefPercent() / 100f;
    float hpPct = ssm.GetHpPercent() / 100f;
    hpBonus += unit.baseMaxHp * hpPct;
    atkBonus += unit.baseAtk * atkPct;
    defBonus += unit.baseDef * defPct;
}
```

- [ ] **Step 5: 시너지 데이터 에디터 도구 생성**

`Assets/Scripts/Editor/SynergyDataCreator.cs` 생성:
초기 시너지 세트:
```
// Combo 시너지
"폭발독" - Skill_Fireball + Skill_PoisonFog → bonusDmgPercent: 25
"극한빙결" - Skill_FrostBite + Skill_SlowMist → cooldownReduction: 15
"신성심판" - Skill_DivineBolt + Skill_HealingLight → bonusAtkPercent: 20

// Element 시너지
"화염 친화" - Fire x2 → bonusDmgPercent: 20
"얼음 친화" - Ice x2 → cooldownReduction: 10
"신성 친화" - Holy x2 → bonusHpPercent: 15

// Tag 시너지
"전투광" - 공격 x2 → bonusAtkPercent: 15
"수호자" - 방어 x2 → bonusDefPercent: 15, bonusHpPercent: 10
"전략가" - 디버프 x2 → bonusDmgPercent: 10, cooldownReduction: 5
```

- [ ] **Step 6: 커밋**

```bash
git add Assets/Scripts/Data/SkillSynergyData.cs Assets/Scripts/Battle/SkillSynergyManager.cs Assets/Scripts/Editor/SynergyDataCreator.cs Assets/Scripts/Battle/SkillManager.cs Assets/Scripts/Battle/UpgradeManager.cs
git commit -m "feat: 스킬 시너지 시스템 (조합/속성/태그 3종)"
```

### Task 4: 스킬 뽑기 + 합성 강화

**Files:**
- Create: `Assets/Scripts/Battle/SkillScrollManager.cs` (재화)
- Create: `Assets/Scripts/Battle/SkillGachaManager.cs`
- Modify: `Assets/Scripts/Battle/SkillUpgradeManager.cs`

- [ ] **Step 1: 스킬 주문서 재화 매니저**

```csharp
// Assets/Scripts/Battle/SkillScrollManager.cs
using UnityEngine;
using System;

/// <summary>
/// 스킬 주문서 재화 관리 (스킬 뽑기 전용)
/// </summary>
public class SkillScrollManager : MonoBehaviour
{
    public static SkillScrollManager Instance { get; private set; }

    public int Scrolls { get; private set; }
    public event Action<int> OnScrollsChanged;

    const string SAVE_KEY = "SkillScrolls";
    bool saveDirty;
    float saveTimer;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }
        Scrolls = PlayerPrefs.GetInt(SAVE_KEY, 0);
    }

    public void AddScrolls(int amount)
    {
        if (amount <= 0) return;
        Scrolls += amount;
        MarkDirty();
        OnScrollsChanged?.Invoke(Scrolls);
    }

    public bool SpendScrolls(int amount)
    {
        if (amount <= 0 || Scrolls < amount) return false;
        Scrolls -= amount;
        MarkDirty();
        OnScrollsChanged?.Invoke(Scrolls);
        return true;
    }

    void MarkDirty() { saveDirty = true; saveTimer = 5f; }

    void Update()
    {
        if (!saveDirty) return;
        saveTimer -= Time.deltaTime;
        if (saveTimer <= 0f) FlushSave();
    }

    void FlushSave()
    {
        if (!saveDirty) return;
        PlayerPrefs.SetInt(SAVE_KEY, Scrolls);
        PlayerPrefs.Save();
        saveDirty = false;
    }

    void OnApplicationPause(bool p) { if (p) FlushSave(); }
    void OnApplicationQuit() { FlushSave(); }
}
```

- [ ] **Step 2: 스킬 뽑기 매니저**

```csharp
// Assets/Scripts/Battle/SkillGachaManager.cs
using UnityEngine;
using System;
using System.Collections.Generic;

/// <summary>
/// 스킬 주문서로 스킬 소환
/// 확률: 1성 60%, 2성 30%, 3성 9%, 4성 0.97%, 5성 0.03%
/// </summary>
public class SkillGachaManager : MonoBehaviour
{
    public static SkillGachaManager Instance { get; private set; }

    public const int SINGLE_COST = 50;
    public const int MULTI_COST = 450;

    SkillData[] allSkills;
    readonly List<SkillData>[] starPools = new List<SkillData>[5];

    // 보유 스킬 인벤토리 (스킬이름 → 보유 수량)
    readonly Dictionary<string, int> ownedSkills = new();

    public event Action<SkillData> OnSkillPulled;
    public event Action<SkillData[]> OnMultiPulled;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        for (int i = 0; i < 5; i++) starPools[i] = new List<SkillData>();
        allSkills = Resources.LoadAll<SkillData>("Skills");
        RebuildPools();
        LoadOwned();
    }

    void RebuildPools()
    {
        for (int i = 0; i < 5; i++) starPools[i].Clear();
        for (int i = 0; i < allSkills.Length; i++)
        {
            if (allSkills[i] == null) continue;
            int idx = (int)allSkills[i].starGrade - 1;
            if (idx >= 0 && idx < 5) starPools[idx].Add(allSkills[i]);
        }
    }

    public SkillData SinglePull()
    {
        if (!SkillScrollManager.Instance.SpendScrolls(SINGLE_COST)) return null;
        var skill = PullOne();
        HandleResult(skill);
        SoundManager.Instance?.PlayGachaSFX();
        OnSkillPulled?.Invoke(skill);
        return skill;
    }

    public SkillData[] MultiPull()
    {
        if (!SkillScrollManager.Instance.SpendScrolls(MULTI_COST)) return null;
        var results = new SkillData[10];
        for (int i = 0; i < 10; i++)
        {
            results[i] = PullOne();
            HandleResult(results[i]);
        }
        SoundManager.Instance?.PlayGachaSFX();
        OnMultiPulled?.Invoke(results);
        return results;
    }

    SkillData PullOne()
    {
        float roll = UnityEngine.Random.Range(0f, 100f);
        int starIdx;
        if (roll < 0.03f) starIdx = 4;
        else if (roll < 1f) starIdx = 3;
        else if (roll < 10f) starIdx = 2;
        else if (roll < 40f) starIdx = 1;
        else starIdx = 0;

        if (starPools[starIdx].Count > 0)
            return starPools[starIdx][UnityEngine.Random.Range(0, starPools[starIdx].Count)];

        // Fallback
        for (int i = starIdx - 1; i >= 0; i--)
            if (starPools[i].Count > 0)
                return starPools[i][UnityEngine.Random.Range(0, starPools[i].Count)];

        return allSkills.Length > 0 ? allSkills[UnityEngine.Random.Range(0, allSkills.Length)] : null;
    }

    void HandleResult(SkillData skill)
    {
        if (skill == null) return;
        if (!ownedSkills.ContainsKey(skill.skillName))
            ownedSkills[skill.skillName] = 0;
        ownedSkills[skill.skillName]++;
        SaveOwned();
    }

    public int GetOwnedCount(string skillName)
    {
        return ownedSkills.TryGetValue(skillName, out int count) ? count : 0;
    }

    /// <summary>
    /// 같은 스킬 합성으로 레벨업 (SkillUpgradeManager와 연동)
    /// 필요 수량: 현재 레벨과 동일 (Lv1→2: 1개, Lv2→3: 2개...)
    /// </summary>
    public bool TryMergeUpgrade(string skillName)
    {
        var sum = SkillUpgradeManager.Instance;
        if (sum == null) return false;

        int level = sum.GetLevel(skillName);
        if (level >= SkillUpgradeManager.MAX_SKILL_LEVEL) return false;

        int needed = level; // Lv1→2: 1개, Lv2→3: 2개...
        int owned = GetOwnedCount(skillName);
        if (owned < needed) return false;

        ownedSkills[skillName] -= needed;
        SaveOwned();

        // SkillUpgradeManager에서 직접 레벨 증가
        sum.ForceUpgrade(skillName);
        return true;
    }

    void SaveOwned()
    {
        var json = JsonUtility.ToJson(new SkillOwnedData(ownedSkills));
        PlayerPrefs.SetString("OwnedSkills", json);
    }

    void LoadOwned()
    {
        string json = PlayerPrefs.GetString("OwnedSkills", "");
        if (string.IsNullOrEmpty(json)) return;
        var data = JsonUtility.FromJson<SkillOwnedData>(json);
        if (data != null) data.ToDict(ownedSkills);
    }
}

/// <summary>
/// 스킬 보유 데이터 직렬화용
/// </summary>
[System.Serializable]
public class SkillOwnedData
{
    public List<string> names = new();
    public List<int> counts = new();

    public SkillOwnedData() {}
    public SkillOwnedData(Dictionary<string, int> dict)
    {
        foreach (var kv in dict) { names.Add(kv.Key); counts.Add(kv.Value); }
    }
    public void ToDict(Dictionary<string, int> dict)
    {
        dict.Clear();
        for (int i = 0; i < names.Count && i < counts.Count; i++)
            dict[names[i]] = counts[i];
    }
}
```

- [ ] **Step 3: SkillUpgradeManager에 ForceUpgrade 메서드 추가**

```csharp
// Assets/Scripts/Battle/SkillUpgradeManager.cs에 추가:

/// <summary>
/// 합성으로 인한 강제 레벨업 (골드 소모 없음)
/// </summary>
public bool ForceUpgrade(string skillName)
{
    if (string.IsNullOrEmpty(skillName)) return false;
    if (GetLevel(skillName) >= MAX_SKILL_LEVEL) return false;

    skillLevels[skillName] = GetLevel(skillName) + 1;
    PlayerPrefs.SetInt($"SkillLv_{skillName}", skillLevels[skillName]);
    OnSkillUpgraded?.Invoke(skillName, skillLevels[skillName]);
    SoundManager.Instance?.PlayLevelUpSFX();
    return true;
}
```

- [ ] **Step 4: 커밋**

```bash
git add Assets/Scripts/Battle/SkillScrollManager.cs Assets/Scripts/Battle/SkillGachaManager.cs Assets/Scripts/Battle/SkillUpgradeManager.cs
git commit -m "feat: 스킬 뽑기 + 합성 강화 시스템"
```

---

## Chunk 3: 탈것 시스템

### Task 5: 탈것 데이터 + 매니저 + 뽑기

**Files:**
- Create: `Assets/Scripts/Data/MountData.cs`
- Create: `Assets/Scripts/Battle/MountManager.cs`
- Create: `Assets/Scripts/Battle/MountStoneManager.cs` (재화)
- Create: `Assets/Scripts/Battle/MountGachaManager.cs`
- Modify: `Assets/Scripts/Battle/CharacterFactory.cs`
- Modify: `Assets/Scripts/Battle/UpgradeManager.cs`

- [ ] **Step 1: MountData ScriptableObject**

```csharp
// Assets/Scripts/Data/MountData.cs
using UnityEngine;

[CreateAssetMenu(fileName = "NewMount", menuName = "Game/Mount Data")]
public class MountData : ScriptableObject
{
    public string mountName;
    public StarGrade starGrade = StarGrade.Star1;

    [Header("SPUM Horse Sprite")]
    public string horseSprite; // BlackHorse, RedHorse, Horse1, Horse2...

    [Header("Bonuses")]
    public float bonusHp;
    public float bonusAtk;
    public float bonusDef;
    public float bonusMoveSpeed;
}
```

- [ ] **Step 2: MountStoneManager (재화)**

`SkillScrollManager`와 동일 구조, 키만 `"MountStones"`로 변경.

```csharp
// Assets/Scripts/Battle/MountStoneManager.cs
using UnityEngine;
using System;

public class MountStoneManager : MonoBehaviour
{
    public static MountStoneManager Instance { get; private set; }

    public int Stones { get; private set; }
    public event Action<int> OnStonesChanged;

    const string SAVE_KEY = "MountStones";
    bool saveDirty;
    float saveTimer;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }
        Stones = PlayerPrefs.GetInt(SAVE_KEY, 0);
    }

    public void AddStones(int amount)
    {
        if (amount <= 0) return;
        Stones += amount;
        MarkDirty();
        OnStonesChanged?.Invoke(Stones);
    }

    public bool SpendStones(int amount)
    {
        if (amount <= 0 || Stones < amount) return false;
        Stones -= amount;
        MarkDirty();
        OnStonesChanged?.Invoke(Stones);
        return true;
    }

    void MarkDirty() { saveDirty = true; saveTimer = 5f; }

    void Update()
    {
        if (!saveDirty) return;
        saveTimer -= Time.deltaTime;
        if (saveTimer <= 0f) FlushSave();
    }

    void FlushSave()
    {
        if (!saveDirty) return;
        PlayerPrefs.SetInt(SAVE_KEY, Stones);
        PlayerPrefs.Save();
        saveDirty = false;
    }

    void OnApplicationPause(bool p) { if (p) FlushSave(); }
    void OnApplicationQuit() { FlushSave(); }
}
```

- [ ] **Step 3: MountManager (장착/해제/보너스)**

```csharp
// Assets/Scripts/Battle/MountManager.cs
using UnityEngine;
using System;
using System.Collections.Generic;

/// <summary>
/// 탈것 인벤토리 + 영웅 장착 관리
/// </summary>
public class MountManager : MonoBehaviour
{
    public static MountManager Instance { get; private set; }

    MountData[] allMounts;
    readonly List<string> ownedMounts = new(); // mountName 목록
    readonly Dictionary<string, string> equipped = new(); // heroName → mountName

    public event Action OnMountChanged;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        allMounts = Resources.LoadAll<MountData>("Mounts");
        LoadData();
    }

    public void AddMount(string mountName)
    {
        ownedMounts.Add(mountName);
        SaveData();
        OnMountChanged?.Invoke();
    }

    public bool EquipMount(string heroName, string mountName)
    {
        if (!ownedMounts.Contains(mountName)) return false;
        equipped[heroName] = mountName;
        SaveData();
        OnMountChanged?.Invoke();
        return true;
    }

    public bool UnequipMount(string heroName)
    {
        if (!equipped.ContainsKey(heroName)) return false;
        equipped.Remove(heroName);
        SaveData();
        OnMountChanged?.Invoke();
        return true;
    }

    public MountData GetEquippedMount(string heroName)
    {
        if (!equipped.TryGetValue(heroName, out string mountName)) return null;
        return FindMountData(mountName);
    }

    public string GetEquippedMountSprite(string heroName)
    {
        var mount = GetEquippedMount(heroName);
        return mount != null ? mount.horseSprite : "";
    }

    public float GetBonusHp(string heroName)
    {
        var m = GetEquippedMount(heroName);
        return m != null ? m.bonusHp : 0f;
    }

    public float GetBonusAtk(string heroName)
    {
        var m = GetEquippedMount(heroName);
        return m != null ? m.bonusAtk : 0f;
    }

    public float GetBonusDef(string heroName)
    {
        var m = GetEquippedMount(heroName);
        return m != null ? m.bonusDef : 0f;
    }

    public float GetBonusMoveSpeed(string heroName)
    {
        var m = GetEquippedMount(heroName);
        return m != null ? m.bonusMoveSpeed : 0f;
    }

    public IReadOnlyList<string> OwnedMounts => ownedMounts;

    MountData FindMountData(string mountName)
    {
        for (int i = 0; i < allMounts.Length; i++)
            if (allMounts[i].mountName == mountName) return allMounts[i];
        return null;
    }

    void SaveData()
    {
        PlayerPrefs.SetString("OwnedMounts", string.Join(",", ownedMounts));
        var eqNames = new List<string>();
        var eqMounts = new List<string>();
        foreach (var kv in equipped) { eqNames.Add(kv.Key); eqMounts.Add(kv.Value); }
        PlayerPrefs.SetString("EquippedMountHeroes", string.Join(",", eqNames));
        PlayerPrefs.SetString("EquippedMountNames", string.Join(",", eqMounts));
        PlayerPrefs.Save();
    }

    void LoadData()
    {
        string owned = PlayerPrefs.GetString("OwnedMounts", "");
        if (!string.IsNullOrEmpty(owned))
        {
            var names = owned.Split(',');
            for (int i = 0; i < names.Length; i++)
                if (!string.IsNullOrEmpty(names[i])) ownedMounts.Add(names[i]);
        }

        string heroes = PlayerPrefs.GetString("EquippedMountHeroes", "");
        string mounts = PlayerPrefs.GetString("EquippedMountNames", "");
        if (!string.IsNullOrEmpty(heroes) && !string.IsNullOrEmpty(mounts))
        {
            var h = heroes.Split(',');
            var m = mounts.Split(',');
            for (int i = 0; i < h.Length && i < m.Length; i++)
                if (!string.IsNullOrEmpty(h[i]) && !string.IsNullOrEmpty(m[i]))
                    equipped[h[i]] = m[i];
        }
    }
}
```

- [ ] **Step 4: MountGachaManager (뽑기)**

`SkillGachaManager`와 동일 구조. `MountStoneManager` 재화 사용. `MountData` 풀에서 뽑기. 결과를 `MountManager.AddMount()`에 전달.

- [ ] **Step 5: CharacterFactory 탈것 연동 수정**

`CharacterFactory.CreateCharacter()`에서:
- 기존 `preset.horseSprite` 대신 `MountManager.GetEquippedMountSprite(heroName)` 사용 (아군일 때)
- 적 유닛은 기존대로 `preset.horseSprite` 사용

```csharp
// CreateCharacter 내부:
string horseSprite = preset.horseSprite;
if (team == BattleUnit.Team.Ally && MountManager.Instance != null)
{
    string mountSprite = MountManager.Instance.GetEquippedMountSprite(preset.characterName);
    if (!string.IsNullOrEmpty(mountSprite))
        horseSprite = mountSprite;
}
bool useHorse = !string.IsNullOrEmpty(horseSprite);
```

- [ ] **Step 6: UpgradeManager에 탈것 보너스 추가**

```csharp
// ApplyAllBonuses() 내부에 추가:
var mm = MountManager.Instance;
if (mm != null)
{
    hpBonus += mm.GetBonusHp(heroName);
    atkBonus += mm.GetBonusAtk(heroName);
    defBonus += mm.GetBonusDef(heroName);
    // moveSpeed는 별도 처리
    unit.moveSpeed = unit.baseMoveSpeed + mm.GetBonusMoveSpeed(heroName);
}
```

- [ ] **Step 7: MountDataCreator (초기 데이터)**

```
Star1: 늙은 말 (Horse1) - HP+10, Speed+0.1
Star2: 갈색 말 (Horse2) - HP+25, ATK+3, Speed+0.2
Star3: 붉은 말 (RedHorse) - HP+50, ATK+8, DEF+3, Speed+0.3
Star4: 검은 말 (BlackHorse) - HP+100, ATK+15, DEF+8, Speed+0.5
Star5: (추후 번들팩 추가)
```

- [ ] **Step 8: 커밋**

```bash
git add Assets/Scripts/Data/MountData.cs Assets/Scripts/Battle/MountManager.cs Assets/Scripts/Battle/MountStoneManager.cs Assets/Scripts/Battle/MountGachaManager.cs Assets/Scripts/Editor/MountDataCreator.cs Assets/Scripts/Battle/CharacterFactory.cs Assets/Scripts/Battle/UpgradeManager.cs
git commit -m "feat: 탈것 시스템 (뽑기/장착/보너스)"
```

---

## Chunk 4: 던전 시스템

### Task 6: 던전 매니저 + 전투 진행

**Files:**
- Create: `Assets/Scripts/Data/DungeonData.cs`
- Create: `Assets/Scripts/Battle/DungeonManager.cs`
- Create: `Assets/Scripts/Battle/DungeonRankingManager.cs`

- [ ] **Step 1: 던전 데이터 정의**

```csharp
// Assets/Scripts/Data/DungeonData.cs
using UnityEngine;

public enum DungeonType
{
    Hero,   // 보석
    Mount,  // 탈것 소환석
    Skill   // 스킬 주문서
}

[System.Serializable]
public class DungeonStageConfig
{
    public int stageNumber;           // 1~100
    public float timeLimit = 60f;     // 제한 시간 (초)
    public int enemyCount = 10;       // 적 수
    public StarGrade enemyMinGrade = StarGrade.Star1;
    public StarGrade enemyMaxGrade = StarGrade.Star2;
    public float enemyStatMultiplier = 1f;  // 기본 스탯 배율
    public int rewardAmount = 10;     // 재화 보상량
}
```

- [ ] **Step 2: DungeonManager 구현**

```csharp
// Assets/Scripts/Battle/DungeonManager.cs
using UnityEngine;
using System;
using System.Collections.Generic;

/// <summary>
/// 3종 던전 관리: 입장/진행/보상/점수
/// </summary>
public class DungeonManager : MonoBehaviour
{
    public static DungeonManager Instance { get; private set; }

    // 던전별 클리어한 최고 단계
    readonly Dictionary<DungeonType, int> clearedStages = new();

    // 현재 던전 진행 상태
    public bool IsInDungeon { get; private set; }
    public DungeonType CurrentDungeon { get; private set; }
    public int CurrentStage { get; private set; }
    public float TimeRemaining { get; private set; }
    public int CurrentScore { get; private set; }
    public int KillCount { get; private set; }

    const float BASE_TIME_LIMIT = 60f;
    const int BASE_ENEMY_COUNT = 10;
    const int SCORE_THRESHOLD = 100000; // 10만점 보상 기준

    public event Action<int> OnScoreChanged;
    public event Action<bool, int> OnDungeonComplete; // success, score

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        foreach (DungeonType t in Enum.GetValues(typeof(DungeonType)))
            clearedStages[t] = PlayerPrefs.GetInt($"DungeonCleared_{t}", 0);
    }

    public int GetClearedStage(DungeonType type)
    {
        return clearedStages.TryGetValue(type, out int s) ? s : 0;
    }

    public bool CanEnter(DungeonType type, int stage)
    {
        if (stage < 1 || stage > 100) return false;
        if (stage == 1) return true;
        return GetClearedStage(type) >= stage - 1;
    }

    /// <summary>
    /// 던전 입장
    /// </summary>
    public bool EnterDungeon(DungeonType type, int stage)
    {
        if (IsInDungeon) return false;
        if (!CanEnter(type, stage)) return false;

        IsInDungeon = true;
        CurrentDungeon = type;
        CurrentStage = stage;
        CurrentScore = 0;
        KillCount = 0;

        // 제한 시간: 기본 60초 + 단계별 약간 증가
        TimeRemaining = BASE_TIME_LIMIT + stage * 0.5f;

        // TODO: BattleManager와 연동하여 던전 전투 시작
        // 적 스폰 설정 등

        return true;
    }

    void Update()
    {
        if (!IsInDungeon) return;

        TimeRemaining -= Time.deltaTime;
        if (TimeRemaining <= 0f)
        {
            TimeRemaining = 0f;
            CompleteDungeon();
        }
    }

    /// <summary>
    /// 적 처치 시 호출
    /// </summary>
    public void RegisterKill(float speedBonus = 1f)
    {
        if (!IsInDungeon) return;
        KillCount++;
        // 점수 = 기본 100점 + 잔여시간 보너스 + 단계 보너스
        int scoreGain = 100 + Mathf.RoundToInt(TimeRemaining * 10f) + CurrentStage * 5;
        CurrentScore += scoreGain;
        OnScoreChanged?.Invoke(CurrentScore);
    }

    void CompleteDungeon()
    {
        IsInDungeon = false;

        bool success = KillCount > 0; // 최소 1킬

        // 클리어 기록 갱신
        if (success && CurrentStage > GetClearedStage(CurrentDungeon))
        {
            clearedStages[CurrentDungeon] = CurrentStage;
            PlayerPrefs.SetInt($"DungeonCleared_{CurrentDungeon}", CurrentStage);
            PlayerPrefs.Save();
        }

        // 보상 지급
        if (success)
            GiveReward();

        // 랭킹 등록
        DungeonRankingManager.Instance?.SubmitScore(CurrentDungeon, CurrentStage, CurrentScore);

        OnDungeonComplete?.Invoke(success, CurrentScore);
    }

    /// <summary>
    /// 수동 클리어 (모든 적 처치 시)
    /// </summary>
    public void ForceComplete()
    {
        if (!IsInDungeon) return;
        CompleteDungeon();
    }

    void GiveReward()
    {
        // 기본 보상 + 단계 보너스
        int baseReward = 10 + CurrentStage * 2;

        // 10만점 이상 추가 보상
        if (CurrentScore >= SCORE_THRESHOLD)
            baseReward = Mathf.RoundToInt(baseReward * 1.5f);

        switch (CurrentDungeon)
        {
            case DungeonType.Hero:
                GemManager.Instance?.AddGem(baseReward);
                break;
            case DungeonType.Mount:
                MountStoneManager.Instance?.AddStones(baseReward);
                break;
            case DungeonType.Skill:
                SkillScrollManager.Instance?.AddScrolls(baseReward);
                break;
        }

        ToastNotification.Instance?.Show(
            $"던전 클리어! +{baseReward} {GetRewardName(CurrentDungeon)}", "");
    }

    string GetRewardName(DungeonType type) => type switch
    {
        DungeonType.Hero => "보석",
        DungeonType.Mount => "소환석",
        DungeonType.Skill => "주문서",
        _ => ""
    };
}
```

- [ ] **Step 3: DungeonRankingManager**

```csharp
// Assets/Scripts/Battle/DungeonRankingManager.cs
using UnityEngine;
using System;
using System.Collections.Generic;

/// <summary>
/// 던전 랭킹 (로컬 저장, 추후 서버 연동 가능)
/// </summary>
public class DungeonRankingManager : MonoBehaviour
{
    public static DungeonRankingManager Instance { get; private set; }

    // 던전타입_단계 → 최고 점수
    readonly Dictionary<string, int> bestScores = new();

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }
        LoadScores();
    }

    public void SubmitScore(DungeonType type, int stage, int score)
    {
        string key = $"{type}_{stage}";
        int prev = GetBestScore(type, stage);
        if (score > prev)
        {
            bestScores[key] = score;
            PlayerPrefs.SetInt($"DungeonScore_{key}", score);
            PlayerPrefs.Save();
        }
    }

    public int GetBestScore(DungeonType type, int stage)
    {
        string key = $"{type}_{stage}";
        return bestScores.TryGetValue(key, out int s) ? s : 0;
    }

    void LoadScores()
    {
        foreach (DungeonType t in Enum.GetValues(typeof(DungeonType)))
        {
            for (int i = 1; i <= 100; i++)
            {
                string key = $"{t}_{i}";
                int score = PlayerPrefs.GetInt($"DungeonScore_{key}", 0);
                if (score > 0) bestScores[key] = score;
            }
        }
    }
}
```

- [ ] **Step 4: 커밋**

```bash
git add Assets/Scripts/Data/DungeonData.cs Assets/Scripts/Battle/DungeonManager.cs Assets/Scripts/Battle/DungeonRankingManager.cs
git commit -m "feat: 던전 시스템 (3종 던전/100단계/점수/보상)"
```

---

## Chunk 5: SceneSetup + UI 연동 + 통합

### Task 7: SceneSetup에 새 매니저 등록

**Files:**
- Modify: `Assets/Scripts/Editor/SceneSetupTool.cs`

- [ ] **Step 1: SceneSetupTool에 새 매니저 GameObject 추가**

기존 `[Managers]` 오브젝트 아래에 추가할 컴포넌트:
- `SkillScrollManager`
- `MountStoneManager`
- `SkillGachaManager`
- `MountGachaManager`
- `MountManager`
- `SkillSynergyManager`
- `DungeonManager`
- `DungeonRankingManager`

- [ ] **Step 2: 커밋**

```bash
git add Assets/Scripts/Editor/SceneSetupTool.cs
git commit -m "feat: SceneSetup에 신규 매니저 등록"
```

### Task 8: MainHUD에 새 재화 표시 + 던전/탈것 탭

**Files:**
- Modify: `Assets/Scripts/UI/MainHUD.cs`

- [ ] **Step 1: 상단 HUD에 재화 표시 추가**

기존 골드/보석 옆에 탈것 소환석/스킬 주문서 표시

- [ ] **Step 2: 하단 탭에 던전 탭 추가 or 기존 탭 내 서브탭**

상점 탭 내에 던전 서브탭 또는 별도 메뉴

- [ ] **Step 3: 소환 탭에 영웅/스킬/탈것 서브탭**

기존 소환 탭을 3개 서브탭으로 분할:
- 영웅 소환 (기존 GachaManager)
- 스킬 소환 (SkillGachaManager)
- 탈것 소환 (MountGachaManager)

- [ ] **Step 4: 커밋**

```bash
git add Assets/Scripts/UI/MainHUD.cs
git commit -m "feat: MainHUD 재화/소환/던전 UI 통합"
```

### Task 9: 최종 통합 테스트

- [ ] **Step 1: Unity 에디터에서 컴파일 확인 (mcp-unity recompile)**
- [ ] **Step 2: PresetCreator / SkillDataCreator / MountDataCreator / SynergyDataCreator 실행하여 ScriptableObject 생성**
- [ ] **Step 3: 게임 플레이 테스트**
  - 영웅 뽑기 → 5성급 확률 확인
  - 스킬 뽑기 → 보유/합성 레벨업
  - 탈것 뽑기 → 영웅 장착 → 전투에서 말 표시
  - 몬스터 성급 → 보스 크기 확인
  - 스킬 시너지 → 조합 효과 발동
  - 던전 입장 → 전투 → 점수/보상
- [ ] **Step 4: 최종 커밋**

```bash
git add -A
git commit -m "feat: 성급 시스템 통합 + 전체 컴파일 확인"
```
