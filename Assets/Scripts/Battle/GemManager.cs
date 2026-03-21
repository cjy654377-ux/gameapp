using UnityEngine;

public class GemManager : MonoBehaviour
{
    public static GemManager Instance { get; private set; }

    public int Gem { get; private set; }
    public event System.Action<int> OnGemChanged;

    private bool isDirty;
    private float saveTimer;
    private const float SAVE_INTERVAL = 5f;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        Gem = PlayerPrefs.GetInt(SaveKeys.Gem, 0);
    }

    public void AddGem(int amount)
    {
        Gem += amount;
        isDirty = true;
        OnGemChanged?.Invoke(Gem);
    }

    public bool SpendGem(int amount)
    {
        if (Gem < amount) return false;
        Gem -= amount;
        isDirty = true;
        OnGemChanged?.Invoke(Gem);
        return true;
    }

    void Update()
    {
        if (!isDirty) return;
        saveTimer += Time.deltaTime;
        if (saveTimer >= SAVE_INTERVAL)
        {
            FlushSave();
        }
    }

    void FlushSave()
    {
        if (!isDirty) return;
        PlayerPrefs.SetInt(SaveKeys.Gem, Gem);
        PlayerPrefs.Save();
        isDirty = false;
        saveTimer = 0f;
    }

    void OnApplicationPause(bool pause)
    {
        if (pause) FlushSave();
    }

    void OnApplicationQuit()
    {
        FlushSave();
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }
}
