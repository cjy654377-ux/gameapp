using UnityEngine;
using System.Collections.Generic;

public class BattleUnit : MonoBehaviour
{
    public enum Team { Ally, Enemy }
    public enum UnitState { Idle, Moving, Attacking, Dead }
    public enum RoleType { Attacker, Healer, Buffer }

    [Header("Stats")]
    public string unitName = "Unit";
    public float maxHp = 100f;
    public float atk = 20f;
    public float def = 5f;
    public float moveSpeed = 1.2f;
    public float attackRange = 1.5f;
    public float attackCooldown = 1.0f;
    public float advanceSpeed = 0.8f;

    [Header("Element & Resist")]
    public DamageElement damageElement = DamageElement.Physical;
    public float lightningResist = 0f;
    public float poisonResist = 0f;

    [Header("Support")]
    public RoleType role = RoleType.Attacker;
    public float healAmount = 0f;
    public float healCooldown = 3f;
    public float healRange = 3f;
    public float buffAtkBonus = 0f;
    public float buffDefBonus = 0f;
    public float buffDuration = 5f;
    public float buffCooldown = 8f;
    public float buffRange = 4f;

    // Base stats (set once at creation, used by UpgradeManager)
    [HideInInspector] public float baseMaxHp;
    [HideInInspector] public float baseAtk;
    [HideInInspector] public float baseDef;
    [HideInInspector] public float baseMoveSpeed;
    [HideInInspector] public float baseAdvanceSpeed;

    public float CurrentHp { get; set; }
    public bool IsDead => CurrentHp <= 0;
    public Team CurrentTeam { get; private set; }
    public UnitState CurrentState { get; private set; } = UnitState.Idle;

    public event System.Action<float, float> OnHpChanged;
    public event System.Action<float> OnDamageTaken;
    public event System.Action OnDeath;

    private BattleUnit target;
    private float attackTimer;
    private float supportTimer = 1f;
    private Animator animator;
    private Camera cachedCamera;
    private Transform spriteRoot;
    private AttackAnimType attackAnimType;
    private StatusEffectController statusEffects;
    private float retargetTimer;

    public StatusEffectController StatusEffects => statusEffects;

    // Temp buff tracking (public read for UpgradeManager compatibility)
    [HideInInspector] public float buffAtk;
    [HideInInspector] public float buffDef;
    private float buffTimer;

    // Per-unit skill system
    [HideInInspector] public SkillData[] skills;
    readonly float[] skillCooldowns = new float[2];
    readonly List<BattleUnit> skillTargetBuffer = new();

    public event System.Action<int, float, float> OnSkillCooldownChanged; // slot, remaining, total
    public event System.Action<int, SkillData> OnSkillActivated;

    static readonly Dictionary<AttackAnimType, string> AttackClipPaths = new()
    {
        { AttackAnimType.Melee,     "Addons/Legacy/0_Unit/1_Animation/02_Attack/00_MeleeAttack/0_Attack_Normal" },
        { AttackAnimType.Axe,       "Addons/Ver300/0_Unit/1_Animation/02_Attack/00_MeleeAttack/AxeAttack_1" },
        { AttackAnimType.Spear,     "Addons/Ver300/0_Unit/1_Animation/02_Attack/00_MeleeAttack/LongSpearAttack_1" },
        { AttackAnimType.ShotSword, "Addons/Ver300/0_Unit/1_Animation/02_Attack/00_MeleeAttack/ShotSwordAttack_1" },
        { AttackAnimType.Bow,       "Addons/Legacy/0_Unit/1_Animation/02_Attack/01_LongRangeAttack/0_Attack_Bow" },
        { AttackAnimType.Magic,     "Addons/Legacy/0_Unit/1_Animation/02_Attack/02_MagicAttack/0_Attack_Magic" },
    };

