using UnityEngine;
using System.Collections;
using System.Text;

/// <summary>
/// 클라우드 저장/불러오기 관리
/// Firestore SDK 연동 전까지는 로컬 직렬화만 동작
/// </summary>
public class CloudSaveManager : MonoBehaviour
{
    public static CloudSaveManager Instance { get; private set; }

    const float AUTO_SAVE_INTERVAL = 300f; // 5분
    float autoSaveTimer;

    public event System.Action<bool> OnSaveComplete;
    public event System.Action<bool> OnLoadComplete;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }
    }

    void Start()
    {
        autoSaveTimer = AUTO_SAVE_INTERVAL;
    }

    void Update()
    {
        if (!Application.isPlaying) return;
        autoSaveTimer -= Time.unscaledDeltaTime;
        if (autoSaveTimer <= 0f)
        {
            autoSaveTimer = AUTO_SAVE_INTERVAL;
            if (AuthManager.Instance != null && AuthManager.Instance.IsLoggedIn)
                SaveToCloud();
        }
    }

    /// <summary>
    /// SaveKeys 기반 PlayerPrefs 전체 수집 → JSON 문자열
    /// </summary>
    public string SerializeAllSaveData()
    {
        var sb = new StringBuilder();
        sb.Append("{");

        AppendStr(sb, SaveKeys.Gold,              PlayerPrefs.GetFloat(SaveKeys.Gold, 0).ToString("F0"));
        AppendStr(sb, SaveKeys.Gem,               PlayerPrefs.GetInt(SaveKeys.Gem, 0).ToString());
        AppendStr(sb, SaveKeys.TotalWaveIndex,    PlayerPrefs.GetInt(SaveKeys.TotalWaveIndex, 0).ToString());
        AppendStr(sb, SaveKeys.UpgradeHp,         PlayerPrefs.GetInt(SaveKeys.UpgradeHp, 0).ToString());
        AppendStr(sb, SaveKeys.UpgradeAtk,        PlayerPrefs.GetInt(SaveKeys.UpgradeAtk, 0).ToString());
        AppendStr(sb, SaveKeys.UpgradeDef,        PlayerPrefs.GetInt(SaveKeys.UpgradeDef, 0).ToString());
        AppendStr(sb, SaveKeys.TapDamageLevel,    PlayerPrefs.GetInt(SaveKeys.TapDamageLevel, 0).ToString());
        AppendStr(sb, SaveKeys.SummonStone,       PlayerPrefs.GetInt(SaveKeys.SummonStone, 0).ToString());
        AppendStr(sb, SaveKeys.SpellScroll,       PlayerPrefs.GetInt(SaveKeys.SpellScroll, 0).ToString());
        AppendStr(sb, SaveKeys.PityCounter,       PlayerPrefs.GetInt(SaveKeys.PityCounter, 0).ToString());
        AppendStr(sb, SaveKeys.AwakeningStone,    PlayerPrefs.GetInt(SaveKeys.AwakeningStone, 0).ToString());
        AppendStr(sb, SaveKeys.MountOwned,        PlayerPrefs.GetString(SaveKeys.MountOwned, ""));
        AppendStr(sb, SaveKeys.MountEquipped,     PlayerPrefs.GetString(SaveKeys.MountEquipped, ""));
        AppendStr(sb, SaveKeys.EquipmentInventory,PlayerPrefs.GetString(SaveKeys.EquipmentInventory, ""));
        AppendStr(sb, SaveKeys.EquippedSkills,    PlayerPrefs.GetString(SaveKeys.EquippedSkills, ""));
        AppendStr(sb, SaveKeys.ClearedStages,     PlayerPrefs.GetString(SaveKeys.ClearedStages, ""));

        // 덱 슬롯
        for (int i = 0; i < DeckManager.MAX_DECK_SIZE; i++)
        {
            string key = $"{SaveKeys.DeckSlotPrefix}{i}";
            AppendStr(sb, key, PlayerPrefs.GetString(key, ""));
        }

        // 마지막 쉼표 제거
        if (sb[sb.Length - 1] == ',') sb.Length--;
        sb.Append("}");
        return sb.ToString();
    }

    static void AppendStr(StringBuilder sb, string key, string value)
    {
        sb.Append($"\"{EscapeJson(key)}\":\"{EscapeJson(value)}\",");
    }

    static string EscapeJson(string s) => s.Replace("\\", "\\\\").Replace("\"", "\\\"");

    /// <summary>
    /// 클라우드 업로드 (TODO: Firestore)
    /// </summary>
    public void SaveToCloud()
    {
        string json = SerializeAllSaveData();
        string userId = AuthManager.Instance?.UserId;

        if (string.IsNullOrEmpty(userId))
        {
            Debug.LogWarning("[CloudSave] 로그인 필요");
            OnSaveComplete?.Invoke(false);
            return;
        }

        // TODO: Firestore.Collection("saves").Document(userId).SetAsync(data)
        Debug.Log($"[CloudSave] 업로드 준비 완료 ({json.Length} bytes) — Firestore SDK 필요");
        PlayerPrefs.SetString(SaveKeys.CloudSaveLastSync, System.DateTime.UtcNow.ToString("o"));
        PlayerPrefs.Save();
        OnSaveComplete?.Invoke(true);
    }

    /// <summary>
    /// 클라우드 다운로드 (TODO: Firestore)
    /// </summary>
    public void LoadFromCloud()
    {
        string userId = AuthManager.Instance?.UserId;

        if (string.IsNullOrEmpty(userId))
        {
            Debug.LogWarning("[CloudSave] 로그인 필요");
            OnLoadComplete?.Invoke(false);
            return;
        }

        // TODO: Firestore.Collection("saves").Document(userId).GetAsync()
        Debug.Log("[CloudSave] 다운로드 — Firestore SDK 필요");
        OnLoadComplete?.Invoke(false);
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }
}
