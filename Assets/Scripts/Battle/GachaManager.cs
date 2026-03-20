using UnityEngine;
using System;
using System.Collections.Generic;

/// <summary>
/// 보석으로 영웅 소환 (가챠)
/// - 단일 뽑기: 50보석
/// - 10연차: 450보석 (1회 할인)
/// - StarGrade 확률: 1성 60%, 2성 30%, 3성 9%, 4성 0.97%, 5성 0.03%
/// - 천장(pity) 없음 — F2P 무한반복 모델
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

    // StarGrade tiers sorted from pool
    readonly List<CharacterPreset> star1Pool = new();
    readonly List<CharacterPreset> star2Pool = new();
    readonly List<CharacterPreset> star3Pool = new();
    readonly List<CharacterPreset> star4Pool = new();
    readonly List<CharacterPreset> star5Pool = new();

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

        RebuildStarPools();
    }

    void RebuildStarPools()
    {
        star1Pool.Clear();
        star2Pool.Clear();
        star3Pool.Clear();
        star4Pool.Clear();
        star5Pool.Clear();

        for (int i = 0; i < allHeroes.Length; i++)
        {
            var hero = allHeroes[i];
            if (hero == null || hero.isEnemy) continue;
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

    /// <summary>
    /// 외부에서 영웅 풀 설정 (Inspector 또는 런타임)
    /// </summary>
    public void SetHeroPool(CharacterPreset[] heroes)
    {
        allHeroes = heroes ?? Array.Empty<CharacterPreset>();
        RebuildStarPools();
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
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

        var hero = PullOne();
        HandlePullResult(hero);
        SoundManager.Instance?.PlayGachaSFX();
        OnHeroPulled?.Invoke(hero);
        DailyMissionManager.Instance?.RegisterGacha();
        return hero;
    }

    /// <summary>
    /// 10연차 (450보석, 1회 할인 포함)
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
        for (int i = 0; i < 10; i++)
            results[i] = PullOne();

        // 결과 처리 (중복/신규)
        for (int i = 0; i < 10; i++)
            HandlePullResult(results[i]);

        SoundManager.Instance?.PlayGachaSFX();
        OnMultiPulled?.Invoke(results);
        DailyMissionManager.Instance?.RegisterGacha();
        return results;
    }

    /// <summary>
    /// StarGrade 가중치 뽑기
    /// 1성 60%, 2성 30%, 3성 9%, 4성 0.97%, 5성 0.03%
    /// 천장 없음
    /// </summary>
    CharacterPreset PullOne()
    {
        if (allHeroes.Length == 0) return null;

        float roll = UnityEngine.Random.Range(0f, 100f);

        StarGrade selectedGrade;
        if (roll < 0.03f)
            selectedGrade = StarGrade.Star5;
        else if (roll < 1f)       // 0.03 + 0.97
            selectedGrade = StarGrade.Star4;
        else if (roll < 10f)      // 1 + 9
            selectedGrade = StarGrade.Star3;
        else if (roll < 40f)      // 10 + 30
            selectedGrade = StarGrade.Star2;
        else
            selectedGrade = StarGrade.Star1;

        // Pick random from selected grade pool, fallback if empty
        var pool = GetPool(selectedGrade);
        if (pool.Count > 0)
            return pool[UnityEngine.Random.Range(0, pool.Count)];

        // Fallback: try lower grades, then any
        for (int g = (int)selectedGrade - 1; g >= 1; g--)
        {
            var fallback = GetPool((StarGrade)g);
            if (fallback.Count > 0)
                return fallback[UnityEngine.Random.Range(0, fallback.Count)];
        }
        // Last resort: any hero
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
