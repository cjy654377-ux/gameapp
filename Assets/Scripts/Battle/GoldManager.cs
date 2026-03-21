using UnityEngine;

public class GoldManager : MonoBehaviour
{
    public static GoldManager Instance { get; private set; }

    public int Gold { get; private set; }
    public event System.Action<int> OnGoldChanged;
    public event System.Action<float> OnBoostTimerChanged;

    private bool isDirty;
    private float saveTimer;
    private const float SAVE_INTERVAL = 5f;

    private float boostMultiplier = 1f;
    private float boostEndTime = 0f;
    private const float BOOST_DURATION_SECONDS = 1800f; // 30분

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        Gold = PlayerPrefs.GetInt(SaveKeys.Gold, 0);

        // Boost 타이머 복구
        string boostTimeStr = PlayerPrefs.GetString(SaveKeys.GoldBoostEndTime, "0");
        if (double.TryParse(boostTimeStr, out double boostTime))
            boostEndTime = (float)boostTime;
    }

    public void AddGold(int amount)
    {
        // Boost 종료 시간 확인
        float now = (float)System.DateTime.UtcNow.Subtract(new System.DateTime(1970, 1, 1)).TotalSeconds;
        if (now >= boostEndTime)
        {
            boostMultiplier = 1f;
            boostEndTime = 0f;
        }
        else
        {
            boostMultiplier = 2f;
        }

        int finalAmount = Mathf.RoundToInt(amount * boostMultiplier);
        Gold += finalAmount;
        isDirty = true;
        OnGoldChanged?.Invoke(Gold);

        // 통계 기록
        if (GameStatsManager.Instance != null)
            GameStatsManager.Instance.AddGoldEarned(finalAmount);
    }

    public bool SpendGold(int amount)
    {
        if (Gold < amount) return false;
        Gold -= amount;
        isDirty = true;
        OnGoldChanged?.Invoke(Gold);
        return true;
    }

    void Update()
    {
        // Boost 타이머 업데이트
        if (boostEndTime > 0)
        {
            float now = (float)System.DateTime.UtcNow.Subtract(new System.DateTime(1970, 1, 1)).TotalSeconds;
            float remainingSeconds = Mathf.Max(0f, boostEndTime - now);
            if (remainingSeconds > 0)
            {
                OnBoostTimerChanged?.Invoke(remainingSeconds);
            }
            else
            {
                boostMultiplier = 1f;
                boostEndTime = 0f;
                PlayerPrefs.DeleteKey(SaveKeys.GoldBoostEndTime);
            }
        }

        if (!isDirty) return;
        saveTimer += Time.unscaledDeltaTime;
        if (saveTimer >= SAVE_INTERVAL)
        {
            FlushSave();
        }
    }

    void FlushSave()
    {
        if (!isDirty) return;
        PlayerPrefs.SetInt(SaveKeys.Gold, Gold);
        PlayerPrefs.Save();
        isDirty = false;
        saveTimer = 0f;
    }

    void OnApplicationPause(bool pause)
    {
        if (pause) FlushSave();
    }

    void OnApplicationQuit()
    {
        FlushSave();
    }

    public void RequestGoldBoostAd()
    {
        // 광고 시청 후 부스트 활성화
        if (AdManager.Instance != null)
        {
            AdManager.Instance.ShowRewardedAd(
                AdManager.AdRewardType.GoldBoost,
                () => ActivateBoost()
            );
        }
    }

    public void ActivateBoost()
    {
        float now = (float)System.DateTime.UtcNow.Subtract(new System.DateTime(1970, 1, 1)).TotalSeconds;
        boostEndTime = now + BOOST_DURATION_SECONDS;
        boostMultiplier = 2f;
        PlayerPrefs.SetString(SaveKeys.GoldBoostEndTime, boostEndTime.ToString("F0"));
        PlayerPrefs.Save();
        OnBoostTimerChanged?.Invoke(BOOST_DURATION_SECONDS);
    }

    public float GetBoostTimeRemaining()
    {
        if (boostEndTime <= 0) return 0f;
        float now = (float)System.DateTime.UtcNow.Subtract(new System.DateTime(1970, 1, 1)).TotalSeconds;
        return Mathf.Max(0f, boostEndTime - now);
    }

    public bool IsBoostActive => GetBoostTimeRemaining() > 0;

    void OnDestroy()
    {
        if (Instance == this)
        {
            FlushSave();
            Instance = null;
        }
    }
}
