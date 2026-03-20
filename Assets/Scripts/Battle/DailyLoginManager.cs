using UnityEngine;
using System;

/// <summary>
/// 일일 출석 체크 시스템 (28일 순환)
/// - 매일 1회 보상 수령
/// - 7일/14일/21일/28일 대보상
/// - 28일 후 리셋하여 순환
/// </summary>
public class DailyLoginManager : MonoBehaviour
{
    public static DailyLoginManager Instance { get; private set; }

    public int CurrentDay { get; private set; }
    public bool ClaimedToday { get; private set; }

    public event Action<int, DailyReward> OnRewardClaimed;

    const int CYCLE_DAYS = 28;
    const string KEY_DAY = "DailyLogin_Day";
    const string KEY_LAST_DATE = "DailyLogin_LastDate";

    [Serializable]
    public struct DailyReward
    {
        public RewardType type;
        public int amount;
    }

    public enum RewardType { Gold, Gem, GachaTikcet }

    // 28일 보상 테이블
    static readonly DailyReward[] REWARDS = new DailyReward[CYCLE_DAYS]
    {
        // Week 1
        new() { type = RewardType.Gold, amount = 100 },
        new() { type = RewardType.Gold, amount = 100 },
        new() { type = RewardType.Gem, amount = 10 },
        new() { type = RewardType.Gold, amount = 150 },
        new() { type = RewardType.Gold, amount = 150 },
        new() { type = RewardType.Gem, amount = 15 },
        new() { type = RewardType.Gem, amount = 30 },  // 7일 대보상

        // Week 2
        new() { type = RewardType.Gold, amount = 200 },
        new() { type = RewardType.Gold, amount = 200 },
        new() { type = RewardType.Gem, amount = 15 },
        new() { type = RewardType.Gold, amount = 250 },
        new() { type = RewardType.Gold, amount = 250 },
        new() { type = RewardType.Gem, amount = 20 },
        new() { type = RewardType.Gem, amount = 50 },  // 14일 대보상

        // Week 3
        new() { type = RewardType.Gold, amount = 300 },
        new() { type = RewardType.Gold, amount = 300 },
        new() { type = RewardType.Gem, amount = 20 },
        new() { type = RewardType.Gold, amount = 350 },
        new() { type = RewardType.Gold, amount = 350 },
        new() { type = RewardType.Gem, amount = 25 },
        new() { type = RewardType.Gem, amount = 70 },  // 21일 대보상

        // Week 4
        new() { type = RewardType.Gold, amount = 400 },
        new() { type = RewardType.Gold, amount = 400 },
        new() { type = RewardType.Gem, amount = 25 },
        new() { type = RewardType.Gold, amount = 500 },
        new() { type = RewardType.Gold, amount = 500 },
        new() { type = RewardType.Gem, amount = 30 },
        new() { type = RewardType.Gem, amount = 100 }, // 28일 대보상
    };

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        LoadState();
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }

    void LoadState()
    {
        CurrentDay = PlayerPrefs.GetInt(KEY_DAY, 0);
        string lastDate = PlayerPrefs.GetString(KEY_LAST_DATE, "");
        string today = DateTime.UtcNow.ToString("yyyy-MM-dd");

        if (lastDate == today)
        {
            ClaimedToday = true;
        }
        else
        {
            ClaimedToday = false;
            // 날짜가 바뀌었으면 다음날로 진행 (첫 로그인 포함)
            if (!string.IsNullOrEmpty(lastDate))
            {
                // 하루 이상 건너뛴 경우에도 1일만 진행 (연속 출석 보너스 없으므로)
                CurrentDay++;
                if (CurrentDay >= CYCLE_DAYS)
                    CurrentDay = 0; // 순환
                PlayerPrefs.SetInt(KEY_DAY, CurrentDay);
            }
        }
    }

    public DailyReward GetTodayReward()
    {
        int idx = Mathf.Clamp(CurrentDay, 0, CYCLE_DAYS - 1);
        return REWARDS[idx];
    }

    public DailyReward GetRewardForDay(int day)
    {
        int idx = Mathf.Clamp(day, 0, CYCLE_DAYS - 1);
        return REWARDS[idx];
    }

    public bool ClaimReward()
    {
        if (ClaimedToday) return false;

        var reward = GetTodayReward();
        switch (reward.type)
        {
            case RewardType.Gold:
                GoldManager.Instance?.AddGold(reward.amount);
                break;
            case RewardType.Gem:
                GemManager.Instance?.AddGem(reward.amount);
                break;
            case RewardType.GachaTikcet:
                GemManager.Instance?.AddGem(GachaManager.SINGLE_PULL_COST);
                break;
        }

        ClaimedToday = true;
        string today = DateTime.UtcNow.ToString("yyyy-MM-dd");
        PlayerPrefs.SetString(KEY_LAST_DATE, today);
        PlayerPrefs.SetInt(KEY_DAY, CurrentDay);
        PlayerPrefs.Save();

        SoundManager.Instance?.PlayLevelUpSFX();
        OnRewardClaimed?.Invoke(CurrentDay, reward);
        return true;
    }

    /// <summary>
    /// 출석 팝업 표시 필요 여부
    /// </summary>
    public bool ShouldShowPopup()
    {
        return !ClaimedToday;
    }
}
