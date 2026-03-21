using UnityEngine;
using System.Collections.Generic;

public class BattleBackground : MonoBehaviour
{
    static readonly string[] AreaBackgrounds = {
        "Backgrounds/bg_grass_field",  // Grass
        "Backgrounds/bg_medieval",     // Desert
        "Backgrounds/bg_dungeon",      // Cave
        "Backgrounds/bg_dungeon",      // Volcano (임시: 던전 배경 재활용)
        "Backgrounds/bg_dungeon"       // Abyss (임시: 던전 배경 재활용)
    };

    // 에리어별 색조 (배경 tint)
    static readonly Color[] AreaTintColors = {
        Color.white,                              // Grass - 자연색
        new Color(1f, 0.9f, 0.7f),                // Desert - 따뜻한 모래색
        new Color(0.7f, 0.75f, 0.85f),            // Cave - 차가운 푸른빛
        new Color(1f, 0.55f, 0.35f),              // Volcano - 붉은 용암빛
        new Color(0.6f, 0.4f, 0.8f)               // Abyss - 짙은 보라빛
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
            int tintIdx = Mathf.Clamp(area - 1, 0, AreaTintColors.Length - 1);
            sr.color = AreaTintColors[tintIdx];
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
