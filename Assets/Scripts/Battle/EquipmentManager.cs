using UnityEngine;
using System;
using System.Collections.Generic;

/// <summary>
/// 장비 아이템 인스턴스 (인벤토리에 저장되는 실체)
/// EquipmentData(ScriptableObject)와 별개로, 런타임에 생성되는 개별 아이템
/// </summary>
[System.Serializable]
public class EquipmentItem
{
    public string id;           // GUID
    public string itemName;
    public EquipmentSlot slot;  // EquipmentData.cs의 enum 재사용
    public int rarity;          // 1~5
    public float bonusHp;
    public float bonusAtk;
    public float bonusDef;
    public string equippedTo;   // heroName, empty if unequipped
    public string setId;        // 세트 ID (전사/마법사/수호자)
    public string weaponSprite; // SPUM 스프라이트 이름 (예: "Sword_3"), 외형 변경용

    public EquipmentItem()
    {
        id = Guid.NewGuid().ToString();
        equippedTo = "";
        setId = "";
    }
}

/// <summary>
/// JSON 직렬화용 래퍼
/// </summary>
[System.Serializable]
public class EquipmentInventoryData
{
    public List<EquipmentItem> items = new();
}

/// <summary>
/// 장비 관리 시스템
/// - 인벤토리 관리 (추가/장착/해제)
/// - 랜덤 장비 생성
/// - 영웅별 장비 스탯 합산
/// - PlayerPrefs JSON 저장
/// </summary>
public class EquipmentManager : MonoBehaviour
{
    public static EquipmentManager Instance { get; private set; }

    [SerializeField] List<EquipmentItem> inventory = new();

    public event Action OnEquipmentChanged;
    public event Action<EquipmentItem> OnEquipmentDropped;

    const string SAVE_KEY = SaveKeys.EquipmentInventory;

    // 랜덤 장비 생성용 상수
    static readonly float[] RARITY_THRESHOLDS = { 0.50f, 0.80f, 0.95f, 0.99f, 1.00f };
    // rarity 1~5 매핑: 50%, 30%, 15%, 4%, 1%

    static readonly string[] RARITY_PREFIX = { "", "낡은", "일반", "고급", "희귀", "전설" };
    // index 0은 미사용, 1~5

    static readonly Dictionary<EquipmentSlot, string> SLOT_NAME = new()
    {
        { EquipmentSlot.Weapon, "검" },
        { EquipmentSlot.Armor, "갑옷" },
        // Shield, Helmet 등 기존 EquipmentSlot enum도 대응
        { EquipmentSlot.Shield, "방패" },
        { EquipmentSlot.Helmet, "투구" },
        { EquipmentSlot.Cloth, "의복" },
        { EquipmentSlot.Back, "망토" },
    };

    // 기본 스탯 (장비 생성 시 base)
    const float BASE_HP = 20f;
    const float BASE_ATK = 5f;
    const float BASE_DEF = 3f;

    // 생성/드롭 상수
    const float DROP_CHANCE        = 0.30f;
    const float SET_ID_CHANCE      = 0.33f;
    const float LEVEL_SCALE_PER_AREA = 0.15f;
    const float STAT_RANDOM_MIN    = 0.8f;
    const float STAT_RANDOM_MAX    = 1.2f;
    const float ENHANCE_BOOST      = 1.3f;
    const int   DISMANTLE_GOLD_PER_RARITY = 50;

    // 강화 성공률 (rarity 1~4 기준, 5는 최대등급이라 강화 불가)
    static readonly float[] BASE_SUCCESS_RATE = { 0f, 1.0f, 0.90f, 0.75f, 0.55f, 0f };

    float _enhanceSuccessBonus;
    public bool LastEnhanceFailed { get; private set; }

    // 2세트 보너스
    const float SET2_WARRIOR_ATK   = 15f;
    const float SET2_MAGE_ATK      = 10f;
    const float SET2_MAGE_DEF      = 5f;
    const float SET2_GUARDIAN_DEF  = 12f;
    const float SET2_GUARDIAN_HP   = 30f;

