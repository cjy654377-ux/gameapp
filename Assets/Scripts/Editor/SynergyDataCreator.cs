using UnityEngine;
using UnityEditor;

public class SynergyDataCreator
{
    [MenuItem("Tools/Create Initial Synergies")]
    static void CreateAll()
    {
        string path = "Assets/Resources/Synergies/";
        if (!AssetDatabase.IsValidFolder("Assets/Resources/Synergies"))
        {
            if (!AssetDatabase.IsValidFolder("Assets/Resources"))
                AssetDatabase.CreateFolder("Assets", "Resources");
            AssetDatabase.CreateFolder("Assets/Resources", "Synergies");
        }

        // === Combo 시너지 ===
        CreateSynergy(path, "Synergy_ExplosivePoison", "폭발독",
            "파이어볼 + 독안개 조합 시 스킬 데미지 증가",
            SynergyType.Combo,
            comboSkills: new[] { "Fireball", "PoisonFog" },
            bonus: new SynergyBonus { bonusDmgPercent = 25f });

        CreateSynergy(path, "Synergy_ExtremeFrost", "극한빙결",
            "프로스트바이트 + 슬로우미스트 조합 시 쿨타임 감소",
            SynergyType.Combo,
            comboSkills: new[] { "FrostBite", "SlowMist" },
            bonus: new SynergyBonus { cooldownReduction = 15f });

        CreateSynergy(path, "Synergy_DivineJudgment", "신성심판",
            "디바인볼트 + 힐링라이트 조합 시 공격력 증가",
            SynergyType.Combo,
            comboSkills: new[] { "DivineBolt", "HealingLight" },
            bonus: new SynergyBonus { bonusAtkPercent = 20f });

        // === Element 시너지 ===
        CreateSynergy(path, "Synergy_FireAffinity", "화염 친화",
            "Fire 속성 스킬 2개 이상 장착 시 스킬 데미지 증가",
            SynergyType.Element,
            element: SkillElement.Fire, elementCount: 2,
            bonus: new SynergyBonus { bonusDmgPercent = 20f });

        CreateSynergy(path, "Synergy_IceAffinity", "얼음 친화",
            "Ice 속성 스킬 2개 이상 장착 시 쿨타임 감소",
            SynergyType.Element,
            element: SkillElement.Ice, elementCount: 2,
            bonus: new SynergyBonus { cooldownReduction = 10f });

        CreateSynergy(path, "Synergy_HolyAffinity", "신성 친화",
            "Holy 속성 스킬 2개 이상 장착 시 HP 증가",
            SynergyType.Element,
            element: SkillElement.Holy, elementCount: 2,
            bonus: new SynergyBonus { bonusHpPercent = 15f });

        // === Tag 시너지 ===
        CreateSynergy(path, "Synergy_BattleFrenzy", "전투광",
            "공격 태그 스킬 2개 이상 장착 시 공격력 증가",
            SynergyType.Tag,
            tag: "공격", tagCount: 2,
            bonus: new SynergyBonus { bonusAtkPercent = 15f });

        CreateSynergy(path, "Synergy_Guardian", "수호자",
            "방어 태그 스킬 2개 이상 장착 시 방어력/HP 증가",
            SynergyType.Tag,
            tag: "방어", tagCount: 2,
            bonus: new SynergyBonus { bonusDefPercent = 15f, bonusHpPercent = 10f });

        CreateSynergy(path, "Synergy_Strategist", "전략가",
            "디버프 태그 스킬 2개 이상 장착 시 데미지/쿨타임 보너스",
            SynergyType.Tag,
            tag: "디버프", tagCount: 2,
            bonus: new SynergyBonus { bonusDmgPercent = 10f, cooldownReduction = 5f });

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        Debug.Log("[SynergyDataCreator] 9개 시너지 데이터 생성 완료!");
    }

    static void CreateSynergy(string path, string fileName, string synergyName,
        string description, SynergyType type,
        string[] comboSkills = null,
        SkillElement element = SkillElement.None, int elementCount = 2,
        string tag = null, int tagCount = 2,
        SynergyBonus bonus = null)
    {
        var data = ScriptableObject.CreateInstance<SkillSynergyData>();
        data.synergyName = synergyName;
        data.description = description;
        data.type = type;
        data.requiredSkillNames = comboSkills;
        data.requiredElement = element;
        data.requiredElementCount = elementCount;
        data.requiredTag = tag;
        data.requiredTagCount = tagCount;
        data.bonus = bonus ?? new SynergyBonus();

        AssetDatabase.CreateAsset(data, path + fileName + ".asset");
    }
}
