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

        HpLevel = PlayerPrefs.GetInt(SaveKeys.UpgradeHp, 0);
        AtkLevel = PlayerPrefs.GetInt(SaveKeys.UpgradeAtk, 0);
        DefLevel = PlayerPrefs.GetInt(SaveKeys.UpgradeDef, 0);
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
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
        PlayerPrefs.SetInt(SaveKeys.UpgradeHp, HpLevel);
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
        PlayerPrefs.SetInt(SaveKeys.UpgradeAtk, AtkLevel);
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
        PlayerPrefs.SetInt(SaveKeys.UpgradeDef, DefLevel);
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

            // 세트 효과
            em.GetSetBonuses(heroName, out float setHp, out float setAtk, out float setDef);
            hpBonus += setHp;
            atkBonus += setAtk;
            defBonus += setDef;
        }

        // MountManager (탈것 스탯 보너스 %)
        var mm = MountManager.Instance;
        if (mm != null && unit.CurrentTeam == BattleUnit.Team.Ally)
        {
            mm.GetMountBonus(out float speedPct, out float hpPct, out float atkPct);
            hpBonus  += unit.baseMaxHp * hpPct  / 100f;
            atkBonus += unit.baseAtk   * atkPct / 100f;
            // moveSpeed는 baseMaxHp/baseAtk 없으므로 직접 배율 적용
            if (speedPct > 0f)
                unit.moveSpeed = unit.baseMoveSpeed > 0f
                    ? unit.baseMoveSpeed * (1f + speedPct / 100f)
                    : unit.moveSpeed * (1f + speedPct / 100f);
        }

        // 시너지 보너스 (퍼센트 기반)
        var ssm = SkillSynergyManager.Instance;
        if (ssm != null)
        {
            hpBonus += unit.baseMaxHp * ssm.GetHpPercent() / 100f;
            atkBonus += unit.baseAtk * ssm.GetAtkPercent() / 100f;
            defBonus += unit.baseDef * ssm.GetDefPercent() / 100f;
        }

        // Revenge stack bonus (ATK+8%, HP+10%, DEF+5% per stack, allies only)
        var sm = StageManager.Instance;
        if (sm != null && sm.RevengeStack > 0 && unit.CurrentTeam == BattleUnit.Team.Ally)
        {
            int stack = sm.RevengeStack;
            hpBonus  += unit.baseMaxHp * (stack * 0.10f);
            atkBonus += unit.baseAtk   * (stack * 0.08f);
            defBonus += unit.baseDef   * (stack * 0.05f);
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

    /// <summary>
    /// CharacterPreset 기반 전투력 계산 (HP + ATK*3 + DEF*2) + 업그레이드/영웅레벨 보너스
    /// </summary>
    public static int CalcCombatPower(CharacterPreset preset)
    {
        if (preset == null) return 0;

        float hp  = preset.maxHp;
        float atk = preset.atk;
        float def = preset.def;

        // 글로벌 업그레이드 보너스
        var um = Instance;
        if (um != null)
        {
            hp  += um.HpLevel  * HP_PER_LEVEL;
            atk += um.AtkLevel * ATK_PER_LEVEL;
            def += um.DefLevel * DEF_PER_LEVEL;
        }

        // 영웅 개별 레벨 보너스
        var hlm = HeroLevelManager.Instance;
        if (hlm != null)
        {
            hp  += hlm.GetHpBonus(preset.characterName);
            atk += hlm.GetAtkBonus(preset.characterName);
            def += hlm.GetDefBonus(preset.characterName);
        }

        return Mathf.RoundToInt(hp + atk * 3f + def * 2f);
    }
}
