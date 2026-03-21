using UnityEngine;

/// <summary>
/// 명성 재화 관리 (싱글톤). 아레나 승리 시 획득, 아레나 상점 전용 통화.
/// 5초 디바운싱 저장.
/// </summary>
public class ReputationManager : MonoBehaviour
{
    public static ReputationManager Instance { get; private set; }

    public int Reputation { get; private set; }
    public event System.Action<int> OnReputationChanged;

    const float SAVE_INTERVAL = 5f;
    bool isDirty;
    float saveTimer;

    void Awake()
    {
        if (Instance != null) { Destroy(gameObject); return; }
        Instance = this;
        DontDestroyOnLoad(gameObject);
        Reputation = PlayerPrefs.GetInt(SaveKeys.Reputation, 0);
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }

    public void AddReputation(int amount)
    {
        if (amount <= 0) return;
        Reputation += amount;
        isDirty = true;
        OnReputationChanged?.Invoke(Reputation);
    }

    public bool SpendReputation(int amount)
    {
        if (amount <= 0 || Reputation < amount) return false;
        Reputation -= amount;
        isDirty = true;
        OnReputationChanged?.Invoke(Reputation);
        return true;
    }

    void Update()
    {
        if (!isDirty) return;
        saveTimer += Time.deltaTime;
        if (saveTimer >= SAVE_INTERVAL) FlushSave();
    }

    void FlushSave()
    {
        if (!isDirty) return;
        PlayerPrefs.SetInt(SaveKeys.Reputation, Reputation);
        PlayerPrefs.Save();
        isDirty = false;
        saveTimer = 0f;
    }

    void OnApplicationPause(bool pause) { if (pause) FlushSave(); }
    void OnApplicationQuit() => FlushSave();
}
