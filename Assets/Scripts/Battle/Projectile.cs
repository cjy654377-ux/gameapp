using UnityEngine;
using System.Collections.Generic;

public class Projectile : MonoBehaviour
{
    private BattleUnit target;
    private float damage;
    private float speed;
    private SpriteRenderer sr;
    private ProjectileType projType;
    private float lifeTimer;

    static Sprite fallbackSprite;

    const string POOL_NAME = "Projectile";
    const string VFX_POOL_PREFIX = "HitVFX_";
    const float MAX_LIFETIME = 3f;

    // Hit VFX prefab paths (Cartoon FX Remaster)
    const string HIT_RED = "VFX/CFXR Hit A (Red)";
    const string HIT_BLUE = "VFX/CFXR3 Hit Ice B (Air)";

    // Projectile constants
    const float ARROW_SPEED     = 12f;
    const float BOLT_SPEED      = 8f;
    const float HIT_DISTANCE    = 0.3f;
    const float VFX_SCALE       = 0.5f;
    const float VFX_LIFETIME    = 1.5f;
    const int   SPRITE_SORT_ORDER = 50;

    public static void Spawn(Vector3 from, BattleUnit target, float damage, ProjectileType type)
    {
        if (target == null || target.IsDead) return;

        EnsureFallbackSprite();

        var pool = ObjectPool.Instance;
        var go = pool != null
            ? pool.Get(POOL_NAME, CreateNewProjectile)
            : CreateNewProjectile();

        go.transform.position = from;
        var proj = go.GetComponent<Projectile>();
        proj.target = target;
        proj.damage = damage;
        proj.projType = type;
        proj.speed = type == ProjectileType.Arrow ? ARROW_SPEED : BOLT_SPEED;
        proj.lifeTimer = MAX_LIFETIME;

        proj.sr.sprite = fallbackSprite;
        proj.sr.sortingOrder = SPRITE_SORT_ORDER;

        if (type == ProjectileType.Arrow)
        {
            proj.sr.color = new Color(0.8f, 0.6f, 0.3f);
            go.transform.localScale = new Vector3(0.3f, 0.1f, 1f);
        }
        else
        {
            proj.sr.color = new Color(0.4f, 0.6f, 1f);
            go.transform.localScale = new Vector3(0.25f, 0.25f, 1f);
        }

        // Rotate towards target
        Vector3 dir = target.transform.position - from;
        float angle = Mathf.Atan2(dir.y, dir.x) * Mathf.Rad2Deg;
        go.transform.rotation = Quaternion.Euler(0, 0, angle);
    }

    static GameObject CreateNewProjectile()
    {
        var go = new GameObject("Projectile");
        var sr = go.AddComponent<SpriteRenderer>();
        go.AddComponent<Projectile>();
        return go;
    }

    static void EnsureFallbackSprite()
    {
        if (fallbackSprite != null) return;
        var tex = new Texture2D(4, 4);
        for (int x = 0; x < 4; x++)
            for (int y = 0; y < 4; y++)
                tex.SetPixel(x, y, Color.white);
        tex.Apply();
        tex.filterMode = FilterMode.Point;
        fallbackSprite = Sprite.Create(tex, new Rect(0, 0, 4, 4), new Vector2(0.5f, 0.5f), 4f);
    }

    void Awake()
    {
        sr = GetComponent<SpriteRenderer>();
        if (sr == null) sr = gameObject.AddComponent<SpriteRenderer>();
    }

    void OnEnable()
    {
        // 풀에서 재활성화 시 상태 리셋
        lifeTimer = MAX_LIFETIME;
        target = null;
        damage = 0f;
        speed = 0f;
        projType = ProjectileType.Arrow;
        if (sr != null)
        {
            sr.sprite = null;
            sr.color = Color.white;
        }
        transform.rotation = Quaternion.identity;
        transform.localScale = Vector3.one;
    }

    void OnDisable()
    {
        // 비활성화 시 참조 정리
        target = null;
        if (sr != null) sr.sprite = null;
    }

    void Update()
    {
        lifeTimer -= Time.deltaTime;
        if (lifeTimer <= 0f)
        {
            ReturnToPool();
            return;
        }

        if (target == null || target.IsDead)
        {
            ReturnToPool();
            return;
        }

        Vector3 dir = target.transform.position - transform.position;
        float dist = dir.magnitude;

        if (dist < HIT_DISTANCE)
        {
            target.TakeDamage(damage);
            SpawnHitVFX();
            ReturnToPool();
            return;
        }

        transform.position += dir.normalized * speed * Time.deltaTime;

        float angle = Mathf.Atan2(dir.y, dir.x) * Mathf.Rad2Deg;
        transform.rotation = Quaternion.Euler(0, 0, angle);
    }

    void ReturnToPool()
    {
        if (!gameObject.activeSelf) return; // 이미 풀에 반환됨

        var pool = ObjectPool.Instance;
        if (pool != null)
        {
            pool.Return(POOL_NAME, gameObject); // Return()이 SetActive(false) 처리 → OnDisable에서 정리
        }
        else
        {
            Destroy(gameObject);
        }
    }

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
    static void ResetStatics()
    {
        if (fallbackSprite != null)
        {
            var tex = fallbackSprite.texture;
            Destroy(fallbackSprite);
            if (tex != null) Destroy(tex);
            fallbackSprite = null;
        }
        hitVfxCache.Clear();
    }

    static readonly Dictionary<string, GameObject> hitVfxCache = new();

    void SpawnHitVFX()
    {
        string prefabPath = projType == ProjectileType.Arrow ? HIT_RED : HIT_BLUE;
        if (!hitVfxCache.TryGetValue(prefabPath, out var prefab))
        {
            prefab = Resources.Load<GameObject>(prefabPath);
            hitVfxCache[prefabPath] = prefab;
        }

        if (prefab == null) return;

        string vfxPoolName = VFX_POOL_PREFIX + prefabPath;
        var pool = ObjectPool.Instance;
        GameObject vfx;

        if (pool != null)
        {
            vfx = pool.Get(vfxPoolName, () => Instantiate(prefab));
            vfx.transform.position = transform.position;
            vfx.transform.rotation = Quaternion.identity;
            vfx.transform.localScale = Vector3.one * VFX_SCALE;
            // 파티클 재시작
            var ps = vfx.GetComponent<ParticleSystem>();
            if (ps != null)
            {
                ps.Clear();
                ps.Play();
            }
            // 코루틴을 ObjectPool(영속 싱글톤)에서 실행 — Projectile은 풀 반환 시 비활성화됨
            pool.StartCoroutine(ReturnVFXAfterDelay(vfxPoolName, vfx, VFX_LIFETIME));
        }
        else
        {
            vfx = Instantiate(prefab, transform.position, Quaternion.identity);
            vfx.transform.localScale = Vector3.one * VFX_SCALE;
            Destroy(vfx, VFX_LIFETIME);
        }
    }

    System.Collections.IEnumerator ReturnVFXAfterDelay(string poolName, GameObject vfx, float delay)
    {
        yield return new WaitForSeconds(delay);
        if (vfx == null) yield break;
        var pool = ObjectPool.Instance;
        if (pool != null)
            pool.Return(poolName, vfx);
        else if (vfx != null)
            Destroy(vfx);
    }
}

public enum ProjectileType
{
    Arrow,
    MagicBolt
}
