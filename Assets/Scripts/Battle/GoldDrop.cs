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

    public static void Spawn(Vector3 position, int amount)
    {
        if (coinSprite == null)
        {
            var tex = new Texture2D(4, 4);
            for (int x = 0; x < 4; x++)
                for (int y = 0; y < 4; y++)
                    tex.SetPixel(x, y, (x + y) % 2 == 0 ? new Color(1f, 0.85f, 0.2f) : new Color(0.9f, 0.7f, 0.1f));
            tex.Apply();
            tex.filterMode = FilterMode.Point;
            coinSprite = Sprite.Create(tex, new Rect(0, 0, 4, 4), new Vector2(0.5f, 0.5f), 8f);
        }

        var go = new GameObject("GoldDrop");
        go.transform.position = position;
        go.transform.localScale = new Vector3(0.5f, 0.5f, 1f);

        var drop = go.AddComponent<GoldDrop>();
        drop.goldAmount = amount;
        drop.groundY = position.y - 0.5f;

        drop.sr = go.AddComponent<SpriteRenderer>();
        drop.sr.sprite = coinSprite;
        drop.sr.color = new Color(1f, 0.85f, 0.2f);
        drop.sr.sortingOrder = 80;

        // Add collider for click detection
        var col = go.AddComponent<BoxCollider2D>();
        col.size = new Vector2(1f, 1f);

        // Pop up effect
        drop.velocity = new Vector3(Random.Range(-1f, 1f), Random.Range(2f, 3f), 0);
        drop.lifetime = 5f;

        Destroy(go, 6f);
    }

    void Update()
    {
        if (collected) return;

        // Apply gravity
        velocity.y -= 5f * Time.deltaTime;
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
            float bob = Mathf.Sin(Time.time * 3f) * 0.05f;
            transform.position += new Vector3(0, bob * Time.deltaTime * 5f, 0);
        }

        lifetime -= Time.deltaTime;

        // Blink when about to expire
        if (lifetime < 1.5f)
        {
            sr.enabled = Mathf.FloorToInt(lifetime * 6f) % 2 == 0;
        }

        // Auto-collect when expired
        if (lifetime <= 0f)
            Collect();
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

        DamagePopup.CreateGold(transform.position + Vector3.up * 0.3f, goldAmount);
        Destroy(gameObject);
    }
}
