using UnityEngine;
using System.Collections.Generic;

public class BattleBackground : MonoBehaviour
{
    public static BattleBackground Instance { get; private set; }

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
    const int MID_SORTING_ORDER = -90;
    // 파랄랙스 배율: 전경(tiles) 1.0x, 중경(midTiles) 0.5x 카메라 이동 추적
    const float MID_PARALLAX = 0.5f;
    const float MID_SCALE_MULT = 0.7f;  // 중경은 약간 작게 (원근감)

    private Sprite bgSprite;
    private float tileWidth;
    private float scale;
    private readonly List<SpriteRenderer> tiles = new();
    private readonly List<SpriteRenderer> midTiles = new();
    private float midTileWidth;
    private int currentArea = -1;
    private Camera cachedCamera;
    private bool caveDarknessActive;
    private Color originalMidTint;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

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
        for (int i = 0; i < midTiles.Count; i++)
            if (midTiles[i] != null) Destroy(midTiles[i].gameObject);
        midTiles.Clear();

        var cam = cachedCamera != null ? cachedCamera : Camera.main;
        if (cam == null) return;

        float camH = cam.orthographicSize * CAM_HEIGHT_MULT;
        scale = camH / bgSprite.bounds.size.y;
        tileWidth = bgSprite.bounds.size.x * scale;

        float camW = camH * cam.aspect;
        int tileCount = Mathf.CeilToInt(camW / tileWidth) + TILE_BUFFER_COUNT;
        int tintIdx = Mathf.Clamp(area - 1, 0, AreaTintColors.Length - 1);
        Color tint = AreaTintColors[tintIdx];

        // 전경 타일 (1.0x 스크롤)
        for (int i = 0; i < tileCount; i++)
        {
            var tileObj = new GameObject($"BgTile_{i}");
            tileObj.transform.SetParent(transform, false);
            var sr = tileObj.AddComponent<SpriteRenderer>();
            sr.sprite = bgSprite;
            sr.sortingOrder = BG_SORTING_ORDER;
            sr.color = tint;
            tileObj.transform.localScale = Vector3.one * scale;
            tiles.Add(sr);
        }

        // 중경 파랄랙스 타일 (0.5x 스크롤, 약간 어둡게)
        float midScale = scale * MID_SCALE_MULT;
        midTileWidth = bgSprite.bounds.size.x * midScale;
        int midCount = Mathf.CeilToInt(camW / midTileWidth) + TILE_BUFFER_COUNT;
        Color midTint = new Color(tint.r * 0.65f, tint.g * 0.65f, tint.b * 0.7f, 1f);

        for (int i = 0; i < midCount; i++)
        {
            var midObj = new GameObject($"BgMidTile_{i}");
            midObj.transform.SetParent(transform, false);
            var sr = midObj.AddComponent<SpriteRenderer>();
            sr.sprite = bgSprite;
            sr.sortingOrder = MID_SORTING_ORDER;
            sr.color = midTint;
            midObj.transform.localScale = Vector3.one * midScale;
            midTiles.Add(sr);
        }
    }

    void LateUpdate()
    {
        if (tiles.Count == 0 || tileWidth <= 0) return;

        var cam = cachedCamera != null ? cachedCamera : Camera.main;
        if (cam == null) return;

        float camX = cam.transform.position.x;

        // 전경: 카메라 1:1 추적
        float startX = Mathf.Floor(camX / tileWidth) * tileWidth - tileWidth;
        for (int i = 0; i < tiles.Count; i++)
            tiles[i].transform.position = new Vector3(startX + i * tileWidth, 0, 0);

        // 중경: 카메라의 0.5배 속도로 스크롤 (파랄랙스)
        if (midTiles.Count > 0 && midTileWidth > 0)
        {
            float midCamX = camX * MID_PARALLAX;
            float midStartX = Mathf.Floor(midCamX / midTileWidth) * midTileWidth - midTileWidth;
            for (int i = 0; i < midTiles.Count; i++)
                midTiles[i].transform.position = new Vector3(midStartX + i * midTileWidth, 0.5f, 0);
        }
    }

    public void ApplyCaveDarkness(bool apply)
    {
        caveDarknessActive = apply;

        if (apply)
        {
            // 가장자리를 어둡게 하기 위해 중경 및 배경 밝기 감소
            for (int i = 0; i < midTiles.Count; i++)
            {
                if (midTiles[i] != null)
                {
                    Color darkColor = midTiles[i].color * 0.4f;
                    darkColor.a = 1f;
                    midTiles[i].color = darkColor;
                }
            }
            for (int i = 0; i < tiles.Count; i++)
            {
                if (tiles[i] != null)
                {
                    Color darkColor = tiles[i].color * 0.5f;
                    darkColor.a = 1f;
                    tiles[i].color = darkColor;
                }
            }
        }
        else
        {
            // 원래 색상 복원 (에리어 재설정)
            SetArea(currentArea);
        }
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
        if (StageManager.Instance != null)
            StageManager.Instance.OnAreaChanged -= SetArea;
    }
}
