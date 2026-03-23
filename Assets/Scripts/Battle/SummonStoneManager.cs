using UnityEngine;

/// <summary>
/// 소환석 재화 싱글톤. GemManager 패턴 동일.
/// Mount 던전 클리어 보상으로 획득, 탈것 뽑기에 사용.
/// </summary>
public class SummonStoneManager : MonoBehaviour
{
    public static SummonStoneManager Instance { get; private set; }

    public int Stone { get; private set; }
    public event System.Action<int> OnStoneChanged;

    private bool _isDirty;
    private float _saveTimer;
    private const float SAVE_INTERVAL = 5f;

    void Awake()
    {
        if (Instance != null) { Destroy(gameObject); return; }
        Instance = this;
        Stone = PlayerPrefs.GetInt(SaveKeys.SummonStone, 0);
    }

    public void AddStone(int amount)
    {
        Stone += amount;
        _isDirty = true;
        OnStoneChanged?.Invoke(Stone);
    }

    public bool SpendStone(int amount)
    {
        if (Stone < amount) return false;
        Stone -= amount;
        _isDirty = true;
        OnStoneChanged?.Invoke(Stone);
        return true;
    }

    void Update()
    {
        if (!_isDirty) return;
        _saveTimer += Time.deltaTime;
        if (_saveTimer >= SAVE_INTERVAL) FlushSave();
    }

    void FlushSave()
    {
        if (!_isDirty) return;
        PlayerPrefs.SetInt(SaveKeys.SummonStone, Stone);
        PlayerPrefs.Save();
        _isDirty = false;
        _saveTimer = 0f;
    }

    void OnApplicationPause(bool pause) { if (pause) FlushSave(); }
    void OnApplicationQuit() { FlushSave(); }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }
}
