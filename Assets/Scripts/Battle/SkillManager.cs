using UnityEngine;
using System.Collections.Generic;

public class SkillManager : MonoBehaviour
{
    public static SkillManager Instance { get; private set; }

    [Header("Skills")]
    public List<SkillData> equippedSkills = new();
    public bool autoUse = true;

    readonly float[] cooldownTimers = new float[4]; // max 4 skill slots
    static Material cachedVFXMaterial;

    // All available skills loaded from Resources
    SkillData[] allSkills;

    public event System.Action<int, float, float> OnCooldownChanged; // slot, remaining, total
    public event System.Action<int> OnSkillUsed;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(gameObject);
    }

    void Start()
    {
        // Load all skills from Resources/Skills
        allSkills = Resources.LoadAll<SkillData>("Skills");

        // Try to load saved equipped skills
        LoadEquippedSkills();

        // If still no skills equipped, auto-equip all available (up to 4)
        if (equippedSkills.Count == 0 && allSkills != null && allSkills.Length > 0)
        {
            int count = Mathf.Min(allSkills.Length, 4);
            for (int i = 0; i < count; i++)
                equippedSkills.Add(allSkills[i]);
            SaveEquippedSkills();
        }

        // Remove null entries from loaded skills
        for (int i = equippedSkills.Count - 1; i >= 0; i--)
            if (equippedSkills[i] == null) equippedSkills.RemoveAt(i);

        // Start with skills on cooldown
        for (int i = 0; i < equippedSkills.Count && i < 4; i++)
            cooldownTimers[i] = equippedSkills[i].cooldown;
    }

    void Update()
    {
        if (BattleManager.Instance == null ||
            BattleManager.Instance.CurrentState != BattleManager.BattleState.Fighting)
            return;

        for (int i = 0; i < equippedSkills.Count && i < 4; i++)
        {
            if (cooldownTimers[i] > 0f)
            {
                float prev = cooldownTimers[i];
                cooldownTimers[i] -= Time.deltaTime;
                // 0.1초 이상 변화 또는 쿨다운 완료 시에만 이벤트 (GC 절감)
                if (prev - cooldownTimers[i] >= 0.1f || cooldownTimers[i] <= 0f)
                    OnCooldownChanged?.Invoke(i, cooldownTimers[i], equippedSkills[i].cooldown);
            }
            else if (autoUse)
            {
                UseSkill(i);
            }
        }
    }

    public void UseSkill(int slotIndex)
    {
        if (slotIndex < 0 || slotIndex >= equippedSkills.Count) return;
        if (cooldownTimers[slotIndex] > 0f) return;

        var skill = equippedSkills[slotIndex];
        if (skill == null) return;
        var targets = GetTargets(skill);
        if (targets == null || targets.Count == 0) return;

        // 스킬 레벨 배율 적용
        float dmgMult = SkillUpgradeManager.Instance != null
            ? SkillUpgradeManager.Instance.GetDamageMultiplier(skill.skillName) : 1f;
        float cdMult = SkillUpgradeManager.Instance != null
            ? SkillUpgradeManager.Instance.GetCooldownMultiplier(skill.skillName) : 1f;

        for (int i = 0; i < targets.Count; i++)
            ApplySkillEffect(skill, targets[i], dmgMult);

        SoundManager.Instance?.PlaySkillSFX();
        cooldownTimers[slotIndex] = skill.cooldown * cdMult;
        OnSkillUsed?.Invoke(slotIndex);
        DailyMissionManager.Instance?.RegisterSkillUse();
    }

    /// <summary>
    /// Save equipped skill names to PlayerPrefs (comma-separated)
    /// </summary>
    public void SaveEquippedSkills()
    {
        var names = new List<string>();
        for (int i = 0; i < equippedSkills.Count; i++)
        {
            if (equippedSkills[i] != null)
                names.Add(equippedSkills[i].skillName);
        }
        PlayerPrefs.SetString("EquippedSkills", string.Join(",", names));
        PlayerPrefs.Save();
    }

    /// <summary>
    /// Load equipped skills from PlayerPrefs
    /// </summary>
    public void LoadEquippedSkills()
    {
        string saved = PlayerPrefs.GetString("EquippedSkills", "");
        if (string.IsNullOrEmpty(saved)) return;
        if (allSkills == null || allSkills.Length == 0) return;

        string[] names = saved.Split(',');
        equippedSkills.Clear();

        for (int i = 0; i < names.Length && i < 4; i++)
        {
            string n = names[i].Trim();
            if (string.IsNullOrEmpty(n)) continue;

            for (int j = 0; j < allSkills.Length; j++)
            {
                if (allSkills[j].skillName == n)
                {
                    equippedSkills.Add(allSkills[j]);
                    break;
                }
            }
        }
    }

    // 캐시된 타겟 버퍼 (GC 절감)
    readonly List<BattleUnit> targetBuffer = new();

    List<BattleUnit> GetTargets(SkillData skill)
    {
        var manager = BattleManager.Instance;
        if (manager == null) return null;

        targetBuffer.Clear();
        var result = targetBuffer;

        switch (skill.targetType)
        {
            case SkillTargetType.SingleEnemy:
                var nearest = FindNearestAlive(manager.enemyUnits);
                if (nearest != null) result.Add(nearest);
                break;
            case SkillTargetType.AllEnemies:
                AddAlive(result, manager.enemyUnits);
                break;
            case SkillTargetType.SingleAlly:
                // Heal: find lowest HP ally
                var weakest = FindWeakestAlive(manager.allyUnits);
                if (weakest != null) result.Add(weakest);
                break;
            case SkillTargetType.AllAllies:
                AddAlive(result, manager.allyUnits);
                break;
            case SkillTargetType.Self:
                if (manager.allyUnits.Count > 0 && !manager.allyUnits[0].IsDead)
                    result.Add(manager.allyUnits[0]);
                break;
        }

        return result;
    }

    /// <summary>
    /// BattleUnit에서도 호출 가능한 공개 스킬 효과 적용
    /// </summary>
    public void ApplyEffect(SkillData skill, BattleUnit target)
    {
        ApplySkillEffect(skill, target, 1f);
    }

    void ApplySkillEffect(SkillData skill, BattleUnit target, float dmgMult = 1f)
    {
        switch (skill.effectType)
        {
            case SkillEffectType.Damage:
                target.TakeDamage(skill.value * dmgMult);
                SpawnSkillVFX(target.transform.position, skill.skillColor, SkillEffectType.Damage);
                break;
            case SkillEffectType.Heal:
                target.Heal(skill.value * dmgMult);
                SpawnSkillVFX(target.transform.position, Color.green, SkillEffectType.Heal);
                break;
            case SkillEffectType.Burn:
                ApplyStatus(target, StatusEffectType.Burn, skill);
                break;
            case SkillEffectType.Freeze:
                ApplyStatus(target, StatusEffectType.Freeze, skill);
                break;
            case SkillEffectType.Poison:
                ApplyStatus(target, StatusEffectType.Poison, skill);
                break;
            case SkillEffectType.Slow:
                ApplyStatus(target, StatusEffectType.Slow, skill);
                break;
            case SkillEffectType.Buff_Atk:
                target.ApplyBuff(skill.value, 0f, skill.statusDuration);
                SpawnSkillVFX(target.transform.position, new Color(1f, 0.5f, 0.2f), SkillEffectType.Damage);
                break;
            case SkillEffectType.Buff_Def:
                target.ApplyBuff(0f, skill.value, skill.statusDuration);
                SpawnSkillVFX(target.transform.position, new Color(0.3f, 0.6f, 1f), SkillEffectType.Heal);
                break;
        }
    }

    void ApplyStatus(BattleUnit target, StatusEffectType type, SkillData skill)
    {
        var controller = target.GetComponent<StatusEffectController>();
        if (controller == null)
            controller = target.gameObject.AddComponent<StatusEffectController>();
        controller.ApplyEffect(type, skill.statusDuration);

        // Also deal some initial damage for offensive status effects
        if (skill.value > 0)
            target.TakeDamage(skill.value * 0.3f);

        SpawnSkillVFX(target.transform.position, skill.skillColor, skill.effectType);
    }

    // SPUM Ultimate Resource Bundle 이펙트 프리팹 경로 (Resources/VFX/ 복사 필요)
    // 복사: Tools > Copy SPUM VFX to Resources
    static readonly Dictionary<SkillEffectType, string> vfxPrefabPaths = new()
    {
        { SkillEffectType.Damage,   "VFX/Eff_Damaged" },
        { SkillEffectType.Burn,     "VFX/Eff_FireDamaged" },
        { SkillEffectType.Freeze,   "VFX/Eff_SaintDamaged" },  // 냉기 대체
        { SkillEffectType.Poison,   "VFX/Eff_Vampire" },        // 독 대체
        { SkillEffectType.Slow,     "VFX/Eff_Slow" },
        { SkillEffectType.Heal,     "VFX/Eff_SaintHeal" },
        { SkillEffectType.Buff_Atk, "VFX/Eff_MagicCast" },
        { SkillEffectType.Buff_Def, "VFX/Eff_SaintCast" },
    };
    static readonly Dictionary<SkillEffectType, GameObject> vfxPrefabCache = new();

    const string VFX_POOL = "SkillVFX";

    void SpawnSkillVFX(Vector3 position, Color color, SkillEffectType effectType = SkillEffectType.Damage)
    {
        if (vfxPrefabPaths.TryGetValue(effectType, out string path))
        {
            if (!vfxPrefabCache.TryGetValue(effectType, out var prefab))
            {
                prefab = Resources.Load<GameObject>(path);
                vfxPrefabCache[effectType] = prefab;
            }
            if (prefab != null)
            {
                var vfx = Instantiate(prefab, position, Quaternion.identity);
                vfx.transform.localScale = Vector3.one * 0.4f;
                Destroy(vfx, 2f);
                return;
            }
        }

        // Fallback: pooled simple particle
        var pool = ObjectPool.Instance;
        var go = pool != null
            ? pool.Get(VFX_POOL, CreateFallbackVFX)
            : CreateFallbackVFX();

        go.transform.position = position;
        go.transform.localScale = Vector3.one;
        var ps = go.GetComponent<ParticleSystem>();
        var main = ps.main;
        main.startColor = color;
        ps.Play();

        StartCoroutine(ReturnVFXAfterDelay(go, 1f));
    }

    GameObject CreateFallbackVFX()
    {
        var go = new GameObject("SkillVFX");
        var ps = go.AddComponent<ParticleSystem>();
        var main = ps.main;
        main.startLifetime = 0.5f;
        main.startSpeed = 3f;
        main.startSize = 0.15f;
        main.maxParticles = 20;
        main.duration = 0.3f;
        main.loop = false;
        main.playOnAwake = false;

        var emission = ps.emission;
        emission.rateOverTime = 0;
        emission.SetBursts(new[] { new ParticleSystem.Burst(0f, 15) });

        var shape = ps.shape;
        shape.shapeType = ParticleSystemShapeType.Circle;
        shape.radius = 0.3f;

        if (cachedVFXMaterial == null)
            cachedVFXMaterial = new Material(Shader.Find("Sprites/Default"));
        var renderer = go.GetComponent<ParticleSystemRenderer>();
        renderer.material = cachedVFXMaterial;
        renderer.sortingOrder = 100;

        return go;
    }

    System.Collections.IEnumerator ReturnVFXAfterDelay(GameObject go, float delay)
    {
        yield return new WaitForSeconds(delay);
        var pool = ObjectPool.Instance;
        if (pool != null && go != null)
        {
            go.SetActive(false);
            pool.Return(VFX_POOL, go);
        }
        else if (go != null)
        {
            Destroy(go);
        }
    }

    BattleUnit FindNearestAlive(List<BattleUnit> units)
    {
        for (int i = 0; i < units.Count; i++)
            if (units[i] != null && !units[i].IsDead) return units[i];
        return null;
    }

    BattleUnit FindWeakestAlive(List<BattleUnit> units)
    {
        BattleUnit weakest = null;
        float lowestHpRatio = float.MaxValue;
        for (int i = 0; i < units.Count; i++)
        {
            if (units[i] == null || units[i].IsDead) continue;
            float ratio = units[i].CurrentHp / units[i].maxHp;
            if (ratio < lowestHpRatio)
            {
                lowestHpRatio = ratio;
                weakest = units[i];
            }
        }
        return weakest;
    }

    void AddAlive(List<BattleUnit> result, List<BattleUnit> source)
    {
        for (int i = 0; i < source.Count; i++)
            if (source[i] != null && !source[i].IsDead) result.Add(source[i]);
    }

    void OnDestroy()
    {
        if (Instance == this)
        {
            if (cachedVFXMaterial != null)
            {
                Destroy(cachedVFXMaterial);
                cachedVFXMaterial = null;
            }
            vfxPrefabCache.Clear();
        }
    }
}
