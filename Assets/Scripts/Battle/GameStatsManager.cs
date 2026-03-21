using UnityEngine;
using System;

/// <summary>
/// 게임 통계 추적 싱글톤
/// - 총 처치 수
/// - 총 획득 골드
/// - 최고 웨이브
/// - 총 플레이 시간
/// - 총 뽑기 횟수
/// </summary>
public class GameStatsManager : MonoBehaviour
{
    public static GameStatsManager Instance { get; private set; }

    private int totalKills = 0;
    private int totalGoldEarned = 0;
    private int highestWave = 0;
    private float totalPlayTime = 0f;
    private int totalPulls = 0;

    private float sessionStartTime = 0f;
    private float playTimeSaveTimer = 0f;
    private const float PLAY_TIME_SAVE_INTERVAL = 5f;

    public event Action<int> OnTotalKillsChanged;
    public event Action<int> OnTotalGoldEarnedChanged;
    public event Action<int> OnHighestWaveChanged;
    public event Action<float> OnTotalPlayTimeChanged;
    public event Action<int> OnTotalPullsChanged;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        LoadStats();
        sessionStartTime = Time.realtimeSinceStartup;
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
        SaveStats();
    }

    void Start()
    {
        StartCoroutine(DeferredSubscribe());
    }

    System.Collections.IEnumerator DeferredSubscribe()
    {
        yield return null;

        // BattleUnit OnDeath 구독 - 단, 모든 유닛 추적이 복잡하므로 BattleManager를 통해 처리
        var bm = BattleManager.Instance;
        if (bm != null)
            bm.OnEnemyKilled += () => AddKill();

        // GoldManager 구독
        var gm = GoldManager.Instance;
        if (gm != null)
            gm.OnGoldChanged += (gold) => OnGoldEarned(gold);

        // StageManager 구독
        var sm = StageManager.Instance;
        if (sm != null)
            sm.OnStageChanged += (area, stage, wave) => UpdateHighestWave(wave);

        // GachaManager 구독
        var gacha = GachaManager.Instance;
        if (gacha != null)
        {
            gacha.OnHeroPulled += (_) => AddPull();
            gacha.OnFreePulled += (_) => AddPull();
            gacha.OnMultiPulled += (results) => AddMultiPulls(results != null ? results.Length : 0);
        }
    }

    public void AddKill()
    {
        totalKills++;
        SaveStats();
        OnTotalKillsChanged?.Invoke(totalKills);
    }

    public void OnGoldEarned(int totalGold)
    {
        // GoldManager.OnGoldChanged는 현재 보유 골드를 전달하므로, 직접 tracking은 어렵다.
        // 대신 GoldManager에서 직접 호출되도록 수정하거나, 이벤트를 추가해야 함.
        // 임시로: 세션 시작 시 기록한 초기값과 비교해서 추가된 골드를 계산
    }

    public void AddGoldEarned(int amount)
    {
        totalGoldEarned += amount;
        SaveStats();
        OnTotalGoldEarnedChanged?.Invoke(totalGoldEarned);
    }

    void UpdateHighestWave(int currentWave)
    {
        if (currentWave > highestWave)
        {
            highestWave = currentWave;
            SaveStats();
            OnHighestWaveChanged?.Invoke(highestWave);
        }
    }

    public void AddPull()
    {
        totalPulls++;
        SaveStats();
        OnTotalPullsChanged?.Invoke(totalPulls);
    }

    public void AddMultiPulls(int count)
    {
        totalPulls += count;
        SaveStats();
        OnTotalPullsChanged?.Invoke(totalPulls);
    }

    void Update()
    {
        // 플레이 시간 갱신 및 저장 (5초 주기)
        playTimeSaveTimer += Time.unscaledDeltaTime;
        if (playTimeSaveTimer >= PLAY_TIME_SAVE_INTERVAL)
        {
            totalPlayTime = PlayerPrefs.GetFloat(SaveKeys.StatsTotalPlayTime, 0f) + (Time.realtimeSinceStartup - sessionStartTime);
            PlayerPrefs.SetFloat(SaveKeys.StatsTotalPlayTime, totalPlayTime);
            PlayerPrefs.Save();
            playTimeSaveTimer = 0f;
            OnTotalPlayTimeChanged?.Invoke(totalPlayTime);
        }
    }

    void LoadStats()
    {
        totalKills = PlayerPrefs.GetInt(SaveKeys.StatsTotalKills, 0);
        totalGoldEarned = PlayerPrefs.GetInt(SaveKeys.StatsTotalGoldEarned, 0);
        highestWave = PlayerPrefs.GetInt(SaveKeys.StatsHighestWave, 0);
        totalPlayTime = PlayerPrefs.GetFloat(SaveKeys.StatsTotalPlayTime, 0f);
        totalPulls = PlayerPrefs.GetInt(SaveKeys.StatsTotalPulls, 0);
    }

    void SaveStats()
    {
        PlayerPrefs.SetInt(SaveKeys.StatsTotalKills, totalKills);
        PlayerPrefs.SetInt(SaveKeys.StatsTotalGoldEarned, totalGoldEarned);
        PlayerPrefs.SetInt(SaveKeys.StatsHighestWave, highestWave);
        PlayerPrefs.SetFloat(SaveKeys.StatsTotalPlayTime, totalPlayTime);
        PlayerPrefs.SetInt(SaveKeys.StatsTotalPulls, totalPulls);
        PlayerPrefs.Save();
    }

    // 공개 접근자
    public int TotalKills => totalKills;
    public int TotalGoldEarned => totalGoldEarned;
    public int HighestWave => highestWave;
    public float TotalPlayTime => totalPlayTime;
    public int TotalPulls => totalPulls;
}
