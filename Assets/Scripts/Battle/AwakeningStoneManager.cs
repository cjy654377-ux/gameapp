using UnityEngine;

/// <summary>
/// 각성석 재화 관리 (싱글톤). 높은 던전 단계 보상으로 획득.
/// 영웅 각성 시 카피 대신 각성석으로 진행 가능.
/// 5초 디바운싱 저장.
/// </summary>
public class AwakeningStoneManager : MonoBehaviour
{
    public static AwakeningStoneManager Instance { get; private set; }

    public int Stone { get; private set; }
    public event System.Action<int> OnStoneChanged;

    const float SAVE_INTERVAL = 5f;
    bool isDirty;
    float saveTimer;

    void Awake()
    {
        if (Instance != null) { Destroy(gameObject); return; }
        Instance = this;
        DontDestroyOnLoad(gameObject);
        Stone = PlayerPrefs.GetInt(SaveKeys.AwakeningStone, 0);
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }

    public void AddStone(int amount)
    {
        if (amount <= 0) return;
        Stone += amount;
        isDirty = true;
        OnStoneChanged?.Invoke(Stone);
    }

    public bool SpendStone(int amount)
    {
        if (amount <= 0 || Stone < amount) return false;
        Stone -= amount;
        isDirty = true;
        OnStoneChanged?.Invoke(Stone);
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
        PlayerPrefs.SetInt(SaveKeys.AwakeningStone, Stone);
        PlayerPrefs.Save();
        isDirty = false;
        saveTimer = 0f;
    }

    void OnApplicationPause(bool pause) { if (pause) FlushSave(); }
    void OnApplicationQuit() => FlushSave();
}
