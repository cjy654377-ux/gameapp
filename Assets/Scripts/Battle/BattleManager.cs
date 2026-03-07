using UnityEngine;
using System.Collections.Generic;

public class BattleManager : MonoBehaviour
{
    public static BattleManager Instance { get; private set; }

    [Header("Teams")]
    public List<BattleUnit> allyUnits = new();
    public List<BattleUnit> enemyUnits = new();

    public enum BattleState { Preparing, Fighting, Victory, Defeat }
    public BattleState CurrentState { get; private set; } = BattleState.Preparing;

    public event System.Action<BattleState> OnBattleStateChanged;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(gameObject);
    }

    public void StartBattle()
    {
        CurrentState = BattleState.Fighting;
        OnBattleStateChanged?.Invoke(CurrentState);
    }

    void Update()
    {
        if (CurrentState != BattleState.Fighting) return;

        bool allEnemiesDead = true;
        bool allAlliesDead = true;

        for (int i = 0; i < enemyUnits.Count; i++)
            if (!enemyUnits[i].IsDead) { allEnemiesDead = false; break; }

        if (!allEnemiesDead)
        {
            for (int i = 0; i < allyUnits.Count; i++)
                if (!allyUnits[i].IsDead) { allAlliesDead = false; break; }
        }

        if (allEnemiesDead)
            SetState(BattleState.Victory);
        else if (allAlliesDead)
            SetState(BattleState.Defeat);
    }

    void SetState(BattleState state)
    {
        CurrentState = state;
        OnBattleStateChanged?.Invoke(state);
    }

    public BattleUnit FindNearestEnemy(BattleUnit unit)
    {
        var enemies = unit.CurrentTeam == BattleUnit.Team.Ally ? enemyUnits : allyUnits;
        BattleUnit nearest = null;
        float minDist = float.MaxValue;

        for (int i = 0; i < enemies.Count; i++)
        {
            var enemy = enemies[i];
            if (enemy.IsDead) continue;
            float dist = Vector2.Distance(unit.transform.position, enemy.transform.position);
            if (dist < minDist)
            {
                minDist = dist;
                nearest = enemy;
            }
        }

        return nearest;
    }
}
