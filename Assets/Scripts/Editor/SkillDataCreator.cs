#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

public class SkillDataCreator
{
    [MenuItem("Game/Create Default Skills")]
    public static void CreateDefaultSkills()
    {
        // Create in Resources/Skills so they can be loaded at runtime
        string dir = "Assets/Resources/Skills";
        if (!AssetDatabase.IsValidFolder("Assets/Resources"))
            AssetDatabase.CreateFolder("Assets", "Resources");
        if (!AssetDatabase.IsValidFolder(dir))
            AssetDatabase.CreateFolder("Assets/Resources", "Skills");

        // 1. 화염구 - Damage, SingleEnemy, damage 80, cooldown 5s
        CreateSkill(dir, "Skill_Fireball", new SkillDef {
            name = "화염구", desc = "적 1명에게 강력한 화염 데미지",
            rarity = SkillRarity.Rare,
            target = SkillTargetType.SingleEnemy,
            effect = SkillEffectType.Damage,
            value = 80f, statusDur = 0f, cooldown = 5f,
            color = new Color(1f, 0.4f, 0.1f), icon = "🔥"
        });

        // 2. 치유의 빛 - Heal, SingleAlly, value 60, cooldown 8s
        CreateSkill(dir, "Skill_HealingLight", new SkillDef {
            name = "치유의 빛", desc = "가장 약한 아군의 HP를 회복",
            rarity = SkillRarity.Common,
            target = SkillTargetType.SingleAlly,
            effect = SkillEffectType.Heal,
            value = 60f, statusDur = 0f, cooldown = 8f,
            color = new Color(0.3f, 1f, 0.4f), icon = "+"
        });

        // 3. 번개 폭풍 - Damage, AllEnemies, damage 40, cooldown 12s
        CreateSkill(dir, "Skill_LightningStorm", new SkillDef {
            name = "번개 폭풍", desc = "적 전체에 번개 데미지",
            rarity = SkillRarity.Epic,
            target = SkillTargetType.AllEnemies,
            effect = SkillEffectType.Damage,
            value = 40f, statusDur = 0f, cooldown = 12f,
            color = new Color(0.4f, 0.8f, 1f), icon = "⚡"
        });

        // 4. 독안개 - Poison, AllEnemies, damage 30, duration 4s, cooldown 10s
        CreateSkill(dir, "Skill_PoisonFog", new SkillDef {
            name = "독안개", desc = "적 전체에 독 안개를 뿌려 지속 피해",
            rarity = SkillRarity.Rare,
            target = SkillTargetType.AllEnemies,
            effect = SkillEffectType.Poison,
            value = 30f, statusDur = 4f, cooldown = 10f,
            color = new Color(0.3f, 0.9f, 0.2f), icon = "☠"
        });

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        Debug.Log("[SkillDataCreator] 4 default skills created in " + dir);
    }

    struct SkillDef
    {
        public string name, desc, icon;
        public SkillRarity rarity;
        public SkillTargetType target;
        public SkillEffectType effect;
        public float value, statusDur, cooldown;
        public Color color;
    }

    static void CreateSkill(string dir, string fileName, SkillDef def)
    {
        string path = $"{dir}/{fileName}.asset";

        // Overwrite if exists
        var existing = AssetDatabase.LoadAssetAtPath<SkillData>(path);
        if (existing != null)
            AssetDatabase.DeleteAsset(path);

        var skill = ScriptableObject.CreateInstance<SkillData>();
        skill.skillName = def.name;
        skill.description = def.desc;
        skill.rarity = def.rarity;
        skill.targetType = def.target;
        skill.effectType = def.effect;
        skill.value = def.value;
        skill.statusDuration = def.statusDur;
        skill.cooldown = def.cooldown;
        skill.skillColor = def.color;
        skill.iconChar = def.icon;

        AssetDatabase.CreateAsset(skill, path);
    }
}
#endif
