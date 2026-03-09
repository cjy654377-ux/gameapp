using UnityEngine;
using System.Collections.Generic;

public class StageManager : MonoBehaviour
{
    public static StageManager Instance { get; private set; }

    [Header("Stage Config")]
    public int wavesPerStage = 10;
    public int stagesPerArea = 10;
    public int enemiesPerWave = 10;
    public float waveCooldown = 1.5f;

    [Header("Difficulty")]
    public float hpScalePerWave = 0.08f;
    public float atkScalePerWave = 0.05f;
    public float midBossHpMult = 3f;
    public float midBossAtkMult = 3f;
    public float areaBossHpMult = 5f;
    public float areaBossAtkMult = 5f;

    [Header("Enemy Presets By Area")]
    public List<CharacterPreset> grassEnemies = new();
    public List<CharacterPreset> desertEnemies = new();
    public List<CharacterPreset> caveEnemies = new();

    [Header("Boss Presets")]
    public CharacterPreset grassMidBoss;
    public CharacterPreset grassAreaBoss;
    public CharacterPreset desertMidBoss;
    public CharacterPreset desertAreaBoss;
    public CharacterPreset caveMidBoss;
    public CharacterPreset caveAreaBoss;

    // Current progress
    public int CurrentArea { get; private set; } = 1;   // 1, 2, 3
    public int CurrentStage { get; private set; } = 1;   // 1~10
    public int CurrentWave { get; private set; } = 0;    // 1~10
    public int TotalWaveIndex { get; private set; } = 0; // absolute wave count

    public event System.Action<int, int, int> OnStageChanged; // area, stage, wave
    public event System.Action<int> OnAreaChanged; // new area

    private float waveTimer;
    private bool waitingForNextWave;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(gameObject);

