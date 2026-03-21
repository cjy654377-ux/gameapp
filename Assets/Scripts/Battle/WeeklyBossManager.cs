using UnityEngine;

/// <summary>
/// 주간 보스 시스템. 매주 월요일(UTC) 리셋.
/// 1회 도전 가능. 승리 시 각성석 + 보석 대량 보상.
/// 전투력 기반 승률 계산 (시뮬레이션).
/// </summary>
public class WeeklyBossManager : MonoBehaviour
{
    public static WeeklyBossManager Instance { get; private set; }

    // 보스 스탯 (웨이브 진행에 따라 증가)
    const int BASE_BOSS_HP  = 5000;
    const int BOSS_HP_SCALE = 200;  // 웨이브당 HP 증가

    public bool CanAttempt  => !attempted;
    public bool IsDefeated  => defeated;

    bool attempted;
    bool defeated;

    public event System.Action OnStateChanged;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        LoadState();
        EnsureWeeklyReset();
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }

    // ─────────────────────────────────────────────
    // 퍼블릭 API
    // ─────────────────────────────────────────────

    /// <summary>
    /// 보스 도전. 승률은 플레이어 전투력 기반 계산.
    /// 승리 시 true 반환 + 보상 지급.
    /// </summary>
    public bool AttemptBoss()
    {
        if (!CanAttempt) return false;

        attempted = true;

        float myPower = CalculatePlayerPower();
        int wave = StageManager.Instance != null ? StageManager.Instance.TotalWaveIndex : 1;
        float bossHp = BASE_BOSS_HP + wave * BOSS_HP_SCALE;
        float winChance = Mathf.Clamp01(myPower / (myPower + bossHp * 0.5f + 0.01f));
        bool win = Random.value < winChance;

        if (win)
        {
            defeated = true;
            GiveRewards(wave);
        }

        SaveState();
        OnStateChanged?.Invoke();
        return win;
    }

    public string GetBossName()
    {
        int wave = StageManager.Instance != null ? StageManager.Instance.TotalWaveIndex : 1;
        if (wave < 30)  return "어둠의 군주 오르카스";
        if (wave < 60)  return "불꽃 마왕 이그니스";
        if (wave < 100) return "공허의 지배자 볼드";
        return "차원 파괴자 나이아르";
    }

    public int GetBossHP()
    {
        int wave = StageManager.Instance != null ? StageManager.Instance.TotalWaveIndex : 1;
        return BASE_BOSS_HP + wave * BOSS_HP_SCALE;
    }

    public (int awakeStone, int gem) GetRewardPreview()
    {
        int wave = StageManager.Instance != null ? StageManager.Instance.TotalWaveIndex : 1;
        int awakeStone = 10 + wave / 10;
        int gem = 30 + wave / 5;
        return (awakeStone, gem);
    }

    // ─────────────────────────────────────────────
    // 내부 헬퍼
    // ─────────────────────────────────────────────

    float CalculatePlayerPower()
    {
        float power = 0f;
        var dm  = DeckManager.Instance;
        var hlm = HeroLevelManager.Instance;
        var um  = UpgradeManager.Instance;

        if (dm != null)
        {
            var deck = dm.GetActiveDeck();
            for (int i = 0; i < deck.Count; i++)
            {
                float hp  = deck[i].maxHp;
                float atk = deck[i].atk;
                if (hlm != null)
                {
                    hp  += hlm.GetHpBonus(deck[i].characterName);
                    atk += hlm.GetAtkBonus(deck[i].characterName);
                }
                power += hp + atk * 5f;
            }
        }
        if (um != null)
            power *= (1f + um.HpLevel * 0.05f + um.AtkLevel * 0.05f);

        return Mathf.Max(power, 100f);
    }

    void GiveRewards(int wave)
    {
        int awakeStone = 10 + wave / 10;
        int gem        = 30 + wave / 5;

        AwakeningStoneManager.Instance?.AddStone(awakeStone);
        GemManager.Instance?.AddGem(gem);

        ToastNotification.Instance?.Show(
            "주간 보스 격파!",
            $"각성석 +{awakeStone}  보석 +{gem}",
            UIColors.Text_Gold);
    }

    // ─────────────────────────────────────────────
    // 주간 리셋 (매주 월요일 UTC)
    // ─────────────────────────────────────────────

    void EnsureWeeklyReset()
    {
        string currentWeek = GetWeekKey();
        string savedWeek   = PlayerPrefs.GetString(SaveKeys.WeeklyBossWeek, "");
        if (savedWeek == currentWeek) return;

        attempted = false;
        defeated  = false;
        PlayerPrefs.SetString(SaveKeys.WeeklyBossWeek, currentWeek);
        SaveState();
    }

    static string GetWeekKey()
    {
        var now = System.DateTime.UtcNow;
        // ISO 8601 주 번호
        var cal = System.Globalization.CultureInfo.InvariantCulture.Calendar;
        int week = cal.GetWeekOfYear(now,
            System.Globalization.CalendarWeekRule.FirstFourDayWeek,
            System.DayOfWeek.Monday);
        return $"{now.Year}_W{week}";
    }

    // ─────────────────────────────────────────────
    // 저장 / 불러오기
    // ─────────────────────────────────────────────

    void SaveState()
    {
        PlayerPrefs.SetInt(SaveKeys.WeeklyBossAttempt,  attempted ? 1 : 0);
        PlayerPrefs.SetInt(SaveKeys.WeeklyBossDefeated, defeated  ? 1 : 0);
        PlayerPrefs.Save();
    }

    void LoadState()
    {
        attempted = PlayerPrefs.GetInt(SaveKeys.WeeklyBossAttempt,  0) == 1;
        defeated  = PlayerPrefs.GetInt(SaveKeys.WeeklyBossDefeated, 0) == 1;
    }
}
