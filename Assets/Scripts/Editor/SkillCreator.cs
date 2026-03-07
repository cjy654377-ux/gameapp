#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

public class SkillCreator
{
    [MenuItem("Game/Create Default Skills")]
    public static void CreateDefaultSkills()
    {
        string dir = "Assets/Data/Skills";
        if (!AssetDatabase.IsValidFolder("Assets/Data"))
            AssetDatabase.CreateFolder("Assets", "Data");
        if (!AssetDatabase.IsValidFolder(dir))
            AssetDatabase.CreateFolder("Assets/Data", "Skills");

        CreateSkill(dir, "Skill_Fireball", new SkillDef {
            name = "파이어볼", desc = "적 1명에게 화염 데미지 + 화상",
            rarity = SkillRarity.Rare,
            target = SkillTargetType.SingleEnemy,
            effect = SkillEffectType.Burn,
            value = 40f, statusDur = 3f, cooldown = 6f,
            color = new Color(1f, 0.4f, 0.1f), icon = "F"
        });

        CreateSkill(dir, "Skill_IceBlast", new SkillDef {
            name = "아이스블라스트", desc = "적 전체 동상",
            rarity = SkillRarity.Epic,
            target = SkillTargetType.AllEnemies,
            effect = SkillEffectType.Freeze,
            value = 20f, statusDur = 4f, cooldown = 10f,
            color = new Color(0.4f, 0.8f, 1f), icon = "I"
        });

        CreateSkill(dir, "Skill_Heal", new SkillDef {
            name = "힐", desc = "가장 약한 아군 HP 회복",
            rarity = SkillRarity.Common,
            target = SkillTargetType.SingleAlly,
            effect = SkillEffectType.Heal,
            value = 50f, statusDur = 0f, cooldown = 8f,
            color = new Color(0.3f, 1f, 0.4f), icon = "H"
        });

        CreateSkill(dir, "Skill_PoisonCloud", new SkillDef {
            name = "독구름", desc = "적 전체 중독",
            rarity = SkillRarity.Rare,
            target = SkillTargetType.AllEnemies,
            effect = SkillEffectType.Poison,
            value = 15f, statusDur = 5f, cooldown = 12f,
            color = new Color(0.3f, 0.9f, 0.2f), icon = "P"
        });

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        Debug.Log("Default skills created in " + dir);
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

        AssetDatabase.CreateAsset(skill, $"{dir}/{fileName}.asset");
    }
}
#endif
