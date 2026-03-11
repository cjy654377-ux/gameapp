using UnityEngine;

public class OfflineRewardManager : MonoBehaviour
{
    public static OfflineRewardManager Instance { get; private set; }

    private const int GOLD_PER_MINUTE = 10;
    private const int GEM_INTERVAL_MINUTES = 10;
    private const int MAX_OFFLINE_MINUTES = 480;

    /// <summary>
    /// gold, gem, offlineMinutes
    /// </summary>
    public event System.Action<int, int, float> OnOfflineReward;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(gameObject);
    }

    void Start()
    {
        CalculateOfflineReward();
    }

    void CalculateOfflineReward()
    {
        if (!PlayerPrefs.HasKey("LastPlayTime"))
        {
            SaveCurrentTime();
            return;
        }

        if (!long.TryParse(PlayerPrefs.GetString("LastPlayTime", "0"), out long lastTime))
            lastTime = 0;
        long now = GetUnixTimestamp();
        float elapsedSeconds = Mathf.Max(0f, now - lastTime);
        float elapsedMinutes = elapsedSeconds / 60f;

        if (elapsedMinutes < 1f)
        {
            SaveCurrentTime();
            return;
        }

        float cappedMinutes = Mathf.Min(elapsedMinutes, MAX_OFFLINE_MINUTES);
        int minutesInt = Mathf.FloorToInt(cappedMinutes);

        int goldReward = minutesInt * GOLD_PER_MINUTE;
        int gemReward = minutesInt / GEM_INTERVAL_MINUTES;

        if (goldReward > 0 && GoldManager.Instance != null)
            GoldManager.Instance.AddGold(goldReward);

        if (gemReward > 0 && GemManager.Instance != null)
            GemManager.Instance.AddGem(gemReward);

        OnOfflineReward?.Invoke(goldReward, gemReward, cappedMinutes);
        SaveCurrentTime();
    }

    void SaveCurrentTime()
    {
        PlayerPrefs.SetString("LastPlayTime", GetUnixTimestamp().ToString());
    }

    long GetUnixTimestamp()
    {
        return (long)(System.DateTime.UtcNow - new System.DateTime(1970, 1, 1)).TotalSeconds;
    }

    void OnApplicationPause(bool pause)
    {
        if (pause) SaveCurrentTime();
    }

    void OnDestroy()
    {
        SaveCurrentTime();
    }
}
