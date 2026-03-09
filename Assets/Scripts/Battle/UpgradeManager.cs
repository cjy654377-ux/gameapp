using UnityEngine;

public class UpgradeManager : MonoBehaviour
{
    public static UpgradeManager Instance { get; private set; }

    public int HpLevel { get; private set; }
    public int AtkLevel { get; private set; }
    public int DefLevel { get; private set; }
    public int SpeedLevel { get; private set; }

    public const float HP_PER_LEVEL = 15f;
    public const float ATK_PER_LEVEL = 3f;
    public const float DEF_PER_LEVEL = 1.5f;
    public const float SPEED_PER_LEVEL = 0.1f;

    public const int BASE_COST = 50;
    public const float COST_SCALE = 1.3f;

    public event System.Action OnUpgraded;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        HpLevel = PlayerPrefs.GetInt("UpgradeHp", 0);
        AtkLevel = PlayerPrefs.GetInt("UpgradeAtk", 0);
        DefLevel = PlayerPrefs.GetInt("UpgradeDef", 0);
        SpeedLevel = PlayerPrefs.GetInt("UpgradeSpeed", 0);
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
        return true;
    }

    public bool UpgradeSpeed()
    {
        if (GoldManager.Instance == null) return false;
        int cost = GetCost(SpeedLevel);
        if (!GoldManager.Instance.SpendGold(cost)) return false;
        SpeedLevel++;
        PlayerPrefs.SetInt("UpgradeSpeed", SpeedLevel);
        RefreshAllAllies();
        OnUpgraded?.Invoke();
        return true;
    }

    void RefreshAllAllies()
    {
        if (BattleManager.Instance == null) return;
        var allies = BattleManager.Instance.allyUnits;
        for (int i = 0; i < allies.Count; i++)
        {
            if (allies[i] != null && !allies[i].IsDead)
                ApplyToUnit(allies[i]);
        }
    }

    // Applies upgrade bonuses on top of base stats (idempotent - safe to call multiple times)
    public void ApplyToUnit(BattleUnit unit)
    {
        float hpBonus = HpLevel * HP_PER_LEVEL;
        float atkBonus = AtkLevel * ATK_PER_LEVEL;
        float defBonus = DefLevel * DEF_PER_LEVEL;
        float speedBonus = SpeedLevel * SPEED_PER_LEVEL;

        // Use base stats stored on unit to avoid stacking, preserve active buffs
        unit.maxHp = unit.baseMaxHp + hpBonus;
        unit.atk = unit.baseAtk + atkBonus + unit.buffAtk;
        unit.def = unit.baseDef + defBonus + unit.buffDef;
        unit.moveSpeed = unit.baseMoveSpeed + speedBonus;
        unit.advanceSpeed = unit.baseAdvanceSpeed + speedBonus;

        // Heal to new max
        if (unit.CurrentHp > 0)
            unit.CurrentHp = unit.maxHp;
    }

    public float GetHpBonus() => HpLevel * HP_PER_LEVEL;
    public float GetAtkBonus() => AtkLevel * ATK_PER_LEVEL;
    public float GetDefBonus() => DefLevel * DEF_PER_LEVEL;
    public float GetSpeedBonus() => SpeedLevel * SPEED_PER_LEVEL;
}
