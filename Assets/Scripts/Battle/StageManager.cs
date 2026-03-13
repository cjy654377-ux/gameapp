using UnityEngine;
using System.Collections.Generic;

public class StageManager : MonoBehaviour
{
    public static StageManager Instance { get; private set; }

    [Header("Stage Config")]
    public int wavesPerStage = 3;
    public int stagesPerArea = 10;
    public int enemiesPerWave = 10;
    public float waveCooldown = 1.5f;

    [Header("Fade Transition")]
    public float fadeOutTime = 0.4f;
    public float fadeHoldTime = 0.3f;
    public float fadeInTime = 0.4f;

    [Header("Difficulty")]
    public float hpScalePerWave = 0.06f;
    public float atkScalePerWave = 0.04f;
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
    public int CurrentArea { get; private set; } = 1;
    public int CurrentStage { get; private set; } = 1;
    public int CurrentWave { get; private set; } = 0;
    public int TotalWaveIndex { get; private set; } = 0;

    public event System.Action<int, int, int> OnStageChanged;
    public event System.Action<int> OnAreaChanged;
    public event System.Action<int> OnStageCleared;

    float waveTimer;
    bool waitingForNextWave;
    bool isTransitioning;
    BattleSetup cachedSetup;
    Camera cachedMainCamera;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(gameObject);

