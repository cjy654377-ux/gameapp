using UnityEngine;

public class OfflineRewardManager : MonoBehaviour
{
    public static OfflineRewardManager Instance { get; private set; }

    private const int GOLD_PER_MINUTE = 10;
    private const int EXP_PER_MINUTE = 2;
    private const int GEM_INTERVAL_MINUTES = 10;
    private const int MAX_OFFLINE_MINUTES = 480;
    private const int COPY_INTERVAL_MINUTES = 60;    // 60분마다 영웅 카드 1장
    private const int FRAGMENT_INTERVAL_MINUTES = 30; // 30분마다 장비 조각 1개
    public const string SAVE_KEY_FRAGMENTS = "EquipFragments";

    /// <summary>
    /// gold, gem, exp, fragments, offlineMinutes
    /// </summary>
    public event System.Action<int, int, int, int, float> OnOfflineReward;
    public event System.Action<int, int> OnDoubleRewardAd;

    const float MIN_REWARD_MINUTES = 1f;

    private int lastGoldReward = 0;
    private int lastGemReward = 0;
    private int lastExpReward = 0;
    public int LastCopiesReward { get; private set; }
    public int LastFragmentsReward { get; private set; }

    public static int EquipFragments
    {
        get => PlayerPrefs.GetInt(SAVE_KEY_FRAGMENTS, 0);
        set => PlayerPrefs.SetInt(SAVE_KEY_FRAGMENTS, Mathf.Max(0, value));
    }

    void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(gameObject);
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
        SaveCurrentTime();
    }

    void Start()
    {
        StartCoroutine(DeferredCalculate());
    }

    System.Collections.IEnumerator DeferredCalculate()
    {
        // 2프레임 대기: MainHUD 등 UI가 DeferredSubscribe(1프레임)로 구독한 뒤 이벤트 발생
        yield return null;
        yield return null;
        CalculateOfflineReward();
    }

    void CalculateOfflineReward()
    {
        if (!PlayerPrefs.HasKey(SaveKeys.LastPlayTime))
        {
            SaveCurrentTime();
            return;
        }

        if (!long.TryParse(PlayerPrefs.GetString(SaveKeys.LastPlayTime, "0"), out long lastTime))
            lastTime = 0;
        long now = GetUnixTimestamp();
        float elapsedSeconds = Mathf.Max(0f, now - lastTime);
        float elapsedMinutes = elapsedSeconds / 60f;

        if (elapsedMinutes < MIN_REWARD_MINUTES)
        {
            SaveCurrentTime();
            return;
        }

        float cappedMinutes = Mathf.Min(elapsedMinutes, MAX_OFFLINE_MINUTES);
        int minutesInt = Mathf.FloorToInt(cappedMinutes);

        int goldReward = minutesInt * GOLD_PER_MINUTE;
        int expReward = minutesInt * EXP_PER_MINUTE;
        int gemReward = minutesInt / GEM_INTERVAL_MINUTES;
        int copyReward = minutesInt / COPY_INTERVAL_MINUTES;
        int fragmentReward = minutesInt / FRAGMENT_INTERVAL_MINUTES;

        lastGoldReward = goldReward;
        lastExpReward = expReward;
        lastGemReward = gemReward;
        LastCopiesReward = copyReward;
        LastFragmentsReward = fragmentReward;

        if (goldReward > 0 && GoldManager.Instance != null)
            GoldManager.Instance.AddGold(goldReward);

        if (gemReward > 0 && GemManager.Instance != null)
            GemManager.Instance.AddGem(gemReward);

        // 영웅 카드: 덱 영웅 중 랜덤에게 추가
        if (copyReward > 0)
            ApplyCopyRewards(copyReward);

        // 장비 조각: PlayerPrefs에 누적
        if (fragmentReward > 0)
            EquipFragments += fragmentReward;

        OnOfflineReward?.Invoke(goldReward, gemReward, expReward, fragmentReward, cappedMinutes);
        SaveCurrentTime();
    }

    void ApplyCopyRewards(int count)
    {
        var hlm = HeroLevelManager.Instance;
        var dm = DeckManager.Instance;
        if (hlm == null || dm == null) return;

        var activeDeck = dm.GetActiveDeck();
        if (activeDeck.Count == 0) return;

        for (int i = 0; i < count; i++)
        {
            var preset = activeDeck[Random.Range(0, activeDeck.Count)];
            if (preset != null)
                hlm.AddCopy(preset.characterName);
        }
    }

    void SaveCurrentTime()
    {
        PlayerPrefs.SetString(SaveKeys.LastPlayTime, GetUnixTimestamp().ToString());
    }

    public void RequestDoubleRewardAd()
    {
        // 광고 시청 후 보상
        if (AdManager.Instance != null)
        {
            AdManager.Instance.ShowRewardedAd(
                AdManager.AdRewardType.OfflineDouble,
                () => ApplyDoubleRewardAd()
            );
        }
    }

    public void ApplyDoubleRewardAd()
    {
        int doubleGold = lastGoldReward;
        int doubleGem = lastGemReward;

        if (doubleGold > 0 && GoldManager.Instance != null)
            GoldManager.Instance.AddGold(doubleGold);

        if (doubleGem > 0 && GemManager.Instance != null)
            GemManager.Instance.AddGem(doubleGem);

        OnDoubleRewardAd?.Invoke(doubleGold, doubleGem);
    }

    long GetUnixTimestamp()
    {
        return (long)(System.DateTime.UtcNow - new System.DateTime(1970, 1, 1)).TotalSeconds;
    }

    void OnApplicationPause(bool pause)
    {
        if (pause) SaveCurrentTime();
    }
}
