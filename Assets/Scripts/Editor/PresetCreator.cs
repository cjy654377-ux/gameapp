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

        // === Allies (3) ===
        CreatePreset(dir, "Ally_Swordsman", new CharacterPresetDef {
            name = "검사", body = "Human_1", eye = "Eye0", hair = "Hair_3",
            weapon = "Sword_1", armor = "Armor_1", helmet = "Helmet_1",
            hp = 120, atk = 25, def = 8, speed = 2f, range = 1.5f, cooldown = 0.9f,
            attackAnim = AttackAnimType.ShotSword
        });

        CreatePreset(dir, "Ally_Archer", new CharacterPresetDef {
            name = "궁수", body = "Human_2", eye = "Eye1", hair = "Hair_5",
            weapon = "Bow_1", cloth = "Cloth_7",
            hp = 80, atk = 30, def = 3, speed = 1.8f, range = 4f, cooldown = 1.2f,
            attackAnim = AttackAnimType.Bow
        });

        CreatePreset(dir, "Ally_Mage", new CharacterPresetDef {
            name = "마법사", body = "Human_3", eye = "Eye2", hair = "Hair_7",
            weapon = "Ward_1", cloth = "Cloth_9", back = "Back_1",
            hp = 70, atk = 35, def = 2, speed = 1.5f, range = 5f, cooldown = 1.5f,
            attackAnim = AttackAnimType.Magic
        });

        // === Enemies (8) ===
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

        CreatePreset(dir, "Enemy_Demon", new CharacterPresetDef {
            name = "악마", isEnemy = true, body = "Devil_1", eye = "Eye8",
            weapon = "Spear_1", armor = "Armor_5",
            bodyColor = new Color(0.8f, 0.4f, 0.4f),
            hp = 130, atk = 28, def = 6, speed = 2f, range = 2f, cooldown = 1.0f,
            attackAnim = AttackAnimType.Spear
        });

        CreatePreset(dir, "Enemy_OrcArcher", new CharacterPresetDef {
            name = "오크 궁수", isEnemy = true, body = "Orc_2", eye = "Eye6",
            weapon = "Bow_1", cloth = "Cloth_9",
            bodyColor = new Color(0.5f, 0.7f, 0.4f),
            hp = 100, atk = 24, def = 3, speed = 1.6f, range = 4f, cooldown = 1.3f,
            attackAnim = AttackAnimType.Bow
        });

        // --- New enemies ---
        CreatePreset(dir, "Enemy_DarkKnight", new CharacterPresetDef {
            name = "흑기사", isEnemy = true, body = "Human_4", eye = "Eye3",
            weapon = "Sword_1", armor = "Armor_5", helmet = "Helmet_3",
            horse = "BlackHorse",
            bodyColor = new Color(0.5f, 0.5f, 0.6f),
            hp = 200, atk = 30, def = 12, speed = 2.5f, range = 1.8f, cooldown = 1.0f,
            attackAnim = AttackAnimType.ShotSword
        });

        CreatePreset(dir, "Enemy_RedRider", new CharacterPresetDef {
            name = "붉은 기병", isEnemy = true, body = "Human_5", eye = "Eye4",
            weapon = "Spear_1", armor = "Armor_3",
            horse = "RedHorse",
            hp = 180, atk = 26, def = 8, speed = 3f, range = 2f, cooldown = 0.9f,
            attackAnim = AttackAnimType.Spear
        });

        CreatePreset(dir, "Enemy_SkeletonMage", new CharacterPresetDef {
            name = "해골 마법사", isEnemy = true, body = "Skelton_1", eye = "Eye_Close",
            weapon = "Ward_1", cloth = "Cloth_9", back = "Back_1",
            hp = 75, atk = 32, def = 2, speed = 1.4f, range = 5f, cooldown = 1.4f,
            attackAnim = AttackAnimType.Magic
        });

        CreatePreset(dir, "Enemy_OrcChief", new CharacterPresetDef {
            name = "오크 족장", isEnemy = true, body = "Orc_1", eye = "Eye5",
            weapon = "Hammer_1", armor = "Armor_4", helmet = "Helmet_6",
            horse = "Horse1",
            bodyColor = new Color(0.5f, 0.7f, 0.4f),
            hp = 250, atk = 35, def = 15, speed = 2f, range = 1.5f, cooldown = 1.3f,
            attackAnim = AttackAnimType.Axe
        });

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        Debug.Log("All character presets created in " + dir);
    }

    struct CharacterPresetDef
    {
        public string name;
        public bool isEnemy;
        public string body, eye, hair, weapon, shield, helmet, armor, cloth, pant, back, horse;
        public Color bodyColor;
        public float hp, atk, def, speed, range, cooldown;
        public AttackAnimType attackAnim;
    }

    static void CreatePreset(string dir, string fileName, CharacterPresetDef def)
    {
        var preset = ScriptableObject.CreateInstance<CharacterPreset>();
        preset.characterName = def.name;
        preset.isEnemy = def.isEnemy;
        preset.bodySprite = def.body;
        preset.bodyColor = def.bodyColor == default ? Color.white : def.bodyColor;
        preset.eyeSprite = def.eye;
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

        AssetDatabase.CreateAsset(preset, $"{dir}/{fileName}.asset");
    }
}
#endif
