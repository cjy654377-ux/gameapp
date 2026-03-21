using UnityEngine;
using System.Collections.Generic;

public class StageManager : MonoBehaviour
{
    public static StageManager Instance { get; private set; }

    // ════════════════════════════════════════
    // Area Enum & Constants
    // ════════════════════════════════════════
    public enum GameArea { Grass = 1, Desert = 2, Cave = 3, Volcano = 4, Abyss = 5 }

    // Boss & Enemy Spawning
    private const int AREA_BOSS_COMPANION_COUNT = 5;

    // Boss Scale Multipliers (일반몹 BASE_SCALE=0.8 기준 배율)
    private const float AREA_BOSS_SCALE = 1.3f;  // 보스: 0.8 × 1.3 = 1.04
    private const float MID_BOSS_SCALE = 1.1f;   // 중간보스: 0.8 × 1.1 = 0.88
    private const float BOSS_SCALE_FINAL = 0.8f;

    // Boss Rage Mechanics
    private const float BOSS_RAGE_THRESHOLD = 0.3f; // 30% HP
    private const float BOSS_RAGE_COOLDOWN_MULT = 0.65f;
    private const float BOSS_RAGE_SPEED_MULT = 1.3f;

    // Camera Effects
    private const float AREA_BOSS_SHAKE_MAG = 0.5f;
    private const float AREA_BOSS_SHAKE_DUR = 0.2f;
    private const float MID_BOSS_SHAKE_MAG = 0.3f;
    private const float MID_BOSS_SHAKE_DUR = 0.12f;

    // Spawn Offsets
    private const float SPAWN_X_OFFSET = 8f;
    private const float SPAWN_X_RANGE = 4f;
    private const float SPAWN_X_BOSS_RANGE = 3f;
    private const float BATTLE_ZONE_HEIGHT_RATIO = 0.6f;

    // Wave Thresholds for Difficulty Curve
    private const int WAVE_THRESHOLD_EARLY = 10;
    private const int WAVE_THRESHOLD_MID = 20;
    private const int WAVE_THRESHOLD_LATE = 30;
    private const float DIFFICULTY_SCALE_BASE = 10f;
    private const float LATE_WAVE_ACCEL = 1.5f;

    // Boss Pattern Timings
    private const float BOSS_STUN_INITIAL_DELAY = 3f;
    private const float BOSS_STUN_INTERVAL = 5f;
    private const float BOSS_STUN_DURATION = 1f;
    private const float BOSS_STUN_DISTANCE_MULT = 2f;
    private const float BOSS_AOE_INITIAL_DELAY = 4f;
    private const float BOSS_AOE_INTERVAL = 8f;
    private const float BOSS_AOE_DAMAGE_MULT = 0.3f;

    // Area Traits
    private const float DESERT_SPEED_MULT = 1.3f;
    private const float DESERT_COOLDOWN_MULT = 0.85f;
    private const float DESERT_LIGHTNING_RESIST = 0.3f;
    private const float CAVE_DEF_MULT = 1.4f;
    private const float CAVE_POISON_RESIST = 0.5f;
    private const float VOLCANO_HP_MULT = 1.2f;
    private const float VOLCANO_LIGHTNING_RESIST = 0.4f;
    private const float ABYSS_ATK_MULT = 1.3f;
    private const float ABYSS_LIGHTNING_RESIST = 0.4f;
    private const float ABYSS_POISON_RESIST = 0.4f;

    // Spawn Spread & Difficulty
    private const float BOSS_COMPANION_SPREAD = 0.33f; // 보스 동반 적 분산 비율
    private const float NORMAL_SPAWN_SPREAD   = 0.5f;  // 일반 스폰 X 분산 비율
    private const float BATTLE_ZONE_MARGIN    = 0.45f; // 전투존 Y 범위 여백
    private const float AREA_JUMP_MULT        = 1.5f;  // 에리어 전환 스탯 점프 배율
    private const float DIFFICULTY_CURVE_POW  = 1.3f;  // 후반 난이도 가속 지수

    // BGM Keys
    private static readonly string[] AREA_BGM = { "", "battle_grass", "battle_desert", "battle_cave", "battle_volcano", "battle_abyss" };

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
    public List<CharacterPreset> volcanoEnemies = new();
    public List<CharacterPreset> abyssEnemies = new();

