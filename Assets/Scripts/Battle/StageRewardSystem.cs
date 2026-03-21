using UnityEngine;
using System.Collections.Generic;

public class StageRewardSystem : MonoBehaviour
{
    public static StageRewardSystem Instance { get; private set; }

    /// <summary>
    /// gold, gem
    /// </summary>
    public event System.Action<int, int> OnStageRewardGranted;
    public event System.Action<int, int> OnBossRewardMultiplierRequested; // 보스 보상 2배 광고 요청 (gold, gem)

    private int _lastBossGoldReward;
    private int _lastBossGemReward;
    private bool _bossRewardMultiplierUsed;

    private HashSet<int> clearedStages = new();
    StageManager cachedStageMgr;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        LoadClearedStages();
    }

    void Start()
    {
        cachedStageMgr = StageManager.Instance;
        if (cachedStageMgr != null)
            cachedStageMgr.OnStageCleared += OnStageClearedEvent;
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
        if (cachedStageMgr != null)
            cachedStageMgr.OnStageCleared -= OnStageClearedEvent;
    }

    void OnStageClearedEvent(int totalWaveIndex)
    {
        GrantReward(totalWaveIndex);
    }

    public bool IsFirstClear(int totalWaveIndex)
    {
        return !clearedStages.Contains(totalWaveIndex);
    }

    public void GrantReward(int totalWaveIndex)
    {
        if (!IsFirstClear(totalWaveIndex)) return;

        int stageIndex = totalWaveIndex;
        int goldReward = 100 + stageIndex * 20;
        int gemReward = 5 + stageIndex / 10;

        if (GoldManager.Instance != null)
            GoldManager.Instance.AddGold(goldReward);

        if (GemManager.Instance != null)
            GemManager.Instance.AddGem(gemReward);

        clearedStages.Add(totalWaveIndex);
        SaveClearedStages();

        OnStageRewardGranted?.Invoke(goldReward, gemReward);

        // 에리어 보스(30의 배수 웨이브)이면 2배 보상 광고 제시
        if (totalWaveIndex > 0 && totalWaveIndex % 30 == 0)
        {
            _lastBossGoldReward = goldReward;
            _lastBossGemReward = gemReward;
            _bossRewardMultiplierUsed = false;
            OnBossRewardMultiplierRequested?.Invoke(goldReward, gemReward);
        }
    }

    void LoadClearedStages()
    {
        clearedStages.Clear();
        string saved = PlayerPrefs.GetString(SaveKeys.ClearedStages, "");
        if (string.IsNullOrEmpty(saved)) return;

        string[] parts = saved.Split(',');
        for (int i = 0; i < parts.Length; i++)
        {
            if (int.TryParse(parts[i], out int idx))
                clearedStages.Add(idx);
        }
    }

    void SaveClearedStages()
    {
        var sb = new System.Text.StringBuilder();
        bool first = true;
        foreach (int idx in clearedStages)
        {
            if (!first) sb.Append(',');
            sb.Append(idx);
            first = false;
        }
        PlayerPrefs.SetString(SaveKeys.ClearedStages, sb.ToString());
    }

    /// <summary>
    /// 광고로 보스 보상 2배 지급 (1회 제한)
    /// </summary>
    public void GrantBossRewardMultiplier()
    {
        if (_bossRewardMultiplierUsed) return;

        if (GoldManager.Instance != null)
            GoldManager.Instance.AddGold(_lastBossGoldReward);

        if (GemManager.Instance != null)
            GemManager.Instance.AddGem(_lastBossGemReward);

        _bossRewardMultiplierUsed = true;
    }
}
