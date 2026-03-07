using UnityEngine;
using System.Collections.Generic;

public class BattleBackground : MonoBehaviour
{
    private Sprite bgSprite;
    private float tileWidth;
    private float scale;
    private readonly List<SpriteRenderer> tiles = new();

    void Awake()
    {
        bgSprite = Resources.Load<Sprite>("Backgrounds/bg_grass_field");
        if (bgSprite == null)
        {
            var tex = Resources.Load<Texture2D>("Backgrounds/bg_grass_field");
            if (tex != null)
            {
                tex.filterMode = FilterMode.Point;
                bgSprite = Sprite.Create(tex, new Rect(0, 0, tex.width, tex.height), new Vector2(0.5f, 0.5f), 100f);
            }
        }

        if (bgSprite == null) return;
        bgSprite.texture.filterMode = FilterMode.Point;

        var cam = Camera.main;
        if (cam == null) return;

        float camH = cam.orthographicSize * 2f;
        scale = camH / bgSprite.bounds.size.y;
        tileWidth = bgSprite.bounds.size.x * scale;

        // Create enough tiles to cover screen + buffer
        float camW = camH * cam.aspect;
        int tileCount = Mathf.CeilToInt(camW / tileWidth) + 3;

        for (int i = 0; i < tileCount; i++)
        {
            var tileObj = new GameObject($"BgTile_{i}");
            tileObj.transform.SetParent(transform, false);
            var sr = tileObj.AddComponent<SpriteRenderer>();
            sr.sprite = bgSprite;
            sr.sortingOrder = -100;
            tileObj.transform.localScale = Vector3.one * scale;
            tiles.Add(sr);
        }
    }

    void LateUpdate()
    {
        if (tiles.Count == 0 || tileWidth <= 0) return;

        var cam = Camera.main;
        if (cam == null) return;

        float camX = cam.transform.position.x;
        float startX = Mathf.Floor(camX / tileWidth) * tileWidth - tileWidth;

        for (int i = 0; i < tiles.Count; i++)
        {
            tiles[i].transform.position = new Vector3(startX + i * tileWidth, 0, 0);
        }
    }
}