    [Header("Boss Presets")]
    public CharacterPreset grassMidBoss;
    public CharacterPreset grassAreaBoss;
    public CharacterPreset desertMidBoss;
    public CharacterPreset desertAreaBoss;
    public CharacterPreset caveMidBoss;
    public CharacterPreset caveAreaBoss;
    public CharacterPreset volcanoMidBoss;
    public CharacterPreset volcanoAreaBoss;
    public CharacterPreset abyssMidBoss;
    public CharacterPreset abyssAreaBoss;

    // Current progress
    public GameArea CurrentAreaEnum { get; private set; } = GameArea.Grass;
    public int CurrentArea => (int)CurrentAreaEnum;  // Backward compatible
    public int CurrentStage { get; private set; } = 1;
    public int CurrentWave { get; private set; } = 0;
    public int TotalWaveIndex { get; private set; } = 0;

    public event System.Action<int, int, int> OnStageChanged;
    public event System.Action<int> OnAreaChanged;
    public event System.Action<int> OnStageCleared;

    // Revenge system
    public int RevengeStack { get; private set; }
    private int lastDefeatWaveIndex = -1;
    public const int MAX_REVENGE_STACK = 5;
    public event System.Action<int> OnRevengeStackChanged;

    float waveTimer;
    bool waitingForNextWave;
    bool isTransitioning;
    BattleSetup cachedSetup;
    Camera cachedMainCamera;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        // Inspector에서 할당 안 된 경우 Resources에서 자동 로드
        AutoLoadPresets();

