using UnityEngine;
using System.Collections.Generic;

public enum DamageNumberStyle
{
    Damage,  // Pink-red gradient (default damage)
    Heal,    // Green gradient
    Gold,    // Gold/yellow gradient
    Critical // Orange-red, bigger
}

public static class PixelNumberFont
{
    static readonly Dictionary<string, Sprite> spriteCache = new();
    const int MAX_CACHE_SIZE = 128;

    // 7x9 bold pixel font patterns for 0-9, + and -
    // Designed to be chunky and wide like MapleStory damage numbers
    static readonly byte[][] patterns = {
        // 0
        new byte[] {
            0,1,1,1,1,1,0,
            1,1,1,1,1,1,1,
            1,1,0,0,0,1,1,
            1,1,0,0,0,1,1,
            1,1,0,0,0,1,1,
            1,1,0,0,0,1,1,
            1,1,0,0,0,1,1,
            1,1,1,1,1,1,1,
            0,1,1,1,1,1,0
        },
        // 1
        new byte[] {
            0,0,0,1,1,0,0,
            0,0,1,1,1,0,0,
            0,1,1,1,1,0,0,
            0,0,0,1,1,0,0,
            0,0,0,1,1,0,0,
            0,0,0,1,1,0,0,
            0,0,0,1,1,0,0,
            1,1,1,1,1,1,1,
            1,1,1,1,1,1,1
        },
        // 2
        new byte[] {
            0,1,1,1,1,1,0,
            1,1,1,1,1,1,1,
            1,1,0,0,0,1,1,
            0,0,0,0,1,1,1,
            0,0,1,1,1,1,0,
            0,1,1,1,0,0,0,
            1,1,1,0,0,0,0,
            1,1,1,1,1,1,1,
            1,1,1,1,1,1,1
        },
        // 3
        new byte[] {
            0,1,1,1,1,1,0,
            1,1,1,1,1,1,1,
            0,0,0,0,0,1,1,
            0,0,1,1,1,1,0,
            0,0,1,1,1,1,0,
            0,0,0,0,0,1,1,
            0,0,0,0,0,1,1,
            1,1,1,1,1,1,1,
            0,1,1,1,1,1,0
        },
        // 4
        new byte[] {
            1,1,0,0,0,1,1,
            1,1,0,0,0,1,1,
            1,1,0,0,0,1,1,
            1,1,0,0,0,1,1,
            1,1,1,1,1,1,1,
            1,1,1,1,1,1,1,
            0,0,0,0,0,1,1,
            0,0,0,0,0,1,1,
            0,0,0,0,0,1,1
        },
        // 5
        new byte[] {
            1,1,1,1,1,1,1,
            1,1,1,1,1,1,1,
            1,1,0,0,0,0,0,
            1,1,1,1,1,1,0,
            1,1,1,1,1,1,1,
            0,0,0,0,0,1,1,
            0,0,0,0,0,1,1,
            1,1,1,1,1,1,1,
            0,1,1,1,1,1,0
        },
        // 6
        new byte[] {
            0,1,1,1,1,1,0,
            1,1,1,1,1,1,1,
            1,1,0,0,0,0,0,
            1,1,1,1,1,1,0,
            1,1,1,1,1,1,1,
            1,1,0,0,0,1,1,
            1,1,0,0,0,1,1,
            1,1,1,1,1,1,1,
            0,1,1,1,1,1,0
        },
        // 7
        new byte[] {
            1,1,1,1,1,1,1,
            1,1,1,1,1,1,1,
            0,0,0,0,0,1,1,
            0,0,0,0,1,1,0,
            0,0,0,1,1,0,0,
            0,0,0,1,1,0,0,
            0,0,0,1,1,0,0,
            0,0,0,1,1,0,0,
            0,0,0,1,1,0,0
        },
        // 8
        new byte[] {
            0,1,1,1,1,1,0,
            1,1,1,1,1,1,1,
            1,1,0,0,0,1,1,
            0,1,1,1,1,1,0,
            0,1,1,1,1,1,0,
            1,1,0,0,0,1,1,
            1,1,0,0,0,1,1,
            1,1,1,1,1,1,1,
            0,1,1,1,1,1,0
        },
        // 9
        new byte[] {
            0,1,1,1,1,1,0,
            1,1,1,1,1,1,1,
            1,1,0,0,0,1,1,
            1,1,0,0,0,1,1,
            1,1,1,1,1,1,1,
            0,1,1,1,1,1,1,
            0,0,0,0,0,1,1,
            1,1,1,1,1,1,1,
            0,1,1,1,1,1,0
        }
    };

