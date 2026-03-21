using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// 8슬롯 덱 편성 관리
/// - roster: 보유한 모든 영웅 프리셋
/// - deck[0~7]: 전투에 출전하는 영웅 (null = 빈 슬롯)
/// - PlayerPrefs로 덱 구성 저장/로드
/// </summary>
public class DeckManager : MonoBehaviour
{
    public static DeckManager Instance { get; private set; }

    public const int MAX_DECK_SIZE = 8;

    [Header("All Hero Presets (drag all ally presets here)")]
    public List<CharacterPreset> roster = new();

    // 현재 덱 (최대 8)
    readonly CharacterPreset[] deck = new CharacterPreset[MAX_DECK_SIZE];

    public event System.Action OnDeckChanged;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }
    }

    bool initialized;

    /// <summary>
    /// roster 설정 후 호출. 자동으로 1회만 실행.
    /// </summary>
    public void Initialize()
    {
        if (initialized) return;
        initialized = true;
        LoadDeck();
    }

    void Start()
    {
        // 씬에 미리 배치된 경우 Start에서 초기화
        Initialize();
    }

    /// <summary>
    /// 덱 슬롯 반환 (읽기 전용)
    /// </summary>
    public CharacterPreset GetSlot(int index)
    {
        if (index < 0 || index >= MAX_DECK_SIZE) return null;
        return deck[index];
    }

    /// <summary>
    /// 덱에 들어있는 영웅 리스트 (null 제외)
    /// </summary>
    public List<CharacterPreset> GetActiveDeck()
    {
        var list = new List<CharacterPreset>();
        for (int i = 0; i < MAX_DECK_SIZE; i++)
            if (deck[i] != null) list.Add(deck[i]);
        return list;
    }

    /// <summary>
    /// 덱 슬롯 수 (null 포함)
    /// </summary>
    public int DeckCount
    {
        get
        {
            int count = 0;
            for (int i = 0; i < MAX_DECK_SIZE; i++)
                if (deck[i] != null) count++;
            return count;
        }
    }

    /// <summary>
    /// 영웅이 덱에 있는지
    /// </summary>
    public bool IsInDeck(CharacterPreset preset)
    {
        for (int i = 0; i < MAX_DECK_SIZE; i++)
            if (deck[i] == preset) return true;
        return false;
    }

    /// <summary>
    /// 덱에서 해당 영웅의 슬롯 인덱스 (-1이면 없음)
    /// </summary>
    public int GetSlotIndex(CharacterPreset preset)
    {
        for (int i = 0; i < MAX_DECK_SIZE; i++)
            if (deck[i] == preset) return i;
        return -1;
    }

    /// <summary>
    /// 빈 슬롯에 영웅 추가. 실패 시 false (덱 꽉 참 or 이미 있음)
    /// </summary>
    public bool AddToDeck(CharacterPreset preset)
    {
        if (IsInDeck(preset)) return false;

        for (int i = 0; i < MAX_DECK_SIZE; i++)
        {
            if (deck[i] == null)
            {
                deck[i] = preset;
                SaveDeck();
                OnDeckChanged?.Invoke();
                return true;
            }
        }
        return false; // 덱 풀
    }

    /// <summary>
    /// 슬롯에서 영웅 제거
    /// </summary>
    public void RemoveFromDeck(int slotIndex)
    {
        if (slotIndex < 0 || slotIndex >= MAX_DECK_SIZE) return;
        if (deck[slotIndex] == null) return;

        deck[slotIndex] = null;
        SaveDeck();
        OnDeckChanged?.Invoke();
    }

    /// <summary>
    /// 특정 슬롯에 영웅 배치 (기존 영웅은 제거됨)
    /// </summary>
    public void SetSlot(int slotIndex, CharacterPreset preset)
    {
        if (slotIndex < 0 || slotIndex >= MAX_DECK_SIZE) return;
        if (preset == null) { RemoveFromDeck(slotIndex); return; }

        // 이미 다른 슬롯에 있으면 그 슬롯 비우기
        int existingSlot = GetSlotIndex(preset);
        if (existingSlot >= 0)
            deck[existingSlot] = null;

        deck[slotIndex] = preset;
        SaveDeck();
        OnDeckChanged?.Invoke();
    }

    /// <summary>
    /// 두 슬롯 스왑
    /// </summary>
    public void SwapSlots(int a, int b)
    {
        if (a < 0 || a >= MAX_DECK_SIZE || b < 0 || b >= MAX_DECK_SIZE) return;
        (deck[a], deck[b]) = (deck[b], deck[a]);
        SaveDeck();
        OnDeckChanged?.Invoke();
    }

    // ═══════════════════════════════════════
    // SAVE / LOAD (PlayerPrefs, 프리셋 이름 기반)
    // ═══════════════════════════════════════

    void SaveDeck()
    {
        for (int i = 0; i < MAX_DECK_SIZE; i++)
        {
            string key = $"Deck_{i}";
            if (deck[i] != null)
                PlayerPrefs.SetString(key, deck[i].name);
            else
                PlayerPrefs.SetString(key, "");
        }
        PlayerPrefs.Save();
    }

    void LoadDeck()
    {
        bool hasAnyData = false;

        for (int i = 0; i < MAX_DECK_SIZE; i++)
        {
            string key = $"Deck_{i}";
            string presetName = PlayerPrefs.GetString(key, "");

            if (!string.IsNullOrEmpty(presetName))
            {
                deck[i] = FindPresetByName(presetName);
                if (deck[i] != null) hasAnyData = true;
            }
            else
            {
                deck[i] = null;
            }
        }

        // 첫 실행: 덱 데이터가 없으면 로스터 앞에서 자동 채우기
        if (!hasAnyData)
            InitDefaultDeck();
    }

    void InitDefaultDeck()
    {
        int count = Mathf.Min(roster.Count, MAX_DECK_SIZE);
        for (int i = 0; i < count; i++)
            deck[i] = roster[i];
        SaveDeck();
    }

    CharacterPreset FindPresetByName(string presetName)
    {
        for (int i = 0; i < roster.Count; i++)
            if (roster[i] != null && roster[i].name == presetName) return roster[i];
        return null;
    }

    // ═══════════════════════════════════════
    // PRESETS (3슬롯 저장/불러오기)
    // ═══════════════════════════════════════

    public const int MAX_PRESETS = 3;

    /// <summary>현재 덱을 프리셋 슬롯에 저장</summary>
    public void SavePreset(int slot)
    {
        if (slot < 0 || slot >= MAX_PRESETS) return;
        for (int i = 0; i < MAX_DECK_SIZE; i++)
        {
            string key = $"Preset_{slot}_{i}";
            PlayerPrefs.SetString(key, deck[i] != null ? deck[i].name : "");
        }
        PlayerPrefs.SetInt($"PresetSaved_{slot}", 1);
        PlayerPrefs.Save();
    }

    /// <summary>프리셋 슬롯을 현재 덱에 적용</summary>
    public bool LoadPreset(int slot)
    {
        if (slot < 0 || slot >= MAX_PRESETS) return false;
        if (!HasPreset(slot)) return false;

        for (int i = 0; i < MAX_DECK_SIZE; i++)
        {
            string name = PlayerPrefs.GetString($"Preset_{slot}_{i}", "");
            deck[i] = string.IsNullOrEmpty(name) ? null : FindPresetByName(name);
        }
        SaveDeck();
        OnDeckChanged?.Invoke();
        return true;
    }

    /// <summary>프리셋 슬롯에 저장된 데이터가 있는지 여부</summary>
    public bool HasPreset(int slot)
    {
        if (slot < 0 || slot >= MAX_PRESETS) return false;
        return PlayerPrefs.GetInt($"PresetSaved_{slot}", 0) == 1;
    }
}
