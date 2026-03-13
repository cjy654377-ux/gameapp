using UnityEngine;

public class UpgradeManager : MonoBehaviour
{
    public static UpgradeManager Instance { get; private set; }

    public int HpLevel { get; private set; }
    public int AtkLevel { get; private set; }
    public int DefLevel { get; private set; }
    public const float HP_PER_LEVEL = 15f;
    public const float ATK_PER_LEVEL = 3f;
    public const float DEF_PER_LEVEL = 1.5f;

    public const int BASE_COST = 50;
    public const float COST_SCALE = 1.18f;

    public event System.Action OnUpgraded;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        HpLevel = PlayerPrefs.GetInt("UpgradeHp", 0);
        AtkLevel = PlayerPrefs.GetInt("UpgradeAtk", 0);
        DefLevel = PlayerPrefs.GetInt("UpgradeDef", 0);
    }

    public int GetCost(int level)
    {
        return Mathf.RoundToInt(BASE_COST * Mathf.Pow(COST_SCALE, level));
    }

    public bool UpgradeHp()
    {
        if (GoldManager.Instance == null) return false;
        int cost = GetCost(HpLevel);
        if (!GoldManager.Instance.SpendGold(cost)) return false;
        HpLevel++;
        PlayerPrefs.SetInt("UpgradeHp", HpLevel);
        RefreshAllAllies();
        OnUpgraded?.Invoke();
        SoundManager.Instance?.PlayLevelUpSFX();
        return true;
    }

    public bool UpgradeAtk()
    {
        if (GoldManager.Instance == null) return false;
        int cost = GetCost(AtkLevel);
        if (!GoldManager.Instance.SpendGold(cost)) return false;
        AtkLevel++;
        PlayerPrefs.SetInt("UpgradeAtk", AtkLevel);
        RefreshAllAllies();
        OnUpgraded?.Invoke();
        SoundManager.Instance?.PlayLevelUpSFX();
        return true;
    }

    public bool UpgradeDef()
    {
        if (GoldManager.Instance == null) return false;
        int cost = GetCost(DefLevel);
        if (!GoldManager.Instance.SpendGold(cost)) return false;
        DefLevel++;
        PlayerPrefs.SetInt("UpgradeDef", DefLevel);
        RefreshAllAllies();
        OnUpgraded?.Invoke();
        SoundManager.Instance?.PlayLevelUpSFX();
        return true;
    }

    void RefreshAllAllies()
    {
        if (BattleManager.Instance == null) return;
        var allies = BattleManager.Instance.allyUnits;
        for (int i = 0; i < allies.Count; i++)
        {
            if (allies[i] != null && !allies[i].IsDead)
                ApplyAllBonuses(allies[i]);
        }
    }

    /// <summary>
    /// 모든 보너스를 통합 적용 (UpgradeManager + HeroLevelManager + EquipmentManager)
    /// </summary>
    public static void ApplyAllBonuses(BattleUnit unit)
    {
        string heroName = unit.unitName;
        float hpBonus = 0f, atkBonus = 0f, defBonus = 0f;

        // UpgradeManager (글로벌 업그레이드)
        var um = Instance;
        if (um != null)
        {
            hpBonus += um.HpLevel * HP_PER_LEVEL;
            atkBonus += um.AtkLevel * ATK_PER_LEVEL;
            defBonus += um.DefLevel * DEF_PER_LEVEL;
        }

        // HeroLevelManager (영웅 개별 레벨)
        var hlm = HeroLevelManager.Instance;
        if (hlm != null)
        {
            hpBonus += hlm.GetHpBonus(heroName);
            atkBonus += hlm.GetAtkBonus(heroName);
            defBonus += hlm.GetDefBonus(heroName);
        }

        // EquipmentManager (장비)
        var em = EquipmentManager.Instance;
        if (em != null)
        {
            hpBonus += em.GetTotalBonusHp(heroName);
            atkBonus += em.GetTotalBonusAtk(heroName);
            defBonus += em.GetTotalBonusDef(heroName);
        }

        // HP 비율 유지
        float hpRatio = unit.maxHp > 0 ? unit.CurrentHp / unit.maxHp : 1f;
        unit.maxHp = unit.baseMaxHp + hpBonus;
        unit.atk = unit.baseAtk + atkBonus + unit.buffAtk;
        unit.def = unit.baseDef + defBonus + unit.buffDef;

        if (unit.CurrentHp > 0)
            unit.CurrentHp = unit.maxHp * hpRatio;

        unit.NotifyHpChanged();
    }

    public float GetHpBonus() => HpLevel * HP_PER_LEVEL;
    public float GetAtkBonus() => AtkLevel * ATK_PER_LEVEL;
    public float GetDefBonus() => DefLevel * DEF_PER_LEVEL;
}
