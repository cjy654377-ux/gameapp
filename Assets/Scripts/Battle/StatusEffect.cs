using UnityEngine;
using System.Collections.Generic;

public enum StatusEffectType
{
    Burn,    // 화상: 지속 데미지
    Freeze,  // 동상: 이동속도 감소 + 지속 데미지
    Poison,  // 중독: 지속 데미지 (방어력 무시)
    Slow     // 둔화: 이동속도 + 공격속도 감소
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
                effect.tickInterval = 0.5f;
                effect.tickDamage = 5f;
                effect.speedMultiplier = 1f;
                effect.attackSpeedMultiplier = 1f;
                break;
            case StatusEffectType.Freeze:
                effect.tickInterval = 1f;
                effect.tickDamage = 3f;
                effect.speedMultiplier = 0.3f;
                effect.attackSpeedMultiplier = 0.7f;
                break;
            case StatusEffectType.Poison:
                effect.tickInterval = 0.8f;
                effect.tickDamage = 8f;
                effect.speedMultiplier = 1f;
                effect.attackSpeedMultiplier = 1f;
                break;
            case StatusEffectType.Slow:
                effect.tickInterval = 0f;
                effect.tickDamage = 0f;
                effect.speedMultiplier = 0.4f;
                effect.attackSpeedMultiplier = 0.5f;
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
        float dt = Time.deltaTime;

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
