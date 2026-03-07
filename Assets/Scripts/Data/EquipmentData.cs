using UnityEngine;

public enum EquipmentSlot
{
    Weapon,
    Shield,
    Helmet,
    Armor,
    Cloth,
    Back
}

public enum WeaponType
{
    Sword, Axe, Bow, Shield, Spear, Wand, Hammer, Dagger, Mace
}

public enum Rarity
{
    Common,
    Uncommon,
    Rare,
    Epic,
    Legendary
}

[CreateAssetMenu(fileName = "NewEquipment", menuName = "Game/Equipment Data")]
public class EquipmentData : ScriptableObject
{
    public string equipmentName;
    public EquipmentSlot slot;
    public WeaponType weaponType;
    public Rarity rarity;

    [Header("Sprites")]
    public string spritePath; // SPUM Resources path
    public Sprite icon;

    [Header("Stats")]
    public float atkBonus;
    public float defBonus;
    public float hpBonus;
    public float speedBonus;

    [Header("Gacha")]
    [Range(0f, 100f)]
    public float dropRate = 10f;
}
