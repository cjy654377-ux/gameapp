using UnityEngine;

/// <summary>
/// 비동기 PvP 아레나: AI 상대 덱과 대전, 포인트 기반 랭킹
/// 서버 없이 로컬에서 가상 상대 생성
/// </summary>
public class ArenaManager : MonoBehaviour
{
    public static ArenaManager Instance { get; private set; }

    public int ArenaPoints { get; private set; }
    public int ArenaRank => GetRank();
    public int WinStreak { get; private set; }

    public event System.Action<int> OnPointsChanged;
    public event System.Action<bool> OnBattleResult; // true = win

    const int WIN_POINTS = 30;
    const int LOSE_POINTS = -15;
    const int STREAK_BONUS = 5;
    const int DAILY_ATTEMPTS = 10;

    // 명성 지급
    const int WIN_REPUTATION = 10;
    const int STREAK_REP_BONUS = 3;

    int attemptsToday;
    string lastResetDate;

    // 가상 상대 프리셋 (난이도별)
    static readonly string[][] OPPONENT_DECKS = new[]
    {
        new[] { "검사", "궁수", "마법사" },                           // Easy
        new[] { "검사", "궁수", "마법사", "기사" },                    // Normal
        new[] { "검사", "궁수", "마법사", "기사", "창병" },             // Hard
        new[] { "검사", "궁수", "마법사", "기사", "창병", "힐러" },      // Expert
        new[] { "검사", "궁수", "마법사", "기사", "창병", "힐러", "음유시인" }, // Master
    };

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        ArenaPoints = PlayerPrefs.GetInt(SaveKeys.ArenaPoints, 0);
        WinStreak = PlayerPrefs.GetInt(SaveKeys.ArenaWinStreak, 0);
        attemptsToday = PlayerPrefs.GetInt(SaveKeys.ArenaAttempts, 0);
        lastResetDate = PlayerPrefs.GetString(SaveKeys.ArenaLastReset, "");
        CheckDailyReset();
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }

    void CheckDailyReset()
    {
        string today = System.DateTime.UtcNow.ToString("yyyy-MM-dd");
        if (lastResetDate != today)
        {
            attemptsToday = 0;
            lastResetDate = today;
            PlayerPrefs.SetString(SaveKeys.ArenaLastReset, today);
            PlayerPrefs.SetInt(SaveKeys.ArenaAttempts, 0);
        }
    }

    public int RemainingAttempts => Mathf.Max(0, DAILY_ATTEMPTS - attemptsToday);

    public bool CanBattle => RemainingAttempts > 0;

    /// <summary>
    /// 현재 포인트 기반 난이도 (0~4)
    /// </summary>
    public int GetDifficulty()
    {
        if (ArenaPoints < 100) return 0;
        if (ArenaPoints < 300) return 1;
        if (ArenaPoints < 600) return 2;
        if (ArenaPoints < 1000) return 3;
        return 4;
    }

    /// <summary>
    /// 상대 덱의 영웅 이름 목록
    /// </summary>
    public string[] GetOpponentDeck()
    {
        int diff = GetDifficulty();
        return OPPONENT_DECKS[Mathf.Clamp(diff, 0, OPPONENT_DECKS.Length - 1)];
    }

    /// <summary>
    /// 상대 스탯 배율 (난이도에 따라 증가)
    /// </summary>
    public float GetOpponentStatScale()
    {
        return 1f + GetDifficulty() * 0.2f + ArenaPoints * 0.001f;
    }

    /// <summary>
    /// 전투 결과 처리 (BattleManager에서 호출)
    /// </summary>
    public void ReportResult(bool won)
    {
        attemptsToday++;
        PlayerPrefs.SetInt(SaveKeys.ArenaAttempts, attemptsToday);

        if (won)
        {
            int points = WIN_POINTS + WinStreak * STREAK_BONUS;
            ArenaPoints += points;
            WinStreak++;

            int rep = WIN_REPUTATION + WinStreak * STREAK_REP_BONUS;
            ReputationManager.Instance?.AddReputation(rep);

            ToastNotification.Instance?.Show("아레나 승리!", $"+{points}P  명성 +{rep}", UIColors.Text_Gold);
        }
        else
        {
            ArenaPoints = Mathf.Max(0, ArenaPoints + LOSE_POINTS);
            WinStreak = 0;
            ToastNotification.Instance?.Show("아레나 패배", $"{LOSE_POINTS}P", UIColors.Defeat_Red);
        }

        PlayerPrefs.SetInt(SaveKeys.ArenaPoints, ArenaPoints);
        PlayerPrefs.SetInt(SaveKeys.ArenaWinStreak, WinStreak);

        OnPointsChanged?.Invoke(ArenaPoints);
        OnBattleResult?.Invoke(won);

        // 랭크업 보상
        CheckRankReward();
    }

    int GetRank()
    {
        if (ArenaPoints >= 1500) return 1;  // 챔피언
        if (ArenaPoints >= 1000) return 2;  // 다이아몬드
        if (ArenaPoints >= 600) return 3;   // 골드
        if (ArenaPoints >= 300) return 4;   // 실버
        return 5;                            // 브론즈
    }

    public string GetRankName()
    {
        return ArenaRank switch
        {
            1 => "챔피언",
            2 => "다이아몬드",
            3 => "골드",
            4 => "실버",
            _ => "브론즈"
        };
    }

    public Color GetRankColor()
    {
        return ArenaRank switch
        {
            1 => new Color(1f, 0.2f, 0.2f),      // 챔피언 레드
            2 => new Color(0.7f, 0.85f, 1f),     // 다이아
            3 => new Color(1f, 0.84f, 0f),       // 골드
            4 => new Color(0.75f, 0.75f, 0.75f), // 실버
            _ => new Color(0.8f, 0.5f, 0.2f)     // 브론즈
        };
    }

    void CheckRankReward()
    {
        int rank = ArenaRank;
        string key = SaveKeys.ArenaRankRewardPrefix + rank;
        if (PlayerPrefs.GetInt(key, 0) == 1) return;

        int[] gemRewards = { 0, 200, 100, 50, 30, 10 };
        int gems = rank < gemRewards.Length ? gemRewards[rank] : 0;
        if (gems <= 0) return;

        PlayerPrefs.SetInt(key, 1);
        GemManager.Instance?.AddGem(gems);
        ToastNotification.Instance?.Show($"랭크업! {GetRankName()}", $"+{gems} 보석", GetRankColor());
    }
}