    static readonly byte[] plusPattern = {
        0,0,0,0,0,0,0,
        0,0,0,1,1,0,0,
        0,0,0,1,1,0,0,
        0,1,1,1,1,1,1,
        0,1,1,1,1,1,1,
        0,0,0,1,1,0,0,
        0,0,0,1,1,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0
    };

    static readonly byte[] minusPattern = {
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,1,1,1,1,1,1,
        0,1,1,1,1,1,1,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,
        0,0,0,0,0,0,0
    };

    const int CHAR_W = 7;
    const int CHAR_H = 9;
    const int SCALE = 2;
    const int OUTLINE = 2;

    // 그래디언트 임계값
    const float HIGHLIGHT_THRESHOLD = 0.15f;
    const float MIDDLE_THRESHOLD = 0.5f;
    const float TOP_MID_RANGE = 0.35f;
    const float MID_BOTTOM_RANGE = 0.5f;

    // 스프라이트 설정
    const float PPU_MULTIPLIER = 0.5f;
    static readonly Vector2 SPRITE_PIVOT = new Vector2(0.5f, 0.5f);

    struct StyleColors
    {
        public Color top, mid, bottom, highlight, outline;
    }

    static StyleColors GetStyleColors(DamageNumberStyle style)
    {
        return style switch
        {
            DamageNumberStyle.Damage => new StyleColors {
                top = new Color(1f, 0.75f, 0.8f),       // light pink
                mid = new Color(0.95f, 0.35f, 0.45f),    // pink-red
                bottom = new Color(0.7f, 0.15f, 0.25f),  // dark red
                highlight = new Color(1f, 0.95f, 0.95f),  // white-ish
                outline = new Color(0.25f, 0.05f, 0.1f)   // dark
            },
            DamageNumberStyle.Heal => new StyleColors {
                top = new Color(0.7f, 1f, 0.75f),
                mid = new Color(0.2f, 0.85f, 0.35f),
                bottom = new Color(0.1f, 0.55f, 0.2f),
                highlight = new Color(0.9f, 1f, 0.9f),
                outline = new Color(0.05f, 0.2f, 0.05f)
            },
            DamageNumberStyle.Gold => new StyleColors {
                top = new Color(1f, 0.95f, 0.5f),
                mid = new Color(1f, 0.8f, 0.2f),
                bottom = new Color(0.75f, 0.55f, 0.1f),
                highlight = new Color(1f, 1f, 0.85f),
                outline = new Color(0.3f, 0.2f, 0.05f)
            },
            DamageNumberStyle.Critical => new StyleColors {
                top = new Color(1f, 0.85f, 0.3f),
                mid = new Color(1f, 0.45f, 0.15f),
                bottom = new Color(0.8f, 0.15f, 0.1f),
                highlight = new Color(1f, 1f, 0.7f),
                outline = new Color(0.3f, 0.05f, 0.02f)
            },
            _ => GetStyleColors(DamageNumberStyle.Damage)
        };
    }

    static byte[] GetPattern(char c)
    {
        if (c >= '0' && c <= '9') return patterns[c - '0'];
        if (c == '+') return plusPattern;
        if (c == '-') return minusPattern;
        return null;
    }

