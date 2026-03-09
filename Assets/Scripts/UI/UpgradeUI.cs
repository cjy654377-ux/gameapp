using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class UpgradeUI : MonoBehaviour
{
    Canvas canvas;
    GameObject panel;
    Button toggleButton;
    TextMeshProUGUI toggleText;

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
        scaler.referenceResolution = new Vector2(1080, 1920);
        scaler.matchWidthOrHeight = 0f;

        gameObject.AddComponent<GraphicRaycaster>();
    }

    void CreateToggleButton()
    {
        var obj = MakeUI("ToggleBtn", canvas.transform);
        var img = obj.AddComponent<Image>();
        img.color = new Color(0.2f, 0.4f, 0.7f, 0.9f);
        toggleButton = obj.AddComponent<Button>();
        toggleButton.targetGraphic = img;
        toggleButton.onClick.AddListener(TogglePanel);

        var rt = obj.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0f, 0f);
        rt.anchorMax = new Vector2(0f, 0f);
        rt.pivot = new Vector2(0f, 0f);
        rt.anchoredPosition = new Vector2(20, 20);
        rt.sizeDelta = new Vector2(100, 40);

        var textObj = MakeUI("Text", obj.transform);
        toggleText = textObj.AddComponent<TextMeshProUGUI>();
        toggleText.text = "UPGRADE";
        toggleText.fontSize = 18;
        toggleText.alignment = TextAlignmentOptions.Center;
        toggleText.color = Color.white;
        toggleText.fontStyle = FontStyles.Bold;
        var trt = textObj.GetComponent<RectTransform>();
        trt.anchorMin = Vector2.zero;
        trt.anchorMax = Vector2.one;
        trt.sizeDelta = Vector2.zero;
    }

    void CreatePanel()
    {
        panel = MakeUI("UpgradePanel", canvas.transform);
        var panelImg = panel.AddComponent<Image>();
        panelImg.color = new Color(0.05f, 0.05f, 0.1f, 0.9f);

        var prt = panel.GetComponent<RectTransform>();
        prt.anchorMin = new Vector2(0f, 0f);
        prt.anchorMax = new Vector2(1f, 0.35f);
        prt.offsetMin = new Vector2(10, 70);
        prt.offsetMax = new Vector2(-10, 0);

        float y = -20f;
        CreateUpgradeRow(panel.transform, "HP", ref hpText, ref hpBtn, y, () => UpgradeManager.Instance?.UpgradeHp());
        y -= 60f;
        CreateUpgradeRow(panel.transform, "ATK", ref atkText, ref atkBtn, y, () => UpgradeManager.Instance?.UpgradeAtk());
        y -= 60f;
        CreateUpgradeRow(panel.transform, "DEF", ref defText, ref defBtn, y, () => UpgradeManager.Instance?.UpgradeDef());
        y -= 60f;
        CreateUpgradeRow(panel.transform, "SPD", ref spdText, ref spdBtn, y, () => UpgradeManager.Instance?.UpgradeSpeed());

        RefreshUI();
    }

    void CreateUpgradeRow(Transform parent, string label, ref TextMeshProUGUI infoText, ref Button btn, float yPos, UnityEngine.Events.UnityAction onClick)
    {
        // Info text
        var infoObj = MakeUI($"{label}Info", parent);
        infoText = infoObj.AddComponent<TextMeshProUGUI>();
        infoText.fontSize = 20;
        infoText.alignment = TextAlignmentOptions.MidlineLeft;
        infoText.color = Color.white;
        var irt = infoObj.GetComponent<RectTransform>();
        irt.anchorMin = new Vector2(0, 1);
        irt.anchorMax = new Vector2(0.65f, 1);
        irt.pivot = new Vector2(0, 1);
        irt.anchoredPosition = new Vector2(20, yPos);
        irt.sizeDelta = new Vector2(0, 50);

        // Button
        var btnObj = MakeUI($"{label}Btn", parent);
        var btnImg = btnObj.AddComponent<Image>();
        btnImg.color = new Color(0.3f, 0.6f, 0.2f);
        btn = btnObj.AddComponent<Button>();
        btn.targetGraphic = btnImg;
        btn.onClick.AddListener(onClick);

        var brt = btnObj.GetComponent<RectTransform>();
        brt.anchorMin = new Vector2(0.7f, 1);
        brt.anchorMax = new Vector2(0.95f, 1);
        brt.pivot = new Vector2(0.5f, 1);
        brt.anchoredPosition = new Vector2(0, yPos);
        brt.sizeDelta = new Vector2(0, 45);

        var costObj = MakeUI("Cost", btnObj.transform);
        var costText = costObj.AddComponent<TextMeshProUGUI>();
        costText.text = "UP";
        costText.fontSize = 18;
        costText.alignment = TextAlignmentOptions.Center;
        costText.color = Color.white;
        costText.fontStyle = FontStyles.Bold;
        var crt = costObj.GetComponent<RectTransform>();
        crt.anchorMin = Vector2.zero;
        crt.anchorMax = Vector2.one;
        crt.sizeDelta = Vector2.zero;
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

        hpText.text = $"HP  Lv.{um.HpLevel}  (+{um.GetHpBonus():F0})";
        atkText.text = $"ATK  Lv.{um.AtkLevel}  (+{um.GetAtkBonus():F0})";
        defText.text = $"DEF  Lv.{um.DefLevel}  (+{um.GetDefBonus():F1})";
        spdText.text = $"SPD  Lv.{um.SpeedLevel}  (+{um.GetSpeedBonus():F1})";

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
        btn.GetComponent<Image>().color = canAfford
            ? new Color(0.3f, 0.6f, 0.2f)
            : new Color(0.4f, 0.4f, 0.4f);
    }

    GameObject MakeUI(string name, Transform parent)
    {
        var obj = new GameObject(name, typeof(RectTransform));
        obj.transform.SetParent(parent, false);
        return obj;
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
