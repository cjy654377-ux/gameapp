using UnityEngine;
using System.Collections.Generic;

public enum StatusEffectType
{
    Burn,    // 화상: 지속 데미지
    Freeze,  // 동상: 이동속도 감소 + 지속 데미지
    Poison,  // 중독: 지속 데미지 (방어력 무시)
    Slow     // 둔화: 이동속도 + 공격속도 감소
}

// 상태이상 수치 상수
public static class StatusEffectConstants
{
    // Burn: 화상
    public const float BURN_TICK_INTERVAL = 0.5f;
    public const float BURN_TICK_DAMAGE = 5f;
    public const float BURN_SPEED_MULT = 1f;
    public const float BURN_ATTACK_SPEED_MULT = 1f;

    // Freeze: 동상
    public const float FREEZE_TICK_INTERVAL = 1f;
    public const float FREEZE_TICK_DAMAGE = 3f;
    public const float FREEZE_SPEED_MULT = 0.3f;
    public const float FREEZE_ATTACK_SPEED_MULT = 0.7f;

    // Poison: 중독
    public const float POISON_TICK_INTERVAL = 0.8f;
    public const float POISON_TICK_DAMAGE = 8f;
    public const float POISON_SPEED_MULT = 1f;
    public const float POISON_ATTACK_SPEED_MULT = 1f;

    // Slow: 둔화
    public const float SLOW_TICK_INTERVAL = 0f;
    public const float SLOW_TICK_DAMAGE = 0f;
    public const float SLOW_SPEED_MULT = 0.4f;
    public const float SLOW_ATTACK_SPEED_MULT = 0.5f;
}

[System.Serializable]
public class StatusEffect
{
    public StatusEffectType type;
    public float duration;
    public float tickInterval;
    public float tickDamage;
    public float speedMultiplier; // 1.0 = no change, 0.5 = 50% slower
    public float attackSpeedMultiplier;

    float remainingDuration;
    float tickTimer;

    public bool IsExpired => remainingDuration <= 0f;

    public static StatusEffect Create(StatusEffectType type, float duration)
    {
        var effect = new StatusEffect { type = type, duration = duration, remainingDuration = duration };

        switch (type)
        {
            case StatusEffectType.Burn:
                effect.tickInterval = StatusEffectConstants.BURN_TICK_INTERVAL;
                effect.tickDamage = StatusEffectConstants.BURN_TICK_DAMAGE;
                effect.speedMultiplier = StatusEffectConstants.BURN_SPEED_MULT;
                effect.attackSpeedMultiplier = StatusEffectConstants.BURN_ATTACK_SPEED_MULT;
                break;
            case StatusEffectType.Freeze:
                effect.tickInterval = StatusEffectConstants.FREEZE_TICK_INTERVAL;
                effect.tickDamage = StatusEffectConstants.FREEZE_TICK_DAMAGE;
                effect.speedMultiplier = StatusEffectConstants.FREEZE_SPEED_MULT;
                effect.attackSpeedMultiplier = StatusEffectConstants.FREEZE_ATTACK_SPEED_MULT;
                break;
            case StatusEffectType.Poison:
                effect.tickInterval = StatusEffectConstants.POISON_TICK_INTERVAL;
                effect.tickDamage = StatusEffectConstants.POISON_TICK_DAMAGE;
                effect.speedMultiplier = StatusEffectConstants.POISON_SPEED_MULT;
                effect.attackSpeedMultiplier = StatusEffectConstants.POISON_ATTACK_SPEED_MULT;
                break;
            case StatusEffectType.Slow:
                effect.tickInterval = StatusEffectConstants.SLOW_TICK_INTERVAL;
                effect.tickDamage = StatusEffectConstants.SLOW_TICK_DAMAGE;
                effect.speedMultiplier = StatusEffectConstants.SLOW_SPEED_MULT;
                effect.attackSpeedMultiplier = StatusEffectConstants.SLOW_ATTACK_SPEED_MULT;
                break;
        }

        return effect;
    }

    // Returns tick damage if any this frame, 0 otherwise
    public float Update(float deltaTime)
    {
        remainingDuration -= deltaTime;
        if (tickInterval <= 0f || tickDamage <= 0f) return 0f;

        tickTimer += deltaTime;
        if (tickTimer >= tickInterval)
        {
            int ticks = Mathf.FloorToInt(tickTimer / tickInterval);
            tickTimer -= ticks * tickInterval;
            return tickDamage * ticks;
        }
        return 0f;
    }

    public float GetRemainingRatio() => Mathf.Clamp01(remainingDuration / duration);
}

public class StatusEffectController : MonoBehaviour
{
    readonly List<StatusEffect> activeEffects = new();
    BattleUnit unit;

    public IReadOnlyList<StatusEffect> ActiveEffects => activeEffects;
    public event System.Action OnEffectsChanged;

    void Awake()
    {
        unit = GetComponent<BattleUnit>();
    }

    public void ApplyEffect(StatusEffectType type, float duration)
    {
        // Replace existing effect of same type (refresh)
        for (int i = activeEffects.Count - 1; i >= 0; i--)
        {
            if (activeEffects[i].type == type)
            {
                activeEffects.RemoveAt(i);
                break;
            }
        }

        activeEffects.Add(StatusEffect.Create(type, duration));
        OnEffectsChanged?.Invoke();
    }

    public bool HasEffect(StatusEffectType type)
    {
        for (int i = 0; i < activeEffects.Count; i++)
            if (activeEffects[i].type == type) return true;
        return false;
    }

    public float GetSpeedMultiplier()
    {
        // 가장 강한 감속 효과만 적용 (곱셈 누적 방지: Freeze+Slow = 0.12배 → 0.3배)
        float minMult = 1f;
        for (int i = 0; i < activeEffects.Count; i++)
        {
            if (activeEffects[i].speedMultiplier < minMult)
                minMult = activeEffects[i].speedMultiplier;
        }
        return minMult;
    }

    public float GetAttackSpeedMultiplier()
    {
        float minMult = 1f;
        for (int i = 0; i < activeEffects.Count; i++)
        {
            if (activeEffects[i].attackSpeedMultiplier < minMult)
                minMult = activeEffects[i].attackSpeedMultiplier;
        }
        return minMult;
    }

    void Update()
    {
        if (unit == null || unit.IsDead || activeEffects.Count == 0) return;

        bool changed = false;
        // Use unscaledDeltaTime to match BattleUnit timers (stun/buff) and support timeScale changes
        float dt = Time.unscaledDeltaTime;

        for (int i = activeEffects.Count - 1; i >= 0; i--)
        {
            float tickDmg = activeEffects[i].Update(dt);
            if (tickDmg > 0f)
            {
                // Poison ignores defense
                if (activeEffects[i].type == StatusEffectType.Poison)
                    unit.TakeDamage(tickDmg, true);
                else
                    unit.TakeDamage(tickDmg);
            }

            if (activeEffects[i].IsExpired)
            {
                activeEffects.RemoveAt(i);
                changed = true;
            }
        }

        if (changed)
            OnEffectsChanged?.Invoke();
    }
}
