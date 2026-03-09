using UnityEngine;
using System.Collections.Generic;

public class BattleSetup : MonoBehaviour
{
    [Header("Ally Presets")]
    public List<CharacterPreset> allyPresets = new();

    [Header("Spawn Settings")]
    public float allyStartX = -1f;
    public float unitSpacingY = 1.0f;

    void Start()
    {
        SpawnAllies();

        if (StageManager.Instance != null)
            StageManager.Instance.StartFirstWave();
    }

    void SpawnAllies()
    {
        var factory = CharacterFactory.Instance;
        if (factory == null) return;

        var manager = BattleManager.Instance;
        float battleZoneH = GetBattleZoneHeight();

        for (int i = 0; i < allyPresets.Count; i++)
        {
            float yOffset = (i - (allyPresets.Count - 1) * 0.5f) * unitSpacingY;
            yOffset = Mathf.Clamp(yOffset, -battleZoneH * 0.5f, battleZoneH * 0.5f);
            Vector3 pos = new Vector3(allyStartX, yOffset, 0);
            var unit = factory.CreateCharacter(allyPresets[i], pos, BattleUnit.Team.Ally);
            if (UpgradeManager.Instance != null)
                UpgradeManager.Instance.ApplyToUnit(unit);
            manager.allyUnits.Add(unit);
        }

        manager.StartBattle();
    }

    float GetBattleZoneHeight()
    {
        float camH = Camera.main != null ? Camera.main.orthographicSize * 2f : 10f;
        return camH * 0.6f;
    }
}
