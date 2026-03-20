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
            name = "검사", rarity = StarGrade.Star1,
            body = "Human_1", eye = "Eye0", hair = "Hair_3",
            weapon = "Sword_1", shield = "Sword_2", armor = "Armor_1",
            hp = 120, atk = 25, def = 8, speed = 2f, range = 1.5f, cooldown = 0.9f,
            attackAnim = AttackAnimType.ShotSword
        });

        CreatePreset(dir, "Ally_Archer", new CharacterPresetDef {
            name = "궁수", rarity = StarGrade.Star1,
            body = "Human_2", eye = "Eye1", hair = "Hair_5",
            weapon = "Bow_1", cloth = "Cloth_7",
            hp = 80, atk = 30, def = 3, speed = 1.8f, range = 4f, cooldown = 1.2f,
            attackAnim = AttackAnimType.Bow
        });

        CreatePreset(dir, "Ally_Mage", new CharacterPresetDef {
            name = "마법사", rarity = StarGrade.Star2,
            body = "Human_3", eye = "Eye2", hair = "Hair_7",
            weapon = "Ward_1", cloth = "Cloth_9", back = "Back_1",
            hp = 70, atk = 35, def = 2, speed = 1.5f, range = 5f, cooldown = 1.5f,
            attackAnim = AttackAnimType.Magic
        });

        CreatePreset(dir, "Ally_Knight", new CharacterPresetDef {
            name = "기사", rarity = StarGrade.Star3,
            body = "Human_4", eye = "Eye3", hair = "Hair_1",
            weapon = "Sword_3", armor = "Armor_5", helmet = "Helmet_3", shield = "Shield_1",
            hp = 180, atk = 18, def = 15, speed = 1.6f, range = 1.5f, cooldown = 1.0f,
            attackAnim = AttackAnimType.Melee
        });

        CreatePreset(dir, "Ally_Lancer", new CharacterPresetDef {
            name = "창기사", rarity = StarGrade.Star4,
            body = "Human_5", eye = "Eye4", hair = "Hair_2",
            weapon = "Spear_1", armor = "Armor_3", horse = "Horse1",
            hp = 150, atk = 32, def = 10, speed = 2.8f, range = 2f, cooldown = 0.8f,
            attackAnim = AttackAnimType.Spear
        });

        CreatePreset(dir, "Ally_Healer", new CharacterPresetDef {
            name = "사제", rarity = StarGrade.Star2,
            body = "Human_2", eye = "Eye1", hair = "Hair_9",
            weapon = "Ward_1", cloth = "Cloth_7", back = "Back_1",
            hp = 90, atk = 10, def = 5, speed = 1.4f, range = 3f, cooldown = 2.0f,
            attackAnim = AttackAnimType.Magic,
            isHealer = true, healAmount = 40f, healCooldown = 3f, healRange = 4f
        });

        CreatePreset(dir, "Ally_Bard", new CharacterPresetDef {
            name = "음유시인", rarity = StarGrade.Star3,
            body = "Elf_1", eye = "Eye2", hair = "Hair_6",
            weapon = "Ward_1", cloth = "Cloth_3",
            hp = 85, atk = 12, def = 4, speed = 1.6f, range = 3f, cooldown = 2.0f,
            attackAnim = AttackAnimType.Magic,
            isBuffer = true, buffAtkBonus = 8f, buffDefBonus = 4f,
            buffDuration = 6f, buffCooldown = 8f, buffRange = 5f
        });

        // ══════════════════════════════════════════════════
        // ENEMIES - Area 1: 초원 (Grassland) - 8종
        // ══════════════════════════════════════════════════

        // ★1 일반몹
        CreatePreset(dir, "Enemy_SkeletonSoldier", new CharacterPresetDef {
            name = "해골 졸병", isEnemy = true, body = "Skelton_1", eye = "Eye_Close",
            weapon = "Sword_1", shield = "Sword_2", cloth = "Cloth_10",
            hp = 80, atk = 15, def = 3, speed = 1.8f, range = 1.5f, cooldown = 1.0f,
            attackAnim = AttackAnimType.Melee
        });

        CreatePreset(dir, "Enemy_OrcScout", new CharacterPresetDef {
            name = "오크 보초", isEnemy = true, body = "Orc_1", eye = "Eye5",
            weapon = "Axe_1", cloth = "Cloth_4",
            bodyColor = new Color(0.6f, 0.8f, 0.5f),
            hp = 100, atk = 18, def = 5, speed = 1.6f, range = 1.5f, cooldown = 1.1f,
            attackAnim = AttackAnimType.Axe
        });

        CreatePreset(dir, "Enemy_ZombieWanderer", new CharacterPresetDef {
            name = "좀비 방랑자", isEnemy = true, body = "Human_1", eye = "Eye_Close",
            weapon = "Sword_4", shield = "Sword_1", cloth = "Cloth_11",
            bodyColor = new Color(0.5f, 0.7f, 0.5f),
            hp = 120, atk = 12, def = 2, speed = 1.2f, range = 1.5f, cooldown = 1.3f,
            attackAnim = AttackAnimType.Melee
        });

        CreatePreset(dir, "Enemy_SkeletonArcher", new CharacterPresetDef {
            name = "해골 궁수", isEnemy = true, body = "Skelton_1", eye = "Eye_Close",
            weapon = "Bow_1", cloth = "Cloth_7",
            hp = 60, atk = 20, def = 2, speed = 1.5f, range = 4f, cooldown = 1.2f,
            attackAnim = AttackAnimType.Bow
        });

        // ★2 강화 일반몹
        CreatePreset(dir, "Enemy_OrcWarrior", new CharacterPresetDef {
            name = "오크 전사", isEnemy = true, body = "Orc_2", eye = "Eye6",
            weapon = "Sword_2", armor = "Armor_1", shield = "Shield_1",
            bodyColor = new Color(0.6f, 0.8f, 0.5f),
            hp = 150, atk = 22, def = 10, speed = 1.5f, range = 1.5f, cooldown = 1.0f,
            attackAnim = AttackAnimType.ShotSword
        });

        CreatePreset(dir, "Enemy_SkeletonKnight", new CharacterPresetDef {
            name = "해골 전사", isEnemy = true, body = "Skelton_1", eye = "Eye_Close",
            weapon = "Sword_3", armor = "Armor_2", shield = "Shield_1",
            hp = 130, atk = 20, def = 12, speed = 1.4f, range = 1.5f, cooldown = 1.1f,
            attackAnim = AttackAnimType.ShotSword
        });

        // ★3 중간보스
        CreatePreset(dir, "Enemy_UndeadGeneral", new CharacterPresetDef {
            name = "언데드 장군", isEnemy = true, body = "Skelton_1", eye = "Eye_Close",
            weapon = "Sword_5", armor = "Armor_4", helmet = "Helmet_3", back = "Back_2",
            hp = 400, atk = 35, def = 15, speed = 1.6f, range = 1.8f, cooldown = 1.0f,
            attackAnim = AttackAnimType.ShotSword
        });

        // ★4 에리어 보스
        CreatePreset(dir, "Enemy_OrcChieftain", new CharacterPresetDef {
            name = "오크 족장", isEnemy = true, body = "Orc_1", eye = "Eye5",
            weapon = "Axe_1", armor = "Armor_5", helmet = "Helmet_4", back = "Soon_Back1",
            horse = "Horse1",
            bodyColor = new Color(0.5f, 0.7f, 0.4f),
            hp = 800, atk = 45, def = 20, speed = 2f, range = 1.5f, cooldown = 1.2f,
            attackAnim = AttackAnimType.Axe
        });

        // ══════════════════════════════════════════════════
        // ENEMIES - Area 2: 사막 (Desert) - 8종
        // ══════════════════════════════════════════════════

        // ★1
        CreatePreset(dir, "Enemy_DesertSkeleton", new CharacterPresetDef {
            name = "사막 해골 검사", isEnemy = true, body = "Skelton_1", eye = "Eye_Close",
            weapon = "Sword_1", shield = "Sword_3", cloth = "Cloth_5",
            bodyColor = new Color(0.9f, 0.85f, 0.7f),
            hp = 90, atk = 18, def = 4, speed = 1.9f, range = 1.5f, cooldown = 1.0f,
            attackAnim = AttackAnimType.Melee,
            element = DamageElement.Lightning
        });

        CreatePreset(dir, "Enemy_DesertOrc", new CharacterPresetDef {
            name = "사막 오크 검사", isEnemy = true, body = "Orc_3", eye = "Eye7",
            weapon = "Sword_2", shield = "Sword_4", cloth = "Cloth_6",
            bodyColor = new Color(0.85f, 0.7f, 0.4f),
            hp = 110, atk = 20, def = 6, speed = 1.7f, range = 1.5f, cooldown = 1.0f,
            attackAnim = AttackAnimType.Melee,
            element = DamageElement.Lightning, lightningResist = 0.2f
        });

        CreatePreset(dir, "Enemy_MummySoldier", new CharacterPresetDef {
            name = "미라 졸병", isEnemy = true, body = "Human_3", eye = "Eye_Close",
            weapon = "Sword_1", shield = "Sword_2", cloth = "Cloth_10",
            bodyColor = new Color(0.8f, 0.75f, 0.6f),
            hp = 130, atk = 16, def = 3, speed = 1.3f, range = 1.5f, cooldown = 1.2f,
            attackAnim = AttackAnimType.Melee,
            poisonResist = 0.3f
        });

        CreatePreset(dir, "Enemy_DesertGhost", new CharacterPresetDef {
            name = "사막 유령", isEnemy = true, body = "Elf_2", eye = "Eye8",
            weapon = "Ward_1", cloth = "Cloth_3",
            bodyColor = new Color(0.9f, 0.9f, 0.7f),
            hp = 55, atk = 25, def = 1, speed = 2.2f, range = 4f, cooldown = 1.3f,
            attackAnim = AttackAnimType.Magic,
            element = DamageElement.Lightning, lightningResist = 0.5f
        });

        // ★2
        CreatePreset(dir, "Enemy_DesertDarkKnight", new CharacterPresetDef {
            name = "사막 전사", isEnemy = true, body = "Human_3", eye = "Eye3",
            weapon = "Sword_6", armor = "Armor_5", shield = "Shield_1",
            bodyColor = new Color(0.8f, 0.75f, 0.6f),
            hp = 180, atk = 28, def = 12, speed = 1.8f, range = 1.8f, cooldown = 1.0f,
            attackAnim = AttackAnimType.ShotSword,
            element = DamageElement.Lightning, lightningResist = 0.4f
        });

        CreatePreset(dir, "Enemy_MummyMage", new CharacterPresetDef {
            name = "미라 법사", isEnemy = true, body = "Human_5", eye = "Eye_Close",
            weapon = "Ward_1", cloth = "Cloth_9", back = "Back_1",
            bodyColor = new Color(0.8f, 0.75f, 0.6f),
            hp = 100, atk = 35, def = 3, speed = 1.5f, range = 5f, cooldown = 1.3f,
            attackAnim = AttackAnimType.Magic,
            element = DamageElement.Lightning
        });

        // ★3 중간보스
        CreatePreset(dir, "Enemy_DesertGuardian", new CharacterPresetDef {
            name = "사막 수호자", isEnemy = true, body = "Orc_4", eye = "Eye7",
            weapon = "Soon_Spear", armor = "Armor_6", helmet = "Helmet_9", shield = "Shield_1",
            bodyColor = new Color(0.85f, 0.7f, 0.4f),
            hp = 500, atk = 38, def = 18, speed = 1.5f, range = 2f, cooldown = 1.1f,
            attackAnim = AttackAnimType.Spear,
            element = DamageElement.Lightning, lightningResist = 0.5f
        });

        // ★4 에리어 보스
        CreatePreset(dir, "Enemy_PharaohUndead", new CharacterPresetDef {
            name = "파라오 언데드", isEnemy = true, body = "Skelton_1", eye = "Eye_Close",
            weapon = "Ward_1", armor = "Armor_8", helmet = "F_SR_Helmet", back = "Soon_Back1",
            horse = "Horse2",
            hp = 1000, atk = 50, def = 22, speed = 1.8f, range = 5f, cooldown = 1.5f,
            attackAnim = AttackAnimType.Magic,
            element = DamageElement.Lightning, lightningResist = 0.6f
        });

        // ══════════════════════════════════════════════════
        // ENEMIES - Area 3: 동굴 (Cave) - 8종
        // ══════════════════════════════════════════════════

        // ★1
        CreatePreset(dir, "Enemy_CaveSkeleton", new CharacterPresetDef {
            name = "동굴 해골 검사", isEnemy = true, body = "Skelton_1", eye = "Eye_Close",
            weapon = "Sword_2", shield = "Sword_3", cloth = "Cloth_8",
            bodyColor = new Color(0.6f, 0.6f, 0.65f),
            hp = 95, atk = 20, def = 5, speed = 1.7f, range = 1.5f, cooldown = 1.0f,
            attackAnim = AttackAnimType.Melee,
            element = DamageElement.Poison, poisonResist = 0.2f
        });

        CreatePreset(dir, "Enemy_CaveBat", new CharacterPresetDef {
            name = "동굴 박쥐", isEnemy = true, body = "Devil_1", eye = "Eye8",
            weapon = "Sword_1", shield = "Sword_4", cloth = "Cloth_5",
            bodyColor = new Color(0.4f, 0.3f, 0.5f),
            hp = 55, atk = 22, def = 1, speed = 3f, range = 1.5f, cooldown = 0.5f,
            attackAnim = AttackAnimType.Melee,
            element = DamageElement.Poison, poisonResist = 0.3f
        });

        CreatePreset(dir, "Enemy_FungusZombie", new CharacterPresetDef {
            name = "독버섯 좀비", isEnemy = true, body = "Human_2", eye = "Eye_Close",
            weapon = "Sword_4", shield = "Sword_1", cloth = "Cloth_11",
            bodyColor = new Color(0.4f, 0.6f, 0.35f),
            hp = 140, atk = 14, def = 4, speed = 1.0f, range = 1.5f, cooldown = 1.4f,
            attackAnim = AttackAnimType.Melee,
            element = DamageElement.Poison, poisonResist = 0.7f
        });

        CreatePreset(dir, "Enemy_CaveOrc", new CharacterPresetDef {
            name = "동굴 오크 검사", isEnemy = true, body = "Orc_2", eye = "Eye6",
            weapon = "Sword_3", shield = "Sword_5", cloth = "Cloth_8",
            bodyColor = new Color(0.55f, 0.55f, 0.6f),
            hp = 120, atk = 22, def = 8, speed = 1.5f, range = 1.5f, cooldown = 1.1f,
            attackAnim = AttackAnimType.Melee,
            element = DamageElement.Poison
        });

        // ★2
        CreatePreset(dir, "Enemy_CaveGolem", new CharacterPresetDef {
            name = "동굴 골렘", isEnemy = true, body = "Orc_4", eye = "Eye_Close",
            weapon = "Sword_4", armor = "Armor_4", shield = "Shield_1",
            bodyColor = new Color(0.5f, 0.5f, 0.55f),
            hp = 250, atk = 20, def = 18, speed = 0.9f, range = 1.5f, cooldown = 1.5f,
            attackAnim = AttackAnimType.Axe,
            element = DamageElement.Poison, poisonResist = 0.5f
        });

        CreatePreset(dir, "Enemy_PoisonMage", new CharacterPresetDef {
            name = "독 마법사", isEnemy = true, body = "Elf_1", eye = "Eye2",
            weapon = "Ward_1", cloth = "Cloth_9", back = "Back_3",
            bodyColor = new Color(0.4f, 0.6f, 0.4f),
            hp = 85, atk = 32, def = 3, speed = 1.4f, range = 5f, cooldown = 1.3f,
            attackAnim = AttackAnimType.Magic,
            element = DamageElement.Poison, poisonResist = 0.4f
        });

        // ★3 중간보스
        CreatePreset(dir, "Enemy_CaveWarden", new CharacterPresetDef {
            name = "동굴 수호자", isEnemy = true, body = "Orc_4", eye = "Eye_Close",
            weapon = "Soon_Spear", armor = "Armor_8", helmet = "Helmet_2",
            bodyColor = new Color(0.45f, 0.45f, 0.5f),
            hp = 600, atk = 30, def = 25, speed = 1.2f, range = 2f, cooldown = 1.3f,
            attackAnim = AttackAnimType.Spear,
            element = DamageElement.Poison, poisonResist = 0.6f
        });

        // ★4 에리어 보스
        CreatePreset(dir, "Enemy_SubterraneanLord", new CharacterPresetDef {
            name = "지하 군주", isEnemy = true, body = "Devil_1", eye = "Eye8",
            weapon = "Sword_6", armor = "Armor_5", helmet = "Helmet_5", back = "Soon_Back1",
            horse = "BlackHorse",
            bodyColor = new Color(0.35f, 0.3f, 0.45f),
            hp = 1200, atk = 55, def = 25, speed = 2.2f, range = 1.8f, cooldown = 1.0f,
            attackAnim = AttackAnimType.ShotSword,
            element = DamageElement.Poison, poisonResist = 0.7f
        });

        // ══════════════════════════════════════════════════
        // ENEMIES - Area 4: 화산 (Volcano) - 8종
        // ══════════════════════════════════════════════════

        // ★1
        CreatePreset(dir, "Enemy_FlameSkeleton", new CharacterPresetDef {
            name = "화염 해골 검사", isEnemy = true, body = "Skelton_1", eye = "Eye_Close",
            weapon = "Sword_3", shield = "Sword_5", cloth = "Cloth_1",
            bodyColor = new Color(1f, 0.7f, 0.5f),
            hp = 100, atk = 22, def = 4, speed = 2f, range = 1.5f, cooldown = 0.9f,
            attackAnim = AttackAnimType.Melee,
            lightningResist = 0.3f
        });

        CreatePreset(dir, "Enemy_LavaOrc", new CharacterPresetDef {
            name = "용암 오크", isEnemy = true, body = "Orc_3", eye = "Eye7",
            weapon = "Axe_1", armor = "Armor_3",
            bodyColor = new Color(0.8f, 0.4f, 0.3f),
            hp = 140, atk = 25, def = 8, speed = 1.5f, range = 1.5f, cooldown = 1.1f,
            attackAnim = AttackAnimType.Axe,
            lightningResist = 0.2f
        });

        CreatePreset(dir, "Enemy_FireImp", new CharacterPresetDef {
            name = "불꽃 임프", isEnemy = true, body = "Devil_1", eye = "Eye8",
            weapon = "Ward_1", cloth = "Cloth_2",
            bodyColor = new Color(1f, 0.5f, 0.3f),
            hp = 60, atk = 28, def = 2, speed = 2.5f, range = 3.5f, cooldown = 1.0f,
            attackAnim = AttackAnimType.Magic,
            lightningResist = 0.4f
        });

        CreatePreset(dir, "Enemy_MagmaZombie", new CharacterPresetDef {
            name = "용암 좀비", isEnemy = true, body = "Human_3", eye = "Eye_Close",
            weapon = "Sword_2", shield = "Sword_4", cloth = "Cloth_12",
            bodyColor = new Color(0.7f, 0.35f, 0.25f),
            hp = 160, atk = 15, def = 6, speed = 1.0f, range = 1.5f, cooldown = 1.4f,
            attackAnim = AttackAnimType.Melee
        });

        // ★2
        CreatePreset(dir, "Enemy_FlameKnight", new CharacterPresetDef {
            name = "화염 전사", isEnemy = true, body = "Devil_1", eye = "Eye8",
            weapon = "Sword_5", armor = "Armor_6", shield = "Shield_1",
            bodyColor = new Color(0.9f, 0.5f, 0.3f),
            hp = 200, atk = 30, def = 14, speed = 1.7f, range = 1.8f, cooldown = 1.0f,
            attackAnim = AttackAnimType.ShotSword,
            lightningResist = 0.3f
        });

        CreatePreset(dir, "Enemy_LavaMage", new CharacterPresetDef {
            name = "용암 법사", isEnemy = true, body = "Devil_1", eye = "Eye8",
            weapon = "Ward_1", cloth = "Cloth_9", back = "Back_2",
            bodyColor = new Color(1f, 0.6f, 0.4f),
            hp = 110, atk = 38, def = 3, speed = 1.4f, range = 5f, cooldown = 1.2f,
            attackAnim = AttackAnimType.Magic,
            lightningResist = 0.5f
        });

        // ★3 중간보스
        CreatePreset(dir, "Enemy_FlameGeneral", new CharacterPresetDef {
            name = "화염 장군", isEnemy = true, body = "Orc_3", eye = "Eye7",
            weapon = "Sword_6", armor = "Armor_8", helmet = "Helmet_9", back = "Back_3",
            bodyColor = new Color(0.9f, 0.4f, 0.25f),
            hp = 700, atk = 42, def = 20, speed = 1.8f, range = 1.8f, cooldown = 1.0f,
            attackAnim = AttackAnimType.ShotSword,
            lightningResist = 0.5f
        });

        // ★4 에리어 보스
        CreatePreset(dir, "Enemy_VolcanoLord", new CharacterPresetDef {
            name = "화산 군주", isEnemy = true, body = "Devil_1", eye = "Eye8",
            weapon = "Soon_Spear", armor = "Armor_5", helmet = "F_SR_Helmet", back = "Soon_Back1",
            horse = "RedHorse",
            bodyColor = new Color(1f, 0.4f, 0.2f),
            hp = 1500, atk = 60, def = 28, speed = 2.3f, range = 2f, cooldown = 1.1f,
            attackAnim = AttackAnimType.Spear,
            lightningResist = 0.7f
        });

        // ══════════════════════════════════════════════════
        // ENEMIES - Area 5: 암흑성 (Dark Castle) - 8종
        // ══════════════════════════════════════════════════

        // ★1
        CreatePreset(dir, "Enemy_DarkSkeleton", new CharacterPresetDef {
            name = "암흑 해골 검사", isEnemy = true, body = "Skelton_1", eye = "Eye_Close",
            weapon = "Sword_4", shield = "Sword_6", cloth = "Cloth_6",
            bodyColor = new Color(0.4f, 0.35f, 0.5f),
            hp = 110, atk = 24, def = 5, speed = 2f, range = 1.5f, cooldown = 0.9f,
            attackAnim = AttackAnimType.Melee,
            element = DamageElement.Lightning, poisonResist = 0.2f
        });

        CreatePreset(dir, "Enemy_DarkArcher", new CharacterPresetDef {
            name = "암흑 궁수", isEnemy = true, body = "Skelton_1", eye = "Eye_Close",
            weapon = "Bow_1", cloth = "Cloth_8", back = "BowBack_1",
            bodyColor = new Color(0.45f, 0.4f, 0.55f),
            hp = 70, atk = 30, def = 2, speed = 1.8f, range = 4.5f, cooldown = 1.1f,
            attackAnim = AttackAnimType.Bow,
            element = DamageElement.Poison
        });

        CreatePreset(dir, "Enemy_GhostWarrior", new CharacterPresetDef {
            name = "유령 검사", isEnemy = true, body = "Skelton_1", eye = "Eye_Close",
            weapon = "Sword_5", shield = "Sword_3", cloth = "Cloth_3",
            bodyColor = new Color(0.6f, 0.6f, 0.8f),
            hp = 80, atk = 28, def = 1, speed = 2.5f, range = 1.5f, cooldown = 0.7f,
            attackAnim = AttackAnimType.ShotSword,
            lightningResist = 0.5f, poisonResist = 0.5f
        });

        CreatePreset(dir, "Enemy_DarkZombie", new CharacterPresetDef {
            name = "암흑 좀비", isEnemy = true, body = "Skelton_1", eye = "Eye_Close",
            weapon = "Sword_1", shield = "Sword_2", cloth = "Cloth_11",
            bodyColor = new Color(0.35f, 0.3f, 0.4f),
            hp = 170, atk = 18, def = 7, speed = 1.1f, range = 1.5f, cooldown = 1.3f,
            attackAnim = AttackAnimType.Axe,
            poisonResist = 0.4f
        });

        // ★2
        CreatePreset(dir, "Enemy_DarkKnight", new CharacterPresetDef {
            name = "암흑 전사", isEnemy = true, body = "Skelton_1", eye = "Eye_Close",
            weapon = "Sword_6", armor = "Armor_5", shield = "Shield_1",
            bodyColor = new Color(0.3f, 0.3f, 0.4f),
            hp = 220, atk = 32, def = 16, speed = 1.8f, range = 1.8f, cooldown = 1.0f,
            attackAnim = AttackAnimType.ShotSword,
            element = DamageElement.Lightning, lightningResist = 0.4f
        });

        CreatePreset(dir, "Enemy_Necromancer", new CharacterPresetDef {
            name = "사령술사", isEnemy = true, body = "Skelton_1", eye = "Eye_Close",
            weapon = "Ward_1", cloth = "Cloth_9", back = "Back_1",
            bodyColor = new Color(0.5f, 0.4f, 0.6f),
            hp = 120, atk = 40, def = 4, speed = 1.3f, range = 5f, cooldown = 1.4f,
            attackAnim = AttackAnimType.Magic,
            element = DamageElement.Poison, poisonResist = 0.5f
        });

        // ★3 중간보스
        CreatePreset(dir, "Enemy_DeathKnight", new CharacterPresetDef {
            name = "죽음의 기사", isEnemy = true, body = "Skelton_1", eye = "Eye_Close",
            weapon = "Sword_6", armor = "Armor_8", helmet = "Helmet_9", shield = "Shield_1",
            back = "Back_3", horse = "BlackHorse",
            hp = 900, atk = 48, def = 28, speed = 2.2f, range = 1.8f, cooldown = 0.9f,
            attackAnim = AttackAnimType.ShotSword,
            lightningResist = 0.5f, poisonResist = 0.5f
        });

        // ★4 에리어 보스
        CreatePreset(dir, "Enemy_LichKing", new CharacterPresetDef {
            name = "리치 킹", isEnemy = true, body = "Skelton_1", eye = "Eye_Close",
            weapon = "Ward_1", armor = "Armor_8", helmet = "F_SR_Helmet", back = "Soon_Back1",
            bodyColor = new Color(0.5f, 0.4f, 0.7f),
            hp = 2000, atk = 65, def = 30, speed = 1.5f, range = 5f, cooldown = 1.5f,
            attackAnim = AttackAnimType.Magic,
            element = DamageElement.Lightning, lightningResist = 0.8f, poisonResist = 0.8f
        });

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        Debug.Log($"All character presets created in {dir}");
    }

    struct CharacterPresetDef
    {
        public string name;
        public bool isEnemy;
        public StarGrade rarity;
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
        preset.starGrade = def.rarity;
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
