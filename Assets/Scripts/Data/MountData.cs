using UnityEngine;

[CreateAssetMenu(fileName = "NewMount", menuName = "Game/Mount Data")]
public class MountData : ScriptableObject
{
    public string mountName;
    public StarGrade starGrade = StarGrade.Star1;
    public string horseSpriteFolder; // "Horse1", "Horse2", "BlackHorse", "RedHorse"

    [Header("Stat Bonus (%)")]
    public float speedBonus;       // 이동속도 % 증가
    public float hpBonusPercent;   // HP % 증가
    public float atkBonusPercent;  // ATK % 증가
}
