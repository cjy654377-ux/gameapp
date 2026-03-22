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
        // SafeArea 루트
        var safeRoot = UIHelper.MakeUI("SafeAreaRoot", canvas.transform);
        safeRoot.AddComponent<SafeAreaAdapter>();
        UIHelper.FillParent(safeRoot.GetComponent<RectTransform>());

        panel = UIHelper.MakeUI("SynergyPanel", safeRoot.transform);
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
        if (synMgr == null || synMgr.AllSynergies == null || synMgr.AllSynergies.Count == 0)
        {
            panel.SetActive(false);
            return;
        }

        panel.SetActive(true);
        var all = synMgr.AllSynergies;
        float y = 0f;

        // 활성 시너지 먼저, 비활성 후
        for (int pass = 0; pass < 2; pass++)
        {
            for (int i = 0; i < all.Count; i++)
            {
                var syn = all[i];
                bool active = synMgr.IsActive(syn);
                if (pass == 0 && !active) continue;
                if (pass == 1 && active)  continue;

                var item = CreateSynergyItem(syn, y, active);
                items.Add(item);
                y -= (ITEM_H + ITEM_SPACING);
            }
        }

        // 패널 높이 갱신
        int count = all.Count;
        float totalH = count * ITEM_H + (count - 1) * ITEM_SPACING + PADDING * 2;
        var panelRT = panel.GetComponent<RectTransform>();
        panelRT.sizeDelta = new Vector2(PANEL_W, totalH);
    }

    GameObject CreateSynergyItem(SkillSynergyData syn, float yOffset, bool active)
    {
        var item = UIHelper.MakeUI($"Syn_{syn.synergyName}", itemContainer.transform);
        var rt = item.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0f, 1f);
        rt.anchorMax = new Vector2(1f, 1f);
        rt.pivot = new Vector2(0.5f, 1f);
        rt.anchoredPosition = new Vector2(0f, yOffset);
        rt.sizeDelta = new Vector2(0f, ITEM_H);

        // 배경: 활성=진한색, 비활성=어두운 회색
        var bg = item.AddComponent<Image>();
        bg.color = active ? GetTypeColor(syn.type) : new Color(0.15f, 0.14f, 0.12f, 0.75f);

        // 활성 표시 (★)
        string prefix = active ? "★ " : "○ ";
        Color nameCol = active ? Color.white : new Color(0.55f, 0.52f, 0.48f);
        var nameText = UIHelper.MakeText("Name", item.transform, prefix + syn.synergyName,
            8f, TextAlignmentOptions.MidlineLeft, nameCol);
        nameText.fontStyle = active ? FontStyles.Bold : FontStyles.Normal;
        nameText.raycastTarget = false;
        var nrt = nameText.GetComponent<RectTransform>();
        nrt.anchorMin = new Vector2(0f, 0.48f);
        nrt.anchorMax = new Vector2(1f, 1f);
        nrt.offsetMin = new Vector2(4f, 0f);
        nrt.offsetMax = new Vector2(-2f, 0f);

        // 조건/보너스 텍스트
        string condStr = BuildConditionString(syn);
        string bonusStr = BuildBonusString(syn.bonus);
        string infoStr = active ? bonusStr : condStr;
        Color infoCol = active ? new Color(0.9f, 0.85f, 0.5f) : new Color(0.65f, 0.65f, 0.58f);
        var bonusText = UIHelper.MakeText("Info", item.transform, infoStr,
            6f, TextAlignmentOptions.MidlineLeft, infoCol);
        bonusText.raycastTarget = false;
        var brt = bonusText.GetComponent<RectTransform>();
        brt.anchorMin = new Vector2(0f, 0f);
        brt.anchorMax = new Vector2(1f, 0.48f);
        brt.offsetMin = new Vector2(4f, 0f);
        brt.offsetMax = new Vector2(-2f, 0f);

        return item;
    }

    static string BuildConditionString(SkillSynergyData syn)
    {
        switch (syn.type)
        {
            case SynergyType.Combo:
                return syn.requiredSkillNames != null
                    ? "필요: " + string.Join("+", syn.requiredSkillNames)
                    : "조합";
            case SynergyType.Element:
                return $"{syn.requiredElement} 속성 {syn.requiredElementCount}개";
            case SynergyType.Tag:
                return $"[{syn.requiredTag}] 태그 {syn.requiredTagCount}개";
            default:
                return "";
        }
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
