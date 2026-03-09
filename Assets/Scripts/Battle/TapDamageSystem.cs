using UnityEngine;
using UnityEngine.EventSystems;

public class TapDamageSystem : MonoBehaviour
{
    public static TapDamageSystem Instance { get; private set; }

    public float baseTapDamage = 5f;
    public int tapDamageLevel = 1;

    public float TapDamage => baseTapDamage + (tapDamageLevel - 1) * 3f;
    public int UpgradeCost => tapDamageLevel * 50;

    Camera mainCam;
    static Sprite tapSprite;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(gameObject);

        tapDamageLevel = PlayerPrefs.GetInt("TapDamageLevel", 1);
    }

    void Start()
    {
        mainCam = Camera.main;

        if (tapSprite == null)
        {
            var tex = new Texture2D(1, 1);
            tex.SetPixel(0, 0, Color.white);
            tex.Apply();
            tex.filterMode = FilterMode.Point;
            tapSprite = Sprite.Create(tex, new Rect(0, 0, 1, 1), new Vector2(0.5f, 0.5f), 1f);
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
        float closestDist = 1.5f;

        for (int i = 0; i < enemies.Count; i++)
        {
            if (enemies[i].IsDead) continue;
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
        sr.color = new Color(1f, 1f, 0.5f, 0.8f);
        sr.sortingOrder = 95;
        go.transform.localScale = Vector3.one * 0.3f;

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
        PlayerPrefs.SetInt("TapDamageLevel", tapDamageLevel);
        return true;
    }
}

public class TapEffectAnim : MonoBehaviour
{
    float timer;
    SpriteRenderer sr;

    public void Init()
    {
        sr = GetComponent<SpriteRenderer>();
        timer = 0.3f;
    }

    void Update()
    {
        timer -= Time.deltaTime;
        float t = 1f - (timer / 0.3f);
        transform.localScale = Vector3.one * (0.3f + t * 0.5f);
        if (sr != null)
        {
            var c = sr.color;
            c.a = 1f - t;
            sr.color = c;
        }
        if (timer <= 0f) Destroy(gameObject);
    }
}
