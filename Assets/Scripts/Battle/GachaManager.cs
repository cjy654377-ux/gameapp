using UnityEngine;
using System;
using System.Collections.Generic;

/// <summary>
/// 보석으로 영웅 소환 (가챠)
/// - 단일 뽑기: 50보석
/// - 10연차: 450보석 (1회 할인)
/// - 중복 영웅 소환 시 경험치 보상 (HeroLevelManager 연동 예정)
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
    }

    /// <summary>
    /// 외부에서 영웅 풀 설정 (Inspector 또는 런타임)
    /// </summary>
    public void SetHeroPool(CharacterPreset[] heroes)
    {
        allHeroes = heroes ?? Array.Empty<CharacterPreset>();
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
        OnHeroPulled?.Invoke(hero);
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
        {
            results[i] = PullOne();
            HandlePullResult(results[i]);
        }

        OnMultiPulled?.Invoke(results);
        return results;
    }

    /// <summary>
    /// 균등 확률로 1명 뽑기 (rarity 미구현, 추후 확률 테이블 추가)
    /// </summary>
    CharacterPreset PullOne()
    {
        int index = UnityEngine.Random.Range(0, allHeroes.Length);
        return allHeroes[index];
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
            Debug.Log($"[GachaManager] New hero acquired: {hero.characterName}");
        }
    }
}
