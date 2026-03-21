using UnityEngine;
using System;
using System.Collections.Generic;

public class HeroLevelManager : MonoBehaviour
{
    public static HeroLevelManager Instance { get; private set; }

    public const int MAX_LEVEL = 50;
    public const int MAX_STAR = 5;
    public const int MAX_AWAKENING = 5;

    // 레벨당 스탯 증가량
    const float HP_PER_LEVEL  = 12f;
    const float ATK_PER_LEVEL = 2.5f;
    const float DEF_PER_LEVEL = 1f;

    private Dictionary<string, int> heroLevels = new();
    private Dictionary<string, int> heroCopies = new(); // 중복 소환 횟수 (강화 재료)
    private Dictionary<string, int> heroStars = new();  // 승급 (1~5★)
    private Dictionary<string, int> heroAwakening = new(); // 각성 단계 (0~5)

    // 승급별 스탯 배율
    static readonly float[] STAR_MULTIPLIER = { 1f, 1f, 1.15f, 1.3f, 1.5f, 1.8f }; // index 0 unused

    // 각성별 스탯 배율
    static readonly float[] AWAKENING_MULTIPLIER = { 1f, 1.1f, 1.25f, 1.45f, 1.7f, 2.0f };

    public event Action<string, int> OnHeroLevelUp;
    public event Action<string, int> OnHeroStarUp;
    public event Action<string, int> OnHeroAwakened;

