using UnityEngine;
using System;
using System.Collections.Generic;

/// <summary>
/// 보석으로 영웅 소환 (가챠)
/// - 단일 뽑기: 50보석
/// - 10연차: 450보석 (1회 할인)
/// - 레어리티 가중치: Common 60%, Rare 25%, Epic 12%, Legendary 3%
/// - 천장(pity): 10회 이내 Rare+ 미출 시 보장
/// - 10연차: 최소 1 Rare+ 보장
/// </summary>
public class GachaManager : MonoBehaviour
{
    public static GachaManager Instance { get; private set; }

    public const int SINGLE_PULL_COST = 50;
    public const int MULTI_PULL_COST = 450; // 10연차 (1회 무료)

    [Header("Hero Pool")]
    [SerializeField] CharacterPreset[] allHeroes;

    public event Action<CharacterPreset> OnHeroPulled;
    public event Action<CharacterPreset[]> OnMultiPulled;

    // Pity counter
    int pullsSinceRare;

    // Rarity tiers sorted from pool
    readonly List<CharacterPreset> commonPool = new();
    readonly List<CharacterPreset> rarePool = new();
    readonly List<CharacterPreset> epicPool = new();
    readonly List<CharacterPreset> legendaryPool = new();

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        // Resources에서 로드 시도 (없으면 빈 배열)
        var loaded = Resources.LoadAll<CharacterPreset>("Presets");
        if (loaded != null && loaded.Length > 0)
            allHeroes = loaded;
        else if (allHeroes == null)
            allHeroes = Array.Empty<CharacterPreset>();

