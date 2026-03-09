using UnityEngine;
using System.Collections.Generic;

public class BattleSetup : MonoBehaviour
{
    [Header("Fallback Ally Presets (DeckManager 없을 때)")]
    public List<CharacterPreset> allyPresets = new();

    [Header("Spawn Settings")]
    public float allyStartX = -1f;
    public float unitSpacingY = 1.0f;

    void Start()
    {
        if (ScreenFader.Instance == null)
        {
            var faderObj = new GameObject("ScreenFader");
            faderObj.AddComponent<ScreenFader>();
        }

        // DeckManager가 없으면 생성 + fallback 프리셋을 로스터로
        if (DeckManager.Instance == null)
        {
            var deckObj = new GameObject("DeckManager");
            var dm = deckObj.AddComponent<DeckManager>();
            dm.roster.AddRange(allyPresets);
            dm.Initialize();
        }

        SpawnAllies();

        if (StageManager.Instance != null)
            StageManager.Instance.StartFirstWave();
    }

    void SpawnAllies()
    {
        var factory = CharacterFactory.Instance;
        if (factory == null) return;

        var manager = BattleManager.Instance;
        if (manager == null) return;

        // DeckManager가 있으면 덱 기반, 없으면 fallback
        List<CharacterPreset> presets;
        if (DeckManager.Instance != null)
            presets = DeckManager.Instance.GetActiveDeck();
        else
            presets = allyPresets;

        if (presets.Count == 0) return;

        float battleZoneH = GetBattleZoneHeight();

        for (int i = 0; i < presets.Count; i++)
        {
            float yOffset = (i - (presets.Count - 1) * 0.5f) * unitSpacingY;
            yOffset = Mathf.Clamp(yOffset, -battleZoneH * 0.5f, battleZoneH * 0.5f);
            Vector3 pos = new Vector3(allyStartX, yOffset, 0);
            var unit = factory.CreateCharacter(presets[i], pos, BattleUnit.Team.Ally);
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
