using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// 장착된 스킬 조합에 따른 시너지 효과 계산
/// </summary>
public class SkillSynergyManager : MonoBehaviour
{
    public static SkillSynergyManager Instance { get; private set; }

    SkillSynergyData[] allSynergies;
    readonly List<SkillSynergyData> activeSynergies = new();

    // 현재 활성 시너지 보너스 (캐시)
    float cachedAtkPercent;
    float cachedDefPercent;
    float cachedHpPercent;
    float cachedDmgPercent;
    float cachedCooldownReduction;

    public event System.Action OnSynergyChanged;

    void Awake()
    {
        if (Instance != null) { Destroy(gameObject); return; }
        Instance = this;
        allSynergies = Resources.LoadAll<SkillSynergyData>("Synergies");
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }

    /// <summary>
    /// 장착 스킬이 변경될 때마다 호출
    /// </summary>
    public void RecalculateSynergies(List<SkillData> equippedSkills)
    {
        activeSynergies.Clear();
        cachedAtkPercent = 0f;
        cachedDefPercent = 0f;
        cachedHpPercent = 0f;
        cachedDmgPercent = 0f;
        cachedCooldownReduction = 0f;

        if (allSynergies == null || equippedSkills == null || equippedSkills.Count == 0)
        {
            OnSynergyChanged?.Invoke();
            return;
        }

        for (int i = 0; i < allSynergies.Length; i++)
        {
            if (CheckSynergy(allSynergies[i], equippedSkills))
            {
                activeSynergies.Add(allSynergies[i]);
                var b = allSynergies[i].bonus;
                cachedAtkPercent += b.bonusAtkPercent;
                cachedDefPercent += b.bonusDefPercent;
                cachedHpPercent += b.bonusHpPercent;
                cachedDmgPercent += b.bonusDmgPercent;
                cachedCooldownReduction += b.cooldownReduction;
            }
        }

        OnSynergyChanged?.Invoke();
    }

    bool CheckSynergy(SkillSynergyData synergy, List<SkillData> skills)
    {
        switch (synergy.type)
        {
            case SynergyType.Combo:
                return CheckCombo(synergy, skills);
            case SynergyType.Element:
                return CheckElement(synergy, skills);
            case SynergyType.Tag:
                return CheckTag(synergy, skills);
            default:
                return false;
        }
    }

    bool CheckCombo(SkillSynergyData synergy, List<SkillData> skills)
    {
        if (synergy.requiredSkillNames == null) return false;
        for (int i = 0; i < synergy.requiredSkillNames.Length; i++)
        {
            bool found = false;
            for (int j = 0; j < skills.Count; j++)
            {
                if (skills[j] != null && skills[j].skillName == synergy.requiredSkillNames[i])
                {
                    found = true;
                    break;
                }
            }
            if (!found) return false;
        }
        return true;
    }

    bool CheckElement(SkillSynergyData synergy, List<SkillData> skills)
    {
        int count = 0;
        for (int i = 0; i < skills.Count; i++)
        {
            if (skills[i] != null && skills[i].element == synergy.requiredElement)
                count++;
        }
        return count >= synergy.requiredElementCount;
    }

    bool CheckTag(SkillSynergyData synergy, List<SkillData> skills)
    {
        int count = 0;
        for (int i = 0; i < skills.Count; i++)
        {
            if (skills[i] == null || skills[i].tags == null) continue;
            for (int j = 0; j < skills[i].tags.Length; j++)
            {
                if (skills[i].tags[j] == synergy.requiredTag)
                {
                    count++;
                    break;
                }
            }
        }
        return count >= synergy.requiredTagCount;
    }

    // 외부에서 보너스 조회
    public float GetAtkPercent() => cachedAtkPercent;
    public float GetDefPercent() => cachedDefPercent;
    public float GetHpPercent() => cachedHpPercent;
    public float GetDmgPercent() => cachedDmgPercent;
    public float GetCooldownReduction() => cachedCooldownReduction;
    public IReadOnlyList<SkillSynergyData> ActiveSynergies => activeSynergies;
    public IReadOnlyList<SkillSynergyData> AllSynergies    => allSynergies;
    public bool IsActive(SkillSynergyData s)               => activeSynergies.Contains(s);
}
