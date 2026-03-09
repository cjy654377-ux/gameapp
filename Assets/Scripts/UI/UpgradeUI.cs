using UnityEngine;
using UnityEngine.UI;
using TMPro;

/// <summary>
/// 훈련(업그레이드) 패널 - UI_SPEC StatUpgradeRow 스타일
/// MainHUD의 "훈련" 탭 패널에 부착하여 사용
/// </summary>
public class UpgradeUI : MonoBehaviour
{
    Canvas canvas;
    GameObject panel;
    Button toggleButton;

    TextMeshProUGUI hpText, atkText, defText, spdText;
    Button hpBtn, atkBtn, defBtn, spdBtn;

    bool panelOpen = false;

    void Start()
    {
        CreateCanvas();
        CreateToggleButton();
        CreatePanel();
        panel.SetActive(false);

        if (UpgradeManager.Instance != null)
            UpgradeManager.Instance.OnUpgraded += RefreshUI;
        if (GoldManager.Instance != null)
            GoldManager.Instance.OnGoldChanged += OnGoldChanged;
    }

    void CreateCanvas()
    {
        canvas = gameObject.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvas.sortingOrder = 97;

        var scaler = gameObject.AddComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = UIConstants.ReferenceResolution;
        scaler.matchWidthOrHeight = UIConstants.MatchWidthOrHeight;

        gameObject.AddComponent<GraphicRaycaster>();
    }

