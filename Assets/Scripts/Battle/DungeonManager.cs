using UnityEngine;
using System;

/// <summary>
/// 던전 입장/클리어/보상 싱글톤 매니저.
/// 던전 타입별 일일 입장 횟수 제한(기본 3회), 보석으로 추가 구매.
/// 보상: Hero→보석, Mount→소환석, Skill→주문서
/// </summary>
public class DungeonManager : MonoBehaviour
{
    public static DungeonManager Instance { get; private set; }

    private const int DEFAULT_DAILY_ENTRIES = 3;
    private const int GEM_COST_PER_EXTRA = 30;
    private const float SAVE_INTERVAL = 5f;

    public event Action<DungeonType, int> OnDungeonCleared;
    public event Action<DungeonType, int> OnEntriesChanged; // type, remaining

    private int _heroUsed;
    private int _mountUsed;
    private int _skillUsed;
    private int _adBonusUsed;
    private bool _isDirty;
    private float _saveTimer;
    private const int MAX_AD_BONUS_ENTRIES = 3;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        LoadData();
        ResetDailyIfNeeded();
    }

    void LoadData()
    {
        _heroUsed  = PlayerPrefs.GetInt(SaveKeys.DungeonHeroEntries, 0);
        _mountUsed = PlayerPrefs.GetInt(SaveKeys.DungeonMountEntries, 0);
        _skillUsed = PlayerPrefs.GetInt(SaveKeys.DungeonSkillEntries, 0);
        _adBonusUsed = PlayerPrefs.GetInt(SaveKeys.DungeonAdBonusCount, 0);
    }

    void ResetDailyIfNeeded()
    {
        string today = DateTime.UtcNow.ToString("yyyy-MM-dd");
        if (PlayerPrefs.GetString(SaveKeys.DungeonLastResetDate, "") != today)
        {
            _heroUsed = _mountUsed = _skillUsed = 0;
            _adBonusUsed = 0;
            PlayerPrefs.SetString(SaveKeys.DungeonLastResetDate, today);
            PlayerPrefs.SetString(SaveKeys.DungeonAdBonusDate, today);
            _isDirty = true;
        }
    }

    // ────────────────────────────────────────
    // Public API
    // ────────────────────────────────────────

    public int GetRemainingEntries(DungeonType type)
        => Mathf.Max(0, DEFAULT_DAILY_ENTRIES - GetUsed(type));

    public bool CanEnter(DungeonType type) => GetRemainingEntries(type) > 0;

    /// <summary>보석 소모로 입장 횟수 1회 추가 구매.</summary>
    public bool BuyExtraEntry(DungeonType type)
    {
        if (GemManager.Instance == null || !GemManager.Instance.SpendGem(GEM_COST_PER_EXTRA))
            return false;
        AddUsed(type, -1); // 사용 횟수 1 감소 = 잔여 횟수 1 증가
        _isDirty = true;
        OnEntriesChanged?.Invoke(type, GetRemainingEntries(type));
        return true;
    }

    /// <summary>광고 시청으로 추가 입장 (일 3회 한정).</summary>
    public bool AddBonusEntry(DungeonType type)
    {
        ResetDailyIfNeeded(); // 날짜 변경 확인
        if (_adBonusUsed >= MAX_AD_BONUS_ENTRIES)
            return false;

        AddUsed(type, -1); // 사용 횟수 1 감소 = 잔여 횟수 1 증가
        _adBonusUsed++;
        _isDirty = true;
        OnEntriesChanged?.Invoke(type, GetRemainingEntries(type));
        return true;
    }

    /// <summary>던전 입장 시 호출. 입장 횟수 소모. 실패 시 false.</summary>
    public bool TryEnter(DungeonData data)
    {
        if (data == null || !CanEnter(data.dungeonType)) return false;
        AddUsed(data.dungeonType, 1);
        _isDirty = true;
        OnEntriesChanged?.Invoke(data.dungeonType, GetRemainingEntries(data.dungeonType));
        return true;
    }

    /// <summary>던전 클리어 시 호출. 보상 지급 및 이벤트 발생.</summary>
    public void ClearDungeon(DungeonData data)
    {
        if (data == null) return;
        int reward = data.CalcReward();
        GiveReward(data.dungeonType, reward, data.stage);
        OnDungeonCleared?.Invoke(data.dungeonType, reward);
    }

    // ────────────────────────────────────────
    // Internal helpers
    // ────────────────────────────────────────

    int GetUsed(DungeonType type) => type switch
    {
        DungeonType.Hero  => _heroUsed,
        DungeonType.Mount => _mountUsed,
        DungeonType.Skill => _skillUsed,
        _                 => 0
    };

    void AddUsed(DungeonType type, int delta)
    {
        switch (type)
        {
            case DungeonType.Hero:  _heroUsed  = Mathf.Max(0, _heroUsed  + delta); break;
            case DungeonType.Mount: _mountUsed = Mathf.Max(0, _mountUsed + delta); break;
            case DungeonType.Skill: _skillUsed = Mathf.Max(0, _skillUsed + delta); break;
        }
    }

    void GiveReward(DungeonType type, int amount, int stage = 0)
    {
        switch (type)
        {
            case DungeonType.Hero:
                GemManager.Instance?.AddGem(amount);
                // 10단계 이상 영웅 던전: 각성석 추가 보상 (10단계당 1개)
                if (stage >= 10)
                {
                    int stones = stage / 10;
                    AwakeningStoneManager.Instance?.AddStone(stones);
                }
                break;
            case DungeonType.Mount: SummonStoneManager.Instance?.AddStone(amount);  break;
            case DungeonType.Skill: SpellScrollManager.Instance?.AddScroll(amount); break;
        }
    }

    // ────────────────────────────────────────
    // Save / lifecycle
    // ────────────────────────────────────────

    void Update()
    {
        if (!_isDirty) return;
        _saveTimer += Time.deltaTime;
        if (_saveTimer >= SAVE_INTERVAL) FlushSave();
    }

    void FlushSave()
    {
        if (!_isDirty) return;
        PlayerPrefs.SetInt(SaveKeys.DungeonHeroEntries,  _heroUsed);
        PlayerPrefs.SetInt(SaveKeys.DungeonMountEntries, _mountUsed);
        PlayerPrefs.SetInt(SaveKeys.DungeonSkillEntries, _skillUsed);
        PlayerPrefs.SetInt(SaveKeys.DungeonAdBonusCount, _adBonusUsed);
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
