using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections;

/// <summary>
/// 활성 스킬 시너지를 전투 HUD 좌측에 표시하는 패널
/// SkillSynergyManager.OnSynergyChanged 이벤트 구독으로 자동 갱신
/// </summary>
public class SynergyUI : MonoBehaviour
{
    public static SynergyUI Instance { get; private set; }

    Canvas canvas;
    GameObject panel;
    GameObject itemContainer;
    readonly System.Collections.Generic.List<GameObject> items = new();

    SkillSynergyManager cachedSynergyMgr;

    const float PANEL_W = 120f;
    const float ITEM_H = 26f;
    const float ITEM_SPACING = 3f;
    const float PADDING = 5f;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        CreateCanvas();
        CreatePanel();
    }

    void Start()
    {
        StartCoroutine(DeferredSubscribe());
    }

    IEnumerator DeferredSubscribe()
    {
        yield return null;
        cachedSynergyMgr = SkillSynergyManager.Instance;
        if (cachedSynergyMgr != null)
        {
            cachedSynergyMgr.OnSynergyChanged += Refresh;
            Refresh();
        }
    }

    void OnDestroy()
    {
        if (cachedSynergyMgr != null)
            cachedSynergyMgr.OnSynergyChanged -= Refresh;
        if (Instance == this) Instance = null;
    }

    void CreateCanvas()
    {
        canvas = gameObject.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvas.sortingOrder = 45;

        var scaler = gameObject.AddComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = UIConstants.ReferenceResolution;
        scaler.matchWidthOrHeight = UIConstants.MatchWidthOrHeight;

        gameObject.AddComponent<GraphicRaycaster>();
    }

    void CreatePanel()
    {
        panel = UIHelper.MakeUI("SynergyPanel", canvas.transform);
        var rt = panel.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0f, 1f);
        rt.anchorMax = new Vector2(0f, 1f);
        rt.pivot = new Vector2(0f, 1f);
        rt.anchoredPosition = new Vector2(8f, -80f);
        rt.sizeDelta = new Vector2(PANEL_W, 10f); // 높이는 Refresh에서 조정

        // 반투명 배경
        var bg = panel.AddComponent<Image>();
        bg.color = new Color(0.1f, 0.08f, 0.05f, 0.72f);

        // 아이템 컨테이너
        itemContainer = UIHelper.MakeUI("Items", panel.transform);
        var crt = itemContainer.GetComponent<RectTransform>();
        crt.anchorMin = Vector2.zero;
        crt.anchorMax = Vector2.one;
        crt.offsetMin = new Vector2(PADDING, PADDING);
        crt.offsetMax = new Vector2(-PADDING, -PADDING);

        panel.SetActive(false);
    }

    void Refresh()
    {
        // 기존 항목 제거
        for (int i = 0; i < items.Count; i++)
            if (items[i] != null) Destroy(items[i]);
        items.Clear();

        var synMgr = SkillSynergyManager.Instance;
        if (synMgr == null || synMgr.ActiveSynergies.Count == 0)
        {
            panel.SetActive(false);
            return;
        }

        panel.SetActive(true);
        var synergies = synMgr.ActiveSynergies;
        float y = 0f;

        for (int i = 0; i < synergies.Count; i++)
        {
            var syn = synergies[i];
            var item = CreateSynergyItem(syn, y);
            items.Add(item);
            y -= (ITEM_H + ITEM_SPACING);
        }

        // 패널 높이 갱신
        float totalH = synergies.Count * ITEM_H + (synergies.Count - 1) * ITEM_SPACING + PADDING * 2;
        var panelRT = panel.GetComponent<RectTransform>();
        panelRT.sizeDelta = new Vector2(PANEL_W, totalH);

        // 컨테이너 위치 재정렬
        var crt = itemContainer.GetComponent<RectTransform>();
        crt.offsetMin = new Vector2(PADDING, PADDING);
        crt.offsetMax = new Vector2(-PADDING, -PADDING);
    }

    GameObject CreateSynergyItem(SkillSynergyData syn, float yOffset)
    {
        var item = UIHelper.MakeUI($"Syn_{syn.synergyName}", itemContainer.transform);
        var rt = item.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0f, 1f);
        rt.anchorMax = new Vector2(1f, 1f);
        rt.pivot = new Vector2(0.5f, 1f);
        rt.anchoredPosition = new Vector2(0f, yOffset);
        rt.sizeDelta = new Vector2(0f, ITEM_H);

        // 아이템 배경 - 시너지 타입별 색상
        var bg = item.AddComponent<Image>();
        bg.color = GetTypeColor(syn.type);

        // 이름 텍스트
        var nameText = UIHelper.MakeText("Name", item.transform, syn.synergyName,
            8f, TextAlignmentOptions.MidlineLeft, Color.white);
        nameText.fontStyle = FontStyles.Bold;
        nameText.raycastTarget = false;
        var nrt = nameText.GetComponent<RectTransform>();
        nrt.anchorMin = new Vector2(0f, 0f);
        nrt.anchorMax = new Vector2(1f, 0.55f);
        nrt.offsetMin = new Vector2(4f, 0f);
        nrt.offsetMax = new Vector2(-2f, 0f);

        // 보너스 텍스트
        string bonusStr = BuildBonusString(syn.bonus);
        var bonusText = UIHelper.MakeText("Bonus", item.transform, bonusStr,
            7f, TextAlignmentOptions.MidlineLeft, new Color(0.9f, 0.85f, 0.5f));
        bonusText.raycastTarget = false;
        var brt = bonusText.GetComponent<RectTransform>();
        brt.anchorMin = new Vector2(0f, 0f);
        brt.anchorMax = new Vector2(1f, 0.45f);
        brt.offsetMin = new Vector2(4f, 0f);
        brt.offsetMax = new Vector2(-2f, 0f);

        return item;
    }

    static Color GetTypeColor(SynergyType type)
    {
        return type switch
        {
            SynergyType.Combo   => new Color(0.55f, 0.28f, 0.08f, 0.85f),
            SynergyType.Element => new Color(0.18f, 0.35f, 0.55f, 0.85f),
            SynergyType.Tag     => new Color(0.28f, 0.45f, 0.18f, 0.85f),
            _                   => new Color(0.25f, 0.25f, 0.25f, 0.85f),
        };
    }

    static string BuildBonusString(SynergyBonus b)
    {
        var sb = new System.Text.StringBuilder();
        if (b.bonusAtkPercent != 0f)  sb.Append($"ATK+{b.bonusAtkPercent:F0}% ");
        if (b.bonusDefPercent != 0f)  sb.Append($"DEF+{b.bonusDefPercent:F0}% ");
        if (b.bonusHpPercent != 0f)   sb.Append($"HP+{b.bonusHpPercent:F0}% ");
        if (b.bonusDmgPercent != 0f)  sb.Append($"DMG+{b.bonusDmgPercent:F0}% ");
        if (b.cooldownReduction != 0f) sb.Append($"CD-{b.cooldownReduction:F0}%");
        return sb.Length > 0 ? sb.ToString().Trim() : "-";
    }
}
