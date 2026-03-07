using UnityEngine;
using System.Collections.Generic;

public class BattleSetup : MonoBehaviour
{
    [Header("Character Presets")]
    public List<CharacterPreset> allyPresets = new();
    public List<CharacterPreset> enemyPresets = new();

    [Header("Spawn Positions")]
    public float allyStartX = -1f;
    public float enemyStartX = 6f;
    public float unitSpacingY = 1.5f;

    void Start()
    {
        SpawnTeams();
    }

    void SpawnTeams()
    {
        var factory = CharacterFactory.Instance;
        if (factory == null)
        {
            Debug.LogError("CharacterFactory not found!");
            return;
        }

        var manager = BattleManager.Instance;

        // Spawn allies (inside map, left-center)
        for (int i = 0; i < allyPresets.Count; i++)
        {
            float yOffset = (i - (allyPresets.Count - 1) * 0.5f) * unitSpacingY;
            Vector3 pos = new Vector3(allyStartX, yOffset, 0);
            var unit = factory.CreateCharacter(allyPresets[i], pos, BattleUnit.Team.Ally);
            manager.allyUnits.Add(unit);
        }

        // Spawn enemies (outside map, far right - they walk in)
        for (int i = 0; i < enemyPresets.Count; i++)
        {
            float yOffset = (i - (enemyPresets.Count - 1) * 0.5f) * unitSpacingY;
            Vector3 pos = new Vector3(enemyStartX, yOffset, 0);
            var unit = factory.CreateCharacter(enemyPresets[i], pos, BattleUnit.Team.Enemy);
            manager.enemyUnits.Add(unit);
        }

        manager.StartBattle();
    }
}
