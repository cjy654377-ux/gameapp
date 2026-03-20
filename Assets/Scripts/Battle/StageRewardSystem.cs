using UnityEngine;
using System.Collections.Generic;

public class StageRewardSystem : MonoBehaviour
{
    public static StageRewardSystem Instance { get; private set; }

    /// <summary>
    /// gold, gem
    /// </summary>
    public event System.Action<int, int> OnStageRewardGranted;

    private HashSet<int> clearedStages = new();

    void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(gameObject);

        LoadClearedStages();
    }

    void Start()
    {
        if (StageManager.Instance != null)
            StageManager.Instance.OnStageCleared += OnStageClearedEvent;
    }

    void OnDestroy()
    {
        if (StageManager.Instance != null)
            StageManager.Instance.OnStageCleared -= OnStageClearedEvent;
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
}
