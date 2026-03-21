using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// 보상형 광고 관리 (싱글톤).
/// testMode=true 시 실제 SDK 없이 콜백 즉시 호출.
/// </summary>
public class AdManager : MonoBehaviour
{
    public static AdManager Instance { get; private set; }

    /// <summary>테스트 모드: true면 광고 없이 바로 보상 지급</summary>
    public bool testMode = true;

    public enum AdRewardType
    {
        OfflineDouble,     // 오프라인 보상 2배 (접속당 1회)
        GoldBoost,         // 30분 골드 2배 (쿨타임 30분)
        FreeSummonHero,    // 무료 영웅 소환 (쿨타임 4시간)
        FreeSummonMount,   // 무료 탈것 소환 (쿨타임 4시간)
        FreeSummonSkill,   // 무료 스킬 소환 (쿨타임 4시간)
        DungeonEntry,      // 던전 추가 입장 (일 3회)
        Revive,            // 패배 시 부활 (전투당 1회)
        BossRewardDouble,  // 보스 보상 2배 (보스당 1회)
        DailyDouble,       // 출석 보상 2배 (일 1회)
        FreeGem,           // 무료 보석 (쿨타임 6시간)
        EnhanceRetry,      // 강화 재시도 (쿨타임 1시간)
    }

    // ─── 쿨타임 상수 (초) ───
    static readonly Dictionary<AdRewardType, float> CooldownSeconds = new()
    {
        { AdRewardType.GoldBoost,        30 * 60f  },
        { AdRewardType.FreeSummonHero,    4 * 3600f },
        { AdRewardType.FreeSummonMount,   4 * 3600f },
        { AdRewardType.FreeSummonSkill,   4 * 3600f },
        { AdRewardType.FreeGem,           6 * 3600f },
        { AdRewardType.EnhanceRetry,      1 * 3600f },
    };

    // ─── 일일 최대 횟수 ───
    static readonly Dictionary<AdRewardType, int> DailyMax = new()
    {
        { AdRewardType.DungeonEntry, 3 },
        { AdRewardType.DailyDouble,  1 },
    };

    // ─── 런타임 상태 ───
    readonly Dictionary<AdRewardType, float> cooldowns   = new();
    readonly Dictionary<AdRewardType, int>   dailyCounts = new();

    // 매 프레임 할당 방지용 캐시
    static readonly AdRewardType[] ALL_AD_TYPES = (AdRewardType[])System.Enum.GetValues(typeof(AdRewardType));

    // 세션/전투 단위 플래그 (ResetBattleAds / ResetBossAds 로 리셋)
    bool offlineDoubleUsed;
    bool reviveUsed;
    bool bossRewardUsed;

    // ─────────────────────────────────────────────
    // 생명주기
    // ─────────────────────────────────────────────

    void Awake()
    {
        if (Instance != null) { Destroy(gameObject); return; }
        Instance = this;
        DontDestroyOnLoad(gameObject);
        LoadState();
    }

    void Update()
    {
        if (cooldowns.Count == 0) return;
        float dt = Time.unscaledDeltaTime;
        for (int i = 0; i < ALL_AD_TYPES.Length; i++)
        {
            var type = ALL_AD_TYPES[i];
            if (!cooldowns.TryGetValue(type, out float remaining)) continue;
            remaining -= dt;
            if (remaining <= 0)
                cooldowns.Remove(type);
            else
                cooldowns[type] = remaining;
        }
    }

    // ─────────────────────────────────────────────
    // 퍼블릭 API
    // ─────────────────────────────────────────────

    /// <summary>보상형 광고 표시. 성공 시 onSuccess, 실패/불가 시 onFail 호출.</summary>
    public void ShowRewardedAd(AdRewardType type, Action onSuccess, Action onFail = null)
    {
        if (!IsAdAvailable(type))
        {
            string reason = GetUnavailableReason(type);
            ToastNotification.Instance?.Show("광고 불가", reason, Color.gray);
            onFail?.Invoke();
            return;
        }

        if (testMode)
        {
            StartCoroutine(TestRewardRoutine(type, onSuccess));
            return;
        }

        // TODO: 실제 SDK 연동 (AdMob / IronSource 등)
        Debug.LogWarning("[AdManager] 실제 SDK 미연동 — testMode를 켜거나 SDK를 추가하세요.");
        onFail?.Invoke();
    }

    /// <summary>해당 광고 타입이 현재 표시 가능한지 여부.</summary>
    public bool IsAdAvailable(AdRewardType type)
    {
        // 세션 플래그 체크
        if (type == AdRewardType.OfflineDouble   && offlineDoubleUsed) return false;
        if (type == AdRewardType.Revive          && reviveUsed)         return false;
        if (type == AdRewardType.BossRewardDouble && bossRewardUsed)    return false;

        // 쿨타임 체크
        if (cooldowns.ContainsKey(type)) return false;

        // 일일 횟수 체크
        if (DailyMax.TryGetValue(type, out int max))
        {
            EnsureDailyReset();
            int used = dailyCounts.TryGetValue(type, out int c) ? c : 0;
            if (used >= max) return false;
        }

        return true;
    }

    /// <summary>세션 시작 후 30분간 광고 버튼 초기 숨김 여부.</summary>
    public bool IsInitialHidePeriod() => Time.realtimeSinceStartup < 1800f;