    void CreateToggleButton()
    {
        var (btn, img) = UIHelper.MakeButton("ToggleBtn", canvas.transform,
            UIColors.Button_Brown, "UPGRADE", UIConstants.Font_Tab);
        toggleButton = btn;
        toggleButton.onClick.AddListener(TogglePanel);

        var outline = btn.gameObject.AddComponent<Outline>();
        outline.effectColor = UIColors.Button_Brown_Border;
        outline.effectDistance = new Vector2(1, 1);

        var rt = btn.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0, 0);
        rt.anchorMax = new Vector2(0, 0);
        rt.pivot = new Vector2(0, 0);
        rt.anchoredPosition = new Vector2(UIConstants.Spacing_Medium, UIConstants.NavBar_Height + UIConstants.Spacing_Medium);
        rt.sizeDelta = new Vector2(UIConstants.Button_MinWidth, UIConstants.Button_MinHeight);
    }

    void CreatePanel()
    {
        panel = UIHelper.MakeUI("UpgradePanel", canvas.transform);
        var panelImg = panel.AddComponent<Image>();
        panelImg.color = UIColors.Background_Panel;

        var panelOutline = panel.AddComponent<Outline>();
        panelOutline.effectColor = UIColors.Panel_Border;
        panelOutline.effectDistance = new Vector2(UIConstants.Panel_BorderWidth, UIConstants.Panel_BorderWidth);

        var prt = panel.GetComponent<RectTransform>();
        prt.anchorMin = new Vector2(0, 0);
        prt.anchorMax = new Vector2(1, 0);
        prt.pivot = new Vector2(0.5f, 0);
        prt.anchoredPosition = new Vector2(0, UIConstants.NavBar_Height + UIConstants.Button_MinHeight + UIConstants.Spacing_Large);
        prt.sizeDelta = new Vector2(-UIConstants.Spacing_XLarge, UIConstants.StatRow_Height * 4 + UIConstants.Spacing_Large * 2);

        float y = -UIConstants.Spacing_Large;
        CreateUpgradeRow(panel.transform, "HP", ref hpText, ref hpBtn, y, () => UpgradeManager.Instance?.UpgradeHp());
        y -= UIConstants.StatRow_Height;
        CreateUpgradeRow(panel.transform, "ATK", ref atkText, ref atkBtn, y, () => UpgradeManager.Instance?.UpgradeAtk());
        y -= UIConstants.StatRow_Height;
        CreateUpgradeRow(panel.transform, "DEF", ref defText, ref defBtn, y, () => UpgradeManager.Instance?.UpgradeDef());
        y -= UIConstants.StatRow_Height;
        CreateUpgradeRow(panel.transform, "SPD", ref spdText, ref spdBtn, y, () => UpgradeManager.Instance?.UpgradeSpeed());

        RefreshUI();
    }

    void CreateUpgradeRow(Transform parent, string label, ref TextMeshProUGUI infoText, ref Button btn, float yPos, UnityEngine.Events.UnityAction onClick)
    {
        // Row background
        var row = UIHelper.MakePanel($"{label}Row", parent, UIColors.Panel_Inner);
        var rrt = row.GetComponent<RectTransform>();
        rrt.anchorMin = new Vector2(0, 1);
        rrt.anchorMax = new Vector2(1, 1);
        rrt.pivot = new Vector2(0.5f, 1);
        rrt.anchoredPosition = new Vector2(0, yPos);
        rrt.sizeDelta = new Vector2(-UIConstants.Panel_Padding * 2, UIConstants.StatRow_Height - UIConstants.Spacing_Small);

        // Divider at bottom
        var divider = UIHelper.MakePanel("Divider", row.transform, UIColors.Panel_Border);
        var drt = divider.GetComponent<RectTransform>();
        drt.anchorMin = new Vector2(0, 0);
        drt.anchorMax = new Vector2(1, 0);
        drt.pivot = new Vector2(0.5f, 0);
        drt.sizeDelta = new Vector2(0, 1);

        // Stat label
        var labelText = UIHelper.MakeText($"{label}Label", row.transform, label,
            UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, UIColors.Text_Secondary);
        var llrt = labelText.GetComponent<RectTransform>();
        llrt.anchorMin = new Vector2(0, 0.6f);
        llrt.anchorMax = new Vector2(0.15f, 1);
        llrt.offsetMin = new Vector2(UIConstants.StatRow_Padding, 0);
        llrt.offsetMax = Vector2.zero;

        // Info text (level + bonus)
        var infoObj = UIHelper.MakeUI($"{label}Info", row.transform);
        infoText = infoObj.AddComponent<TextMeshProUGUI>();
        infoText.fontSize = UIConstants.Font_StatValue;
        infoText.alignment = TextAlignmentOptions.MidlineLeft;
        infoText.color = UIColors.Text_Primary;
        infoText.fontStyle = FontStyles.Bold;
        var irt = infoObj.GetComponent<RectTransform>();
        irt.anchorMin = new Vector2(0.15f, 0);
        irt.anchorMax = new Vector2(0.65f, 0.65f);
        irt.offsetMin = new Vector2(UIConstants.StatRow_Padding, UIConstants.Spacing_Small);
        irt.offsetMax = Vector2.zero;

        // Upgrade button (green)
        var (upgradeBtn, upgImg) = UIHelper.MakeButton($"{label}Btn", row.transform,
            UIColors.Button_Green, "", UIConstants.Font_Cost);
        btn = upgradeBtn;
        btn.onClick.AddListener(onClick);

        var ubOutline = btn.gameObject.AddComponent<Outline>();
        ubOutline.effectColor = UIColors.Button_Green_Border;
        ubOutline.effectDistance = new Vector2(1, 1);

        var ubrt = btn.GetComponent<RectTransform>();
        ubrt.anchorMin = new Vector2(0.7f, 0.1f);
        ubrt.anchorMax = new Vector2(0.97f, 0.9f);
        ubrt.offsetMin = Vector2.zero;
        ubrt.offsetMax = Vector2.zero;

        // Cost text inside button
        var costText = UIHelper.MakeText("Cost", btn.transform, "UP",
            UIConstants.Font_Cost, TextAlignmentOptions.Center, UIColors.Text_Gold);
        costText.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(costText.GetComponent<RectTransform>());
    }

    void TogglePanel()
    {
        panelOpen = !panelOpen;
        panel.SetActive(panelOpen);
        if (panelOpen) RefreshUI();
    }

    void RefreshUI()
    {
        var um = UpgradeManager.Instance;
        if (um == null) return;

        hpText.text = $"Lv.{um.HpLevel}  +{um.GetHpBonus():F0}";
        atkText.text = $"Lv.{um.AtkLevel}  +{um.GetAtkBonus():F0}";
        defText.text = $"Lv.{um.DefLevel}  +{um.GetDefBonus():F1}";
        spdText.text = $"Lv.{um.SpeedLevel}  +{um.GetSpeedBonus():F1}";

        SetBtnCost(hpBtn, um.GetCost(um.HpLevel));
        SetBtnCost(atkBtn, um.GetCost(um.AtkLevel));
        SetBtnCost(defBtn, um.GetCost(um.DefLevel));
        SetBtnCost(spdBtn, um.GetCost(um.SpeedLevel));
    }

    void SetBtnCost(Button btn, int cost)
    {
        var text = btn.GetComponentInChildren<TextMeshProUGUI>();
        if (text != null)
            text.text = $"{cost}G";

        bool canAfford = GoldManager.Instance != null && GoldManager.Instance.Gold >= cost;
        btn.GetComponent<Image>().color = canAfford ? UIColors.Button_Green : UIColors.Button_Gray;
    }

    void OnGoldChanged(int _) => RefreshUI();

    void OnDestroy()
    {
        if (UpgradeManager.Instance != null)
            UpgradeManager.Instance.OnUpgraded -= RefreshUI;
        if (GoldManager.Instance != null)
            GoldManager.Instance.OnGoldChanged -= OnGoldChanged;
    }
}
