using UnityEngine;

/// <summary>
/// 스킬 시너지 타입
/// </summary>
public enum SynergyType
{
    Combo,      // 특정 스킬 2개 조합
    Element,    // 같은 속성 N개
    Tag         // 같은 태그 N개
}

/// <summary>
/// 시너지 보너스 효과
/// </summary>
[System.Serializable]
public class SynergyBonus
{
    public float bonusAtkPercent;    // 공격력 % 증가
    public float bonusDefPercent;    // 방어력 % 증가
    public float bonusHpPercent;     // HP % 증가
    public float bonusDmgPercent;    // 스킬 데미지 % 증가
    public float cooldownReduction;  // 쿨타임 % 감소
}

/// <summary>
/// 개별 시너지 정의 (ScriptableObject)
/// </summary>
[CreateAssetMenu(fileName = "NewSynergy", menuName = "Game/Skill Synergy")]
public class SkillSynergyData : ScriptableObject
{
    public string synergyName;
    [TextArea] public string description;
    public SynergyType type;

    [Header("Combo Type - 필요 스킬 이름")]
    public string[] requiredSkillNames;

    [Header("Element Type - 필요 속성 + 수량")]
    public SkillElement requiredElement;
    public int requiredElementCount = 2;

    [Header("Tag Type - 필요 태그 + 수량")]
    public string requiredTag;
    public int requiredTagCount = 2;

    [Header("보너스")]
    public SynergyBonus bonus;
}