    public static Sprite CreateNumberSprite(string text, DamageNumberStyle style = DamageNumberStyle.Damage)
    {
        string cacheKey = $"{text}_{style}";
        if (spriteCache.TryGetValue(cacheKey, out var cached)) return cached;

        var colors = GetStyleColors(style);
        int charCount = text.Length;
        int scaledW = CHAR_W * SCALE;
        int scaledH = CHAR_H * SCALE;
        int pad = OUTLINE * 2;
        int spacing = 1 * SCALE;
        int totalW = charCount * (scaledW + pad) + (charCount - 1) * spacing;
        int totalH = scaledH + pad;

        // 캐시 크기 제한: 오래된 항목 일괄 제거
        if (spriteCache.Count >= MAX_CACHE_SIZE)
        {
            foreach (var kvp in spriteCache)
            {
                if (kvp.Value != null)
                {
                    var t = kvp.Value.texture;
                    Object.Destroy(kvp.Value);
                    if (t != null) Object.Destroy(t);
                }
            }
            spriteCache.Clear();
        }

        var tex = new Texture2D(totalW, totalH, TextureFormat.RGBA32, false);
        tex.filterMode = FilterMode.Point;

        // 배열 기반 픽셀 조작 (SetPixel 개별 호출 대신)
        var pixels = new Color[totalW * totalH];

        for (int ci = 0; ci < charCount; ci++)
        {
            var pattern = GetPattern(text[ci]);
            if (pattern == null) continue;

            int offsetX = ci * (scaledW + pad + spacing);

            // Pass 1: thick outline
            for (int py = 0; py < CHAR_H; py++)
            {
                for (int px = 0; px < CHAR_W; px++)
                {
                    if (pattern[py * CHAR_W + px] == 0) continue;

                    for (int ox = -OUTLINE; ox <= OUTLINE; ox++)
                    {
                        for (int oy = -OUTLINE; oy <= OUTLINE; oy++)
                        {
                            int sx = offsetX + OUTLINE + px * SCALE + ox;
                            int sy = totalH - 1 - (OUTLINE + py * SCALE + oy);

                            for (int i = 0; i < SCALE; i++)
                            {
                                for (int j = 0; j < SCALE; j++)
                                {
                                    int fx = sx + i, fy = sy - j;
                                    if (fx >= 0 && fx < totalW && fy >= 0 && fy < totalH)
                                        pixels[fy * totalW + fx] = colors.outline;
                                }
                            }
                        }
                    }
                }
            }

            // Pass 2: gradient fill
            for (int py = 0; py < CHAR_H; py++)
            {
                for (int px = 0; px < CHAR_W; px++)
                {
                    if (pattern[py * CHAR_W + px] == 0) continue;

                    float t = (float)py / (CHAR_H - 1);
                    Color fill;
                    if (t < HIGHLIGHT_THRESHOLD)
                        fill = colors.highlight;
                    else if (t < MIDDLE_THRESHOLD)
                        fill = Color.Lerp(colors.top, colors.mid, (t - HIGHLIGHT_THRESHOLD) / TOP_MID_RANGE);
                    else
                        fill = Color.Lerp(colors.mid, colors.bottom, (t - MIDDLE_THRESHOLD) / MID_BOTTOM_RANGE);

                    int sx = offsetX + OUTLINE + px * SCALE;
                    int sy = totalH - 1 - (OUTLINE + py * SCALE);

                    for (int i = 0; i < SCALE; i++)
                    {
                        for (int j = 0; j < SCALE; j++)
                        {
                            int fx = sx + i, fy = sy - j;
                            if (fx >= 0 && fx < totalW && fy >= 0 && fy < totalH)
                                pixels[fy * totalW + fx] = fill;
                        }
                    }
                }
            }
        }

        tex.SetPixels(pixels);
        tex.Apply();
        float ppu = totalH * PPU_MULTIPLIER;
        var sprite = Sprite.Create(tex, new Rect(0, 0, totalW, totalH), SPRITE_PIVOT, ppu);
        spriteCache[cacheKey] = sprite;
        return sprite;
    }
}