    /// <summary>남은 쿨타임 문자열 "H:MM:SS" 또는 빈 문자열(사용 가능).</summary>
    public string GetCooldownText(AdRewardType type)
    {
        if (cooldowns.TryGetValue(type, out float remaining) && remaining > 0)
        {
            int h  = (int)(remaining / 3600);
            int m  = (int)(remaining % 3600 / 60);
            int s  = (int)(remaining % 60);
            return h > 0 ? $"{h}:{m:D2}:{s:D2}" : $"{m}:{s:D2}";
        }

        if (DailyMax.TryGetValue(type, out int max))
        {
            EnsureDailyReset();
            int used = dailyCounts.TryGetValue(type, out int c) ? c : 0;
            if (used >= max) return "내일 초기화";
        }

        if (type == AdRewardType.OfflineDouble   && offlineDoubleUsed) return "이미 사용";
        if (type == AdRewardType.Revive          && reviveUsed)         return "이미 사용";
        if (type == AdRewardType.BossRewardDouble && bossRewardUsed)    return "이미 사용";

        return "";
    }

    // ─────────────────────────────────────────────
    // 세션 리셋 (외부 호출용)
    // ─────────────────────────────────────────────

    /// <summary>새 전투 시작 시 호출 — Revive / OfflineDouble 리셋.</summary>
    public void ResetBattleAds()
    {
        reviveUsed        = false;
        offlineDoubleUsed = false;
    }

    /// <summary>보스 처치 후 호출 — BossRewardDouble 리셋.</summary>
    public void ResetBossAds()
    {
        bossRewardUsed = false;
    }

    // ─────────────────────────────────────────────
    // 내부 헬퍼
    // ─────────────────────────────────────────────

    IEnumerator TestRewardRoutine(AdRewardType type, Action onSuccess)
    {
        yield return new WaitForSecondsRealtime(0.3f); // 광고 시청 흉내
        ApplyConsumption(type);
        onSuccess?.Invoke();
    }

    void ApplyConsumption(AdRewardType type)
    {
        // 세션 플래그
        if (type == AdRewardType.OfflineDouble)   { offlineDoubleUsed = true; return; }
        if (type == AdRewardType.Revive)           { reviveUsed = true;         return; }
        if (type == AdRewardType.BossRewardDouble) { bossRewardUsed = true;     return; }

        // 쿨타임 등록
        if (CooldownSeconds.TryGetValue(type, out float cd))
        {
            cooldowns[type] = cd;
            SaveCooldown(type, cd);
        }

        // 일일 카운트 증가
        if (DailyMax.ContainsKey(type))
        {
            EnsureDailyReset();
            dailyCounts[type] = (dailyCounts.TryGetValue(type, out int c) ? c : 0) + 1;
            PlayerPrefs.SetInt(SaveKeys.AdDailyCountPrefix + type, dailyCounts[type]);
            PlayerPrefs.Save();
        }
    }

    string GetUnavailableReason(AdRewardType type)
    {
        string cd = GetCooldownText(type);
        if (!string.IsNullOrEmpty(cd)) return cd;
        return "사용 불가";
    }

    // ─── 저장/복원 ───

    void SaveCooldown(AdRewardType type, float seconds)
    {
        double expireAt = (DateTime.UtcNow + TimeSpan.FromSeconds(seconds))
                          .Subtract(new DateTime(1970, 1, 1)).TotalSeconds;
        PlayerPrefs.SetFloat(SaveKeys.AdCooldownPrefix + type, (float)expireAt);
        PlayerPrefs.Save();
    }

    void LoadState()
    {
        double nowEpoch = DateTime.UtcNow.Subtract(new DateTime(1970, 1, 1)).TotalSeconds;
        var types = (AdRewardType[])Enum.GetValues(typeof(AdRewardType));
        for (int i = 0; i < types.Length; i++)
        {
            float expireAt = PlayerPrefs.GetFloat(SaveKeys.AdCooldownPrefix + types[i], 0);
            if (expireAt > 0)
            {
                float remaining = (float)(expireAt - nowEpoch);
                if (remaining > 0) cooldowns[types[i]] = remaining;
            }
        }

        EnsureDailyReset();
        for (int i = 0; i < types.Length; i++)
        {
            if (DailyMax.ContainsKey(types[i]))
                dailyCounts[types[i]] = PlayerPrefs.GetInt(SaveKeys.AdDailyCountPrefix + types[i], 0);
        }
    }

    void EnsureDailyReset()
    {
        string today = DateTime.Today.ToString("yyyyMMdd");
        if (PlayerPrefs.GetString(SaveKeys.AdDailyResetDate, "") == today) return;

        var types = (AdRewardType[])Enum.GetValues(typeof(AdRewardType));
        for (int i = 0; i < types.Length; i++)
        {
            if (!DailyMax.ContainsKey(types[i])) continue;
            PlayerPrefs.DeleteKey(SaveKeys.AdDailyCountPrefix + types[i]);
            dailyCounts.Remove(types[i]);
        }
        PlayerPrefs.SetString(SaveKeys.AdDailyResetDate, today);
        PlayerPrefs.Save();
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }

    void OnApplicationQuit() => PersistCooldowns();
    void OnApplicationPause(bool pause) { if (pause) PersistCooldowns(); }

    void PersistCooldowns()
    {
        var types = (AdRewardType[])Enum.GetValues(typeof(AdRewardType));
        for (int i = 0; i < types.Length; i++)
        {
            if (cooldowns.TryGetValue(types[i], out float remaining) && remaining > 0)
                SaveCooldown(types[i], remaining);
            else
                PlayerPrefs.DeleteKey(SaveKeys.AdCooldownPrefix + types[i]);
        }
        PlayerPrefs.Save();
    }
}