        int saved = PlayerPrefs.GetInt("TotalWaveIndex", 0);
        TotalWaveIndex = saved;
        CalcStageFromTotal(saved);
    }

    void CalcStageFromTotal(int total)
    {
        total = Mathf.Max(0, total);
        int wavesPerArea = wavesPerStage * stagesPerArea;
        CurrentArea = Mathf.Clamp(total / wavesPerArea + 1, 1, 3);
        int remaining = total % wavesPerArea;
        CurrentStage = remaining / wavesPerStage + 1;
        CurrentWave = remaining % wavesPerStage + 1;
    }

    public void StartFirstWave()
    {
        PlayAreaBGM();
        SpawnNextWave();
    }

    void PlayAreaBGM()
    {
        string bgm = CurrentArea switch
        {
            1 => "battle_grass",
            2 => "battle_desert",
            3 => "battle_cave",
            _ => "battle_grass"
        };
        SoundManager.Instance?.PlayBGM(bgm);
    }

    void Update()
    {
        if (!waitingForNextWave || isTransitioning) return;

        var manager = BattleManager.Instance;
        if (manager == null || manager.CurrentState != BattleManager.BattleState.Fighting) return;

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
        int prevStage = CurrentStage;
        int prevArea = CurrentArea;

        TotalWaveIndex++;
        PlayerPrefs.SetInt("TotalWaveIndex", TotalWaveIndex);
        CalcStageFromTotal(TotalWaveIndex);

        if (CurrentArea != prevArea)
            OnAreaChanged?.Invoke(CurrentArea);

        // 스테이지가 바뀌면 페이드 전환 (1-1의 3웨이브 끝 → 1-2로)
        bool stageChanged = (CurrentStage != prevStage) || (CurrentArea != prevArea);
        if (stageChanged)
        {
            OnStageCleared?.Invoke(TotalWaveIndex - 1);
            DoStageTransition();
        }
        else
        {
            SoundManager.Instance?.PlayWaveClearSFX();
            SpawnNextWave();
        }
    }

    void DoStageTransition()
    {
        isTransitioning = true;
        var fader = ScreenFader.Instance;
        if (fader == null)
        {
            // ScreenFader 없으면 즉시 진행
            ResetBattlefield();
            SpawnNextWave();
            isTransitioning = false; // SpawnWaveImmediate 후 해제
            return;
        }

        fader.FadeTransition(fadeOutTime, fadeHoldTime, fadeInTime, () =>
        {
            // 페이드 아웃 완료 시점: 전장 리셋
            ResetBattlefield();
            PlayAreaBGM();
            OnStageChanged?.Invoke(CurrentArea, CurrentStage, CurrentWave);
            isTransitioning = false;
            SpawnWaveImmediate();
        });
    }

    void ResetBattlefield()
    {
        var manager = BattleManager.Instance;
        if (manager == null) return;

        // 적 전부 제거
        for (int i = manager.enemyUnits.Count - 1; i >= 0; i--)
        {
            if (manager.enemyUnits[i] != null)
                Destroy(manager.enemyUnits[i].gameObject);
        }
        manager.enemyUnits.Clear();

        // 아군 위치 리셋 + 체력 회복
        if (cachedSetup == null) cachedSetup = FindFirstObjectByType<BattleSetup>();
        float startX = cachedSetup != null ? cachedSetup.allyStartX : -1f;
        float spacing = cachedSetup != null ? cachedSetup.unitSpacingY : 1f;

        for (int i = 0; i < manager.allyUnits.Count; i++)
        {
            var unit = manager.allyUnits[i];
            if (unit == null) continue;

            unit.gameObject.SetActive(true);
            unit.Revive();
            float yOffset = (i - (manager.allyUnits.Count - 1) * 0.5f) * spacing;
            unit.transform.position = new Vector3(startX, yOffset, 0);

            UpgradeManager.ApplyAllBonuses(unit);
        }

        // 카메라 리셋
        var cam = GetMainCamera();
        if (cam != null)
        {
            var camPos = cam.transform.position;
            camPos.x = 0;
            cam.transform.position = camPos;
        }
    }

    void SpawnNextWave()
    {
        OnStageChanged?.Invoke(CurrentArea, CurrentStage, CurrentWave);
        SpawnWaveImmediate();
    }

    void SpawnWaveImmediate()
    {
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

        float hpMult = GetDifficultyMultiplier(TotalWaveIndex, hpScalePerWave);
        float atkMult = GetDifficultyMultiplier(TotalWaveIndex, atkScalePerWave);
        unit.maxHp *= hpMult;
        unit.atk *= atkMult;
        unit.CurrentHp = unit.maxHp;
        unit.damageElement = GetAreaElement();

        // 에리어별 적 특성
        switch (CurrentArea)
        {
            case 2: // Desert: 빠르고 공격적
                unit.moveSpeed *= 1.3f;
                unit.attackCooldown *= 0.85f;
                unit.lightningResist = 0.3f;
                break;
            case 3: // Cave: 단단하고 독 저항
                unit.def *= 1.4f;
                unit.poisonResist = 0.5f;
                unit.maxHp *= 1.2f;
                unit.CurrentHp = unit.maxHp;
                break;
        }

        manager.enemyUnits.Add(unit);
    }

    public event System.Action<bool> OnBossSpawned; // true = area boss, false = mid boss

    void SpawnBoss(CharacterFactory factory, BattleManager manager, float spawnX, bool isAreaBoss)
    {
        var preset = isAreaBoss ? GetAreaBossPreset() : GetMidBossPreset();
        if (preset == null)
        {
            float battleZoneH = GetBattleZoneHeight();
            for (int i = 0; i < enemiesPerWave; i++)
                SpawnNormalEnemy(factory, manager, spawnX + Random.Range(0f, 2f), battleZoneH);
            return;
        }

        var unit = factory.CreateCharacter(preset, new Vector3(spawnX, 0, 0), BattleUnit.Team.Enemy);

        float hpMult = GetDifficultyMultiplier(TotalWaveIndex, hpScalePerWave);
        float atkMult = GetDifficultyMultiplier(TotalWaveIndex, atkScalePerWave);
        float bossMult = isAreaBoss ? areaBossHpMult : midBossHpMult;
        float bossAtkMult = isAreaBoss ? areaBossAtkMult : midBossAtkMult;

        unit.maxHp *= hpMult * bossMult;
        unit.atk *= atkMult * bossAtkMult;
        unit.CurrentHp = unit.maxHp;
        unit.damageElement = GetAreaElement();

        float sizeScale = isAreaBoss ? 2f : 1.5f;
        unit.transform.localScale = Vector3.one * sizeScale * 0.8f;

        // Boss rage: 30% HP 이하일 때 공격속도 1.5배
        var bossUnit = unit;
        float rageThreshold = unit.maxHp * 0.3f;
        bool raged = false;
        System.Action<float, float> rageHandler = null;
        System.Action deathCleanup = null;
        rageHandler = (hp, max) =>
        {
            if (!raged && hp <= rageThreshold && hp > 0)
            {
                raged = true;
                bossUnit.attackCooldown *= 0.65f;
                bossUnit.moveSpeed *= 1.3f;
                if (EffectManager.Instance != null)
                    EffectManager.Instance.SpawnLightningEffect(bossUnit.transform.position);
                bossUnit.OnHpChanged -= rageHandler;
                bossUnit.OnDeath -= deathCleanup;
            }
        };
        deathCleanup = () =>
        {
            bossUnit.OnHpChanged -= rageHandler;
        };
        unit.OnHpChanged += rageHandler;
        unit.OnDeath += deathCleanup;

        manager.enemyUnits.Add(unit);
        SoundManager.Instance?.PlayBossAppearSFX();
        OnBossSpawned?.Invoke(isAreaBoss);

        // 카메라 셰이크
        var cam = GetMainCamera();
        var camShake = cam != null ? cam.GetComponent<QuarterViewCamera>() : null;
        if (camShake != null)
            camShake.Shake(isAreaBoss ? 0.5f : 0.3f, isAreaBoss ? 0.2f : 0.12f);
    }

    Camera GetMainCamera()
    {
        if (cachedMainCamera == null)
            cachedMainCamera = Camera.main;
        return cachedMainCamera;
    }

    float GetSpawnX()
    {
        var cam = GetMainCamera();
        if (cam == null) return 8f;
        return cam.transform.position.x + cam.orthographicSize * cam.aspect + 4f;
    }

    float GetBattleZoneHeight()
    {
        var cam = GetMainCamera();
        float camH = cam != null ? cam.orthographicSize * 2f : 10f;
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

    /// <summary>
    /// 패배 시 이전 웨이브로 되돌리고 페이드 전환 후 자동 재시작
    /// </summary>
    public void RewindAndRestart()
    {
        if (isTransitioning) return;
        SoundManager.Instance?.PlayDefeatSFX();
        AchievementManager.Instance?.ResetBossTracking();

        if (TotalWaveIndex > 0)
            TotalWaveIndex--;
        PlayerPrefs.SetInt("TotalWaveIndex", TotalWaveIndex);
        CalcStageFromTotal(TotalWaveIndex);

        isTransitioning = true;
        var fader = ScreenFader.Instance;
        if (fader == null)
        {
            ResetBattlefield();
            BattleManager.Instance?.StartBattle();
            SpawnWaveImmediate();
            OnStageChanged?.Invoke(CurrentArea, CurrentStage, CurrentWave);
            isTransitioning = false;
            return;
        }

        fader.FadeTransition(fadeOutTime, fadeHoldTime, fadeInTime, () =>
        {
            ResetBattlefield();
            BattleManager.Instance?.StartBattle();
            OnStageChanged?.Invoke(CurrentArea, CurrentStage, CurrentWave);
            isTransitioning = false;
            SpawnWaveImmediate();
        });
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

    /// <summary>
    /// 구간별 난이도 곡선: 초반 완만 → 중반 선형 → 후반 가파름 + 에리어 전환 점프
    /// wave 0~29: 완만 (sqrt 기반), 30~59: 선형, 60+: 가속 (pow 1.3)
    /// 에리어 전환 시 1.5배 점프
    /// </summary>
    float GetDifficultyMultiplier(int wave, float baseScale)
    {
        int wavesPerArea = wavesPerStage * stagesPerArea; // 30
        int area = wave / wavesPerArea; // 0, 1, 2
        int localWave = wave % wavesPerArea;

        // 구간별 곡선
        float curveMult;
        if (localWave <= 10)
        {
            // 초반 완만: sqrt 기반 (0~10웨이브)
            curveMult = Mathf.Sqrt(localWave / 10f) * 10f * baseScale;
        }
        else if (localWave <= 20)
        {
            // 중반 선형 (10~20웨이브)
            float basePart = Mathf.Sqrt(1f) * 10f * baseScale; // 10웨이브 시점 값
            curveMult = basePart + (localWave - 10) * baseScale;
        }
        else
        {
            // 후반 가속 (20~30웨이브)
            float basePart = Mathf.Sqrt(1f) * 10f * baseScale + 10f * baseScale;
            float accel = Mathf.Pow((localWave - 20) / 10f, 1.3f) * 10f * baseScale * 1.5f;
            curveMult = basePart + accel;
        }

        // 에리어 전환 점프 (에리어 2: 1.5배, 에리어 3: 2.25배)
        float areaJump = Mathf.Pow(1.5f, area);

        return 1f + curveMult * areaJump;
    }
}
