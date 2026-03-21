using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// Achievement system with gem rewards.
/// Tracks completion via PlayerPrefs, fires events for UI notifications.
/// </summary>
public class AchievementManager : MonoBehaviour
{
    public static AchievementManager Instance { get; private set; }

    [System.Serializable]
    public class Achievement
    {
        public string id;
        public string name;
        public string description;
        public int gemReward;
        public bool completed;
        public bool claimed;
    }

    // Achievement 임계값 상수
    const int KILL_SAVE_INTERVAL  = 10;
    const int KILL_100_THRESHOLD  = 100;
    const int FULL_PARTY_SIZE     = 5;
    const int WAVE_10_THRESHOLD   = 10;

    // Achievement ID 상수
    const string ACH_FIRST_WAVE   = "first_wave";
    const string ACH_WAVE_10      = "wave_10";
    const string ACH_FIRST_GACHA  = "first_gacha";
    const string ACH_FIRST_BOSS   = "first_boss";
    const string ACH_KILL_100     = "kill_100";
    const string ACH_FULL_PARTY   = "full_party";
    const string ACH_FIRST_UPGRADE = "first_upgrade";
    const string ACH_STAGE_5      = "stage_5";

    readonly List<Achievement> achievements = new();
    int killCount;

    public event System.Action<string> OnAchievementCompleted;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        InitAchievements();
        killCount = PlayerPrefs.GetInt(SaveKeys.AchievementKillCount, 0);
    }

    void InitAchievements()
    {
        achievements.Clear();
        AddAchievement(ACH_FIRST_WAVE,    "첫 번째 웨이브", "첫 웨이브를 클리어하세요", 10);
        AddAchievement(ACH_WAVE_10,       "10웨이브 돌파",  "10웨이브에 도달하세요",   20);
        AddAchievement(ACH_FIRST_GACHA,   "첫 소환",        "영웅을 소환하세요",        5);
        AddAchievement(ACH_FIRST_BOSS,    "보스 처치",      "보스를 처치하세요",        30);
        AddAchievement(ACH_KILL_100,      "100킬 달성",     "적 100마리를 처치하세요", 15);
        AddAchievement(ACH_FULL_PARTY,    "풀 파티",        "영웅 5명을 보유하세요",   25);
        AddAchievement(ACH_FIRST_UPGRADE, "첫 강화",        "번개를 강화하세요",        10);
        AddAchievement(ACH_STAGE_5,       "5스테이지 돌파", "스테이지 5에 도달하세요", 20);
    }

    void AddAchievement(string id, string name, string desc, int gems)
    {
        var a = new Achievement
        {
            id = id,
            name = name,
            description = desc,
            gemReward = gems,
            completed = PlayerPrefs.GetInt(SaveKeys.AchievementPrefix + id, 0) == 1,
            claimed = PlayerPrefs.GetInt(SaveKeys.AchievementClaimedPrefix + id, 0) == 1
        };
        achievements.Add(a);
    }

    // Cached references for safe unsubscribe
    StageManager cachedStageMgr;
    GachaManager cachedGachaMgr;
    UpgradeManager cachedUpgradeMgr;

    void Start()
    {
        StartCoroutine(DeferredSubscribe());
    }

    System.Collections.IEnumerator DeferredSubscribe()
    {
        // 다른 싱글톤이 Awake에서 초기화될 때까지 1프레임 대기
        yield return null;

        cachedStageMgr = StageManager.Instance;
        cachedGachaMgr = GachaManager.Instance;
        cachedUpgradeMgr = UpgradeManager.Instance;

        if (cachedStageMgr != null)
        {
            cachedStageMgr.OnStageChanged += OnStageChanged;
            cachedStageMgr.OnBossSpawned += OnBossKillCheck;
        }
        if (cachedGachaMgr != null)
            cachedGachaMgr.OnHeroPulled += OnHeroPulled;
        if (cachedUpgradeMgr != null)
            cachedUpgradeMgr.OnUpgraded += OnUpgraded;
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
        if (cachedStageMgr != null)
        {
            cachedStageMgr.OnStageChanged -= OnStageChanged;
            cachedStageMgr.OnBossSpawned -= OnBossKillCheck;
        }
        if (cachedGachaMgr != null)
            cachedGachaMgr.OnHeroPulled -= OnHeroPulled;
        if (cachedUpgradeMgr != null)
            cachedUpgradeMgr.OnUpgraded -= OnUpgraded;
    }

    void OnStageChanged(int area, int stage, int wave)
    {
        int totalWave = cachedStageMgr != null ? cachedStageMgr.TotalWaveIndex : 0;

        if (totalWave >= 1)
            CheckAchievement(ACH_FIRST_WAVE);

        if (totalWave >= WAVE_10_THRESHOLD)
            CheckAchievement(ACH_WAVE_10);

        if (stage >= 5 || area > 1)
            CheckAchievement(ACH_STAGE_5);

        // 보스 웨이브 클리어 시 보스 처치 업적
        if (bossWaveActive)
        {
            bossWaveActive = false;
            CheckAchievement(ACH_FIRST_BOSS);
        }
    }

    void OnBossKillCheck(bool isAreaBoss)
    {
        // Boss spawned - track via stage clear event instead
        // The first_boss achievement is checked when the boss wave is cleared
        bossWaveActive = true;
    }

    bool bossWaveActive;

    public void ResetBossTracking() => bossWaveActive = false;

    void OnHeroPulled(CharacterPreset preset)
    {
        CheckAchievement(ACH_FIRST_GACHA);

        if (DeckManager.Instance != null && DeckManager.Instance.roster.Count >= FULL_PARTY_SIZE)
            CheckAchievement(ACH_FULL_PARTY);
    }

    void OnUpgraded()
    {
        CheckAchievement(ACH_FIRST_UPGRADE);
    }

    /// <summary>
    /// Call this when an enemy is killed to track kill count achievements.
    /// </summary>
    public void RegisterKill()
    {
        killCount++;
        if (killCount % KILL_SAVE_INTERVAL == 0)
            PlayerPrefs.SetInt(SaveKeys.AchievementKillCount, killCount);

        if (killCount >= KILL_100_THRESHOLD && !IsCompleted(ACH_KILL_100))
            CheckAchievement(ACH_KILL_100);
    }

    void OnApplicationPause(bool pause)
    {
        if (pause)
            PlayerPrefs.SetInt(SaveKeys.AchievementKillCount, killCount);
    }

    void OnApplicationQuit()
    {
        PlayerPrefs.SetInt(SaveKeys.AchievementKillCount, killCount);
    }

    public void CheckAchievement(string id)
    {
        var ach = FindAchievement(id);
        if (ach == null || ach.completed) return;

        ach.completed = true;
        PlayerPrefs.SetInt(SaveKeys.AchievementPrefix + id, 1);
        PlayerPrefs.Save();

        OnAchievementCompleted?.Invoke(id);
    }

    public bool ClaimReward(string id)
    {
        var ach = FindAchievement(id);
        if (ach == null || !ach.completed || ach.claimed) return false;

        ach.claimed = true;
        PlayerPrefs.SetInt(SaveKeys.AchievementClaimedPrefix + id, 1);
        PlayerPrefs.Save();

        if (GemManager.Instance != null)
            GemManager.Instance.AddGem(ach.gemReward);

        SoundManager.Instance?.PlayUISound(UISoundType.achievement);

        return true;
    }

    public List<Achievement> GetAchievements() => achievements;

    public bool IsCompleted(string id)
    {
        var ach = FindAchievement(id);
        return ach != null && ach.completed;
    }

    public bool IsClaimed(string id)
    {
        var ach = FindAchievement(id);
        return ach != null && ach.claimed;
    }

    Achievement FindAchievement(string id)
    {
        for (int i = 0; i < achievements.Count; i++)
        {
            if (achievements[i].id == id) return achievements[i];
        }
        return null;
    }
}