        pullsSinceRare = PlayerPrefs.GetInt("PullsSinceRare", 0);
        RebuildRarityPools();
    }

    void RebuildRarityPools()
    {
        commonPool.Clear();
        rarePool.Clear();
        epicPool.Clear();
        legendaryPool.Clear();

        for (int i = 0; i < allHeroes.Length; i++)
        {
            var hero = allHeroes[i];
            if (hero == null) continue;
            switch (hero.rarity)
            {
                case HeroRarity.Common: commonPool.Add(hero); break;
                case HeroRarity.Rare: rarePool.Add(hero); break;
                case HeroRarity.Epic: epicPool.Add(hero); break;
                case HeroRarity.Legendary: legendaryPool.Add(hero); break;
            }
        }
    }

    /// <summary>
    /// 외부에서 영웅 풀 설정 (Inspector 또는 런타임)
    /// </summary>
    public void SetHeroPool(CharacterPreset[] heroes)
    {
        allHeroes = heroes ?? Array.Empty<CharacterPreset>();
        RebuildRarityPools();
    }

    /// <summary>
    /// 현재 풀 크기
    /// </summary>
    public int HeroPoolCount => allHeroes.Length;

    /// <summary>
    /// 단일 뽑기 (50보석)
    /// </summary>
    public CharacterPreset SinglePull()
    {
        if (allHeroes.Length == 0)
        {
            Debug.LogWarning("[GachaManager] Hero pool is empty!");
            return null;
        }

        if (GemManager.Instance == null)
        {
            Debug.LogWarning("[GachaManager] GemManager not found!");
            return null;
        }

        if (!GemManager.Instance.SpendGem(SINGLE_PULL_COST))
        {
            Debug.Log("[GachaManager] Not enough gems for single pull.");
            return null;
        }

        var hero = PullOne(false);
        HandlePullResult(hero);
        SoundManager.Instance?.PlayGachaSFX();
        OnHeroPulled?.Invoke(hero);
        DailyMissionManager.Instance?.RegisterGacha();
        return hero;
    }

    /// <summary>
    /// 10연차 (450보석, 1회 할인 포함)
    /// 최소 1 Rare+ 보장
    /// </summary>
    public CharacterPreset[] MultiPull()
    {
        if (allHeroes.Length == 0)
        {
            Debug.LogWarning("[GachaManager] Hero pool is empty!");
            return null;
        }

        if (GemManager.Instance == null)
        {
            Debug.LogWarning("[GachaManager] GemManager not found!");
            return null;
        }

        if (!GemManager.Instance.SpendGem(MULTI_PULL_COST))
        {
            Debug.Log("[GachaManager] Not enough gems for multi pull.");
            return null;
        }

        var results = new CharacterPreset[10];
        bool hasRarePlus = false;

        for (int i = 0; i < 10; i++)
        {
            results[i] = PullOne(false);
            if (results[i] != null && results[i].rarity >= HeroRarity.Rare)
                hasRarePlus = true;
        }

        // 10연차 Rare+ 보장: 없으면 마지막 슬롯을 Rare+로 교체
        if (!hasRarePlus)
            results[9] = PullOne(true);

        // 결과 처리 (중복/신규)
        for (int i = 0; i < 10; i++)
            HandlePullResult(results[i]);

        SoundManager.Instance?.PlayGachaSFX();
        OnMultiPulled?.Invoke(results);
        DailyMissionManager.Instance?.RegisterGacha();
        return results;
    }

    /// <summary>
    /// 레어리티 가중치 뽑기
    /// Common 60%, Rare 25%, Epic 12%, Legendary 3%
    /// Pity: 10회 연속 Common이면 Rare+ 보장
    /// </summary>
    CharacterPreset PullOne(bool guaranteeRarePlus)
    {
        if (allHeroes.Length == 0) return null;

        HeroRarity selectedRarity;

        if (guaranteeRarePlus || pullsSinceRare >= 9)
        {
            // Pity 발동: Rare+ 보장 (Rare 70%, Epic 22%, Legendary 8%)
            float pityRoll = UnityEngine.Random.Range(0f, 100f);
            if (pityRoll < 8f)
                selectedRarity = HeroRarity.Legendary;
            else if (pityRoll < 30f)
                selectedRarity = HeroRarity.Epic;
            else
                selectedRarity = HeroRarity.Rare;

            pullsSinceRare = 0;
        }
        else
        {
            float roll = UnityEngine.Random.Range(0f, 100f);
            if (roll < 3f)
                selectedRarity = HeroRarity.Legendary;
            else if (roll < 15f) // 3 + 12
                selectedRarity = HeroRarity.Epic;
            else if (roll < 40f) // 15 + 25
                selectedRarity = HeroRarity.Rare;
            else
                selectedRarity = HeroRarity.Common;

            if (selectedRarity == HeroRarity.Common)
                pullsSinceRare++;
            else
                pullsSinceRare = 0;
        }

        SavePity();

        // Pick random from selected rarity pool, fallback if empty
        var pool = GetPool(selectedRarity);
        if (pool.Count > 0)
            return pool[UnityEngine.Random.Range(0, pool.Count)];

        // Fallback: try lower rarities, then any
        for (int r = (int)selectedRarity - 1; r >= 0; r--)
        {
            var fallback = GetPool((HeroRarity)r);
            if (fallback.Count > 0)
                return fallback[UnityEngine.Random.Range(0, fallback.Count)];
        }
        // Last resort: any hero
        return allHeroes[UnityEngine.Random.Range(0, allHeroes.Length)];
    }

    List<CharacterPreset> GetPool(HeroRarity rarity)
    {
        return rarity switch
        {
            HeroRarity.Common => commonPool,
            HeroRarity.Rare => rarePool,
            HeroRarity.Epic => epicPool,
            HeroRarity.Legendary => legendaryPool,
            _ => commonPool
        };
    }

    void SavePity()
    {
        PlayerPrefs.SetInt("PullsSinceRare", pullsSinceRare);
    }

    /// <summary>
    /// 뽑기 결과 처리: 중복이면 경험치 보상 (예정), 신규면 roster 추가
    /// </summary>
    void HandlePullResult(CharacterPreset hero)
    {
        if (hero == null) return;

        var deck = DeckManager.Instance;
        if (deck == null) return;

        // roster에 이미 있는지 확인
        bool isDuplicate = false;
        for (int i = 0; i < deck.roster.Count; i++)
        {
            if (deck.roster[i] == hero)
            {
                isDuplicate = true;
                break;
            }
        }

        if (isDuplicate)
        {
            // 중복 영웅: 강화 재료로 카피 추가
            if (HeroLevelManager.Instance != null)
                HeroLevelManager.Instance.AddCopy(hero.characterName);
        }
        else
        {
            // 신규 영웅: roster에 추가
            deck.roster.Add(hero);
        }
    }
}
