#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

public class PresetCreator
{
    [MenuItem("Game/Create All Character Presets")]
    public static void CreateAllPresets()
    {
        string dir = "Assets/Data/Presets";
        if (!AssetDatabase.IsValidFolder("Assets/Data"))
            AssetDatabase.CreateFolder("Assets", "Data");
        if (!AssetDatabase.IsValidFolder(dir))
            AssetDatabase.CreateFolder("Assets/Data", "Presets");

        // ══════════════════════════════════════
        // ALLIES (7)
        // ══════════════════════════════════════

        CreatePreset(dir, "Ally_Swordsman", new CharacterPresetDef {
            name = "검사", rarity = HeroRarity.Common,
            body = "Human_1", eye = "Eye0", hair = "Hair_3",
            weapon = "Sword_1", armor = "Armor_1", helmet = "Helmet_1",
            hp = 120, atk = 25, def = 8, speed = 2f, range = 1.5f, cooldown = 0.9f,
            attackAnim = AttackAnimType.ShotSword
        });

        CreatePreset(dir, "Ally_Archer", new CharacterPresetDef {
            name = "궁수", rarity = HeroRarity.Common,
            body = "Human_2", eye = "Eye1", hair = "Hair_5",
            weapon = "Bow_1", cloth = "Cloth_7",
            hp = 80, atk = 30, def = 3, speed = 1.8f, range = 4f, cooldown = 1.2f,
            attackAnim = AttackAnimType.Bow
        });

        CreatePreset(dir, "Ally_Mage", new CharacterPresetDef {
            name = "마법사", rarity = HeroRarity.Rare,
            body = "Human_3", eye = "Eye2", hair = "Hair_7",
            weapon = "Ward_1", cloth = "Cloth_9", back = "Back_1",
            hp = 70, atk = 35, def = 2, speed = 1.5f, range = 5f, cooldown = 1.5f,
            attackAnim = AttackAnimType.Magic
        });

        CreatePreset(dir, "Ally_Knight", new CharacterPresetDef {
            name = "기사", rarity = HeroRarity.Rare,
            body = "Human_4", eye = "Eye3", hair = "Hair_1",
            weapon = "Sword_3", armor = "Armor_5", helmet = "Helmet_3", shield = "Shield_1",
            hp = 180, atk = 18, def = 15, speed = 1.6f, range = 1.5f, cooldown = 1.0f,
            attackAnim = AttackAnimType.Melee
        });

        CreatePreset(dir, "Ally_Lancer", new CharacterPresetDef {
            name = "창기사", rarity = HeroRarity.Epic,
            body = "Human_5", eye = "Eye4", hair = "Hair_2",
            weapon = "Spear_1", armor = "Armor_3", horse = "Horse1",
            hp = 150, atk = 32, def = 10, speed = 2.8f, range = 2f, cooldown = 0.8f,
            attackAnim = AttackAnimType.Spear
        });

        CreatePreset(dir, "Ally_Healer", new CharacterPresetDef {
            name = "사제", rarity = HeroRarity.Rare,
            body = "Human_2", eye = "Eye1", hair = "Hair_9",
            weapon = "Ward_1", cloth = "Cloth_7", back = "Back_1",
            hp = 90, atk = 10, def = 5, speed = 1.4f, range = 3f, cooldown = 2.0f,
            attackAnim = AttackAnimType.Magic,
            isHealer = true, healAmount = 40f, healCooldown = 3f, healRange = 4f
        });

        CreatePreset(dir, "Ally_Bard", new CharacterPresetDef {
            name = "음유시인", rarity = HeroRarity.Epic,
            body = "Elf_1", eye = "Eye2", hair = "Hair_6",
            weapon = "Ward_1", cloth = "Cloth_3",
            hp = 85, atk = 12, def = 4, speed = 1.6f, range = 3f, cooldown = 2.0f,
            attackAnim = AttackAnimType.Magic,
            isBuffer = true, buffAtkBonus = 8f, buffDefBonus = 4f,
            buffDuration = 6f, buffCooldown = 8f, buffRange = 5f
        });

        // ══════════════════════════════════════
        // ENEMIES - Grass Area (5)
        // ══════════════════════════════════════

        CreatePreset(dir, "Enemy_OrcWarrior", new CharacterPresetDef {
            name = "오크 전사", isEnemy = true, body = "Orc_1", eye = "Eye5",
            weapon = "Axe_1", armor = "Armor_4", helmet = "Helmet_6",
            bodyColor = new Color(0.6f, 0.8f, 0.5f),
            hp = 150, atk = 22, def = 10, speed = 1.5f, range = 1.5f, cooldown = 1.1f,
            attackAnim = AttackAnimType.Axe
        });

        CreatePreset(dir, "Enemy_Skeleton", new CharacterPresetDef {
            name = "해골 검사", isEnemy = true, body = "Skelton_1", eye = "Eye_Close",
            weapon = "Sword_3", helmet = "Helmet_8",
            hp = 90, atk = 20, def = 4, speed = 2.2f, range = 1.5f, cooldown = 0.8f,
            attackAnim = AttackAnimType.Melee
        });

        CreatePreset(dir, "Enemy_OrcArcher", new CharacterPresetDef {
            name = "오크 궁수", isEnemy = true, body = "Orc_2", eye = "Eye6",
            weapon = "Bow_1", cloth = "Cloth_9",
            bodyColor = new Color(0.5f, 0.7f, 0.4f),
            hp = 100, atk = 24, def = 3, speed = 1.6f, range = 4f, cooldown = 1.3f,
            attackAnim = AttackAnimType.Bow
        });

        CreatePreset(dir, "Enemy_SkeletonMage", new CharacterPresetDef {
            name = "해골 마법사", isEnemy = true, body = "Skelton_1", eye = "Eye_Close",
            weapon = "Ward_1", cloth = "Cloth_9", back = "Back_1",
            hp = 75, atk = 32, def = 2, speed = 1.4f, range = 5f, cooldown = 1.4f,
            attackAnim = AttackAnimType.Magic
        });

        CreatePreset(dir, "Enemy_OrcChief", new CharacterPresetDef {
            name = "오크 족장", isEnemy = true, body = "Orc_1", eye = "Eye5",
            weapon = "Axe_1", armor = "Armor_4", helmet = "Helmet_6",
            horse = "Horse1",
            bodyColor = new Color(0.5f, 0.7f, 0.4f),
            hp = 250, atk = 35, def = 15, speed = 2f, range = 1.5f, cooldown = 1.3f,
            attackAnim = AttackAnimType.Axe
        });

        // ══════════════════════════════════════
        // ENEMIES - Desert Area (4)
        // ══════════════════════════════════════

        CreatePreset(dir, "Enemy_Demon", new CharacterPresetDef {
            name = "악마", isEnemy = true, body = "Devil_1", eye = "Eye8",
            weapon = "Spear_1", armor = "Armor_5",
            bodyColor = new Color(0.8f, 0.4f, 0.4f),
            hp = 130, atk = 28, def = 6, speed = 2f, range = 2f, cooldown = 1.0f,
            attackAnim = AttackAnimType.Spear,
            element = DamageElement.Lightning, lightningResist = 0.3f
        });

        CreatePreset(dir, "Enemy_DarkKnight", new CharacterPresetDef {
            name = "흑기사", isEnemy = true, body = "Human_4", eye = "Eye3",
            weapon = "Sword_1", armor = "Armor_5", helmet = "Helmet_3",
            horse = "BlackHorse",
            bodyColor = new Color(0.5f, 0.5f, 0.6f),
            hp = 200, atk = 30, def = 12, speed = 2.5f, range = 1.8f, cooldown = 1.0f,
            attackAnim = AttackAnimType.ShotSword,
            element = DamageElement.Lightning, lightningResist = 0.4f
        });

        CreatePreset(dir, "Enemy_SandScorpion", new CharacterPresetDef {
            name = "사막 전갈", isEnemy = true, body = "Orc_3", eye = "Eye7",
            weapon = "Spear_1", cloth = "Cloth_5",
            bodyColor = new Color(0.85f, 0.7f, 0.4f),
            hp = 110, atk = 26, def = 8, speed = 2.3f, range = 1.8f, cooldown = 0.7f,
            attackAnim = AttackAnimType.Spear,
            element = DamageElement.Lightning, poisonResist = 0.2f
        });

        CreatePreset(dir, "Enemy_DesertMage", new CharacterPresetDef {
            name = "사막 마법사", isEnemy = true, body = "Human_5", eye = "Eye4",
            weapon = "Ward_1", cloth = "Cloth_3", back = "Back_1",
            bodyColor = new Color(0.9f, 0.8f, 0.5f),
            hp = 85, atk = 35, def = 3, speed = 1.5f, range = 5f, cooldown = 1.3f,
            attackAnim = AttackAnimType.Magic,
            element = DamageElement.Lightning
        });

        // ══════════════════════════════════════
        // ENEMIES - Cave Area (4)
        // ══════════════════════════════════════

        CreatePreset(dir, "Enemy_CaveGolem", new CharacterPresetDef {
            name = "동굴 골렘", isEnemy = true, body = "Orc_4", eye = "Eye_Close",
            weapon = "Hammer_1", armor = "Armor_4",
            bodyColor = new Color(0.5f, 0.5f, 0.55f),
            hp = 300, atk = 20, def = 20, speed = 1.0f, range = 1.5f, cooldown = 1.5f,
            attackAnim = AttackAnimType.Axe,
            element = DamageElement.Poison, poisonResist = 0.5f
        });

        CreatePreset(dir, "Enemy_CaveBat", new CharacterPresetDef {
            name = "동굴 박쥐", isEnemy = true, body = "Devil_1", eye = "Eye8",
            weapon = "Sword_1", cloth = "Cloth_5",
            bodyColor = new Color(0.4f, 0.3f, 0.5f),
            hp = 60, atk = 22, def = 2, speed = 3f, range = 1.5f, cooldown = 0.5f,
            attackAnim = AttackAnimType.Melee,
            element = DamageElement.Poison, poisonResist = 0.3f
        });

        CreatePreset(dir, "Enemy_RedRider", new CharacterPresetDef {
            name = "붉은 기병", isEnemy = true, body = "Human_5", eye = "Eye4",
            weapon = "Spear_1", armor = "Armor_3",
            horse = "RedHorse",
            hp = 180, atk = 26, def = 8, speed = 3f, range = 2f, cooldown = 0.9f,
            attackAnim = AttackAnimType.Spear,
            element = DamageElement.Poison, poisonResist = 0.4f
        });

        CreatePreset(dir, "Enemy_PoisonSpider", new CharacterPresetDef {
            name = "독거미", isEnemy = true, body = "Orc_2", eye = "Eye6",
            weapon = "Bow_1", cloth = "Cloth_9",
            bodyColor = new Color(0.3f, 0.6f, 0.3f),
            hp = 70, atk = 18, def = 3, speed = 2.5f, range = 4f, cooldown = 0.9f,
            attackAnim = AttackAnimType.Bow,
            element = DamageElement.Poison, poisonResist = 0.6f
        });

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        Debug.Log($"All character presets created in {dir}");
    }

