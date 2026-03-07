using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class GoldUI : MonoBehaviour
{
    TextMeshProUGUI goldText;
    TextMeshProUGUI tapDmgText;
    Button upgradeButton;
    TextMeshProUGUI upgradeCostText;

    void Start()
    {
        var canvas = GetComponent<Canvas>();
        if (canvas == null)
        {
            canvas = gameObject.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 98;

            var scaler = gameObject.AddComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1080, 1920);
            scaler.matchWidthOrHeight = 0f;
            gameObject.AddComponent<GraphicRaycaster>();
        }

        CreateGoldDisplay();
        CreateTapUpgradeButton();

        if (GoldManager.Instance != null)
            GoldManager.Instance.OnGoldChanged += UpdateGoldDisplay;

        UpdateGoldDisplay(GoldManager.Instance != null ? GoldManager.Instance.Gold : 0);
        UpdateTapInfo();
    }

    void CreateGoldDisplay()
    {
        var panel = CreateUIObj("GoldPanel", transform);
        var panelImg = panel.AddComponent<Image>();
        panelImg.color = new Color(0.1f, 0.1f, 0.15f, 0.8f);

        var panelRT = panel.GetComponent<RectTransform>();
        panelRT.anchorMin = new Vector2(1f, 1f);
        panelRT.anchorMax = new Vector2(1f, 1f);
        panelRT.pivot = new Vector2(1f, 1f);
        panelRT.anchoredPosition = new Vector2(-20, -20);
        panelRT.sizeDelta = new Vector2(250, 50);

        var textObj = CreateUIObj("GoldText", panel.transform);
        goldText = textObj.AddComponent<TextMeshProUGUI>();
        goldText.text = "0 G";
        goldText.fontSize = 28;
        goldText.alignment = TextAlignmentOptions.MidlineRight;
        goldText.color = new Color(1f, 0.85f, 0.2f);
        goldText.fontStyle = FontStyles.Bold;
        var textRT = textObj.GetComponent<RectTransform>();
        textRT.anchorMin = Vector2.zero;
        textRT.anchorMax = Vector2.one;
        textRT.sizeDelta = new Vector2(-20, 0);
    }

    void CreateTapUpgradeButton()
    {
        var panel = CreateUIObj("TapPanel", transform);
        var panelImg = panel.AddComponent<Image>();
        panelImg.color = new Color(0.2f, 0.15f, 0.1f, 0.8f);

        var panelRT = panel.GetComponent<RectTransform>();
        panelRT.anchorMin = new Vector2(1f, 1f);
        panelRT.anchorMax = new Vector2(1f, 1f);
        panelRT.pivot = new Vector2(1f, 1f);
        panelRT.anchoredPosition = new Vector2(-20, -80);
        panelRT.sizeDelta = new Vector2(250, 70);

        // Tap damage info
        var infoObj = CreateUIObj("TapInfo", panel.transform);
        tapDmgText = infoObj.AddComponent<TextMeshProUGUI>();
        tapDmgText.fontSize = 18;
        tapDmgText.alignment = TextAlignmentOptions.MidlineLeft;
        tapDmgText.color = Color.white;
        var infoRT = infoObj.GetComponent<RectTransform>();
        infoRT.anchorMin = new Vector2(0, 0.5f);
        infoRT.anchorMax = new Vector2(0.55f, 1f);
        infoRT.sizeDelta = Vector2.zero;
        infoRT.offsetMin = new Vector2(10, 0);

        // Upgrade button
        var btnObj = CreateUIObj("UpgradeBtn", panel.transform);
        var btnImg = btnObj.AddComponent<Image>();
        btnImg.color = new Color(0.3f, 0.6f, 0.2f);
        upgradeButton = btnObj.AddComponent<Button>();
        upgradeButton.targetGraphic = btnImg;
        upgradeButton.onClick.AddListener(OnUpgradeClicked);

        var btnRT = btnObj.GetComponent<RectTransform>();
        btnRT.anchorMin = new Vector2(0.6f, 0.1f);
        btnRT.anchorMax = new Vector2(0.95f, 0.9f);
        btnRT.sizeDelta = Vector2.zero;

        var costObj = CreateUIObj("Cost", btnObj.transform);
        upgradeCostText = costObj.AddComponent<TextMeshProUGUI>();
        upgradeCostText.fontSize = 16;
        upgradeCostText.alignment = TextAlignmentOptions.Center;
        upgradeCostText.color = Color.white;
        var costRT = costObj.GetComponent<RectTransform>();
        costRT.anchorMin = Vector2.zero;
        costRT.anchorMax = Vector2.one;
        costRT.sizeDelta = Vector2.zero;
    }

    void UpdateGoldDisplay(int gold)
    {
        if (goldText != null)
            goldText.text = $"{gold} G";
    }

    void UpdateTapInfo()
    {
        if (TapDamageSystem.Instance == null) return;
        tapDmgText.text = $"Tap Lv.{TapDamageSystem.Instance.tapDamageLevel}\nDMG: {TapDamageSystem.Instance.TapDamage:F0}";
        upgradeCostText.text = $"UP\n{TapDamageSystem.Instance.UpgradeCost}G";
    }

    void OnUpgradeClicked()
    {
        if (TapDamageSystem.Instance != null && TapDamageSystem.Instance.UpgradeTapDamage())
            UpdateTapInfo();
    }

    GameObject CreateUIObj(string name, Transform parent)
    {
        var obj = new GameObject(name, typeof(RectTransform));
        obj.transform.SetParent(parent, false);
        return obj;
    }

    void OnDestroy()
    {
        if (GoldManager.Instance != null)
            GoldManager.Instance.OnGoldChanged -= UpdateGoldDisplay;
    }
}
