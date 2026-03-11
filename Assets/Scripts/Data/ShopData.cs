using UnityEngine;

public enum ShopItemType { GoldBundle, SkillBox, EquipmentBox, GemPackage }

[System.Serializable]
public class ShopItem
{
    public string id;
    public string displayName;
    public string description;
    public ShopItemType type;
    public int gemCost;      // 0 if free/IAP
    public int goldCost;     // 0 if gem purchase
    public int rewardAmount;
    public bool isIAP;       // future real-money
    public float cooldownMinutes; // for free items
}