    public void Init(AttackAnimType animType = AttackAnimType.Melee)
    {
        // Store base stats for upgrade system
        baseMaxHp = maxHp;
        baseAtk = atk;
        baseDef = def;
        baseMoveSpeed = moveSpeed;
        baseAdvanceSpeed = advanceSpeed;

        CurrentHp = maxHp;
        attackAnimType = animType;
        cachedCamera = Camera.main;
        animator = GetComponentInChildren<Animator>();
        statusEffects = GetComponent<StatusEffectController>();
        if (statusEffects == null)
            statusEffects = gameObject.AddComponent<StatusEffectController>();
        if (transform.childCount > 0)
            spriteRoot = transform.GetChild(0);

        if (animator != null && AttackClipPaths.TryGetValue(animType, out string clipPath))
        {
            var clip = Resources.Load<AnimationClip>(clipPath);
            if (clip != null)
            {
                var overrideCtrl = new AnimatorOverrideController(animator.runtimeAnimatorController);
                overrideCtrl["ATTACK"] = clip;
                animator.runtimeAnimatorController = overrideCtrl;
            }
        }
    }

    public void SetTeam(Team team)
    {
        CurrentTeam = team;
        if (team == Team.Enemy && spriteRoot != null)
            spriteRoot.localScale = new Vector3(-1, 1, 1);
    }

    void Update()
    {
        if (IsDead || BattleManager.Instance == null ||
            BattleManager.Instance.CurrentState != BattleManager.BattleState.Fighting)
            return;

        // Stun check
        if (stunTimer > 0f)
        {
            stunTimer -= Time.deltaTime;
            return;
        }

        // Skill auto-use
        UpdateSkills();

        // Buff timer
        if (buffTimer > 0f)
        {
            buffTimer -= Time.deltaTime;
            if (buffTimer <= 0f)
            {
                atk -= buffAtk;
                def -= buffDef;
                buffAtk = 0f;
                buffDef = 0f;
            }
        }

        // Support roles: heal/buff allies first
        if (CurrentTeam == Team.Ally && role != RoleType.Attacker)
        {
            supportTimer -= Time.deltaTime;
            if (supportTimer <= 0f)
            {
                if (TrySupportAction())
                {
                    ClampY();
                    return;
                }
                else
                {
                    supportTimer = 0.5f; // retry interval instead of every frame
                }
            }
        }

        if (target == null || target.IsDead)
        {
            retargetTimer -= Time.deltaTime;
            if (retargetTimer <= 0f)
            {
                target = BattleManager.Instance.FindNearestEnemy(this);
                retargetTimer = 0.2f;
            }
            if (target == null)
            {
                if (CurrentTeam == Team.Ally)
                {
                    SetState(UnitState.Moving);
                    transform.position += Vector3.right * advanceSpeed * Time.deltaTime;
                    if (spriteRoot != null)
                        spriteRoot.localScale = new Vector3(1, 1, 1);
                }
                else
                {
                    SetState(UnitState.Idle);
                }
                ClampY();
                return;
            }
        }

        float distToTarget = Vector2.Distance(transform.position, target.transform.position);

        if (distToTarget > attackRange)
            MoveToTarget();
        else
            AttackTarget();

        ClampY();
    }

    bool TrySupportAction()
    {
        var allies = BattleManager.Instance.allyUnits;

        if (role == RoleType.Healer)
        {
            // Find most injured ally in range
            BattleUnit mostInjured = null;
            float lowestRatio = 1f;

            for (int i = 0; i < allies.Count; i++)
            {
                if (allies[i] == null || allies[i].IsDead || allies[i] == this) continue;
                float ratio = allies[i].CurrentHp / allies[i].maxHp;
                float dist = Vector2.Distance(transform.position, allies[i].transform.position);
                if (ratio < 0.8f && dist <= healRange && ratio < lowestRatio)
                {
                    lowestRatio = ratio;
                    mostInjured = allies[i];
                }
            }

            if (mostInjured != null)
            {
                mostInjured.Heal(healAmount);
                supportTimer = healCooldown;
                SetState(UnitState.Attacking);
                if (animator != null) animator.SetTrigger("2_Attack");
                return true;
            }
        }
        else if (role == RoleType.Buffer)
        {
            // Buff ally with no active buff, nearest first
            BattleUnit buffTarget = null;
            float minDist = float.MaxValue;

            for (int i = 0; i < allies.Count; i++)
            {
                if (allies[i] == null || allies[i].IsDead || allies[i] == this) continue;
                float dist = Vector2.Distance(transform.position, allies[i].transform.position);
                if (dist <= buffRange && dist < minDist)
                {
                    minDist = dist;
                    buffTarget = allies[i];
                }
            }

            if (buffTarget != null)
            {
                buffTarget.ApplyBuff(buffAtkBonus, buffDefBonus, buffDuration);
                supportTimer = buffCooldown;
                SetState(UnitState.Attacking);
                if (animator != null) animator.SetTrigger("2_Attack");
                return true;
            }
        }

        return false;
    }

