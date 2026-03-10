using UnityEngine;
using System;
using System.Collections.Generic;

public class HeroLevelManager : MonoBehaviour
{
    public static HeroLevelManager Instance { get; private set; }

    public const int MAX_LEVEL = 50;

    private Dictionary<string, int> heroLevels = new();
    private Dictionary<string, int> heroCopies = new(); // 중복 소환 횟수 (강화 재료)

    public event Action<string, int> OnHeroLevelUp;

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

    // ═══ Stat Bonuses ═══

    public float GetHpBonus(string heroName)
    {
        return (GetLevel(heroName) - 1) * 12f;
    }

    public float GetAtkBonus(string heroName)
    {
        return (GetLevel(heroName) - 1) * 2.5f;
    }

    public float GetDefBonus(string heroName)
    {
        return (GetLevel(heroName) - 1) * 1f;
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
