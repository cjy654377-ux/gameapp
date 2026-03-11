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
    }

    public BattleUnit CreateCharacter(CharacterPreset preset, Vector3 position, BattleUnit.Team team)
    {
        var unitObj = new GameObject(preset.characterName);
        unitObj.transform.position = position;

        // Instantiate saved SPUM prefab
        var spumInstance = Instantiate(spumBasePrefab);
        bool useHorse = !string.IsNullOrEmpty(preset.horseSprite);

        if (useHorse)
        {
            // Horse mount: HorseRoot contains both horse AND rider, so use it instead of UnitRoot
            var horseRoot = spumInstance.transform.Find("HorseRoot");
            if (horseRoot != null)
            {
                horseRoot.SetParent(unitObj.transform, false);
                horseRoot.localPosition = Vector3.zero;
                horseRoot.gameObject.SetActive(true);
                // Apply horse body sprites by matching GameObject name to sub-sprite name
                var horseSprites = LoadSprites($"Addons/Legacy/1_Horse/0_Sprite/0_Body/{preset.horseSprite}");
                if (horseSprites != null && horseSprites.Length > 0)
                {
                    // Build lookup: sub-sprite name -> Sprite
                    var spriteLookup = new Dictionary<string, Sprite>();
                    foreach (var s in horseSprites)
                        spriteLookup[s.name] = s;

                    // Map GameObject names to sub-sprite names
                    var nameMap = new Dictionary<string, string>
                    {
                        { "Head", "Head" },
                        { "Neck", "Neck" },
                        { "BodyFront", "BodyFront" },
                        { "BodyBack", "BodyBack" },
                        { "Tail", "Tail" },
                        { "Acc", "Acc" },
                    };
                    var horseSRs = horseRoot.GetComponentsInChildren<SpriteRenderer>(true);
                    foreach (var sr in horseSRs)
                    {
                        string goName = sr.gameObject.name;

                        // Direct name match
                        if (nameMap.TryGetValue(goName, out string spriteName))
                        {
                            if (spriteLookup.TryGetValue(spriteName, out var sprite))
                                sr.sprite = sprite;
                        }
                        // Foot parts: FrontFootTop in prefab -> FootFrontTop/FootBackTop in sprite
                        else if (goName == "FrontFootTop")
                        {
                            // Try both front and back (assign whichever exists)
                            if (spriteLookup.TryGetValue("FootFrontTop", out var s1))
                                sr.sprite = s1;
                            else if (spriteLookup.TryGetValue("FootBackTop", out var s2))
                                sr.sprite = s2;
                        }
                        else if (goName == "FrontFootBottom")
                        {
                            if (spriteLookup.TryGetValue("FootFrontBottom", out var s1))
                                sr.sprite = s1;
                            else if (spriteLookup.TryGetValue("FootBackBottom", out var s2))
                                sr.sprite = s2;
                        }
                    }
                }
            }
        }
        else
        {
            // No horse: use UnitRoot only
            var unitRoot = spumInstance.transform.Find("UnitRoot");
            if (unitRoot != null)
            {
                unitRoot.SetParent(unitObj.transform, false);
                unitRoot.localPosition = Vector3.zero;
                unitRoot.localScale = Vector3.one;
            }
        }
        Destroy(spumInstance);

        // Apply sprites via SpriteRenderer hierarchy search
        ApplySprites(unitObj, preset);

        // Setup BattleUnit
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

        // Support role
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

        // Assign skills from preset
        if (preset.skills != null && preset.skills.Length > 0)
            battleUnit.skills = preset.skills;

        battleUnit.Init(preset.attackAnimType);
        battleUnit.SetTeam(team);

        // Portrait scale (80%)
        unitObj.transform.localScale = Vector3.one * 0.8f;

        // Add HP bar
        unitObj.AddComponent<HpBar>();

        // Enemy gold drops handled by StageManager for bosses,
        // default drop for normal enemies
        if (team == BattleUnit.Team.Enemy)
        {
            var unitRef = battleUnit;
            int goldReward = Mathf.RoundToInt(preset.maxHp * 0.5f);
            System.Action deathHandler = null;
            deathHandler = () =>
            {
                GoldDrop.Spawn(unitRef.transform.position, goldReward);
                AchievementManager.Instance?.RegisterKill();
                unitRef.OnDeath -= deathHandler;
            };
            battleUnit.OnDeath += deathHandler;
        }

        return battleUnit;
    }

    void ApplySprites(GameObject unitObj, CharacterPreset preset)
    {
        // Find SpriteRenderers by hierarchy path names
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
                    // Match body parts by name
                    if (srName == "Body" && sr.transform.parent.name == "P_Body")
                        AssignBodyPart(sr, bodySprites, "Body", preset.bodyColor);
                    else if (srName == "5_Head")
                        AssignBodyPart(sr, bodySprites, "Head", preset.bodyColor);
                    else if (srName == "20_L_Arm" || srName == "21_LCArm" || srName == "25_L_Shoulder")
                        AssignBodyPart(sr, bodySprites, "L_Arm", preset.bodyColor);
                    else if (srName == "-20_R_Arm" || srName == "-19_RCArm" || srName == "-15_R_Shoulder")
                        AssignBodyPart(sr, bodySprites, "R_Arm", preset.bodyColor);
                    else if (srName == "_3L_Foot")
                        AssignBodyPart(sr, bodySprites, "L_Foot", preset.bodyColor);
                    else if (srName == "_12R_Foot")
                        AssignBodyPart(sr, bodySprites, "R_Foot", preset.bodyColor);
                }
            }
        }

        // Weapon
        if (!string.IsNullOrEmpty(preset.weaponSprite))
        {
            var weaponSprite = FindWeaponSprite(preset.weaponSprite);
            if (weaponSprite != null)
            {
                foreach (var sr in renderers)
                {
                    if (sr.gameObject.name == "R_Weapon")
                    {
                        sr.sprite = weaponSprite;
                        break;
                    }
                }
            }
        }

        // Simple parts: eye, hair, helmet, armor, cloth, back
        ApplySimplePart(renderers, preset.eyeSprite, "0_Eye", "Front", preset.eyeColor);
        ApplySimplePart(renderers, preset.hairSprite, "0_Hair", "7_Hair", Color.white);
        ApplySimplePart(renderers, preset.helmetSprite, "4_Helmet", "11_Helmet1", Color.white);

        // Armor (multi-part: Body, Left, Right)
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
                    {
                        sr.sprite = backSprite;
                        break;
                    }
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
            {
                sr.sprite = sprites[0];
                sr.color = color;
                break;
            }
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
