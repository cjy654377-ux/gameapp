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

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
    static void ResetStatics()
    {
        if (pixelSprite != null)
        {
            var tex = pixelSprite.texture;
            Object.Destroy(pixelSprite);
            if (tex != null) Object.Destroy(tex);
            pixelSprite = null;
        }
    }

    const float BAR_WIDTH_ALLY  = 0.9f;
    const float BAR_WIDTH_ENEMY = 0.75f;
    const float BAR_HEIGHT_ALLY  = 0.11f;
    const float BAR_HEIGHT_ENEMY = 0.08f;
    const float BORDER = 0.02f;
    const float Y_OFFSET = 1.1f;
    const float ICON_SIZE = 0.15f;
    const float ICON_SPACING = 0.18f;

    // computed per-unit
    float barWidth;
    float barHeight;

    void Start()
    {
        unit = GetComponent<BattleUnit>();
        if (unit != null)
            unit.OnHpChanged += UpdateBar;

        statusController = GetComponent<StatusEffectController>();
        if (statusController != null)
            statusController.OnEffectsChanged += RefreshStatusIcons;

        bool isAlly = unit != null && unit.CurrentTeam == BattleUnit.Team.Ally;
        barWidth  = isAlly ? BAR_WIDTH_ALLY  : BAR_WIDTH_ENEMY;
        barHeight = isAlly ? BAR_HEIGHT_ALLY : BAR_HEIGHT_ENEMY;

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

        bool isAlly = unit != null && unit.CurrentTeam == BattleUnit.Team.Ally;

        // Border (black outline)
        var borderObj = new GameObject("Border");
        borderObj.transform.SetParent(barRoot, false);
        borderObj.transform.localScale = new Vector3(barWidth + BORDER * 2, barHeight + BORDER * 2, 1);
        borderRenderer = borderObj.AddComponent<SpriteRenderer>();
        borderRenderer.sprite = pixelSprite;
        borderRenderer.color = Color.black;
        borderRenderer.sortingOrder = 89;

        // Background (dark)
        var bgObj = new GameObject("BG");
        bgObj.transform.SetParent(barRoot, false);
        bgObj.transform.localScale = new Vector3(barWidth, barHeight, 1);
        bgRenderer = bgObj.AddComponent<SpriteRenderer>();
        bgRenderer.sprite = pixelSprite;
        bgRenderer.color = UIColors.ProgressBar_BG;
        bgRenderer.sortingOrder = 90;

        // Fill
        var fillObj = new GameObject("Fill");
        fillObj.transform.SetParent(barRoot, false);
        fillObj.transform.localPosition = new Vector3(-barWidth * 0.5f, 0, 0);
        fillTransform = fillObj.transform;

        var innerFill = new GameObject("Inner");
        innerFill.transform.SetParent(fillObj.transform, false);
        innerFill.transform.localPosition = new Vector3(barWidth * 0.5f, 0, 0);
        innerFill.transform.localScale = new Vector3(barWidth, barHeight, 1);
        fillRenderer = innerFill.AddComponent<SpriteRenderer>();
        fillRenderer.sprite = pixelSprite;
        // 아군: 청록 계열, 적군: 녹색→황→적 그라디언트 (UpdateBar에서 동적 설정)
        fillRenderer.color = isAlly ? new Color(0.3f, 0.85f, 0.7f) : UIColors.ProgressBar_Fill;
        fillRenderer.sortingOrder = 91;
    }

    void UpdateBar(float current, float max)
    {
        if (fillTransform == null) return;
        float ratio = Mathf.Clamp01(current / max);

        fillTransform.localScale = new Vector3(ratio, 1, 1);

        bool isAlly = unit != null && unit.CurrentTeam == BattleUnit.Team.Ally;
        if (isAlly)
        {
            // 아군: 청록(풀체력) → 노랑(절반) → 빨강(위험)
            if (ratio > 0.5f)
                fillRenderer.color = Color.Lerp(UIColors.Text_Gold, new Color(0.3f, 0.85f, 0.7f), (ratio - 0.5f) * 2f);
            else
                fillRenderer.color = Color.Lerp(UIColors.Defeat_Red, UIColors.Text_Gold, ratio * 2f);
        }
        else
        {
            // 적군: 녹→황→적 그라디언트
            if (ratio > 0.5f)
                fillRenderer.color = Color.Lerp(UIColors.Text_Gold, UIColors.ProgressBar_Fill, (ratio - 0.5f) * 2f);
            else
                fillRenderer.color = Color.Lerp(UIColors.Defeat_Red, UIColors.Text_Gold, ratio * 2f);
        }
    }

    void RefreshStatusIcons()
    {
        // Clear old icons
        for (int i = 0; i < statusIcons.Count; i++)
            if (statusIcons[i] != null) Destroy(statusIcons[i].gameObject);
        statusIcons.Clear();

        if (statusController == null || barRoot == null) return;

        var effects = statusController.ActiveEffects;
        float startX = -barWidth * 0.5f;

        for (int i = 0; i < effects.Count; i++)
        {
            var iconObj = new GameObject($"StatusIcon_{effects[i].type}");
            iconObj.transform.SetParent(barRoot, false);
            iconObj.transform.localPosition = new Vector3(startX + i * ICON_SPACING, -(barHeight + ICON_SIZE * 0.5f + 0.03f), 0);
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
