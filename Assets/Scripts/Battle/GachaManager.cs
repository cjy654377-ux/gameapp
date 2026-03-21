using UnityEngine;
using System;
using System.Collections.Generic;

/// <summary>
/// 보석으로 영웅 소환 (가챠)
/// - 단일 뽑기: 50보석
/// - 10연차: 450보석 (1회 할인)
/// - StarGrade 확률: 1성 60%, 2성 30%, 3성 9%, 4성 0.97%, 5성 0.03%
/// - 천장(pity): 200회 뽑기 보장 4성
/// </summary>
public class GachaManager : MonoBehaviour
{
    public static GachaManager Instance { get; private set; }

    public const int SINGLE_PULL_COST   = 50;
    public const int MULTI_PULL_COST    = 450;  // 10연차 (1회 무료)
    public const int MULTI_PULL_COUNT   = 10;
    public const int HUNDRED_PULL_COST  = 4000; // 100연차 (4500→4000, 할인)
    public const int HUNDRED_PULL_COUNT = 100;
    public const int PITY_THRESHOLD = 200;
    private const float FREE_PULL_COOLDOWN_HOURS = 4f;

    // 가챠 확률 (누적, 0~100 롤 기준)
    const float PROB_STAR5     = 0.03f;
    const float PROB_STAR4_CUM = 1f;    // 0.03 + 0.97
    const float PROB_STAR3_CUM = 10f;   // 1 + 9
    const float PROB_STAR2_CUM = 40f;   // 10 + 30

    [Header("Hero Pool")]
    [SerializeField] CharacterPreset[] allHeroes;

    public event Action<CharacterPreset> OnHeroPulled;
    public event Action<CharacterPreset[]> OnMultiPulled;
    public event Action<CharacterPreset> OnDuplicatePulled; // 중복 소환 시 발생 → 각성 재료 전환 연출용
    public event Action<CharacterPreset> OnFreePulled; // 광고 무료 소환
    public event Action<int> OnPityCounterChanged; // 천장 카운터 변경

    // StarGrade tiers sorted from pool
    readonly List<CharacterPreset> star1Pool = new();
    readonly List<CharacterPreset> star2Pool = new();
    readonly List<CharacterPreset> star3Pool = new();
    readonly List<CharacterPreset> star4Pool = new();
    readonly List<CharacterPreset> star5Pool = new();

    private int pityCounter = 0;
    private bool _isFirstPull;
    private bool _isFirstMultiPull;

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
        LoadPityCounter();
        _isFirstPull      = PlayerPrefs.GetInt(SaveKeys.FirstPullDone, 0) == 0;
        _isFirstMultiPull = PlayerPrefs.GetInt(SaveKeys.FirstMultiPullDone, 0) == 0;
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

    void LoadPityCounter()
    {
        pityCounter = PlayerPrefs.GetInt(SaveKeys.PityCounter, 0);
        OnPityCounterChanged?.Invoke(pityCounter);
    }

    void SavePityCounter()
    {
        PlayerPrefs.SetInt(SaveKeys.PityCounter, pityCounter);
        PlayerPrefs.Save();
    }

    void IncrementPityCounter()
    {
        pityCounter++;
        SavePityCounter();
        OnPityCounterChanged?.Invoke(pityCounter);
    }

    void ResetPityCounter()
    {
        pityCounter = 0;
        SavePityCounter();
        OnPityCounterChanged?.Invoke(pityCounter);
    }

    public int PityCounter => pityCounter;
    public int PityRemaining => Mathf.Max(0, PITY_THRESHOLD - pityCounter);

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