    void UpdateSkills()
    {
        if (skills == null || CurrentTeam != Team.Ally) return;

        for (int i = 0; i < skills.Length && i < 2; i++)
        {
            if (skills[i] == null) continue;
            if (skillCooldowns[i] > 0f)
            {
                skillCooldowns[i] -= Time.deltaTime;
                OnSkillCooldownChanged?.Invoke(i, skillCooldowns[i], skills[i].cooldown);
            }
            else
            {
                UseUnitSkill(i);
            }
        }
    }

    void UseUnitSkill(int slot)
    {
        var skill = skills[slot];
        var sm = SkillManager.Instance;
        if (sm == null) return;

        // Delegate to SkillManager for consistent effect application
        var targets = GetSkillTargets(skill);
        if (targets == null || targets.Count == 0) return;

        for (int i = 0; i < targets.Count; i++)
            sm.ApplyEffect(skill, targets[i]);

        skillCooldowns[slot] = skill.cooldown;
        OnSkillActivated?.Invoke(slot, skill);
    }

    List<BattleUnit> GetSkillTargets(SkillData skill)
    {
        var manager = BattleManager.Instance;
        if (manager == null) return null;

        skillTargetBuffer.Clear();
        var result = skillTargetBuffer;
        switch (skill.targetType)
        {
            case SkillTargetType.SingleEnemy:
                if (target != null && !target.IsDead) result.Add(target);
                else
                {
                    var nearest = manager.FindNearestEnemy(this);
                    if (nearest != null) result.Add(nearest);
                }
                break;
            case SkillTargetType.AllEnemies:
                var enemies = manager.enemyUnits;
                for (int i = 0; i < enemies.Count; i++)
                    if (enemies[i] != null && !enemies[i].IsDead) result.Add(enemies[i]);
                break;
            case SkillTargetType.SingleAlly:
                BattleUnit weakest = null;
                float lowestRatio = 1f;
                var allies = manager.allyUnits;
                for (int i = 0; i < allies.Count; i++)
                {
                    if (allies[i] == null || allies[i].IsDead) continue;
                    float ratio = allies[i].CurrentHp / allies[i].maxHp;
                    if (ratio < lowestRatio) { lowestRatio = ratio; weakest = allies[i]; }
                }
                if (weakest != null) result.Add(weakest);
                break;
            case SkillTargetType.AllAllies:
                var allAllies = manager.allyUnits;
                for (int i = 0; i < allAllies.Count; i++)
                    if (allAllies[i] != null && !allAllies[i].IsDead) result.Add(allAllies[i]);
                break;
            case SkillTargetType.Self:
                result.Add(this);
                break;
        }
        return result;
    }

    void ClampY()
    {
        float camH = cachedCamera != null ? cachedCamera.orthographicSize * 2f : 10f;
        float halfZone = camH * 0.3f;
        var pos = transform.position;
        pos.y = Mathf.Clamp(pos.y, -halfZone, halfZone);
        transform.position = pos;
    }

