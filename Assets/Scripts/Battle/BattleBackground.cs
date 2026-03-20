using UnityEngine;
using System.Collections.Generic;

public class BattleBackground : MonoBehaviour
{
    static readonly string[] AreaBackgrounds = {
        "Backgrounds/bg_grass_field",
        "Backgrounds/bg_medieval",    // Desert area
        "Backgrounds/bg_dungeon"      // Cave area
    };

    const int DEFAULT_AREA = 1;
    const float BG_SPRITE_PIVOT = 0.5f;
    const float BG_SPRITE_PPU = 100f;
    const float CAM_HEIGHT_MULT = 2f;
    const int TILE_BUFFER_COUNT = 3;
    const int BG_SORTING_ORDER = -100;

    private Sprite bgSprite;
    private float tileWidth;
    private float scale;
    private readonly List<SpriteRenderer> tiles = new();
    private int currentArea = -1;
    private Camera cachedCamera;

    void Awake()
    {
        cachedCamera = Camera.main;
        SetArea(DEFAULT_AREA);
    }

    void Start()
    {
        if (StageManager.Instance != null)
            StageManager.Instance.OnAreaChanged += SetArea;
    }

    public void SetArea(int area)
    {
        if (area == currentArea) return;
        currentArea = area;

        int idx = Mathf.Clamp(area - 1, 0, AreaBackgrounds.Length - 1);
        string path = AreaBackgrounds[idx];

        bgSprite = Resources.Load<Sprite>(path);
        if (bgSprite == null)
        {
            var tex = Resources.Load<Texture2D>(path);
            if (tex != null)
            {
                tex.filterMode = FilterMode.Point;
                bgSprite = Sprite.Create(tex, new Rect(0, 0, tex.width, tex.height), new Vector2(BG_SPRITE_PIVOT, BG_SPRITE_PIVOT), BG_SPRITE_PPU);
            }
        }

        if (bgSprite == null) return;
        bgSprite.texture.filterMode = FilterMode.Point;

        // Clear old tiles
        for (int i = 0; i < tiles.Count; i++)
            if (tiles[i] != null) Destroy(tiles[i].gameObject);
        tiles.Clear();

        var cam = cachedCamera != null ? cachedCamera : Camera.main;
        if (cam == null) return;

        float camH = cam.orthographicSize * CAM_HEIGHT_MULT;
        scale = camH / bgSprite.bounds.size.y;
        tileWidth = bgSprite.bounds.size.x * scale;

        float camW = camH * cam.aspect;
        int tileCount = Mathf.CeilToInt(camW / tileWidth) + TILE_BUFFER_COUNT;

        for (int i = 0; i < tileCount; i++)
        {
            var tileObj = new GameObject($"BgTile_{i}");
            tileObj.transform.SetParent(transform, false);
            var sr = tileObj.AddComponent<SpriteRenderer>();
            sr.sprite = bgSprite;
            sr.sortingOrder = BG_SORTING_ORDER;
            tileObj.transform.localScale = Vector3.one * scale;
            tiles.Add(sr);
        }
    }

    void LateUpdate()
    {
        if (tiles.Count == 0 || tileWidth <= 0) return;

        var cam = cachedCamera != null ? cachedCamera : Camera.main;
        if (cam == null) return;

        float camX = cam.transform.position.x;
        float startX = Mathf.Floor(camX / tileWidth) * tileWidth - tileWidth;

        for (int i = 0; i < tiles.Count; i++)
            tiles[i].transform.position = new Vector3(startX + i * tileWidth, 0, 0);
    }

    void OnDestroy()
    {
        if (StageManager.Instance != null)
            StageManager.Instance.OnAreaChanged -= SetArea;
    }
}
