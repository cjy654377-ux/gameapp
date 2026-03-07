using UnityEngine;
using System.Collections.Generic;

public class HpBar : MonoBehaviour
{
    private SpriteRenderer bgRenderer;
    private SpriteRenderer fillRenderer;
    private SpriteRenderer borderRenderer;
    private Transform fillTransform;
    private BattleUnit unit;
    private Transform barRoot;
    private StatusEffectController statusController;

    // Status effect icons
    private readonly List<SpriteRenderer> statusIcons = new();

    static Sprite pixelSprite;
    const float BAR_WIDTH = 0.8f;
    const float BAR_HEIGHT = 0.08f;
    const float BORDER = 0.02f;
    const float Y_OFFSET = 1.0f;
    const float ICON_SIZE = 0.15f;
    const float ICON_SPACING = 0.18f;

    void Start()
    {
        unit = GetComponent<BattleUnit>();
        if (unit != null)
            unit.OnHpChanged += UpdateBar;

        statusController = GetComponent<StatusEffectController>();
        if (statusController != null)
            statusController.OnEffectsChanged += RefreshStatusIcons;

        CreateBar();
    }

    void CreateBar()
    {
        if (pixelSprite == null)
        {
            var tex = new Texture2D(1, 1);
            tex.SetPixel(0, 0, Color.white);
            tex.Apply();
            tex.filterMode = FilterMode.Point;
            pixelSprite = Sprite.Create(tex, new Rect(0, 0, 1, 1), new Vector2(0.5f, 0.5f), 1f);
        }

        barRoot = new GameObject("HpBar").transform;
        barRoot.SetParent(transform, false);
        barRoot.localPosition = new Vector3(0, Y_OFFSET, 0);

        // Border (black outline)
        var borderObj = new GameObject("Border");
        borderObj.transform.SetParent(barRoot, false);
        borderObj.transform.localScale = new Vector3(BAR_WIDTH + BORDER * 2, BAR_HEIGHT + BORDER * 2, 1);
        borderRenderer = borderObj.AddComponent<SpriteRenderer>();
        borderRenderer.sprite = pixelSprite;
        borderRenderer.color = new Color(0.1f, 0.1f, 0.1f, 0.9f);
        borderRenderer.sortingOrder = 89;

        // Background (dark)
        var bgObj = new GameObject("BG");
        bgObj.transform.SetParent(barRoot, false);
        bgObj.transform.localScale = new Vector3(BAR_WIDTH, BAR_HEIGHT, 1);
        bgRenderer = bgObj.AddComponent<SpriteRenderer>();
        bgRenderer.sprite = pixelSprite;
        bgRenderer.color = new Color(0.15f, 0.05f, 0.05f, 0.9f);
        bgRenderer.sortingOrder = 90;

        // Fill (gradient green)
        var fillObj = new GameObject("Fill");
        fillObj.transform.SetParent(barRoot, false);
        fillObj.transform.localPosition = new Vector3(-BAR_WIDTH * 0.5f, 0, 0);
        fillTransform = fillObj.transform;

        var innerFill = new GameObject("Inner");
        innerFill.transform.SetParent(fillObj.transform, false);
        innerFill.transform.localPosition = new Vector3(BAR_WIDTH * 0.5f, 0, 0);
        innerFill.transform.localScale = new Vector3(BAR_WIDTH, BAR_HEIGHT, 1);
        fillRenderer = innerFill.AddComponent<SpriteRenderer>();
        fillRenderer.sprite = pixelSprite;
        fillRenderer.color = new Color(0.2f, 0.9f, 0.3f);
        fillRenderer.sortingOrder = 91;
    }

    void UpdateBar(float current, float max)
    {
        if (fillTransform == null) return;
        float ratio = Mathf.Clamp01(current / max);

        fillTransform.localScale = new Vector3(ratio, 1, 1);

        // Color gradient: green -> yellow -> red
        if (ratio > 0.5f)
            fillRenderer.color = Color.Lerp(new Color(0.9f, 0.9f, 0.1f), new Color(0.2f, 0.9f, 0.3f), (ratio - 0.5f) * 2f);
        else
            fillRenderer.color = Color.Lerp(new Color(0.9f, 0.15f, 0.15f), new Color(0.9f, 0.9f, 0.1f), ratio * 2f);
    }

    void RefreshStatusIcons()
    {
        // Clear old icons
        for (int i = 0; i < statusIcons.Count; i++)
            if (statusIcons[i] != null) Destroy(statusIcons[i].gameObject);
        statusIcons.Clear();

        if (statusController == null || barRoot == null) return;

        var effects = statusController.ActiveEffects;
        float startX = -BAR_WIDTH * 0.5f;

        for (int i = 0; i < effects.Count; i++)
        {
            var iconObj = new GameObject($"StatusIcon_{effects[i].type}");
            iconObj.transform.SetParent(barRoot, false);
            iconObj.transform.localPosition = new Vector3(startX + i * ICON_SPACING, -(BAR_HEIGHT + ICON_SIZE * 0.5f + 0.03f), 0);
            iconObj.transform.localScale = new Vector3(ICON_SIZE, ICON_SIZE, 1);

            var sr = iconObj.AddComponent<SpriteRenderer>();
            sr.sprite = pixelSprite;
            sr.sortingOrder = 92;
            sr.color = GetStatusColor(effects[i].type);

            statusIcons.Add(sr);
        }
    }

    static Color GetStatusColor(StatusEffectType type)
    {
        return type switch
        {
            StatusEffectType.Burn => new Color(1f, 0.4f, 0.1f),     // orange-red
            StatusEffectType.Freeze => new Color(0.4f, 0.8f, 1f),   // ice blue
            StatusEffectType.Poison => new Color(0.3f, 0.9f, 0.2f), // toxic green
            StatusEffectType.Slow => new Color(0.6f, 0.4f, 0.8f),   // purple
            _ => Color.white
        };
    }

    void LateUpdate()
    {
        // Keep bar horizontal even when parent is flipped
        if (barRoot != null)
            barRoot.rotation = Quaternion.identity;
    }

    void OnDestroy()
    {
        if (unit != null)
            unit.OnHpChanged -= UpdateBar;
        if (statusController != null)
            statusController.OnEffectsChanged -= RefreshStatusIcons;
    }
}
