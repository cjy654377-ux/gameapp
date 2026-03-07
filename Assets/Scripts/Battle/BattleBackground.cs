using UnityEngine;

public class BattleBackground : MonoBehaviour
{
    void Awake()
    {
        var sprite = Resources.Load<Sprite>("Backgrounds/bg_grass_field");
        if (sprite == null)
        {
            var tex = Resources.Load<Texture2D>("Backgrounds/bg_grass_field");
            if (tex != null)
            {
                tex.filterMode = FilterMode.Point;
                sprite = Sprite.Create(tex, new Rect(0, 0, tex.width, tex.height), new Vector2(0.5f, 0.5f), 100f);
            }
        }

        if (sprite == null) return;

        sprite.texture.filterMode = FilterMode.Point;

        var sr = GetComponent<SpriteRenderer>();
        if (sr == null) sr = gameObject.AddComponent<SpriteRenderer>();
        sr.sprite = sprite;
        sr.sortingOrder = -100;
        transform.position = new Vector3(0, 0, 0f);

        var cam = Camera.main;
        if (cam == null) return;

        float camH = cam.orthographicSize * 2f;
        float camW = camH * cam.aspect;
        float scale = Mathf.Max(camW / sprite.bounds.size.x, camH / sprite.bounds.size.y);
        transform.localScale = Vector3.one * scale;
    }
}