    void MoveToTarget()
    {
        SetState(UnitState.Moving);
        Vector3 direction = (target.transform.position - transform.position).normalized;
        float speedMult = statusEffects != null ? statusEffects.GetSpeedMultiplier() : 1f;
        transform.position += direction * moveSpeed * speedMult * Time.deltaTime;

        if (spriteRoot != null)
        {
            if (direction.x > 0)
                spriteRoot.localScale = new Vector3(-1, 1, 1);
            else if (direction.x < 0)
                spriteRoot.localScale = new Vector3(1, 1, 1);
        }
    }

    bool IsRanged => attackAnimType == AttackAnimType.Bow || attackAnimType == AttackAnimType.Magic;

    void AttackTarget()
    {
        SetState(UnitState.Attacking);

        if (spriteRoot != null)
        {
            float dirX = target.transform.position.x - transform.position.x;
            spriteRoot.localScale = new Vector3(dirX > 0 ? -1 : 1, 1, 1);
        }

        float atkSpeedMult = statusEffects != null ? statusEffects.GetAttackSpeedMultiplier() : 1f;
        attackTimer -= Time.deltaTime * atkSpeedMult;

        if (attackTimer <= 0f)
        {
            float damage = CalcDamage(target);

            if (IsRanged)
            {
                var projType = attackAnimType == AttackAnimType.Bow ? ProjectileType.Arrow : ProjectileType.MagicBolt;
                Projectile.Spawn(transform.position + Vector3.up * 0.3f, target, damage, projType);
            }
            else
            {
                target.TakeDamage(damage);
            }

            attackTimer = attackCooldown;
        }
    }

    float CalcDamage(BattleUnit defender)
    {
        float baseDmg = Mathf.Max(1f, atk - defender.def);

        // Element bonus damage
        float elementMult = 1f;
        switch (damageElement)
        {
            case DamageElement.Lightning:
                elementMult = 1f + 0.5f * (1f - defender.lightningResist);
                break;
            case DamageElement.Poison:
                elementMult = 1f + 0.5f * (1f - defender.poisonResist);
                break;
        }

        return baseDmg * elementMult;
    }

    public void TakeDamage(float damage, bool ignoreDefense = false)
    {
        if (IsDead) return;

        CurrentHp = Mathf.Max(0, CurrentHp - damage);
        OnHpChanged?.Invoke(CurrentHp, maxHp);
        OnDamageTaken?.Invoke(damage);

        DamagePopup.Create(transform.position + Vector3.up * 0.5f, damage);

        if (EffectManager.Instance != null)
            EffectManager.Instance.SpawnHitEffect(transform.position);
        if (SoundManager.Instance != null)
            SoundManager.Instance.PlayHitSFX();

        if (animator != null)
            animator.SetTrigger("3_Damaged");

        FlashWhite();

        if (CurrentHp <= 0)
            Die();
    }

    void FlashWhite()
    {
        if (flashRoutine != null)
            StopCoroutine(flashRoutine);
        flashRoutine = StartCoroutine(FlashWhiteRoutine());
    }

    private Coroutine flashRoutine;
    private SpriteRenderer[] cachedRenderers;
    private Color[] originalColors;

    System.Collections.IEnumerator FlashWhiteRoutine()
    {
        if (cachedRenderers == null)
            cachedRenderers = GetComponentsInChildren<SpriteRenderer>();

        if (originalColors == null || originalColors.Length != cachedRenderers.Length)
            originalColors = new Color[cachedRenderers.Length];

        for (int i = 0; i < cachedRenderers.Length; i++)
            if (cachedRenderers[i] != null) originalColors[i] = cachedRenderers[i].color;

        for (int i = 0; i < cachedRenderers.Length; i++)
            if (cachedRenderers[i] != null) cachedRenderers[i].color = Color.white;

        yield return new WaitForSeconds(0.08f);

        for (int i = 0; i < cachedRenderers.Length; i++)
            if (cachedRenderers[i] != null) cachedRenderers[i].color = originalColors[i];

        flashRoutine = null;
    }

    public void NotifyHpChanged()
    {
        OnHpChanged?.Invoke(CurrentHp, maxHp);
    }

