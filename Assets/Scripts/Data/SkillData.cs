using UnityEngine;

public enum SkillTargetType
{
    SingleEnemy,    // 적 1명
    AllEnemies,     // 적 전체
    SingleAlly,     // 아군 1명
    AllAllies,      // 아군 전체
    Self            // 자기 자신
}

public enum SkillEffectType
{
    Damage,         // 데미지
    Heal,           // 힐
    Burn,           // 화상 부여
    Freeze,         // 동상 부여
    Poison,         // 중독 부여
    Slow,           // 둔화 부여
    Buff_Atk,       // 공격력 버프
    Buff_Def,       // 방어력 버프
}

public enum SkillElement
{
    None,
    Fire,
    Ice,
    Lightning,
    Poison,
    Holy,
    Dark
}

[CreateAssetMenu(fileName = "NewSkill", menuName = "Game/Skill Data")]
public class SkillData : ScriptableObject
{
    public string skillName;
    [TextArea] public string description;
    public StarGrade starGrade = StarGrade.Star1;
    public SkillElement element = SkillElement.None;
    public string[] tags;

    [Header("Targeting")]
    public SkillTargetType targetType = SkillTargetType.SingleEnemy;

    [Header("Effects")]
    public SkillEffectType effectType = SkillEffectType.Damage;
    public float value = 50f;              // damage/heal amount
    public float statusDuration = 3f;      // for status effects

    [Header("Cooldown")]
    public float cooldown = 5f;

    [Header("Visual")]
    public Color skillColor = Color.white;
    public string iconChar = "!";          // Placeholder character for icon
}
