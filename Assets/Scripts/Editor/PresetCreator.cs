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
        // ENEMIES - Area 1: 초원 (Grass) — 오크 부족
        // 특성: HP+30%, DEF+20%, 근접 위주 | bodyColor 녹색
        // ══════════════════════════════════════════════════

        // ★1 일반몹
        CreatePreset(dir, "Enemy_OrcGrunt", new CharacterPresetDef {
            name = "오크 졸병", isEnemy = true, rarity = StarGrade.Star1,
            body = "Orc_1", eye = "Eye5",
            weapon = "Sword_1", shield = "Sword_2", cloth = "Cloth_4",
            bodyColor = new Color(0.6f, 0.8f, 0.5f),
            hp = 130, atk = 18, def = 6, speed = 1.6f, range = 1.5f, cooldown = 1.1f,
            attackAnim = AttackAnimType.Melee
        });

        CreatePreset(dir, "Enemy_OrcArcher", new CharacterPresetDef {
            name = "오크 궁수", isEnemy = true, rarity = StarGrade.Star1,
            body = "Orc_2", eye = "Eye6",
            weapon = "Bow_1", cloth = "Cloth_4", back = "BowBack_1",
            bodyColor = new Color(0.6f, 0.8f, 0.5f),
            hp = 100, atk = 22, def = 4, speed = 1.7f, range = 4f, cooldown = 1.2f,
            attackAnim = AttackAnimType.Bow
        });

        CreatePreset(dir, "Enemy_OrcScout", new CharacterPresetDef {
            name = "오크 척후", isEnemy = true, rarity = StarGrade.Star1,
            body = "Orc_3", eye = "Eye7",
            weapon = "Axe_1", cloth = "Cloth_8",
            bodyColor = new Color(0.55f, 0.75f, 0.45f),
            hp = 110, atk = 20, def = 5, speed = 2.2f, range = 1.5f, cooldown = 0.9f,
            attackAnim = AttackAnimType.Axe
        });

        CreatePreset(dir, "Enemy_OrcBerserker", new CharacterPresetDef {
            name = "오크 돌격병", isEnemy = true, rarity = StarGrade.Star1,
            body = "Orc_4", eye = "Eye5",
            weapon = "Axe_1", armor = "Armor_1",
            bodyColor = new Color(0.65f, 0.82f, 0.52f),
            hp = 150, atk = 24, def = 4, speed = 1.9f, range = 1.5f, cooldown = 0.8f,
            attackAnim = AttackAnimType.Axe
        });

        // ★2 강화 일반몹
        CreatePreset(dir, "Enemy_OrcWarrior", new CharacterPresetDef {
            name = "오크 전사", isEnemy = true, rarity = StarGrade.Star2,
            body = "Orc_2", eye = "Eye6",
            weapon = "Sword_3", armor = "Orc_Armor_02", helmet = "Orc_Helmet_02", shield = "Shield_1",
            bodyColor = new Color(0.58f, 0.78f, 0.48f),
            hp = 200, atk = 28, def = 10, speed = 1.5f, range = 1.5f, cooldown = 1.0f,
            attackAnim = AttackAnimType.ShotSword
        });

        CreatePreset(dir, "Enemy_OrcShaman", new CharacterPresetDef {
            name = "오크 주술사", isEnemy = true, rarity = StarGrade.Star2,
            body = "Orc_1", eye = "Eye5",
            weapon = "Ward_1", cloth = "Cloth_9", back = "Back_1",
            bodyColor = new Color(0.6f, 0.8f, 0.5f),
            hp = 160, atk = 32, def = 5, speed = 1.4f, range = 4.5f, cooldown = 1.3f,
            attackAnim = AttackAnimType.Magic
        });

        // ★3 중간보스
        CreatePreset(dir, "Enemy_OrcGeneral", new CharacterPresetDef {
            name = "오크 장군", isEnemy = true, rarity = StarGrade.Star3,
            body = "Orc_3", eye = "Eye7",
            weapon = "Sword_5", armor = "Orc_Armor_03", helmet = "Orc_Helmet_04", back = "Back_2",
            bodyColor = new Color(0.55f, 0.75f, 0.45f),
            hp = 550, atk = 38, def = 18, speed = 1.7f, range = 1.8f, cooldown = 1.0f,
            attackAnim = AttackAnimType.ShotSword
        });

        // ★4 에리어 보스
        CreatePreset(dir, "Enemy_OrcWarchief", new CharacterPresetDef {
            name = "오크 대족장", isEnemy = true, rarity = StarGrade.Star4,
            body = "Orc_4", eye = "Eye5",
            weapon = "Axe_1", armor = "Orc_Armor_04", helmet = "Orc_Helmet_05", back = "Soon_Back1",
            horse = "Horse1",
            bodyColor = new Color(0.5f, 0.72f, 0.4f),
            hp = 1100, atk = 50, def = 24, speed = 2.0f, range = 1.5f, cooldown = 1.1f,
            attackAnim = AttackAnimType.Axe
        });

        // ══════════════════════════════════════════════════
        // ENEMIES - Area 2: 사막 (Desert) — 미라/언데드
        // 특성: ATK+10%, 마법 공격 많음 | bodyColor 모래색
        // ══════════════════════════════════════════════════

        // ★1
        CreatePreset(dir, "Enemy_MummyGrunt", new CharacterPresetDef {
            name = "미라 졸병", isEnemy = true, rarity = StarGrade.Star1,
            body = "Zombie_1", eye = "Eye_Close",
            weapon = "Sword_1", shield = "Sword_2", cloth = "Cloth_10",
            bodyColor = new Color(0.9f, 0.8f, 0.6f),
            hp = 100, atk = 18, def = 4, speed = 1.3f, range = 1.5f, cooldown = 1.2f,
            attackAnim = AttackAnimType.Melee,
            poisonResist = 0.3f
        });

        CreatePreset(dir, "Enemy_SkeletonSword", new CharacterPresetDef {
            name = "해골 검사", isEnemy = true, rarity = StarGrade.Star1,
            body = "Skelton_1", eye = "Eye_Close",
            weapon = "Sword_2", shield = "Sword_3", cloth = "Cloth_5",
            bodyColor = new Color(0.9f, 0.85f, 0.7f),
            hp = 80, atk = 20, def = 3, speed = 1.7f, range = 1.5f, cooldown = 1.0f,
            attackAnim = AttackAnimType.Melee,
            element = SkillElement.Lightning, lightningResist = 0.2f
        });

        CreatePreset(dir, "Enemy_SkeletonArcher", new CharacterPresetDef {
            name = "해골 궁수", isEnemy = true, rarity = StarGrade.Star1,
            body = "Skelton_1", eye = "Eye_Close",
            weapon = "Bow_1", cloth = "Cloth_7", back = "BowBack_1",
            bodyColor = new Color(0.88f, 0.83f, 0.68f),
            hp = 60, atk = 24, def = 2, speed = 1.5f, range = 4.5f, cooldown = 1.1f,
            attackAnim = AttackAnimType.Bow
        });

        CreatePreset(dir, "Enemy_MummyWanderer", new CharacterPresetDef {
            name = "미라 방랑자", isEnemy = true, rarity = StarGrade.Star1,
            body = "Zombie_2", eye = "Eye_Close",
            weapon = "Sword_4", shield = "Sword_1", cloth = "Cloth_11",
            bodyColor = new Color(0.85f, 0.78f, 0.6f),
            hp = 130, atk = 16, def = 2, speed = 1.2f, range = 1.5f, cooldown = 1.3f,
            attackAnim = AttackAnimType.Melee
        });

        // ★2
        CreatePreset(dir, "Enemy_SkeletonWarrior", new CharacterPresetDef {
            name = "해골 전사", isEnemy = true, rarity = StarGrade.Star2,
            body = "Zombie_3", eye = "Eye_Close",
            weapon = "Sword_6", armor = "Undead_Armor_02", shield = "Shield_1",
            bodyColor = new Color(0.9f, 0.85f, 0.7f),
            hp = 160, atk = 30, def = 10, speed = 1.6f, range = 1.8f, cooldown = 1.0f,
            attackAnim = AttackAnimType.ShotSword,
            element = SkillElement.Lightning, lightningResist = 0.4f
        });

        CreatePreset(dir, "Enemy_MummyMage", new CharacterPresetDef {
            name = "미라 법사", isEnemy = true, rarity = StarGrade.Star2,
            body = "Zombie_4", eye = "Eye_Close",
            weapon = "Ward_1", cloth = "Cloth_9", back = "Back_1",
            bodyColor = new Color(0.9f, 0.8f, 0.6f),
            hp = 120, atk = 36, def = 3, speed = 1.4f, range = 5f, cooldown = 1.3f,
            attackAnim = AttackAnimType.Magic,
            element = SkillElement.Lightning
        });

        // ★3 중간보스
        CreatePreset(dir, "Enemy_UndeadGeneral", new CharacterPresetDef {
            name = "언데드 장군", isEnemy = true, rarity = StarGrade.Star3,
            body = "Zombie_5", eye = "Eye_Close",
            weapon = "Sword_5", armor = "Undead_Armor_04", helmet = "Undead_Helmet_04", shield = "Shield_1",
            bodyColor = new Color(0.88f, 0.83f, 0.65f),
            hp = 500, atk = 42, def = 16, speed = 1.5f, range = 2f, cooldown = 1.1f,
            attackAnim = AttackAnimType.ShotSword,
            element = SkillElement.Lightning, lightningResist = 0.5f
        });

        // ★4 에리어 보스
        CreatePreset(dir, "Enemy_Pharaoh", new CharacterPresetDef {
            name = "파라오", isEnemy = true, rarity = StarGrade.Star4,
            body = "Zombie_6", eye = "Eye_Close",
            weapon = "Ward_1", armor = "Undead_Armor_06", helmet = "Undead_Helmet_06", back = "Soon_Back1",
            horse = "Horse2",
            bodyColor = new Color(0.92f, 0.88f, 0.7f),
            hp = 1000, atk = 55, def = 20, speed = 1.6f, range = 5f, cooldown = 1.4f,
            attackAnim = AttackAnimType.Magic,
            element = SkillElement.Lightning, lightningResist = 0.6f
        });

        // ══════════════════════════════════════════════════
        // ENEMIES - Area 3: 동굴 (Cave) — 다크엘프
        // 특성: HP-20%, ATK+25%, DEF-15%, speed+30%, 근접 위주 | bodyColor 어두운 남색
        // ══════════════════════════════════════════════════

        // ★1
        CreatePreset(dir, "Enemy_DarkElfScout", new CharacterPresetDef {
            name = "다크엘프 정찰병", isEnemy = true, rarity = StarGrade.Star1,
            body = "New_Elf_1", eye = "Eye8",
            weapon = "Sword_1", cloth = "Cloth_5",
            bodyColor = new Color(0.3f, 0.3f, 0.5f),
            hp = 80, atk = 30, def = 3, speed = 2.6f, range = 1.5f, cooldown = 0.8f,
            attackAnim = AttackAnimType.Melee
        });

        CreatePreset(dir, "Enemy_DarkElfRogue", new CharacterPresetDef {
            name = "다크엘프 도적", isEnemy = true, rarity = StarGrade.Star1,
            body = "Elf_1", eye = "Eye8",
            weapon = "Sword_2", shield = "Sword_1", cloth = "Cloth_8",
            bodyColor = new Color(0.3f, 0.3f, 0.5f),
            hp = 70, atk = 32, def = 2, speed = 2.8f, range = 1.5f, cooldown = 0.7f,
            attackAnim = AttackAnimType.ShotSword
        });

        CreatePreset(dir, "Enemy_DarkElfInfiltrator", new CharacterPresetDef {
            name = "다크엘프 잠입자", isEnemy = true, rarity = StarGrade.Star1,
            body = "New_Elf_2", eye = "Eye8",
            weapon = "Sword_4", cloth = "Cloth_3",
            bodyColor = new Color(0.3f, 0.3f, 0.5f),
            hp = 75, atk = 28, def = 2, speed = 3.0f, range = 1.5f, cooldown = 0.7f,
            attackAnim = AttackAnimType.Melee
        });

        CreatePreset(dir, "Enemy_DarkElfTrapper", new CharacterPresetDef {
            name = "다크엘프 함정사", isEnemy = true, rarity = StarGrade.Star1,
            body = "Elf_2", eye = "Eye8",
            weapon = "Bow_1", cloth = "Cloth_11", back = "BowBack_1",
            bodyColor = new Color(0.3f, 0.3f, 0.5f),
            hp = 65, atk = 34, def = 2, speed = 2.4f, range = 3f, cooldown = 1.0f,
            attackAnim = AttackAnimType.Bow
        });

        // ★2
        CreatePreset(dir, "Enemy_DarkElfAssassin", new CharacterPresetDef {
            name = "다크엘프 암살자", isEnemy = true, rarity = StarGrade.Star2,
            body = "New_Elf_1", eye = "Eye8",
            weapon = "Sword_5", armor = "Armor_3", shield = "Shield_1",
            bodyColor = new Color(0.28f, 0.28f, 0.48f),
            hp = 120, atk = 50, def = 5, speed = 3.0f, range = 1.8f, cooldown = 0.6f,
            attackAnim = AttackAnimType.ShotSword
        });

        CreatePreset(dir, "Enemy_DarkElfHexer", new CharacterPresetDef {
            name = "다크엘프 주술사", isEnemy = true, rarity = StarGrade.Star2,
            body = "New_Elf_2", eye = "Eye2",
            weapon = "Ward_1", cloth = "Cloth_9", back = "Back_3",
            bodyColor = new Color(0.28f, 0.28f, 0.48f),
            hp = 95, atk = 52, def = 3, speed = 2.6f, range = 3f, cooldown = 1.1f,
            attackAnim = AttackAnimType.Magic,
            element = SkillElement.Lightning
        });

        // ★3 중간보스
        CreatePreset(dir, "Enemy_DarkElfShadowMaster", new CharacterPresetDef {
            name = "다크엘프 암살단장", isEnemy = true, rarity = StarGrade.Star3,
            body = "Elf_1", eye = "Eye8",
            weapon = "Sword_6", armor = "Armor_4", helmet = "Helmet_2", back = "Back_2",
            bodyColor = new Color(0.25f, 0.25f, 0.45f),
            hp = 440, atk = 62, def = 12, speed = 3.2f, range = 1.8f, cooldown = 0.7f,
            attackAnim = AttackAnimType.ShotSword
        });

        // ★4 에리어 보스
        CreatePreset(dir, "Enemy_DarkElfOverlord", new CharacterPresetDef {
            name = "다크엘프 군주", isEnemy = true, rarity = StarGrade.Star4,
            body = "Elf_2", eye = "Eye8",
            weapon = "Sword_5", armor = "Armor_6", helmet = "Helmet_5", back = "Soon_Back1",
            horse = "BlackHorse",
            bodyColor = new Color(0.22f, 0.22f, 0.42f),
            hp = 880, atk = 78, def = 18, speed = 3.5f, range = 2f, cooldown = 0.8f,
            attackAnim = AttackAnimType.ShotSword
        });

        // ══════════════════════════════════════════════════
        // ENEMIES - Area 4: 화산 (Volcano) — 악마/데몬
        // 특성: HP+10%, ATK+30%, DEF-10%, 화염 공격 | bodyColor 붉은색
        // ══════════════════════════════════════════════════

        // ★1
        CreatePreset(dir, "Enemy_Imp", new CharacterPresetDef {
            name = "임프", isEnemy = true, rarity = StarGrade.Star1,
            body = "Devil_1", eye = "Eye8",
            weapon = "Sword_1", shield = "Sword_4", cloth = "Cloth_2",
            bodyColor = new Color(1f, 0.4f, 0.3f),
            hp = 80, atk = 28, def = 3, speed = 2.5f, range = 1.5f, cooldown = 0.7f,
            attackAnim = AttackAnimType.Melee,
            lightningResist = 0.3f
        });

        CreatePreset(dir, "Enemy_FlameDevil", new CharacterPresetDef {
            name = "화염 악마", isEnemy = true, rarity = StarGrade.Star1,
            body = "Devil_1", eye = "Eye8",
            weapon = "Sword_3", cloth = "Cloth_1",
            bodyColor = new Color(1f, 0.45f, 0.25f),
            hp = 110, atk = 30, def = 4, speed = 1.8f, range = 1.5f, cooldown = 0.9f,
            attackAnim = AttackAnimType.Melee,
            lightningResist = 0.4f
        });

        CreatePreset(dir, "Enemy_LavaDemon", new CharacterPresetDef {
            name = "용암 데몬", isEnemy = true, rarity = StarGrade.Star1,
            body = "Devil_1", eye = "Eye8",
            weapon = "Axe_1", armor = "Armor_1",
            bodyColor = new Color(0.85f, 0.35f, 0.2f),
            hp = 130, atk = 26, def = 5, speed = 1.5f, range = 1.5f, cooldown = 1.0f,
            attackAnim = AttackAnimType.Axe,
            lightningResist = 0.2f
        });

        CreatePreset(dir, "Enemy_FireSpirit", new CharacterPresetDef {
            name = "불꽃 요마", isEnemy = true, rarity = StarGrade.Star1,
            body = "Devil_1", eye = "Eye8",
            weapon = "Ward_1", cloth = "Cloth_9",
            bodyColor = new Color(1f, 0.5f, 0.3f),
            hp = 75, atk = 32, def = 2, speed = 2.2f, range = 4f, cooldown = 1.1f,
            attackAnim = AttackAnimType.Magic,
            lightningResist = 0.5f
        });

        // ★2
        CreatePreset(dir, "Enemy_HighDevil", new CharacterPresetDef {
            name = "상급 악마", isEnemy = true, rarity = StarGrade.Star2,
            body = "Devil_1", eye = "Eye8",
            weapon = "Sword_5", armor = "Armor_6", shield = "Shield_1",
            bodyColor = new Color(0.95f, 0.38f, 0.25f),
            hp = 180, atk = 45, def = 7, speed = 1.9f, range = 1.8f, cooldown = 0.9f,
            attackAnim = AttackAnimType.ShotSword,
            lightningResist = 0.4f
        });

        CreatePreset(dir, "Enemy_FlameSorcerer", new CharacterPresetDef {
            name = "화염 술사", isEnemy = true, rarity = StarGrade.Star2,
            body = "Devil_1", eye = "Eye8",
            weapon = "Ward_1", cloth = "Cloth_9", back = "Back_2",
            bodyColor = new Color(1f, 0.5f, 0.3f),
            hp = 140, atk = 52, def = 3, speed = 1.5f, range = 5f, cooldown = 1.2f,
            attackAnim = AttackAnimType.Magic,
            lightningResist = 0.5f
        });

        // ★3 중간보스
        CreatePreset(dir, "Enemy_DemonGeneral", new CharacterPresetDef {
            name = "악마 장군", isEnemy = true, rarity = StarGrade.Star3,
            body = "Devil_1", eye = "Eye8",
            weapon = "Sword_6", armor = "Armor_8", helmet = "Helmet_9", back = "Back_3",
            bodyColor = new Color(0.9f, 0.35f, 0.2f),
            hp = 550, atk = 58, def = 15, speed = 2.0f, range = 1.8f, cooldown = 0.9f,
            attackAnim = AttackAnimType.ShotSword,
            lightningResist = 0.55f
        });

        // ★4 에리어 보스
        CreatePreset(dir, "Enemy_DemonLord", new CharacterPresetDef {
            name = "마왕", isEnemy = true, rarity = StarGrade.Star4,
            body = "Devil_1", eye = "Eye8",
            weapon = "Soon_Spear", armor = "Armor_5", helmet = "F_SR_Helmet", back = "Soon_Back1",
            horse = "RedHorse",
            bodyColor = new Color(1f, 0.3f, 0.15f),
            hp = 1100, atk = 75, def = 18, speed = 2.5f, range = 2f, cooldown = 1.0f,
            attackAnim = AttackAnimType.Spear,
            lightningResist = 0.7f
        });

        // ══════════════════════════════════════════════════
        // ENEMIES - Area 5: 암흑성 (Abyss) — 망령/유령
        // 특성: HP-30%, ATK+20%, speed+20%, 암흑마법 | bodyColor 어두운 보라
        // ══════════════════════════════════════════════════

        // ★1
        CreatePreset(dir, "Enemy_WanderingSoul", new CharacterPresetDef {
            name = "떠도는 혼", isEnemy = true, rarity = StarGrade.Star1,
            body = "New_Elf_2", eye = "Eye8",
            weapon = "Ward_1", cloth = "Cloth_3",
            bodyColor = new Color(0.4f, 0.3f, 0.6f),
            hp = 70, atk = 24, def = 2, speed = 2.2f, range = 3.5f, cooldown = 1.0f,
            attackAnim = AttackAnimType.Magic,
            lightningResist = 0.3f, poisonResist = 0.3f
        });

        CreatePreset(dir, "Enemy_Shadow", new CharacterPresetDef {
            name = "그림자", isEnemy = true, rarity = StarGrade.Star1,
            body = "Human_1", eye = "Eye_Close",
            weapon = "Sword_4", shield = "Sword_3", cloth = "Cloth_6",
            bodyColor = new Color(0.35f, 0.28f, 0.52f),
            hp = 65, atk = 26, def = 1, speed = 2.8f, range = 1.5f, cooldown = 0.7f,
            attackAnim = AttackAnimType.ShotSword,
            lightningResist = 0.5f
        });

        CreatePreset(dir, "Enemy_Wraith", new CharacterPresetDef {
            name = "원혼", isEnemy = true, rarity = StarGrade.Star1,
            body = "New_Elf_1", eye = "Eye_Close",
            weapon = "Sword_5", shield = "Sword_1", cloth = "Cloth_8",
            bodyColor = new Color(0.45f, 0.35f, 0.65f),
            hp = 60, atk = 28, def = 1, speed = 2.5f, range = 1.5f, cooldown = 0.8f,
            attackAnim = AttackAnimType.Melee,
            lightningResist = 0.4f, poisonResist = 0.4f
        });

        CreatePreset(dir, "Enemy_EvilSpirit", new CharacterPresetDef {
            name = "악령", isEnemy = true, rarity = StarGrade.Star1,
            body = "Human_3", eye = "Eye_Close",
            weapon = "Ward_1", cloth = "Cloth_9",
            bodyColor = new Color(0.42f, 0.32f, 0.58f),
            hp = 55, atk = 30, def = 1, speed = 2.0f, range = 4.5f, cooldown = 1.1f,
            attackAnim = AttackAnimType.Magic,
            element = SkillElement.Poison,
            lightningResist = 0.3f, poisonResist = 0.5f
        });

        // ★2
        CreatePreset(dir, "Enemy_VengeanceKnight", new CharacterPresetDef {
            name = "원한의 기사", isEnemy = true, rarity = StarGrade.Star2,
            body = "Human_4", eye = "Eye_Close",
            weapon = "Sword_6", armor = "Armor_5", shield = "Shield_1",
            bodyColor = new Color(0.38f, 0.28f, 0.55f),
            hp = 140, atk = 40, def = 12, speed = 2.2f, range = 1.8f, cooldown = 0.9f,
            attackAnim = AttackAnimType.ShotSword,
            lightningResist = 0.4f, poisonResist = 0.4f
        });

        CreatePreset(dir, "Enemy_ShadowMage", new CharacterPresetDef {
            name = "그림자 마법사", isEnemy = true, rarity = StarGrade.Star2,
            body = "New_Elf_2", eye = "Eye_Close",
            weapon = "Ward_1", cloth = "Cloth_9", back = "Back_1",
            bodyColor = new Color(0.4f, 0.3f, 0.62f),
            hp = 110, atk = 48, def = 3, speed = 1.8f, range = 5f, cooldown = 1.3f,
            attackAnim = AttackAnimType.Magic,
            element = SkillElement.Lightning,
            lightningResist = 0.5f, poisonResist = 0.5f
        });

        // ★3 중간보스
        CreatePreset(dir, "Enemy_DeathKnight", new CharacterPresetDef {
            name = "죽음의 기사", isEnemy = true, rarity = StarGrade.Star3,
            body = "Human_5", eye = "Eye_Close",
            weapon = "Sword_6", armor = "Armor_8", helmet = "Helmet_9", shield = "Shield_1",
            back = "Back_3", horse = "BlackHorse",
            bodyColor = new Color(0.35f, 0.25f, 0.52f),
            hp = 560, atk = 55, def = 22, speed = 2.4f, range = 1.8f, cooldown = 0.9f,
            attackAnim = AttackAnimType.ShotSword,
            lightningResist = 0.55f, poisonResist = 0.55f
        });

        // ★4 에리어 보스
        CreatePreset(dir, "Enemy_AbyssLord", new CharacterPresetDef {
            name = "어비스 군주", isEnemy = true, rarity = StarGrade.Star4,
            body = "New_Elf_1", eye = "Eye_Close",
            weapon = "Ward_1", armor = "Armor_8", helmet = "F_SR_Helmet", back = "Soon_Back1",
            bodyColor = new Color(0.3f, 0.2f, 0.5f),
            hp = 1120, atk = 72, def = 25, speed = 2.0f, range = 5f, cooldown = 1.4f,
            attackAnim = AttackAnimType.Magic,
            element = SkillElement.Lightning,
            lightningResist = 0.8f, poisonResist = 0.8f
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
        public SkillElement element;
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