        int saved = PlayerPrefs.GetInt(SaveKeys.TotalWaveIndex, 0);
        TotalWaveIndex = saved;
        CalcStageFromTotal(saved);
        SoundManager.Instance?.PlayAreaBGM(CurrentArea);
    }

    void AutoLoadPresets()
    {
        if (grassEnemies.Count > 0) return;

        // 에디터에서 AssetDatabase로 직접 로드
        #if UNITY_EDITOR
        var guids = UnityEditor.AssetDatabase.FindAssets("t:CharacterPreset", new[] { "Assets/Data/Presets" });
        Debug.Log($"[StageManager] Found {guids.Length} presets in Data/Presets");
        foreach (var guid in guids)
        {
            string path = UnityEditor.AssetDatabase.GUIDToAssetPath(guid);
            var p = UnityEditor.AssetDatabase.LoadAssetAtPath<CharacterPreset>(path);
            if (p == null || !p.isEnemy) continue;

            string n = p.name;
            // 보스 매핑 (새 이름 기준)
            if (n == "Enemy_OrcGeneral")      { grassMidBoss    = p; continue; }
            if (n == "Enemy_OrcWarchief")     { grassAreaBoss   = p; continue; }
            if (n == "Enemy_UndeadGeneral")   { desertMidBoss   = p; continue; }
            if (n == "Enemy_Pharaoh")         { desertAreaBoss  = p; continue; }
            if (n == "Enemy_DarkElfShadowMaster") { caveMidBoss   = p; continue; }
            if (n == "Enemy_DarkElfOverlord") { caveAreaBoss    = p; continue; }
            if (n == "Enemy_DemonGeneral")    { volcanoMidBoss  = p; continue; }
            if (n == "Enemy_DemonLord")       { volcanoAreaBoss = p; continue; }
            if (n == "Enemy_DeathKnight")     { abyssMidBoss    = p; continue; }
            if (n == "Enemy_AbyssLord")       { abyssAreaBoss   = p; continue; }

            // 에리어 분류 (종족 키워드 기반)
            if (n.Contains("Orc"))
                grassEnemies.Add(p);
            else if (n.Contains("Mummy") || n.Contains("Skeleton") || n.Contains("Undead") || n.Contains("Pharaoh"))
                desertEnemies.Add(p);
            else if (n.Contains("DarkElf") || n.Contains("Assassin") || n.Contains("Rogue") || n.Contains("Infiltrator") || n.Contains("Trapper") || n.Contains("Hexer") || n.Contains("Overlord"))
                caveEnemies.Add(p);
            else if (n.Contains("Imp") || n.Contains("Flame") || n.Contains("Lava") || n.Contains("Fire") || n.Contains("Devil") || n.Contains("Demon"))
                volcanoEnemies.Add(p);
            else if (n.Contains("Soul") || n.Contains("Shadow") || n.Contains("Wraith") || n.Contains("Spirit") || n.Contains("Vengeance") || n.Contains("Death") || n.Contains("Abyss"))
                abyssEnemies.Add(p);
            else
                grassEnemies.Add(p); // 분류 미정은 grass 폴백
        }
        #else
        // 빌드에서는 Resources 로드
        var allPresets = Resources.LoadAll<CharacterPreset>("Presets");
        if (allPresets == null) return;
        foreach (var p in allPresets)
        {
            if (p == null || !p.isEnemy) continue;
            grassEnemies.Add(p); // 빌드에서는 전부 1에리어로 (임시)
        }
        #endif

        Debug.Log($"[StageManager] AutoLoad: 오크={grassEnemies.Count} 언데드={desertEnemies.Count} 다크엘프={caveEnemies.Count} 악마={volcanoEnemies.Count} 망령={abyssEnemies.Count} | " +
                  $"boss: gM={grassMidBoss?.name} gA={grassAreaBoss?.name} dM={desertMidBoss?.name} dA={desertAreaBoss?.name} " +
                  $"cM={caveMidBoss?.name} cA={caveAreaBoss?.name} vM={volcanoMidBoss?.name} vA={volcanoAreaBoss?.name} " +
                  $"aM={abyssMidBoss?.name} aA={abyssAreaBoss?.name}");
    }

    void CalcStageFromTotal(int total)
    {
        total = Mathf.Max(0, total);
        int wavesPerArea = wavesPerStage * stagesPerArea;
        int areaNum = Mathf.Clamp(total / wavesPerArea + 1, 1, 5);
        CurrentAreaEnum = (GameArea)areaNum;
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
        int idx = Mathf.Clamp(CurrentArea, 0, AREA_BGM.Length - 1);
        string bgm = AREA_BGM[idx];
        if (!string.IsNullOrEmpty(bgm))
            SoundManager.Instance?.PlayBGM(bgm);
    }

    void Update()
    {
        if (!waitingForNextWave || isTransitioning) return;

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
        // Reset revenge stack on successful progress
        if (RevengeStack > 0)
        {
            RevengeStack = 0;
            lastDefeatWaveIndex = -1;
            OnRevengeStackChanged?.Invoke(0);
        }

        int prevStage = CurrentStage;
        int prevArea = CurrentArea;

        TotalWaveIndex++;
        PlayerPrefs.SetInt(SaveKeys.TotalWaveIndex, TotalWaveIndex);
        CalcStageFromTotal(TotalWaveIndex);

        if (CurrentArea != prevArea)
        {
            OnAreaChanged?.Invoke(CurrentArea);
            SoundManager.Instance?.PlayAreaBGM(CurrentArea);
        }

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
            OnWaveCleared?.Invoke();
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
        // 보스 패턴 코루틴 정리 (누적 방지)
        StopAllCoroutines();

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
        waveCountInArea++;
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
                for (int i = 0; i < AREA_BOSS_COMPANION_COUNT; i++)
                    SpawnNormalEnemy(factory, manager, spawnX + Random.Range(SPAWN_X_BOSS_RANGE * BOSS_COMPANION_SPREAD, SPAWN_X_BOSS_RANGE), battleZoneH);
            }
        }
        else
        {
            for (int i = 0; i < enemiesPerWave; i++)
                SpawnNormalEnemy(factory, manager, spawnX + Random.Range(0f, SPAWN_X_RANGE * NORMAL_SPAWN_SPREAD), battleZoneH);
        }

        waveTimer = waveCooldown;
        waitingForNextWave = true;

        // 웨이브 시작 시 에리어 기믹 코루틴 시작 (이전 코루틴은 자동 중지)
        StartAreaMechanic();
    }

    void SpawnNormalEnemy(CharacterFactory factory, BattleManager manager, float spawnX, float battleZoneH)
    {
        var presets = GetAreaEnemies();
        if (presets.Count == 0) return;

        var preset = presets[Random.Range(0, presets.Count)];
        float y = Random.Range(-battleZoneH * BATTLE_ZONE_MARGIN, battleZoneH * BATTLE_ZONE_MARGIN);
        var unit = factory.CreateCharacter(preset, new Vector3(spawnX, y, 0), BattleUnit.Team.Enemy);

        float hpMult = GetDifficultyMultiplier(TotalWaveIndex, hpScalePerWave);
        float atkMult = GetDifficultyMultiplier(TotalWaveIndex, atkScalePerWave);
        unit.maxHp *= hpMult;
        unit.atk *= atkMult;
        unit.CurrentHp = unit.maxHp;
        unit.damageElement = GetAreaElement();

        // 에리어별 적 특성
        ApplyAreaTraits(unit);
        manager.enemyUnits.Add(unit);
    }

    void ApplyAreaTraits(BattleUnit unit)
    {
        switch (CurrentAreaEnum)
        {
            case GameArea.Desert:
                unit.moveSpeed *= DESERT_SPEED_MULT;
                unit.attackCooldown *= DESERT_COOLDOWN_MULT;
                unit.lightningResist = DESERT_LIGHTNING_RESIST;
                break;
            case GameArea.Cave:
                unit.def *= CAVE_DEF_MULT;
                unit.poisonResist = CAVE_POISON_RESIST;
                unit.maxHp *= VOLCANO_HP_MULT;
                unit.CurrentHp = unit.maxHp;
                break;
            case GameArea.Volcano:
                unit.maxHp *= VOLCANO_HP_MULT;
                unit.CurrentHp = unit.maxHp;
                unit.lightningResist = Mathf.Max(unit.lightningResist, VOLCANO_LIGHTNING_RESIST);
                break;
            case GameArea.Abyss:
                unit.atk *= ABYSS_ATK_MULT;
                unit.lightningResist = Mathf.Max(unit.lightningResist, ABYSS_LIGHTNING_RESIST);
                unit.poisonResist = Mathf.Max(unit.poisonResist, ABYSS_POISON_RESIST);
                break;
        }
    }

    public event System.Action<bool> OnBossSpawned; // true = area boss, false = mid boss
    public event System.Action OnWaveCleared;

    void SpawnBoss(CharacterFactory factory, BattleManager manager, float spawnX, bool isAreaBoss)
    {
        var preset = isAreaBoss ? GetAreaBossPreset() : GetMidBossPreset();
        if (preset == null)
        {
            float battleZoneH = GetBattleZoneHeight();
            for (int i = 0; i < enemiesPerWave; i++)
                SpawnNormalEnemy(factory, manager, spawnX + Random.Range(0f, SPAWN_X_RANGE * 0.5f), battleZoneH);
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

        float sizeScale = isAreaBoss ? AREA_BOSS_SCALE : MID_BOSS_SCALE;
        unit.transform.localScale = Vector3.one * sizeScale * BOSS_SCALE_FINAL;

        // Boss rage: HP 이하일 때 공격속도 및 이동속도 증가
        var bossUnit = unit;
        float rageThreshold = unit.maxHp * BOSS_RAGE_THRESHOLD;
        bool raged = false;
        System.Action<float, float> rageHandler = null;
        System.Action deathCleanup = null;
        rageHandler = (hp, max) =>
        {
            if (!raged && hp <= rageThreshold && hp > 0)
            {
                raged = true;
                bossUnit.attackCooldown *= BOSS_RAGE_COOLDOWN_MULT;
                bossUnit.moveSpeed *= BOSS_RAGE_SPEED_MULT;
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

        // Boss special patterns
        if (isAreaBoss)
            StartCoroutine(BossAoePattern(bossUnit));
        else
            StartCoroutine(BossStunPattern(bossUnit));

        manager.enemyUnits.Add(unit);
        SoundManager.Instance?.PlayBossAppearSFX();
        OnBossSpawned?.Invoke(isAreaBoss);
        StartCoroutine(BossSlowMotion());

        // 카메라 셰이크
        var cam = GetMainCamera();
        var camShake = cam != null ? cam.GetComponent<QuarterViewCamera>() : null;
        if (camShake != null)
        {
            float shakeMag = isAreaBoss ? AREA_BOSS_SHAKE_MAG : MID_BOSS_SHAKE_MAG;
            float shakeDur = isAreaBoss ? AREA_BOSS_SHAKE_DUR : MID_BOSS_SHAKE_DUR;
            camShake.Shake(shakeMag, shakeDur);
        }
    }

    System.Collections.IEnumerator BossSlowMotion()
    {
        const float SLOW_SCALE   = 0.3f;
        const float HOLD_TIME    = 0.4f; // 실제 시간 기준
        const float RESTORE_TIME = 0.3f;

        Time.timeScale = SLOW_SCALE;
        yield return new WaitForSecondsRealtime(HOLD_TIME);

        float elapsed = 0f;
        while (elapsed < RESTORE_TIME)
        {
            elapsed += Time.unscaledDeltaTime;
            Time.timeScale = Mathf.Lerp(SLOW_SCALE, 1f, elapsed / RESTORE_TIME);
            yield return null;
        }
        Time.timeScale = 1f;
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
        if (cam == null) return SPAWN_X_OFFSET;
        return cam.transform.position.x + cam.orthographicSize * cam.aspect + SPAWN_X_RANGE;
    }

    float GetBattleZoneHeight()
    {
        var cam = GetMainCamera();
        float camH = cam != null ? cam.orthographicSize * 2f : 10f;
        return camH * BATTLE_ZONE_HEIGHT_RATIO;
    }

    List<CharacterPreset> GetAreaEnemies()
    {
        return CurrentAreaEnum switch
        {
            GameArea.Grass   => grassEnemies,
            GameArea.Desert  => desertEnemies,
            GameArea.Cave    => caveEnemies,
            GameArea.Volcano => volcanoEnemies.Count > 0 ? volcanoEnemies : grassEnemies,
            GameArea.Abyss   => abyssEnemies.Count > 0 ? abyssEnemies : caveEnemies,
            _                => grassEnemies
        };
    }

    SkillElement GetAreaElement()
    {
        return CurrentAreaEnum switch
        {
            GameArea.Grass   => SkillElement.None,
            GameArea.Desert  => SkillElement.Lightning,
            GameArea.Cave    => SkillElement.None,
            GameArea.Volcano => SkillElement.None,
            GameArea.Abyss   => SkillElement.None,
            _                => SkillElement.None
        };
    }

    CharacterPreset GetMidBossPreset()
    {
        return CurrentAreaEnum switch
        {
            GameArea.Grass   => grassMidBoss,
            GameArea.Desert  => desertMidBoss,
            GameArea.Cave    => caveMidBoss,
            GameArea.Volcano => volcanoMidBoss,
            GameArea.Abyss   => abyssMidBoss,
            _                => grassMidBoss
        };
    }

    CharacterPreset GetAreaBossPreset()
    {
        return CurrentAreaEnum switch
        {
            GameArea.Grass   => grassAreaBoss,
            GameArea.Desert  => desertAreaBoss,
            GameArea.Cave    => caveAreaBoss,
            GameArea.Volcano => volcanoAreaBoss,
            GameArea.Abyss   => abyssAreaBoss,
            _                => grassAreaBoss
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

        // Revenge stack: same wave = stack+1, new wave = stack reset to 1
        if (lastDefeatWaveIndex == TotalWaveIndex)
            RevengeStack = Mathf.Min(RevengeStack + 1, MAX_REVENGE_STACK);
        else
        {
            RevengeStack = 1;
            lastDefeatWaveIndex = TotalWaveIndex;
        }
        OnRevengeStackChanged?.Invoke(RevengeStack);

        if (TotalWaveIndex > 0)
            TotalWaveIndex--;
        PlayerPrefs.SetInt(SaveKeys.TotalWaveIndex, TotalWaveIndex);
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
            SpawnWaveImmediate();
            isTransitioning = false; // SpawnWaveImmediate 이후 해제 (waitingForNextWave 동기화)
        });
    }

    public string GetStageText()
    {
        int displayStage = (CurrentArea - 1) * stagesPerArea + CurrentStage;
        return $"{displayStage}-{CurrentWave}";
    }

    public string GetAreaName()
    {
        return CurrentAreaEnum switch
        {
            GameArea.Grass   => "초원",
            GameArea.Desert  => "사막",
            GameArea.Cave    => "동굴",
            GameArea.Volcano => "화산",
            GameArea.Abyss   => "암흑성",
            _                => "Unknown"
        };
    }

    /// <summary>
    /// 구간별 난이도 곡선: 초반 완만 → 중반 선형 → 후반 가파름 + 에리어 전환 점프
    /// wave 0~29: 완만 (sqrt 기반), 30~59: 선형, 60+: 가속 (pow 1.3)
    /// 에리어 전환 시 1.5배 점프
    /// </summary>
    float GetDifficultyMultiplier(int wave, float baseScale)
    {
        int wavesPerArea = wavesPerStage * stagesPerArea;
        int area = wave / wavesPerArea;
        int localWave = wave % wavesPerArea;

        // 구간별 난이도 곡선
        float curveMult;
        if (localWave <= WAVE_THRESHOLD_EARLY)
        {
            // 초반 완만: sqrt 기반
            curveMult = Mathf.Sqrt(localWave / (float)WAVE_THRESHOLD_EARLY) * DIFFICULTY_SCALE_BASE * baseScale;
        }
        else if (localWave <= WAVE_THRESHOLD_MID)
        {
            // 중반 선형
            float basePart = Mathf.Sqrt(1f) * DIFFICULTY_SCALE_BASE * baseScale;
            curveMult = basePart + (localWave - WAVE_THRESHOLD_EARLY) * baseScale;
        }
        else
        {
            // 후반 가속
            float basePart = Mathf.Sqrt(1f) * DIFFICULTY_SCALE_BASE * baseScale + WAVE_THRESHOLD_EARLY * baseScale;
            float accel = Mathf.Pow((localWave - WAVE_THRESHOLD_MID) / (float)WAVE_THRESHOLD_EARLY, DIFFICULTY_CURVE_POW) * DIFFICULTY_SCALE_BASE * baseScale * LATE_WAVE_ACCEL;
            curveMult = basePart + accel;
        }

        // 에리어 전환 점프 (1.5배씩 누적)
        float areaJump = Mathf.Pow(AREA_JUMP_MULT, area);

        return 1f + curveMult * areaJump;
    }

    // ════════════════════════════════════════
    // Boss Special Patterns
    // ════════════════════════════════════════

    /// <summary>
    /// 미드보스: 일정 주기마다 가장 가까운 아군에게 스턴 적용
    /// </summary>
    System.Collections.IEnumerator BossStunPattern(BattleUnit boss)
    {
        yield return new WaitForSeconds(BOSS_STUN_INITIAL_DELAY);
        while (boss != null && !boss.IsDead)
        {
            var manager = BattleManager.Instance;
            if (manager != null && manager.CurrentState == BattleManager.BattleState.Fighting)
            {
                BattleUnit nearest = null;
                float minDist = float.MaxValue;
                for (int i = 0; i < manager.allyUnits.Count; i++)
                {
                    var ally = manager.allyUnits[i];
                    if (ally == null || ally.IsDead) continue;
                    float d = Vector3.Distance(boss.transform.position, ally.transform.position);
                    if (d < minDist) { minDist = d; nearest = ally; }
                }
                if (nearest != null && minDist < boss.attackRange * BOSS_STUN_DISTANCE_MULT)
                {
                    nearest.ApplyStun(BOSS_STUN_DURATION);
                    DamagePopup.Create(nearest.transform.position + Vector3.up * 0.7f, 0f, false, "STUN!");
                    EffectManager.Instance?.SpawnLightningEffect(nearest.transform.position);
                }
            }
            yield return new WaitForSeconds(BOSS_STUN_INTERVAL);
        }
    }

    /// <summary>
    /// 에리어 보스: 일정 주기마다 전체 아군에게 광역 데미지
    /// </summary>
    System.Collections.IEnumerator BossAoePattern(BattleUnit boss)
    {
        yield return new WaitForSeconds(BOSS_AOE_INITIAL_DELAY);
        while (boss != null && !boss.IsDead)
        {
            var manager = BattleManager.Instance;
            if (manager != null && manager.CurrentState == BattleManager.BattleState.Fighting)
            {
                float aoeDmg = boss.atk * BOSS_AOE_DAMAGE_MULT;
                for (int i = 0; i < manager.allyUnits.Count; i++)
                {
                    var ally = manager.allyUnits[i];
                    if (ally == null || ally.IsDead) continue;
                    ally.TakeDamage(aoeDmg);
                }
                EffectManager.Instance?.SpawnLightningEffect(boss.transform.position);

                // 카메라 셰이크
                var cam = GetMainCamera();
                var camShake = cam != null ? cam.GetComponent<QuarterViewCamera>() : null;
                if (camShake != null) camShake.Shake(AREA_BOSS_SHAKE_MAG * 0.4f, AREA_BOSS_SHAKE_DUR * 0.5f);
            }
            yield return new WaitForSeconds(BOSS_AOE_INTERVAL);
        }
    }

    // ─── Area Mechanics Coroutines ───

    Coroutine areaMechanicCoroutine;

    void StartAreaMechanic()
    {
        if (areaMechanicCoroutine != null)
            StopCoroutine(areaMechanicCoroutine);

        areaMechanicCoroutine = StartCoroutine(RunAreaMechanic());
    }

    System.Collections.IEnumerator RunAreaMechanic()
    {
        switch (CurrentAreaEnum)
        {
            case GameArea.Desert:
                yield return StartCoroutine(DesertMechanicRoutine());
                break;
            case GameArea.Cave:
                yield return StartCoroutine(CaveMechanicRoutine());
                break;
            case GameArea.Volcano:
                yield return StartCoroutine(VolcanoMechanicRoutine());
                break;
            case GameArea.Abyss:
                yield return StartCoroutine(AbyssMechanicRoutine());
                break;
        }
    }

    /// <summary>
    /// 사막: 15초마다 모래폭풍 (전체 아군 ATK -10%, 5초)
    /// </summary>
    System.Collections.IEnumerator DesertMechanicRoutine()
    {
        while (true)
        {
            yield return new WaitForSeconds(15f);
            var manager = BattleManager.Instance;
            if (manager == null || manager.CurrentState != BattleManager.BattleState.Fighting) break;

            for (int i = 0; i < manager.allyUnits.Count; i++)
            {
                var ally = manager.allyUnits[i];
                if (ally == null || ally.IsDead) continue;
                float atkReduction = -ally.atk * 0.1f;
                ally.ApplyBuff(atkReduction, 0, 5f);
            }

            DamagePopup.Create(Vector3.zero, 0f, false, "모래폭풍!");
        }
    }

    /// <summary>
    /// 동굴: 시야 제한 (화면 가장자리 어둡게)
    /// </summary>
    System.Collections.IEnumerator CaveMechanicRoutine()
    {
        var bgController = BattleBackground.Instance;
        if (bgController != null)
            bgController.ApplyCaveDarkness(true);

        while (true)
        {
            yield return new WaitForSeconds(1f);
            var manager = BattleManager.Instance;
            if (manager == null || manager.CurrentState != BattleManager.BattleState.Fighting) break;
        }

        if (bgController != null)
            bgController.ApplyCaveDarkness(false);
    }

    /// <summary>
    /// 화산: 3초마다 용암 데미지 (전체 유닛 maxHP 1%)
    /// </summary>
    System.Collections.IEnumerator VolcanoMechanicRoutine()
    {
        while (true)
        {
            yield return new WaitForSeconds(3f);
            var manager = BattleManager.Instance;
            if (manager == null || manager.CurrentState != BattleManager.BattleState.Fighting) break;

            foreach (var unit in manager.allyUnits)
            {
                if (unit != null && !unit.IsDead)
                    unit.TakeDamage(unit.maxHp * 0.01f);
            }
            foreach (var unit in manager.enemyUnits)
            {
                if (unit != null && !unit.IsDead)
                    unit.TakeDamage(unit.maxHp * 0.01f);
            }
        }
    }

    /// <summary>
    /// 심연: 10초마다 랜덤 아군 1명 3초 행동불능
    /// </summary>
    System.Collections.IEnumerator AbyssMechanicRoutine()
    {
        while (true)
        {
            yield return new WaitForSeconds(10f);
            var manager = BattleManager.Instance;
            if (manager == null || manager.CurrentState != BattleManager.BattleState.Fighting) break;

            var aliveAllies = new List<BattleUnit>();
            foreach (var ally in manager.allyUnits)
            {
                if (ally != null && !ally.IsDead)
                    aliveAllies.Add(ally);
            }

            if (aliveAllies.Count > 0)
            {
                BattleUnit target = aliveAllies[Random.Range(0, aliveAllies.Count)];
                target.ApplyStun(3f);
                DamagePopup.Create(target.transform.position + Vector3.up * 0.7f, 0f, false, "STUN!");
            }
        }
    }
}