        CharacterPreset hero;
        if (_isFirstPull)
        {
            hero = PullGuaranteed(StarGrade.Star3);
            _isFirstPull = false;
            PlayerPrefs.SetInt(SaveKeys.FirstPullDone, 1);
            PlayerPrefs.Save();
        }
        else
        {
            hero = PullOne();
        }
        HandlePullResult(hero);
        IncrementPityCounter();
        SoundManager.Instance?.PlayGachaSFX();
        OnHeroPulled?.Invoke(hero);
        DailyMissionManager.Instance?.RegisterGacha();
        return hero;
    }

    /// <summary>
    /// 무료 소환 (광고 시청) - 비용 없음, 4시간 쿨타임
    /// </summary>
    public CharacterPreset FreeSinglePull()
    {
        if (allHeroes.Length == 0)
        {
            Debug.LogWarning("[GachaManager] Hero pool is empty!");
            return null;
        }

        if (!CanFreePull())
        {
            Debug.Log("[GachaManager] Free pull cooldown not ready.");
            return null;
        }

        var hero = PullOne();
        HandlePullResult(hero);
        IncrementPityCounter();
        SoundManager.Instance?.PlayGachaSFX();
        OnFreePulled?.Invoke(hero);
        DailyMissionManager.Instance?.RegisterGacha();

        // 쿨타임 갱신
        UpdateFreePullCooldown();
        return hero;
    }

    /// <summary>
    /// 무료 소환 가능 여부
    /// </summary>
    public bool CanFreePull()
    {
        string lastTimeStr = PlayerPrefs.GetString(SaveKeys.FreeGachaLastTime, "0");
        if (!double.TryParse(lastTimeStr, out double lastTime))
            return true; // 기록 없으면 가능

        double now = System.DateTime.UtcNow.Subtract(new System.DateTime(1970, 1, 1)).TotalSeconds;
        double elapsedHours = (now - lastTime) / 3600.0;
        return elapsedHours >= FREE_PULL_COOLDOWN_HOURS;
    }

    /// <summary>
    /// 무료 소환 쿨타임 갱신
    /// </summary>
    void UpdateFreePullCooldown()
    {
        double now = System.DateTime.UtcNow.Subtract(new System.DateTime(1970, 1, 1)).TotalSeconds;
        PlayerPrefs.SetString(SaveKeys.FreeGachaLastTime, now.ToString("F0"));
        PlayerPrefs.Save();
    }

    /// <summary>
    /// 무료 소환 남은 시간 (초)
    /// </summary>
    public float GetFreePullCooldownRemaining()
    {
        string lastTimeStr = PlayerPrefs.GetString(SaveKeys.FreeGachaLastTime, "0");
        if (!double.TryParse(lastTimeStr, out double lastTime))
            return 0f;

        double now = System.DateTime.UtcNow.Subtract(new System.DateTime(1970, 1, 1)).TotalSeconds;
        double elapsedSeconds = now - lastTime;
        double cooldownSeconds = FREE_PULL_COOLDOWN_HOURS * 3600.0;
        return Mathf.Max(0f, (float)(cooldownSeconds - elapsedSeconds));
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

        var results = new CharacterPreset[MULTI_PULL_COUNT];
        for (int i = 0; i < MULTI_PULL_COUNT; i++)
        {
            results[i] = PullOne();
            IncrementPityCounter();
        }

        // 첫 10연차: 최소 1개 Star3 보장
        if (_isFirstMultiPull)
        {
            bool hasStar3Plus = false;
            for (int i = 0; i < MULTI_PULL_COUNT; i++)
                if (results[i] != null && results[i].starGrade >= StarGrade.Star3) { hasStar3Plus = true; break; }
            if (!hasStar3Plus)
                results[UnityEngine.Random.Range(0, MULTI_PULL_COUNT)] = PullGuaranteed(StarGrade.Star3);
            _isFirstMultiPull = false;
            PlayerPrefs.SetInt(SaveKeys.FirstMultiPullDone, 1);
            PlayerPrefs.Save();
        }

        // 결과 처리 (중복/신규)
        for (int i = 0; i < MULTI_PULL_COUNT; i++)
            HandlePullResult(results[i]);

        SoundManager.Instance?.PlayGachaSFX();
        OnMultiPulled?.Invoke(results);
        DailyMissionManager.Instance?.RegisterGacha();
        return results;
    }

    /// <summary>
    /// 100연차 (4000보석, 4500→4000 할인)
    /// </summary>
    public CharacterPreset[] HundredPull()
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

        if (!GemManager.Instance.SpendGem(HUNDRED_PULL_COST))
        {
            Debug.Log("[GachaManager] Not enough gems for hundred pull.");
            return null;
        }

        var results = new CharacterPreset[HUNDRED_PULL_COUNT];
        for (int i = 0; i < HUNDRED_PULL_COUNT; i++)
        {
            results[i] = PullOne();
            IncrementPityCounter();
        }

        for (int i = 0; i < HUNDRED_PULL_COUNT; i++)
            HandlePullResult(results[i]);

        SoundManager.Instance?.PlayGachaSFX();
        OnMultiPulled?.Invoke(results);
        DailyMissionManager.Instance?.RegisterGacha();
        return results;
    }

    /// <summary>
    /// 특정 등급 이상 보장 뽑기 (보장 풀 비어있으면 폴백)
    /// </summary>
    CharacterPreset PullGuaranteed(StarGrade minGrade)
    {
        var pool = GetPool(minGrade);
        if (pool.Count > 0)
            return pool[UnityEngine.Random.Range(0, pool.Count)];
        // 폴백: 낮은 등급
        for (int g = (int)minGrade - 1; g >= 1; g--)
        {
            var fallback = GetPool((StarGrade)g);
            if (fallback.Count > 0)
                return fallback[UnityEngine.Random.Range(0, fallback.Count)];
        }
        return allHeroes[UnityEngine.Random.Range(0, allHeroes.Length)];
    }

    /// <summary>
    /// StarGrade 가중치 뽑기
    /// 1성 60%, 2성 30%, 3성 9%, 4성 0.97%, 5성 0.03%
    /// 천장: 200회 도달 시 강제 4성
    /// </summary>
    CharacterPreset PullOne()
    {
        if (allHeroes.Length == 0) return null;

        // 천장 도달 시 강제 4성
        if (pityCounter >= PITY_THRESHOLD)
        {
            var star4 = GetPool(StarGrade.Star4);
            if (star4.Count > 0)
                return star4[UnityEngine.Random.Range(0, star4.Count)];
        }

        float roll = UnityEngine.Random.Range(0f, 100f);

        StarGrade selectedGrade;
        if (roll < PROB_STAR5)
            selectedGrade = StarGrade.Star5;
        else if (roll < PROB_STAR4_CUM)
            selectedGrade = StarGrade.Star4;
        else if (roll < PROB_STAR3_CUM)
            selectedGrade = StarGrade.Star3;
        else if (roll < PROB_STAR2_CUM)
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
    /// 4성 이상 획득 시 천장 카운터 리셋
    /// </summary>
    void HandlePullResult(CharacterPreset hero)
    {
        if (hero == null) return;

        // 4성 이상 획득 시 천장 카운터 리셋
        if (hero.starGrade >= StarGrade.Star4)
            ResetPityCounter();

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
            OnDuplicatePulled?.Invoke(hero);
        }
        else
        {
            // 신규 영웅: roster에 추가
            deck.roster.Add(hero);
        }
    }
}
