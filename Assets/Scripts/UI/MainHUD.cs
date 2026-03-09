using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class MainHUD : MonoBehaviour
{
    public static MainHUD Instance { get; private set; }

    Canvas canvas;

    // Top bar
    TextMeshProUGUI playerNameText;
    TextMeshProUGUI goldText;
    TextMeshProUGUI gemText;
    TextMeshProUGUI stageText;
    TextMeshProUGUI powerText;
    Image progressBarFill;
    TextMeshProUGUI progressText;

    // Bottom tabs
    GameObject tabPanel;
    readonly string[] tabNames = { "훈련", "영웅", "편성", "소환", "상점" };
    readonly Button[] tabButtons = new Button[5];

    // Overlay panels (shown when tab is pressed)
    readonly GameObject[] tabPanels = new GameObject[5];
    int activeTab = -1;

    // Defeat overlay
    GameObject defeatPanel;
    Button retryButton;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        CreateCanvas();
        CreateTopBar();
        CreateStageBar();
        CreateBottomTabBar();
        CreateDefeatPanel();
        CreateTabPanels();
    }

    void Start()
    {
        if (GoldManager.Instance != null)
            GoldManager.Instance.OnGoldChanged += OnGoldChanged;

        if (StageManager.Instance != null)
            StageManager.Instance.OnStageChanged += OnStageChanged;

        if (BattleManager.Instance != null)
            BattleManager.Instance.OnBattleStateChanged += OnBattleStateChanged;

        UpdateGold(GoldManager.Instance != null ? GoldManager.Instance.Gold : 0);
        UpdateGem(0);
        UpdatePower();

        if (StageManager.Instance != null)
            stageText.text = StageManager.Instance.GetStageText();
    }

    // ── Canvas ──
    void CreateCanvas()
    {
        canvas = gameObject.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvas.sortingOrder = 100;

        var scaler = gameObject.AddComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = new Vector2(1080, 1920);
        scaler.matchWidthOrHeight = 0f;

        gameObject.AddComponent<GraphicRaycaster>();
    }

    // ── Top Bar: Profile, Gold, Gem ──
    void CreateTopBar()
    {
        // Background strip
        var topBg = MakeUI("TopBar", canvas.transform);
        var topImg = topBg.AddComponent<Image>();
        topImg.color = new Color(0.08f, 0.06f, 0.12f, 0.85f);
        SetAnchors(topBg, new Vector2(0, 1), new Vector2(1, 1), new Vector2(0, 1));
        topBg.GetComponent<RectTransform>().sizeDelta = new Vector2(0, 90);

        // Profile circle placeholder
        var profile = MakeUI("Profile", topBg.transform);
        var profileImg = profile.AddComponent<Image>();
        profileImg.color = new Color(0.3f, 0.3f, 0.35f);
        var prt = profile.GetComponent<RectTransform>();
        prt.anchorMin = new Vector2(0, 0.5f);
        prt.anchorMax = new Vector2(0, 0.5f);
        prt.pivot = new Vector2(0, 0.5f);
        prt.anchoredPosition = new Vector2(15, 0);
        prt.sizeDelta = new Vector2(65, 65);

        // Player name
        playerNameText = MakeText("PlayerName", topBg.transform, "Player", 22, TextAlignmentOptions.MidlineLeft);
        var nrt = playerNameText.GetComponent<RectTransform>();
        nrt.anchorMin = new Vector2(0, 0.5f);
        nrt.anchorMax = new Vector2(0, 0.5f);
        nrt.pivot = new Vector2(0, 0.5f);
        nrt.anchoredPosition = new Vector2(90, 10);
        nrt.sizeDelta = new Vector2(200, 30);

        // Gold display
        var goldBg = MakeUI("GoldBg", topBg.transform);
        var goldBgImg = goldBg.AddComponent<Image>();
        goldBgImg.color = new Color(0.15f, 0.12f, 0.08f, 0.8f);
        var grt = goldBg.GetComponent<RectTransform>();
        grt.anchorMin = new Vector2(0.45f, 0.5f);
        grt.anchorMax = new Vector2(0.45f, 0.5f);
        grt.pivot = new Vector2(0.5f, 0.5f);
        grt.anchoredPosition = Vector2.zero;
        grt.sizeDelta = new Vector2(180, 40);

        goldText = MakeText("GoldText", goldBg.transform, "0", 22, TextAlignmentOptions.Center);
        goldText.color = new Color(1f, 0.85f, 0.2f);
        goldText.fontStyle = FontStyles.Bold;
        FillParent(goldText.GetComponent<RectTransform>());

        // Gem display
        var gemBg = MakeUI("GemBg", topBg.transform);
        var gemBgImg = gemBg.AddComponent<Image>();
        gemBgImg.color = new Color(0.08f, 0.1f, 0.18f, 0.8f);
        var ert = gemBg.GetComponent<RectTransform>();
        ert.anchorMin = new Vector2(0.72f, 0.5f);
        ert.anchorMax = new Vector2(0.72f, 0.5f);
        ert.pivot = new Vector2(0.5f, 0.5f);
        ert.anchoredPosition = Vector2.zero;
        ert.sizeDelta = new Vector2(160, 40);

        gemText = MakeText("GemText", gemBg.transform, "0", 22, TextAlignmentOptions.Center);
        gemText.color = new Color(0.4f, 0.8f, 1f);
        gemText.fontStyle = FontStyles.Bold;
        FillParent(gemText.GetComponent<RectTransform>());
    }

    // ── Stage Bar: Power, Stage, Progress ──
    void CreateStageBar()
    {
        var bar = MakeUI("StageBar", canvas.transform);
        var barImg = bar.AddComponent<Image>();
        barImg.color = new Color(0.06f, 0.05f, 0.1f, 0.75f);
        SetAnchors(bar, new Vector2(0, 1), new Vector2(1, 1), new Vector2(0, 1));
        bar.GetComponent<RectTransform>().anchoredPosition = new Vector2(0, -90);
        bar.GetComponent<RectTransform>().sizeDelta = new Vector2(0, 50);

        // Power
        powerText = MakeText("Power", bar.transform, "Power: 0", 18, TextAlignmentOptions.MidlineLeft);
        powerText.color = new Color(0.9f, 0.7f, 0.3f);
        var pwrt = powerText.GetComponent<RectTransform>();
        pwrt.anchorMin = new Vector2(0, 0);
        pwrt.anchorMax = new Vector2(0.25f, 1);
        pwrt.offsetMin = new Vector2(15, 0);
        pwrt.offsetMax = Vector2.zero;

        // Stage text
        stageText = MakeText("Stage", bar.transform, "1-1", 22, TextAlignmentOptions.Center);
        stageText.color = Color.white;
        stageText.fontStyle = FontStyles.Bold;
        var srt = stageText.GetComponent<RectTransform>();
        srt.anchorMin = new Vector2(0.25f, 0);
        srt.anchorMax = new Vector2(0.55f, 1);
        srt.offsetMin = Vector2.zero;
        srt.offsetMax = Vector2.zero;

        // Progress bar bg
        var progBg = MakeUI("ProgBg", bar.transform);
        var progBgImg = progBg.AddComponent<Image>();
        progBgImg.color = new Color(0.15f, 0.15f, 0.2f);
        var pbrt = progBg.GetComponent<RectTransform>();
        pbrt.anchorMin = new Vector2(0.58f, 0.25f);
        pbrt.anchorMax = new Vector2(0.95f, 0.75f);
        pbrt.offsetMin = Vector2.zero;
        pbrt.offsetMax = Vector2.zero;

        // Progress fill
        var progFill = MakeUI("ProgFill", progBg.transform);
        progressBarFill = progFill.AddComponent<Image>();
        progressBarFill.color = new Color(0.3f, 0.8f, 0.3f);
        var pfrt = progFill.GetComponent<RectTransform>();
        pfrt.anchorMin = Vector2.zero;
        pfrt.anchorMax = new Vector2(0, 1);
        pfrt.pivot = new Vector2(0, 0.5f);
        pfrt.offsetMin = Vector2.zero;
        pfrt.offsetMax = Vector2.zero;
        pfrt.sizeDelta = new Vector2(0, 0);

        // Progress text overlay
        progressText = MakeText("ProgText", progBg.transform, "0/10", 16, TextAlignmentOptions.Center);
        FillParent(progressText.GetComponent<RectTransform>());
    }

    // ── Bottom Tab Bar ──
    void CreateBottomTabBar()
    {
        tabPanel = MakeUI("TabBar", canvas.transform);
        var tabImg = tabPanel.AddComponent<Image>();
        tabImg.color = new Color(0.08f, 0.06f, 0.12f, 0.92f);
        SetAnchors(tabPanel, new Vector2(0, 0), new Vector2(1, 0), new Vector2(0, 0));
        tabPanel.GetComponent<RectTransform>().sizeDelta = new Vector2(0, 120);

        for (int i = 0; i < 5; i++)
        {
            int idx = i;
            var btn = MakeUI($"Tab_{tabNames[i]}", tabPanel.transform);
            var btnImg = btn.AddComponent<Image>();
            btnImg.color = new Color(0.15f, 0.12f, 0.2f, 0.9f);
            tabButtons[i] = btn.AddComponent<Button>();
            tabButtons[i].targetGraphic = btnImg;
            tabButtons[i].onClick.AddListener(() => OnTabClicked(idx));

            var brt = btn.GetComponent<RectTransform>();
            float xMin = i * 0.2f;
            float xMax = (i + 1) * 0.2f;
            brt.anchorMin = new Vector2(xMin + 0.005f, 0.05f);
            brt.anchorMax = new Vector2(xMax - 0.005f, 0.95f);
            brt.offsetMin = Vector2.zero;
            brt.offsetMax = Vector2.zero;

            // Icon placeholder (circle)
            var icon = MakeUI("Icon", btn.transform);
            var iconImg = icon.AddComponent<Image>();
            iconImg.color = new Color(0.4f, 0.35f, 0.5f);
            var irt = icon.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0.5f, 0.55f);
            irt.anchorMax = new Vector2(0.5f, 0.55f);
            irt.pivot = new Vector2(0.5f, 0.5f);
            irt.sizeDelta = new Vector2(50, 50);

            // Label
            var label = MakeText("Label", btn.transform, tabNames[i], 18, TextAlignmentOptions.Center);
            label.color = new Color(0.7f, 0.7f, 0.8f);
            var lrt = label.GetComponent<RectTransform>();
            lrt.anchorMin = new Vector2(0, 0);
            lrt.anchorMax = new Vector2(1, 0.35f);
            lrt.offsetMin = Vector2.zero;
            lrt.offsetMax = Vector2.zero;
        }
    }

    // ── Tab Overlay Panels (empty for now) ──
    void CreateTabPanels()
    {
        for (int i = 0; i < 5; i++)
        {
            var panel = MakeUI($"Panel_{tabNames[i]}", canvas.transform);
            var panelImg = panel.AddComponent<Image>();
            panelImg.color = new Color(0.05f, 0.04f, 0.08f, 0.95f);

            var prt = panel.GetComponent<RectTransform>();
            prt.anchorMin = new Vector2(0, 0.07f);  // above tab bar
            prt.anchorMax = new Vector2(1, 0.85f);   // below top bars
            prt.offsetMin = Vector2.zero;
            prt.offsetMax = Vector2.zero;

            // Title
            var title = MakeText("Title", panel.transform, tabNames[i], 32, TextAlignmentOptions.Center);
            title.fontStyle = FontStyles.Bold;
            var trt = title.GetComponent<RectTransform>();
            trt.anchorMin = new Vector2(0, 0.9f);
            trt.anchorMax = new Vector2(1, 1);
            trt.offsetMin = Vector2.zero;
            trt.offsetMax = Vector2.zero;

            // Close button
            var closeBtn = MakeUI("Close", panel.transform);
            var closeImg = closeBtn.AddComponent<Image>();
            closeImg.color = new Color(0.6f, 0.2f, 0.2f);
            var cb = closeBtn.AddComponent<Button>();
            cb.targetGraphic = closeImg;
            cb.onClick.AddListener(ClosePanel);
            var crt = closeBtn.GetComponent<RectTransform>();
            crt.anchorMin = new Vector2(1, 1);
            crt.anchorMax = new Vector2(1, 1);
            crt.pivot = new Vector2(1, 1);
            crt.anchoredPosition = new Vector2(-10, -10);
            crt.sizeDelta = new Vector2(50, 50);

            var xText = MakeText("X", closeBtn.transform, "X", 24, TextAlignmentOptions.Center);
            xText.fontStyle = FontStyles.Bold;
            FillParent(xText.GetComponent<RectTransform>());

            // "Coming Soon" placeholder
            var soon = MakeText("Soon", panel.transform, "준비 중...", 24, TextAlignmentOptions.Center);
            soon.color = new Color(0.5f, 0.5f, 0.6f);
            var soort = soon.GetComponent<RectTransform>();
            soort.anchorMin = new Vector2(0, 0.4f);
            soort.anchorMax = new Vector2(1, 0.6f);
            soort.offsetMin = Vector2.zero;
            soort.offsetMax = Vector2.zero;

            tabPanels[i] = panel;
            panel.SetActive(false);
        }
    }

    // ── Defeat Panel ──
    void CreateDefeatPanel()
    {
        defeatPanel = MakeUI("DefeatPanel", canvas.transform);
        var overlay = defeatPanel.AddComponent<Image>();
        overlay.color = new Color(0, 0, 0, 0.7f);
        FillParent(defeatPanel.GetComponent<RectTransform>());

        var title = MakeText("DefeatText", defeatPanel.transform, "DEFEAT", 72, TextAlignmentOptions.Center);
        title.color = new Color(0.8f, 0.2f, 0.2f);
        title.fontStyle = FontStyles.Bold;
        var trt = title.GetComponent<RectTransform>();
        trt.anchorMin = new Vector2(0.5f, 0.55f);
        trt.anchorMax = new Vector2(0.5f, 0.55f);
        trt.sizeDelta = new Vector2(600, 100);

        var btnObj = MakeUI("RetryBtn", defeatPanel.transform);
        var btnImg = btnObj.AddComponent<Image>();
        btnImg.color = new Color(0.3f, 0.5f, 0.8f);
        retryButton = btnObj.AddComponent<Button>();
        retryButton.targetGraphic = btnImg;
        retryButton.onClick.AddListener(() =>
            UnityEngine.SceneManagement.SceneManager.LoadScene(
                UnityEngine.SceneManagement.SceneManager.GetActiveScene().buildIndex));

        var brt = btnObj.GetComponent<RectTransform>();
        brt.anchorMin = new Vector2(0.5f, 0.4f);
        brt.anchorMax = new Vector2(0.5f, 0.4f);
        brt.sizeDelta = new Vector2(250, 70);

        var btnText = MakeText("BtnText", btnObj.transform, "RETRY", 30, TextAlignmentOptions.Center);
        btnText.fontStyle = FontStyles.Bold;
        FillParent(btnText.GetComponent<RectTransform>());

        defeatPanel.SetActive(false);
    }

    // ── Events ──
    void OnGoldChanged(int gold) => UpdateGold(gold);

    void OnStageChanged(int area, int stage, int wave)
    {
        if (StageManager.Instance != null)
            stageText.text = StageManager.Instance.GetStageText();
        UpdateProgress(wave);
        UpdatePower();
    }

    void OnBattleStateChanged(BattleManager.BattleState state)
    {
        if (state == BattleManager.BattleState.Defeat)
            defeatPanel.SetActive(true);
    }

    void OnTabClicked(int idx)
    {
        if (activeTab == idx)
        {
            ClosePanel();
            return;
        }

        ClosePanel();
        activeTab = idx;
        tabPanels[idx].SetActive(true);
        HighlightTab(idx);
    }

    void ClosePanel()
    {
        if (activeTab >= 0)
            tabPanels[activeTab].SetActive(false);
        activeTab = -1;
        HighlightTab(-1);
    }

    void HighlightTab(int idx)
    {
        for (int i = 0; i < 5; i++)
        {
            var img = tabButtons[i].GetComponent<Image>();
            img.color = (i == idx)
                ? new Color(0.3f, 0.25f, 0.45f, 0.95f)
                : new Color(0.15f, 0.12f, 0.2f, 0.9f);
        }
    }

    // ── Updates ──
    void UpdateGold(int gold) { if (goldText != null) goldText.text = FormatNumber(gold); }
    void UpdateGem(int gem) { if (gemText != null) gemText.text = FormatNumber(gem); }

    void UpdateProgress(int wave)
    {
        int total = StageManager.Instance != null ? StageManager.Instance.wavesPerStage : 10;
        if (progressBarFill != null)
        {
            var rt = progressBarFill.GetComponent<RectTransform>();
            rt.anchorMax = new Vector2((float)wave / total, 1);
        }
        if (progressText != null)
            progressText.text = $"{wave}/{total}";
    }

    void UpdatePower()
    {
        if (powerText == null) return;
        float totalAtk = 0;
        if (BattleManager.Instance != null)
        {
            var allies = BattleManager.Instance.allyUnits;
            for (int i = 0; i < allies.Count; i++)
                if (allies[i] != null && !allies[i].IsDead)
                    totalAtk += allies[i].atk;
        }
        powerText.text = $"Power {FormatNumber(Mathf.RoundToInt(totalAtk))}";
    }

    static string FormatNumber(int n)
    {
        if (n >= 1000000) return (n / 1000000f).ToString("F1") + "M";
        if (n >= 1000) return (n / 1000f).ToString("F1") + "K";
        return n.ToString();
    }

    // ── Helpers ──
    GameObject MakeUI(string name, Transform parent)
    {
        var obj = new GameObject(name, typeof(RectTransform));
        obj.transform.SetParent(parent, false);
        return obj;
    }

    TextMeshProUGUI MakeText(string name, Transform parent, string text, float size, TextAlignmentOptions align)
    {
        var obj = MakeUI(name, parent);
        var tmp = obj.AddComponent<TextMeshProUGUI>();
        tmp.text = text;
        tmp.fontSize = size;
        tmp.alignment = align;
        tmp.color = Color.white;
        return tmp;
    }

    void SetAnchors(GameObject obj, Vector2 anchorMin, Vector2 anchorMax, Vector2 pivot)
    {
        var rt = obj.GetComponent<RectTransform>();
        rt.anchorMin = anchorMin;
        rt.anchorMax = anchorMax;
        rt.pivot = pivot;
        rt.anchoredPosition = Vector2.zero;
    }

    void FillParent(RectTransform rt)
    {
        rt.anchorMin = Vector2.zero;
        rt.anchorMax = Vector2.one;
        rt.offsetMin = Vector2.zero;
        rt.offsetMax = Vector2.zero;
    }

    void OnDestroy()
    {
        if (GoldManager.Instance != null)
            GoldManager.Instance.OnGoldChanged -= OnGoldChanged;
        if (StageManager.Instance != null)
            StageManager.Instance.OnStageChanged -= OnStageChanged;
        if (BattleManager.Instance != null)
            BattleManager.Instance.OnBattleStateChanged -= OnBattleStateChanged;
    }
}
