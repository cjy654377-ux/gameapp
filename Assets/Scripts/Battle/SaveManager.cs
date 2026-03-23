using UnityEngine;
using System;
using System.Collections.Generic;

/// <summary>
/// 통합 세이브/로드 시스템
/// 기존 각 매니저의 PlayerPrefs 산재를 하나의 JSON으로 통합
/// 5초 디바운싱 + 앱 일시중지/종료 시 즉시 저장
/// </summary>
public class SaveManager : MonoBehaviour
{
    public static SaveManager Instance { get; private set; }

    const string SAVE_KEY         = "GameSaveData";
    const float  SAVE_DEBOUNCE    = 5f;
    const int    DECK_SLOT_COUNT  = 8;
    const float  DEFAULT_BGM_VOL  = 0.5f;
    const float  DEFAULT_SFX_VOL  = 0.7f;

    bool dirty;
    float saveTimer;

    void Awake()
    {
        if (Instance != null) { Destroy(gameObject); return; }
        Instance = this;
        DontDestroyOnLoad(gameObject);
    }

    /// <summary>
    /// 저장 필요 플래그 설정 (각 매니저에서 호출)
    /// </summary>
    public void MarkDirty()
    {
        dirty = true;
        saveTimer = SAVE_DEBOUNCE;
    }

    void Update()
    {
        if (!dirty) return;

        saveTimer -= Time.deltaTime;
        if (saveTimer <= 0f)
            FlushSave();
    }

    /// <summary>
    /// 즉시 저장 실행
    /// </summary>
    public void FlushSave()
    {
        if (!dirty) return;

        var data = GatherAllData();
        string json = JsonUtility.ToJson(data);
        PlayerPrefs.SetString(SAVE_KEY, json);
        PlayerPrefs.Save();
        dirty = false;
    }

    /// <summary>
    /// 모든 데이터 로드 + 각 매니저에 배포
    /// </summary>
    public void LoadAll()
    {
        string json = PlayerPrefs.GetString(SAVE_KEY, "");
        if (string.IsNullOrEmpty(json)) return;

        var data = JsonUtility.FromJson<GameSaveData>(json);
        if (data == null) return;

        DistributeData(data);
    }

    GameSaveData GatherAllData()
    {
        var data = new GameSaveData();

        // Gold
        if (GoldManager.Instance != null)
            data.gold = GoldManager.Instance.Gold;

        // Gem
        if (GemManager.Instance != null)
            data.gem = GemManager.Instance.Gem;

        // Stage
        if (StageManager.Instance != null)
            data.totalWaveIndex = StageManager.Instance.TotalWaveIndex;

        // Upgrades
        data.upgradeHp = PlayerPrefs.GetInt(SaveKeys.UpgradeHp, 0);
        data.upgradeAtk = PlayerPrefs.GetInt(SaveKeys.UpgradeAtk, 0);
        data.upgradeDef = PlayerPrefs.GetInt(SaveKeys.UpgradeDef, 0);
        data.tapDamageLevel = PlayerPrefs.GetInt(SaveKeys.TapDamageLevel, 1);

        // Sound
        data.bgmVolume = PlayerPrefs.GetFloat(SaveKeys.BgmVolume, DEFAULT_BGM_VOL);
        data.sfxVolume = PlayerPrefs.GetFloat(SaveKeys.SfxVolume, DEFAULT_SFX_VOL);

        // Offline
        data.lastPlayTime = PlayerPrefs.GetString(SaveKeys.LastPlayTime, "");

        // Equipment (already JSON)
        data.equipmentJson = PlayerPrefs.GetString(SaveKeys.EquipmentInventory, "");

        // Deck
        data.deckSlots = new string[DECK_SLOT_COUNT];
        for (int i = 0; i < DECK_SLOT_COUNT; i++)
            data.deckSlots[i] = PlayerPrefs.GetString(SaveKeys.DeckSlotPrefix + i, "");

        // Hero levels/copies - gather from HeroLevelManager
        if (HeroLevelManager.Instance != null)
        {
            var dm = DeckManager.Instance;
            if (dm != null)
            {
                data.heroData = new List<HeroSaveEntry>();
                for (int i = 0; i < dm.roster.Count; i++)
                {
                    if (dm.roster[i] == null) continue;
                    string name = dm.roster[i].characterName;
                    data.heroData.Add(new HeroSaveEntry
                    {
                        heroName = name,
                        level = HeroLevelManager.Instance.GetLevel(name),
                        copies = HeroLevelManager.Instance.GetCopies(name)
                    });
                }
            }
        }

        return data;
    }

    void DistributeData(GameSaveData data)
    {
        // 기존 PlayerPrefs 키에도 복원 (하위 호환)
        PlayerPrefs.SetInt(SaveKeys.Gold, data.gold);
        PlayerPrefs.SetInt(SaveKeys.Gem, data.gem);
        PlayerPrefs.SetInt(SaveKeys.TotalWaveIndex, data.totalWaveIndex);
        PlayerPrefs.SetInt(SaveKeys.UpgradeHp, data.upgradeHp);
        PlayerPrefs.SetInt(SaveKeys.UpgradeAtk, data.upgradeAtk);
        PlayerPrefs.SetInt(SaveKeys.UpgradeDef, data.upgradeDef);
        PlayerPrefs.SetInt(SaveKeys.TapDamageLevel, data.tapDamageLevel);
        PlayerPrefs.SetFloat(SaveKeys.BgmVolume, data.bgmVolume);
        PlayerPrefs.SetFloat(SaveKeys.SfxVolume, data.sfxVolume);

        if (!string.IsNullOrEmpty(data.lastPlayTime))
            PlayerPrefs.SetString(SaveKeys.LastPlayTime, data.lastPlayTime);

        if (!string.IsNullOrEmpty(data.equipmentJson))
            PlayerPrefs.SetString(SaveKeys.EquipmentInventory, data.equipmentJson);

        if (data.deckSlots != null)
        {
            for (int i = 0; i < data.deckSlots.Length && i < DECK_SLOT_COUNT; i++)
                PlayerPrefs.SetString(SaveKeys.DeckSlotPrefix + i, data.deckSlots[i]);
        }

        if (data.heroData != null)
        {
            for (int i = 0; i < data.heroData.Count; i++)
            {
                var h = data.heroData[i];
                PlayerPrefs.SetInt(SaveKeys.HeroLevelPrefix + h.heroName, h.level);
                PlayerPrefs.SetInt(SaveKeys.HeroCopiesPrefix + h.heroName, h.copies);
            }
        }
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
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

[Serializable]
public class GameSaveData
{
    public int gold;
    public int gem;
    public int totalWaveIndex;
    public int upgradeHp;
    public int upgradeAtk;
    public int upgradeDef;
    public int tapDamageLevel;
    public float bgmVolume;
    public float sfxVolume;
    public string lastPlayTime;
    public string equipmentJson;
    public string[] deckSlots;
    public List<HeroSaveEntry> heroData;
}

[Serializable]
public class HeroSaveEntry
{
    public string heroName;
    public int level;
    public int copies;
}
