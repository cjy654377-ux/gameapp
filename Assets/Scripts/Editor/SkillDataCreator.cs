#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

public class SkillDataCreator
{
    [MenuItem("Game/Create Default Skills")]
    public static void CreateDefaultSkills()
    {
        string dir = "Assets/Resources/Skills";
        if (!AssetDatabase.IsValidFolder("Assets/Resources"))
            AssetDatabase.CreateFolder("Assets", "Resources");
        if (!AssetDatabase.IsValidFolder(dir))
            AssetDatabase.CreateFolder("Assets/Resources", "Skills");

        // 1. 화염구 - 단일 고데미지
        CreateSkill(dir, "Skill_Fireball", new SkillDef {
            name = "화염구", desc = "적 1명에게 강력한 화염 데미지",
            rarity = StarGrade.Star2,
            target = SkillTargetType.SingleEnemy,
            effect = SkillEffectType.Damage,
            value = 80f, statusDur = 0f, cooldown = 5f,
            color = new Color(1f, 0.4f, 0.1f), icon = "🔥"
        });

        // 2. 치유의 빛 - 단일 힐
        CreateSkill(dir, "Skill_HealingLight", new SkillDef {
            name = "치유의 빛", desc = "가장 약한 아군의 HP를 회복",
            rarity = StarGrade.Star1,
            target = SkillTargetType.SingleAlly,
            effect = SkillEffectType.Heal,
            value = 60f, statusDur = 0f, cooldown = 8f,
            color = new Color(0.3f, 1f, 0.4f), icon = "✚"
        });

        // 3. 번개 폭풍 - 전체 데미지
        CreateSkill(dir, "Skill_LightningStorm", new SkillDef {
            name = "번개 폭풍", desc = "적 전체에 번개 데미지",
            rarity = StarGrade.Star3,
            target = SkillTargetType.AllEnemies,
            effect = SkillEffectType.Damage,
            value = 40f, statusDur = 0f, cooldown = 12f,
            color = new Color(0.4f, 0.8f, 1f), icon = "⚡"
        });

        // 4. 독안개 - 전체 독
        CreateSkill(dir, "Skill_PoisonFog", new SkillDef {
            name = "독안개", desc = "적 전체에 독 안개를 뿌려 지속 피해",
            rarity = StarGrade.Star2,
            target = SkillTargetType.AllEnemies,
            effect = SkillEffectType.Poison,
            value = 30f, statusDur = 4f, cooldown = 10f,
            color = new Color(0.3f, 0.9f, 0.2f), icon = "☠"
        });

        // 5. 빙결 - 단일 동결
        CreateSkill(dir, "Skill_FrostBite", new SkillDef {
            name = "빙결", desc = "적 1명을 얼려 이동/공격 정지",
            rarity = StarGrade.Star2,
            target = SkillTargetType.SingleEnemy,
            effect = SkillEffectType.Freeze,
            value = 25f, statusDur = 3f, cooldown = 9f,
            color = new Color(0.4f, 0.8f, 1f), icon = "❄"
        });

        // 6. 화염 장막 - 전체 화상
        CreateSkill(dir, "Skill_FireWall", new SkillDef {
            name = "화염 장막", desc = "적 전체에 화상을 입혀 지속 피해",
            rarity = StarGrade.Star3,
            target = SkillTargetType.AllEnemies,
            effect = SkillEffectType.Burn,
            value = 35f, statusDur = 5f, cooldown = 14f,
            color = new Color(1f, 0.3f, 0.1f), icon = "🔥"
        });

        // 7. 전투함성 - 전체 공격 버프
        CreateSkill(dir, "Skill_WarCry", new SkillDef {
            name = "전투함성", desc = "아군 전체의 공격력을 일시적으로 강화",
            rarity = StarGrade.Star3,
            target = SkillTargetType.AllAllies,
            effect = SkillEffectType.Buff_Atk,
            value = 15f, statusDur = 6f, cooldown = 15f,
            color = new Color(1f, 0.5f, 0.2f), icon = "⚔"
        });

        // 8. 수호의 방패 - 전체 방어 버프
        CreateSkill(dir, "Skill_GuardShield", new SkillDef {
            name = "수호의 방패", desc = "아군 전체의 방어력을 일시적으로 강화",
            rarity = StarGrade.Star1,
            target = SkillTargetType.AllAllies,
            effect = SkillEffectType.Buff_Def,
            value = 10f, statusDur = 6f, cooldown = 12f,
            color = new Color(0.3f, 0.6f, 1f), icon = "🛡"
        });

        // 9. 둔화의 안개 - 전체 슬로우
        CreateSkill(dir, "Skill_SlowMist", new SkillDef {
            name = "둔화의 안개", desc = "적 전체의 이동/공격 속도를 낮춤",
            rarity = StarGrade.Star1,
            target = SkillTargetType.AllEnemies,
            effect = SkillEffectType.Slow,
            value = 20f, statusDur = 4f, cooldown = 10f,
            color = new Color(0.6f, 0.4f, 0.8f), icon = "🌀"
        });

        // 10. 심판의 벼락 - 단일 전설급 데미지
        CreateSkill(dir, "Skill_DivineBolt", new SkillDef {
            name = "심판의 벼락", desc = "가장 강한 적에게 천벌 데미지",
            rarity = StarGrade.Star4,
            target = SkillTargetType.SingleEnemy,
            effect = SkillEffectType.Damage,
            value = 200f, statusDur = 0f, cooldown = 20f,
            color = new Color(1f, 0.95f, 0.4f), icon = "✦"
        });

        // 11. 대자연의 축복 - 전체 힐 (전설)
        CreateSkill(dir, "Skill_NatureBlessing", new SkillDef {
            name = "대자연의 축복", desc = "아군 전체의 HP를 대량 회복",
            rarity = StarGrade.Star4,
            target = SkillTargetType.AllAllies,
            effect = SkillEffectType.Heal,
            value = 100f, statusDur = 0f, cooldown = 25f,
            color = new Color(0.2f, 1f, 0.5f), icon = "❖"
        });

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        Debug.Log($"[SkillDataCreator] 11 skills created in {dir}");
    }

    struct SkillDef
    {
        public string name, desc, icon;
        public StarGrade rarity;
        public SkillTargetType target;
        public SkillEffectType effect;
        public float value, statusDur, cooldown;
        public Color color;
    }

    static void CreateSkill(string dir, string fileName, SkillDef def)
    {
        string path = $"{dir}/{fileName}.asset";

        var existing = AssetDatabase.LoadAssetAtPath<SkillData>(path);
        if (existing != null)
            AssetDatabase.DeleteAsset(path);

        var skill = ScriptableObject.CreateInstance<SkillData>();
        skill.skillName = def.name;
        skill.description = def.desc;
        skill.starGrade = def.rarity;
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
