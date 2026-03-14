using UnityEngine;
using System;
using System.Collections.Generic;

public class HeroLevelManager : MonoBehaviour
{
    public static HeroLevelManager Instance { get; private set; }

    public const int MAX_LEVEL = 50;
    public const int MAX_STAR = 5;

    private Dictionary<string, int> heroLevels = new();
    private Dictionary<string, int> heroCopies = new(); // 중복 소환 횟수 (강화 재료)
    private Dictionary<string, int> heroStars = new();  // 승급 (1~5★)

    // 승급별 스탯 배율
    static readonly float[] STAR_MULTIPLIER = { 1f, 1f, 1.15f, 1.3f, 1.5f, 1.8f }; // index 0 unused

    public event Action<string, int> OnHeroLevelUp;
    public event Action<string, int> OnHeroStarUp;

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
            heroStars[heroName] = PlayerPrefs.GetInt($"HeroStar_{heroName}", 1);
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
        PlayerPrefs.SetInt($"HeroStar_{heroName}", heroStars[heroName]);
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

    // ═══ Stat Bonuses ═══

    public float GetHpBonus(string heroName)
    {
        return (GetLevel(heroName) - 1) * 12f * GetStarMultiplier(heroName);
    }

    public float GetAtkBonus(string heroName)
    {
        return (GetLevel(heroName) - 1) * 2.5f * GetStarMultiplier(heroName);
    }

    public float GetDefBonus(string heroName)
    {
        return (GetLevel(heroName) - 1) * 1f * GetStarMultiplier(heroName);
    }

    public void ApplyToUnit(BattleUnit unit)
    {
        string heroName = unit.unitName;
        unit.maxHp = unit.baseMaxHp + GetHpBonus(heroName);
        unit.atk = unit.baseAtk + GetAtkBonus(heroName);
        unit.def = unit.baseDef + GetDefBonus(heroName);

        if (unit.CurrentHp > 0)
            unit.CurrentHp = unit.maxHp;
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
        PlayerPrefs.SetInt($"HeroLevel_{name}", heroLevels[name]);
        PlayerPrefs.SetInt($"HeroCopies_{name}", heroCopies[name]);
    }

    public void LoadHero(string name)
    {
        heroLevels[name] = PlayerPrefs.GetInt($"HeroLevel_{name}", 1);
        heroCopies[name] = PlayerPrefs.GetInt($"HeroCopies_{name}", 0);
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