    public void Heal(float amount)
    {
        if (IsDead) return;
        CurrentHp = Mathf.Min(maxHp, CurrentHp + amount);
        OnHpChanged?.Invoke(CurrentHp, maxHp);
        DamagePopup.Create(transform.position + Vector3.up * 0.5f, amount, true);
        if (EffectManager.Instance != null)
            EffectManager.Instance.SpawnHealEffect(transform.position + Vector3.up * 0.5f);
    }

    float stunTimer;

    public void ApplyStun(float duration)
    {
        if (IsDead) return;
        stunTimer = Mathf.Max(stunTimer, duration);
    }

    public bool IsStunned => stunTimer > 0f;

    public void ApplyBuff(float atkBonus, float defBonus, float duration)
    {
        if (buffTimer > 0f)
        {
            atk -= buffAtk;
            def -= buffDef;
        }
        buffAtk = atkBonus;
        buffDef = defBonus;
        buffTimer = duration;
        atk += buffAtk;
        def += buffDef;
    }

    void Die()
    {
        SetState(UnitState.Dead);
        OnDeath?.Invoke();

        // Track kills for HUD
        if (CurrentTeam == Team.Enemy && MainHUD.Instance != null)
            MainHUD.Instance.AddKill();

        if (animator != null)
        {
            animator.SetBool("isDeath", true);
            animator.SetTrigger("4_Death");
        }

        // Stop flash before fade to preserve original colors
        if (flashRoutine != null)
        {
            StopCoroutine(flashRoutine);
            flashRoutine = null;
        }
        StartCoroutine(DeathFadeOut());
    }

    System.Collections.IEnumerator DeathFadeOut()
    {
        float duration = 1.2f;
        float elapsed = 0f;

        // Collect all sprite renderers
        var renderers = GetComponentsInChildren<SpriteRenderer>();
        var originalColors = new Color[renderers.Length];
        for (int i = 0; i < renderers.Length; i++)
            originalColors[i] = renderers[i].color;

        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            float alpha = 1f - (elapsed / duration);
            for (int i = 0; i < renderers.Length; i++)
            {
                if (renderers[i] != null)
                {
                    var c = originalColors[i];
                    c.a = alpha;
                    renderers[i].color = c;
                }
            }
            yield return null;
        }

        // Restore colors before disable (for pool reuse)
        for (int i = 0; i < renderers.Length; i++)
        {
            if (renderers[i] != null)
                renderers[i].color = originalColors[i];
        }

        DisableUnit();
    }

    void DisableUnit()
    {
        gameObject.SetActive(false);
    }

    void OnDisable()
    {
        CancelInvoke(nameof(DisableUnit));
    }

    /// <summary>
    /// 패배 복귀 시 아군 부활
    /// </summary>
    public void Revive()
    {
        StopAllCoroutines();
        gameObject.SetActive(true);
        // Restore alpha after death fade
        var renderers = GetComponentsInChildren<SpriteRenderer>();
        for (int i = 0; i < renderers.Length; i++)
        {
            if (renderers[i] != null)
            {
                var c = renderers[i].color;
                c.a = 1f;
                renderers[i].color = c;
            }
        }
        CurrentHp = maxHp;
        CurrentState = UnitState.Idle;
        target = null;
        attackTimer = 0f;
        buffTimer = 0f;
        buffAtk = 0f;
        buffDef = 0f;
        stunTimer = 0f;
        for (int i = 0; i < skillCooldowns.Length; i++) skillCooldowns[i] = 0f;
        OnHpChanged?.Invoke(CurrentHp, maxHp);

        if (animator != null)
        {
            animator.SetBool("isDeath", false);
            animator.SetBool("1_Move", false);
            animator.Rebind();
            animator.Update(0f);
        }
    }

    void SetState(UnitState newState)
    {
        if (CurrentState == newState) return;
        CurrentState = newState;

        if (animator == null) return;

        animator.SetBool("1_Move", newState == UnitState.Moving);

        if (newState == UnitState.Attacking)
            animator.SetTrigger("2_Attack");
    }
}
