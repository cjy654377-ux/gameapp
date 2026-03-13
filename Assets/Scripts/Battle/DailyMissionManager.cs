using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// 일일 미션 시스템. 매일 자정(UTC) 리셋.
/// 미션 완료 시 보석 보상.
/// </summary>
public class DailyMissionManager : MonoBehaviour
{
    public static DailyMissionManager Instance { get; private set; }

    [System.Serializable]
    public class Mission
    {
        public string id;
        public string name;
        public int targetCount;
        public int currentCount;
        public int gemReward;
        public bool claimed;
    }

    readonly List<Mission> missions = new();
    string lastResetDate;

    public event System.Action OnMissionUpdated;

    // Cached references
    StageManager cachedStageMgr;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        CheckAndResetDaily();
    }

    void Start()
    {
        StartCoroutine(DeferredSubscribe());
    }

    System.Collections.IEnumerator DeferredSubscribe()
    {
        yield return null;

        cachedStageMgr = StageManager.Instance;
        if (cachedStageMgr != null)
            cachedStageMgr.OnStageChanged += OnStageChanged;
    }

    void OnDestroy()
    {
        if (cachedStageMgr != null)
            cachedStageMgr.OnStageChanged -= OnStageChanged;
    }

    void CheckAndResetDaily()
    {
        string today = System.DateTime.UtcNow.ToString("yyyy-MM-dd");
        lastResetDate = PlayerPrefs.GetString("DailyMission_Date", "");

        if (lastResetDate != today)
        {
            ResetMissions();
            PlayerPrefs.SetString("DailyMission_Date", today);
            PlayerPrefs.Save();
        }
        else
        {
            LoadMissions();
        }
    }

    static void PopulateDefaultMissions(List<Mission> list)
    {
        list.Clear();
        list.Add(new Mission { id = "kill_10", name = "적 10마리 처치", targetCount = 10, gemReward = 5 });
        list.Add(new Mission { id = "wave_3", name = "3웨이브 클리어", targetCount = 3, gemReward = 5 });
        list.Add(new Mission { id = "kill_50", name = "적 50마리 처치", targetCount = 50, gemReward = 10 });
        list.Add(new Mission { id = "wave_10", name = "10웨이브 클리어", targetCount = 10, gemReward = 10 });
        list.Add(new Mission { id = "gacha_1", name = "소환 1회", targetCount = 1, gemReward = 5 });
    }

    void ResetMissions()
    {
        PopulateDefaultMissions(missions);
        SaveMissions();
    }

    public IReadOnlyList<Mission> GetMissions() => missions;

    public void AddProgress(string missionId, int amount = 1)
    {
        for (int i = 0; i < missions.Count; i++)
        {
            if (missions[i].id == missionId && !missions[i].claimed)
            {
                missions[i].currentCount = Mathf.Min(
                    missions[i].currentCount + amount,
                    missions[i].targetCount);
                SaveMissions();
                OnMissionUpdated?.Invoke();
                break;
            }
        }
    }

    public bool ClaimReward(string missionId)
    {
        for (int i = 0; i < missions.Count; i++)
        {
            var m = missions[i];
            if (m.id == missionId && m.currentCount >= m.targetCount && !m.claimed)
            {
                m.claimed = true;
                GemManager.Instance?.AddGem(m.gemReward);
                SaveMissions();
                OnMissionUpdated?.Invoke();
                return true;
            }
        }
        return false;
    }

    // ── Event handlers ──

    void OnStageChanged(int area, int stage, int wave)
    {
        AddProgress("wave_3");
        AddProgress("wave_10");
    }

    public void RegisterKill()
    {
        AddProgress("kill_10");
        AddProgress("kill_50");
    }

    public void RegisterGacha()
    {
        AddProgress("gacha_1");
    }

    // ── Save/Load ──

    void SaveMissions()
    {
        for (int i = 0; i < missions.Count; i++)
        {
            var m = missions[i];
            PlayerPrefs.SetInt($"DM_{m.id}_cur", m.currentCount);
            PlayerPrefs.SetInt($"DM_{m.id}_claimed", m.claimed ? 1 : 0);
        }
    }

    void LoadMissions()
    {
        PopulateDefaultMissions(missions);

        for (int i = 0; i < missions.Count; i++)
        {
            var m = missions[i];
            m.currentCount = PlayerPrefs.GetInt($"DM_{m.id}_cur", 0);
            m.claimed = PlayerPrefs.GetInt($"DM_{m.id}_claimed", 0) == 1;
        }
    }
}
