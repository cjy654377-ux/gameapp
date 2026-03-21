using UnityEngine;
using System.Collections.Generic;

public enum DungeonType { Hero, Mount, Skill }

[CreateAssetMenu(menuName = "Game/DungeonData", fileName = "DungeonData")]
public class DungeonData : ScriptableObject
{
    public DungeonType dungeonType;
    [Range(1, 100)] public int stage = 1;
    public int baseReward = 10;
    public List<CharacterPreset> enemyPresets = new();

    public float DifficultyMultiplier => 1f + (stage - 1) * 0.1f;

    public int CalcReward() => Mathf.RoundToInt(baseReward * DifficultyMultiplier);

    public string RewardCurrencyName => dungeonType switch
    {
        DungeonType.Hero  => "보석",
        DungeonType.Mount => "소환석",
        DungeonType.Skill => "주문서",
        _                 => "보석"
    };
}
