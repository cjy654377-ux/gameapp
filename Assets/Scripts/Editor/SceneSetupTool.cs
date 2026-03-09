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

        stageMgr.caveEnemies.Clear();
        AddPreset(stageMgr.caveEnemies, "Assets/Data/Presets/Enemy_RedRider.asset");
        AddPreset(stageMgr.caveEnemies, "Assets/Data/Presets/Enemy_Skeleton.asset");

        // Boss presets (use existing strong enemies as placeholders)
        stageMgr.grassMidBoss = AssetDatabase.LoadAssetAtPath<CharacterPreset>("Assets/Data/Presets/Enemy_OrcChief.asset");
        stageMgr.grassAreaBoss = AssetDatabase.LoadAssetAtPath<CharacterPreset>("Assets/Data/Presets/Enemy_OrcChief.asset");
        stageMgr.desertMidBoss = AssetDatabase.LoadAssetAtPath<CharacterPreset>("Assets/Data/Presets/Enemy_DarkKnight.asset");
        stageMgr.desertAreaBoss = AssetDatabase.LoadAssetAtPath<CharacterPreset>("Assets/Data/Presets/Enemy_DarkKnight.asset");
        stageMgr.caveMidBoss = AssetDatabase.LoadAssetAtPath<CharacterPreset>("Assets/Data/Presets/Enemy_RedRider.asset");
        stageMgr.caveAreaBoss = AssetDatabase.LoadAssetAtPath<CharacterPreset>("Assets/Data/Presets/Enemy_RedRider.asset");
        Debug.Log("StageManager presets assigned");

        // Ensure managers
        EnsureComponent<GoldManager>(gm);
        EnsureComponent<TapDamageSystem>(gm);
        EnsureComponent<SkillManager>(gm);
        EnsureComponent<UpgradeManager>(FindOrCreate("UpgradeManager"));

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
        EnsureUIObject("BattleHUD", typeof(BattleHUD));
        EnsureUIObject("SkillUI", typeof(SkillUI));
        EnsureUIObject("GoldUI", typeof(GoldUI));
        EnsureUIObject("UpgradeUI", typeof(UpgradeUI));

        // Assign default skills
        var skillMgr = gm.GetComponent<SkillManager>();
        if (skillMgr != null)
        {
            skillMgr.equippedSkills.Clear();
            AddSkill(skillMgr, "Assets/Data/Skills/Skill_Fireball.asset");
            AddSkill(skillMgr, "Assets/Data/Skills/Skill_IceBlast.asset");
            AddSkill(skillMgr, "Assets/Data/Skills/Skill_Heal.asset");
            AddSkill(skillMgr, "Assets/Data/Skills/Skill_PoisonCloud.asset");
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
