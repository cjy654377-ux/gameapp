using UnityEngine;
using UnityEngine.EventSystems;

public class TapDamageSystem : MonoBehaviour
{
    public static TapDamageSystem Instance { get; private set; }

    const float BASE_TAP_DAMAGE = 5f;
    const float TAP_DAMAGE_PER_LEVEL = 3f;
    const int UPGRADE_COST_MULTIPLIER = 50;

    const int TAP_SPRITE_SIZE = 1;
    const float TAP_SPRITE_PPU = 1f;
    const float TAP_SPRITE_PIVOT = 0.5f;

    const float TAP_EFFECT_COLOR_R = 1f;
    const float TAP_EFFECT_COLOR_G = 1f;
    const float TAP_EFFECT_COLOR_B = 0.5f;
    const float TAP_EFFECT_COLOR_A = 0.8f;
    const int TAP_EFFECT_SORTING_ORDER = 95;
    public const float TAP_EFFECT_SCALE = 0.3f;

    public const float TAP_EFFECT_ANIM_DURATION = 0.3f;
    public const float TAP_EFFECT_ANIM_SCALE_ADD = 0.5f;

    public float baseTapDamage = BASE_TAP_DAMAGE;
    public int tapDamageLevel = 1;

    public float TapDamage => baseTapDamage + (tapDamageLevel - 1) * TAP_DAMAGE_PER_LEVEL;
    public int UpgradeCost => tapDamageLevel * UPGRADE_COST_MULTIPLIER;

    Camera mainCam;
    static Sprite tapSprite;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(gameObject);

        tapDamageLevel = PlayerPrefs.GetInt(SaveKeys.TapDamageLevel, 1);
    }

    void Start()
    {
        mainCam = Camera.main;

        if (tapSprite == null)
        {
            var tex = new Texture2D(TAP_SPRITE_SIZE, TAP_SPRITE_SIZE);
            tex.SetPixel(0, 0, Color.white);
            tex.Apply();
            tex.filterMode = FilterMode.Point;
            tapSprite = Sprite.Create(tex, new Rect(0, 0, TAP_SPRITE_SIZE, TAP_SPRITE_SIZE), new Vector2(TAP_SPRITE_PIVOT, TAP_SPRITE_PIVOT), TAP_SPRITE_PPU);
        }
    }

    void Update()
    {
        if (BattleManager.Instance == null ||
            BattleManager.Instance.CurrentState != BattleManager.BattleState.Fighting)
            return;

        if (Input.GetMouseButtonDown(0) && !IsPointerOverUI())
        {
            TryTapDamage();
        }
    }

    bool IsPointerOverUI()
    {
        return EventSystem.current != null && EventSystem.current.IsPointerOverGameObject();
    }

    void TryTapDamage()
    {
        if (mainCam == null) return;

        Vector2 worldPos = mainCam.ScreenToWorldPoint(Input.mousePosition);

        var enemies = BattleManager.Instance.enemyUnits;
        BattleUnit closest = null;
        float closestDist = float.MaxValue;

        for (int i = 0; i < enemies.Count; i++)
        {
            if (enemies[i] == null || enemies[i].IsDead) continue;
            float dist = Vector2.Distance(worldPos, enemies[i].transform.position);
            if (dist < closestDist)
            {
                closestDist = dist;
                closest = enemies[i];
            }
        }

        if (closest != null)
        {
            closest.TakeDamage(TapDamage);
            if (EffectManager.Instance != null)
                EffectManager.Instance.SpawnLightningEffect(closest.transform.position);
            else
                SpawnTapEffect(worldPos);
        }
    }

    void SpawnTapEffect(Vector2 pos)
    {
        var go = new GameObject("TapEffect");
        go.transform.position = pos;

        var sr = go.AddComponent<SpriteRenderer>();
        sr.sprite = tapSprite;
        sr.color = new Color(TAP_EFFECT_COLOR_R, TAP_EFFECT_COLOR_G, TAP_EFFECT_COLOR_B, TAP_EFFECT_COLOR_A);
        sr.sortingOrder = TAP_EFFECT_SORTING_ORDER;
        go.transform.localScale = Vector3.one * TAP_EFFECT_SCALE;

        var anim = go.AddComponent<TapEffectAnim>();
        anim.Init();
    }

    void OnDestroy()
    {
        if (Instance == this && tapSprite != null)
        {
            Destroy(tapSprite.texture);
            Destroy(tapSprite);
            tapSprite = null;
        }
    }

    public bool UpgradeTapDamage()
    {
        if (GoldManager.Instance == null) return false;
        if (!GoldManager.Instance.SpendGold(UpgradeCost)) return false;

        tapDamageLevel++;
        PlayerPrefs.SetInt(SaveKeys.TapDamageLevel, tapDamageLevel);
        return true;
    }
}

public class TapEffectAnim : MonoBehaviour
{
    const float ANIM_DURATION = TapDamageSystem.TAP_EFFECT_ANIM_DURATION;
    const float SCALE_ADD = TapDamageSystem.TAP_EFFECT_ANIM_SCALE_ADD;

    float timer;
    SpriteRenderer sr;

    public void Init()
    {
        sr = GetComponent<SpriteRenderer>();
        timer = ANIM_DURATION;
    }

    void Update()
    {
        timer -= Time.deltaTime;
        float t = 1f - (timer / ANIM_DURATION);
        transform.localScale = Vector3.one * (TapDamageSystem.TAP_EFFECT_SCALE + t * SCALE_ADD);
        if (sr != null)
        {
            var c = sr.color;
            c.a = 1f - t;
            sr.color = c;
        }
        if (timer <= 0f) Destroy(gameObject);
    }
}
