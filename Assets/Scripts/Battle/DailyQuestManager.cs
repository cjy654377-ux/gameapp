using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// 일일 퀘스트 시스템. 매일 자정(UTC) 리셋.
/// 퀘스트 3종: 웨이브 클리어(골드), 스킬 사용(보석), 던전 클리어(주문서)
/// </summary>
public class DailyQuestManager : MonoBehaviour
{
    public static DailyQuestManager Instance { get; private set; }

    public enum RewardType { Gold, Gem, Scroll }

    [System.Serializable]
    public class Quest
    {
        public string id;
        public string name;
        public int targetCount;
        public int currentCount;
        public bool claimed;
        public RewardType rewardType;
        public int rewardAmount;
    }

    readonly List<Quest> quests = new();

    public event System.Action OnQuestUpdated;

    // Cached references
    StageManager   cachedStageMgr;
    DungeonManager cachedDungeonMgr;

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
            cachedStageMgr.OnWaveCleared += OnWaveCleared;

        cachedDungeonMgr = DungeonManager.Instance;
        if (cachedDungeonMgr != null)
            cachedDungeonMgr.OnDungeonCleared += OnDungeonCleared;
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
        if (cachedStageMgr  != null) cachedStageMgr.OnWaveCleared       -= OnWaveCleared;
        if (cachedDungeonMgr != null) cachedDungeonMgr.OnDungeonCleared  -= OnDungeonCleared;
    }

    // ─────────────────────────────────────────────
    // 일일 리셋
    // ─────────────────────────────────────────────

    void CheckAndResetDaily()
    {
        string today = System.DateTime.UtcNow.ToString("yyyy-MM-dd");
        string saved = PlayerPrefs.GetString(SaveKeys.DailyQuestDate, "");

        if (saved != today)
        {
            PopulateQuests();
            SaveQuests();
            PlayerPrefs.SetString(SaveKeys.DailyQuestDate, today);
            PlayerPrefs.Save();
        }
        else
        {
            LoadQuests();
        }
    }

    void PopulateQuests()
    {
        quests.Clear();
        quests.Add(new Quest { id = "dq_wave10",  name = "웨이브 10개 클리어", targetCount = 10, rewardType = RewardType.Gold,   rewardAmount = 500 });
        quests.Add(new Quest { id = "dq_skill5",  name = "스킬 5회 사용",      targetCount = 5,  rewardType = RewardType.Gem,    rewardAmount = 5  });
        quests.Add(new Quest { id = "dq_dungeon1", name = "던전 1회 클리어",    targetCount = 1,  rewardType = RewardType.Scroll, rewardAmount = 1  });
    }

    // ─────────────────────────────────────────────
    // 퍼블릭 API
    // ─────────────────────────────────────────────

    public IReadOnlyList<Quest> GetQuests() => quests;

    public void RegisterSkillUse()   => AddProgress("dq_skill5");
    public void RegisterWaveClear()  => AddProgress("dq_wave10");

    public bool ClaimReward(string questId)
    {
        for (int i = 0; i < quests.Count; i++)
        {
            var q = quests[i];
            if (q.id != questId || q.currentCount < q.targetCount || q.claimed) continue;

            q.claimed = true;
            switch (q.rewardType)
            {
                case RewardType.Gold:   GoldManager.Instance?.AddGold(q.rewardAmount);              break;
                case RewardType.Gem:    GemManager.Instance?.AddGem(q.rewardAmount);                break;
                case RewardType.Scroll: SpellScrollManager.Instance?.AddScroll(q.rewardAmount);     break;
            }
            SaveQuests();
            OnQuestUpdated?.Invoke();
            return true;
        }
        return false;
    }

    // ─────────────────────────────────────────────
    // 이벤트 핸들러
    // ─────────────────────────────────────────────

    void OnWaveCleared()    => AddProgress("dq_wave10");
    void OnDungeonCleared(DungeonManager.DungeonType _, int __) => AddProgress("dq_dungeon1");

    // ─────────────────────────────────────────────
    // 내부 헬퍼
    // ─────────────────────────────────────────────

    void AddProgress(string questId, int amount = 1)
    {
        for (int i = 0; i < quests.Count; i++)
        {
            var q = quests[i];
            if (q.id != questId || q.claimed) continue;
            q.currentCount = Mathf.Min(q.currentCount + amount, q.targetCount);
            SaveQuests();
            OnQuestUpdated?.Invoke();
            break;
        }
    }

    // ─────────────────────────────────────────────
    // 저장 / 불러오기
    // ─────────────────────────────────────────────

    void SaveQuests()
    {
        for (int i = 0; i < quests.Count; i++)
        {
            var q = quests[i];
            PlayerPrefs.SetInt(SaveKeys.DailyQuestCurPrefix     + q.id, q.currentCount);
            PlayerPrefs.SetInt(SaveKeys.DailyQuestClaimedPrefix + q.id, q.claimed ? 1 : 0);
        }
    }

    void LoadQuests()
    {
        PopulateQuests();
        for (int i = 0; i < quests.Count; i++)
        {
            var q = quests[i];
            q.currentCount = PlayerPrefs.GetInt(SaveKeys.DailyQuestCurPrefix     + q.id, 0);
            q.claimed      = PlayerPrefs.GetInt(SaveKeys.DailyQuestClaimedPrefix + q.id, 0) == 1;
        }
    }

    void OnApplicationPause(bool pause) { if (pause) { SaveQuests(); PlayerPrefs.Save(); } }
    void OnApplicationQuit()            { SaveQuests(); PlayerPrefs.Save(); }
}
