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

    public EquipmentItem()
    {
        id = Guid.NewGuid().ToString();
        equippedTo = "";
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

    const string SAVE_KEY = "Equipment_Inventory";

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
        if (UnityEngine.Random.value > 0.30f) return;
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

    /// <summary>
    /// 영웅의 장비 총 보너스 HP
    /// </summary>
    public float GetTotalBonusHp(string heroName)
    {
        float total = 0f;
        for (int i = 0; i < inventory.Count; i++)
            if (inventory[i].equippedTo == heroName)
                total += inventory[i].bonusHp;
        return total;
    }

    /// <summary>
    /// 영웅의 장비 총 보너스 ATK
    /// </summary>
    public float GetTotalBonusAtk(string heroName)
    {
        float total = 0f;
        for (int i = 0; i < inventory.Count; i++)
            if (inventory[i].equippedTo == heroName)
                total += inventory[i].bonusAtk;
        return total;
    }

    /// <summary>
    /// 영웅의 장비 총 보너스 DEF
    /// </summary>
    public float GetTotalBonusDef(string heroName)
    {
        float total = 0f;
        for (int i = 0; i < inventory.Count; i++)
            if (inventory[i].equippedTo == heroName)
                total += inventory[i].bonusDef;
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

        // 이름
        string prefix = RARITY_PREFIX[rarity];
        string slotName = SLOT_NAME.TryGetValue(item.slot, out var sn) ? sn : "장비";
        item.itemName = $"{prefix} {slotName}";

        // 스탯 = base * rarity * areaLevel factor * 랜덤(0.8~1.2)
        float levelFactor = 1f + (areaLevel - 1) * 0.15f;
        float randomMult = UnityEngine.Random.Range(0.8f, 1.2f);

        // 슬롯별 주요 스탯 가중치
        switch (item.slot)
        {
            case EquipmentSlot.Weapon:
                item.bonusAtk = BASE_ATK * rarity * levelFactor * randomMult;
                item.bonusHp = BASE_HP * rarity * levelFactor * UnityEngine.Random.Range(0.8f, 1.2f) * 0.3f;
                item.bonusDef = 0f;
                break;
            case EquipmentSlot.Armor:
                item.bonusDef = BASE_DEF * rarity * levelFactor * randomMult;
                item.bonusHp = BASE_HP * rarity * levelFactor * UnityEngine.Random.Range(0.8f, 1.2f) * 0.5f;
                item.bonusAtk = 0f;
                break;
            default: // Shield 등
                item.bonusDef = BASE_DEF * rarity * levelFactor * randomMult * 0.7f;
                item.bonusHp = BASE_HP * rarity * levelFactor * UnityEngine.Random.Range(0.8f, 1.2f) * 0.4f;
                item.bonusAtk = BASE_ATK * rarity * levelFactor * UnityEngine.Random.Range(0.8f, 1.2f) * 0.2f;
                break;
        }

        return item;
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

        int goldReward = item.rarity * 50;
        inventory.Remove(item);
        SaveInventory();
        OnEquipmentChanged?.Invoke();

        GoldManager.Instance?.AddGold(goldReward);
        return goldReward;
    }

    /// <summary>
    /// 장비 강화: 같은 슬롯+등급 아이템 2개 소모 → 1등급 상승
    /// materialId를 소모하여 targetId의 등급을 올림
    /// </summary>
    public bool EnhanceItem(string targetId, string materialId)
    {
        var target = FindItem(targetId);
        var material = FindItem(materialId);
        if (target == null || material == null) return false;
        if (target.id == material.id) return false;
        if (target.rarity >= 5) return false; // 최대 등급
        if (target.slot != material.slot) return false; // 같은 슬롯만
        if (target.rarity != material.rarity) return false; // 같은 등급만
        if (!string.IsNullOrEmpty(material.equippedTo)) return false; // 재료 장착 중 불가

        // 등급 상승
        target.rarity++;
        float boost = 1.3f; // 30% 스탯 증가
        target.bonusHp *= boost;
        target.bonusAtk *= boost;
        target.bonusDef *= boost;

        // 이름 갱신
        string prefix = target.rarity <= 5 ? new[] { "", "낡은", "일반", "고급", "희귀", "전설" }[target.rarity] : "전설";
        string slotName = target.slot switch
        {
            EquipmentSlot.Weapon => "검",
            EquipmentSlot.Armor => "갑옷",
            EquipmentSlot.Shield => "방패",
            _ => "장비"
        };
        target.itemName = $"{prefix} {slotName}";

        // 재료 소모
        inventory.Remove(material);
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
        if (!saveDirty)
            saveTimer = SAVE_DEBOUNCE;
        saveDirty = true;
    }

    void Update()
    {
        if (!saveDirty) return;

        saveTimer -= Time.deltaTime;
        if (saveTimer <= 0f)
        {
            var data = new EquipmentInventoryData { items = inventory };
            string json = JsonUtility.ToJson(data);
            PlayerPrefs.SetString(SAVE_KEY, json);
            saveDirty = false;
        }
    }

    void OnApplicationPause(bool pause)
    {
        if (pause && saveDirty)
        {
            var data = new EquipmentInventoryData { items = inventory };
            PlayerPrefs.SetString(SAVE_KEY, JsonUtility.ToJson(data));
            PlayerPrefs.Save();
            saveDirty = false;
        }
    }

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
