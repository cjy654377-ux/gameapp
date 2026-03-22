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

        if (_cachedStageMgr != null && _stageChangedHandler != null)
            _cachedStageMgr.OnStageChanged -= _stageChangedHandler;

        if (_cachedGachaMgr != null)
        {
            if (_heroPulledHandler  != null) _cachedGachaMgr.OnHeroPulled   -= _heroPulledHandler;
            if (_freePulledHandler  != null) _cachedGachaMgr.OnFreePulled   -= _freePulledHandler;
            if (_multiPulledHandler != null) _cachedGachaMgr.OnMultiPulled  -= _multiPulledHandler;
        }

        SaveStats();
    }

    // 이벤트 핸들러 캐시 (OnDestroy 해제용)
    System.Action<int, int, int> _stageChangedHandler;
    System.Action<CharacterPreset> _heroPulledHandler;
    System.Action<CharacterPreset> _freePulledHandler;
    System.Action<CharacterPreset[]> _multiPulledHandler;
    StageManager _cachedStageMgr;
    GachaManager _cachedGachaMgr;

    void Start()
    {
        StartCoroutine(DeferredSubscribe());
    }

    System.Collections.IEnumerator DeferredSubscribe()
    {
        yield return null;

        // 킬 카운트는 BattleUnit.Die()에서 GameStatsManager.Instance.AddKill()로 직접 호출됨
        // 골드 통계는 AddGoldEarned()로 직접 호출됨

        // StageManager 구독
        _cachedStageMgr = StageManager.Instance;
        if (_cachedStageMgr != null)
        {
            _stageChangedHandler = (area, stage, wave) => UpdateHighestWave(wave);
            _cachedStageMgr.OnStageChanged += _stageChangedHandler;
        }

        // GachaManager 구독
        _cachedGachaMgr = GachaManager.Instance;
        if (_cachedGachaMgr != null)
        {
            _heroPulledHandler   = (_) => AddPull();
            _freePulledHandler   = (_) => AddPull();
            _multiPulledHandler  = (results) => AddMultiPulls(results != null ? results.Length : 0);
            _cachedGachaMgr.OnHeroPulled   += _heroPulledHandler;
            _cachedGachaMgr.OnFreePulled   += _freePulledHandler;
            _cachedGachaMgr.OnMultiPulled  += _multiPulledHandler;
        }
    }

    public void AddKill()
    {
        totalKills++;
        SaveStats();
        OnTotalKillsChanged?.Invoke(totalKills);
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
