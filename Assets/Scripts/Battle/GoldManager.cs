using UnityEngine;

public class GoldManager : MonoBehaviour
{
    public static GoldManager Instance { get; private set; }

    public int Gold { get; private set; }
    public event System.Action<int> OnGoldChanged;

    private bool isDirty;
    private float saveTimer;
    private const float SAVE_INTERVAL = 5f;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(gameObject);

        Gold = PlayerPrefs.GetInt("Gold", 0);
    }

    public void AddGold(int amount)
    {
        Gold += amount;
        isDirty = true;
        OnGoldChanged?.Invoke(Gold);
    }

    public bool SpendGold(int amount)
    {
        if (Gold < amount) return false;
        Gold -= amount;
        isDirty = true;
        OnGoldChanged?.Invoke(Gold);
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
        PlayerPrefs.SetInt("Gold", Gold);
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
}
