using UnityEngine;
using System;
using System.Collections.Generic;

public class ShopManager : MonoBehaviour
{
    public static ShopManager Instance { get; private set; }

    List<ShopItem> stockItems = new();

    public event Action<ShopItem> OnPurchased;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        InitStock();
    }

    void InitStock()
    {
        stockItems = new List<ShopItem>
        {
            new ShopItem
            {
                id = "gold_small",
                displayName = "소량 골드",
                description = "골드 100개를 획득합니다.",
                type = ShopItemType.GoldBundle,
                gemCost = 10,
                goldCost = 0,
                rewardAmount = 100,
                isIAP = false,
                cooldownMinutes = 0f
            },
            new ShopItem
            {
                id = "gold_large",
                displayName = "대량 골드",
                description = "골드 500개를 획득합니다.",
                type = ShopItemType.GoldBundle,
                gemCost = 40,
                goldCost = 0,
                rewardAmount = 500,
                isIAP = false,
                cooldownMinutes = 0f
            },
            new ShopItem
            {
                id = "skill_box",
                displayName = "스킬 상자",
                description = "랜덤 스킬 1개를 획득합니다.",
                type = ShopItemType.SkillBox,
                gemCost = 80,
                goldCost = 0,
                rewardAmount = 1,
                isIAP = false,
                cooldownMinutes = 0f
            },
            new ShopItem
            {
                id = "equip_box",
                displayName = "장비 상자",
                description = "랜덤 장비 1개를 획득합니다.",
                type = ShopItemType.EquipmentBox,
                gemCost = 60,
                goldCost = 0,
                rewardAmount = 1,
                isIAP = false,
                cooldownMinutes = 0f
            },
            new ShopItem
            {
                id = "free_gold",
                displayName = "무료 골드",
                description = "골드 50개를 무료로 획득합니다. (5분 쿨타임)",
                type = ShopItemType.GoldBundle,
                gemCost = 0,
                goldCost = 0,
                rewardAmount = 50,
                isIAP = false,
                cooldownMinutes = 5f
            }
        };
    }

    public List<ShopItem> GetStockItems() => stockItems;

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }

    public bool CanPurchase(ShopItem item)
    {
        if (item == null) return false;

        // Cooldown check
        if (item.cooldownMinutes > 0f)
        {
            string key = "ShopCooldown_" + item.id;
            string lastClaimStr = PlayerPrefs.GetString(key, "");
            if (!string.IsNullOrEmpty(lastClaimStr))
            {
                if (long.TryParse(lastClaimStr, out long lastTicks))
                {
                    var lastClaim = new DateTime(lastTicks);
                    double elapsed = (DateTime.UtcNow - lastClaim).TotalMinutes;
                    if (elapsed < item.cooldownMinutes)
                        return false;
                }
            }
        }

        // Currency check
        if (item.gemCost > 0)
        {
            if (GemManager.Instance == null || GemManager.Instance.Gem < item.gemCost)
                return false;
        }
        if (item.goldCost > 0)
        {
            if (GoldManager.Instance == null || GoldManager.Instance.Gold < item.goldCost)
                return false;
        }

        return true;
    }

    public bool Purchase(ShopItem item)
    {
        if (!CanPurchase(item)) return false;

        // Deduct currency
        if (item.gemCost > 0)
        {
            if (!GemManager.Instance.SpendGem(item.gemCost))
                return false;
        }
        if (item.goldCost > 0)
        {
            if (!GoldManager.Instance.SpendGold(item.goldCost))
                return false;
        }

        // Grant reward
        switch (item.type)
        {
            case ShopItemType.GoldBundle:
                GoldManager.Instance?.AddGold(item.rewardAmount);
                break;
            case ShopItemType.SkillBox:
                GrantRandomSkill(item.rewardAmount);
                break;
            case ShopItemType.EquipmentBox:
                if (EquipmentManager.Instance != null)
                {
                    for (int i = 0; i < item.rewardAmount; i++)
                    {
                        var equip = EquipmentManager.Instance.GenerateRandomEquipment(1);
                        EquipmentManager.Instance.AddItem(equip);
                    }
                }
                break;
            case ShopItemType.GemPackage:
                GemManager.Instance?.AddGem(item.rewardAmount);
                break;
        }

        // Record cooldown
        if (item.cooldownMinutes > 0f)
        {
            string key = "ShopCooldown_" + item.id;
            PlayerPrefs.SetString(key, DateTime.UtcNow.Ticks.ToString());
        }

        SoundManager.Instance?.PlayButtonSFX();
        OnPurchased?.Invoke(item);
        return true;
    }

    void GrantRandomSkill(int count)
    {
        var sm = SkillManager.Instance;
        if (sm == null) return;

        var allSkills = Resources.LoadAll<SkillData>("Skills");
        if (allSkills == null || allSkills.Length == 0) return;

        for (int i = 0; i < count; i++)
        {
            // 장착 중이 아닌 스킬 우선
            SkillData picked = null;
            for (int attempt = 0; attempt < 10; attempt++)
            {
                var candidate = allSkills[UnityEngine.Random.Range(0, allSkills.Length)];
                if (!sm.equippedSkills.Contains(candidate))
                {
                    picked = candidate;
                    break;
                }
            }
            if (picked == null) picked = allSkills[UnityEngine.Random.Range(0, allSkills.Length)];

            // 빈 슬롯에 장착, 없으면 최약 스킬 자동 교체
            if (sm.equippedSkills.Count < 4)
            {
                sm.equippedSkills.Add(picked);
                sm.SaveEquippedSkills();
                ToastNotification.Instance?.Show($"스킬 획득!", picked.skillName, UIColors.Text_Diamond);
            }
            else
            {
                // 가장 낮은 value 스킬을 교체
                int weakIdx = 0;
                float weakVal = float.MaxValue;
                for (int j = 0; j < sm.equippedSkills.Count; j++)
                {
                    if (sm.equippedSkills[j] != null && sm.equippedSkills[j].value < weakVal)
                    {
                        weakVal = sm.equippedSkills[j].value;
                        weakIdx = j;
                    }
                }
                if (picked.value > weakVal)
                {
                    string oldName = sm.equippedSkills[weakIdx].skillName;
                    sm.equippedSkills[weakIdx] = picked;
                    sm.SaveEquippedSkills();
                    ToastNotification.Instance?.Show($"스킬 교체!", $"{oldName} → {picked.skillName}", UIColors.Text_Diamond);
                }
                else
                {
                    // 스킬 업그레이드 재화로 전환
                    var sum = SkillUpgradeManager.Instance;
                    if (sum != null)
                    {
                        GoldManager.Instance?.AddGold(50);
                        ToastNotification.Instance?.Show($"스킬 분해", $"{picked.skillName} → +50 골드", UIColors.Text_Gold);
                    }
                }
            }
        }
    }

    /// <summary>
    /// Returns remaining cooldown in seconds, 0 if ready
    /// </summary>
    public float GetRemainingCooldown(ShopItem item)
    {
        if (item == null || item.cooldownMinutes <= 0f) return 0f;

        string key = "ShopCooldown_" + item.id;
        string lastClaimStr = PlayerPrefs.GetString(key, "");
        if (string.IsNullOrEmpty(lastClaimStr)) return 0f;

        if (long.TryParse(lastClaimStr, out long lastTicks))
        {
            var lastClaim = new DateTime(lastTicks);
            double elapsed = (DateTime.UtcNow - lastClaim).TotalSeconds;
            double cooldownSec = item.cooldownMinutes * 60.0;
            double remaining = cooldownSec - elapsed;
            return remaining > 0 ? (float)remaining : 0f;
        }
        return 0f;
    }
}
