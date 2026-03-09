using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections.Generic;

/// <summary>
/// Battle Cats 스타일 메인 HUD (UI_SPEC.md 기반)
/// 상단: HUD 바 (에리어명/스테이지/코인/다이아)
/// 중앙: 웨이브 배너, 킬 카운터
/// 하단: 네비게이션 바 (훈련/영웅/편성/소환/상점)
/// 오버레이: 탭 패널
/// 패배 시: 메시지 없이 이전 웨이브로 자동 복귀
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
    TextMeshProUGUI areaNameText;
    Image progressBarFill;
    TextMeshProUGUI progressText;

    // Wave Banner
    GameObject waveBanner;
    TextMeshProUGUI waveBannerText;
    CanvasGroup waveBannerCG;
    float waveBannerTimer;

    // Kill Counter
    TextMeshProUGUI killCountText;
    int killCount;

    // Bottom Nav
    readonly string[] tabNames = { "훈련", "영웅", "편성", "소환", "상점" };
    readonly string[] tabIcons = { "⚔", "★", "☰", "◆", "♦" };
    readonly Button[] tabButtons = new Button[5];
    readonly Image[] tabIndicators = new Image[5];
    readonly TextMeshProUGUI[] tabLabels = new TextMeshProUGUI[5];
    readonly TextMeshProUGUI[] tabIconTexts = new TextMeshProUGUI[5];

    // Tab overlay panels
    readonly GameObject[] tabPanels = new GameObject[5];
    int activeTab = -1;

    // 훈련 탭 업그레이드 UI
    TextMeshProUGUI tapUpText;
    Button tapUpBtn;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        BuildUI();
    }

    void Start()
    {
        if (GoldManager.Instance != null)
            GoldManager.Instance.OnGoldChanged += UpdateGold;
        if (GemManager.Instance != null)
            GemManager.Instance.OnGemChanged += UpdateGem;
        if (StageManager.Instance != null)
            StageManager.Instance.OnStageChanged += OnStageChanged;
        if (BattleManager.Instance != null)
            BattleManager.Instance.OnBattleStateChanged += OnBattleStateChanged;

        UpdateGold(GoldManager.Instance != null ? GoldManager.Instance.Gold : 0);
        UpdateGem(GemManager.Instance != null ? GemManager.Instance.Gem : 0);
        if (StageManager.Instance != null)
        {
            if (stageText != null) stageText.text = StageManager.Instance.GetStageText();
            if (areaNameText != null) areaNameText.text = StageManager.Instance.GetAreaName();
        }
    }

    void Update()
    {
        if (waveBannerTimer <= 0) return;

        waveBannerTimer -= Time.unscaledDeltaTime;
        if (waveBannerTimer <= 0.5f && waveBannerCG != null)
            waveBannerCG.alpha = waveBannerTimer / 0.5f;
        if (waveBannerTimer <= 0 && waveBanner != null)
            waveBanner.SetActive(false);
    }

    // ════════════════════════════════════════
    // BUILD
    // ════════════════════════════════════════

    void BuildUI()
    {
        CreateCanvas();
        CreateSafeAreaRoot();
        CreateHUDBar();
        CreateWaveBanner();
        CreateKillCounter();
        CreateBottomNavBar();
        CreateTabPanels();
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

        // Area name (small, top-left)
        areaNameText = UIHelper.MakeText("AreaName", hudBar.transform, "Grass Field",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.TopLeft, UIColors.Text_Secondary);
        var anrt = areaNameText.GetComponent<RectTransform>();
        anrt.anchorMin = new Vector2(0, 0.55f);
        anrt.anchorMax = new Vector2(0.40f, 1);
        anrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
        anrt.offsetMax = new Vector2(0, -UIConstants.Spacing_Small);

        // Stage text
        stageText = UIHelper.MakeText("Stage", hudBar.transform, "1-1",
            UIConstants.Font_HeaderMedium, TextAlignmentOptions.MidlineLeft);
        stageText.fontStyle = FontStyles.Bold;
        var srt = stageText.GetComponent<RectTransform>();
        srt.anchorMin = new Vector2(0, 0.05f);
        srt.anchorMax = new Vector2(0.15f, 0.55f);
        srt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
        srt.offsetMax = Vector2.zero;

        // Progress bar
        var progBg = UIHelper.MakePanel("ProgBG", hudBar.transform, UIColors.ProgressBar_BG);
        var progOutline = progBg.gameObject.AddComponent<Outline>();
        progOutline.effectColor = UIColors.ProgressBar_Border;
        progOutline.effectDistance = new Vector2(1, 1);
        var prt = progBg.GetComponent<RectTransform>();
        prt.anchorMin = new Vector2(0.16f, 0.18f);
        prt.anchorMax = new Vector2(0.40f, 0.48f);
        prt.offsetMin = Vector2.zero;
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

        // Gold
        CreateResourceDisplay(hudBar.transform, "Gold", "G",
            UIColors.Text_Gold, new Vector2(0.42f, 0.12f), new Vector2(0.70f, 0.88f),
            out goldText);

        // Gem
        CreateResourceDisplay(hudBar.transform, "Gem", "D",
            UIColors.Text_Diamond, new Vector2(0.72f, 0.12f), new Vector2(0.98f, 0.88f),
            out gemText);
    }

    void CreateResourceDisplay(Transform parent, string name, string iconChar,
        Color iconColor, Vector2 anchorMin, Vector2 anchorMax, out TextMeshProUGUI valueText)
    {
        var container = UIHelper.MakePanel($"{name}BG", parent, UIColors.Panel_Inner);
        var containerOutline = container.gameObject.AddComponent<Outline>();
        containerOutline.effectColor = UIColors.Panel_Border;
        containerOutline.effectDistance = new Vector2(1, 1);
        var crt = container.GetComponent<RectTransform>();
        crt.anchorMin = anchorMin;
        crt.anchorMax = anchorMax;
        crt.offsetMin = Vector2.zero;
        crt.offsetMax = Vector2.zero;

        // Icon circle
        var iconBg = UIHelper.MakePanel($"{name}Icon", container.transform, iconColor);
        var irt = iconBg.GetComponent<RectTransform>();
        irt.anchorMin = new Vector2(0, 0.15f);
        irt.anchorMax = new Vector2(0, 0.85f);
        irt.pivot = new Vector2(0, 0.5f);
        irt.anchoredPosition = new Vector2(UIConstants.Spacing_Small, 0);
        irt.sizeDelta = new Vector2(22, 0);

        var iconText = UIHelper.MakeText($"{name}IconText", iconBg.transform, iconChar,
            UIConstants.Font_LevelBadge, TextAlignmentOptions.Center, UIColors.Background_Dark);
        iconText.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(iconText.GetComponent<RectTransform>());

        valueText = UIHelper.MakeText($"{name}Text", container.transform, "0",
            UIConstants.Font_HUDResource, TextAlignmentOptions.Center, iconColor);
        valueText.fontStyle = FontStyles.Bold;
        var vrt = valueText.GetComponent<RectTransform>();
        vrt.anchorMin = new Vector2(0.28f, 0);
        vrt.anchorMax = new Vector2(1, 1);
        vrt.offsetMin = Vector2.zero;
        vrt.offsetMax = Vector2.zero;
    }

    // ── Wave Banner (중앙 상단) ──
    void CreateWaveBanner()
    {
        waveBanner = UIHelper.MakeUI("WaveBanner", safeAreaRoot.transform);
        waveBannerCG = waveBanner.AddComponent<CanvasGroup>();

        var bannerBg = waveBanner.AddComponent<Image>();
        bannerBg.color = new Color(0, 0, 0, 0.6f);

        var rt = waveBanner.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0.15f, 0.75f);
        rt.anchorMax = new Vector2(0.85f, 0.82f);
        rt.offsetMin = Vector2.zero;
        rt.offsetMax = Vector2.zero;

        var bannerOutline = waveBanner.AddComponent<Outline>();
        bannerOutline.effectColor = UIColors.Button_Yellow;
        bannerOutline.effectDistance = new Vector2(2, 2);

        waveBannerText = UIHelper.MakeText("BannerText", waveBanner.transform, "WAVE 1",
            UIConstants.Font_HeaderLarge, TextAlignmentOptions.Center, UIColors.Button_Yellow);
        waveBannerText.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(waveBannerText.GetComponent<RectTransform>());

        waveBanner.SetActive(false);
    }

    // ── Kill Counter (좌측 중앙) ──
    void CreateKillCounter()
    {
        var container = UIHelper.MakeUI("KillCounter", safeAreaRoot.transform);
        var bg = container.AddComponent<Image>();
        bg.color = new Color(0, 0, 0, 0.5f);

        var outline = container.AddComponent<Outline>();
        outline.effectColor = UIColors.Defeat_Red;
        outline.effectDistance = new Vector2(1, 1);

        var rt = container.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0, 0.5f);
        rt.anchorMax = new Vector2(0, 0.5f);
        rt.pivot = new Vector2(0, 0.5f);
        rt.anchoredPosition = new Vector2(UIConstants.Spacing_Medium, 60);
        rt.sizeDelta = new Vector2(70, 28);

        var iconText = UIHelper.MakeText("KillIcon", container.transform, "KILL",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.MidlineLeft, UIColors.Defeat_Red);
        iconText.fontStyle = FontStyles.Bold;
        var irt = iconText.GetComponent<RectTransform>();
        irt.anchorMin = new Vector2(0, 0);
        irt.anchorMax = new Vector2(0.5f, 1);
        irt.offsetMin = new Vector2(UIConstants.Spacing_Small, 0);
        irt.offsetMax = Vector2.zero;

        killCountText = UIHelper.MakeText("KillCount", container.transform, "0",
            UIConstants.Font_Tab, TextAlignmentOptions.MidlineRight, UIColors.Text_Primary);
        killCountText.fontStyle = FontStyles.Bold;
        var krt = killCountText.GetComponent<RectTransform>();
        krt.anchorMin = new Vector2(0.5f, 0);
        krt.anchorMax = new Vector2(1, 1);
        krt.offsetMin = Vector2.zero;
        krt.offsetMax = new Vector2(-UIConstants.Spacing_Small, 0);
    }

    // ── Bottom Nav Bar (하단) ──
    void CreateBottomNavBar()
    {
        var navBar = UIHelper.MakeUI("NavBar", safeAreaRoot.transform);
        var navImg = navBar.AddComponent<Image>();
        navImg.color = UIColors.Background_Dark;
        UIHelper.SetAnchors(navBar, new Vector2(0, 0), new Vector2(1, 0), new Vector2(0.5f, 0));
        navBar.GetComponent<RectTransform>().sizeDelta = new Vector2(0, UIConstants.NavBar_Height);

        // Top border (golden)
        var borderLine = UIHelper.MakePanel("Border", navBar.transform, UIColors.Panel_Border);
        var brt = borderLine.GetComponent<RectTransform>();
        brt.anchorMin = new Vector2(0, 1);
        brt.anchorMax = new Vector2(1, 1);
        brt.pivot = new Vector2(0.5f, 1);
        brt.sizeDelta = new Vector2(0, 2);

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
            trt.offsetMax = new Vector2(-1, -2);

            // Active indicator
            var indicator = UIHelper.MakePanel("Indicator", tabObj.transform, UIColors.Button_Yellow);
            var irt = indicator.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0.05f, 1);
            irt.anchorMax = new Vector2(0.95f, 1);
            irt.pivot = new Vector2(0.5f, 1);
            irt.sizeDelta = new Vector2(0, 3);
            indicator.gameObject.SetActive(false);
            tabIndicators[i] = indicator;

            // Icon text
            tabIconTexts[i] = UIHelper.MakeText("Icon", tabObj.transform, tabIcons[i],
                UIConstants.NavBar_IconSize, TextAlignmentOptions.Center, UIColors.Text_Disabled);
            tabIconTexts[i].fontStyle = FontStyles.Bold;
            var icrt = tabIconTexts[i].GetComponent<RectTransform>();
            icrt.anchorMin = new Vector2(0, 0.35f);
            icrt.anchorMax = new Vector2(1, 0.9f);
            icrt.offsetMin = Vector2.zero;
            icrt.offsetMax = Vector2.zero;

            // Label
            tabLabels[i] = UIHelper.MakeText("Label", tabObj.transform, tabNames[i],
                UIConstants.Font_NavLabel, TextAlignmentOptions.Top, UIColors.Text_Disabled);
            var lrt = tabLabels[i].GetComponent<RectTransform>();
            lrt.anchorMin = new Vector2(0, 0);
            lrt.anchorMax = new Vector2(1, 0.35f);
            lrt.offsetMin = Vector2.zero;
            lrt.offsetMax = Vector2.zero;
        }
    }

    // ── Tab Overlay Panels ──
    void CreateTabPanels()
    {
        float refH = UIConstants.ReferenceResolution.y;
        float navRatio = UIConstants.NavBar_Height / refH;

        for (int i = 0; i < 5; i++)
        {
            var panel = UIHelper.MakeUI($"Panel_{tabNames[i]}", safeAreaRoot.transform);
            var panelImg = panel.AddComponent<Image>();
            panelImg.color = UIColors.Background_Panel;

            var prt = panel.GetComponent<RectTransform>();
            // 모든 탭 하단 절반만 사용
            prt.anchorMin = new Vector2(0, navRatio);
            prt.anchorMax = new Vector2(1, 0.55f);
            prt.offsetMin = Vector2.zero;
            prt.offsetMax = Vector2.zero;

            var panelOutline = panel.AddComponent<Outline>();
            panelOutline.effectColor = UIColors.Panel_Border;
            panelOutline.effectDistance = new Vector2(UIConstants.Panel_BorderWidth, UIConstants.Panel_BorderWidth);

            // Header bar
            var header = UIHelper.MakePanel("Header", panel.transform, UIColors.Background_Dark);
            var headerOutline = header.gameObject.AddComponent<Outline>();
            headerOutline.effectColor = UIColors.Panel_Border;
            headerOutline.effectDistance = new Vector2(0, -1);
            var hrt = header.GetComponent<RectTransform>();
            hrt.anchorMin = new Vector2(0, 1);
            hrt.anchorMax = new Vector2(1, 1);
            hrt.pivot = new Vector2(0.5f, 1);
            hrt.sizeDelta = new Vector2(0, UIConstants.Tab_Height);

            var title = UIHelper.MakeText("Title", header.transform, $"{tabIcons[i]} {tabNames[i]}",
                UIConstants.Font_HeaderMedium, TextAlignmentOptions.Center);
            title.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(title.GetComponent<RectTransform>());

            // Close button
            var (closeBtn, closeImg) = UIHelper.MakeButton("CloseBtn", header.transform,
                UIColors.Button_Brown, "X", UIConstants.Font_Button);
            closeImg.color = UIColors.Button_Brown;
            var closeBtnOutline = closeBtn.gameObject.AddComponent<Outline>();
            closeBtnOutline.effectColor = UIColors.Button_Brown_Border;
            closeBtnOutline.effectDistance = new Vector2(1, 1);
            closeBtn.onClick.AddListener(ClosePanel);
            var crt = closeBtn.GetComponent<RectTransform>();
            crt.anchorMin = new Vector2(1, 0.5f);
            crt.anchorMax = new Vector2(1, 0.5f);
            crt.pivot = new Vector2(1, 0.5f);
            crt.anchoredPosition = new Vector2(-UIConstants.Spacing_Medium, 0);
            crt.sizeDelta = new Vector2(UIConstants.MinTouchTarget, UIConstants.Tab_Height - UIConstants.Spacing_Small);

            // 탭별 콘텐츠
            if (i == 0)
                BuildUpgradeContent(panel.transform);
            else if (i == 1)
                BuildHeroContent(panel.transform);
            else if (i == 2)
            {
                var deckUI = panel.AddComponent<DeckUI>();
                deckUI.Init(panel.transform);
            }
            else if (i == 3)
                BuildGachaContent(panel.transform);
            else
            {
                var content = UIHelper.MakeText("Content", panel.transform, "준비 중...",
                    UIConstants.Font_HeaderMedium, TextAlignmentOptions.Center, UIColors.Text_Disabled);
                var contrt = content.GetComponent<RectTransform>();
                contrt.anchorMin = new Vector2(0, 0.4f);
                contrt.anchorMax = new Vector2(1, 0.6f);
                contrt.offsetMin = Vector2.zero;
                contrt.offsetMax = Vector2.zero;
            }

            tabPanels[i] = panel;
            panel.SetActive(false);
        }
    }

    // ── 훈련 탭 콘텐츠 ──
    void BuildUpgradeContent(Transform parent)
    {
        var content = UIHelper.MakeUI("UpgradeContent", parent);
        var contentRT = content.GetComponent<RectTransform>();
        contentRT.anchorMin = new Vector2(0, 0);
        contentRT.anchorMax = new Vector2(1, 1);
        contentRT.offsetMin = new Vector2(UIConstants.Spacing_Small, UIConstants.Spacing_Small);
        contentRT.offsetMax = new Vector2(-UIConstants.Spacing_Small, -UIConstants.Tab_Height);

        float rowH = 1f; // 1행만
        BuildUpgradeRow(content.transform, "번개", 0, rowH,
            ref tapUpText, ref tapUpBtn, () => { TapDamageSystem.Instance?.UpgradeTapDamage(); RefreshUpgradeUI(); });
    }

    void BuildUpgradeRow(Transform parent, string label, int index, float rowH,
        ref TextMeshProUGUI infoText, ref Button btn, UnityEngine.Events.UnityAction onClick)
    {
        float yMax = 1f - index * rowH;
        float yMin = yMax - rowH;

        var row = UIHelper.MakePanel($"{label}Row", parent, UIColors.Panel_Inner);
        var rrt = row.GetComponent<RectTransform>();
        rrt.anchorMin = new Vector2(0, yMin);
        rrt.anchorMax = new Vector2(1, yMax);
        rrt.offsetMin = new Vector2(0, 1);
        rrt.offsetMax = new Vector2(0, -1);

        // Label
        var labelText = UIHelper.MakeText($"{label}Label", row.transform, label,
            UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, UIColors.Text_Secondary);
        labelText.fontStyle = FontStyles.Bold;
        var llrt = labelText.GetComponent<RectTransform>();
        llrt.anchorMin = new Vector2(0, 0);
        llrt.anchorMax = new Vector2(0.18f, 1);
        llrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
        llrt.offsetMax = Vector2.zero;

        // Info
        infoText = UIHelper.MakeText($"{label}Info", row.transform, "",
            UIConstants.Font_StatValue, TextAlignmentOptions.MidlineLeft, UIColors.Text_Primary);
        infoText.fontStyle = FontStyles.Bold;
        var irt = infoText.GetComponent<RectTransform>();
        irt.anchorMin = new Vector2(0.18f, 0);
        irt.anchorMax = new Vector2(0.65f, 1);
        irt.offsetMin = new Vector2(UIConstants.Spacing_Small, 0);
        irt.offsetMax = Vector2.zero;

        // Button
        var (upgradeBtn, _) = UIHelper.MakeButton($"{label}Btn", row.transform,
            UIColors.Button_Green, "", UIConstants.Font_Cost);
        btn = upgradeBtn;
        btn.onClick.AddListener(onClick);

        var ubOutline = btn.gameObject.AddComponent<Outline>();
        ubOutline.effectColor = UIColors.Button_Green_Border;
        ubOutline.effectDistance = new Vector2(1, 1);

        var ubrt = btn.GetComponent<RectTransform>();
        ubrt.anchorMin = new Vector2(0.68f, 0.1f);
        ubrt.anchorMax = new Vector2(0.97f, 0.9f);
        ubrt.offsetMin = Vector2.zero;
        ubrt.offsetMax = Vector2.zero;

        var costText = UIHelper.MakeText("Cost", btn.transform, "",
            UIConstants.Font_Cost, TextAlignmentOptions.Center, UIColors.Text_Gold);
        costText.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(costText.GetComponent<RectTransform>());
    }

    void RefreshUpgradeUI()
    {
        var tap = TapDamageSystem.Instance;
        if (tap != null && tapUpText != null)
            tapUpText.text = $"Lv.{tap.tapDamageLevel}  DMG:{tap.TapDamage:F0}";
        if (tap != null)
            SetUpgradeBtnCost(tapUpBtn, tap.UpgradeCost);
    }

    void SetUpgradeBtnCost(Button btn, int cost)
    {
        if (btn == null) return;
        var text = btn.GetComponentInChildren<TextMeshProUGUI>();
        if (text != null) text.text = $"{cost}G";
        bool canAfford = GoldManager.Instance != null && GoldManager.Instance.Gold >= cost;
        btn.GetComponent<Image>().color = canAfford ? UIColors.Button_Green : UIColors.Button_Gray;
    }

    // ════════════════════════════════════════
    // EVENTS
    // ════════════════════════════════════════

    void OnStageChanged(int area, int stage, int wave)
    {
        if (StageManager.Instance != null)
        {
            if (stageText != null) stageText.text = StageManager.Instance.GetStageText();
            if (areaNameText != null) areaNameText.text = StageManager.Instance.GetAreaName();
        }
        UpdateProgress(wave);
        ShowWaveBanner(wave);
    }

    void OnBattleStateChanged(BattleManager.BattleState state)
    {
        if (state == BattleManager.BattleState.Defeat)
        {
            ClosePanel();
            if (StageManager.Instance != null)
                StageManager.Instance.RewindAndRestart();
        }
    }

    void OnTabClicked(int idx)
    {
        if (activeTab == idx) { ClosePanel(); return; }
        ClosePanel();
        activeTab = idx;
        tabPanels[idx].SetActive(true);
        UpdateTabVisuals();
        if (idx == 0) RefreshUpgradeUI();
        if (idx == 1) RefreshHeroUI();
        if (idx == 3) RefreshGachaUI();
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
            tabLabels[i].color = active ? UIColors.Text_Primary : UIColors.Text_Disabled;
            tabLabels[i].fontStyle = active ? FontStyles.Bold : FontStyles.Normal;
            tabIconTexts[i].color = active ? UIColors.Button_Yellow : UIColors.Text_Disabled;
            tabIndicators[i].gameObject.SetActive(active);
        }
    }

    // ════════════════════════════════════════
    // UPDATES
    // ════════════════════════════════════════

    void UpdateGold(int gold)
    {
        if (goldText != null) goldText.text = UIHelper.FormatNumber(gold);
        if (activeTab == 0) RefreshUpgradeUI();
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
            progressText.SetText("{0}/{1}", wave, total);
    }

    void ShowWaveBanner(int wave)
    {
        if (waveBanner == null || waveBannerText == null) return;
        bool isBoss = wave == (StageManager.Instance != null ? StageManager.Instance.wavesPerStage : 10);
        waveBannerText.text = isBoss ? "BOSS!" : $"WAVE {wave}";
        waveBannerText.color = isBoss ? UIColors.Defeat_Red : UIColors.Button_Yellow;

        var outline = waveBanner.GetComponent<Outline>();
        if (outline != null)
            outline.effectColor = isBoss ? UIColors.Defeat_Red : UIColors.Button_Yellow;

        if (waveBannerCG != null) waveBannerCG.alpha = 1f;
        waveBanner.SetActive(true);
        waveBannerTimer = 2f;
    }

    // ── Public API ──

    public void AddKill()
    {
        killCount++;
        if (killCountText != null)
            killCountText.SetText("{0}", killCount);
    }

    void OnDestroy()
    {
        if (GoldManager.Instance != null)
            GoldManager.Instance.OnGoldChanged -= UpdateGold;
        if (GemManager.Instance != null)
            GemManager.Instance.OnGemChanged -= UpdateGem;
        if (StageManager.Instance != null)
            StageManager.Instance.OnStageChanged -= OnStageChanged;
        if (BattleManager.Instance != null)
            BattleManager.Instance.OnBattleStateChanged -= OnBattleStateChanged;
    }

    // ════════════════════════════════════════
    // 영웅 탭 (index 1) - 영웅 강화
    // ════════════════════════════════════════

    GameObject heroListContainer;
    readonly List<GameObject> heroListItems = new();

    void BuildHeroContent(Transform parent)
    {
        var content = UIHelper.MakeUI("HeroContent", parent);
        var contentRT = content.GetComponent<RectTransform>();
        contentRT.anchorMin = new Vector2(0, 0);
        contentRT.anchorMax = new Vector2(1, 1);
        contentRT.offsetMin = new Vector2(UIConstants.Spacing_Small, UIConstants.Spacing_Small);
        contentRT.offsetMax = new Vector2(-UIConstants.Spacing_Small, -UIConstants.Tab_Height);

        // 스크롤
        var scrollObj = UIHelper.MakeUI("HeroScroll", content.transform);
        var scrollRT = scrollObj.GetComponent<RectTransform>();
        scrollRT.anchorMin = Vector2.zero;
        scrollRT.anchorMax = Vector2.one;
        scrollRT.offsetMin = Vector2.zero;
        scrollRT.offsetMax = Vector2.zero;

        var scrollRect = scrollObj.AddComponent<ScrollRect>();
        scrollRect.horizontal = false;
        scrollRect.vertical = true;

        var viewport = UIHelper.MakeUI("Viewport", scrollObj.transform);
        viewport.AddComponent<Image>().color = Color.clear;
        viewport.AddComponent<Mask>().showMaskGraphic = false;
        UIHelper.FillParent(viewport.GetComponent<RectTransform>());
        scrollRect.viewport = viewport.GetComponent<RectTransform>();

        heroListContainer = UIHelper.MakeUI("Content", viewport.transform);
        var hcRT = heroListContainer.GetComponent<RectTransform>();
        hcRT.anchorMin = new Vector2(0, 1);
        hcRT.anchorMax = new Vector2(1, 1);
        hcRT.pivot = new Vector2(0.5f, 1);
        hcRT.anchoredPosition = Vector2.zero;
        scrollRect.content = hcRT;
    }

    void RefreshHeroUI()
    {
        if (heroListContainer == null) return;
        var dm = DeckManager.Instance;
        var hlm = HeroLevelManager.Instance;
        if (dm == null) return;

        // Clear
        for (int i = 0; i < heroListItems.Count; i++)
            if (heroListItems[i] != null) Object.Destroy(heroListItems[i]);
        heroListItems.Clear();

        float itemH = 50f;
        float spacing = 3f;
        float y = 0;

        for (int i = 0; i < dm.roster.Count; i++)
        {
            var preset = dm.roster[i];
            if (preset == null || preset.isEnemy) continue;
            string heroName = preset.characterName;

            var itemImg = UIHelper.MakePanel($"Hero_{heroName}", heroListContainer.transform, UIColors.Panel_Inner);
            var item = itemImg.gameObject;
            heroListItems.Add(item);
            var irt = item.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0, 1);
            irt.anchorMax = new Vector2(1, 1);
            irt.pivot = new Vector2(0.5f, 1);
            irt.anchoredPosition = new Vector2(0, y);
            irt.sizeDelta = new Vector2(0, itemH);

            int level = hlm != null ? hlm.GetLevel(heroName) : 1;
            int copies = hlm != null ? hlm.GetCopies(heroName) : 0;
            int needed = hlm != null ? hlm.GetCopiesNeeded(level) : 1;

            // Name + Level
            var nameText = UIHelper.MakeText("Name", item.transform, $"{heroName}",
                UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, UIColors.Text_Primary);
            nameText.fontStyle = FontStyles.Bold;
            var nrt = nameText.GetComponent<RectTransform>();
            nrt.anchorMin = new Vector2(0, 0.5f);
            nrt.anchorMax = new Vector2(0.3f, 1);
            nrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
            nrt.offsetMax = Vector2.zero;

            // Level badge
            var lvText = UIHelper.MakeText("Lv", item.transform, $"Lv.{level}",
                UIConstants.Font_SmallInfo, TextAlignmentOptions.MidlineLeft, UIColors.Text_Gold);
            lvText.fontStyle = FontStyles.Bold;
            var lvrt = lvText.GetComponent<RectTransform>();
            lvrt.anchorMin = new Vector2(0, 0);
            lvrt.anchorMax = new Vector2(0.3f, 0.5f);
            lvrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
            lvrt.offsetMax = Vector2.zero;

            // Copies info
            var copyText = UIHelper.MakeText("Copies", item.transform, $"카드: {copies}/{needed}",
                9f, TextAlignmentOptions.Center, copies >= needed ? UIColors.Text_Green : UIColors.Text_Secondary);
            var cprt = copyText.GetComponent<RectTransform>();
            cprt.anchorMin = new Vector2(0.32f, 0);
            cprt.anchorMax = new Vector2(0.65f, 1);
            cprt.offsetMin = Vector2.zero;
            cprt.offsetMax = Vector2.zero;

            // Level up button
            bool canLevelUp = hlm != null && copies >= needed && level < HeroLevelManager.MAX_LEVEL;
            string btnLabel = level >= HeroLevelManager.MAX_LEVEL ? "MAX" : "강화";
            Color btnColor = canLevelUp ? UIColors.Button_Green : UIColors.Button_Gray;

            var (btn, _) = UIHelper.MakeButton($"LvUp_{heroName}", item.transform, btnColor, "", 10f);
            var btnRT = btn.GetComponent<RectTransform>();
            btnRT.anchorMin = new Vector2(0.68f, 0.1f);
            btnRT.anchorMax = new Vector2(0.97f, 0.9f);
            btnRT.offsetMin = Vector2.zero;
            btnRT.offsetMax = Vector2.zero;

            var btnText = UIHelper.MakeText("Label", btn.transform, btnLabel,
                UIConstants.Font_Cost, TextAlignmentOptions.Center,
                canLevelUp ? UIColors.Text_Primary : UIColors.Text_Disabled);
            btnText.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(btnText.GetComponent<RectTransform>());

            if (canLevelUp)
            {
                string capturedName = heroName;
                btn.onClick.AddListener(() =>
                {
                    if (HeroLevelManager.Instance != null)
                    {
                        HeroLevelManager.Instance.TryLevelUp(capturedName);
                        RefreshHeroUI();
                    }
                });
            }

            y -= (itemH + spacing);
        }

        var containerRT = heroListContainer.GetComponent<RectTransform>();
        containerRT.sizeDelta = new Vector2(0, Mathf.Abs(y));
    }

    // ════════════════════════════════════════
    // 소환 탭 (index 3) - 가챠
    // ════════════════════════════════════════

    TextMeshProUGUI gachaGemText;
    TextMeshProUGUI gachaResultText;

    void BuildGachaContent(Transform parent)
    {
        var content = UIHelper.MakeUI("GachaContent", parent);
        var contentRT = content.GetComponent<RectTransform>();
        contentRT.anchorMin = new Vector2(0, 0);
        contentRT.anchorMax = new Vector2(1, 1);
        contentRT.offsetMin = new Vector2(UIConstants.Spacing_Medium, UIConstants.Spacing_Medium);
        contentRT.offsetMax = new Vector2(-UIConstants.Spacing_Medium, -UIConstants.Tab_Height);

        // 보석 보유량 표시
        gachaGemText = UIHelper.MakeText("GemInfo", content.transform, "보석: 0",
            UIConstants.Font_StatLabel, TextAlignmentOptions.Center, UIColors.Text_Diamond);
        gachaGemText.fontStyle = FontStyles.Bold;
        var grt = gachaGemText.GetComponent<RectTransform>();
        grt.anchorMin = new Vector2(0, 0.8f);
        grt.anchorMax = new Vector2(1, 1);
        grt.offsetMin = Vector2.zero;
        grt.offsetMax = Vector2.zero;

        // 1회 뽑기 버튼 (50보석)
        var (singleBtn, _) = UIHelper.MakeButton("SinglePull", content.transform,
            UIColors.Button_Green, "", UIConstants.Font_Button);
        singleBtn.onClick.AddListener(OnSinglePull);
        var sbrt = singleBtn.GetComponent<RectTransform>();
        sbrt.anchorMin = new Vector2(0.05f, 0.45f);
        sbrt.anchorMax = new Vector2(0.47f, 0.75f);
        sbrt.offsetMin = Vector2.zero;
        sbrt.offsetMax = Vector2.zero;
        var sText = UIHelper.MakeText("Label", singleBtn.transform, $"1회 소환\n{GachaManager.SINGLE_PULL_COST} 보석",
            10f, TextAlignmentOptions.Center, UIColors.Text_Primary);
        sText.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(sText.GetComponent<RectTransform>());

        // 10연차 버튼 (450보석)
        var (multiBtn, _) = UIHelper.MakeButton("MultiPull", content.transform,
            UIColors.Button_Yellow, "", UIConstants.Font_Button);
        multiBtn.onClick.AddListener(OnMultiPull);
        var mbrt = multiBtn.GetComponent<RectTransform>();
        mbrt.anchorMin = new Vector2(0.53f, 0.45f);
        mbrt.anchorMax = new Vector2(0.95f, 0.75f);
        mbrt.offsetMin = Vector2.zero;
        mbrt.offsetMax = Vector2.zero;
        var mText = UIHelper.MakeText("Label", multiBtn.transform, $"10연차\n{GachaManager.MULTI_PULL_COST} 보석",
            10f, TextAlignmentOptions.Center, UIColors.Background_Dark);
        mText.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(mText.GetComponent<RectTransform>());

        // 결과 텍스트
        gachaResultText = UIHelper.MakeText("Result", content.transform, "",
            9f, TextAlignmentOptions.Center, UIColors.Text_Green);
        var rrt = gachaResultText.GetComponent<RectTransform>();
        rrt.anchorMin = new Vector2(0, 0);
        rrt.anchorMax = new Vector2(1, 0.4f);
        rrt.offsetMin = Vector2.zero;
        rrt.offsetMax = Vector2.zero;
    }

    void RefreshGachaUI()
    {
        if (gachaGemText != null && GemManager.Instance != null)
            gachaGemText.text = $"보석: {GemManager.Instance.Gem}";
    }

    void OnSinglePull()
    {
        if (GachaManager.Instance == null) return;
        var hero = GachaManager.Instance.SinglePull();
        if (hero != null)
        {
            bool isDuplicate = false;
            var dm = DeckManager.Instance;
            if (dm != null)
            {
                int count = 0;
                for (int i = 0; i < dm.roster.Count; i++)
                    if (dm.roster[i] == hero) count++;
                isDuplicate = count > 1 || (count == 1 && HeroLevelManager.Instance != null && HeroLevelManager.Instance.GetCopies(hero.characterName) > 0);
            }

            if (gachaResultText != null)
            {
                if (isDuplicate)
                    gachaResultText.text = $"<color=#FFD700>{hero.characterName}</color> 중복! 강화 카드 +1";
                else
                    gachaResultText.text = $"<color=#7FD44C>NEW!</color> {hero.characterName} 획득!";
            }
        }
        else
        {
            if (gachaResultText != null)
                gachaResultText.text = "<color=#CC3333>보석이 부족합니다</color>";
        }
        RefreshGachaUI();
    }

    void OnMultiPull()
    {
        if (GachaManager.Instance == null) return;
        var results = GachaManager.Instance.MultiPull();
        if (results != null)
        {
            var counts = new Dictionary<string, int>();
            for (int i = 0; i < results.Length; i++)
            {
                string n = results[i].characterName;
                if (!counts.ContainsKey(n)) counts[n] = 0;
                counts[n]++;
            }
            string resultStr = "";
            foreach (var kv in counts)
                resultStr += $"{kv.Key} x{kv.Value}  ";
            if (gachaResultText != null)
                gachaResultText.text = resultStr.Trim();
        }
        else
        {
            if (gachaResultText != null)
                gachaResultText.text = "<color=#CC3333>보석이 부족합니다</color>";
        }
        RefreshGachaUI();
    }
}
