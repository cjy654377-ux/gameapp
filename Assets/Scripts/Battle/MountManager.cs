using UnityEngine;
using System;
using System.Collections.Generic;

/// <summary>
/// 탈것 뽑기/장착/해제 싱글톤.
/// SummonStone 소모로 뽑기, 보유 목록 및 장착 상태 PlayerPrefs 저장.
/// </summary>
public class MountManager : MonoBehaviour
{
    public static MountManager Instance { get; private set; }

    public const int PULL_COST = 1; // 소환석 1개

    // 가챠 확률 (GachaManager 동일 구조)
    const float PROB_STAR5     = 0.03f;
    const float PROB_STAR4_CUM = 1f;
    const float PROB_STAR3_CUM = 10f;
    const float PROB_STAR2_CUM = 40f;

    [Header("Mount Pool (에디터 또는 Resources/Mounts/)")]
    [SerializeField] MountData[] allMounts;

    // 성급별 풀
    readonly List<MountData> star1Pool = new();
    readonly List<MountData> star2Pool = new();
    readonly List<MountData> star3Pool = new();
    readonly List<MountData> star4Pool = new();
    readonly List<MountData> star5Pool = new();

    public List<string> OwnedMountNames { get; private set; } = new();
    public string EquippedMountName { get; private set; } = "";

    public event Action<MountData> OnMountPulled;
    public event Action<MountData> OnMountEquipped;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        LoadMountPool();
        LoadSaved();
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }

    // ────────────────────────────────────────
    // Setup
    // ────────────────────────────────────────

    void LoadMountPool()
    {
        if (allMounts == null || allMounts.Length == 0)
            allMounts = Resources.LoadAll<MountData>("Mounts");

        star1Pool.Clear(); star2Pool.Clear(); star3Pool.Clear();
        star4Pool.Clear(); star5Pool.Clear();

        if (allMounts == null) return;
        foreach (var m in allMounts)
        {
            if (m == null) continue;
            switch (m.starGrade)
            {
                case StarGrade.Star1: star1Pool.Add(m); break;
                case StarGrade.Star2: star2Pool.Add(m); break;
                case StarGrade.Star3: star3Pool.Add(m); break;
                case StarGrade.Star4: star4Pool.Add(m); break;
                case StarGrade.Star5: star5Pool.Add(m); break;
            }
        }
    }

    void LoadSaved()
    {
        string ownedJson = PlayerPrefs.GetString(SaveKeys.MountOwned, "");
        if (!string.IsNullOrEmpty(ownedJson))
        {
            var wrapper = JsonUtility.FromJson<StringListWrapper>(ownedJson);
            if (wrapper?.items != null)
                OwnedMountNames = new List<string>(wrapper.items);
        }
        EquippedMountName = PlayerPrefs.GetString(SaveKeys.MountEquipped, "");
    }

    // ────────────────────────────────────────
    // Public API
    // ────────────────────────────────────────

    public bool PullMount()
    {
        if (SummonStoneManager.Instance == null ||
            !SummonStoneManager.Instance.SpendStone(PULL_COST))
            return false;

        var mount = RollMount();
        if (mount == null) return false;

        if (!OwnedMountNames.Contains(mount.mountName))
            OwnedMountNames.Add(mount.mountName);

        FlushSave();
        OnMountPulled?.Invoke(mount);
        return true;
    }

    public void EquipMount(string mountName)
    {
        EquippedMountName = mountName;
        FlushSave();
        var data = GetMountData(mountName);
        OnMountEquipped?.Invoke(data);
    }

    public void UnequipMount()
    {
        EquippedMountName = "";
        FlushSave();
        OnMountEquipped?.Invoke(null);
    }

    public MountData GetEquippedMount() => GetMountData(EquippedMountName);

    /// <summary>장착된 탈것의 horseSpriteFolder 반환. 없으면 빈 문자열.</summary>
    public string GetEquippedSpriteFolder()
    {
        var m = GetEquippedMount();
        return m != null ? m.horseSpriteFolder : "";
    }

    /// <summary>장착 탈것의 스탯 보너스 반환.</summary>
    public void GetMountBonus(out float speedPct, out float hpPct, out float atkPct)
    {
        var m = GetEquippedMount();
        if (m == null) { speedPct = hpPct = atkPct = 0f; return; }
        speedPct = m.speedBonus;
        hpPct    = m.hpBonusPercent;
        atkPct   = m.atkBonusPercent;
    }

    public bool IsOwned(string mountName) => OwnedMountNames.Contains(mountName);

    // ────────────────────────────────────────
    // Gacha roll
    // ────────────────────────────────────────

    MountData RollMount()
    {
        float roll = UnityEngine.Random.Range(0f, 100f);
        List<MountData> pool;
        if (roll < PROB_STAR5)           pool = star5Pool.Count > 0 ? star5Pool : star4Pool;
        else if (roll < PROB_STAR4_CUM)  pool = star4Pool.Count > 0 ? star4Pool : star3Pool;
        else if (roll < PROB_STAR3_CUM)  pool = star3Pool.Count > 0 ? star3Pool : star2Pool;
        else if (roll < PROB_STAR2_CUM)  pool = star2Pool.Count > 0 ? star2Pool : star1Pool;
        else                             pool = star1Pool.Count > 0 ? star1Pool : GetAnyPool();

        if (pool == null || pool.Count == 0) return null;
        return pool[UnityEngine.Random.Range(0, pool.Count)];
    }

    List<MountData> GetAnyPool()
    {
        if (star1Pool.Count > 0) return star1Pool;
        if (star2Pool.Count > 0) return star2Pool;
        if (star3Pool.Count > 0) return star3Pool;
        return star4Pool;
    }

    // ────────────────────────────────────────
    // Helpers
    // ────────────────────────────────────────

    MountData GetMountData(string name)
    {
        if (string.IsNullOrEmpty(name) || allMounts == null) return null;
        foreach (var m in allMounts)
            if (m != null && m.mountName == name) return m;
        return null;
    }

    void FlushSave()
    {
        var wrapper = new StringListWrapper { items = OwnedMountNames.ToArray() };
        PlayerPrefs.SetString(SaveKeys.MountOwned, JsonUtility.ToJson(wrapper));
        PlayerPrefs.SetString(SaveKeys.MountEquipped, EquippedMountName);
        PlayerPrefs.Save();
    }

    void OnApplicationPause(bool pause) { if (pause) FlushSave(); }
    void OnApplicationQuit() { FlushSave(); }

    [Serializable]
    class StringListWrapper { public string[] items; }
}