        // Load progress
        int saved = PlayerPrefs.GetInt("TotalWaveIndex", 0);
        TotalWaveIndex = saved;
        CalcStageFromTotal(saved);
    }

    void CalcStageFromTotal(int total)
    {
        int wavesPerArea = wavesPerStage * stagesPerArea; // 100
        CurrentArea = Mathf.Clamp(total / wavesPerArea + 1, 1, 3);
        int remaining = total % wavesPerArea;
        CurrentStage = remaining / wavesPerStage + 1;
        CurrentWave = remaining % wavesPerStage + 1; // 1-based
    }

    public void StartFirstWave()
    {
        SpawnNextWave();
    }

    void Update()
    {
        if (!waitingForNextWave) return;

        var manager = BattleManager.Instance;
        if (manager == null || manager.CurrentState != BattleManager.BattleState.Fighting) return;

        // Check if all enemies dead
        bool allDead = true;
        for (int i = 0; i < manager.enemyUnits.Count; i++)
        {
            if (manager.enemyUnits[i] != null && !manager.enemyUnits[i].IsDead)
            {
                allDead = false;
                break;
            }
        }

        if (allDead)
        {
            waveTimer -= Time.deltaTime;
            if (waveTimer <= 0f)
            {
                waitingForNextWave = false;
                AdvanceWave();
            }
        }
    }

    void AdvanceWave()
    {
        TotalWaveIndex++;
        PlayerPrefs.SetInt("TotalWaveIndex", TotalWaveIndex);

        int prevArea = CurrentArea;
        CalcStageFromTotal(TotalWaveIndex);

        if (CurrentArea != prevArea)
            OnAreaChanged?.Invoke(CurrentArea);

        SpawnNextWave();
    }

    void SpawnNextWave()
    {
        // CalcStageFromTotal already set CurrentArea/Stage/Wave correctly
        // Just fire the event and spawn
        OnStageChanged?.Invoke(CurrentArea, CurrentStage, CurrentWave);

        var manager = BattleManager.Instance;
        var factory = CharacterFactory.Instance;
        if (manager == null || factory == null) return;

        // Clean dead enemies
        for (int i = manager.enemyUnits.Count - 1; i >= 0; i--)
        {
            if (manager.enemyUnits[i] == null || manager.enemyUnits[i].IsDead)
            {
                if (manager.enemyUnits[i] != null)
                    Destroy(manager.enemyUnits[i].gameObject);
                manager.enemyUnits.RemoveAt(i);
            }
        }

        bool isBossWave = CurrentWave == wavesPerStage;
        bool isAreaBoss = isBossWave && CurrentStage == stagesPerArea;

        float spawnX = GetSpawnX();
        float battleZoneH = GetBattleZoneHeight();

        if (isBossWave)
        {
            SpawnBoss(factory, manager, spawnX, isAreaBoss);
            // Add some minions for area boss
            if (isAreaBoss)
            {
                for (int i = 0; i < 5; i++)
                    SpawnNormalEnemy(factory, manager, spawnX + Random.Range(1f, 3f), battleZoneH);
            }
        }
        else
        {
            for (int i = 0; i < enemiesPerWave; i++)
                SpawnNormalEnemy(factory, manager, spawnX + Random.Range(0f, 2f), battleZoneH);
        }

        waveTimer = waveCooldown;
        waitingForNextWave = true;
    }

    void SpawnNormalEnemy(CharacterFactory factory, BattleManager manager, float spawnX, float battleZoneH)
    {
        var presets = GetAreaEnemies();
        if (presets.Count == 0) return;

        var preset = presets[Random.Range(0, presets.Count)];
        float y = Random.Range(-battleZoneH * 0.45f, battleZoneH * 0.45f);
        var unit = factory.CreateCharacter(preset, new Vector3(spawnX, y, 0), BattleUnit.Team.Enemy);

        float statMult = GetStatMultiplier();
        unit.maxHp *= statMult;
        unit.atk *= statMult;
        unit.CurrentHp = unit.maxHp;
        unit.damageElement = GetAreaElement();

        manager.enemyUnits.Add(unit);
    }

    void SpawnBoss(CharacterFactory factory, BattleManager manager, float spawnX, bool isAreaBoss)
    {
        var preset = isAreaBoss ? GetAreaBossPreset() : GetMidBossPreset();
        if (preset == null)
        {
            // Fallback: spawn normal enemies
            float battleZoneH = GetBattleZoneHeight();
            for (int i = 0; i < enemiesPerWave; i++)
                SpawnNormalEnemy(factory, manager, spawnX + Random.Range(0f, 2f), battleZoneH);
            return;
        }

        var unit = factory.CreateCharacter(preset, new Vector3(spawnX, 0, 0), BattleUnit.Team.Enemy);

        float statMult = GetStatMultiplier();
        float bossMult = isAreaBoss ? areaBossHpMult : midBossHpMult;
        float bossAtkMult = isAreaBoss ? areaBossAtkMult : midBossAtkMult;

        unit.maxHp *= statMult * bossMult;
        unit.atk *= statMult * bossAtkMult;
        unit.CurrentHp = unit.maxHp;
        unit.damageElement = GetAreaElement();

        // Boss size
        float sizeScale = isAreaBoss ? 2f : 1.5f;
        unit.transform.localScale = Vector3.one * sizeScale;

        manager.enemyUnits.Add(unit);
    }

    float GetStatMultiplier()
    {
        return 1f + TotalWaveIndex * hpScalePerWave;
    }

    float GetSpawnX()
    {
        var cam = Camera.main;
        if (cam == null) return 8f;
        return cam.transform.position.x + cam.orthographicSize * cam.aspect + 4f;
    }

    float GetBattleZoneHeight()
    {
        float camH = Camera.main != null ? Camera.main.orthographicSize * 2f : 10f;
        return camH * 0.6f;
    }

    List<CharacterPreset> GetAreaEnemies()
    {
        return CurrentArea switch
        {
            1 => grassEnemies,
            2 => desertEnemies,
            3 => caveEnemies,
            _ => grassEnemies
        };
    }

    DamageElement GetAreaElement()
    {
        return CurrentArea switch
        {
            1 => DamageElement.Physical,
            2 => DamageElement.Lightning,
            3 => DamageElement.Poison,
            _ => DamageElement.Physical
        };
    }

    CharacterPreset GetMidBossPreset()
    {
        return CurrentArea switch
        {
            1 => grassMidBoss,
            2 => desertMidBoss,
            3 => caveMidBoss,
            _ => grassMidBoss
        };
    }

    CharacterPreset GetAreaBossPreset()
    {
        return CurrentArea switch
        {
            1 => grassAreaBoss,
            2 => desertAreaBoss,
            3 => caveAreaBoss,
            _ => grassAreaBoss
        };
    }

    public string GetStageText()
    {
        int displayStage = (CurrentArea - 1) * stagesPerArea + CurrentStage;
        return $"{displayStage}-{CurrentWave}";
    }

    public string GetAreaName()
    {
        return CurrentArea switch
        {
            1 => "Grass Field",
            2 => "Desert",
            3 => "Underground Cave",
            _ => "Unknown"
        };
    }
}
