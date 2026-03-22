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
    public event System.Action OnReviveRequested; // 광고 부활 팝업 트리거용
    public event System.Action OnEnemyKilled;

    // === Dungeon Mode ===
    public bool IsDungeonMode { get; private set; }
    int dungeonType;
    int dungeonStage;

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

        // 아군 전멸 체크
        bool allAlliesDead = true;
        for (int i = 0; i < allyUnits.Count; i++)
        {
            if (allyUnits[i] != null && !allyUnits[i].IsDead) { allAlliesDead = false; break; }
        }

        if (allAlliesDead)
        {
            SetState(BattleState.Defeat);
            return;
        }

        // 던전 모드: 적 전멸 체크 → Victory
        if (IsDungeonMode)
        {
            bool allEnemiesDead = true;
            for (int i = 0; i < enemyUnits.Count; i++)
            {
                if (enemyUnits[i] != null && !enemyUnits[i].IsDead) { allEnemiesDead = false; break; }
            }

            if (allEnemiesDead)
                SetState(BattleState.Victory);
        }
    }

    void SetState(BattleState state)
    {
        CurrentState = state;
        OnBattleStateChanged?.Invoke(state);
    }

    public void EnterDungeonMode(int type, int stage)
    {
        IsDungeonMode = true;
        dungeonType = type;
        dungeonStage = stage;
    }

    public void ExitDungeonMode()
    {
        IsDungeonMode = false;
        dungeonType = 0;
        dungeonStage = 0;
    }

    /// <summary>
    /// 광고 보상으로 모든 아군 부활: HP 100% 복구 후 전투 재개
    /// </summary>
    public void ReviveAllies()
    {
        for (int i = 0; i < allyUnits.Count; i++)
        {
            var unit = allyUnits[i];
            if (unit == null) continue;
            // Heal() is a no-op on dead units. Use Revive() to restore HP and re-enable the GameObject.
            if (unit.IsDead || !unit.gameObject.activeSelf)
                unit.Revive();
            else
                unit.Heal(unit.maxHp);
        }
        // Ensure state is Fighting so Update() loop resumes
        if (CurrentState == BattleState.Defeat)
            SetState(BattleState.Fighting);
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }

    public BattleUnit FindNearestEnemy(BattleUnit unit)
    {
        var enemies = unit.CurrentTeam == BattleUnit.Team.Ally ? enemyUnits : allyUnits;

        // 적 유닛이 아군을 타겟: 가장 가까운 전방 아군 우선 (탱커 어그로)
        if (unit.CurrentTeam == BattleUnit.Team.Enemy)
            return FindFrontmostAlive(enemies);

        // 아군: 기본 가장 가까운 적
        BattleUnit nearest = null;
        float minDist = float.MaxValue;

        for (int i = 0; i < enemies.Count; i++)
        {
            var enemy = enemies[i];
            if (enemy == null || enemy.IsDead) continue;
            float dist = Vector2.Distance(unit.transform.position, enemy.transform.position);
            if (dist < minDist)
            {
                minDist = dist;
                nearest = enemy;
            }
        }

        return nearest;
    }

    /// <summary>
    /// 가장 전방(X가 작은/큰)에 있는 생존 유닛 반환 - 탱커 어그로용
    /// </summary>
    BattleUnit FindFrontmostAlive(List<BattleUnit> units)
    {
        BattleUnit frontmost = null;
        float bestX = float.MinValue;

        for (int i = 0; i < units.Count; i++)
        {
            var u = units[i];
            if (u == null || u.IsDead) continue;
            // 아군은 오른쪽으로 전진하므로, 가장 오른쪽(X 큰) = 전방
            // 적은 왼쪽에서 오므로, 아군 중 가장 왼쪽(X 작은) = 가장 가까운 적
            // 여기서는 "적이 아군을 찾는" 경우이므로, 아군 중 가장 앞(X 큰) 유닛
            if (u.transform.position.x > bestX)
            {
                bestX = u.transform.position.x;
                frontmost = u;
            }
        }

        return frontmost;
    }

    /// <summary>
    /// 힐러용: 가장 HP 비율이 낮은 아군 반환
    /// </summary>
    public BattleUnit FindWeakestAlly(BattleUnit healer)
    {
        var allies = healer.CurrentTeam == BattleUnit.Team.Ally ? allyUnits : enemyUnits;
        BattleUnit weakest = null;
        float lowestRatio = 1f;

        for (int i = 0; i < allies.Count; i++)
        {
            var ally = allies[i];
            if (ally == null || ally.IsDead) continue;
            float ratio = ally.CurrentHp / ally.maxHp;
            if (ratio < lowestRatio)
            {
                lowestRatio = ratio;
                weakest = ally;
            }
        }

        return weakest;
    }
}
