using UnityEngine;
using System.Collections.Generic;

public class CharacterFactory : MonoBehaviour
{
    public static CharacterFactory Instance { get; private set; }

    [Header("Base Prefab")]
    public GameObject spumBasePrefab;

    static readonly Dictionary<string, Sprite[]> spriteCache = new();

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
            spriteCache.Clear();
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

        var unitObj = new GameObject(preset.characterName);
        unitObj.transform.position = position;

        // SPUM 프리팹 인스턴스화
        var spumInstance = Instantiate(spumBasePrefab);

        // 탈것 스프라이트 결정 (아군: MountManager, 적: preset)
        string horseSprite = preset.horseSprite;
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

        // 스프라이트 적용
        ApplySprites(unitObj, preset);

        // BattleUnit 설정
        var battleUnit = unitObj.AddComponent<BattleUnit>();
        battleUnit.unitName = preset.characterName;
        battleUnit.maxHp = preset.maxHp;
        battleUnit.atk = preset.atk;
        battleUnit.def = preset.def;
        battleUnit.moveSpeed = preset.moveSpeed;
        battleUnit.attackRange = preset.attackRange;
        battleUnit.attackCooldown = preset.attackCooldown;
        battleUnit.damageElement = preset.damageElement;
        battleUnit.lightningResist = preset.lightningResist;
        battleUnit.poisonResist = preset.poisonResist;

        if (preset.isHealer)
        {
            battleUnit.role = BattleUnit.RoleType.Healer;
            battleUnit.healAmount = preset.healAmount;
            battleUnit.healCooldown = preset.healCooldown;
            battleUnit.healRange = preset.healRange;
        }
        else if (preset.isBuffer)
        {
            battleUnit.role = BattleUnit.RoleType.Buffer;
            battleUnit.buffAtkBonus = preset.buffAtkBonus;
            battleUnit.buffDefBonus = preset.buffDefBonus;
            battleUnit.buffDuration = preset.buffDuration;
            battleUnit.buffCooldown = preset.buffCooldown;
            battleUnit.buffRange = preset.buffRange;
        }

        if (preset.skills != null && preset.skills.Length > 0)
            battleUnit.skills = preset.skills;

        battleUnit.Init(preset.attackAnimType);
        battleUnit.SetTeam(team);

        // 성급 기반 크기 (적만)
        float baseScale = 0.8f;
        unitObj.transform.localScale = Vector3.one * baseScale;

        unitObj.AddComponent<HpBar>();

        // 도감 등록
        CollectionManager.Instance?.RegisterHero(
            team == BattleUnit.Team.Ally ? preset.characterName : null);
        if (team == BattleUnit.Team.Enemy)
            CollectionManager.Instance?.RegisterMonster(preset.characterName);

        // 적 골드 드롭
        if (team == BattleUnit.Team.Enemy)
        {
            var unitRef = battleUnit;
            int goldReward = Mathf.RoundToInt(preset.maxHp * 0.5f);
            System.Action deathHandler = null;
            deathHandler = () =>
            {
                GoldDrop.Spawn(unitRef.transform.position, goldReward);
                unitRef.OnDeath -= deathHandler;
            };
            battleUnit.OnDeath += deathHandler;
        }

        return battleUnit;
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

    void ApplyHorseSprites(Transform horseRoot, string horseName)
    {
        var horseSprites = LoadSprites($"Addons/Legacy/1_Horse/0_Sprite/0_Body/{horseName}");
        if (horseSprites == null || horseSprites.Length == 0) return;

        var spriteLookup = new Dictionary<string, Sprite>();
        foreach (var s in horseSprites)
            spriteLookup[s.name] = s;

        var nameMap = new Dictionary<string, string>
        {
            { "Head", "Head" }, { "Neck", "Neck" },
            { "BodyFront", "BodyFront" }, { "BodyBack", "BodyBack" },
            { "Tail", "Tail" }, { "Acc", "Acc" },
        };

        var horseSRs = horseRoot.GetComponentsInChildren<SpriteRenderer>(true);
        foreach (var sr in horseSRs)
        {
            string goName = sr.gameObject.name;
            if (nameMap.TryGetValue(goName, out string spriteName))
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

    static Sprite[] LoadSprites(string path)
    {
        if (spriteCache.TryGetValue(path, out var cached))
            return cached;
        var loaded = Resources.LoadAll<Sprite>(path);
        spriteCache[path] = loaded;
        return loaded;
    }

    Sprite FindSubSprite(Sprite[] sprites, string subName)
    {
        for (int i = 0; i < sprites.Length; i++)
            if (sprites[i].name == subName) return sprites[i];
        return sprites.Length > 0 ? sprites[0] : null;
    }

    Sprite FindWeaponSprite(string weaponName)
    {
        string[] folders = {
            "Addons/Legacy/0_Unit/0_Sprite/6_Weapons/0_Sword",
            "Addons/Legacy/0_Unit/0_Sprite/6_Weapons/1_Axe",
            "Addons/Legacy/0_Unit/0_Sprite/6_Weapons/2_Bow",
            "Addons/Legacy/0_Unit/0_Sprite/6_Weapons/3_Shield",
            "Addons/Legacy/0_Unit/0_Sprite/6_Weapons/4_Spear",
            "Addons/Legacy/0_Unit/0_Sprite/6_Weapons/5_Wand",
            "Addons/Legacy/0_Unit/0_Sprite/6_Weapons/6_Hammer",
        };
        foreach (var folder in folders)
        {
            var sprite = Resources.Load<Sprite>($"{folder}/{weaponName}");
            if (sprite != null) return sprite;
        }
        return null;
    }
}
