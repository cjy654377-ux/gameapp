using UnityEngine;

public class GoldDrop : MonoBehaviour
{
    private int goldAmount;
    private SpriteRenderer sr;
    private float lifetime;
    private Vector3 velocity;
    private bool collected;
    private float groundY;

    static Sprite coinSprite;
    const string POOL_NAME = "GoldDrop";

    // Coin sprite 설정
    const int COIN_TEXTURE_SIZE = 4;
    const float COIN_PPU = 8f;
    const float COIN_PIVOT = 0.5f;

    // 위치/크기
    const float SPAWN_SCALE = 0.5f;
    const float GROUND_OFFSET = 0.5f;
    const int SORTING_ORDER = 80;

    // 애니메이션
    const float SPAWN_VEL_X_MIN = -1f;
    const float SPAWN_VEL_X_MAX = 1f;
    const float SPAWN_VEL_Y_MIN = 2f;
    const float SPAWN_VEL_Y_MAX = 3f;
    const float INITIAL_LIFETIME = 5f;
    const float GRAVITY = 5f;
    const float BOB_FREQ = 3f;
    const float BOB_AMOUNT = 0.05f;
    const float BOB_SPEED_MULT = 5f;
    const float BLINK_THRESHOLD = 1.5f;
    const float BLINK_FREQ = 6f;
    const float COLLIDER_SIZE = 1f;
    const float POPUP_HEIGHT = 0.3f;

    public static void Spawn(Vector3 position, int amount)
    {
        if (coinSprite == null)
        {
            var tex = new Texture2D(COIN_TEXTURE_SIZE, COIN_TEXTURE_SIZE);
            for (int x = 0; x < COIN_TEXTURE_SIZE; x++)
                for (int y = 0; y < COIN_TEXTURE_SIZE; y++)
                    tex.SetPixel(x, y, (x + y) % 2 == 0 ? new Color(1f, 0.85f, 0.2f) : new Color(0.9f, 0.7f, 0.1f));
            tex.Apply();
            tex.filterMode = FilterMode.Point;
            coinSprite = Sprite.Create(tex, new Rect(0, 0, COIN_TEXTURE_SIZE, COIN_TEXTURE_SIZE), new Vector2(COIN_PIVOT, COIN_PIVOT), COIN_PPU);
        }

        var pool = ObjectPool.Instance;
        var go = pool != null
            ? pool.Get(POOL_NAME, CreateNewGoldDrop)
            : CreateNewGoldDrop();

        go.transform.position = position;
        go.transform.localScale = new Vector3(SPAWN_SCALE, SPAWN_SCALE, 1f);

        var drop = go.GetComponent<GoldDrop>();
        drop.goldAmount = amount;
        drop.groundY = position.y - GROUND_OFFSET;
        drop.collected = false;
        drop.sr.sprite = coinSprite;
        drop.sr.color = new Color(1f, 0.85f, 0.2f);
        drop.sr.enabled = true;
        drop.sr.sortingOrder = SORTING_ORDER;

        // Pop up effect
        drop.velocity = new Vector3(Random.Range(SPAWN_VEL_X_MIN, SPAWN_VEL_X_MAX), Random.Range(SPAWN_VEL_Y_MIN, SPAWN_VEL_Y_MAX), 0);
        drop.lifetime = INITIAL_LIFETIME;
    }

    static GameObject CreateNewGoldDrop()
    {
        var go = new GameObject("GoldDrop");
        var sr = go.AddComponent<SpriteRenderer>();
        go.AddComponent<GoldDrop>();
        var col = go.AddComponent<BoxCollider2D>();
        col.size = new Vector2(COLLIDER_SIZE, COLLIDER_SIZE);
        return go;
    }

    void Awake()
    {
        sr = GetComponent<SpriteRenderer>();
        if (sr == null) sr = gameObject.AddComponent<SpriteRenderer>();
    }

    void Update()
    {
        if (collected) return;

        // Apply gravity
        velocity.y -= GRAVITY * Time.deltaTime;
        transform.position += velocity * Time.deltaTime;

        // Stop at ground level (relative to spawn position)
        if (transform.position.y < groundY)
        {
            var pos = transform.position;
            pos.y = groundY;
            transform.position = pos;
            velocity = Vector3.zero;
        }

        // Bobbing animation when on ground
        if (velocity.sqrMagnitude < 0.01f)
        {
            float bob = Mathf.Sin(Time.time * BOB_FREQ) * BOB_AMOUNT;
            transform.position += new Vector3(0, bob * Time.deltaTime * BOB_SPEED_MULT, 0);
        }

        lifetime -= Time.deltaTime;

        // Blink when about to expire
        if (lifetime < BLINK_THRESHOLD)
        {
            sr.enabled = Mathf.FloorToInt(lifetime * BLINK_FREQ) % 2 == 0;
        }

        // Auto-collect when expired
        if (lifetime <= 0f)
            Collect();
    }

    void OnEnable()
    {
        // 풀에서 꺼낼 때 상태 초기화
        collected = false;
    }

    void OnMouseDown()
    {
        Collect();
    }

    public void Collect()
    {
        if (collected) return;
        collected = true;

        if (GoldManager.Instance != null)
            GoldManager.Instance.AddGold(goldAmount);

        SoundManager.Instance?.PlayGoldSFX();
        DamagePopup.CreateGold(transform.position + Vector3.up * POPUP_HEIGHT, goldAmount);
        StartCoroutine(FlyToHUD());
    }

    System.Collections.IEnumerator FlyToHUD()
    {
        float duration = 0.35f;
        float elapsed = 0f;
        Vector3 startPos = transform.position;
        Vector3 startScale = transform.localScale;

        // HUD 골드 위치: 화면 좌상단 근처 (WorldToScreenPoint 역산)
        var cam = Camera.main;
        Vector3 hudScreenPos = new Vector3(Screen.width * 0.12f, Screen.height * 0.92f, 10f);
        Vector3 endPos = cam != null ? cam.ScreenToWorldPoint(hudScreenPos) : startPos + Vector3.up * 3f;

        while (elapsed < duration)
        {
            elapsed += Time.unscaledDeltaTime;
            float t = Mathf.SmoothStep(0f, 1f, elapsed / duration);
            transform.position = Vector3.Lerp(startPos, endPos, t);
            transform.localScale = Vector3.Lerp(startScale, startScale * 0.05f, t);
            yield return null;
        }
        ReturnToPool();
    }

    void ReturnToPool()
    {
        var pool = ObjectPool.Instance;
        if (pool != null)
        {
            sr.sprite = null;
            gameObject.SetActive(false);
            pool.Return(POOL_NAME, gameObject);
        }
        else
        {
            Destroy(gameObject);
        }
    }

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
    static void CleanupStatic()
    {
        if (coinSprite != null)
        {
            var tex = coinSprite.texture;
            Destroy(coinSprite);
            coinSprite = null;
            if (tex != null) Destroy(tex);
        }
    }
}
