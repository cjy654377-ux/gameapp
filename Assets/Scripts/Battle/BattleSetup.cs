using UnityEngine;
using System.Collections.Generic;

public class BattleSetup : MonoBehaviour
{
    [Header("Character Presets")]
    public List<CharacterPreset> allyPresets = new();
    public List<CharacterPreset> enemyPresets = new();

    [Header("Spawn Settings")]
    public float allyStartX = -1f;
    public float enemySpawnOffset = 6f; // distance ahead of camera right edge
    public float unitSpacingY = 1.0f;

    [Header("Wave Settings")]
    public float waveCooldown = 2f;
    public int baseEnemyCount = 3;
    public float difficultyScale = 0.15f;

    private int currentWave = 0;
    private float waveTimer = 0f;
    private bool alliesSpawned = false;

    void Start()
    {
        SpawnAllies();
        SpawnWave();
    }

    void Update()
    {
        if (!alliesSpawned) return;

        var manager = BattleManager.Instance;
        if (manager == null || manager.CurrentState != BattleManager.BattleState.Fighting) return;

        // Check if all enemies are dead
        bool allEnemiesDead = true;
        for (int i = 0; i < manager.enemyUnits.Count; i++)
        {
            if (!manager.enemyUnits[i].IsDead)
            {
                allEnemiesDead = false;
                break;
            }
        }

        if (allEnemiesDead)
        {
            waveTimer -= Time.deltaTime;
            if (waveTimer <= 0f)
                SpawnWave();
        }
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
            manager.allyUnits.Add(unit);
        }

        alliesSpawned = true;
        manager.StartBattle();
    }

    void SpawnWave()
    {
        currentWave++;
        waveTimer = waveCooldown;

        var factory = CharacterFactory.Instance;
        var manager = BattleManager.Instance;
        if (factory == null || manager == null) return;

        // Clean up dead enemies
        manager.enemyUnits.RemoveAll(e => e == null || e.IsDead);

        // Spawn position: ahead of camera
        float spawnX = Camera.main != null
            ? Camera.main.transform.position.x + Camera.main.orthographicSize * Camera.main.aspect + enemySpawnOffset
            : 8f;

        int enemyCount = baseEnemyCount + Mathf.FloorToInt(currentWave * 0.5f);
        float statMultiplier = 1f + currentWave * difficultyScale;

        float battleZoneH = GetBattleZoneHeight();

        for (int i = 0; i < enemyCount; i++)
        {
            // Pick random enemy preset
            var preset = enemyPresets[Random.Range(0, enemyPresets.Count)];

            float yOffset = Random.Range(-battleZoneH * 0.45f, battleZoneH * 0.45f);
            float xOffset = Random.Range(0f, 2f); // stagger spawn
            Vector3 pos = new Vector3(spawnX + xOffset, yOffset, 0);

            var unit = factory.CreateCharacter(preset, pos, BattleUnit.Team.Enemy);
            // Scale stats by wave
            unit.maxHp *= statMultiplier;
            unit.atk *= statMultiplier;
            unit.CurrentHp = unit.maxHp;

            manager.enemyUnits.Add(unit);
        }
    }

    float GetBattleZoneHeight()
    {
        // Middle 3/5 of screen height
        float camH = Camera.main != null ? Camera.main.orthographicSize * 2f : 8f;
        return camH * 0.6f; // 3/5
    }
}
