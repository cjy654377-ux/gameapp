using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// 스킬 강화 시스템: 골드로 스킬 레벨업 → 데미지 증가 + 쿨타임 감소
/// </summary>
public class SkillUpgradeManager : MonoBehaviour
{
    public static SkillUpgradeManager Instance { get; private set; }

    public const int MAX_SKILL_LEVEL = 10;
    public const int BASE_UPGRADE_COST = 100;
    public const float COST_SCALE = 1.25f;
    public const float DAMAGE_PER_LEVEL = 0.12f;   // +12% per level
    public const float COOLDOWN_PER_LEVEL = 0.03f;  // -3% per level

    Dictionary<string, int> skillLevels = new();

    public event System.Action<string, int> OnSkillUpgraded;

    void Awake()
    {
        if (Instance != null) { Destroy(gameObject); return; }
        Instance = this;
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }

    public int GetLevel(string skillName)
    {
        if (string.IsNullOrEmpty(skillName)) return 1;
        if (!skillLevels.ContainsKey(skillName))
            skillLevels[skillName] = PlayerPrefs.GetInt(SaveKeys.SkillLevelPrefix + skillName, 1);
        return skillLevels[skillName];
    }

    public int GetUpgradeCost(string skillName)
    {
        int level = GetLevel(skillName);
        return Mathf.RoundToInt(BASE_UPGRADE_COST * Mathf.Pow(COST_SCALE, level - 1));
    }

    public bool CanUpgrade(string skillName)
    {
        if (string.IsNullOrEmpty(skillName)) return false;
        if (GetLevel(skillName) >= MAX_SKILL_LEVEL) return false;
        if (GoldManager.Instance == null) return false;
        return GoldManager.Instance.Gold >= GetUpgradeCost(skillName);
    }

    public bool TryUpgrade(string skillName)
    {
        if (!CanUpgrade(skillName)) return false;
        int cost = GetUpgradeCost(skillName);
        if (!GoldManager.Instance.SpendGold(cost)) return false;

        skillLevels[skillName] = GetLevel(skillName) + 1;
        PlayerPrefs.SetInt(SaveKeys.SkillLevelPrefix + skillName, skillLevels[skillName]);
        OnSkillUpgraded?.Invoke(skillName, skillLevels[skillName]);
        SoundManager.Instance?.PlayLevelUpSFX();
        return true;
    }

    /// <summary>
    /// 스킬 레벨에 따른 데미지 배율
    /// </summary>
    public float GetDamageMultiplier(string skillName)
    {
        int level = GetLevel(skillName);
        return 1f + (level - 1) * DAMAGE_PER_LEVEL;
    }

    /// <summary>
    /// 스킬 레벨에 따른 쿨타임 배율
    /// </summary>
    public float GetCooldownMultiplier(string skillName)
    {
        int level = GetLevel(skillName);
        return 1f - (level - 1) * COOLDOWN_PER_LEVEL;
    }
}
