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
    public SkillElement damageElement = SkillElement.None;
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

    [HideInInspector] public CharacterPreset cachedPreset;

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

    // Animator parameter name constants
    const string ANIM_MOVE     = "1_Move";
    const string ANIM_ATTACK   = "2_Attack";
    const string ANIM_DAMAGED  = "3_Damaged";
    const string ANIM_DEATH    = "4_Death";
    const string ANIM_IS_DEATH = "isDeath";
    const float  DEATH_FADE_DURATION = 0.3f;

    static readonly Dictionary<AttackAnimType, string> AttackClipPaths = new()
    {
        { AttackAnimType.Melee,     "Addons/Legacy/0_Unit/1_Animation/02_Attack/00_MeleeAttack/0_Attack_Normal" },
        { AttackAnimType.Axe,       "Addons/Ver300/0_Unit/1_Animation/02_Attack/00_MeleeAttack/AxeAttack_1" },
        { AttackAnimType.Spear,     "Addons/Ver300/0_Unit/1_Animation/02_Attack/00_MeleeAttack/LongSpearAttack_1" },
        { AttackAnimType.ShotSword, "Addons/Ver300/0_Unit/1_Animation/02_Attack/00_MeleeAttack/ShotSwordAttack_1" },
        { AttackAnimType.Bow,       "Addons/Legacy/0_Unit/1_Animation/02_Attack/01_LongRangeAttack/1_Skill_Bow" },
        { AttackAnimType.Magic,     "Addons/Legacy/0_Unit/1_Animation/02_Attack/02_MagicAttack/0_Attack_Magic" },
    };

    public void Init(AttackAnimType animType = AttackAnimType.Melee)
    {
        // Store base stats for upgrade system
        baseMaxHp = maxHp;
        baseAtk = atk;
        baseDef = def;
        baseMoveSpeed = moveSpeed;

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
            else
            {
                Debug.LogWarning($"[BattleUnit] Attack clip not found: {clipPath} for {unitName}");
            }
        }
        else if (animator == null)
        {
            Debug.LogWarning($"[BattleUnit] No Animator found for {unitName}");
        }
    }

    public void SetTeam(Team team)
    {
        CurrentTeam = team;
        // SPUM 스프라이트 기본 방향: 왼쪽
        // 아군(오른쪽 전진) = -1 (반전), 적(왼쪽 전진) = 1 (기본)
        if (spriteRoot != null)
            spriteRoot.localScale = new Vector3(team == Team.Ally ? -1 : 1, 1, 1);
    }

    void Update()
    {
        if (IsDead || BattleManager.Instance == null ||
            BattleManager.Instance.CurrentState != BattleManager.BattleState.Fighting)
            return;

        // Stun check
        if (stunTimer > 0f)
        {
            stunTimer -= Time.unscaledDeltaTime;
            return;
        }

        // Skill auto-use
        UpdateSkills();

        // Buff timer
        if (buffTimer > 0f)
        {
            buffTimer -= Time.unscaledDeltaTime;
            if (buffTimer <= 0f)
            {
                buffAtk = 0f;
                buffDef = 0f;
                UpgradeManager.ApplyAllBonuses(this);
            }
        }

        // Support roles: heal/buff allies first
        if (CurrentTeam == Team.Ally && role != RoleType.Attacker)
        {
            supportTimer -= Time.unscaledDeltaTime;
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
            retargetTimer -= Time.unscaledDeltaTime;
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
                    transform.position += Vector3.right * advanceSpeed * Time.unscaledDeltaTime;
                    if (spriteRoot != null)
                        spriteRoot.localScale = new Vector3(-1, 1, 1); // 오른쪽 전진 = 반전
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
                if (animator != null) animator.SetTrigger(ANIM_ATTACK);
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
                if (animator != null) animator.SetTrigger(ANIM_ATTACK);
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
                skillCooldowns[i] -= Time.unscaledDeltaTime;
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

        // 스킬 업그레이드 쿨타임 배율 적용
        var skillUpgrade = SkillUpgradeManager.Instance;
        float cdMult = skillUpgrade != null ? skillUpgrade.GetCooldownMultiplier(skill.skillName) : 1f;
        skillCooldowns[slot] = skill.cooldown * cdMult;
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
        transform.position += direction * moveSpeed * speedMult * Time.unscaledDeltaTime;

        if (spriteRoot != null)
        {
            // SPUM 기본 방향 왼쪽: 오른쪽 이동 = -1(반전), 왼쪽 이동 = 1(기본)
            if (direction.x > 0)
                spriteRoot.localScale = new Vector3(-1, 1, 1);
            else if (direction.x < 0)
                spriteRoot.localScale = new Vector3(1, 1, 1);
        }
    }

    bool IsRanged => attackAnimType == AttackAnimType.Bow || attackAnimType == AttackAnimType.Magic;

    const float CRIT_CHANCE = 0.20f;
    const float CRIT_MULT   = 1.5f;

    void AttackTarget()
    {
        SetState(UnitState.Attacking);

        if (spriteRoot != null)
        {
            // SPUM 기본 방향 왼쪽: 적이 오른쪽에 있으면 -1(반전), 왼쪽이면 1(기본)
            float dirX = target.transform.position.x - transform.position.x;
            spriteRoot.localScale = new Vector3(dirX > 0 ? -1 : 1, 1, 1);
        }

        float atkSpeedMult = statusEffects != null ? statusEffects.GetAttackSpeedMultiplier() : 1f;
        attackTimer -= Time.unscaledDeltaTime * atkSpeedMult;

        if (attackTimer <= 0f)
        {
            // 매 공격마다 애니메이션 트리거 발동
            if (animator != null)
                animator.SetTrigger(ANIM_ATTACK);

            float damage = CalcDamage(target);
            bool isCrit = Random.value < CRIT_CHANCE;
            if (isCrit) damage *= CRIT_MULT;

            if (IsRanged)
            {
                var projType = attackAnimType == AttackAnimType.Bow ? ProjectileType.Arrow : ProjectileType.MagicBolt;
                Projectile.Spawn(transform.position + Vector3.up * 0.3f, target, damage, projType);
            }
            else
            {
                target.TakeDamage(damage, false, isCrit);
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
            case SkillElement.Lightning:
                elementMult = 1f + 0.5f * (1f - defender.lightningResist);
                break;
            case SkillElement.Poison:
                elementMult = 1f + 0.5f * (1f - defender.poisonResist);
                break;
        }

        return baseDmg * elementMult;
    }

    public void TakeDamage(float damage, bool ignoreDefense = false, bool isCrit = false)
    {
        if (IsDead) return;

        CurrentHp = Mathf.Max(0, CurrentHp - damage);
        OnHpChanged?.Invoke(CurrentHp, maxHp);
        OnDamageTaken?.Invoke(damage);

        if (isCrit)
        {
            DamagePopup.CreateCritical(transform.position + Vector3.up * 0.6f, damage);
        }
        else
        {
            DamagePopup.Create(transform.position + Vector3.up * 0.5f, damage);
        }

        if (EffectManager.Instance != null)
            EffectManager.Instance.SpawnHitEffect(transform.position);
        if (SoundManager.Instance != null)
            SoundManager.Instance.PlayHitSFX();

        if (animator != null)
            animator.SetTrigger(ANIM_DAMAGED);

        FlashWhite();
        KnockbackShake();

        if (CurrentHp <= 0)
            Die();
    }

    Coroutine _knockbackRoutine;

    void KnockbackShake()
    {
        if (_knockbackRoutine != null) StopCoroutine(_knockbackRoutine);
        _knockbackRoutine = StartCoroutine(KnockbackShakeRoutine());
    }

    System.Collections.IEnumerator KnockbackShakeRoutine()
    {
        const float DURATION  = 0.08f;
        const float MAGNITUDE = 0.04f;
        float elapsed  = 0f;
        float prevOffset = 0f;
        // 피격 방향: 적은 왼쪽으로, 아군은 오른쪽으로 밀림
        float dir = CurrentTeam == Team.Enemy ? -1f : 1f;

        while (elapsed < DURATION)
        {
            float t = elapsed / DURATION;
            float offset = Mathf.Sin(t * Mathf.PI * 5f) * MAGNITUDE * (1f - t) * dir;
            var pos = transform.position;
            pos.x += offset - prevOffset;
            transform.position = pos;
            prevOffset = offset;
            elapsed += Time.unscaledDeltaTime;
            yield return null;
        }

        // 누적 오프셋 되돌리기
        var p = transform.position;
        p.x -= prevOffset;
        transform.position = p;
        _knockbackRoutine = null;
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
        // 기존 버프 제거 후 새 버프 적용 (base 기반 계산으로 마이너스 방지)
        buffAtk = atkBonus;
        buffDef = defBonus;
        buffTimer = duration;
        // UpgradeManager가 base+bonus+buff를 재계산
        UpgradeManager.ApplyAllBonuses(this);
    }

    void Die()
    {
        SetState(UnitState.Dead);
        OnDeath?.Invoke();

        // Track kills for HUD + daily missions + achievements + stats
        if (CurrentTeam == Team.Enemy)
        {
            MainHUD.Instance?.AddKill();
            DailyMissionManager.Instance?.RegisterKill();
            AchievementManager.Instance?.RegisterKill();
            GameStatsManager.Instance?.AddKill();
        }

        if (animator != null)
        {
            animator.SetBool(ANIM_IS_DEATH, true);
            animator.SetTrigger(ANIM_DEATH);
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
        float duration = DEATH_FADE_DURATION;
        float elapsed = 0f;

        // Collect all sprite renderers
        var renderers = GetComponentsInChildren<SpriteRenderer>();
        var originalColors = new Color[renderers.Length];
        for (int i = 0; i < renderers.Length; i++)
            originalColors[i] = renderers[i].color;

        while (elapsed < duration)
        {
            elapsed += Time.unscaledDeltaTime;
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
            animator.SetBool(ANIM_IS_DEATH, false);
            animator.SetBool(ANIM_MOVE, false);
            animator.Rebind();
            animator.Update(0f);
        }
    }

    void SetState(UnitState newState)
    {
        if (CurrentState == newState) return;
        CurrentState = newState;

        if (animator == null) return;

        animator.SetBool(ANIM_MOVE, newState == UnitState.Moving);

        if (newState == UnitState.Attacking)
            animator.SetTrigger(ANIM_ATTACK);
    }

    // ────────────────────────────────────────
    // 장비 외형 변경
    // ────────────────────────────────────────

    /// <summary>
    /// 장비 장착/해제 시 SPUM 스프라이트를 교체.
    /// equip=true → item.weaponSprite 적용, false → cachedPreset 기본 스프라이트 복원.
    /// </summary>
    public void UpdateEquipmentVisual(EquipmentItem item, bool equip)
    {
        if (item == null) return;
        var renderers = GetComponentsInChildren<SpriteRenderer>();

        if (equip)
        {
            // weaponSprite 없으면 등급별 기본값 사용
            string spriteName = !string.IsNullOrEmpty(item.weaponSprite)
                ? item.weaponSprite
                : GetFallbackSpriteName(item.slot, item.rarity);
            if (string.IsNullOrEmpty(spriteName)) return;

            switch (item.slot)
            {
                case EquipmentSlot.Weapon:
                    var ws = CharacterFactory.FindWeaponSprite(spriteName);
                    if (ws != null) foreach (var sr in renderers)
                        if (sr.gameObject.name == "R_Weapon") { sr.sprite = ws; break; }
                    break;
                case EquipmentSlot.Shield:
                    var ss = CharacterFactory.FindWeaponSprite(spriteName);
                    if (ss != null) foreach (var sr in renderers)
                        if (sr.gameObject.name == "L_Weapon") { sr.sprite = ss; break; }
                    break;
                case EquipmentSlot.Helmet:
                    var hs = CharacterFactory.LoadSprites($"Addons/Legacy/0_Unit/0_Sprite/4_Helmet/{spriteName}");
                    if (hs != null && hs.Length > 0) foreach (var sr in renderers)
                        if (sr.gameObject.name == "11_Helmet1") { sr.sprite = hs[0]; break; }
                    break;
                case EquipmentSlot.Armor:
                    var armorSpr = CharacterFactory.LoadSprites($"Addons/Legacy/0_Unit/0_Sprite/5_Armor/{spriteName}");
                    if (armorSpr != null && armorSpr.Length > 0)
                        ApplyArmorSprites(renderers, armorSpr);
                    break;
            }
        }
        else
        {
            if (cachedPreset == null) return;
            switch (item.slot)
            {
                case EquipmentSlot.Weapon:
                    var ws = CharacterFactory.FindWeaponSprite(cachedPreset.weaponSprite);
                    foreach (var sr in renderers)
                        if (sr.gameObject.name == "R_Weapon") { sr.sprite = ws; break; }
                    break;
                case EquipmentSlot.Shield:
                    var ss = CharacterFactory.FindWeaponSprite(cachedPreset.shieldSprite);
                    foreach (var sr in renderers)
                        if (sr.gameObject.name == "L_Weapon") { sr.sprite = ss; break; }
                    break;
                case EquipmentSlot.Helmet:
                    var hs = !string.IsNullOrEmpty(cachedPreset.helmetSprite)
                        ? CharacterFactory.LoadSprites($"Addons/Legacy/0_Unit/0_Sprite/4_Helmet/{cachedPreset.helmetSprite}") : null;
                    foreach (var sr in renderers)
                        if (sr.gameObject.name == "11_Helmet1") { sr.sprite = hs != null && hs.Length > 0 ? hs[0] : null; break; }
                    break;
                case EquipmentSlot.Armor:
                    if (!string.IsNullOrEmpty(cachedPreset.armorSprite))
                    {
                        var armorSpr = CharacterFactory.LoadSprites($"Addons/Legacy/0_Unit/0_Sprite/5_Armor/{cachedPreset.armorSprite}");
                        if (armorSpr != null && armorSpr.Length > 0)
                            ApplyArmorSprites(renderers, armorSpr);
                    }
                    break;
            }
        }
    }

    static void ApplyArmorSprites(SpriteRenderer[] renderers, Sprite[] armorSprites)
    {
        foreach (var sr in renderers)
        {
            if (sr.gameObject.name == "BodyArmor")
                sr.sprite = CharacterFactory.FindSubSprite(armorSprites, "Body");
            else if (sr.gameObject.name == "25_L_Shoulder")
                sr.sprite = CharacterFactory.FindSubSprite(armorSprites, "Left") ?? sr.sprite;
            else if (sr.gameObject.name == "-15_R_Shoulder")
                sr.sprite = CharacterFactory.FindSubSprite(armorSprites, "Right") ?? sr.sprite;
        }
    }

    static string GetFallbackSpriteName(EquipmentSlot slot, int rarity) => slot switch
    {
        EquipmentSlot.Weapon => rarity switch { 1 => "Sword", 2 => "Sword_2", 3 => "Sword_3", _ => "Sword_4" },
        EquipmentSlot.Shield => rarity switch { 1 => "Shield", 2 => "Shield_2", 3 => "Shield_3", _ => "Shield_4" },
        EquipmentSlot.Armor  => rarity switch { 1 => "Armor1", 2 => "Armor2", 3 => "Armor3", _ => "Armor4" },
        EquipmentSlot.Helmet => rarity switch { 1 => "Helm1", 2 => "Helm2", 3 => "Helm3", _ => "Helm4" },
        _ => ""
    };
}
