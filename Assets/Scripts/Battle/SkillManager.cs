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

    public event System.Action<int, float, float> OnCooldownChanged; // slot, remaining, total
    public event System.Action<int> OnSkillUsed;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(gameObject);
    }

    void Start()
    {
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
                cooldownTimers[i] -= Time.deltaTime;
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
        var targets = GetTargets(skill);
        if (targets == null || targets.Count == 0) return;

        foreach (var target in targets)
            ApplySkillEffect(skill, target);

        cooldownTimers[slotIndex] = skill.cooldown;
        OnSkillUsed?.Invoke(slotIndex);
    }

    List<BattleUnit> GetTargets(SkillData skill)
    {
        var manager = BattleManager.Instance;
        if (manager == null) return null;

        var result = new List<BattleUnit>();

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

    void ApplySkillEffect(SkillData skill, BattleUnit target)
    {
        switch (skill.effectType)
        {
            case SkillEffectType.Damage:
                target.TakeDamage(skill.value);
                SpawnSkillVFX(target.transform.position, skill.skillColor, SkillEffectType.Damage);
                break;
            case SkillEffectType.Heal:
                target.Heal(skill.value);
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

    // Cartoon FX Remaster prefab paths
    static readonly System.Collections.Generic.Dictionary<SkillEffectType, string> vfxPrefabPaths = new()
    {
        { SkillEffectType.Damage,  "VFX/CFXR Hit A (Red)" },
        { SkillEffectType.Burn,    "VFX/CFXR3 Hit Fire B (Air)" },
        { SkillEffectType.Freeze,  "VFX/CFXR3 Hit Ice B (Air)" },
        { SkillEffectType.Poison,  "VFX/CFXR3 Hit Fire B (Air)" },
        { SkillEffectType.Slow,    "VFX/CFXR3 Hit Electric C (Air)" },
        { SkillEffectType.Heal,    "VFX/CFXR4 Falling Stars" },
    };

    void SpawnSkillVFX(Vector3 position, Color color, SkillEffectType effectType = SkillEffectType.Damage)
    {
        // Try Cartoon FX Remaster prefab first
        if (vfxPrefabPaths.TryGetValue(effectType, out string path))
        {
            var prefab = Resources.Load<GameObject>(path);
            if (prefab != null)
            {
                var vfx = Instantiate(prefab, position, Quaternion.identity);
                vfx.transform.localScale = Vector3.one * 0.4f;
                Destroy(vfx, 2f);
                return;
            }
        }

        // Fallback: simple particle
        var go = new GameObject("SkillVFX");
        go.transform.position = position;

        var ps = go.AddComponent<ParticleSystem>();
        var main = ps.main;
        main.startLifetime = 0.5f;
        main.startSpeed = 3f;
        main.startSize = 0.15f;
        main.startColor = color;
        main.maxParticles = 20;
        main.duration = 0.3f;
        main.loop = false;

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

        Destroy(go, 1f);
    }

    BattleUnit FindNearestAlive(List<BattleUnit> units)
    {
        // For auto-targeting, just pick first alive
        for (int i = 0; i < units.Count; i++)
            if (!units[i].IsDead) return units[i];
        return null;
    }

    BattleUnit FindWeakestAlive(List<BattleUnit> units)
    {
        BattleUnit weakest = null;
        float lowestHpRatio = float.MaxValue;
        for (int i = 0; i < units.Count; i++)
        {
            if (units[i].IsDead) continue;
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
            if (!source[i].IsDead) result.Add(source[i]);
    }

    void OnDestroy()
    {
        if (cachedVFXMaterial != null)
        {
            Destroy(cachedVFXMaterial);
            cachedVFXMaterial = null;
        }
    }
}
