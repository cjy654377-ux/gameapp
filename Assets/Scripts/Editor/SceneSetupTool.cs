#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

public class SceneSetupTool
{
    [MenuItem("Game/Setup Battle Scene")]
    public static void SetupBattleScene()
    {
        var gm = GameObject.Find("GameManager");
        if (gm == null)
        {
            Debug.LogError("GameManager not found in scene!");
            return;
        }

        // CharacterFactory - assign base prefab
        var factory = gm.GetComponent<CharacterFactory>();
        if (factory != null)
        {
            factory.spumBasePrefab = AssetDatabase.LoadAssetAtPath<GameObject>(
                "Assets/SPUM/Resources/Addons/Legacy/2_Prefab/SPUM_20250915183854408.prefab");
            if (factory.spumBasePrefab == null)
                Debug.LogError("SPUM base prefab not found!");
            else
                Debug.Log("Base prefab assigned: " + factory.spumBasePrefab.name);
        }

        // BattleSetup - assign ally presets
        var setup = gm.GetComponent<BattleSetup>();
        if (setup != null)
        {
            setup.allyPresets.Clear();
            AddPreset(setup.allyPresets, "Assets/Data/Presets/Ally_Swordsman.asset");
            AddPreset(setup.allyPresets, "Assets/Data/Presets/Ally_Archer.asset");
            AddPreset(setup.allyPresets, "Assets/Data/Presets/Ally_Mage.asset");
            Debug.Log($"Ally presets assigned: {setup.allyPresets.Count}");
        }

        // StageManager - assign enemy presets by area
        var stageMgr = EnsureComponent<StageManager>(FindOrCreate("StageManager"));
        stageMgr.grassEnemies.Clear();
        AddPreset(stageMgr.grassEnemies, "Assets/Data/Presets/Enemy_OrcWarrior.asset");
        AddPreset(stageMgr.grassEnemies, "Assets/Data/Presets/Enemy_Skeleton.asset");
        AddPreset(stageMgr.grassEnemies, "Assets/Data/Presets/Enemy_OrcArcher.asset");
        AddPreset(stageMgr.grassEnemies, "Assets/Data/Presets/Enemy_SkeletonMage.asset");
        AddPreset(stageMgr.grassEnemies, "Assets/Data/Presets/Enemy_OrcChief.asset");

        stageMgr.desertEnemies.Clear();
        AddPreset(stageMgr.desertEnemies, "Assets/Data/Presets/Enemy_Demon.asset");
        AddPreset(stageMgr.desertEnemies, "Assets/Data/Presets/Enemy_DarkKnight.asset");
        AddPreset(stageMgr.desertEnemies, "Assets/Data/Presets/Enemy_SandScorpion.asset");
        AddPreset(stageMgr.desertEnemies, "Assets/Data/Presets/Enemy_DesertMage.asset");

        stageMgr.caveEnemies.Clear();
        AddPreset(stageMgr.caveEnemies, "Assets/Data/Presets/Enemy_CaveGolem.asset");
        AddPreset(stageMgr.caveEnemies, "Assets/Data/Presets/Enemy_CaveBat.asset");
        AddPreset(stageMgr.caveEnemies, "Assets/Data/Presets/Enemy_RedRider.asset");
        AddPreset(stageMgr.caveEnemies, "Assets/Data/Presets/Enemy_PoisonSpider.asset");

        // Boss presets
        stageMgr.grassMidBoss = AssetDatabase.LoadAssetAtPath<CharacterPreset>("Assets/Data/Presets/Enemy_OrcChief.asset");
        stageMgr.grassAreaBoss = AssetDatabase.LoadAssetAtPath<CharacterPreset>("Assets/Data/Presets/Enemy_OrcChief.asset");
        stageMgr.desertMidBoss = AssetDatabase.LoadAssetAtPath<CharacterPreset>("Assets/Data/Presets/Enemy_DarkKnight.asset");
        stageMgr.desertAreaBoss = AssetDatabase.LoadAssetAtPath<CharacterPreset>("Assets/Data/Presets/Enemy_Demon.asset");
        stageMgr.caveMidBoss = AssetDatabase.LoadAssetAtPath<CharacterPreset>("Assets/Data/Presets/Enemy_RedRider.asset");
        stageMgr.caveAreaBoss = AssetDatabase.LoadAssetAtPath<CharacterPreset>("Assets/Data/Presets/Enemy_CaveGolem.asset");
        Debug.Log("StageManager presets assigned");

        // GachaManager - assign hero pool (allies only)
        var gachaMgr = EnsureComponent<GachaManager>(gm);
        var heroPool = new System.Collections.Generic.List<CharacterPreset>();
        AddPreset(heroPool, "Assets/Data/Presets/Ally_Swordsman.asset");
        AddPreset(heroPool, "Assets/Data/Presets/Ally_Archer.asset");
        AddPreset(heroPool, "Assets/Data/Presets/Ally_Mage.asset");
        AddPreset(heroPool, "Assets/Data/Presets/Ally_Knight.asset");
        AddPreset(heroPool, "Assets/Data/Presets/Ally_Lancer.asset");
        AddPreset(heroPool, "Assets/Data/Presets/Ally_Healer.asset");
        AddPreset(heroPool, "Assets/Data/Presets/Ally_Bard.asset");
        gachaMgr.SetHeroPool(heroPool.ToArray());
        Debug.Log($"GachaManager pool set: {heroPool.Count} heroes");

        // DeckManager - assign roster
        var deckMgr = EnsureComponent<DeckManager>(gm);
        deckMgr.roster.Clear();
        deckMgr.roster.AddRange(heroPool);

        // Ensure managers
        EnsureComponent<ObjectPool>(gm);
        EnsureComponent<GoldManager>(gm);
        EnsureComponent<TapDamageSystem>(gm);
        EnsureComponent<SkillManager>(gm);
        EnsureComponent<UpgradeManager>(FindOrCreate("UpgradeManager"));
        EnsureComponent<DailyMissionManager>(gm);
        EnsureComponent<DailyLoginManager>(gm);
        EnsureComponent<CollectionManager>(gm);
        EnsureComponent<SkillUpgradeManager>(gm);
        EnsureComponent<ArenaManager>(gm);

        // EventSystem
        if (GameObject.FindFirstObjectByType<UnityEngine.EventSystems.EventSystem>() == null)
        {
            var esObj = new GameObject("EventSystem");
            esObj.AddComponent<UnityEngine.EventSystems.EventSystem>();
            esObj.AddComponent<UnityEngine.EventSystems.StandaloneInputModule>();
        }

        // Background
        if (GameObject.Find("Background") == null)
        {
            var bgObj = new GameObject("Background");
            bgObj.AddComponent<BattleBackground>();
        }

        // UI objects
        EnsureUIObject("MainHUD", typeof(MainHUD));
        EnsureUIObject("SkillUI", typeof(SkillUI));
        EnsureUIObject("GrowthFeedback", typeof(GrowthFeedback));

        // Assign default skills
        var skillMgr = gm.GetComponent<SkillManager>();
        if (skillMgr != null)
        {
            skillMgr.equippedSkills.Clear();
            AddSkill(skillMgr, "Assets/Resources/Skills/Skill_Fireball.asset");
            AddSkill(skillMgr, "Assets/Resources/Skills/Skill_HealingLight.asset");
            AddSkill(skillMgr, "Assets/Resources/Skills/Skill_LightningStorm.asset");
            AddSkill(skillMgr, "Assets/Resources/Skills/Skill_PoisonFog.asset");
        }

        EditorUtility.SetDirty(gm);
        UnityEditor.SceneManagement.EditorSceneManager.MarkSceneDirty(
            UnityEditor.SceneManagement.EditorSceneManager.GetActiveScene());
        Debug.Log("Battle scene setup complete!");
    }

    static GameObject FindOrCreate(string name)
    {
        var obj = GameObject.Find(name);
        if (obj == null) obj = new GameObject(name);
        return obj;
    }

    static void AddPreset(System.Collections.Generic.List<CharacterPreset> list, string path)
    {
        var preset = AssetDatabase.LoadAssetAtPath<CharacterPreset>(path);
        if (preset != null)
            list.Add(preset);
        else
            Debug.LogWarning("Preset not found: " + path);
    }

    static void AddSkill(SkillManager mgr, string path)
    {
        var skill = AssetDatabase.LoadAssetAtPath<SkillData>(path);
        if (skill != null)
            mgr.equippedSkills.Add(skill);
    }

    static T EnsureComponent<T>(GameObject go) where T : Component
    {
        var comp = go.GetComponent<T>();
        if (comp == null) comp = go.AddComponent<T>();
        return comp;
    }

    static void EnsureUIObject(string name, System.Type componentType)
    {
        var existing = GameObject.Find(name);
        if (existing == null)
        {
            existing = new GameObject(name);
            existing.AddComponent(componentType);
        }
    }
}
#endif
