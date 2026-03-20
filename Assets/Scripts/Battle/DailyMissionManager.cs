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
        if (Instance == this) Instance = null;
        if (cachedStageMgr != null)
            cachedStageMgr.OnStageChanged -= OnStageChanged;
    }

    void CheckAndResetDaily()
    {
        string today = System.DateTime.UtcNow.ToString("yyyy-MM-dd");
        lastResetDate = PlayerPrefs.GetString(SaveKeys.DailyMissionDate, "");

        if (lastResetDate != today)
        {
            ResetMissions();
            PlayerPrefs.SetString(SaveKeys.DailyMissionDate, today);
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
        list.Add(new Mission { id = "kill_10", name = "적 10마리 처치", targetCount = 10, gemReward = 10 });
        list.Add(new Mission { id = "wave_3", name = "3웨이브 클리어", targetCount = 3, gemReward = 15 });
        list.Add(new Mission { id = "gacha_1", name = "소환 1회", targetCount = 1, gemReward = 10 });
        list.Add(new Mission { id = "skill_5", name = "스킬 5회 사용", targetCount = 5, gemReward = 20 });
        list.Add(new Mission { id = "equip_1", name = "장비 1개 획득", targetCount = 1, gemReward = 30 });
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
    }

    public void RegisterKill()
    {
        AddProgress("kill_10");
    }

    public void RegisterGacha()
    {
        AddProgress("gacha_1");
    }

    public void RegisterWaveClear()
    {
        AddProgress("wave_3");
    }

    public void RegisterSkillUse()
    {
        AddProgress("skill_5");
    }

    public void RegisterEquipDrop()
    {
        AddProgress("equip_1");
    }

    // ── Save/Load ──

    void SaveMissions()
    {
        for (int i = 0; i < missions.Count; i++)
        {
            var m = missions[i];
            PlayerPrefs.SetInt(SaveKeys.DailyMissionCurPrefix + m.id, m.currentCount);
            PlayerPrefs.SetInt(SaveKeys.DailyMissionClaimedPrefix + m.id, m.claimed ? 1 : 0);
        }
    }

    void LoadMissions()
    {
        PopulateDefaultMissions(missions);

        for (int i = 0; i < missions.Count; i++)
        {
            var m = missions[i];
            m.currentCount = PlayerPrefs.GetInt(SaveKeys.DailyMissionCurPrefix + m.id, 0);
            m.claimed = PlayerPrefs.GetInt(SaveKeys.DailyMissionClaimedPrefix + m.id, 0) == 1;
        }
    }

    void OnApplicationPause(bool pause)
    {
        if (pause) { SaveMissions(); PlayerPrefs.Save(); }
    }

    void OnApplicationQuit()
    {
        SaveMissions();
        PlayerPrefs.Save();
    }
}
