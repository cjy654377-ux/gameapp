using UnityEngine;

public class Projectile : MonoBehaviour
{
    private BattleUnit target;
    private float damage;
    private float speed;
    private SpriteRenderer sr;
    private ProjectileType projType;

    static Sprite fallbackSprite;

    // Hit VFX prefab paths (Cartoon FX Remaster)
    const string HIT_RED = "VFX/CFXR Hit A (Red)";
    const string HIT_BLUE = "VFX/CFXR3 Hit Ice B (Air)";

    public static void Spawn(Vector3 from, BattleUnit target, float damage, ProjectileType type)
    {
        EnsureFallbackSprite();

        var go = new GameObject("Projectile");
        go.transform.position = from;
        var proj = go.AddComponent<Projectile>();
        proj.target = target;
        proj.damage = damage;
        proj.projType = type;
        proj.speed = type == ProjectileType.Arrow ? 12f : 8f;

        proj.sr = go.AddComponent<SpriteRenderer>();
        proj.sr.sortingOrder = 50;
        proj.sr.sprite = fallbackSprite;

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

        Destroy(go, 3f);
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

    void Update()
    {
        if (target == null || target.IsDead)
        {
            Destroy(gameObject);
            return;
        }

        Vector3 dir = target.transform.position - transform.position;
        float dist = dir.magnitude;

        if (dist < 0.2f)
        {
            target.TakeDamage(damage);
            SpawnHitVFX();
            Destroy(gameObject);
            return;
        }

        transform.position += dir.normalized * speed * Time.deltaTime;

        float angle = Mathf.Atan2(dir.y, dir.x) * Mathf.Rad2Deg;
        transform.rotation = Quaternion.Euler(0, 0, angle);
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
    }

    void SpawnHitVFX()
    {
        string prefabPath = projType == ProjectileType.Arrow ? HIT_RED : HIT_BLUE;
        var prefab = Resources.Load<GameObject>(prefabPath);

        if (prefab != null)
        {
            var vfx = Instantiate(prefab, transform.position, Quaternion.identity);
            vfx.transform.localScale = Vector3.one * 0.5f;
            Destroy(vfx, 1.5f);
        }
    }
}

public enum ProjectileType
{
    Arrow,
    MagicBolt
}
