using UnityEngine;
using UnityEngine.UI;
using TMPro;

/// <summary>
/// Battle Cats 스타일 메인 HUD (UI_SPEC.md 기반)
/// 상단: HUD 바 (아바타/스테이지/코인/다이아)
/// 하단: 네비게이션 바 (훈련/영웅/편성/소환/상점)
/// 오버레이: 탭 패널, 패배 패널
/// </summary>
public class MainHUD : MonoBehaviour
{
    public static MainHUD Instance { get; private set; }

    Canvas canvas;
    GameObject safeAreaRoot;

    // HUD Bar
    TextMeshProUGUI goldText;
    TextMeshProUGUI gemText;
    TextMeshProUGUI stageText;
    TextMeshProUGUI powerText;
    Image progressBarFill;
    TextMeshProUGUI progressText;
    Image avatarImg;

    // Bottom Nav
    readonly string[] tabNames = { "훈련", "영웅", "편성", "소환", "상점" };
    readonly Button[] tabButtons = new Button[5];
    readonly Image[] tabIndicators = new Image[5];
    readonly TextMeshProUGUI[] tabLabels = new TextMeshProUGUI[5];

    // Tab overlay panels
    readonly GameObject[] tabPanels = new GameObject[5];
    int activeTab = -1;

    // Defeat
    GameObject defeatPanel;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        BuildUI();
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
        if (StageManager.Instance != null && stageText != null)
            stageText.text = StageManager.Instance.GetStageText();
    }

    // ════════════════════════════════════════
    // BUILD
    // ════════════════════════════════════════

    void BuildUI()
    {
        CreateCanvas();
        CreateSafeAreaRoot();
        CreateHUDBar();
        CreateBottomNavBar();
        CreateTabPanels();
        CreateDefeatPanel();
    }

    void CreateCanvas()
    {
        canvas = gameObject.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvas.sortingOrder = 100;

        var scaler = gameObject.AddComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = UIConstants.ReferenceResolution;
        scaler.matchWidthOrHeight = UIConstants.MatchWidthOrHeight;

        gameObject.AddComponent<GraphicRaycaster>();
    }

    void CreateSafeAreaRoot()
    {
        safeAreaRoot = UIHelper.MakeUI("SafeAreaRoot", canvas.transform);
        safeAreaRoot.AddComponent<SafeAreaAdapter>();
        UIHelper.FillParent(safeAreaRoot.GetComponent<RectTransform>());
    }

    // ── HUD Bar (상단) ──
    void CreateHUDBar()
    {
        var hudBar = UIHelper.MakeUI("HUDBar", safeAreaRoot.transform);
        var hudImg = hudBar.AddComponent<Image>();
        hudImg.color = UIColors.Background_Dark;
        UIHelper.SetAnchors(hudBar, new Vector2(0, 1), new Vector2(1, 1), new Vector2(0.5f, 1));
        hudBar.GetComponent<RectTransform>().sizeDelta = new Vector2(0, UIConstants.HUD_Height);

        // Avatar
        var avatar = UIHelper.MakeUI("Avatar", hudBar.transform);
        avatarImg = avatar.AddComponent<Image>();
        avatarImg.color = UIColors.Panel_Inner;
        var avOutline = avatar.AddComponent<Outline>();
        avOutline.effectColor = UIColors.Panel_Border;
        avOutline.effectDistance = new Vector2(UIConstants.HUD_AvatarBorder, UIConstants.HUD_AvatarBorder);
        var art = avatar.GetComponent<RectTransform>();
        art.anchorMin = new Vector2(0, 0.5f);
        art.anchorMax = new Vector2(0, 0.5f);
        art.pivot = new Vector2(0, 0.5f);
        art.anchoredPosition = new Vector2(UIConstants.Spacing_Medium, 0);
        art.sizeDelta = new Vector2(UIConstants.HUD_AvatarSize, UIConstants.HUD_AvatarSize);

        // Stage text (center)
        float stageX = UIConstants.Spacing_Medium + UIConstants.HUD_AvatarSize + UIConstants.Spacing_Medium;
        stageText = UIHelper.MakeText("Stage", hudBar.transform, "1-1",
            UIConstants.Font_HeaderMedium, TextAlignmentOptions.MidlineLeft);
        stageText.fontStyle = FontStyles.Bold;
        var srt = stageText.GetComponent<RectTransform>();
        srt.anchorMin = new Vector2(0, 0);
        srt.anchorMax = new Vector2(0.35f, 0.55f);
        srt.offsetMin = new Vector2(stageX, 0);
        srt.offsetMax = Vector2.zero;

        // Progress bar (under stage text)
        var progBg = UIHelper.MakePanel("ProgBG", hudBar.transform, UIColors.ProgressBar_BG);
        var prt = progBg.GetComponent<RectTransform>();
        prt.anchorMin = new Vector2(0, 0);
        prt.anchorMax = new Vector2(0.35f, 0);
        prt.pivot = new Vector2(0, 0);
        prt.anchoredPosition = new Vector2(stageX, UIConstants.Spacing_Small + 2);
        prt.sizeDelta = new Vector2(0, UIConstants.HUD_ProgressHeight);
        // stretch width via anchors
        prt.anchorMin = new Vector2(0, 0.08f);
        prt.anchorMax = new Vector2(0.35f, 0.08f + UIConstants.HUD_ProgressHeight / UIConstants.HUD_Height);
        prt.offsetMin = new Vector2(stageX, 0);
        prt.offsetMax = Vector2.zero;

        var progFillObj = UIHelper.MakeUI("ProgFill", progBg.transform);
        progressBarFill = progFillObj.AddComponent<Image>();
        progressBarFill.color = UIColors.ProgressBar_Fill;
        var pfrt = progFillObj.GetComponent<RectTransform>();
        pfrt.anchorMin = Vector2.zero;
        pfrt.anchorMax = new Vector2(0.1f, 1);
        pfrt.offsetMin = Vector2.zero;
        pfrt.offsetMax = Vector2.zero;

        progressText = UIHelper.MakeText("ProgText", progBg.transform, "1/10",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center);
        UIHelper.FillParent(progressText.GetComponent<RectTransform>());

        // Power (left of coins)
        powerText = UIHelper.MakeText("Power", hudBar.transform, "0",
            UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineRight, UIColors.Text_Secondary);
        var pwrt = powerText.GetComponent<RectTransform>();
        pwrt.anchorMin = new Vector2(0.36f, 0);
        pwrt.anchorMax = new Vector2(0.50f, 1);
        pwrt.offsetMin = Vector2.zero;
        pwrt.offsetMax = Vector2.zero;

        // Gold
        var goldBg = UIHelper.MakePanel("GoldBG", hudBar.transform, UIColors.Panel_Inner);
        var grt = goldBg.GetComponent<RectTransform>();
        grt.anchorMin = new Vector2(0.52f, 0.15f);
        grt.anchorMax = new Vector2(0.74f, 0.85f);
        grt.offsetMin = Vector2.zero;
        grt.offsetMax = Vector2.zero;

        goldText = UIHelper.MakeText("GoldText", goldBg.transform, "0",
            UIConstants.Font_HUDResource, TextAlignmentOptions.Center, UIColors.Text_Gold);
        goldText.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(goldText.GetComponent<RectTransform>());

        // Gem
        var gemBg = UIHelper.MakePanel("GemBG", hudBar.transform, UIColors.Panel_Inner);
        var ert = gemBg.GetComponent<RectTransform>();
        ert.anchorMin = new Vector2(0.76f, 0.15f);
        ert.anchorMax = new Vector2(0.98f, 0.85f);
        ert.offsetMin = Vector2.zero;
        ert.offsetMax = Vector2.zero;

        gemText = UIHelper.MakeText("GemText", gemBg.transform, "0",
            UIConstants.Font_HUDResource, TextAlignmentOptions.Center, UIColors.Text_Diamond);
        gemText.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(gemText.GetComponent<RectTransform>());
    }

    // ── Bottom Nav Bar (하단) ──
    void CreateBottomNavBar()
    {
        var navBar = UIHelper.MakeUI("NavBar", safeAreaRoot.transform);
        var navImg = navBar.AddComponent<Image>();
        navImg.color = UIColors.Background_Dark;
        UIHelper.SetAnchors(navBar, new Vector2(0, 0), new Vector2(1, 0), new Vector2(0.5f, 0));
        navBar.GetComponent<RectTransform>().sizeDelta = new Vector2(0, UIConstants.NavBar_Height);

        // Top border line
        var borderLine = UIHelper.MakePanel("Border", navBar.transform, UIColors.Panel_Border);
        var brt = borderLine.GetComponent<RectTransform>();
        brt.anchorMin = new Vector2(0, 1);
        brt.anchorMax = new Vector2(1, 1);
        brt.pivot = new Vector2(0.5f, 1);
        brt.sizeDelta = new Vector2(0, UIConstants.NavBar_BorderTop);

        for (int i = 0; i < 5; i++)
        {
            int idx = i;
            float xMin = i * 0.2f;
            float xMax = (i + 1) * 0.2f;

            var tabObj = UIHelper.MakeUI($"Tab_{tabNames[i]}", navBar.transform);
            var tabImg = tabObj.AddComponent<Image>();
            tabImg.color = UIColors.Tab_Inactive;
            tabButtons[i] = tabObj.AddComponent<Button>();
            tabButtons[i].targetGraphic = tabImg;
            tabButtons[i].onClick.AddListener(() => OnTabClicked(idx));

            var trt = tabObj.GetComponent<RectTransform>();
            trt.anchorMin = new Vector2(xMin, 0);
            trt.anchorMax = new Vector2(xMax, 1);
            trt.offsetMin = new Vector2(1, 0);
            trt.offsetMax = new Vector2(-1, -UIConstants.NavBar_BorderTop);

            // Active indicator (top line)
            var indicator = UIHelper.MakePanel("Indicator", tabObj.transform, UIColors.Button_Yellow);
            var irt = indicator.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0.1f, 1);
            irt.anchorMax = new Vector2(0.9f, 1);
            irt.pivot = new Vector2(0.5f, 1);
            irt.sizeDelta = new Vector2(0, 2);
            indicator.gameObject.SetActive(false);
            tabIndicators[i] = indicator;

            // Icon placeholder
            var icon = UIHelper.MakePanel("Icon", tabObj.transform, UIColors.Panel_Border);
            var icrt = icon.GetComponent<RectTransform>();
            icrt.anchorMin = new Vector2(0.5f, 0.5f);
            icrt.anchorMax = new Vector2(0.5f, 0.5f);
            icrt.pivot = new Vector2(0.5f, 0.4f);
            icrt.sizeDelta = new Vector2(UIConstants.NavBar_IconSize, UIConstants.NavBar_IconSize);

            // Label
            tabLabels[i] = UIHelper.MakeText("Label", tabObj.transform, tabNames[i],
                UIConstants.Font_NavLabel, TextAlignmentOptions.Bottom, UIColors.Text_Disabled);
            var lrt = tabLabels[i].GetComponent<RectTransform>();
            lrt.anchorMin = new Vector2(0, 0);
            lrt.anchorMax = new Vector2(1, 0.3f);
            lrt.offsetMin = Vector2.zero;
            lrt.offsetMax = Vector2.zero;
        }
    }

    // ── Tab Overlay Panels ──
    void CreateTabPanels()
    {
        for (int i = 0; i < 5; i++)
        {
            var panel = UIHelper.MakeUI($"Panel_{tabNames[i]}", safeAreaRoot.transform);
            var panelImg = panel.AddComponent<Image>();
            panelImg.color = UIColors.Background_Panel;

            // Panel position: above nav bar, below HUD
            var prt = panel.GetComponent<RectTransform>();
            float refH = UIConstants.ReferenceResolution.y;
            float navRatio = UIConstants.NavBar_Height / refH;
            float hudRatio = UIConstants.HUD_Height / refH;
            prt.anchorMin = new Vector2(0, navRatio);
            prt.anchorMax = new Vector2(1, 1f - hudRatio);
            prt.offsetMin = Vector2.zero;
            prt.offsetMax = Vector2.zero;

            // Border
            var panelOutline = panel.AddComponent<Outline>();
            panelOutline.effectColor = UIColors.Panel_Border;
            panelOutline.effectDistance = new Vector2(UIConstants.Panel_BorderWidth, UIConstants.Panel_BorderWidth);

            // Header bar
            var header = UIHelper.MakePanel("Header", panel.transform, UIColors.Background_Dark);
            var hrt = header.GetComponent<RectTransform>();
            hrt.anchorMin = new Vector2(0, 1);
            hrt.anchorMax = new Vector2(1, 1);
            hrt.pivot = new Vector2(0.5f, 1);
            hrt.sizeDelta = new Vector2(0, UIConstants.Tab_Height);

            // Title
            var title = UIHelper.MakeText("Title", header.transform, tabNames[i],
                UIConstants.Font_HeaderMedium, TextAlignmentOptions.Center);
            title.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(title.GetComponent<RectTransform>());

            // Close button
            var (closeBtn, closeImg) = UIHelper.MakeButton("CloseBtn", header.transform,
                UIColors.Button_Brown, "X", UIConstants.Font_Button);
            closeImg.color = UIColors.Button_Brown;
            closeBtn.onClick.AddListener(ClosePanel);
            var crt = closeBtn.GetComponent<RectTransform>();
            crt.anchorMin = new Vector2(1, 0.5f);
            crt.anchorMax = new Vector2(1, 0.5f);
            crt.pivot = new Vector2(1, 0.5f);
            crt.anchoredPosition = new Vector2(-UIConstants.Spacing_Medium, 0);
            crt.sizeDelta = new Vector2(UIConstants.MinTouchTarget, UIConstants.Tab_Height - UIConstants.Spacing_Small);

            // Placeholder content
            var content = UIHelper.MakeText("Content", panel.transform, "준비 중...",
                UIConstants.Font_HeaderMedium, TextAlignmentOptions.Center, UIColors.Text_Disabled);
            var contrt = content.GetComponent<RectTransform>();
            contrt.anchorMin = new Vector2(0, 0.4f);
            contrt.anchorMax = new Vector2(1, 0.6f);
            contrt.offsetMin = Vector2.zero;
            contrt.offsetMax = Vector2.zero;

            tabPanels[i] = panel;
            panel.SetActive(false);
        }
    }

    // ── Defeat Panel ──
    void CreateDefeatPanel()
    {
        defeatPanel = UIHelper.MakeUI("DefeatPanel", canvas.transform);
        var overlay = defeatPanel.AddComponent<Image>();
        overlay.color = UIColors.Overlay_Dark;
        UIHelper.FillParent(defeatPanel.GetComponent<RectTransform>());

        // Center container
        var container = UIHelper.MakePanel("Container", defeatPanel.transform, UIColors.Panel_Inner);
        var containerOutline = container.gameObject.AddComponent<Outline>();
        containerOutline.effectColor = UIColors.Panel_Border;
        containerOutline.effectDistance = new Vector2(UIConstants.Panel_BorderWidth, UIConstants.Panel_BorderWidth);
        var conrt = container.GetComponent<RectTransform>();
        conrt.anchorMin = new Vector2(0.5f, 0.5f);
        conrt.anchorMax = new Vector2(0.5f, 0.5f);
        conrt.sizeDelta = new Vector2(280, 180);

        // DEFEAT text
        var title = UIHelper.MakeText("Title", container.transform, "DEFEAT",
            UIConstants.Font_HeaderLarge * 1.5f, TextAlignmentOptions.Center, UIColors.Defeat_Red);
        title.fontStyle = FontStyles.Bold;
        var trt = title.GetComponent<RectTransform>();
        trt.anchorMin = new Vector2(0, 0.55f);
        trt.anchorMax = new Vector2(1, 0.95f);
        trt.offsetMin = Vector2.zero;
        trt.offsetMax = Vector2.zero;

        // Retry button (Yellow CTA)
        var (retryBtn, retryImg) = UIHelper.MakeButton("RetryBtn", container.transform,
            UIColors.Button_Yellow, "RETRY", UIConstants.Font_Button);
        retryBtn.onClick.AddListener(() =>
            UnityEngine.SceneManagement.SceneManager.LoadScene(
                UnityEngine.SceneManagement.SceneManager.GetActiveScene().buildIndex));
        // Make retry button text dark for readability on yellow
        var retryLabel = retryBtn.GetComponentInChildren<TextMeshProUGUI>();
        if (retryLabel != null) retryLabel.color = UIColors.Text_TabActive;

        var rbrt = retryBtn.GetComponent<RectTransform>();
        rbrt.anchorMin = new Vector2(0.5f, 0.05f);
        rbrt.anchorMax = new Vector2(0.5f, 0.05f);
        rbrt.pivot = new Vector2(0.5f, 0);
        rbrt.sizeDelta = new Vector2(UIConstants.Button_CTAWidth, UIConstants.Button_CTAHeight);

        defeatPanel.SetActive(false);
    }

    // ════════════════════════════════════════
    // EVENTS
    // ════════════════════════════════════════

    void OnGoldChanged(int gold) => UpdateGold(gold);

    void OnStageChanged(int area, int stage, int wave)
    {
        if (StageManager.Instance != null && stageText != null)
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
        UpdateTabVisuals();
    }

    void ClosePanel()
    {
        if (activeTab >= 0)
            tabPanels[activeTab].SetActive(false);
        activeTab = -1;
        UpdateTabVisuals();
    }

    void UpdateTabVisuals()
    {
        for (int i = 0; i < 5; i++)
        {
            bool active = (i == activeTab);
            tabButtons[i].GetComponent<Image>().color = active ? UIColors.Tab_Active : UIColors.Tab_Inactive;
            tabLabels[i].color = active ? UIColors.Text_Secondary : UIColors.Text_Disabled;
            tabLabels[i].fontStyle = active ? FontStyles.Bold : FontStyles.Normal;
            tabIndicators[i].gameObject.SetActive(active);
        }
    }

    // ════════════════════════════════════════
    // UPDATES
    // ════════════════════════════════════════

    void UpdateGold(int gold)
    {
        if (goldText != null) goldText.text = UIHelper.FormatNumber(gold);
    }

    void UpdateGem(int gem)
    {
        if (gemText != null) gemText.text = UIHelper.FormatNumber(gem);
    }

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
        powerText.text = UIHelper.FormatNumber(Mathf.RoundToInt(totalAtk));
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