    // 4세트 보너스
    const float SET4_WARRIOR_ATK   = 30f;
    const float SET4_MAGE_ATK      = 20f;
    const float SET4_MAGE_DEF      = 10f;
    const float SET4_GUARDIAN_DEF  = 25f;
    const float SET4_GUARDIAN_HP   = 80f;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        LoadInventory();
    }

    StageManager cachedStageMgr;

    void Start()
    {
        StartCoroutine(DeferredSubscribe());
    }

    System.Collections.IEnumerator DeferredSubscribe()
    {
        yield return null;
        cachedStageMgr = StageManager.Instance;
        if (cachedStageMgr != null)
        {
            cachedStageMgr.OnStageCleared += OnStageCleared;
            cachedStageMgr.OnBossSpawned += OnBossKilled;
        }
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
        if (cachedStageMgr != null)
        {
            cachedStageMgr.OnStageCleared -= OnStageCleared;
            cachedStageMgr.OnBossSpawned -= OnBossKilled;
        }
    }

    /// <summary>
    /// 스테이지 클리어 시 30% 확률로 장비 드롭 + 보스 드롭 처리
    /// </summary>
    void OnStageCleared(int waveIndex)
    {
        int area = cachedStageMgr != null ? cachedStageMgr.CurrentArea : 1;

        // 보스 추가 드롭 (스폰 시 플래그 → 스테이지 클리어 시 지급)
        if (bossDropPending > 0)
        {
            for (int i = 0; i < bossDropPending; i++)
            {
                var bossItem = GenerateRandomEquipment(area);
                AddItem(bossItem);
                ToastNotification.Instance?.Show($"보스 장비: {bossItem.itemName}", "");
            }
            bossDropPending = 0;
        }

        // 일반 웨이브 30% 확률 드롭
        if (UnityEngine.Random.value > DROP_CHANCE) return;
        var item = GenerateRandomEquipment(area);
        AddItem(item);
        ToastNotification.Instance?.Show($"장비 획득: {item.itemName}", "");
    }

    /// <summary>
    /// 보스 스폰 시 드롭 플래그 설정 (실제 드롭은 OnStageCleared에서)
    /// </summary>
    void OnBossKilled(bool isAreaBoss)
    {
        bossDropPending = isAreaBoss ? 2 : 1;
    }

    int bossDropPending;

    /// <summary>
    /// 읽기 전용 인벤토리
    /// </summary>
    public IReadOnlyList<EquipmentItem> Inventory => inventory;

    /// <summary>
    /// 아이템 추가
    /// </summary>
    public void AddItem(EquipmentItem item)
    {
        if (item == null) return;
        inventory.Add(item);
        SaveInventory();
        OnEquipmentChanged?.Invoke();
        OnEquipmentDropped?.Invoke(item);
        DailyMissionManager.Instance?.RegisterEquipDrop();
    }

    /// <summary>
    /// 아이템 장착 (heroName에 equip)
    /// 같은 슬롯에 이미 장착된 아이템이 있으면 해제 후 장착
    /// </summary>
    public bool EquipItem(string itemId, string heroName)
    {
        var item = FindItem(itemId);
        if (item == null) return false;

        // 같은 슬롯에 이미 장착된 아이템 해제
        for (int i = 0; i < inventory.Count; i++)
        {
            var other = inventory[i];
            if (other.equippedTo == heroName && other.slot == item.slot && other.id != itemId)
            {
                other.equippedTo = "";
            }
        }

        item.equippedTo = heroName;

        // 전투 중 SPUM 외형 갱신
        var bm = BattleManager.Instance;
        if (bm != null)
            foreach (var unit in bm.allyUnits)
                if (unit != null && unit.unitName == heroName) { unit.UpdateEquipmentVisual(item, true); break; }

        SaveInventory();
        OnEquipmentChanged?.Invoke();
        SoundManager.Instance?.PlayEquipSFX();
        return true;
    }

    /// <summary>
    /// 아이템 장착 해제
    /// </summary>
    public bool UnequipItem(string itemId)
    {
        var item = FindItem(itemId);
        if (item == null) return false;
        if (string.IsNullOrEmpty(item.equippedTo)) return false;

        // 전투 중 SPUM 외형 복원
        var bm = BattleManager.Instance;
        if (bm != null)
            foreach (var unit in bm.allyUnits)
                if (unit != null && unit.unitName == item.equippedTo) { unit.UpdateEquipmentVisual(item, false); break; }

        item.equippedTo = "";
        SaveInventory();
        OnEquipmentChanged?.Invoke();
        return true;
    }

    /// <summary>
    /// 특정 영웅에게 장착된 아이템 목록
    /// </summary>
    public List<EquipmentItem> GetEquippedItems(string heroName)
    {
        var result = new List<EquipmentItem>();
        for (int i = 0; i < inventory.Count; i++)
        {
            if (inventory[i].equippedTo == heroName)
                result.Add(inventory[i]);
        }
        return result;
    }

    public float GetTotalBonusHp(string heroName)  => GetTotalBonus(heroName, e => e.bonusHp);
    public float GetTotalBonusAtk(string heroName) => GetTotalBonus(heroName, e => e.bonusAtk);
    public float GetTotalBonusDef(string heroName) => GetTotalBonus(heroName, e => e.bonusDef);

    float GetTotalBonus(string heroName, System.Func<EquipmentItem, float> selector)
    {
        float total = 0f;
        for (int i = 0; i < inventory.Count; i++)
            if (inventory[i].equippedTo == heroName)
                total += selector(inventory[i]);
        return total;
    }

    /// <summary>
    /// 랜덤 장비 생성
    /// </summary>
    public EquipmentItem GenerateRandomEquipment(int areaLevel)
    {
        var item = new EquipmentItem();

        // rarity 결정
        float roll = UnityEngine.Random.value;
        int rarity = 1;
        float cumulative = 0f;
        for (int i = 0; i < RARITY_THRESHOLDS.Length; i++)
        {
            cumulative = RARITY_THRESHOLDS[i];
            if (roll < cumulative)
            {
                rarity = i + 1;
                break;
            }
        }
        item.rarity = rarity;

        // 슬롯 결정 (Weapon, Armor, Shield 중 랜덤 - 주요 3종)
        var slots = new EquipmentSlot[] { EquipmentSlot.Weapon, EquipmentSlot.Armor, EquipmentSlot.Shield };
        item.slot = slots[UnityEngine.Random.Range(0, slots.Length)];

        // 등급별 기본 스프라이트 이름 자동 배정
        item.weaponSprite = GetDefaultSpriteName(item.slot, rarity);

        // 이름
        string prefix = RARITY_PREFIX[rarity];
        string slotName = SLOT_NAME.TryGetValue(item.slot, out var sn) ? sn : "장비";
        item.itemName = $"{prefix} {slotName}";

        // 스탯 = base * rarity * areaLevel factor * 랜덤(0.8~1.2)
        float levelFactor = 1f + (areaLevel - 1) * LEVEL_SCALE_PER_AREA;
        float randomMult = UnityEngine.Random.Range(STAT_RANDOM_MIN, STAT_RANDOM_MAX);

        // 슬롯별 주요 스탯 가중치
        switch (item.slot)
        {
            case EquipmentSlot.Weapon:
                item.bonusAtk = BASE_ATK * rarity * levelFactor * randomMult;
                item.bonusHp  = BASE_HP  * rarity * levelFactor * UnityEngine.Random.Range(STAT_RANDOM_MIN, STAT_RANDOM_MAX) * 0.3f;
                item.bonusDef = 0f;
                break;
            case EquipmentSlot.Armor:
                item.bonusDef = BASE_DEF * rarity * levelFactor * randomMult;
                item.bonusHp  = BASE_HP  * rarity * levelFactor * UnityEngine.Random.Range(STAT_RANDOM_MIN, STAT_RANDOM_MAX) * 0.5f;
                item.bonusAtk = 0f;
                break;
            default: // Shield 등
                item.bonusDef = BASE_DEF * rarity * levelFactor * randomMult * 0.7f;
                item.bonusHp  = BASE_HP  * rarity * levelFactor * UnityEngine.Random.Range(STAT_RANDOM_MIN, STAT_RANDOM_MAX) * 0.4f;
                item.bonusAtk = BASE_ATK * rarity * levelFactor * UnityEngine.Random.Range(STAT_RANDOM_MIN, STAT_RANDOM_MAX) * 0.2f;
                break;
        }

        // 세트 ID 부여 (33% 확률)
        if (UnityEngine.Random.value < SET_ID_CHANCE)
        {
            string[] sets = { "전사", "마법사", "수호자" };
            item.setId = sets[UnityEngine.Random.Range(0, sets.Length)];
            item.itemName = $"{item.itemName} [{item.setId}]";
        }

        // 도감 등록
        CollectionManager.Instance?.RegisterEquipment(item.slot, item.rarity);

        return item;
    }

    // ═══ 세트 효과 ═══

    readonly Dictionary<string, int> setCountCache = new();

    /// <summary>
    /// 영웅의 세트 보너스 합산 (2세트/4세트 효과)
    /// </summary>
    public void GetSetBonuses(string heroName, out float bonusHp, out float bonusAtk, out float bonusDef)
    {
        bonusHp = 0f;
        bonusAtk = 0f;
        bonusDef = 0f;

        // 세트별 착용 수 카운트 (캐시 재사용)
        setCountCache.Clear();
        var setCounts = setCountCache;
        for (int i = 0; i < inventory.Count; i++)
        {
            var eq = inventory[i];
            if (eq.equippedTo != heroName || string.IsNullOrEmpty(eq.setId)) continue;
            if (!setCounts.ContainsKey(eq.setId)) setCounts[eq.setId] = 0;
            setCounts[eq.setId]++;
        }

        foreach (var kv in setCounts)
        {
            // 2세트 효과
            if (kv.Value >= 2)
            {
                switch (kv.Key)
                {
                    case "전사": bonusAtk += SET2_WARRIOR_ATK; break;
                    case "마법사": bonusAtk += SET2_MAGE_ATK; bonusDef += SET2_MAGE_DEF; break;
                    case "수호자": bonusDef += SET2_GUARDIAN_DEF; bonusHp += SET2_GUARDIAN_HP; break;
                }
            }
            // 4세트 효과
            if (kv.Value >= 4)
            {
                switch (kv.Key)
                {
                    case "전사": bonusAtk += SET4_WARRIOR_ATK; break;
                    case "마법사": bonusAtk += SET4_MAGE_ATK; bonusDef += SET4_MAGE_DEF; break;
                    case "수호자": bonusDef += SET4_GUARDIAN_DEF; bonusHp += SET4_GUARDIAN_HP; break;
                }
            }
        }
    }

    /// <summary>
    /// ID로 아이템 검색
    /// </summary>
    EquipmentItem FindItem(string itemId)
    {
        for (int i = 0; i < inventory.Count; i++)
            if (inventory[i].id == itemId) return inventory[i];
        return null;
    }

    /// <summary>
    /// 장비 분해: 아이템 삭제 후 골드 획득 (rarity * 50)
    /// </summary>
    public int DismantleItem(string itemId)
    {
        var item = FindItem(itemId);
        if (item == null) return 0;
        if (!string.IsNullOrEmpty(item.equippedTo)) return 0; // 장착 중이면 분해 불가

        int goldReward = item.rarity * DISMANTLE_GOLD_PER_RARITY;
        inventory.Remove(item);
        SaveInventory();
        OnEquipmentChanged?.Invoke();

        GoldManager.Instance?.AddGold(goldReward);
        return goldReward;
    }

    /// <summary>
    /// maxGrade 이하 비장착 장비를 전부 분해. (count, totalGold) 반환.
    /// </summary>
    public (int count, int totalGold) DismantleAll(int maxGrade = 2)
    {
        int count = 0, totalGold = 0;
        for (int i = inventory.Count - 1; i >= 0; i--)
        {
            var item = inventory[i];
            if (item.rarity > maxGrade) continue;
            if (!string.IsNullOrEmpty(item.equippedTo)) continue; // 장착 중 제외
            totalGold += item.rarity * DISMANTLE_GOLD_PER_RARITY;
            inventory.RemoveAt(i);
            count++;
        }
        if (count > 0)
        {
            GoldManager.Instance?.AddGold(totalGold);
            SaveInventory();
            OnEquipmentChanged?.Invoke();
        }
        return (count, totalGold);
    }

    /// <summary>
    /// maxGrade 이하 비장착 장비 수 및 예상 골드 미리보기.
    /// </summary>
    public (int count, int totalGold) PreviewDismantleAll(int maxGrade = 2)
    {
        int count = 0, totalGold = 0;
        for (int i = 0; i < inventory.Count; i++)
        {
            var item = inventory[i];
            if (item.rarity > maxGrade || !string.IsNullOrEmpty(item.equippedTo)) continue;
            totalGold += item.rarity * DISMANTLE_GOLD_PER_RARITY;
            count++;
        }
        return (count, totalGold);
    }

    /// <summary>
    /// 다음 강화 성공률을 boost만큼 높임 (광고 시청 보상)
    /// </summary>
    public void BoostNextEnhance(float boost = 0.20f)
    {
        _enhanceSuccessBonus = boost;
    }

    /// <summary>
    /// 강화 성공률 반환 (0~1)
    /// </summary>
    public float GetEnhanceSuccessRate(int rarity)
    {
        float rate = rarity >= 0 && rarity < BASE_SUCCESS_RATE.Length
            ? BASE_SUCCESS_RATE[rarity] : 0f;
        return Mathf.Clamp01(rate + _enhanceSuccessBonus);
    }

    /// <summary>
    /// 장비 강화: 같은 슬롯+등급 아이템 2개 소모 → 확률적으로 1등급 상승
    /// 실패 시 재료만 소모, LastEnhanceFailed = true
    /// 골드 비용: rarity * 100 (강화 레벨에 따라 증가)
    /// </summary>
    public bool EnhanceItem(string targetId, string materialId)
    {
        LastEnhanceFailed = false;
        var target = FindItem(targetId);
        var material = FindItem(materialId);
        if (target == null || material == null) return false;
        if (target.id == material.id) return false;
        if (target.rarity >= 5) return false; // 최대 등급
        if (target.slot != material.slot) return false; // 같은 슬롯만
        if (target.rarity != material.rarity) return false; // 같은 등급만
        if (!string.IsNullOrEmpty(material.equippedTo)) return false; // 재료 장착 중 불가

        // 강화 비용: 현재 등급 * 100
        int enhanceCost = target.rarity * 100;
        if (GoldManager.Instance == null || !GoldManager.Instance.SpendGold(enhanceCost))
            return false;

        float successRate = GetEnhanceSuccessRate(target.rarity);
        _enhanceSuccessBonus = 0f; // 보너스 소비

        bool success = UnityEngine.Random.value < successRate;

        // 재료는 성공/실패 무관하게 소모
        inventory.Remove(material);

        if (!success)
        {
            LastEnhanceFailed = true;
            SaveInventory();
            OnEquipmentChanged?.Invoke();
            return false;
        }

        // 등급 상승
        target.rarity++;
        target.bonusHp  *= ENHANCE_BOOST;
        target.bonusAtk *= ENHANCE_BOOST;
        target.bonusDef *= ENHANCE_BOOST;

        // 이름 갱신
        string prefix = target.rarity <= 5 ? RARITY_PREFIX[target.rarity] : "전설";
        string slotName = SLOT_NAME.TryGetValue(target.slot, out var sn) ? sn : "장비";
        target.itemName = string.IsNullOrEmpty(target.setId)
            ? $"{prefix} {slotName}"
            : $"{prefix} {slotName} [{target.setId}]";

        SaveInventory();
        OnEquipmentChanged?.Invoke();
        SoundManager.Instance?.PlayLevelUpSFX();
        return true;
    }

    /// <summary>
    /// 강화 가능한 재료 목록 (같은 슬롯+등급, 미장착, 자기 자신 제외)
    /// </summary>
    public List<EquipmentItem> GetEnhanceMaterials(string targetId)
    {
        var target = FindItem(targetId);
        var result = new List<EquipmentItem>();
        if (target == null || target.rarity >= 5) return result;

        for (int i = 0; i < inventory.Count; i++)
        {
            var other = inventory[i];
            if (other.id == targetId) continue;
            if (other.slot != target.slot) continue;
            if (other.rarity != target.rarity) continue;
            if (!string.IsNullOrEmpty(other.equippedTo)) continue;
            result.Add(other);
        }
        return result;
    }

    // ═══════════════════════════════════════
    // SAVE / LOAD (PlayerPrefs JSON)
    // ═══════════════════════════════════════

    bool saveDirty;
    float saveTimer;
    const float SAVE_DEBOUNCE = 5f;

    void SaveInventory()
    {
        saveDirty = true;
        saveTimer = SAVE_DEBOUNCE;
    }

    void Update()
    {
        if (!saveDirty) return;

        saveTimer -= Time.deltaTime;
        if (saveTimer <= 0f)
        {
            FlushSave();
        }
    }

    void FlushSave()
    {
        if (!saveDirty) return;
        var data = new EquipmentInventoryData { items = inventory };
        PlayerPrefs.SetString(SAVE_KEY, JsonUtility.ToJson(data));
        PlayerPrefs.Save();
        saveDirty = false;
    }

    void OnApplicationPause(bool pause)
    {
        if (pause) FlushSave();
    }

    void OnApplicationQuit()
    {
        FlushSave();
    }

    /// <summary>
    /// 슬롯과 등급으로 기본 SPUM 스프라이트 이름 반환
    /// </summary>
    static string GetDefaultSpriteName(EquipmentSlot slot, int rarity) => slot switch
    {
        EquipmentSlot.Weapon => rarity switch { 1 => "Sword", 2 => "Sword_2", 3 => "Sword_3", _ => "Sword_4" },
        EquipmentSlot.Shield => rarity switch { 1 => "Shield", 2 => "Shield_2", 3 => "Shield_3", _ => "Shield_4" },
        EquipmentSlot.Armor  => rarity switch { 1 => "Armor1", 2 => "Armor2", 3 => "Armor3", _ => "Armor4" },
        EquipmentSlot.Helmet => rarity switch { 1 => "Helm1", 2 => "Helm2", 3 => "Helm3", _ => "Helm4" },
        _ => ""
    };

    void LoadInventory()
    {
        string json = PlayerPrefs.GetString(SAVE_KEY, "");
        if (!string.IsNullOrEmpty(json))
        {
            var data = JsonUtility.FromJson<EquipmentInventoryData>(json);
            if (data != null && data.items != null)
                inventory = data.items;
        }
    }
}
