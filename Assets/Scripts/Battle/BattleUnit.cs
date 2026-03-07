using UnityEngine;

public class BattleUnit : MonoBehaviour
{
    public enum Team { Ally, Enemy }
    public enum UnitState { Idle, Moving, Attacking, Dead }

    [Header("Stats")]
    public string unitName = "Unit";
    public float maxHp = 100f;
    public float atk = 20f;
    public float def = 5f;
    public float moveSpeed = 2f;
    public float attackRange = 1.5f;
    public float attackCooldown = 1.0f;

    public float CurrentHp { get; set; }
    public bool IsDead => CurrentHp <= 0;
    public Team CurrentTeam { get; private set; }
    public UnitState CurrentState { get; private set; } = UnitState.Idle;

    public event System.Action<float, float> OnHpChanged;
    public event System.Action<float> OnDamageTaken;
    public event System.Action OnDeath;

    private BattleUnit target;
    private float attackTimer;
    private Animator animator;
    private Transform spriteRoot;
    private AttackAnimType attackAnimType;
    private StatusEffectController statusEffects;

    // Temp buff tracking
    private float buffAtk;
    private float buffDef;
    private float buffTimer;

    static readonly System.Collections.Generic.Dictionary<AttackAnimType, string> AttackClipPaths = new()
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
        CurrentHp = maxHp;
        attackAnimType = animType;
        animator = GetComponentInChildren<Animator>();
        statusEffects = GetComponent<StatusEffectController>();
        if (statusEffects == null)
            statusEffects = gameObject.AddComponent<StatusEffectController>();
        if (transform.childCount > 0)
            spriteRoot = transform.GetChild(0);

        // Override attack animation based on weapon type
        if (animator != null && AttackClipPaths.TryGetValue(animType, out string clipPath))
        {
            var clip = Resources.Load<AnimationClip>(clipPath);
            if (clip != null)
            {
                var overrideCtrl = new AnimatorOverrideController(animator.runtimeAnimatorController);
                // SPUM ATTACK state uses "ATTACK" clip name
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

    public float advanceSpeed = 1.5f;

    void Update()
    {
        if (IsDead || BattleManager.Instance == null ||
            BattleManager.Instance.CurrentState != BattleManager.BattleState.Fighting)
            return;

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

        if (target == null || target.IsDead)
        {
            target = BattleManager.Instance.FindNearestEnemy(this);
            if (target == null)
            {
                // Allies auto-advance right when no enemies
                if (CurrentTeam == Team.Ally)
                {
                    SetState(UnitState.Moving);
                    transform.position += Vector3.right * advanceSpeed * Time.deltaTime;
                    if (spriteRoot != null)
                        spriteRoot.localScale = new Vector3(-1, 1, 1); // face right
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

    void ClampY()
    {
        // Clamp Y to middle 3/5 of screen
        float camH = Camera.main != null ? Camera.main.orthographicSize * 2f : 8f;
        float halfZone = camH * 0.3f; // 3/5 / 2
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

        // Flip sprite based on direction
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

        // Face target while attacking
        if (spriteRoot != null)
        {
            float dirX = target.transform.position.x - transform.position.x;
            spriteRoot.localScale = new Vector3(dirX > 0 ? -1 : 1, 1, 1);
        }

        float atkSpeedMult = statusEffects != null ? statusEffects.GetAttackSpeedMultiplier() : 1f;
        attackTimer -= Time.deltaTime * atkSpeedMult;

        if (attackTimer <= 0f)
        {
            float damage = Mathf.Max(1f, atk - target.def);

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

    public void TakeDamage(float damage, bool ignoreDefense = false)
    {
        if (IsDead) return;

        CurrentHp = Mathf.Max(0, CurrentHp - damage);
        OnHpChanged?.Invoke(CurrentHp, maxHp);
        OnDamageTaken?.Invoke(damage);

        DamagePopup.Create(transform.position + Vector3.up * 0.5f, damage);

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

        // Cache original colors
        if (originalColors == null || originalColors.Length != cachedRenderers.Length)
            originalColors = new Color[cachedRenderers.Length];

        for (int i = 0; i < cachedRenderers.Length; i++)
        {
            if (cachedRenderers[i] != null)
                originalColors[i] = cachedRenderers[i].color;
        }

        // Flash white
        for (int i = 0; i < cachedRenderers.Length; i++)
        {
            if (cachedRenderers[i] != null)
                cachedRenderers[i].color = Color.white;
        }

        yield return new WaitForSeconds(0.08f);

        // Restore
        for (int i = 0; i < cachedRenderers.Length; i++)
        {
            if (cachedRenderers[i] != null)
                cachedRenderers[i].color = originalColors[i];
        }

        flashRoutine = null;
    }

    public void Heal(float amount)
    {
        if (IsDead) return;
        CurrentHp = Mathf.Min(maxHp, CurrentHp + amount);
        OnHpChanged?.Invoke(CurrentHp, maxHp);
        DamagePopup.Create(transform.position + Vector3.up * 0.5f, amount, true);
    }

    public void ApplyBuff(float atkBonus, float defBonus, float duration)
    {
        // Remove previous buff if active
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

        if (animator != null)
        {
            animator.SetBool("isDeath", true);
            animator.SetTrigger("4_Death");
        }

        Invoke(nameof(DisableUnit), 1.5f);
    }

    void DisableUnit()
    {
        gameObject.SetActive(false);
    }

    void SetState(UnitState newState)
    {
        if (CurrentState == newState) return;
        CurrentState = newState;

        if (animator == null) return;

        // SPUM Animator parameters: 1_Move (bool), 2_Attack (trigger), isDeath (bool)
        animator.SetBool("1_Move", newState == UnitState.Moving);

        if (newState == UnitState.Attacking)
            animator.SetTrigger("2_Attack");
    }
}
