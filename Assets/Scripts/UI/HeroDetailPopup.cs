using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections.Generic;

/// <summary>
/// 영웅 상세 팝업: 이름/성급/스탯/장비/각성/레벨 표시
/// MainHUD canvas 위에 오버레이로 표시
/// </summary>
public class HeroDetailPopup : MonoBehaviour
{
    public static HeroDetailPopup Instance { get; private set; }

    Canvas canvas;
    GameObject popup;
    TextMeshProUGUI nameText;
    TextMeshProUGUI levelText;
    TextMeshProUGUI statsText;
    TextMeshProUGUI equipText;
    TextMeshProUGUI awakeText;
    Transform starContainer;

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
        canvas.sortingOrder = 200;

        var scaler = gameObject.AddComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = UIConstants.ReferenceResolution;
        scaler.matchWidthOrHeight = UIConstants.MatchWidthOrHeight;

        gameObject.AddComponent<GraphicRaycaster>();
    }

    void CreatePopup()
    {
        popup = UIHelper.MakeUI("HeroDetailPopup", canvas.transform);
        var dimBg = popup.AddComponent<Image>();
        dimBg.color = UIColors.Overlay_Dark;
        UIHelper.FillParent(popup.GetComponent<RectTransform>());

        // 클릭 시 닫기 (배경)
        var dimBtn = popup.AddComponent<Button>();
        dimBtn.targetGraphic = dimBg;
        dimBtn.onClick.AddListener(Hide);

        // 패널 — Board 배경
        var panel = UIHelper.MakeSpritePanel("Panel", popup.transform,
            UISprites.Board, UIColors.Background_Panel);
        var prt = panel.GetComponent<RectTransform>();
        prt.anchorMin = new Vector2(0.08f, 0.25f);
        prt.anchorMax = new Vector2(0.92f, 0.75f);
        prt.offsetMin = Vector2.zero;
        prt.offsetMax = Vector2.zero;

        // 타이틀바
        var titleBar = UIHelper.MakeSpritePanel("TitleBar", panel.transform,
            UISprites.BoxBanner, UIColors.Background_Dark);
        var tbrt = titleBar.GetComponent<RectTransform>();
        tbrt.anchorMin = new Vector2(0, 0.85f);
        tbrt.anchorMax = new Vector2(1, 1);
        tbrt.offsetMin = Vector2.zero;
        tbrt.offsetMax = Vector2.zero;

        nameText = UIHelper.MakeText("Name", titleBar.transform, "",
            UIConstants.Font_HeaderMedium, TextAlignmentOptions.Center, Color.white);
        nameText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(nameText);
        UIHelper.FillParent(nameText.GetComponent<RectTransform>());

        // 닫기 버튼
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
        var crt = closeObj.GetComponent<RectTransform>();
        crt.anchorMin = new Vector2(1, 0.5f);
        crt.anchorMax = new Vector2(1, 0.5f);
        crt.pivot = new Vector2(1, 0.5f);
        crt.anchoredPosition = new Vector2(-4, 0);
        crt.sizeDelta = new Vector2(22, 22);

        // 콘텐츠 영역
        var content = UIHelper.MakeUI("Content", panel.transform);
        var cntrt = content.GetComponent<RectTransform>();
        cntrt.anchorMin = new Vector2(0.05f, 0.04f);
        cntrt.anchorMax = new Vector2(0.95f, 0.84f);
        cntrt.offsetMin = Vector2.zero;
        cntrt.offsetMax = Vector2.zero;

        // 레벨 + 각성
        levelText = UIHelper.MakeText("Level", content.transform, "",
            UIConstants.Font_StatValue, TextAlignmentOptions.TopLeft, UIColors.Text_Gold);
        levelText.fontStyle = FontStyles.Bold;
        var lvrt = levelText.GetComponent<RectTransform>();
        lvrt.anchorMin = new Vector2(0, 0.82f);
        lvrt.anchorMax = new Vector2(0.5f, 1);
        lvrt.offsetMin = Vector2.zero;
        lvrt.offsetMax = Vector2.zero;

        awakeText = UIHelper.MakeText("Awake", content.transform, "",
            UIConstants.Font_StatValue, TextAlignmentOptions.TopRight, new Color(0.8f, 0.5f, 1f));
        awakeText.fontStyle = FontStyles.Bold;
        var awrt = awakeText.GetComponent<RectTransform>();
        awrt.anchorMin = new Vector2(0.5f, 0.82f);
        awrt.anchorMax = new Vector2(1, 1);
        awrt.offsetMin = Vector2.zero;
        awrt.offsetMax = Vector2.zero;

        // 성급 별
        starContainer = UIHelper.MakeUI("Stars", content.transform).transform;
        var scrt = starContainer.GetComponent<RectTransform>();
        scrt.anchorMin = new Vector2(0, 0.70f);
        scrt.anchorMax = new Vector2(1, 0.82f);
        scrt.offsetMin = Vector2.zero;
        scrt.offsetMax = Vector2.zero;

        // 스탯
        statsText = UIHelper.MakeText("Stats", content.transform, "",
            UIConstants.Font_StatLabel, TextAlignmentOptions.TopLeft, UIColors.Text_Dark);
        var strt = statsText.GetComponent<RectTransform>();
        strt.anchorMin = new Vector2(0, 0.30f);
        strt.anchorMax = new Vector2(1, 0.70f);
        strt.offsetMin = Vector2.zero;
        strt.offsetMax = Vector2.zero;

        // 장비
        equipText = UIHelper.MakeText("Equip", content.transform, "",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.TopLeft, UIColors.Text_DarkSecondary);
        var ert = equipText.GetComponent<RectTransform>();
        ert.anchorMin = new Vector2(0, 0);
        ert.anchorMax = new Vector2(1, 0.30f);
        ert.offsetMin = Vector2.zero;
        ert.offsetMax = Vector2.zero;
    }

    public void Show(CharacterPreset preset)
    {
        if (preset == null || popup == null) return;

        nameText.text = preset.characterName;

        // 레벨
        int level = 1;
        int awakening = 0;
        var hlm = HeroLevelManager.Instance;
        if (hlm != null)
        {
            level = hlm.GetLevel(preset.characterName);
            awakening = hlm.GetAwakeningStage(preset.characterName);
        }
        levelText.text = $"Lv.{level}";
        awakeText.text = awakening > 0 ? $"각성 {awakening}단계" : "";

        // 별
        foreach (Transform child in starContainer)
            Destroy(child.gameObject);
        UIHelper.MakeStarRating("Stars", starContainer, (int)preset.starGrade, 12f);

        // 스탯
        statsText.text = $"HP: {preset.maxHp:F0}\nATK: {preset.atk:F0}\nDEF: {preset.def:F0}\nSPD: {preset.moveSpeed:F1}";

        // 장비
        var em = EquipmentManager.Instance;
        if (em != null)
        {
            var items = em.GetEquippedItems(preset.characterName);
            if (items.Count > 0)
            {
                var sb = new System.Text.StringBuilder("장착 장비:\n");
                foreach (var eq in items)
                    sb.AppendLine($"  ★{eq.rarity} {eq.itemName} ({eq.slot})");
                equipText.text = sb.ToString();
            }
            else
                equipText.text = "장착 장비: 없음";
        }
        else
            equipText.text = "장착 장비: 없음";

        popup.SetActive(true);
    }

    public void Hide()
    {
        if (popup != null)
            popup.SetActive(false);
    }
}
