using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using TMPro;

/// <summary>
/// 스킬 정보 팝업: 스킬 슬롯 길게 누르면(0.5초) 표시
/// 스킬 이름/속성/태그/효과/쿨타임/시너지 여부
/// </summary>
public class SkillInfoPopup : MonoBehaviour
{
    public static SkillInfoPopup Instance { get; private set; }

    Canvas canvas;
    GameObject popup;
    TextMeshProUGUI titleText;
    TextMeshProUGUI elementText;
    TextMeshProUGUI tagText;
    TextMeshProUGUI descText;
    TextMeshProUGUI cooldownText;
    TextMeshProUGUI synergyText;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        CreateCanvas();
        CreatePopup();
        popup.SetActive(false);
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }

    void CreateCanvas()
    {
        canvas = gameObject.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvas.sortingOrder = 210;

        var scaler = gameObject.AddComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = UIConstants.ReferenceResolution;
        scaler.matchWidthOrHeight = UIConstants.MatchWidthOrHeight;

        gameObject.AddComponent<GraphicRaycaster>();
    }

    void CreatePopup()
    {
        popup = UIHelper.MakeUI("SkillInfoPopup", canvas.transform);
        var dimBg = popup.AddComponent<Image>();
        dimBg.color = new Color(0, 0, 0, 0.4f);
        UIHelper.FillParent(popup.GetComponent<RectTransform>());

        var dimBtn = popup.AddComponent<Button>();
        dimBtn.targetGraphic = dimBg;
        dimBtn.onClick.AddListener(Hide);

        // 패널
        var panel = UIHelper.MakeSpritePanel("Panel", popup.transform,
            UISprites.Board, UIColors.Background_Panel);
        var prt = panel.GetComponent<RectTransform>();
        prt.anchorMin = new Vector2(0.08f, 0.35f);
        prt.anchorMax = new Vector2(0.92f, 0.65f);
        prt.offsetMin = Vector2.zero;
        prt.offsetMax = Vector2.zero;

        // 타이틀바
        var titleBar = UIHelper.MakeSpritePanel("TitleBar", panel.transform,
            UISprites.BoxBanner, UIColors.Background_Dark);
        var tbrt = titleBar.GetComponent<RectTransform>();
        tbrt.anchorMin = new Vector2(0, 0.82f);
        tbrt.anchorMax = new Vector2(1, 1);
        tbrt.offsetMin = Vector2.zero;
        tbrt.offsetMax = Vector2.zero;

        titleText = UIHelper.MakeText("Title", titleBar.transform, "",
            UIConstants.Font_HeaderMedium, TextAlignmentOptions.Center, Color.white);
        titleText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(titleText);
        UIHelper.FillParent(titleText.GetComponent<RectTransform>());

        // 닫기
        var closeObj = UIHelper.MakeUI("CloseBtn", titleBar.transform);
        var closeImg = closeObj.AddComponent<Image>();
        if (UISprites.BtnX != null)
        {
            closeImg.sprite = UISprites.BtnX;
            closeImg.type = Image.Type.Simple;
            closeImg.preserveAspect = true;
            closeImg.color = Color.white;
        }
        else closeImg.color = UIColors.Button_Brown;
        var closeBtn = closeObj.AddComponent<Button>();
        closeBtn.targetGraphic = closeImg;
        closeBtn.onClick.AddListener(Hide);
        var ccrt = closeObj.GetComponent<RectTransform>();
        ccrt.anchorMin = new Vector2(1, 0.5f);
        ccrt.anchorMax = new Vector2(1, 0.5f);
        ccrt.pivot = new Vector2(1, 0.5f);
        ccrt.anchoredPosition = new Vector2(-4, 0);
        ccrt.sizeDelta = new Vector2(20, 20);

        // 콘텐츠
        var content = UIHelper.MakeUI("Content", panel.transform);
        var cntrt = content.GetComponent<RectTransform>();
        cntrt.anchorMin = new Vector2(0.06f, 0.06f);
        cntrt.anchorMax = new Vector2(0.94f, 0.80f);
        cntrt.offsetMin = Vector2.zero;
        cntrt.offsetMax = Vector2.zero;

        // 속성 + 태그
        elementText = UIHelper.MakeText("Element", content.transform, "",
            UIConstants.Font_StatValue, TextAlignmentOptions.TopLeft, new Color(0.4f, 0.8f, 1f));
        elementText.fontStyle = FontStyles.Bold;
        var elrt = elementText.GetComponent<RectTransform>();
        elrt.anchorMin = new Vector2(0, 0.78f);
        elrt.anchorMax = new Vector2(0.5f, 1);
        elrt.offsetMin = Vector2.zero;
        elrt.offsetMax = Vector2.zero;

        tagText = UIHelper.MakeText("Tags", content.transform, "",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.TopRight, UIColors.Text_Secondary);
        var tgrt = tagText.GetComponent<RectTransform>();
        tgrt.anchorMin = new Vector2(0.5f, 0.78f);
        tgrt.anchorMax = new Vector2(1, 1);
        tgrt.offsetMin = Vector2.zero;
        tgrt.offsetMax = Vector2.zero;

        // 효과 설명
        descText = UIHelper.MakeText("Desc", content.transform, "",
            UIConstants.Font_StatLabel, TextAlignmentOptions.TopLeft, UIColors.Text_Dark);
        var drt = descText.GetComponent<RectTransform>();
        drt.anchorMin = new Vector2(0, 0.35f);
        drt.anchorMax = new Vector2(1, 0.78f);
        drt.offsetMin = Vector2.zero;
        drt.offsetMax = Vector2.zero;

        // 쿨타임
        cooldownText = UIHelper.MakeText("Cooldown", content.transform, "",
            UIConstants.Font_StatValue, TextAlignmentOptions.TopLeft, UIColors.Text_Gold);
        cooldownText.fontStyle = FontStyles.Bold;
        var cdrt = cooldownText.GetComponent<RectTransform>();
        cdrt.anchorMin = new Vector2(0, 0.15f);
        cdrt.anchorMax = new Vector2(0.5f, 0.35f);
        cdrt.offsetMin = Vector2.zero;
        cdrt.offsetMax = Vector2.zero;

        // 시너지
        synergyText = UIHelper.MakeText("Synergy", content.transform, "",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.TopLeft, new Color(0.3f, 0.9f, 0.5f));
        var snrt = synergyText.GetComponent<RectTransform>();
        snrt.anchorMin = new Vector2(0, 0);
        snrt.anchorMax = new Vector2(1, 0.15f);
        snrt.offsetMin = Vector2.zero;
        snrt.offsetMax = Vector2.zero;
    }

    public void Show(SkillData skill)
    {
        if (skill == null || popup == null) return;

        titleText.text = skill.skillName;
        elementText.text = skill.element != SkillElement.None ? $"속성: {skill.element}" : "";
        tagText.text = skill.tags != null && skill.tags.Length > 0 ? string.Join(", ", skill.tags) : "";
        descText.text = !string.IsNullOrEmpty(skill.description) ? skill.description :
            $"{skill.effectType} — {skill.value:F0} ({skill.targetType})";
        cooldownText.text = $"쿨타임: {skill.cooldown:F1}초";

        // 시너지 확인
        var ssm = SkillSynergyManager.Instance;
        if (ssm != null)
        {
            bool inSynergy = false;
            foreach (var syn in ssm.ActiveSynergies)
            {
                if (syn.requiredElement == skill.element && skill.element != SkillElement.None)
                    { inSynergy = true; break; }
                if (!string.IsNullOrEmpty(syn.requiredTag) && skill.tags != null
                    && System.Array.IndexOf(skill.tags, syn.requiredTag) >= 0)
                    { inSynergy = true; break; }
            }
            synergyText.text = inSynergy ? "★ 시너지 활성 중" : "";
        }
        else
            synergyText.text = "";

        popup.SetActive(true);
    }

    public void Hide()
    {
        if (popup != null)
            popup.SetActive(false);
    }

    /// <summary>
    /// 스킬 슬롯에 LongPressDetector 컴포넌트를 추가하는 헬퍼
    /// </summary>
    public static void AddLongPress(GameObject target, SkillData skill, float holdTime = 0.5f)
    {
        var detector = target.GetComponent<LongPressDetector>();
        if (detector == null) detector = target.AddComponent<LongPressDetector>();
        detector.Setup(skill, holdTime);
    }
}

/// <summary>
/// 길게 누르기 감지 (IPointerDownHandler/UpHandler 사용)
/// </summary>
public class LongPressDetector : MonoBehaviour, IPointerDownHandler, IPointerUpHandler
{
    SkillData skill;
    float holdTime = 0.5f;
    float pressStartTime;
    bool isPressed;
    bool fired;

    public void Setup(SkillData skillData, float hold)
    {
        skill = skillData;
        holdTime = hold;
    }

    public void OnPointerDown(PointerEventData eventData)
    {
        pressStartTime = Time.unscaledTime;
        isPressed = true;
        fired = false;
    }

    public void OnPointerUp(PointerEventData eventData)
    {
        isPressed = false;
    }

    void Update()
    {
        if (isPressed && !fired && Time.unscaledTime - pressStartTime >= holdTime)
        {
            fired = true;
            isPressed = false;
            SkillInfoPopup.Instance?.Show(skill);
        }
    }
}