    void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }
        else
        {
            Destroy(gameObject);
        }
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }

    public int GetLevel(string heroName)
    {
        if (!heroLevels.ContainsKey(heroName))
            LoadHero(heroName);
        return heroLevels[heroName];
    }

    public int GetCopies(string heroName)
    {
        if (!heroCopies.ContainsKey(heroName))
            LoadHero(heroName);
        return heroCopies[heroName];
    }

    /// <summary>
    /// 레벨업에 필요한 중복 소환 수
    /// </summary>
    public int GetCopiesNeeded(int level)
    {
        if (level < 5) return 1;
        if (level < 10) return 2;
        if (level < 20) return 3;
        if (level < 30) return 5;
        return 8;
    }

    /// <summary>
    /// 가챠에서 중복 소환 시 호출
    /// </summary>
    public void AddCopy(string heroName)
    {
        if (!heroCopies.ContainsKey(heroName))
            LoadHero(heroName);
        heroCopies[heroName]++;
        SaveHero(heroName);
    }

    /// <summary>
    /// 중복 카드를 소모하여 레벨업
    /// </summary>
    public bool TryLevelUp(string heroName)
    {
        if (!heroLevels.ContainsKey(heroName))
            LoadHero(heroName);

        int level = heroLevels[heroName];
        if (level >= MAX_LEVEL) return false;

        int needed = GetCopiesNeeded(level);
        if (heroCopies[heroName] < needed) return false;

        heroCopies[heroName] -= needed;
        heroLevels[heroName]++;
        OnHeroLevelUp?.Invoke(heroName, heroLevels[heroName]);
        SaveHero(heroName);
        return true;
    }

    // ═══ Star Rank (승급) ═══

    public int GetStarRank(string heroName)
    {
        if (!heroStars.ContainsKey(heroName))
            heroStars[heroName] = PlayerPrefs.GetInt(SaveKeys.HeroStarPrefix + heroName, 1);
        return heroStars[heroName];
    }

    /// <summary>
    /// 승급 조건: MAX_LEVEL 도달 + 필요 카드 수 보유
    /// </summary>
    public int GetStarUpCopiesNeeded(int currentStar)
    {
        return currentStar switch
        {
            1 => 5,
            2 => 10,
            3 => 20,
            4 => 40,
            _ => 999
        };
    }

    public bool CanStarUp(string heroName)
    {
        int star = GetStarRank(heroName);
        if (star >= MAX_STAR) return false;
        if (GetLevel(heroName) < MAX_LEVEL) return false;
        return GetCopies(heroName) >= GetStarUpCopiesNeeded(star);
    }

    public bool TryStarUp(string heroName)
    {
        if (!CanStarUp(heroName)) return false;
        int star = GetStarRank(heroName);
        int needed = GetStarUpCopiesNeeded(star);

        heroCopies[heroName] -= needed;
        heroStars[heroName] = star + 1;
        PlayerPrefs.SetInt(SaveKeys.HeroStarPrefix + heroName, heroStars[heroName]);
        SaveHero(heroName);
        OnHeroStarUp?.Invoke(heroName, heroStars[heroName]);
        SoundManager.Instance?.PlayLevelUpSFX();
        return true;
    }

    public float GetStarMultiplier(string heroName)
    {
        int star = GetStarRank(heroName);
        return star >= 0 && star < STAR_MULTIPLIER.Length ? STAR_MULTIPLIER[star] : 1f;
    }

    // ═══ Awakening (각성) ═══

    public int GetAwakeningStage(string heroName)
    {
        if (!heroAwakening.ContainsKey(heroName))
            heroAwakening[heroName] = PlayerPrefs.GetInt(SaveKeys.HeroAwakeningPrefix + heroName, 0);
        return heroAwakening[heroName];
    }

    /// <summary>
    /// 각성 조건: 카피 수 (성급별 차등)
    /// </summary>
    public int GetAwakeningCopiesNeeded(int currentStar)
    {
        return currentStar switch
        {
            1 => 5,
            2 => 10,
            3 => 20,
            4 => 30,
            5 => 50,
            _ => 999
        };
    }

    public bool CanAwaken(string heroName)
    {
        int awakening = GetAwakeningStage(heroName);
        if (awakening >= MAX_AWAKENING) return false;
        int star = GetStarRank(heroName);
        return GetCopies(heroName) >= GetAwakeningCopiesNeeded(star);
    }

    public bool TryAwaken(string heroName)
    {
        if (!CanAwaken(heroName)) return false;
        int star = GetStarRank(heroName);
        int needed = GetAwakeningCopiesNeeded(star);

        heroCopies[heroName] -= needed;
        heroAwakening[heroName]++;
        OnHeroAwakened?.Invoke(heroName, heroAwakening[heroName]);
        SaveHero(heroName);
        return true;
    }

    /// <summary>각성석 소모 비용 (성급별). 카피 대신 각성석으로 각성 가능.</summary>
    public int GetAwakeStoneCost(int star) => star switch
    {
        1 => 3,
        2 => 6,
        3 => 12,
        4 => 25,
        5 => 50,
        _ => 3
    };

    /// <summary>각성석으로 각성 가능 여부 (카피 무관).</summary>
    public bool CanAwakenWithStone(string heroName)
    {
        if (GetAwakeningStage(heroName) >= MAX_AWAKENING) return false;
        int cost = GetAwakeStoneCost(GetStarRank(heroName));
        return AwakeningStoneManager.Instance != null && AwakeningStoneManager.Instance.Stone >= cost;
    }

    /// <summary>각성석 소모로 각성 시도. 성공 시 true.</summary>
    public bool TryAwakenWithStone(string heroName)
    {
        if (GetAwakeningStage(heroName) >= MAX_AWAKENING) return false;
        int cost = GetAwakeStoneCost(GetStarRank(heroName));
        if (AwakeningStoneManager.Instance == null || !AwakeningStoneManager.Instance.SpendStone(cost))
            return false;

        heroAwakening[heroName] = (heroAwakening.TryGetValue(heroName, out int cur) ? cur : 0) + 1;
        OnHeroAwakened?.Invoke(heroName, heroAwakening[heroName]);
        SaveHero(heroName);
        return true;
    }

    public float GetAwakeningMultiplier(string heroName)
    {
        int awakening = GetAwakeningStage(heroName);
        return awakening >= 0 && awakening < AWAKENING_MULTIPLIER.Length ? AWAKENING_MULTIPLIER[awakening] : 1f;
    }

    // ═══ Stat Bonuses ═══

    public float GetHpBonus(string heroName)  => (GetLevel(heroName) - 1) * HP_PER_LEVEL  * GetStarMultiplier(heroName) * GetAwakeningMultiplier(heroName);
    public float GetAtkBonus(string heroName) => (GetLevel(heroName) - 1) * ATK_PER_LEVEL * GetStarMultiplier(heroName) * GetAwakeningMultiplier(heroName);
    public float GetDefBonus(string heroName) => (GetLevel(heroName) - 1) * DEF_PER_LEVEL * GetStarMultiplier(heroName) * GetAwakeningMultiplier(heroName);

    /// <summary>
    /// 단독 사용 금지 — UpgradeManager.ApplyAllBonuses() 사용 권장
    /// (버프/장비/업그레이드 통합 계산)
    /// </summary>
    public void ApplyToUnit(BattleUnit unit)
    {
        UpgradeManager.ApplyAllBonuses(unit);
    }

    // ═══ Save/Load ═══

    public void SaveAll()
    {
        foreach (var heroName in heroLevels.Keys)
            SaveHero(heroName);
        PlayerPrefs.Save();
    }

    void SaveHero(string name)
    {
        PlayerPrefs.SetInt(SaveKeys.HeroLevelPrefix + name, heroLevels[name]);
        PlayerPrefs.SetInt(SaveKeys.HeroCopiesPrefix + name, heroCopies[name]);
        PlayerPrefs.SetInt(SaveKeys.HeroAwakeningPrefix + name, heroAwakening[name]);
    }

    public void LoadHero(string name)
    {
        heroLevels[name] = PlayerPrefs.GetInt(SaveKeys.HeroLevelPrefix + name, 1);
        heroCopies[name] = PlayerPrefs.GetInt(SaveKeys.HeroCopiesPrefix + name, 0);
        heroAwakening[name] = PlayerPrefs.GetInt(SaveKeys.HeroAwakeningPrefix + name, 0);
    }

    void OnApplicationPause(bool pause)
    {
        if (pause) SaveAll();
    }

    void OnApplicationQuit()
    {
        SaveAll();
    }
}
