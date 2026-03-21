using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// 광고 시스템 코어 — 보상형 광고(Rewarded Video)만 사용
/// testMode=true 시 실제 SDK 없이 콜백 즉시 호출 (개발/테스트용)
/// </summary>
public class AdManager : MonoBehaviour
{
    public static AdManager Instance { get; private set; }

    [Header("테스트 모드 (실제 SDK 없이 즉시 콜백)")]
    public bool testMode = true;

    // ─── 쿨타임 설정 (초) ───
    const float REWARDED_COOLDOWN     = 30f;
    const int   REWARDED_DAILY_MAX    = 10;  // 보상형 1종당 일일 최대 횟수

    // ─── 런타임 상태 ───
    readonly Dictionary<AdRewardType, float> rewardCooldowns = new();

    // ─── 이벤트 ───
    public event Action<AdRewardType>        OnRewardedAdCompleted;
    public event Action<AdRewardType, string> OnRewardedAdFailed;

    // ─────────────────────────────────────────────
    // 생명주기
    // ─────────────────────────────────────────────

    void Awake()
    {
        if (Instance != null) { Destroy(gameObject); return; }
        Instance = this;
        DontDestroyOnLoad(gameObject);
    }

    void Update()
    {
        float dt = Time.unscaledDeltaTime;

        var types = (AdRewardType[])Enum.GetValues(typeof(AdRewardType));
        for (int i = 0; i < types.Length; i++)
        {
            if (rewardCooldowns.TryGetValue(types[i], out float cd) && cd > 0)
                rewardCooldowns[types[i]] = Mathf.Max(0, cd - dt);
        }
    }

    // ─────────────────────────────────────────────
    // 보상형 광고
    // ─────────────────────────────────────────────

    /// <summary>
    /// 보상형 광고 표시. 성공 시 onComplete(true), 실패/스킵 시 onComplete(false).
    /// </summary>
    public void ShowRewardedAd(AdRewardType rewardType, Action<bool> onComplete)
    {
        if (!CanShowRewarded(rewardType))
        {
            float cd = GetRewardedCooldown(rewardType);
            string reason = cd > 0
                ? $"쿨타임 {Mathf.CeilToInt(cd)}초"
                : "오늘 횟수 초과";
            OnRewardedAdFailed?.Invoke(rewardType, reason);
            ToastNotification.Instance?.Show("광고 불가", reason, UnityEngine.Color.gray);
            onComplete?.Invoke(false);
            return;
        }

        if (testMode)
        {
            StartCoroutine(SimulateRewardedAd(rewardType, onComplete));
            return;
        }

        // TODO: 실제 SDK 연동 (AdMob / AppLovin 등)
        // AdSdk.ShowRewarded(rewardType.ToString(), (success) => OnRewardedResult(rewardType, success, onComplete));
        Debug.LogWarning("[AdManager] 실제 SDK 미연동 — testMode를 활성화하거나 SDK를 추가하세요.");
        onComplete?.Invoke(false);
    }

    IEnumerator SimulateRewardedAd(AdRewardType rewardType, Action<bool> onComplete)
    {
        // 테스트 모드: 0.5초 딜레이 후 성공 콜백
        yield return new WaitForSecondsRealtime(0.5f);
        OnRewardedResult(rewardType, success: true, onComplete);
    }

    void OnRewardedResult(AdRewardType rewardType, bool success, Action<bool> onComplete)
    {
        if (success)
        {
            rewardCooldowns[rewardType] = REWARDED_COOLDOWN;
            IncrementDailyCount(rewardType);
            SaveCooldown(rewardType);
            OnRewardedAdCompleted?.Invoke(rewardType);
        }
        else
        {
            OnRewardedAdFailed?.Invoke(rewardType, "광고 시청 취소");
        }
        onComplete?.Invoke(success);
    }

    // ─────────────────────────────────────────────
    // 쿨타임 / 일일 횟수 쿼리
    // ─────────────────────────────────────────────

    public float GetRewardedCooldown(AdRewardType type)
    {
        return rewardCooldowns.TryGetValue(type, out float cd) ? cd : 0f;
    }

    public bool CanShowRewarded(AdRewardType type)
    {
        if (GetRewardedCooldown(type) > 0) return false;
        return GetDailyCount(type) < REWARDED_DAILY_MAX;
    }

    public int GetDailyCount(AdRewardType type)
    {
        EnsureDailyReset();
        return PlayerPrefs.GetInt(SaveKeys.AdDailyCountPrefix + type, 0);
    }

    public int GetDailyMax() => REWARDED_DAILY_MAX;

    // ─────────────────────────────────────────────
    // 내부 헬퍼
    // ─────────────────────────────────────────────

    void IncrementDailyCount(AdRewardType type)
    {
        EnsureDailyReset();
        string key = SaveKeys.AdDailyCountPrefix + type;
        PlayerPrefs.SetInt(key, PlayerPrefs.GetInt(key, 0) + 1);
        PlayerPrefs.Save();
    }

    void EnsureDailyReset()
    {
        string today = System.DateTime.Today.ToString("yyyyMMdd");
        if (PlayerPrefs.GetString(SaveKeys.AdDailyResetDate, "") != today)
        {
            // 날짜가 바뀌었으면 일일 카운트 초기화
            var types = (AdRewardType[])Enum.GetValues(typeof(AdRewardType));
            for (int i = 0; i < types.Length; i++)
                PlayerPrefs.DeleteKey(SaveKeys.AdDailyCountPrefix + types[i]);
            PlayerPrefs.SetString(SaveKeys.AdDailyResetDate, today);
            PlayerPrefs.Save();
        }
    }

    void SaveCooldown(AdRewardType type)
    {
        PlayerPrefs.SetFloat(SaveKeys.AdCooldownPrefix + type, REWARDED_COOLDOWN);
        PlayerPrefs.Save();
    }

    void LoadCooldowns()
    {
        var types = (AdRewardType[])Enum.GetValues(typeof(AdRewardType));
        for (int i = 0; i < types.Length; i++)
        {
            float saved = PlayerPrefs.GetFloat(SaveKeys.AdCooldownPrefix + types[i], 0);
            if (saved > 0) rewardCooldowns[types[i]] = saved;
        }
    }

    void OnEnable() => LoadCooldowns();

    void OnApplicationQuit()
    {
        // 앱 종료 시 쿨타임 저장 (재시작 후 복원용)
        var types = (AdRewardType[])Enum.GetValues(typeof(AdRewardType));
        for (int i = 0; i < types.Length; i++)
        {
            float cd = GetRewardedCooldown(types[i]);
            if (cd > 0)
                PlayerPrefs.SetFloat(SaveKeys.AdCooldownPrefix + types[i], cd);
            else
                PlayerPrefs.DeleteKey(SaveKeys.AdCooldownPrefix + types[i]);
        }
        PlayerPrefs.Save();
    }
}