    struct CharacterPresetDef
    {
        public string name;
        public bool isEnemy;
        public HeroRarity rarity;
        public string body, eye, hair, weapon, shield, helmet, armor, cloth, pant, back, horse;
        public Color bodyColor;
        public float hp, atk, def, speed, range, cooldown;
        public AttackAnimType attackAnim;
        // Element & resist
        public DamageElement element;
        public float lightningResist, poisonResist;
        // Support
        public bool isHealer;
        public float healAmount, healCooldown, healRange;
        public bool isBuffer;
        public float buffAtkBonus, buffDefBonus, buffDuration, buffCooldown, buffRange;
    }

    static void CreatePreset(string dir, string fileName, CharacterPresetDef def)
    {
        var preset = ScriptableObject.CreateInstance<CharacterPreset>();
        preset.characterName = def.name;
        preset.isEnemy = def.isEnemy;
        preset.rarity = def.rarity;
        preset.bodySprite = def.body;
        preset.bodyColor = def.bodyColor == default ? Color.white : def.bodyColor;
        preset.eyeSprite = def.eye;
        preset.eyeColor = new Color(0.28f, 0.1f, 0.1f, 1f);
        preset.hairSprite = def.hair ?? "";
        preset.weaponSprite = def.weapon ?? "";
        preset.shieldSprite = def.shield ?? "";
        preset.helmetSprite = def.helmet ?? "";
        preset.armorSprite = def.armor ?? "";
        preset.clothSprite = def.cloth ?? "";
        preset.pantSprite = def.pant ?? "";
        preset.backSprite = def.back ?? "";
        preset.horseSprite = def.horse ?? "";
        preset.maxHp = def.hp;
        preset.atk = def.atk;
        preset.def = def.def;
        preset.moveSpeed = def.speed;
        preset.attackRange = def.range;
        preset.attackCooldown = def.cooldown;
        preset.attackAnimType = def.attackAnim;
        preset.damageElement = def.element;
        preset.lightningResist = def.lightningResist;
        preset.poisonResist = def.poisonResist;

        // Support
        if (def.isHealer)
        {
            preset.isHealer = true;
            preset.healAmount = def.healAmount;
            preset.healCooldown = def.healCooldown;
            preset.healRange = def.healRange;
        }
        if (def.isBuffer)
        {
            preset.isBuffer = true;
            preset.buffAtkBonus = def.buffAtkBonus;
            preset.buffDefBonus = def.buffDefBonus;
            preset.buffDuration = def.buffDuration;
            preset.buffCooldown = def.buffCooldown;
            preset.buffRange = def.buffRange;
        }

        AssetDatabase.CreateAsset(preset, $"{dir}/{fileName}.asset");
    }
}
#endif
