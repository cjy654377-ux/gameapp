using UnityEngine;
using System.Collections.Generic;

public class CharacterFactory : MonoBehaviour
{
    public static CharacterFactory Instance { get; private set; }

    [Header("Base Prefab")]
    public GameObject spumBasePrefab;

    static readonly Dictionary<string, Sprite[]> spriteCache = new();

    const float BASE_SCALE          = 0.8f;
    const float GOLD_REWARD_HP_RATIO = 0.5f;

    // 성급별 크기 배율 (index = StarGrade int)
    static readonly float[] STAR_SCALE = { 1.0f, 1.0f, 1.0f, 1.4f, 1.7f, 2.0f };
    // 적 성급별 스탯 배율
    static readonly float[] ENEMY_STAT_MULT = { 1.0f, 1.0f, 1.3f, 2.0f, 3.5f, 6.0f };

    void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(gameObject);

        // SPUM 저장 프리팹 로드 (UnitRoot/HorseRoot 구조 포함)
        if (spumBasePrefab == null)
            spumBasePrefab = Resources.Load<GameObject>("Addons/Legacy/2_Prefab/SPUM_20250915183854408");
        #if UNITY_EDITOR
        if (spumBasePrefab == null)
            spumBasePrefab = UnityEditor.AssetDatabase.LoadAssetAtPath<GameObject>(
                "Assets/SPUM/Resources/Addons/Legacy/2_Prefab/SPUM_20250915183854408.prefab");
        #endif
        if (spumBasePrefab == null)
            Debug.LogError("[CharacterFactory] SPUM 프리팹 로드 실패!");
    }

    void OnDestroy()
    {
        if (Instance == this)
        {
            Instance = null;
            spriteCache.Clear();
        }
    }

    public BattleUnit CreateCharacter(CharacterPreset preset, Vector3 position, BattleUnit.Team team)
    {
        if (preset == null)
        {
            Debug.LogError("[CharacterFactory] preset is null!");
            return null;
        }
        if (spumBasePrefab == null)
        {
            Debug.LogError("[CharacterFactory] spumBasePrefab is null!");
            return null;
        }

        // 진형 오프셋: 후열 아군은 X -1.0f 뒤로 배치
        if (team == BattleUnit.Team.Ally && DeckManager.Instance != null &&
            DeckManager.Instance.GetFormation(preset) == DeckManager.FormationSlot.Back)
            position.x -= 1.0f;

        var unitObj = new GameObject(preset.characterName);
        unitObj.transform.position = position;

        // SPUM 프리팹 인스턴스화
        var spumInstance = Instantiate(spumBasePrefab);

        // 탈것 스프라이트 결정 (아군: MountManager 우선, 적: preset)
        string horseSprite = preset.horseSprite;
        if (team == BattleUnit.Team.Ally && MountManager.Instance != null)
        {
            string mountFolder = MountManager.Instance.GetEquippedSpriteFolder();
            if (!string.IsNullOrEmpty(mountFolder))
                horseSprite = mountFolder;
        }
        bool useHorse = !string.IsNullOrEmpty(horseSprite);

        if (useHorse)
        {
            var horseRoot = spumInstance.transform.Find("HorseRoot");
            if (horseRoot != null)
            {
                horseRoot.SetParent(unitObj.transform, false);
                horseRoot.localPosition = Vector3.zero;
                horseRoot.gameObject.SetActive(true);
                ApplyHorseSprites(horseRoot, horseSprite);
            }
            else
            {
                // HorseRoot 없으면 UnitRoot 폴백
                AttachUnitRoot(spumInstance, unitObj);
            }
        }
        else
        {
            AttachUnitRoot(spumInstance, unitObj);
        }
        Destroy(spumInstance);

        // Shadow 비활성화
        DisableShadows(unitObj.transform);

        // 스프라이트 적용
        ApplySprites(unitObj, preset);

        var battleUnit = unitObj.AddComponent<BattleUnit>();
        ConfigureBattleUnit(battleUnit, preset, team);

        ApplyStarScale(unitObj, preset.starGrade);
        if (team == BattleUnit.Team.Enemy)
            ApplyEnemyStatMult(battleUnit, preset.starGrade);

        unitObj.AddComponent<HpBar>();

        RegisterCollections(preset, team);
        if (team == BattleUnit.Team.Enemy)
            SetupGoldDrop(battleUnit, preset);

        return battleUnit;
    }

    static void ConfigureBattleUnit(BattleUnit battleUnit, CharacterPreset preset, BattleUnit.Team team)
    {
        battleUnit.unitName       = preset.characterName;
        battleUnit.cachedPreset   = preset;
        battleUnit.maxHp          = preset.maxHp;
        battleUnit.atk            = preset.atk;
        battleUnit.def            = preset.def;
        battleUnit.moveSpeed      = preset.moveSpeed;
        battleUnit.attackRange    = preset.attackRange;
        battleUnit.attackCooldown = preset.attackCooldown;
        battleUnit.damageElement  = preset.damageElement;
        battleUnit.lightningResist = preset.lightningResist;
        battleUnit.poisonResist   = preset.poisonResist;

        if (preset.isHealer)
        {
            battleUnit.role         = BattleUnit.RoleType.Healer;
            battleUnit.healAmount   = preset.healAmount;
            battleUnit.healCooldown = preset.healCooldown;
            battleUnit.healRange    = preset.healRange;
        }
        else if (preset.isBuffer)
        {
            battleUnit.role          = BattleUnit.RoleType.Buffer;
            battleUnit.buffAtkBonus  = preset.buffAtkBonus;
            battleUnit.buffDefBonus  = preset.buffDefBonus;
            battleUnit.buffDuration  = preset.buffDuration;
            battleUnit.buffCooldown  = preset.buffCooldown;
            battleUnit.buffRange     = preset.buffRange;
        }

        if (preset.skills != null && preset.skills.Length > 0)
            battleUnit.skills = preset.skills;

        battleUnit.Init(preset.attackAnimType);
        battleUnit.SetTeam(team);
    }

    void ApplyStarScale(GameObject unitObj, StarGrade star)
    {
        int idx = Mathf.Clamp((int)star, 0, STAR_SCALE.Length - 1);
        unitObj.transform.localScale = Vector3.one * BASE_SCALE * STAR_SCALE[idx];
    }

    void ApplyEnemyStatMult(BattleUnit unit, StarGrade star)
    {
        int idx = Mathf.Clamp((int)star, 0, ENEMY_STAT_MULT.Length - 1);
        float mult = ENEMY_STAT_MULT[idx];
        unit.maxHp *= mult;
        unit.atk   *= mult;
        unit.def   *= mult;
    }

    static void RegisterCollections(CharacterPreset preset, BattleUnit.Team team)
    {
        if (team == BattleUnit.Team.Ally)
            CollectionManager.Instance?.RegisterHero(preset.characterName);
        else
            CollectionManager.Instance?.RegisterMonster(preset.characterName);
    }

    static void SetupGoldDrop(BattleUnit battleUnit, CharacterPreset preset)
    {
        int goldReward = Mathf.RoundToInt(preset.maxHp * GOLD_REWARD_HP_RATIO);
        System.Action deathHandler = null;
        var unitRef = battleUnit;
        deathHandler = () =>
        {
            GoldDrop.Spawn(unitRef.transform.position, goldReward);
            unitRef.OnDeath -= deathHandler;
        };
        battleUnit.OnDeath += deathHandler;
    }

    void AttachUnitRoot(GameObject spumInstance, GameObject unitObj)
    {
        var unitRoot = spumInstance.transform.Find("UnitRoot");
        if (unitRoot != null)
        {
            unitRoot.SetParent(unitObj.transform, false);
            unitRoot.localPosition = Vector3.zero;
            unitRoot.localScale = Vector3.one;
        }
        else
        {
            // UnitRoot 없으면 전체 자식을 직접 붙임
            Debug.LogWarning("[CharacterFactory] UnitRoot not found, attaching all children");
            while (spumInstance.transform.childCount > 0)
            {
                var child = spumInstance.transform.GetChild(0);
                child.SetParent(unitObj.transform, false);
            }
        }
    }

    static readonly Dictionary<string, string> HorsePartNameMap = new()
    {
        { "Head", "Head" }, { "Neck", "Neck" },
        { "BodyFront", "BodyFront" }, { "BodyBack", "BodyBack" },
        { "Tail", "Tail" }, { "Acc", "Acc" },
    };

    void ApplyHorseSprites(Transform horseRoot, string horseName)
    {
        var horseSprites = LoadSprites($"Addons/Legacy/1_Horse/0_Sprite/0_Body/{horseName}");
        if (horseSprites == null || horseSprites.Length == 0) return;

        var spriteLookup = new Dictionary<string, Sprite>();
        foreach (var s in horseSprites)
            spriteLookup[s.name] = s;

        var horseSRs = horseRoot.GetComponentsInChildren<SpriteRenderer>(true);
        foreach (var sr in horseSRs)
        {
            string goName = sr.gameObject.name;
            if (HorsePartNameMap.TryGetValue(goName, out string spriteName))
            {
                if (spriteLookup.TryGetValue(spriteName, out var sprite))
                    sr.sprite = sprite;
            }
            else if (goName == "FrontFootTop")
            {
                if (spriteLookup.TryGetValue("FootFrontTop", out var s1)) sr.sprite = s1;
                else if (spriteLookup.TryGetValue("FootBackTop", out var s2)) sr.sprite = s2;
            }
            else if (goName == "FrontFootBottom")
            {
                if (spriteLookup.TryGetValue("FootFrontBottom", out var s1)) sr.sprite = s1;
                else if (spriteLookup.TryGetValue("FootBackBottom", out var s2)) sr.sprite = s2;
            }
        }
    }

    void ApplySprites(GameObject unitObj, CharacterPreset preset)
    {
        var renderers = unitObj.GetComponentsInChildren<SpriteRenderer>(true);

        // Body
        if (!string.IsNullOrEmpty(preset.bodySprite))
        {
            var bodySprites = LoadSprites($"Addons/Legacy/0_Unit/0_Sprite/1_Body/{preset.bodySprite}");
            if (bodySprites != null && bodySprites.Length > 0)
            {
                foreach (var sr in renderers)
                {
                    if (sr == null) continue;
                    string srName = sr.gameObject.name;
                    if (srName == "Body" && sr.transform.parent.name == "P_Body")
                        AssignBodyPart(sr, bodySprites, "Body", preset.bodyColor);
                    else if (srName == "5_Head")
                        AssignBodyPart(sr, bodySprites, "Head", preset.bodyColor);
                    else if (srName == "20_L_Arm" || srName == "21_LCArm" || srName == "25_L_Shoulder")
                        AssignBodyPart(sr, bodySprites, "Arm_L", preset.bodyColor);
                    else if (srName == "-20_R_Arm" || srName == "-19_RCArm" || srName == "-15_R_Shoulder")
                        AssignBodyPart(sr, bodySprites, "Arm_R", preset.bodyColor);
                    else if (srName == "_3L_Foot")
                        AssignBodyPart(sr, bodySprites, "Foot_L", preset.bodyColor);
                    else if (srName == "_12R_Foot")
                        AssignBodyPart(sr, bodySprites, "Foot_R", preset.bodyColor);
                }
            }
        }

        // Weapon (Right hand)
        if (!string.IsNullOrEmpty(preset.weaponSprite))
        {
            var weaponSprite = FindWeaponSprite(preset.weaponSprite);
            if (weaponSprite != null)
            {
                foreach (var sr in renderers)
                {
                    if (sr.gameObject.name == "R_Weapon")
                    { sr.sprite = weaponSprite; break; }
                }
            }
        }

        // Shield / Left-hand weapon
        if (!string.IsNullOrEmpty(preset.shieldSprite))
        {
            var leftSprite = FindWeaponSprite(preset.shieldSprite);
            if (leftSprite != null)
            {
                foreach (var sr in renderers)
                {
                    if (sr.gameObject.name == "L_Weapon")
                    { sr.sprite = leftSprite; break; }
                }
            }
        }

        // Eye, Hair, Helmet
        ApplySimplePart(renderers, preset.eyeSprite, "0_Eye", "Front", preset.eyeColor);
        ApplySimplePart(renderers, preset.hairSprite, "0_Hair", "7_Hair", Color.white);
        ApplySimplePart(renderers, preset.helmetSprite, "4_Helmet", "11_Helmet1", Color.white);

        // Armor (multi-part)
        if (!string.IsNullOrEmpty(preset.armorSprite))
        {
            var armorSprites = LoadSprites($"Addons/Legacy/0_Unit/0_Sprite/5_Armor/{preset.armorSprite}");
            if (armorSprites != null && armorSprites.Length > 0)
            {
                foreach (var sr in renderers)
                {
                    if (sr.gameObject.name == "BodyArmor")
                        sr.sprite = FindSubSprite(armorSprites, "Body");
                    else if (sr.gameObject.name == "25_L_Shoulder")
                        sr.sprite = FindSubSprite(armorSprites, "Left") ?? sr.sprite;
                    else if (sr.gameObject.name == "-15_R_Shoulder")
                        sr.sprite = FindSubSprite(armorSprites, "Right") ?? sr.sprite;
                }
            }
        }

        // Cloth
        if (!string.IsNullOrEmpty(preset.clothSprite))
        {
            var clothSprites = LoadSprites($"Addons/Legacy/0_Unit/0_Sprite/2_Cloth/{preset.clothSprite}");
            if (clothSprites != null && clothSprites.Length > 0)
            {
                foreach (var sr in renderers)
                {
                    if (sr.gameObject.name == "ClothBody")
                        sr.sprite = FindSubSprite(clothSprites, "Body");
                    else if (sr.gameObject.name == "_2L_Cloth" || sr.gameObject.name == "_11R_Cloth")
                        sr.sprite = clothSprites[0];
                }
            }
        }

        // Back
        if (!string.IsNullOrEmpty(preset.backSprite))
        {
            var backSprite = Resources.Load<Sprite>($"Addons/Legacy/0_Unit/0_Sprite/7_Back/{preset.backSprite}");
            if (backSprite != null)
            {
                foreach (var sr in renderers)
                {
                    if (sr.gameObject.name == "Back" && sr.transform.parent.name == "P_Back")
                    { sr.sprite = backSprite; break; }
                }
            }
        }
    }

    void AssignBodyPart(SpriteRenderer sr, Sprite[] bodySprites, string partName, Color color)
    {
        var sprite = FindSubSprite(bodySprites, partName);
        if (sprite != null) sr.sprite = sprite;
        sr.color = color;
    }

    void ApplySimplePart(SpriteRenderer[] renderers, string spriteName, string folder, string targetRendererName, Color color)
    {
        if (string.IsNullOrEmpty(spriteName)) return;
        var sprites = LoadSprites($"Addons/Legacy/0_Unit/0_Sprite/{folder}/{spriteName}");
        if (sprites == null || sprites.Length == 0) return;
        foreach (var sr in renderers)
        {
            if (sr.gameObject.name == targetRendererName)
            { sr.sprite = sprites[0]; sr.color = color; break; }
        }
    }

    public static Sprite[] LoadSprites(string path)
    {
        if (spriteCache.TryGetValue(path, out var cached))
            return cached;
        var loaded = Resources.LoadAll<Sprite>(path);
        spriteCache[path] = loaded;
        return loaded;
    }

    public static Sprite FindSubSprite(Sprite[] sprites, string subName)
    {
        for (int i = 0; i < sprites.Length; i++)
            if (sprites[i].name == subName) return sprites[i];
        return sprites.Length > 0 ? sprites[0] : null;
    }

    static void DisableShadows(Transform root)
    {
        for (int i = 0; i < root.childCount; i++)
        {
            var child = root.GetChild(i);
            if (child.name == "Shadow") child.gameObject.SetActive(false);
            else DisableShadows(child);
        }
    }

    static readonly string[] WeaponFolders = {
        "Addons/Legacy/0_Unit/0_Sprite/6_Weapons/0_Sword",
        "Addons/Legacy/0_Unit/0_Sprite/6_Weapons/1_Axe",
        "Addons/Legacy/0_Unit/0_Sprite/6_Weapons/2_Bow",
        "Addons/Legacy/0_Unit/0_Sprite/6_Weapons/3_Shield",
        "Addons/Legacy/0_Unit/0_Sprite/6_Weapons/4_Spear",
        "Addons/Legacy/0_Unit/0_Sprite/6_Weapons/5_Wand",
        "Addons/Legacy/0_Unit/0_Sprite/6_Weapons/6_Hammer",
    };

    public static Sprite FindWeaponSprite(string weaponName)
    {
        for (int i = 0; i < WeaponFolders.Length; i++)
        {
            var sprite = Resources.Load<Sprite>($"{WeaponFolders[i]}/{weaponName}");
            if (sprite != null) return sprite;
        }
        return null;
    }
}
