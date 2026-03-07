using UnityEngine;

public enum AttackAnimType
{
    Melee,      // 0_Attack_Normal (검/기본)
    Axe,        // AxeAttack_1
    Spear,      // LongSpearAttack_1
    ShotSword,  // ShotSwordAttack_1
    Bow,        // 0_Attack_Bow
    Magic       // 0_Attack_Magic
}

[CreateAssetMenu(fileName = "NewCharacterPreset", menuName = "Game/Character Preset")]
public class CharacterPreset : ScriptableObject
{
    public string characterName;
    public bool isEnemy;

    [Header("Body")]
    public string bodySprite = "Human_1"; // Human_1~5, Orc_1~4, Skelton_1, Devil_1, Elf_1~2
    public Color bodyColor = Color.white;

    [Header("Eye")]
    public string eyeSprite = "Eye0";
    public Color eyeColor = new Color(0.28f, 0.1f, 0.1f, 1f);

    [Header("Hair")]
    public string hairSprite = "";
    public Color hairColor = Color.white;

    [Header("Equipment Sprites (SPUM Resource Paths)")]
    public string weaponSprite = "";
    public string shieldSprite = "";
    public string helmetSprite = "";
    public string armorSprite = "";
    public string clothSprite = "";
    public string pantSprite = "";
    public string backSprite = "";

    [Header("Mount")]
    public string horseSprite = ""; // BlackHorse, RedHorse, Horse1, Horse2

    [Header("Animation")]
    public AttackAnimType attackAnimType = AttackAnimType.Melee;

    [Header("Battle Stats")]
    public float maxHp = 100f;
    public float atk = 20f;
    public float def = 5f;
    public float moveSpeed = 2f;
    public float attackRange = 1.5f;
    public float attackCooldown = 1.0f;
}
