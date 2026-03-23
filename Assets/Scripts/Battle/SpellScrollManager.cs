using UnityEngine;

/// <summary>
/// 주문서 재화 싱글톤. GemManager 패턴 동일.
/// Skill 던전 클리어 보상으로 획득, 스킬 뽑기에 사용.
/// </summary>
public class SpellScrollManager : MonoBehaviour
{
    public static SpellScrollManager Instance { get; private set; }

    public int Scroll { get; private set; }
    public event System.Action<int> OnScrollChanged;

    private bool _isDirty;
    private float _saveTimer;
    private const float SAVE_INTERVAL = 5f;

    void Awake()
    {
        if (Instance != null) { Destroy(gameObject); return; }
        Instance = this;
        Scroll = PlayerPrefs.GetInt(SaveKeys.SpellScroll, 0);
    }

    public void AddScroll(int amount)
    {
        Scroll += amount;
        _isDirty = true;
        OnScrollChanged?.Invoke(Scroll);
    }

    public bool SpendScroll(int amount)
    {
        if (Scroll < amount) return false;
        Scroll -= amount;
        _isDirty = true;
        OnScrollChanged?.Invoke(Scroll);
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
        PlayerPrefs.SetInt(SaveKeys.SpellScroll, Scroll);
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
