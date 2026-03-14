using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// 도감 시스템: 영웅/몬스터/장비 발견 기록 + 완성 보상
/// </summary>
public class CollectionManager : MonoBehaviour
{
    public static CollectionManager Instance { get; private set; }

    // 발견한 항목 이름 저장
    HashSet<string> discoveredHeroes = new();
    HashSet<string> discoveredMonsters = new();
    HashSet<string> discoveredEquipSlots = new(); // "슬롯_등급" 형태

    public event System.Action OnCollectionChanged;

    // 전체 컬렉션 크기 (하드코딩 - PresetCreator 기준)
    public const int TOTAL_HEROES = 7;
    public const int TOTAL_MONSTERS = 13;
    public const int TOTAL_EQUIP_TYPES = 18; // 6슬롯 x 3등급대(1-2, 3, 4-5)

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }
        LoadCollection();
    }

    // ═══ 등록 ═══

    public void RegisterHero(string heroName)
    {
        if (string.IsNullOrEmpty(heroName)) return;
        if (discoveredHeroes.Add(heroName))
        {
            SaveCollection();
            OnCollectionChanged?.Invoke();
            CheckMilestone("hero", discoveredHeroes.Count);
        }
    }

    public void RegisterMonster(string monsterName)
    {
        if (string.IsNullOrEmpty(monsterName)) return;
        if (discoveredMonsters.Add(monsterName))
        {
            SaveCollection();
            OnCollectionChanged?.Invoke();
            CheckMilestone("monster", discoveredMonsters.Count);
        }
    }

    public void RegisterEquipment(EquipmentSlot slot, int rarity)
    {
        string tier = rarity <= 2 ? "low" : rarity <= 3 ? "mid" : "high";
        string key = $"{slot}_{tier}";
        if (discoveredEquipSlots.Add(key))
        {
            SaveCollection();
            OnCollectionChanged?.Invoke();
        }
    }

    // ═══ 조회 ═══

    public int HeroCount => discoveredHeroes.Count;
    public int MonsterCount => discoveredMonsters.Count;
    public int EquipCount => discoveredEquipSlots.Count;

    public float HeroProgress => (float)discoveredHeroes.Count / TOTAL_HEROES;
    public float MonsterProgress => (float)discoveredMonsters.Count / TOTAL_MONSTERS;
    public float EquipProgress => (float)discoveredEquipSlots.Count / TOTAL_EQUIP_TYPES;
    public float TotalProgress => (HeroCount + MonsterCount + EquipCount) /
                                   (float)(TOTAL_HEROES + TOTAL_MONSTERS + TOTAL_EQUIP_TYPES);

    public bool IsHeroDiscovered(string name) => discoveredHeroes.Contains(name);
    public bool IsMonsterDiscovered(string name) => discoveredMonsters.Contains(name);

    public IReadOnlyCollection<string> DiscoveredHeroes => discoveredHeroes;
    public IReadOnlyCollection<string> DiscoveredMonsters => discoveredMonsters;

    // ═══ 마일스톤 보상 ═══

    void CheckMilestone(string type, int count)
    {
        int[] milestones = { 3, 5, 7, 10, 13 };
        for (int i = 0; i < milestones.Length; i++)
        {
            if (count != milestones[i]) continue;
            string key = $"Collection_{type}_{count}";
            if (PlayerPrefs.GetInt(key, 0) == 1) continue;

            PlayerPrefs.SetInt(key, 1);
            int gemReward = count * 5;
            GemManager.Instance?.AddGem(gemReward);
            ToastNotification.Instance?.Show($"도감 보상!", $"+{gemReward} 보석", UIColors.Text_Diamond);
        }
    }

    // ═══ Save/Load ═══

    void SaveCollection()
    {
        PlayerPrefs.SetString("Collection_Heroes", string.Join(",", discoveredHeroes));
        PlayerPrefs.SetString("Collection_Monsters", string.Join(",", discoveredMonsters));
        PlayerPrefs.SetString("Collection_Equips", string.Join(",", discoveredEquipSlots));
    }

    void LoadCollection()
    {
        LoadSet("Collection_Heroes", discoveredHeroes);
        LoadSet("Collection_Monsters", discoveredMonsters);
        LoadSet("Collection_Equips", discoveredEquipSlots);
    }

    void OnApplicationPause(bool pause)
    {
        if (pause) { SaveCollection(); PlayerPrefs.Save(); }
    }

    void OnApplicationQuit()
    {
        SaveCollection();
        PlayerPrefs.Save();
    }

    static void LoadSet(string key, HashSet<string> set)
    {
        string data = PlayerPrefs.GetString(key, "");
        if (string.IsNullOrEmpty(data)) return;
        var parts = data.Split(',');
        for (int i = 0; i < parts.Length; i++)
        {
            string s = parts[i].Trim();
            if (!string.IsNullOrEmpty(s)) set.Add(s);
        }
    }
}
