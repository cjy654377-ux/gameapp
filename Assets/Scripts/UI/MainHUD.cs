using UnityEngine;
using UnityEngine.UI;
using TMPro;

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
        if (StageManager.Instance != null)
            StageManager.Instance.OnStageChanged += OnStageChanged;
        if (BattleManager.Instance != null)
            BattleManager.Instance.OnBattleStateChanged += OnBattleStateChanged;

        UpdateGold(GoldManager.Instance != null ? GoldManager.Instance.Gold : 0);
        UpdateGem(0);
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
        float hudRatio = UIConstants.HUD_Height / refH;

        for (int i = 0; i < 5; i++)
        {
            var panel = UIHelper.MakeUI($"Panel_{tabNames[i]}", safeAreaRoot.transform);
            var panelImg = panel.AddComponent<Image>();
            panelImg.color = UIColors.Background_Panel;

            var prt = panel.GetComponent<RectTransform>();
            // 편성 탭은 하단 절반만, 나머지는 전체
            if (i == 2)
            {
                prt.anchorMin = new Vector2(0, navRatio);
                prt.anchorMax = new Vector2(1, 0.55f);
            }
            else
            {
                prt.anchorMin = new Vector2(0, navRatio);
                prt.anchorMax = new Vector2(1, 1f - hudRatio);
            }
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

            // 편성 탭(index 2)에는 DeckUI 연결
            if (i == 2)
            {
                var deckUI = panel.AddComponent<DeckUI>();
                deckUI.Init(panel.transform);
            }
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
        if (StageManager.Instance != null)
            StageManager.Instance.OnStageChanged -= OnStageChanged;
        if (BattleManager.Instance != null)
            BattleManager.Instance.OnBattleStateChanged -= OnBattleStateChanged;
    }
}
