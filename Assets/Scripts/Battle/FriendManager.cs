using UnityEngine;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// 로컬 가상 친구 시스템 (서버 없이 동작).
/// - 가상 친구 5명 자동 생성 (랜덤 이름 + 랜덤 영웅)
/// - 원군 요청: 전투 중 1회, 친구 영웅 1명 30초간 임시 소환
/// - 일일 친구 선물: 골드 100 수령
/// </summary>
public class FriendManager : MonoBehaviour
{
    public static FriendManager Instance { get; private set; }

    public class Friend
    {
        public string name;
        public string heroPresetName; // Resources/Presets/ 경로
        public int    level;
    }

    static readonly string[] FRIEND_NAMES = {
        "용사 레온", "마법사 실비아", "기사 토르", "궁수 아이리스", "성기사 발탄"
    };
    static readonly string[] HERO_PRESETS = {
        "Ally_Swordsman", "Ally_Mage", "Ally_Knight", "Ally_Archer", "Ally_Lancer"
    };

    public const int DAILY_GIFT_GOLD = 100;
    const float REINFORCEMENT_DURATION = 30f;

    readonly List<Friend> friends = new();

    public bool CanClaimGift         { get; private set; } = true;
    public bool CanCallReinforcement  { get; private set; } = true;

    public event System.Action OnStateChanged;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        InitFriends();
        LoadState();
        EnsureDailyReset();
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }

    // ─────────────────────────────────────────────
    // 퍼블릭 API
    // ─────────────────────────────────────────────

    public IReadOnlyList<Friend> GetFriends() => friends;

    /// <summary>일일 친구 선물 수령 (골드 100).</summary>
    public bool ClaimDailyGift()
    {
        if (!CanClaimGift) return false;

        GoldManager.Instance?.AddGold(DAILY_GIFT_GOLD);
        CanClaimGift = false;
        SaveState();
        OnStateChanged?.Invoke();

        ToastNotification.Instance?.Show("친구 선물!", $"골드 +{DAILY_GIFT_GOLD}", UIColors.Text_Gold);
        return true;
    }

    /// <summary>원군 요청: 랜덤 친구 영웅을 30초간 전투에 임시 소환.</summary>
    public bool RequestReinforcement()
    {
        if (!CanCallReinforcement) return false;

        CanCallReinforcement = false;
        SaveState();
        OnStateChanged?.Invoke();

        StartCoroutine(SpawnReinforcementRoutine());
        return true;
    }

    // ─────────────────────────────────────────────
    // 내부 헬퍼
    // ─────────────────────────────────────────────

    void InitFriends()
    {
        friends.Clear();
        for (int i = 0; i < FRIEND_NAMES.Length; i++)
        {
            friends.Add(new Friend
            {
                name          = FRIEND_NAMES[i],
                heroPresetName = HERO_PRESETS[i % HERO_PRESETS.Length],
                level         = Random.Range(5, 30),
            });
        }
    }

    IEnumerator SpawnReinforcementRoutine()
    {
        // 랜덤 친구 선택
        var friend = friends[Random.Range(0, friends.Count)];
        var preset = Resources.Load<CharacterPreset>($"Presets/{friend.heroPresetName}");
        if (preset == null)
        {
            Debug.LogWarning($"[FriendManager] 프리셋 없음: {friend.heroPresetName}");
            yield break;
        }

        // 아군 위치 근처에 소환
        var bm = BattleManager.Instance;
        Vector3 spawnPos = Vector3.zero;
        if (bm != null && bm.allyUnits.Count > 0)
            spawnPos = bm.allyUnits[0].transform.position + new Vector3(-1f, 0, 0);

        BattleUnit unit = null;
        var factory = CharacterFactory.Instance;
        if (factory != null)
            unit = factory.CreateCharacter(preset, spawnPos, BattleUnit.Team.Ally);

        if (unit != null)
        {
            ToastNotification.Instance?.Show(
                "원군 도착!",
                $"{friend.name}의 {friend.heroPresetName.Replace("Ally_", "")}이(가) 30초간 참전!",
                UIColors.Button_Blue);

            yield return new WaitForSeconds(REINFORCEMENT_DURATION);

            if (unit != null)
                Destroy(unit.gameObject);
        }
    }

    // ─────────────────────────────────────────────
    // 일일 리셋
    // ─────────────────────────────────────────────

    void EnsureDailyReset()
    {
        string today = System.DateTime.UtcNow.ToString("yyyy-MM-dd");

        if (PlayerPrefs.GetString(SaveKeys.FriendGiftDate, "") != today)
        {
            CanClaimGift = true;
            PlayerPrefs.SetString(SaveKeys.FriendGiftDate, today);
        }
        if (PlayerPrefs.GetString(SaveKeys.FriendReinforcementDate, "") != today)
        {
            CanCallReinforcement = true;
            PlayerPrefs.SetString(SaveKeys.FriendReinforcementDate, today);
        }
        PlayerPrefs.Save();
    }

    // ─────────────────────────────────────────────
    // 저장 / 불러오기
    // ─────────────────────────────────────────────

    void SaveState()
    {
        string today = System.DateTime.UtcNow.ToString("yyyy-MM-dd");
        if (!CanClaimGift)        PlayerPrefs.SetString(SaveKeys.FriendGiftDate,          today);
        if (!CanCallReinforcement) PlayerPrefs.SetString(SaveKeys.FriendReinforcementDate, today);
        PlayerPrefs.Save();
    }

    void LoadState()
    {
        // EnsureDailyReset에서 처리하므로 여기서는 별도 로드 불필요
    }
}
