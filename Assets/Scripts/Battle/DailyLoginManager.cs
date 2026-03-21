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
    public event Action<int, DailyReward> OnDailyLoginMultiplierRequested; // 일일 로그인 2배 광고 요청 (day, reward)

    private DailyReward _lastClaimedReward;
    private bool _dailyLoginMultiplierUsed;

    const int CYCLE_DAYS = 28;
    const string KEY_DAY       = "DailyLogin_Day";
    const string KEY_LAST_DATE = "DailyLogin_LastDate";
    const string DATE_FORMAT   = "yyyy-MM-dd";

    [Serializable]
    public struct DailyReward
    {
        public RewardType type;
        public int amount;
    }

    public enum RewardType { Gold, Gem, GachaTicket, SummonStone, AwakeningStone, Star4HeroTicket }

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
        string today = DateTime.UtcNow.ToString(DATE_FORMAT);

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
        int dayNum = CurrentDay + 1; // 1-indexed

        // 마일스톤 특별 보상 (7일, 14일, 30일)
        if (dayNum == 7)
        {
            // 7일: 보석 100
            GemManager.Instance?.AddGem(100);
        }
        else if (dayNum == 14)
        {
            // 14일: 소환석 10 + 각성석 5
            SummonStoneManager.Instance?.AddStone(10);
            AwakeningStoneManager.Instance?.AddStone(5);
        }
        else if (dayNum == 30)
        {
            // 30일: Star4 영웅 보장 티켓 (따로 처리 필요)
            // 현재 구현: 보석 추가 대신 별도의 티켓 시스템 필요
            GemManager.Instance?.AddGem(500); // 임시: 고급 보석 보상
            // TODO: Star4 영웅 보장 시스템 구현 필요
        }
        else
        {
            // 일반 보상
            switch (reward.type)
            {
                case RewardType.Gold:
                    GoldManager.Instance?.AddGold(reward.amount);
                    break;
                case RewardType.Gem:
                    GemManager.Instance?.AddGem(reward.amount);
                    break;
                case RewardType.GachaTicket:
                    GemManager.Instance?.AddGem(GachaManager.SINGLE_PULL_COST);
                    break;
                case RewardType.SummonStone:
                    SummonStoneManager.Instance?.AddStone(reward.amount);
                    break;
                case RewardType.AwakeningStone:
                    AwakeningStoneManager.Instance?.AddStone(reward.amount);
                    break;
            }
        }

        ClaimedToday = true;
        string today = DateTime.UtcNow.ToString(DATE_FORMAT);
        PlayerPrefs.SetString(KEY_LAST_DATE, today);
        PlayerPrefs.SetInt(KEY_DAY, CurrentDay);
        PlayerPrefs.Save();

        SoundManager.Instance?.PlayLevelUpSFX();
        OnRewardClaimed?.Invoke(CurrentDay, reward);

        // 2배 보상 광고 제시
        _lastClaimedReward = reward;
        _dailyLoginMultiplierUsed = false;
        OnDailyLoginMultiplierRequested?.Invoke(CurrentDay, reward);

        return true;
    }

    /// <summary>
    /// 출석 팝업 표시 필요 여부
    /// </summary>
    public bool ShouldShowPopup()
    {
        return !ClaimedToday;
    }

    /// <summary>
    /// 광고로 일일 로그인 보상 2배 지급 (1회 제한)
    /// </summary>
    public void GrantDailyLoginRewardMultiplier()
    {
        if (_dailyLoginMultiplierUsed) return;

        int dayNum = CurrentDay + 1; // 1-indexed

        // 마일스톤은 2배 광고 미지원
        if (dayNum == 7 || dayNum == 14 || dayNum == 30) return;

        switch (_lastClaimedReward.type)
        {
            case RewardType.Gold:
                GoldManager.Instance?.AddGold(_lastClaimedReward.amount);
                break;
            case RewardType.Gem:
                GemManager.Instance?.AddGem(_lastClaimedReward.amount);
                break;
            case RewardType.GachaTicket:
                GemManager.Instance?.AddGem(GachaManager.SINGLE_PULL_COST);
                break;
            case RewardType.SummonStone:
                SummonStoneManager.Instance?.AddStone(_lastClaimedReward.amount);
                break;
            case RewardType.AwakeningStone:
                AwakeningStoneManager.Instance?.AddStone(_lastClaimedReward.amount);
                break;
        }

        _dailyLoginMultiplierUsed = true;
    }
}
