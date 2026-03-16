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
    readonly string[] tabNames = { "훈련", "강화", "편성", "소환", "상점" };
    readonly string[] tabIcons = { "⚔", "★", "☰", "◆", "$" };
    const int TAB_COUNT = 5;
    readonly Button[] tabButtons = new Button[TAB_COUNT];
    readonly Image[] tabIndicators = new Image[TAB_COUNT];
    readonly TextMeshProUGUI[] tabLabels = new TextMeshProUGUI[TAB_COUNT];
    readonly TextMeshProUGUI[] tabIconTexts = new TextMeshProUGUI[TAB_COUNT];

    // Tab overlay panels
    readonly GameObject[] tabPanels = new GameObject[TAB_COUNT];
    int activeTab = -1;

    // Badge notifications
    readonly GameObject[] tabBadges = new GameObject[TAB_COUNT];
    readonly TextMeshProUGUI[] tabBadgeTexts = new TextMeshProUGUI[TAB_COUNT];

    // 강화 탭 서브탭
    int enhanceSubTab; // 0=영웅, 1=장비
    Button[] enhanceSubTabBtns;
    TextMeshProUGUI[] enhanceSubTabLabels;
    GameObject enhanceHeroRoot;
    GameObject enhanceEquipRoot;

    // 훈련 탭 업그레이드 UI
    TextMeshProUGUI tapUpText;
    Button tapUpBtn;

    // Boss HP bar
    GameObject bossHpBarRoot;
    Image bossHpBarFill;
    TextMeshProUGUI bossNameText;
    TextMeshProUGUI bossHpText;
    BattleUnit trackedBoss;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        BuildUI();
    }

    // Hero select popup (for equipment)
    GameObject heroSelectPopup;
    GameObject heroSelectListContainer;
    readonly List<GameObject> heroSelectItems = new();
    string pendingEquipItemId;

    // Confirm dialog
    GameObject confirmPopup;
    TextMeshProUGUI confirmTitleText;
    TextMeshProUGUI confirmDescText;
    Button confirmYesBtn;
    System.Action pendingConfirmAction;

    // Offline reward popup
    GameObject offlinePopup;
    TextMeshProUGUI offlineText;

    // Achievement list
    GameObject achieveListContainer;
    readonly List<GameObject> achieveListItems = new();

    // Cached references for safe unsubscribe
    GoldManager cachedGoldMgr;
    GemManager cachedGemMgr;
    StageManager cachedStageMgr;
    BattleManager cachedBattleMgr;
    OfflineRewardManager cachedOfflineMgr;

    void Start()
    {
        StartCoroutine(DeferredSubscribe());
    }

    System.Collections.IEnumerator DeferredSubscribe()
    {
        yield return null;

        cachedGoldMgr = GoldManager.Instance;
        cachedGemMgr = GemManager.Instance;
        cachedStageMgr = StageManager.Instance;
        cachedBattleMgr = BattleManager.Instance;

        if (cachedGoldMgr != null)
            cachedGoldMgr.OnGoldChanged += UpdateGold;
        if (cachedGemMgr != null)
            cachedGemMgr.OnGemChanged += UpdateGem;
        if (cachedStageMgr != null)
        {
            cachedStageMgr.OnStageChanged += OnStageChanged;
            cachedStageMgr.OnBossSpawned += OnBossSpawned;
        }
        if (cachedBattleMgr != null)
            cachedBattleMgr.OnBattleStateChanged += OnBattleStateChanged;

        cachedOfflineMgr = OfflineRewardManager.Instance;
        if (cachedOfflineMgr != null)
            cachedOfflineMgr.OnOfflineReward += OnOfflineReward;

        UpdateGold(cachedGoldMgr != null ? cachedGoldMgr.Gold : 0);
        UpdateGem(cachedGemMgr != null ? cachedGemMgr.Gem : 0);
        if (cachedStageMgr != null)
        {
            if (stageText != null) stageText.text = cachedStageMgr.GetStageText();
            if (areaNameText != null) areaNameText.text = cachedStageMgr.GetAreaName();
        }

        // 출석 체크 팝업 (2프레임 지연 - UI 구독 완료 후)
        yield return null;
        if (DailyLoginManager.Instance != null && DailyLoginManager.Instance.ShouldShowPopup())
            ShowDailyLoginPopup();
    }

    void Update()
    {
        // Wave banner fade
        if (waveBannerTimer > 0)
        {
            waveBannerTimer -= Time.unscaledDeltaTime;
            if (waveBannerTimer <= 0.5f && waveBannerCG != null)
                waveBannerCG.alpha = waveBannerTimer / 0.5f;
            if (waveBannerTimer <= 0 && waveBanner != null)
                waveBanner.SetActive(false);
        }

        // Badge update (every 2s)
        badgeTimer -= Time.unscaledDeltaTime;
        if (badgeTimer <= 0f)
        {
            badgeTimer = BADGE_INTERVAL;
            UpdateBadges();
        }
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
        CreateOfflinePopup();
        CreateHeroSelectPopup();
        CreateConfirmPopup();
        CreateBossHpBar();
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
        irt.sizeDelta = new Vector2(18, 0);

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
        rt.anchorMin = new Vector2(0.2f, 0.78f);
        rt.anchorMax = new Vector2(0.8f, 0.83f);
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
        rt.anchoredPosition = new Vector2(UIConstants.Spacing_Small, 50);
        rt.sizeDelta = new Vector2(58, 22);

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

        float tabWidth = 1f / TAB_COUNT;
        for (int i = 0; i < TAB_COUNT; i++)
        {
            int idx = i;
            float xMin = i * tabWidth;
            float xMax = (i + 1) * tabWidth;

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
            icrt.anchorMin = new Vector2(0, 0.32f);
            icrt.anchorMax = new Vector2(1, 0.88f);
            icrt.offsetMin = Vector2.zero;
            icrt.offsetMax = Vector2.zero;

            // Label
            tabLabels[i] = UIHelper.MakeText("Label", tabObj.transform, tabNames[i],
                UIConstants.Font_NavLabel, TextAlignmentOptions.Top, UIColors.Text_Disabled);
            var lrt = tabLabels[i].GetComponent<RectTransform>();
            lrt.anchorMin = new Vector2(0, 0.02f);
            lrt.anchorMax = new Vector2(1, 0.32f);
            lrt.offsetMin = Vector2.zero;
            lrt.offsetMax = Vector2.zero;

            // Badge (red circle with count)
            var badge = UIHelper.MakeUI($"Badge_{i}", tabObj.transform);
            var badgeImg = badge.AddComponent<Image>();
            badgeImg.color = UIColors.Defeat_Red;
            var bdrt = badge.GetComponent<RectTransform>();
            bdrt.anchorMin = new Vector2(0.65f, 0.65f);
            bdrt.anchorMax = new Vector2(0.65f, 0.65f);
            bdrt.pivot = new Vector2(0.5f, 0.5f);
            bdrt.sizeDelta = new Vector2(16, 16);

            var badgeText = UIHelper.MakeText("Count", badge.transform, "",
                7f, TextAlignmentOptions.Center, Color.white);
            badgeText.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(badgeText.GetComponent<RectTransform>());

            tabBadges[i] = badge;
            tabBadgeTexts[i] = badgeText;
            badge.SetActive(false);
        }
    }

    // ── Tab Overlay Panels ──
    void CreateTabPanels()
    {
        float refH = UIConstants.ReferenceResolution.y;
        float navRatio = UIConstants.NavBar_Height / refH;

        for (int i = 0; i < TAB_COUNT; i++)
        {
            var panel = UIHelper.MakeUI($"Panel_{tabNames[i]}", safeAreaRoot.transform);
            var panelImg = panel.AddComponent<Image>();
            panelImg.color = UIColors.Background_Panel;

            var prt = panel.GetComponent<RectTransform>();
            // 모든 탭 하단 절반 이하만 사용
            prt.anchorMin = new Vector2(0, navRatio);
            prt.anchorMax = new Vector2(1, 0.48f);
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
                BuildEnhanceContent(panel.transform);
            else if (i == 2)
            {
                var deckUI = panel.AddComponent<DeckUI>();
                deckUI.Init(panel.transform);
            }
            else if (i == 3)
                BuildGachaContent(panel.transform);
            else if (i == 4)
                BuildShopContent(panel.transform);

            tabPanels[i] = panel;
            panel.SetActive(false);
        }
    }

    // ── 훈련 탭 콘텐츠 ──
    // 스킬 강화 UI
    GameObject skillUpgradeContainer;
    readonly List<GameObject> skillUpgradeItems = new();

    void BuildUpgradeContent(Transform parent)
    {
        var content = UIHelper.MakeUI("UpgradeContent", parent);
        var contentRT = content.GetComponent<RectTransform>();
        contentRT.anchorMin = new Vector2(0, 0);
        contentRT.anchorMax = new Vector2(1, 1);
        contentRT.offsetMin = new Vector2(UIConstants.Spacing_Small, UIConstants.Spacing_Small);
        contentRT.offsetMax = new Vector2(-UIConstants.Spacing_Small, -UIConstants.Tab_Height);

        // 번개 업그레이드 (상단 25%)
        BuildUpgradeRow(content.transform, "번개", 0, 0.25f,
            ref tapUpText, ref tapUpBtn, () =>
            {
                var tap = TapDamageSystem.Instance;
                if (tap != null && !tap.UpgradeTapDamage())
                    ToastNotification.Instance?.Show("골드 부족!", $"{tap.UpgradeCost}G 필요", UIColors.Defeat_Red);
                RefreshUpgradeUI();
            });

        // 스킬 강화 라벨
        var skillLabel = UIHelper.MakeText("SkillLabel", content.transform, "스킬 강화",
            UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, UIColors.Text_Gold);
        skillLabel.fontStyle = FontStyles.Bold;
        var slrt = skillLabel.GetComponent<RectTransform>();
        slrt.anchorMin = new Vector2(0, 0.7f);
        slrt.anchorMax = new Vector2(1, 0.75f);
        slrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
        slrt.offsetMax = Vector2.zero;

        // 스킬 강화 스크롤
        var scrollObj = UIHelper.MakeUI("SkillUpScroll", content.transform);
        var scrollRT = scrollObj.GetComponent<RectTransform>();
        scrollRT.anchorMin = new Vector2(0, 0);
        scrollRT.anchorMax = new Vector2(1, 0.7f);
        scrollRT.offsetMin = Vector2.zero;
        scrollRT.offsetMax = Vector2.zero;

        var scrollRect = scrollObj.AddComponent<ScrollRect>();
        scrollRect.horizontal = false;
        scrollRect.vertical = true;

        var viewport = UIHelper.MakeUI("Viewport", scrollObj.transform);
        viewport.AddComponent<RectMask2D>();
        UIHelper.FillParent(viewport.GetComponent<RectTransform>());
        scrollRect.viewport = viewport.GetComponent<RectTransform>();

        skillUpgradeContainer = UIHelper.MakeUI("Content", viewport.transform);
        var crt2 = skillUpgradeContainer.GetComponent<RectTransform>();
        crt2.anchorMin = new Vector2(0, 1);
        crt2.anchorMax = new Vector2(1, 1);
        crt2.pivot = new Vector2(0.5f, 1);
        crt2.anchoredPosition = Vector2.zero;
        scrollRect.content = crt2;
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
        RefreshSkillUpgradeUI();
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
            if (StageManager.Instance != null)
                StageManager.Instance.RewindAndRestart();
        }
    }

    void OnTabClicked(int idx)
    {
        SoundManager.Instance?.PlayButtonSFX();
        if (activeTab == idx) { ClosePanel(); return; }
        ClosePanel();
        activeTab = idx;
        tabPanels[idx].SetActive(true);
        SkillUI.IsTabPanelOpen = true;
        UpdateTabVisuals();
        if (idx == 0) RefreshUpgradeUI();
        if (idx == 1) RefreshEnhanceTab();
        if (idx == 3) RefreshGachaUI();
        if (idx == 4) RefreshShopUI();
    }

    void ClosePanel()
    {
        if (activeTab >= 0)
            tabPanels[activeTab].SetActive(false);
        activeTab = -1;
        SkillUI.IsTabPanelOpen = false;
        UpdateTabVisuals();
    }

    void UpdateTabVisuals()
    {
        for (int i = 0; i < TAB_COUNT; i++)
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

    void OnBossSpawned(bool isAreaBoss)
    {
        if (waveBanner == null || waveBannerText == null) return;
        string bossLabel = isAreaBoss ? "AREA BOSS!" : "BOSS!";
        waveBannerText.text = $"⚠ {bossLabel} ⚠";
        waveBannerText.color = isAreaBoss ? new Color(1f, 0.2f, 0.2f) : UIColors.Defeat_Red;

        var outline = waveBanner.GetComponent<Outline>();
        if (outline != null)
            outline.effectColor = isAreaBoss ? new Color(1f, 0.2f, 0.2f) : UIColors.Defeat_Red;

        if (waveBannerCG != null) waveBannerCG.alpha = 1f;
        waveBanner.SetActive(true);
        waveBannerTimer = 3f; // 보스는 더 오래 표시

        // Boss HP bar 활성화
        TrackBoss(isAreaBoss);
    }

    void TrackBoss(bool isAreaBoss)
    {
        if (BattleManager.Instance == null) return;
        // 가장 HP 높은 적 = 보스
        BattleUnit boss = null;
        float maxHp = 0f;
        var enemies = BattleManager.Instance.enemyUnits;
        for (int i = 0; i < enemies.Count; i++)
        {
            if (enemies[i] != null && !enemies[i].IsDead && enemies[i].maxHp > maxHp)
            {
                maxHp = enemies[i].maxHp;
                boss = enemies[i];
            }
        }
        if (boss == null) return;

        trackedBoss = boss;
        if (bossHpBarRoot != null) bossHpBarRoot.SetActive(true);
        if (bossNameText != null)
            bossNameText.text = isAreaBoss ? $"AREA BOSS: {boss.unitName}" : $"BOSS: {boss.unitName}";
        bossNameText.color = isAreaBoss ? new Color(1f, 0.2f, 0.2f) : UIColors.Text_Gold;

        trackedBoss.OnHpChanged += UpdateBossHpBar;
        trackedBoss.OnDeath += HideBossHpBar;
    }

    void UpdateBossHpBar(float hp, float maxHp)
    {
        if (bossHpBarFill != null)
            bossHpBarFill.fillAmount = maxHp > 0 ? hp / maxHp : 0f;
        if (bossHpText != null)
            bossHpText.text = $"{Mathf.CeilToInt(hp)} / {Mathf.CeilToInt(maxHp)}";
    }

    void HideBossHpBar()
    {
        if (bossHpBarRoot != null) bossHpBarRoot.SetActive(false);
        if (trackedBoss != null)
        {
            trackedBoss.OnHpChanged -= UpdateBossHpBar;
            trackedBoss.OnDeath -= HideBossHpBar;
            trackedBoss = null;
        }
    }

    // ── Public API ──

    public void AddKill()
    {
        killCount++;
        if (killCountText != null)
            killCountText.text = killCount.ToString();
    }

    float badgeTimer;
    const float BADGE_INTERVAL = 2f;

    // ── List pooling helpers ──
    static void RecycleList(List<GameObject> items)
    {
        for (int i = 0; i < items.Count; i++)
            if (items[i] != null) items[i].SetActive(false);
    }

    static GameObject ReuseOrCreate(List<GameObject> items, ref int reuseIdx,
        string name, Transform parent, Color color)
    {
        while (reuseIdx < items.Count)
        {
            var candidate = items[reuseIdx++];
            if (candidate == null) continue;
            // Clear children for fresh rebuild
            for (int c = candidate.transform.childCount - 1; c >= 0; c--)
                Object.Destroy(candidate.transform.GetChild(c).gameObject);
            candidate.SetActive(true);
            candidate.name = name;
            candidate.GetComponent<Image>().color = color;
            return candidate;
        }
        var img = UIHelper.MakePanel(name, parent, color);
        items.Add(img.gameObject);
        return img.gameObject;
    }

    static void TrimExcess(List<GameObject> items, int activeCount)
    {
        for (int i = items.Count - 1; i >= activeCount; i--)
        {
            if (items[i] != null && !items[i].activeSelf)
                Object.Destroy(items[i]);
            items.RemoveAt(i);
        }
    }

    void UpdateBadges()
    {
        // 강화 탭 (index 1): 레벨업 가능한 영웅 수
        var dm = DeckManager.Instance;
        var hlm = HeroLevelManager.Instance;
        int heroCount = 0;
        if (dm != null && hlm != null)
        {
            for (int i = 0; i < dm.roster.Count; i++)
            {
                var p = dm.roster[i];
                if (p == null || p.isEnemy) continue;
                int lv = hlm.GetLevel(p.characterName);
                if (lv >= HeroLevelManager.MAX_LEVEL) continue;
                if (hlm.GetCopies(p.characterName) >= hlm.GetCopiesNeeded(lv))
                    heroCount++;
            }
        }
        SetBadge(1, heroCount);

        // 상점 탭 (index 4): 미수령 업적 + 미션 보상 수
        int rewardCount = 0;
        var am = AchievementManager.Instance;
        if (am != null)
        {
            var achs = am.GetAchievements();
            for (int i = 0; i < achs.Count; i++)
                if (achs[i].completed && !achs[i].claimed) rewardCount++;
        }
        var mm = DailyMissionManager.Instance;
        if (mm != null)
        {
            var missions = mm.GetMissions();
            for (int i = 0; i < missions.Count; i++)
                if (missions[i].currentCount >= missions[i].targetCount && !missions[i].claimed)
                    rewardCount++;
        }
        SetBadge(4, rewardCount);
    }

    void SetBadge(int tabIndex, int count)
    {
        if (tabIndex < 0 || tabIndex >= TAB_COUNT) return;
        if (tabBadges[tabIndex] == null) return;

        if (count <= 0)
        {
            tabBadges[tabIndex].SetActive(false);
            return;
        }
        tabBadges[tabIndex].SetActive(true);
        if (tabBadgeTexts[tabIndex] != null)
            tabBadgeTexts[tabIndex].text = count.ToString();
    }

    void CreateBossHpBar()
    {
        bossHpBarRoot = UIHelper.MakeUI("BossHpBar", safeAreaRoot.transform);
        var rt = bossHpBarRoot.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0.1f, 0.78f);
        rt.anchorMax = new Vector2(0.9f, 0.84f);
        rt.offsetMin = Vector2.zero;
        rt.offsetMax = Vector2.zero;

        // 배경
        var bg = bossHpBarRoot.AddComponent<Image>();
        bg.color = new Color(0.15f, 0.05f, 0.05f, 0.85f);

        // 이름 텍스트
        var nameObj = UIHelper.MakeUI("BossName", bossHpBarRoot.transform);
        var nameRt = nameObj.GetComponent<RectTransform>();
        nameRt.anchorMin = new Vector2(0f, 1f);
        nameRt.anchorMax = new Vector2(1f, 1.8f);
        nameRt.offsetMin = Vector2.zero;
        nameRt.offsetMax = Vector2.zero;
        bossNameText = nameObj.AddComponent<TextMeshProUGUI>();
        bossNameText.text = "BOSS";
        bossNameText.fontSize = UIConstants.Font_StatLabel;
        bossNameText.alignment = TextAlignmentOptions.Center;
        bossNameText.color = UIColors.Text_Gold;

        // HP바 fill
        var fillObj = UIHelper.MakeUI("Fill", bossHpBarRoot.transform);
        var fillRt = fillObj.GetComponent<RectTransform>();
        fillRt.anchorMin = new Vector2(0.02f, 0.15f);
        fillRt.anchorMax = new Vector2(0.98f, 0.85f);
        fillRt.offsetMin = Vector2.zero;
        fillRt.offsetMax = Vector2.zero;
        bossHpBarFill = fillObj.AddComponent<Image>();
        bossHpBarFill.color = new Color(0.9f, 0.15f, 0.15f);
        bossHpBarFill.type = Image.Type.Filled;
        bossHpBarFill.fillMethod = Image.FillMethod.Horizontal;

        // HP 텍스트
        var hpObj = UIHelper.MakeUI("BossHpText", bossHpBarRoot.transform);
        var hpRt = hpObj.GetComponent<RectTransform>();
        hpRt.anchorMin = Vector2.zero;
        hpRt.anchorMax = Vector2.one;
        hpRt.offsetMin = Vector2.zero;
        hpRt.offsetMax = Vector2.zero;
        bossHpText = hpObj.AddComponent<TextMeshProUGUI>();
        bossHpText.text = "";
        bossHpText.fontSize = UIConstants.Font_SmallInfo;
        bossHpText.alignment = TextAlignmentOptions.Center;
        bossHpText.color = Color.white;

        bossHpBarRoot.SetActive(false);
    }

    void OnDestroy()
    {
        HideBossHpBar(); // 보스 이벤트 구독 해제

        if (cachedGoldMgr != null)
            cachedGoldMgr.OnGoldChanged -= UpdateGold;
        if (cachedGemMgr != null)
            cachedGemMgr.OnGemChanged -= UpdateGem;
        if (cachedStageMgr != null)
        {
            cachedStageMgr.OnStageChanged -= OnStageChanged;
            cachedStageMgr.OnBossSpawned -= OnBossSpawned;
        }
        if (cachedBattleMgr != null)
            cachedBattleMgr.OnBattleStateChanged -= OnBattleStateChanged;
        if (cachedOfflineMgr != null)
            cachedOfflineMgr.OnOfflineReward -= OnOfflineReward;
    }

    // ════════════════════════════════════════
    // 강화 탭 (index 1) - 서브탭: 영웅 / 장비
    // ════════════════════════════════════════

    void BuildEnhanceContent(Transform parent)
    {
        var content = UIHelper.MakeUI("EnhanceContent", parent);
        var contentRT = content.GetComponent<RectTransform>();
        contentRT.anchorMin = Vector2.zero;
        contentRT.anchorMax = Vector2.one;
        contentRT.offsetMin = new Vector2(0, 0);
        contentRT.offsetMax = new Vector2(0, -UIConstants.Tab_Height);

        // 서브탭 바
        float subTabH = 30f;
        var subTabBar = UIHelper.MakePanel("SubTabBar", content.transform, UIColors.Background_Dark);
        var stbRT = subTabBar.GetComponent<RectTransform>();
        stbRT.anchorMin = new Vector2(0, 1);
        stbRT.anchorMax = new Vector2(1, 1);
        stbRT.pivot = new Vector2(0.5f, 1);
        stbRT.sizeDelta = new Vector2(0, subTabH);

        string[] subNames = { "영웅", "장비" };
        enhanceSubTabBtns = new Button[2];
        enhanceSubTabLabels = new TextMeshProUGUI[2];

        for (int s = 0; s < 2; s++)
        {
            float xMin = s * 0.5f;
            float xMax = (s + 1) * 0.5f;
            var (btn, _) = UIHelper.MakeButton($"SubTab_{subNames[s]}", subTabBar.transform,
                UIColors.Tab_Inactive, "", 0);
            var brt = btn.GetComponent<RectTransform>();
            brt.anchorMin = new Vector2(xMin, 0);
            brt.anchorMax = new Vector2(xMax, 1);
            brt.offsetMin = new Vector2(1, 0);
            brt.offsetMax = new Vector2(-1, 0);

            var label = UIHelper.MakeText("Label", btn.transform, subNames[s],
                UIConstants.Font_Tab, TextAlignmentOptions.Center, UIColors.Text_Disabled);
            label.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(label.GetComponent<RectTransform>());

            enhanceSubTabBtns[s] = btn;
            enhanceSubTabLabels[s] = label;

            int captured = s;
            btn.onClick.AddListener(() => SwitchEnhanceSubTab(captured));
        }

        // 영웅 콘텐츠 루트
        enhanceHeroRoot = UIHelper.MakeUI("HeroRoot", content.transform);
        var heroRT = enhanceHeroRoot.GetComponent<RectTransform>();
        heroRT.anchorMin = Vector2.zero;
        heroRT.anchorMax = new Vector2(1, 1);
        heroRT.offsetMin = Vector2.zero;
        heroRT.offsetMax = new Vector2(0, -subTabH);
        BuildHeroContent(enhanceHeroRoot.transform);

        // 장비 콘텐츠 루트
        enhanceEquipRoot = UIHelper.MakeUI("EquipRoot", content.transform);
        var equipRT = enhanceEquipRoot.GetComponent<RectTransform>();
        equipRT.anchorMin = Vector2.zero;
        equipRT.anchorMax = new Vector2(1, 1);
        equipRT.offsetMin = Vector2.zero;
        equipRT.offsetMax = new Vector2(0, -subTabH);
        BuildEquipmentContent(enhanceEquipRoot.transform);

        enhanceSubTab = 0;
        UpdateEnhanceSubTabVisuals();
    }

    void SwitchEnhanceSubTab(int subIdx)
    {
        SoundManager.Instance?.PlayButtonSFX();
        enhanceSubTab = subIdx;
        UpdateEnhanceSubTabVisuals();
        if (subIdx == 0) RefreshHeroUI();
        else RefreshEquipmentUI();
    }

    void UpdateEnhanceSubTabVisuals()
    {
        if (enhanceSubTabBtns == null) return;
        for (int i = 0; i < 2; i++)
        {
            bool active = (i == enhanceSubTab);
            enhanceSubTabBtns[i].GetComponent<Image>().color = active ? UIColors.Tab_Active : UIColors.Tab_Inactive;
            enhanceSubTabLabels[i].color = active ? UIColors.Text_TabActive : UIColors.Text_Disabled;
        }
        if (enhanceHeroRoot != null) enhanceHeroRoot.SetActive(enhanceSubTab == 0);
        if (enhanceEquipRoot != null) enhanceEquipRoot.SetActive(enhanceSubTab == 1);
    }

    void RefreshEnhanceTab()
    {
        UpdateEnhanceSubTabVisuals();
        if (enhanceSubTab == 0) RefreshHeroUI();
        else RefreshEquipmentUI();
    }

    // ── 영웅 서브탭 콘텐츠 ──

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
        viewport.AddComponent<RectMask2D>();
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

        RecycleList(heroListItems);
        int heroReuse = 0;

        float itemH = 42f;
        float spacing = 2f;
        float y = 0;
        int activeHeroCount = 0;

        for (int i = 0; i < dm.roster.Count; i++)
        {
            var preset = dm.roster[i];
            if (preset == null || preset.isEnemy) continue;
            string heroName = preset.characterName;

            var item = ReuseOrCreate(heroListItems, ref heroReuse,
                $"Hero_{heroName}", heroListContainer.transform, UIColors.Panel_Inner);
            activeHeroCount++;
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

            // Level badge + Star
            int star = hlm != null ? hlm.GetStarRank(heroName) : 1;
            string starStr = new string('\u2605', star); // ★
            var lvText = UIHelper.MakeText("Lv", item.transform, $"Lv.{level} {starStr}",
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

        TrimExcess(heroListItems, activeHeroCount);
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
        grt.anchorMin = new Vector2(0, 0.85f);
        grt.anchorMax = new Vector2(1, 1);
        grt.offsetMin = Vector2.zero;
        grt.offsetMax = Vector2.zero;

        // 1회 뽑기 버튼 (50보석)
        var (singleBtn, _) = UIHelper.MakeButton("SinglePull", content.transform,
            UIColors.Button_Green, "", UIConstants.Font_Button);
        singleBtn.onClick.AddListener(OnSinglePull);
        var sbrt = singleBtn.GetComponent<RectTransform>();
        sbrt.anchorMin = new Vector2(0.05f, 0.5f);
        sbrt.anchorMax = new Vector2(0.47f, 0.8f);
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
        mbrt.anchorMin = new Vector2(0.53f, 0.5f);
        mbrt.anchorMax = new Vector2(0.95f, 0.8f);
        mbrt.offsetMin = Vector2.zero;
        mbrt.offsetMax = Vector2.zero;
        var mText = UIHelper.MakeText("Label", multiBtn.transform, $"10연차\n{GachaManager.MULTI_PULL_COST} 보석",
            10f, TextAlignmentOptions.Center, UIColors.Background_Dark);
        mText.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(mText.GetComponent<RectTransform>());

        // 확률 정보 버튼 (법적 의무)
        var (probBtn, _) = UIHelper.MakeButton("ProbInfoBtn", content.transform,
            UIColors.Button_Brown, "", UIConstants.Font_SmallInfo);
        probBtn.onClick.AddListener(ShowProbabilityInfo);
        var pbrt = probBtn.GetComponent<RectTransform>();
        pbrt.anchorMin = new Vector2(0.3f, 0.42f);
        pbrt.anchorMax = new Vector2(0.7f, 0.5f);
        pbrt.offsetMin = Vector2.zero;
        pbrt.offsetMax = Vector2.zero;
        var probLabel = UIHelper.MakeText("Label", probBtn.transform, "확률 정보",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, UIColors.Text_Secondary);
        UIHelper.FillParent(probLabel.GetComponent<RectTransform>());

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
        int cost = GachaManager.SINGLE_PULL_COST;
        if (GemManager.Instance != null && GemManager.Instance.Gem < cost)
        {
            ToastNotification.Instance?.Show("보석 부족!", $"{cost}보석 필요", UIColors.Defeat_Red);
            return;
        }
        ShowConfirm("소환 확인", $"보석 {cost}개를 사용합니다.\n진행하시겠습니까?", DoSinglePull);
    }

    void DoSinglePull()
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
        int cost = GachaManager.MULTI_PULL_COST;
        if (GemManager.Instance != null && GemManager.Instance.Gem < cost)
        {
            ToastNotification.Instance?.Show("보석 부족!", $"{cost}보석 필요", UIColors.Defeat_Red);
            return;
        }
        ShowConfirm("10연 소환 확인", $"보석 {cost}개를 사용합니다.\n진행하시겠습니까?", DoMultiPull);
    }

    void DoMultiPull()
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

    // ════════════════════════════════════════
    // 장비 탭 (index 4) - 인벤토리/장착
    // ════════════════════════════════════════

    GameObject equipListContainer;
    readonly List<GameObject> equipListItems = new();
    TextMeshProUGUI equipInfoText;

    void BuildEquipmentContent(Transform parent)
    {
        var content = UIHelper.MakeUI("EquipContent", parent);
        var contentRT = content.GetComponent<RectTransform>();
        contentRT.anchorMin = new Vector2(0, 0);
        contentRT.anchorMax = new Vector2(1, 1);
        contentRT.offsetMin = new Vector2(UIConstants.Spacing_Small, UIConstants.Spacing_Small);
        contentRT.offsetMax = new Vector2(-UIConstants.Spacing_Small, -UIConstants.Tab_Height);

        // 상단 요약
        equipInfoText = UIHelper.MakeText("EquipInfo", content.transform, "장비: 0개",
            UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, UIColors.Text_Secondary);
        equipInfoText.fontStyle = FontStyles.Bold;
        var irt = equipInfoText.GetComponent<RectTransform>();
        irt.anchorMin = new Vector2(0, 0.88f);
        irt.anchorMax = new Vector2(1, 1);
        irt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
        irt.offsetMax = Vector2.zero;

        // 스크롤 리스트
        var scrollObj = UIHelper.MakeUI("EquipScroll", content.transform);
        var scrollRT = scrollObj.GetComponent<RectTransform>();
        scrollRT.anchorMin = new Vector2(0, 0);
        scrollRT.anchorMax = new Vector2(1, 0.87f);
        scrollRT.offsetMin = Vector2.zero;
        scrollRT.offsetMax = Vector2.zero;

        var scrollRect = scrollObj.AddComponent<ScrollRect>();
        scrollRect.horizontal = false;
        scrollRect.vertical = true;

        var viewport = UIHelper.MakeUI("Viewport", scrollObj.transform);
        viewport.AddComponent<RectMask2D>();
        UIHelper.FillParent(viewport.GetComponent<RectTransform>());
        scrollRect.viewport = viewport.GetComponent<RectTransform>();

        equipListContainer = UIHelper.MakeUI("Content", viewport.transform);
        var hcRT = equipListContainer.GetComponent<RectTransform>();
        hcRT.anchorMin = new Vector2(0, 1);
        hcRT.anchorMax = new Vector2(1, 1);
        hcRT.pivot = new Vector2(0.5f, 1);
        hcRT.anchoredPosition = Vector2.zero;
        scrollRect.content = hcRT;
    }

    void RefreshEquipmentUI()
    {
        if (equipListContainer == null) return;
        var em = EquipmentManager.Instance;
        if (em == null) return;

        RecycleList(equipListItems);
        int equipReuse = 0;

        var inv = em.Inventory;
        if (equipInfoText != null)
            equipInfoText.text = $"장비: {inv.Count}개";

        float itemH = 40f;
        float spacing = 2f;
        float y = 0;
        int activeEquipCount = 0;

        // 레어도별 색상
        Color[] rarityColors = {
            UIColors.Text_Secondary,        // 0 (unused)
            UIColors.Text_Secondary,        // 1
            UIColors.Rarity_Common,         // 2
            new Color(0.3f, 0.6f, 1f),     // 3
            UIColors.Rarity_Rare,           // 4
            UIColors.Text_Gold              // 5
        };

        for (int i = 0; i < inv.Count; i++)
        {
            var equip = inv[i];
            Color rarityCol = equip.rarity >= 0 && equip.rarity < rarityColors.Length ? rarityColors[equip.rarity] : UIColors.Text_Secondary;

            var item = ReuseOrCreate(equipListItems, ref equipReuse,
                $"Equip_{i}", equipListContainer.transform, UIColors.Panel_Inner);
            activeEquipCount++;
            var ert = item.GetComponent<RectTransform>();
            ert.anchorMin = new Vector2(0, 1);
            ert.anchorMax = new Vector2(1, 1);
            ert.pivot = new Vector2(0.5f, 1);
            ert.anchoredPosition = new Vector2(0, y);
            ert.sizeDelta = new Vector2(0, itemH);

            // 이름 + 레어도
            string stars = new string('★', equip.rarity);
            var nameText = UIHelper.MakeText("Name", item.transform, $"{equip.itemName}",
                UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, rarityCol);
            nameText.fontStyle = FontStyles.Bold;
            var nrt = nameText.GetComponent<RectTransform>();
            nrt.anchorMin = new Vector2(0, 0.5f);
            nrt.anchorMax = new Vector2(0.4f, 1);
            nrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
            nrt.offsetMax = Vector2.zero;

            // 레어도 별
            var starText = UIHelper.MakeText("Stars", item.transform, stars,
                8f, TextAlignmentOptions.MidlineLeft, UIColors.Text_Gold);
            var srt = starText.GetComponent<RectTransform>();
            srt.anchorMin = new Vector2(0, 0);
            srt.anchorMax = new Vector2(0.4f, 0.5f);
            srt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
            srt.offsetMax = Vector2.zero;

            // 스탯
            string statStr = "";
            if (equip.bonusAtk > 0) statStr += $"ATK+{equip.bonusAtk:F0} ";
            if (equip.bonusDef > 0) statStr += $"DEF+{equip.bonusDef:F0} ";
            if (equip.bonusHp > 0) statStr += $"HP+{equip.bonusHp:F0}";
            var statText = UIHelper.MakeText("Stats", item.transform, statStr,
                8f, TextAlignmentOptions.Center, UIColors.Text_Primary);
            var strt = statText.GetComponent<RectTransform>();
            strt.anchorMin = new Vector2(0.4f, 0);
            strt.anchorMax = new Vector2(0.7f, 1);
            strt.offsetMin = Vector2.zero;
            strt.offsetMax = Vector2.zero;

            // 장착/해제 버튼
            bool isEquipped = !string.IsNullOrEmpty(equip.equippedTo);
            string btnLabel = isEquipped ? $"{equip.equippedTo}" : "장착";
            Color btnColor = isEquipped ? UIColors.Button_Brown : UIColors.Button_Green;

            var (btn, _) = UIHelper.MakeButton($"Btn_{i}", item.transform, btnColor, "", 9f);
            var btnRT = btn.GetComponent<RectTransform>();
            btnRT.anchorMin = new Vector2(0.72f, 0.05f);
            btnRT.anchorMax = new Vector2(0.97f, 0.48f);
            btnRT.offsetMin = Vector2.zero;
            btnRT.offsetMax = Vector2.zero;

            var btnText = UIHelper.MakeText("Label", btn.transform, btnLabel,
                8f, TextAlignmentOptions.Center, UIColors.Text_Primary);
            btnText.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(btnText.GetComponent<RectTransform>());

            string capturedId = equip.id;
            if (isEquipped)
            {
                btn.onClick.AddListener(() =>
                {
                    EquipmentManager.Instance?.UnequipItem(capturedId);
                    RefreshEquipmentUI();
                });
            }
            else
            {
                btn.onClick.AddListener(() => ShowHeroSelectPopup(capturedId));
            }

            // 강화/분해 버튼 (미장착 아이템만)
            if (!isEquipped)
            {
                // 강화 버튼
                var materials = em.GetEnhanceMaterials(equip.id);
                bool canEnhance = materials.Count > 0 && equip.rarity < 5;

                var (enhBtn, _3) = UIHelper.MakeButton($"Enh_{i}", item.transform,
                    canEnhance ? UIColors.Button_Green : UIColors.Button_Gray, "", 7f);
                var enhBtnRT = enhBtn.GetComponent<RectTransform>();
                enhBtnRT.anchorMin = new Vector2(0.72f, 0.52f);
                enhBtnRT.anchorMax = new Vector2(0.84f, 0.95f);
                enhBtnRT.offsetMin = Vector2.zero;
                enhBtnRT.offsetMax = Vector2.zero;

                var enhBtnText = UIHelper.MakeText("Label", enhBtn.transform, "강화",
                    7f, TextAlignmentOptions.Center,
                    canEnhance ? UIColors.Text_Primary : UIColors.Text_Disabled);
                enhBtnText.fontStyle = FontStyles.Bold;
                UIHelper.FillParent(enhBtnText.GetComponent<RectTransform>());

                if (canEnhance)
                {
                    string enhId = equip.id;
                    string matId = materials[0].id;
                    enhBtn.onClick.AddListener(() =>
                    {
                        if (EquipmentManager.Instance != null && EquipmentManager.Instance.EnhanceItem(enhId, matId))
                            ToastNotification.Instance?.Show("강화 성공!", "등급 상승!", UIColors.Text_Gold);
                        RefreshEquipmentUI();
                    });
                }

                // 분해 버튼
                var (disBtn, _2) = UIHelper.MakeButton($"Dis_{i}", item.transform,
                    UIColors.Defeat_Red, "", 7f);
                var disBtnRT = disBtn.GetComponent<RectTransform>();
                disBtnRT.anchorMin = new Vector2(0.85f, 0.52f);
                disBtnRT.anchorMax = new Vector2(0.97f, 0.95f);
                disBtnRT.offsetMin = Vector2.zero;
                disBtnRT.offsetMax = Vector2.zero;

                string disLabel = $"{equip.rarity * 50}G";
                var disBtnText = UIHelper.MakeText("Label", disBtn.transform, disLabel,
                    7f, TextAlignmentOptions.Center, UIColors.Text_Primary);
                disBtnText.fontStyle = FontStyles.Bold;
                UIHelper.FillParent(disBtnText.GetComponent<RectTransform>());

                string disId = equip.id;
                disBtn.onClick.AddListener(() =>
                {
                    int gold = EquipmentManager.Instance != null
                        ? EquipmentManager.Instance.DismantleItem(disId) : 0;
                    if (gold > 0)
                        ToastNotification.Instance?.Show($"분해 완료!", $"+{gold}G", UIColors.Text_Gold);
                    RefreshEquipmentUI();
                });
            }

            y -= (itemH + spacing);
        }

        TrimExcess(equipListItems, activeEquipCount);
        var containerRT = equipListContainer.GetComponent<RectTransform>();
        containerRT.sizeDelta = new Vector2(0, Mathf.Abs(y));
    }

    // ════════════════════════════════════════
    // 상점 탭 (index 4) - 서브탭: 상점/업적/설정
    // ════════════════════════════════════════

    int shopSubTab; // 0=상점, 1=업적, 2=미션, 3=도감, 4=아레나, 5=설정
    Button[] shopSubTabBtns;
    TextMeshProUGUI[] shopSubTabLabels;
    GameObject shopRoot;
    GameObject achieveRoot;
    GameObject missionRoot;
    GameObject collectionRoot;
    GameObject arenaRoot;
    GameObject settingsRoot;

    GameObject shopListContainer;
    readonly List<GameObject> shopListItems = new();

    void BuildShopContent(Transform parent)
    {
        var content = UIHelper.MakeUI("ShopContent", parent);
        var contentRT = content.GetComponent<RectTransform>();
        contentRT.anchorMin = Vector2.zero;
        contentRT.anchorMax = Vector2.one;
        contentRT.offsetMin = new Vector2(0, 0);
        contentRT.offsetMax = new Vector2(0, -UIConstants.Tab_Height);

        // 서브탭 바
        float subTabH = 28f;
        var subTabBar = UIHelper.MakePanel("ShopSubTabBar", content.transform, UIColors.Background_Dark);
        var stbRT = subTabBar.GetComponent<RectTransform>();
        stbRT.anchorMin = new Vector2(0, 1);
        stbRT.anchorMax = new Vector2(1, 1);
        stbRT.pivot = new Vector2(0.5f, 1);
        stbRT.sizeDelta = new Vector2(0, subTabH);

        string[] subNames = { "상점", "업적", "미션", "도감", "아레나", "설정" };
        int subCount = subNames.Length;
        shopSubTabBtns = new Button[subCount];
        shopSubTabLabels = new TextMeshProUGUI[subCount];

        for (int s = 0; s < subCount; s++)
        {
            float xMin = s / (float)subCount;
            float xMax = (s + 1) / (float)subCount;
            var (btn, _) = UIHelper.MakeButton($"ShopSub_{subNames[s]}", subTabBar.transform,
                UIColors.Tab_Inactive, "", 0);
            var brt = btn.GetComponent<RectTransform>();
            brt.anchorMin = new Vector2(xMin, 0);
            brt.anchorMax = new Vector2(xMax, 1);
            brt.offsetMin = new Vector2(1, 0);
            brt.offsetMax = new Vector2(-1, 0);

            var label = UIHelper.MakeText("Label", btn.transform, subNames[s],
                UIConstants.Font_Tab, TextAlignmentOptions.Center, UIColors.Text_Disabled);
            label.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(label.GetComponent<RectTransform>());

            shopSubTabBtns[s] = btn;
            shopSubTabLabels[s] = label;

            int captured = s;
            btn.onClick.AddListener(() => SwitchShopSubTab(captured));
        }

        // 상점 루트
        shopRoot = UIHelper.MakeUI("ShopRoot", content.transform);
        var srRT = shopRoot.GetComponent<RectTransform>();
        srRT.anchorMin = Vector2.zero;
        srRT.anchorMax = Vector2.one;
        srRT.offsetMin = Vector2.zero;
        srRT.offsetMax = new Vector2(0, -subTabH);
        BuildShopList(shopRoot.transform);

        // 업적 루트
        achieveRoot = UIHelper.MakeUI("AchieveRoot", content.transform);
        var arRT = achieveRoot.GetComponent<RectTransform>();
        arRT.anchorMin = Vector2.zero;
        arRT.anchorMax = Vector2.one;
        arRT.offsetMin = Vector2.zero;
        arRT.offsetMax = new Vector2(0, -subTabH);
        BuildAchievementList(achieveRoot.transform);

        // 미션 루트
        missionRoot = UIHelper.MakeUI("MissionRoot", content.transform);
        var mrRT = missionRoot.GetComponent<RectTransform>();
        mrRT.anchorMin = Vector2.zero;
        mrRT.anchorMax = Vector2.one;
        mrRT.offsetMin = Vector2.zero;
        mrRT.offsetMax = new Vector2(0, -subTabH);
        BuildMissionList(missionRoot.transform);

        // 도감 루트
        collectionRoot = UIHelper.MakeUI("CollectionRoot", content.transform);
        var crRT = collectionRoot.GetComponent<RectTransform>();
        crRT.anchorMin = Vector2.zero;
        crRT.anchorMax = Vector2.one;
        crRT.offsetMin = Vector2.zero;
        crRT.offsetMax = new Vector2(0, -subTabH);
        BuildCollectionContent(collectionRoot.transform);

        // 아레나 루트
        arenaRoot = UIHelper.MakeUI("ArenaRoot", content.transform);
        var anRT = arenaRoot.GetComponent<RectTransform>();
        anRT.anchorMin = Vector2.zero;
        anRT.anchorMax = Vector2.one;
        anRT.offsetMin = Vector2.zero;
        anRT.offsetMax = new Vector2(0, -subTabH);
        BuildArenaContent(arenaRoot.transform);

        // 설정 루트
        settingsRoot = UIHelper.MakeUI("SettingsRoot", content.transform);
        var setRT = settingsRoot.GetComponent<RectTransform>();
        setRT.anchorMin = Vector2.zero;
        setRT.anchorMax = Vector2.one;
        setRT.offsetMin = Vector2.zero;
        setRT.offsetMax = new Vector2(0, -subTabH);
        BuildSettingsContent(settingsRoot.transform);

        shopSubTab = 0;
        UpdateShopSubTabVisuals();
    }

    void SwitchShopSubTab(int subIdx)
    {
        SoundManager.Instance?.PlayButtonSFX();
        shopSubTab = subIdx;
        UpdateShopSubTabVisuals();
        RefreshCurrentShopSubTab();
    }

    void UpdateShopSubTabVisuals()
    {
        if (shopSubTabBtns == null) return;
        for (int i = 0; i < shopSubTabBtns.Length; i++)
        {
            bool active = (i == shopSubTab);
            shopSubTabBtns[i].GetComponent<Image>().color = active ? UIColors.Tab_Active : UIColors.Tab_Inactive;
            shopSubTabLabels[i].color = active ? UIColors.Text_TabActive : UIColors.Text_Disabled;
        }
        if (shopRoot != null) shopRoot.SetActive(shopSubTab == 0);
        if (achieveRoot != null) achieveRoot.SetActive(shopSubTab == 1);
        if (missionRoot != null) missionRoot.SetActive(shopSubTab == 2);
        if (collectionRoot != null) collectionRoot.SetActive(shopSubTab == 3);
        if (arenaRoot != null) arenaRoot.SetActive(shopSubTab == 4);
        if (settingsRoot != null) settingsRoot.SetActive(shopSubTab == 5);
    }

    void RefreshCurrentShopSubTab()
    {
        switch (shopSubTab)
        {
            case 0: RefreshShopList(); break;
            case 1: RefreshAchievementUI(); break;
            case 2: RefreshMissionUI(); break;
            case 3: RefreshCollectionUI(); break;
            case 4: RefreshArenaUI(); break;
            case 5: RefreshSettingsUI(); break;
        }
    }

    void RefreshShopUI()
    {
        UpdateShopSubTabVisuals();
        RefreshCurrentShopSubTab();
    }

    // ── 상점 리스트 ──

    void BuildShopList(Transform parent)
    {
        var scrollObj = UIHelper.MakeUI("ShopScroll", parent);
        var scrollRT = scrollObj.GetComponent<RectTransform>();
        scrollRT.anchorMin = Vector2.zero;
        scrollRT.anchorMax = Vector2.one;
        scrollRT.offsetMin = new Vector2(UIConstants.Spacing_Small, UIConstants.Spacing_Small);
        scrollRT.offsetMax = new Vector2(-UIConstants.Spacing_Small, 0);

        var scrollRect = scrollObj.AddComponent<ScrollRect>();
        scrollRect.horizontal = false;
        scrollRect.vertical = true;

        var viewport = UIHelper.MakeUI("Viewport", scrollObj.transform);
        viewport.AddComponent<RectMask2D>();
        UIHelper.FillParent(viewport.GetComponent<RectTransform>());
        scrollRect.viewport = viewport.GetComponent<RectTransform>();

        shopListContainer = UIHelper.MakeUI("Content", viewport.transform);
        var hcRT = shopListContainer.GetComponent<RectTransform>();
        hcRT.anchorMin = new Vector2(0, 1);
        hcRT.anchorMax = new Vector2(1, 1);
        hcRT.pivot = new Vector2(0.5f, 1);
        hcRT.anchoredPosition = Vector2.zero;
        scrollRect.content = hcRT;
    }

    void RefreshShopList()
    {
        if (shopListContainer == null) return;
        var shop = ShopManager.Instance;
        if (shop == null) return;

        RecycleList(shopListItems);
        int shopReuse = 0;

        var items = shop.GetStockItems();
        float itemH = 44f;
        float spacing = 2f;
        float y = 0;
        int activeShopCount = 0;

        for (int i = 0; i < items.Count; i++)
        {
            var shopItem = items[i];

            var item = ReuseOrCreate(shopListItems, ref shopReuse,
                $"Shop_{i}", shopListContainer.transform, UIColors.Panel_Inner);
            activeShopCount++;
            var irt = item.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0, 1);
            irt.anchorMax = new Vector2(1, 1);
            irt.pivot = new Vector2(0.5f, 1);
            irt.anchoredPosition = new Vector2(0, y);
            irt.sizeDelta = new Vector2(0, itemH);

            var nameText = UIHelper.MakeText("Name", item.transform, shopItem.displayName,
                UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, UIColors.Text_Primary);
            nameText.fontStyle = FontStyles.Bold;
            var nrt = nameText.GetComponent<RectTransform>();
            nrt.anchorMin = new Vector2(0, 0.5f);
            nrt.anchorMax = new Vector2(0.4f, 1);
            nrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
            nrt.offsetMax = Vector2.zero;

            var descText = UIHelper.MakeText("Desc", item.transform, shopItem.description,
                8f, TextAlignmentOptions.MidlineLeft, UIColors.Text_Secondary);
            var drt = descText.GetComponent<RectTransform>();
            drt.anchorMin = new Vector2(0, 0);
            drt.anchorMax = new Vector2(0.4f, 0.5f);
            drt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
            drt.offsetMax = Vector2.zero;

            string priceStr = shopItem.gemCost > 0 ? $"{shopItem.gemCost} 보석" :
                              shopItem.goldCost > 0 ? $"{shopItem.goldCost}G" : "무료";
            var priceText = UIHelper.MakeText("Price", item.transform, priceStr,
                9f, TextAlignmentOptions.Center, UIColors.Text_Diamond);
            var prt = priceText.GetComponent<RectTransform>();
            prt.anchorMin = new Vector2(0.4f, 0);
            prt.anchorMax = new Vector2(0.65f, 1);
            prt.offsetMin = Vector2.zero;
            prt.offsetMax = Vector2.zero;

            bool canBuy = shop.CanPurchase(shopItem);
            float cooldown = shop.GetRemainingCooldown(shopItem);
            string btnLabel = cooldown > 0 ? $"{Mathf.CeilToInt(cooldown / 60f)}분" : "구매";

            var (btn, _) = UIHelper.MakeButton($"Buy_{i}", item.transform,
                canBuy ? UIColors.Button_Green : UIColors.Button_Gray, "", 10f);
            var btnRT = btn.GetComponent<RectTransform>();
            btnRT.anchorMin = new Vector2(0.68f, 0.1f);
            btnRT.anchorMax = new Vector2(0.97f, 0.9f);
            btnRT.offsetMin = Vector2.zero;
            btnRT.offsetMax = Vector2.zero;

            var btnText = UIHelper.MakeText("Label", btn.transform, btnLabel,
                UIConstants.Font_Cost, TextAlignmentOptions.Center,
                canBuy ? UIColors.Text_Primary : UIColors.Text_Disabled);
            btnText.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(btnText.GetComponent<RectTransform>());

            {
                var capturedItem = shopItem;
                btn.onClick.AddListener(() =>
                {
                    if (!shop.CanPurchase(capturedItem))
                    {
                        string currency = capturedItem.gemCost > 0 ? "보석" : "골드";
                        ToastNotification.Instance?.Show($"{currency} 부족!", "", UIColors.Defeat_Red);
                        return;
                    }
                    if (capturedItem.gemCost > 0)
                    {
                        ShowConfirm("구매 확인", $"보석 {capturedItem.gemCost}개를 사용합니다.\n진행하시겠습니까?", () =>
                        {
                            shop.Purchase(capturedItem);
                            SoundManager.Instance?.PlayGoldSFX();
                            RefreshShopList();
                        });
                    }
                    else
                    {
                        shop.Purchase(capturedItem);
                        SoundManager.Instance?.PlayGoldSFX();
                        RefreshShopList();
                    }
                });
            }

            y -= (itemH + spacing);
        }

        TrimExcess(shopListItems, activeShopCount);
        var srt2 = shopListContainer.GetComponent<RectTransform>();
        srt2.sizeDelta = new Vector2(0, Mathf.Abs(y));
    }

    // ════════════════════════════════════════
    // 업적 리스트
    // ════════════════════════════════════════

    void BuildAchievementList(Transform parent)
    {
        var scrollObj = UIHelper.MakeUI("AchieveScroll", parent);
        var scrollRT = scrollObj.GetComponent<RectTransform>();
        scrollRT.anchorMin = Vector2.zero;
        scrollRT.anchorMax = Vector2.one;
        scrollRT.offsetMin = new Vector2(UIConstants.Spacing_Small, UIConstants.Spacing_Small);
        scrollRT.offsetMax = new Vector2(-UIConstants.Spacing_Small, 0);

        var scrollRect = scrollObj.AddComponent<ScrollRect>();
        scrollRect.horizontal = false;
        scrollRect.vertical = true;

        var viewport = UIHelper.MakeUI("Viewport", scrollObj.transform);
        viewport.AddComponent<RectMask2D>();
        UIHelper.FillParent(viewport.GetComponent<RectTransform>());
        scrollRect.viewport = viewport.GetComponent<RectTransform>();

        achieveListContainer = UIHelper.MakeUI("Content", viewport.transform);
        var hcRT = achieveListContainer.GetComponent<RectTransform>();
        hcRT.anchorMin = new Vector2(0, 1);
        hcRT.anchorMax = new Vector2(1, 1);
        hcRT.pivot = new Vector2(0.5f, 1);
        hcRT.anchoredPosition = Vector2.zero;
        scrollRect.content = hcRT;
    }

    void RefreshAchievementUI()
    {
        if (achieveListContainer == null) return;
        var am = AchievementManager.Instance;
        if (am == null) return;

        RecycleList(achieveListItems);
        int achReuse = 0;

        var achievements = am.GetAchievements();
        float itemH = 42f;
        float spacing = 2f;
        float y = 0;
        int activeAchCount = 0;

        for (int i = 0; i < achievements.Count; i++)
        {
            var ach = achievements[i];

            Color bgColor = ach.claimed ? UIColors.Panel_Inner :
                            ach.completed ? UIColors.Panel_Selected : UIColors.Panel_Inner;

            var item = ReuseOrCreate(achieveListItems, ref achReuse,
                $"Ach_{i}", achieveListContainer.transform, bgColor);
            activeAchCount++;
            var irt = item.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0, 1);
            irt.anchorMax = new Vector2(1, 1);
            irt.pivot = new Vector2(0.5f, 1);
            irt.anchoredPosition = new Vector2(0, y);
            irt.sizeDelta = new Vector2(0, itemH);

            // 이름
            Color nameColor = ach.completed ? UIColors.Text_Primary : UIColors.Text_Disabled;
            var nameText = UIHelper.MakeText("Name", item.transform, ach.name,
                UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, nameColor);
            nameText.fontStyle = FontStyles.Bold;
            var nrt = nameText.GetComponent<RectTransform>();
            nrt.anchorMin = new Vector2(0, 0.5f);
            nrt.anchorMax = new Vector2(0.45f, 1);
            nrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
            nrt.offsetMax = Vector2.zero;

            // 설명
            var descText = UIHelper.MakeText("Desc", item.transform, ach.description,
                8f, TextAlignmentOptions.MidlineLeft, UIColors.Text_Secondary);
            var drt2 = descText.GetComponent<RectTransform>();
            drt2.anchorMin = new Vector2(0, 0);
            drt2.anchorMax = new Vector2(0.45f, 0.5f);
            drt2.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
            drt2.offsetMax = Vector2.zero;

            // 보상
            var rewardText = UIHelper.MakeText("Reward", item.transform, $"{ach.gemReward} 보석",
                9f, TextAlignmentOptions.Center, UIColors.Text_Diamond);
            var rrt = rewardText.GetComponent<RectTransform>();
            rrt.anchorMin = new Vector2(0.45f, 0);
            rrt.anchorMax = new Vector2(0.68f, 1);
            rrt.offsetMin = Vector2.zero;
            rrt.offsetMax = Vector2.zero;

            // 버튼
            string btnLabel;
            Color btnColor;
            if (ach.claimed) { btnLabel = "완료"; btnColor = UIColors.Button_Gray; }
            else if (ach.completed) { btnLabel = "수령"; btnColor = UIColors.Button_Yellow; }
            else { btnLabel = "미달성"; btnColor = UIColors.Button_Gray; }

            var (btn, _) = UIHelper.MakeButton($"AchBtn_{i}", item.transform, btnColor, "", 10f);
            var btnRT = btn.GetComponent<RectTransform>();
            btnRT.anchorMin = new Vector2(0.70f, 0.1f);
            btnRT.anchorMax = new Vector2(0.97f, 0.9f);
            btnRT.offsetMin = Vector2.zero;
            btnRT.offsetMax = Vector2.zero;

            Color btnTextColor = ach.completed && !ach.claimed ? UIColors.Background_Dark : UIColors.Text_Disabled;
            var btnText = UIHelper.MakeText("Label", btn.transform, btnLabel,
                UIConstants.Font_Cost, TextAlignmentOptions.Center, btnTextColor);
            btnText.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(btnText.GetComponent<RectTransform>());

            if (ach.completed && !ach.claimed)
            {
                string capturedId = ach.id;
                btn.onClick.AddListener(() =>
                {
                    am.ClaimReward(capturedId);
                    SoundManager.Instance?.PlayGoldSFX();
                    ToastNotification.Instance?.Show("보상 수령!", "", UIColors.Text_Diamond);
                    RefreshAchievementUI();
                });
            }

            y -= (itemH + spacing);
        }

        TrimExcess(achieveListItems, activeAchCount);
        var containerRT = achieveListContainer.GetComponent<RectTransform>();
        containerRT.sizeDelta = new Vector2(0, Mathf.Abs(y));
    }

    // ════════════════════════════════════════
    // 미션 리스트
    // ════════════════════════════════════════

    GameObject missionListContainer;
    readonly List<GameObject> missionListItems = new();

    void BuildMissionList(Transform parent)
    {
        var scrollObj = UIHelper.MakeUI("MissionScroll", parent);
        var scrollRT = scrollObj.GetComponent<RectTransform>();
        scrollRT.anchorMin = Vector2.zero;
        scrollRT.anchorMax = Vector2.one;
        scrollRT.offsetMin = new Vector2(UIConstants.Spacing_Small, UIConstants.Spacing_Small);
        scrollRT.offsetMax = new Vector2(-UIConstants.Spacing_Small, 0);

        var scrollRect = scrollObj.AddComponent<ScrollRect>();
        scrollRect.horizontal = false;
        scrollRect.vertical = true;

        var viewport = UIHelper.MakeUI("Viewport", scrollObj.transform);
        viewport.AddComponent<RectMask2D>();
        UIHelper.FillParent(viewport.GetComponent<RectTransform>());
        scrollRect.viewport = viewport.GetComponent<RectTransform>();

        missionListContainer = UIHelper.MakeUI("Content", viewport.transform);
        var hcRT = missionListContainer.GetComponent<RectTransform>();
        hcRT.anchorMin = new Vector2(0, 1);
        hcRT.anchorMax = new Vector2(1, 1);
        hcRT.pivot = new Vector2(0.5f, 1);
        hcRT.anchoredPosition = Vector2.zero;
        scrollRect.content = hcRT;
    }

    void RefreshMissionUI()
    {
        if (missionListContainer == null) return;
        var mm = DailyMissionManager.Instance;
        if (mm == null) return;

        RecycleList(missionListItems);
        int missionReuse = 0;

        var missions = mm.GetMissions();
        float itemH = 42f;
        float spacing = 2f;
        float y = 0;
        int activeMissionCount = 0;

        for (int i = 0; i < missions.Count; i++)
        {
            var mission = missions[i];
            bool completed = mission.currentCount >= mission.targetCount;

            Color bgColor = mission.claimed ? UIColors.Panel_Inner :
                            completed ? UIColors.Panel_Selected : UIColors.Panel_Inner;

            var item = ReuseOrCreate(missionListItems, ref missionReuse,
                $"Mission_{i}", missionListContainer.transform, bgColor);
            activeMissionCount++;
            var irt = item.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0, 1);
            irt.anchorMax = new Vector2(1, 1);
            irt.pivot = new Vector2(0.5f, 1);
            irt.anchoredPosition = new Vector2(0, y);
            irt.sizeDelta = new Vector2(0, itemH);

            // 미션명
            Color nameColor = completed ? UIColors.Text_Primary : UIColors.Text_Disabled;
            var nameText = UIHelper.MakeText("Name", item.transform, mission.name,
                UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, nameColor);
            nameText.fontStyle = FontStyles.Bold;
            var nrt = nameText.GetComponent<RectTransform>();
            nrt.anchorMin = new Vector2(0, 0.5f);
            nrt.anchorMax = new Vector2(0.4f, 1);
            nrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
            nrt.offsetMax = Vector2.zero;

            // 진행도
            string progressStr = $"{mission.currentCount}/{mission.targetCount}";
            Color progColor = completed ? UIColors.Text_Green : UIColors.Text_Secondary;
            var progText = UIHelper.MakeText("Progress", item.transform, progressStr,
                9f, TextAlignmentOptions.MidlineLeft, progColor);
            var prt = progText.GetComponent<RectTransform>();
            prt.anchorMin = new Vector2(0, 0);
            prt.anchorMax = new Vector2(0.4f, 0.5f);
            prt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
            prt.offsetMax = Vector2.zero;

            // 보상
            var rewardText = UIHelper.MakeText("Reward", item.transform, $"{mission.gemReward} 보석",
                9f, TextAlignmentOptions.Center, UIColors.Text_Diamond);
            var rrt = rewardText.GetComponent<RectTransform>();
            rrt.anchorMin = new Vector2(0.4f, 0);
            rrt.anchorMax = new Vector2(0.65f, 1);
            rrt.offsetMin = Vector2.zero;
            rrt.offsetMax = Vector2.zero;

            // 버튼
            string btnLabel;
            Color btnColor;
            if (mission.claimed) { btnLabel = "완료"; btnColor = UIColors.Button_Gray; }
            else if (completed) { btnLabel = "수령"; btnColor = UIColors.Button_Yellow; }
            else { btnLabel = "진행중"; btnColor = UIColors.Button_Gray; }

            var (btn, _) = UIHelper.MakeButton($"MissionBtn_{i}", item.transform, btnColor, "", 10f);
            var btnRT = btn.GetComponent<RectTransform>();
            btnRT.anchorMin = new Vector2(0.68f, 0.1f);
            btnRT.anchorMax = new Vector2(0.97f, 0.9f);
            btnRT.offsetMin = Vector2.zero;
            btnRT.offsetMax = Vector2.zero;

            Color btnTextColor = completed && !mission.claimed ? UIColors.Background_Dark : UIColors.Text_Disabled;
            var btnText = UIHelper.MakeText("Label", btn.transform, btnLabel,
                UIConstants.Font_Cost, TextAlignmentOptions.Center, btnTextColor);
            btnText.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(btnText.GetComponent<RectTransform>());

            if (completed && !mission.claimed)
            {
                string capturedId = mission.id;
                btn.onClick.AddListener(() =>
                {
                    mm.ClaimReward(capturedId);
                    SoundManager.Instance?.PlayGoldSFX();
                    ToastNotification.Instance?.Show("미션 보상!", "", UIColors.Text_Diamond);
                    RefreshMissionUI();
                });
            }

            y -= (itemH + spacing);
        }

        TrimExcess(missionListItems, activeMissionCount);
        var containerRT = missionListContainer.GetComponent<RectTransform>();
        containerRT.sizeDelta = new Vector2(0, Mathf.Abs(y));
    }

    // ════════════════════════════════════════
    // 설정 패널 (상점 탭 서브탭)
    // ════════════════════════════════════════

    Slider settingsBgmSlider;
    Slider settingsSfxSlider;
    TextMeshProUGUI bgmValueText;
    TextMeshProUGUI sfxValueText;

    void BuildSettingsContent(Transform parent)
    {
        var content = UIHelper.MakeUI("SettingsContent", parent);
        var crt = content.GetComponent<RectTransform>();
        crt.anchorMin = Vector2.zero;
        crt.anchorMax = Vector2.one;
        crt.offsetMin = new Vector2(UIConstants.Spacing_Medium, UIConstants.Spacing_Medium);
        crt.offsetMax = new Vector2(-UIConstants.Spacing_Medium, 0);

        // BGM Volume
        BuildVolumeSlider(content.transform, "BGM 볼륨", 0.7f, 1f,
            out settingsBgmSlider, out bgmValueText, (val) =>
            {
                SoundManager.Instance?.SetBGMVolume(val);
                if (bgmValueText != null) bgmValueText.text = $"{Mathf.RoundToInt(val * 100)}%";
            });

        // SFX Volume
        BuildVolumeSlider(content.transform, "SFX 볼륨", 0.4f, 1f,
            out settingsSfxSlider, out sfxValueText, (val) =>
            {
                SoundManager.Instance?.SetSFXVolume(val);
                if (sfxValueText != null) sfxValueText.text = $"{Mathf.RoundToInt(val * 100)}%";
            });

        // 데이터 초기화 버튼
        var (resetBtn, _) = UIHelper.MakeButton("ResetBtn", content.transform,
            UIColors.Defeat_Red, "", UIConstants.Font_Button);
        var rbrt = resetBtn.GetComponent<RectTransform>();
        rbrt.anchorMin = new Vector2(0.15f, 0.05f);
        rbrt.anchorMax = new Vector2(0.85f, 0.2f);
        rbrt.offsetMin = Vector2.zero;
        rbrt.offsetMax = Vector2.zero;

        var resetText = UIHelper.MakeText("Label", resetBtn.transform, "데이터 초기화",
            UIConstants.Font_Button, TextAlignmentOptions.Center, UIColors.Text_Primary);
        resetText.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(resetText.GetComponent<RectTransform>());

        resetBtn.onClick.AddListener(OnResetData);
    }

    void BuildVolumeSlider(Transform parent, string label, float yMin, float yMax,
        out Slider slider, out TextMeshProUGUI valueText, UnityEngine.Events.UnityAction<float> onChange)
    {
        // Row container
        var row = UIHelper.MakePanel($"{label}Row", parent, UIColors.Panel_Inner);
        var rrt = row.GetComponent<RectTransform>();
        rrt.anchorMin = new Vector2(0, yMin);
        rrt.anchorMax = new Vector2(1, yMax);
        rrt.offsetMin = new Vector2(0, 2);
        rrt.offsetMax = new Vector2(0, -2);

        // Label
        var labelText = UIHelper.MakeText("Label", row.transform, label,
            UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, UIColors.Text_Secondary);
        labelText.fontStyle = FontStyles.Bold;
        var lrt = labelText.GetComponent<RectTransform>();
        lrt.anchorMin = new Vector2(0, 0);
        lrt.anchorMax = new Vector2(0.25f, 1);
        lrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
        lrt.offsetMax = Vector2.zero;

        // Slider
        var sliderObj = UIHelper.MakeUI("Slider", row.transform);
        slider = sliderObj.AddComponent<Slider>();
        slider.minValue = 0;
        slider.maxValue = 1;
        slider.wholeNumbers = false;

        var srt = sliderObj.GetComponent<RectTransform>();
        srt.anchorMin = new Vector2(0.27f, 0.2f);
        srt.anchorMax = new Vector2(0.78f, 0.8f);
        srt.offsetMin = Vector2.zero;
        srt.offsetMax = Vector2.zero;

        // Slider background
        var bgObj = UIHelper.MakePanel("Background", sliderObj.transform, UIColors.ProgressBar_BG);
        UIHelper.FillParent(bgObj.GetComponent<RectTransform>());
        slider.targetGraphic = bgObj;

        // Fill area
        var fillArea = UIHelper.MakeUI("Fill Area", sliderObj.transform);
        var fart = fillArea.GetComponent<RectTransform>();
        fart.anchorMin = Vector2.zero;
        fart.anchorMax = Vector2.one;
        fart.offsetMin = Vector2.zero;
        fart.offsetMax = Vector2.zero;

        var fillObj = UIHelper.MakePanel("Fill", fillArea.transform, UIColors.ProgressBar_Fill);
        var fillRT = fillObj.GetComponent<RectTransform>();
        fillRT.anchorMin = Vector2.zero;
        fillRT.anchorMax = Vector2.one;
        fillRT.offsetMin = Vector2.zero;
        fillRT.offsetMax = Vector2.zero;
        slider.fillRect = fillRT;

        // Handle area
        var handleArea = UIHelper.MakeUI("Handle Slide Area", sliderObj.transform);
        var hart = handleArea.GetComponent<RectTransform>();
        hart.anchorMin = Vector2.zero;
        hart.anchorMax = Vector2.one;
        hart.offsetMin = Vector2.zero;
        hart.offsetMax = Vector2.zero;

        var handleObj = UIHelper.MakePanel("Handle", handleArea.transform, UIColors.Text_Primary);
        var hrt = handleObj.GetComponent<RectTransform>();
        hrt.sizeDelta = new Vector2(14, 0);
        slider.handleRect = hrt;

        // Value text
        valueText = UIHelper.MakeText("Value", row.transform, "50%",
            UIConstants.Font_StatValue, TextAlignmentOptions.Center, UIColors.Text_Primary);
        valueText.fontStyle = FontStyles.Bold;
        var vrt = valueText.GetComponent<RectTransform>();
        vrt.anchorMin = new Vector2(0.80f, 0);
        vrt.anchorMax = new Vector2(1, 1);
        vrt.offsetMin = Vector2.zero;
        vrt.offsetMax = Vector2.zero;

        slider.onValueChanged.AddListener(onChange);
    }

    void RefreshSettingsUI()
    {
        var sm = SoundManager.Instance;
        if (sm == null) return;
        if (settingsBgmSlider != null)
        {
            settingsBgmSlider.SetValueWithoutNotify(sm.bgmVolume);
            if (bgmValueText != null) bgmValueText.text = $"{Mathf.RoundToInt(sm.bgmVolume * 100)}%";
        }
        if (settingsSfxSlider != null)
        {
            settingsSfxSlider.SetValueWithoutNotify(sm.sfxVolume);
            if (sfxValueText != null) sfxValueText.text = $"{Mathf.RoundToInt(sm.sfxVolume * 100)}%";
        }
    }

    void OnResetData()
    {
        PlayerPrefs.DeleteAll();
        PlayerPrefs.Save();
        ToastNotification.Instance?.Show("데이터 초기화", "게임을 재시작합니다", UIColors.Defeat_Red);
    }

    // ════════════════════════════════════════
    // 오프라인 보상 팝업
    // ════════════════════════════════════════

    void CreateOfflinePopup()
    {
        offlinePopup = UIHelper.MakeUI("OfflinePopup", safeAreaRoot.transform);
        var bg = offlinePopup.AddComponent<Image>();
        bg.color = UIColors.Overlay_Dark;
        UIHelper.FillParent(offlinePopup.GetComponent<RectTransform>());

        // Center panel
        var panel = UIHelper.MakePanel("Panel", offlinePopup.transform, UIColors.Background_Panel);
        var panelOutline = panel.gameObject.AddComponent<Outline>();
        panelOutline.effectColor = UIColors.Panel_Border;
        panelOutline.effectDistance = new Vector2(2, 2);
        var prt = panel.GetComponent<RectTransform>();
        prt.anchorMin = new Vector2(0.1f, 0.35f);
        prt.anchorMax = new Vector2(0.9f, 0.65f);
        prt.offsetMin = Vector2.zero;
        prt.offsetMax = Vector2.zero;

        // Title
        var titleText = UIHelper.MakeText("Title", panel.transform, "오프라인 보상",
            UIConstants.Font_HeaderLarge, TextAlignmentOptions.Center, UIColors.Text_Gold);
        titleText.fontStyle = FontStyles.Bold;
        var trt = titleText.GetComponent<RectTransform>();
        trt.anchorMin = new Vector2(0, 0.7f);
        trt.anchorMax = new Vector2(1, 0.95f);
        trt.offsetMin = Vector2.zero;
        trt.offsetMax = Vector2.zero;

        // Reward text
        offlineText = UIHelper.MakeText("RewardText", panel.transform, "",
            UIConstants.Font_StatValue, TextAlignmentOptions.Center, UIColors.Text_Primary);
        var rrt = offlineText.GetComponent<RectTransform>();
        rrt.anchorMin = new Vector2(0, 0.3f);
        rrt.anchorMax = new Vector2(1, 0.7f);
        rrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
        rrt.offsetMax = new Vector2(-UIConstants.Spacing_Medium, 0);

        // Confirm button
        var (confirmBtn, _) = UIHelper.MakeButton("ConfirmBtn", panel.transform,
            UIColors.Button_Green, "", UIConstants.Font_Button);
        var cbrt = confirmBtn.GetComponent<RectTransform>();
        cbrt.anchorMin = new Vector2(0.25f, 0.05f);
        cbrt.anchorMax = new Vector2(0.75f, 0.28f);
        cbrt.offsetMin = Vector2.zero;
        cbrt.offsetMax = Vector2.zero;

        var confirmText = UIHelper.MakeText("Label", confirmBtn.transform, "확인",
            UIConstants.Font_Button, TextAlignmentOptions.Center, UIColors.Text_Primary);
        confirmText.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(confirmText.GetComponent<RectTransform>());

        confirmBtn.onClick.AddListener(() =>
        {
            offlinePopup.SetActive(false);
            SoundManager.Instance?.PlayButtonSFX();
        });

        offlinePopup.SetActive(false);
    }

    void OnOfflineReward(int gold, int gem, float minutes)
    {
        if (offlinePopup == null || offlineText == null) return;
        if (gold <= 0 && gem <= 0) return;

        int mins = Mathf.FloorToInt(minutes);
        string timeStr = mins >= 60 ? $"{mins / 60}시간 {mins % 60}분" : $"{mins}분";

        string rewardStr = $"접속하지 않은 {timeStr} 동안\n";
        if (gold > 0) rewardStr += $"<color=#FFD700>골드 +{gold}</color>  ";
        if (gem > 0) rewardStr += $"<color=#87CEEB>보석 +{gem}</color>";

        offlineText.text = rewardStr;
        offlinePopup.SetActive(true);
    }

    // ════════════════════════════════════════
    // 영웅 선택 팝업 (장비 장착용)
    // ════════════════════════════════════════

    void CreateHeroSelectPopup()
    {
        heroSelectPopup = UIHelper.MakeUI("HeroSelectPopup", safeAreaRoot.transform);
        var bg = heroSelectPopup.AddComponent<Image>();
        bg.color = UIColors.Overlay_Dark;
        UIHelper.FillParent(heroSelectPopup.GetComponent<RectTransform>());

        // 닫기용 풀스크린 버튼
        var tapClose = heroSelectPopup.AddComponent<Button>();
        tapClose.targetGraphic = bg;
        tapClose.onClick.AddListener(() => heroSelectPopup.SetActive(false));

        // 패널
        var panel = UIHelper.MakePanel("Panel", heroSelectPopup.transform, UIColors.Background_Panel);
        var panelOutline = panel.gameObject.AddComponent<Outline>();
        panelOutline.effectColor = UIColors.Panel_Border;
        panelOutline.effectDistance = new Vector2(2, 2);
        var prt = panel.GetComponent<RectTransform>();
        prt.anchorMin = new Vector2(0.08f, 0.25f);
        prt.anchorMax = new Vector2(0.92f, 0.75f);
        prt.offsetMin = Vector2.zero;
        prt.offsetMax = Vector2.zero;

        // 타이틀 바
        var titleBar = UIHelper.MakeUI("TitleBar", panel.transform);
        var titleBarRT = titleBar.GetComponent<RectTransform>();
        titleBarRT.anchorMin = new Vector2(0, 0.88f);
        titleBarRT.anchorMax = new Vector2(1, 1);
        titleBarRT.offsetMin = Vector2.zero;
        titleBarRT.offsetMax = Vector2.zero;

        var titleText = UIHelper.MakeText("Title", titleBar.transform, "장비 장착할 영웅 선택",
            UIConstants.Font_HeaderMedium, TextAlignmentOptions.Center, UIColors.Text_Gold);
        titleText.fontStyle = FontStyles.Bold;
        var trt = titleText.GetComponent<RectTransform>();
        trt.anchorMin = new Vector2(0.1f, 0);
        trt.anchorMax = new Vector2(0.9f, 1);
        trt.offsetMin = Vector2.zero;
        trt.offsetMax = Vector2.zero;

        // X 닫기 버튼
        var (closeBtn, _) = UIHelper.MakeButton("CloseBtn", titleBar.transform,
            UIColors.Button_Brown, "", 10f);
        var closeBtnRT = closeBtn.GetComponent<RectTransform>();
        closeBtnRT.anchorMin = new Vector2(1, 0);
        closeBtnRT.anchorMax = new Vector2(1, 1);
        closeBtnRT.pivot = new Vector2(1, 0.5f);
        closeBtnRT.sizeDelta = new Vector2(36, 0);
        closeBtnRT.anchoredPosition = new Vector2(-4, 0);

        var closeBtnText = UIHelper.MakeText("X", closeBtn.transform, "X",
            UIConstants.Font_HeaderMedium, TextAlignmentOptions.Center, UIColors.Text_Primary);
        closeBtnText.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(closeBtnText.GetComponent<RectTransform>());
        closeBtn.onClick.AddListener(() => heroSelectPopup.SetActive(false));

        // 스크롤 리스트
        var scrollObj = UIHelper.MakeUI("HeroScroll", panel.transform);
        var scrollRT = scrollObj.GetComponent<RectTransform>();
        scrollRT.anchorMin = new Vector2(0, 0);
        scrollRT.anchorMax = new Vector2(1, 0.86f);
        scrollRT.offsetMin = new Vector2(UIConstants.Spacing_Small, UIConstants.Spacing_Small);
        scrollRT.offsetMax = new Vector2(-UIConstants.Spacing_Small, 0);

        var scrollRect = scrollObj.AddComponent<ScrollRect>();
        scrollRect.horizontal = false;
        scrollRect.vertical = true;

        var viewport = UIHelper.MakeUI("Viewport", scrollObj.transform);
        viewport.AddComponent<RectMask2D>();
        UIHelper.FillParent(viewport.GetComponent<RectTransform>());
        scrollRect.viewport = viewport.GetComponent<RectTransform>();

        heroSelectListContainer = UIHelper.MakeUI("Content", viewport.transform);
        var hcRT = heroSelectListContainer.GetComponent<RectTransform>();
        hcRT.anchorMin = new Vector2(0, 1);
        hcRT.anchorMax = new Vector2(1, 1);
        hcRT.pivot = new Vector2(0.5f, 1);
        hcRT.anchoredPosition = Vector2.zero;
        scrollRect.content = hcRT;

        heroSelectPopup.SetActive(false);
    }

    void ShowHeroSelectPopup(string equipItemId)
    {
        pendingEquipItemId = equipItemId;
        RefreshHeroSelectList();
        heroSelectPopup.SetActive(true);
        SoundManager.Instance?.PlayButtonSFX();
    }

    /// <summary>
    /// HeroRarity → 표시용 컬러 매핑
    /// </summary>
    static Color GetHeroRarityColor(HeroRarity rarity)
    {
        return rarity switch
        {
            HeroRarity.Common    => UIColors.Rarity_Common,
            HeroRarity.Rare      => UIColors.Rarity_Rare,
            HeroRarity.Epic      => UIColors.Rarity_Epic,
            HeroRarity.Legendary => UIColors.Rarity_Legendary,
            _                    => UIColors.Text_Secondary
        };
    }

    /// <summary>
    /// HeroRarity → 한글 표시
    /// </summary>
    static string GetHeroRarityLabel(HeroRarity rarity)
    {
        return rarity switch
        {
            HeroRarity.Common    => "일반",
            HeroRarity.Rare      => "레어",
            HeroRarity.Epic      => "에픽",
            HeroRarity.Legendary => "전설",
            _                    => ""
        };
    }

    void RefreshHeroSelectList()
    {
        if (heroSelectListContainer == null) return;
        var dm = DeckManager.Instance;
        if (dm == null) return;

        for (int i = 0; i < heroSelectItems.Count; i++)
            if (heroSelectItems[i] != null) Object.Destroy(heroSelectItems[i]);
        heroSelectItems.Clear();

        float itemH = 48f;
        float spacing = 3f;
        float y = 0;

        // 장착 대상 장비 정보 표시
        EquipmentItem pendingItem = null;
        if (EquipmentManager.Instance != null)
        {
            var inv = EquipmentManager.Instance.Inventory;
            for (int i = 0; i < inv.Count; i++)
                if (inv[i].id == pendingEquipItemId) { pendingItem = inv[i]; break; }
        }

        if (pendingItem != null)
        {
            var infoImg = UIHelper.MakePanel("EquipInfo", heroSelectListContainer.transform, UIColors.Background_Dark);
            heroSelectItems.Add(infoImg.gameObject);
            var infoRT = infoImg.GetComponent<RectTransform>();
            infoRT.anchorMin = new Vector2(0, 1);
            infoRT.anchorMax = new Vector2(1, 1);
            infoRT.pivot = new Vector2(0.5f, 1);
            infoRT.anchoredPosition = new Vector2(0, y);
            infoRT.sizeDelta = new Vector2(0, 32f);

            string stars = new string('\u2605', pendingItem.rarity);
            string statStr = "";
            if (pendingItem.bonusAtk > 0) statStr += $"ATK+{pendingItem.bonusAtk:F0} ";
            if (pendingItem.bonusDef > 0) statStr += $"DEF+{pendingItem.bonusDef:F0} ";
            if (pendingItem.bonusHp > 0) statStr += $"HP+{pendingItem.bonusHp:F0}";

            var infoText = UIHelper.MakeText("Info", infoImg.transform,
                $"{stars} {pendingItem.itemName}  {statStr}",
                9f, TextAlignmentOptions.Center, UIColors.Text_Gold);
            UIHelper.FillParent(infoText.GetComponent<RectTransform>());

            y -= (32f + spacing);
        }

        for (int i = 0; i < dm.roster.Count; i++)
        {
            var preset = dm.roster[i];
            if (preset == null || preset.isEnemy) continue;
            string heroName = preset.characterName;
            Color rarityCol = GetHeroRarityColor(preset.rarity);
            string rarityLabel = GetHeroRarityLabel(preset.rarity);

            // 아이템 행 - 레어리티 색상 왼쪽 바
            var itemImg = UIHelper.MakePanel($"Hero_{i}", heroSelectListContainer.transform, UIColors.Panel_Inner);
            var item = itemImg.gameObject;
            heroSelectItems.Add(item);
            var irt = item.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0, 1);
            irt.anchorMax = new Vector2(1, 1);
            irt.pivot = new Vector2(0.5f, 1);
            irt.anchoredPosition = new Vector2(0, y);
            irt.sizeDelta = new Vector2(0, itemH);

            // 왼쪽 레어리티 컬러 바
            var rarityBar = UIHelper.MakeUI("RarityBar", item.transform);
            var rarityBarImg = rarityBar.AddComponent<Image>();
            rarityBarImg.color = rarityCol;
            var rbRT = rarityBar.GetComponent<RectTransform>();
            rbRT.anchorMin = new Vector2(0, 0);
            rbRT.anchorMax = new Vector2(0, 1);
            rbRT.pivot = new Vector2(0, 0.5f);
            rbRT.sizeDelta = new Vector2(4f, 0);
            rbRT.anchoredPosition = Vector2.zero;

            // 레어리티 뱃지
            var badge = UIHelper.MakeUI("Badge", item.transform);
            var badgeImg = badge.AddComponent<Image>();
            badgeImg.color = rarityCol;
            var badgeRT = badge.GetComponent<RectTransform>();
            badgeRT.anchorMin = new Vector2(0, 0.55f);
            badgeRT.anchorMax = new Vector2(0, 1);
            badgeRT.pivot = new Vector2(0, 1);
            badgeRT.sizeDelta = new Vector2(32f, 0);
            badgeRT.anchoredPosition = new Vector2(8f, -2f);

            var badgeText = UIHelper.MakeText("BadgeLabel", badge.transform, rarityLabel,
                7f, TextAlignmentOptions.Center, UIColors.Text_Primary);
            badgeText.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(badgeText.GetComponent<RectTransform>());

            // 영웅 이름 (레어리티 컬러)
            var nameText = UIHelper.MakeText("Name", item.transform, heroName,
                UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, rarityCol);
            nameText.fontStyle = FontStyles.Bold;
            var nrt = nameText.GetComponent<RectTransform>();
            nrt.anchorMin = new Vector2(0, 0);
            nrt.anchorMax = new Vector2(0.50f, 0.55f);
            nrt.offsetMin = new Vector2(8f, 0);
            nrt.offsetMax = Vector2.zero;

            // 현재 장비 수 + 역할
            int equipCount = EquipmentManager.Instance != null
                ? EquipmentManager.Instance.GetEquippedItems(heroName).Count : 0;
            string roleStr = preset.isHealer ? "힐러" : preset.isBuffer ? "버퍼" :
                preset.attackRange > 3f ? "원거리" : "근거리";
            var eqText = UIHelper.MakeText("Equip", item.transform,
                $"{roleStr} | 장비 {equipCount}개",
                8f, TextAlignmentOptions.Center, UIColors.Text_Secondary);
            var ert = eqText.GetComponent<RectTransform>();
            ert.anchorMin = new Vector2(0.50f, 0);
            ert.anchorMax = new Vector2(0.76f, 1);
            ert.offsetMin = Vector2.zero;
            ert.offsetMax = Vector2.zero;

            // 선택 버튼
            var (btn, _) = UIHelper.MakeButton($"Select_{i}", item.transform,
                UIColors.Button_Green, "", 10f);
            var btnRT = btn.GetComponent<RectTransform>();
            btnRT.anchorMin = new Vector2(0.77f, 0.12f);
            btnRT.anchorMax = new Vector2(0.97f, 0.88f);
            btnRT.offsetMin = Vector2.zero;
            btnRT.offsetMax = Vector2.zero;

            var btnText = UIHelper.MakeText("Label", btn.transform, "선택",
                UIConstants.Font_Cost, TextAlignmentOptions.Center, UIColors.Text_Primary);
            btnText.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(btnText.GetComponent<RectTransform>());

            string capturedHero = heroName;
            btn.onClick.AddListener(() =>
            {
                EquipmentManager.Instance?.EquipItem(pendingEquipItemId, capturedHero);
                heroSelectPopup.SetActive(false);
                RefreshEquipmentUI();
                ToastNotification.Instance?.Show($"{capturedHero}에게 장비 장착!", "");
            });

            y -= (itemH + spacing);
        }

        var containerRT = heroSelectListContainer.GetComponent<RectTransform>();
        containerRT.sizeDelta = new Vector2(0, Mathf.Abs(y));
    }

    // ════════════════════════════════════════
    // 확인 팝업
    // ════════════════════════════════════════

    void CreateConfirmPopup()
    {
        confirmPopup = UIHelper.MakeUI("ConfirmPopup", safeAreaRoot.transform);
        var bg = confirmPopup.AddComponent<Image>();
        bg.color = UIColors.Overlay_Dark;
        UIHelper.FillParent(confirmPopup.GetComponent<RectTransform>());

        var panel = UIHelper.MakePanel("Panel", confirmPopup.transform, UIColors.Background_Panel);
        var panelOutline = panel.gameObject.AddComponent<Outline>();
        panelOutline.effectColor = UIColors.Panel_Border;
        panelOutline.effectDistance = new Vector2(2, 2);
        var prt = panel.GetComponent<RectTransform>();
        prt.anchorMin = new Vector2(0.1f, 0.38f);
        prt.anchorMax = new Vector2(0.9f, 0.62f);
        prt.offsetMin = Vector2.zero;
        prt.offsetMax = Vector2.zero;

        confirmTitleText = UIHelper.MakeText("Title", panel.transform, "",
            UIConstants.Font_HeaderMedium, TextAlignmentOptions.Center, UIColors.Text_Gold);
        confirmTitleText.fontStyle = FontStyles.Bold;
        var trt = confirmTitleText.GetComponent<RectTransform>();
        trt.anchorMin = new Vector2(0, 0.72f);
        trt.anchorMax = new Vector2(1, 0.95f);
        trt.offsetMin = Vector2.zero;
        trt.offsetMax = Vector2.zero;

        confirmDescText = UIHelper.MakeText("Desc", panel.transform, "",
            UIConstants.Font_StatValue, TextAlignmentOptions.Center, UIColors.Text_Primary);
        var drt = confirmDescText.GetComponent<RectTransform>();
        drt.anchorMin = new Vector2(0.05f, 0.35f);
        drt.anchorMax = new Vector2(0.95f, 0.72f);
        drt.offsetMin = Vector2.zero;
        drt.offsetMax = Vector2.zero;

        // YES 버튼
        var (yesBtn, _) = UIHelper.MakeButton("YesBtn", panel.transform,
            UIColors.Button_Green, "", UIConstants.Font_Button);
        var ybrt = yesBtn.GetComponent<RectTransform>();
        ybrt.anchorMin = new Vector2(0.55f, 0.06f);
        ybrt.anchorMax = new Vector2(0.92f, 0.3f);
        ybrt.offsetMin = Vector2.zero;
        ybrt.offsetMax = Vector2.zero;
        var yesLabel = UIHelper.MakeText("Label", yesBtn.transform, "확인",
            UIConstants.Font_Button, TextAlignmentOptions.Center, UIColors.Text_Primary);
        yesLabel.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(yesLabel.GetComponent<RectTransform>());
        confirmYesBtn = yesBtn;
        yesBtn.onClick.AddListener(() =>
        {
            confirmPopup.SetActive(false);
            pendingConfirmAction?.Invoke();
            pendingConfirmAction = null;
            SoundManager.Instance?.PlayButtonSFX();
        });

        // NO 버튼
        var (noBtn, _) = UIHelper.MakeButton("NoBtn", panel.transform,
            UIColors.Defeat_Red, "", UIConstants.Font_Button);
        var nbrt = noBtn.GetComponent<RectTransform>();
        nbrt.anchorMin = new Vector2(0.08f, 0.06f);
        nbrt.anchorMax = new Vector2(0.45f, 0.3f);
        nbrt.offsetMin = Vector2.zero;
        nbrt.offsetMax = Vector2.zero;
        var noLabel = UIHelper.MakeText("Label", noBtn.transform, "취소",
            UIConstants.Font_Button, TextAlignmentOptions.Center, UIColors.Text_Primary);
        noLabel.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(noLabel.GetComponent<RectTransform>());
        noBtn.onClick.AddListener(() =>
        {
            confirmPopup.SetActive(false);
            pendingConfirmAction = null;
            SoundManager.Instance?.PlayButtonSFX();
        });

        confirmPopup.SetActive(false);
    }

    void ShowConfirm(string title, string desc, System.Action onConfirm)
    {
        if (confirmPopup == null) return;
        confirmTitleText.text = title;
        confirmDescText.text = desc;
        pendingConfirmAction = onConfirm;
        confirmPopup.SetActive(true);
        SoundManager.Instance?.PlayButtonSFX();
    }

    // ════════════════════════════════════════
    // 스킬 강화 UI (훈련 탭)
    // ════════════════════════════════════════

    void RefreshSkillUpgradeUI()
    {
        if (skillUpgradeContainer == null) return;
        var sm = SkillManager.Instance;
        var sum = SkillUpgradeManager.Instance;
        if (sm == null) return;

        RecycleList(skillUpgradeItems);
        int reuse = 0;
        float itemH = 38f;
        float spacing = 2f;
        float y = 0;
        int activeCount = 0;

        for (int i = 0; i < sm.equippedSkills.Count && i < 4; i++)
        {
            var skill = sm.equippedSkills[i];
            if (skill == null) continue;

            var item = ReuseOrCreate(skillUpgradeItems, ref reuse,
                $"SkillUp_{i}", skillUpgradeContainer.transform, UIColors.Panel_Inner);
            activeCount++;
            var irt = item.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0, 1);
            irt.anchorMax = new Vector2(1, 1);
            irt.pivot = new Vector2(0.5f, 1);
            irt.anchoredPosition = new Vector2(0, y);
            irt.sizeDelta = new Vector2(0, itemH);

            int level = sum != null ? sum.GetLevel(skill.skillName) : 1;
            int cost = sum != null ? sum.GetUpgradeCost(skill.skillName) : 0;
            bool canUp = sum != null && sum.CanUpgrade(skill.skillName);
            float dmgMult = sum != null ? sum.GetDamageMultiplier(skill.skillName) : 1f;

            var nameText = UIHelper.MakeText("Name", item.transform,
                $"{skill.iconChar} {skill.skillName}",
                UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, UIColors.Text_Primary);
            nameText.fontStyle = FontStyles.Bold;
            var nrt = nameText.GetComponent<RectTransform>();
            nrt.anchorMin = new Vector2(0, 0);
            nrt.anchorMax = new Vector2(0.35f, 1);
            nrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
            nrt.offsetMax = Vector2.zero;

            string info = $"Lv.{level} DMG:{dmgMult:P0}";
            var infoText = UIHelper.MakeText("Info", item.transform, info,
                9f, TextAlignmentOptions.Center, UIColors.Text_Gold);
            var inrt = infoText.GetComponent<RectTransform>();
            inrt.anchorMin = new Vector2(0.35f, 0);
            inrt.anchorMax = new Vector2(0.65f, 1);
            inrt.offsetMin = Vector2.zero;
            inrt.offsetMax = Vector2.zero;

            string btnLabel = level >= SkillUpgradeManager.MAX_SKILL_LEVEL ? "MAX" : $"{cost}G";
            Color btnColor = canUp ? UIColors.Button_Green : UIColors.Button_Gray;
            var (btn, _) = UIHelper.MakeButton($"Up_{i}", item.transform, btnColor, "", 10f);
            var brt = btn.GetComponent<RectTransform>();
            brt.anchorMin = new Vector2(0.68f, 0.1f);
            brt.anchorMax = new Vector2(0.97f, 0.9f);
            brt.offsetMin = Vector2.zero;
            brt.offsetMax = Vector2.zero;
            var btnText = UIHelper.MakeText("Label", btn.transform, btnLabel,
                UIConstants.Font_Cost, TextAlignmentOptions.Center,
                canUp ? UIColors.Text_Primary : UIColors.Text_Disabled);
            btnText.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(btnText.GetComponent<RectTransform>());

            if (canUp)
            {
                string capturedName = skill.skillName;
                btn.onClick.AddListener(() =>
                {
                    if (sum != null && !sum.TryUpgrade(capturedName))
                        ToastNotification.Instance?.Show("골드 부족!", "", UIColors.Defeat_Red);
                    RefreshSkillUpgradeUI();
                    RefreshUpgradeUI();
                });
            }

            y -= (itemH + spacing);
        }

        TrimExcess(skillUpgradeItems, activeCount);
        var containerRT = skillUpgradeContainer.GetComponent<RectTransform>();
        containerRT.sizeDelta = new Vector2(0, Mathf.Abs(y));
    }

    // ════════════════════════════════════════
    // 도감 UI (상점 탭 서브탭)
    // ════════════════════════════════════════

    TextMeshProUGUI collectionText;

    void BuildCollectionContent(Transform parent)
    {
        var content = UIHelper.MakeUI("CollectionContent", parent);
        var crt = content.GetComponent<RectTransform>();
        crt.anchorMin = Vector2.zero;
        crt.anchorMax = Vector2.one;
        crt.offsetMin = new Vector2(UIConstants.Spacing_Medium, UIConstants.Spacing_Medium);
        crt.offsetMax = new Vector2(-UIConstants.Spacing_Medium, 0);

        collectionText = UIHelper.MakeText("Info", content.transform, "",
            UIConstants.Font_StatValue, TextAlignmentOptions.TopLeft, UIColors.Text_Primary);
        UIHelper.FillParent(collectionText.GetComponent<RectTransform>());
    }

    void RefreshCollectionUI()
    {
        if (collectionText == null) return;
        var cm = CollectionManager.Instance;
        if (cm == null) { collectionText.text = "도감 로딩 중..."; return; }

        collectionText.text =
            $"<color=#FFD700>═══ 도감 ═══</color>\n\n" +
            $"<color=#7FD44C>영웅</color>  {cm.HeroCount}/{CollectionManager.TOTAL_HEROES}  " +
            $"({cm.HeroProgress:P0})\n" +
            $"<color=#FF6B6B>몬스터</color>  {cm.MonsterCount}/{CollectionManager.TOTAL_MONSTERS}  " +
            $"({cm.MonsterProgress:P0})\n" +
            $"<color=#87CEEB>장비</color>  {cm.EquipCount}/{CollectionManager.TOTAL_EQUIP_TYPES}  " +
            $"({cm.EquipProgress:P0})\n\n" +
            $"<color=#FFD700>전체 완성도: {cm.TotalProgress:P0}</color>\n\n" +
            $"마일스톤 보상: 3/5/7/10/13종 달성 시 보석!";
    }

    // ════════════════════════════════════════
    // 아레나 UI (상점 탭 서브탭)
    // ════════════════════════════════════════

    TextMeshProUGUI arenaInfoText;
    Button arenaBattleBtn;

    void BuildArenaContent(Transform parent)
    {
        var content = UIHelper.MakeUI("ArenaContent", parent);
        var crt = content.GetComponent<RectTransform>();
        crt.anchorMin = Vector2.zero;
        crt.anchorMax = Vector2.one;
        crt.offsetMin = new Vector2(UIConstants.Spacing_Medium, UIConstants.Spacing_Medium);
        crt.offsetMax = new Vector2(-UIConstants.Spacing_Medium, 0);

        arenaInfoText = UIHelper.MakeText("Info", content.transform, "",
            UIConstants.Font_StatValue, TextAlignmentOptions.TopLeft, UIColors.Text_Primary);
        var irt = arenaInfoText.GetComponent<RectTransform>();
        irt.anchorMin = new Vector2(0, 0.35f);
        irt.anchorMax = new Vector2(1, 1);
        irt.offsetMin = Vector2.zero;
        irt.offsetMax = Vector2.zero;

        var (btn, _) = UIHelper.MakeButton("BattleBtn", content.transform,
            UIColors.Button_Green, "", UIConstants.Font_Button);
        arenaBattleBtn = btn;
        var brt = btn.GetComponent<RectTransform>();
        brt.anchorMin = new Vector2(0.2f, 0.08f);
        brt.anchorMax = new Vector2(0.8f, 0.28f);
        brt.offsetMin = Vector2.zero;
        brt.offsetMax = Vector2.zero;
        var btnText = UIHelper.MakeText("Label", btn.transform, "도전!",
            UIConstants.Font_Button, TextAlignmentOptions.Center, UIColors.Text_Primary);
        btnText.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(btnText.GetComponent<RectTransform>());

        btn.onClick.AddListener(OnArenaBattle);
    }

    void RefreshArenaUI()
    {
        if (arenaInfoText == null) return;
        var am = ArenaManager.Instance;
        if (am == null) { arenaInfoText.text = "아레나 로딩 중..."; return; }

        arenaInfoText.text =
            $"<color=#FFD700>═══ 아레나 ═══</color>\n\n" +
            $"랭크: <color=#{ColorUtility.ToHtmlStringRGB(am.GetRankColor())}>{am.GetRankName()}</color>\n" +
            $"포인트: {am.ArenaPoints}P\n" +
            $"연승: {am.WinStreak}\n" +
            $"남은 도전: {am.RemainingAttempts}/{10}\n\n" +
            $"상대 난이도: {am.GetDifficulty() + 1}단계";

        if (arenaBattleBtn != null)
        {
            arenaBattleBtn.GetComponent<Image>().color =
                am.CanBattle ? UIColors.Button_Green : UIColors.Button_Gray;
        }
    }

    void OnArenaBattle()
    {
        var am = ArenaManager.Instance;
        if (am == null || !am.CanBattle)
        {
            ToastNotification.Instance?.Show("도전 횟수 소진!", "내일 다시 도전", UIColors.Defeat_Red);
            return;
        }

        // 승률 시뮬레이션: 덱 파워 vs 상대 스케일
        float myPower = 0f;
        var dm = DeckManager.Instance;
        var hlm = HeroLevelManager.Instance;
        if (dm != null)
        {
            var deck = dm.GetActiveDeck();
            for (int i = 0; i < deck.Count; i++)
            {
                float hp = deck[i].maxHp;
                float atk = deck[i].atk;
                if (hlm != null)
                {
                    hp += hlm.GetHpBonus(deck[i].characterName);
                    atk += hlm.GetAtkBonus(deck[i].characterName);
                }
                myPower += hp + atk * 5f;
            }
        }

        float opponentPower = am.GetOpponentDeck().Length * 200f * am.GetOpponentStatScale();
        float winChance = Mathf.Clamp01(myPower / (myPower + opponentPower + 0.01f));
        bool won = Random.value < winChance;

        am.ReportResult(won);
        RefreshArenaUI();
        SoundManager.Instance?.PlayButtonSFX();
    }

    // ════════════════════════════════════════
    // 일일 출석 체크 팝업
    // ════════════════════════════════════════

    void ShowDailyLoginPopup()
    {
        var dlm = DailyLoginManager.Instance;
        if (dlm == null || dlm.ClaimedToday) return;

        var reward = dlm.GetTodayReward();
        int day = dlm.CurrentDay + 1; // 1-based 표시

        string rewardStr = reward.type switch
        {
            DailyLoginManager.RewardType.Gold => $"골드 {reward.amount}",
            DailyLoginManager.RewardType.Gem => $"보석 {reward.amount}",
            DailyLoginManager.RewardType.GachaTikcet => "소환권 1장",
            _ => ""
        };

        Color rewardColor = reward.type == DailyLoginManager.RewardType.Gem
            ? UIColors.Text_Diamond : UIColors.Text_Gold;

        // 7일 단위 대보상 표시
        bool isMilestone = day % 7 == 0;

        string desc = isMilestone
            ? $"축하합니다! {day}일 출석!\n<size=14><color=#{ColorUtility.ToHtmlStringRGB(rewardColor)}>{rewardStr}</color></size>"
            : $"출석 {day}일차\n<size=12><color=#{ColorUtility.ToHtmlStringRGB(rewardColor)}>{rewardStr}</color></size>";

        ShowConfirm("출석 체크", desc, () =>
        {
            dlm.ClaimReward();
            ToastNotification.Instance?.Show("출석 보상!", rewardStr, rewardColor);
            UpdateGold(cachedGoldMgr != null ? cachedGoldMgr.Gold : 0);
            UpdateGem(cachedGemMgr != null ? cachedGemMgr.Gem : 0);
        });
    }

    // ════════════════════════════════════════
    // 확률 공시 팝업 (법적 의무)
    // ════════════════════════════════════════

    GameObject probPopup;

    void ShowProbabilityInfo()
    {
        if (probPopup != null)
        {
            probPopup.SetActive(true);
            return;
        }

        // 풀스크린 오버레이
        var overlay = UIHelper.MakePanel("ProbPopup", canvas.transform, UIColors.Overlay_Dark);
        probPopup = overlay.gameObject;
        var overlayRT = probPopup.GetComponent<RectTransform>();
        UIHelper.FillParent(overlayRT);

        // 탭하여 닫기
        var closeBtn = probPopup.AddComponent<Button>();
        closeBtn.targetGraphic = overlay;
        closeBtn.onClick.AddListener(() => probPopup.SetActive(false));

        // 중앙 패널
        var panel = UIHelper.MakePanel("Panel", probPopup.transform, UIColors.Background_Panel);
        var panelRT = panel.GetComponent<RectTransform>();
        panelRT.anchorMin = new Vector2(0.05f, 0.1f);
        panelRT.anchorMax = new Vector2(0.95f, 0.9f);
        panelRT.offsetMin = Vector2.zero;
        panelRT.offsetMax = Vector2.zero;

        // 패널 내부 클릭 시 닫히지 않도록
        var panelBtn = panel.gameObject.AddComponent<Button>();
        panelBtn.targetGraphic = panel;
        panelBtn.onClick.AddListener(() => { }); // 이벤트 소비

        // 테두리
        var border = UIHelper.MakePanel("Border", panel.transform, UIColors.Panel_Border);
        var borderRT = border.GetComponent<RectTransform>();
        UIHelper.FillParent(borderRT);
        var inner = UIHelper.MakePanel("Inner", border.transform, UIColors.Background_Panel);
        var innerRT = inner.GetComponent<RectTransform>();
        innerRT.anchorMin = Vector2.zero;
        innerRT.anchorMax = Vector2.one;
        innerRT.offsetMin = new Vector2(2, 2);
        innerRT.offsetMax = new Vector2(-2, -2);

        // 타이틀
        var title = UIHelper.MakeText("Title", inner.transform, "소환 확률 정보",
            UIConstants.Font_HeaderMedium, TextAlignmentOptions.Center, UIColors.Text_Gold);
        title.fontStyle = FontStyles.Bold;
        var titleRT = title.GetComponent<RectTransform>();
        titleRT.anchorMin = new Vector2(0, 0.9f);
        titleRT.anchorMax = new Vector2(1, 1);
        titleRT.offsetMin = Vector2.zero;
        titleRT.offsetMax = Vector2.zero;

        // 확률 내용 텍스트
        string content =
            "<color=#FFD700>[ 기본 소환 확률 ]</color>\n" +
            $"  <color=#607080>Common</color>    60.00%\n" +
            $"  <color=#6B3FA0>Rare</color>          25.00%\n" +
            $"  <color=#E07020>Epic</color>          12.00%\n" +
            $"  <color=#FFD700>Legendary</color>   3.00%\n" +
            "\n" +
            "<color=#FFD700>[ 천장 시스템 (Pity) ]</color>\n" +
            "  10회 연속 Common 출현 시\n" +
            "  다음 소환은 Rare 이상 보장:\n" +
            $"  <color=#6B3FA0>Rare</color>          70.00%\n" +
            $"  <color=#E07020>Epic</color>          22.00%\n" +
            $"  <color=#FFD700>Legendary</color>   8.00%\n" +
            "\n" +
            "<color=#FFD700>[ 10연차 보장 ]</color>\n" +
            "  10회 소환 중 Rare 이상이\n" +
            "  1회도 없을 경우\n" +
            "  마지막 소환은 Rare 이상 보장\n" +
            "\n" +
            "<color=#FFD700>[ 소환 비용 ]</color>\n" +
            $"  1회 소환: {GachaManager.SINGLE_PULL_COST}보석\n" +
            $"  10연차:   {GachaManager.MULTI_PULL_COST}보석 (1회 할인)\n" +
            "\n" +
            "<color=#FFD700>[ 중복 소환 ]</color>\n" +
            "  이미 보유한 영웅 소환 시\n" +
            "  해당 영웅의 강화 카드 +1 획득";

        var contentText = UIHelper.MakeText("Content", inner.transform, content,
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Left, UIColors.Text_Primary);
        contentText.lineSpacing = 5f;
        var contentRT = contentText.GetComponent<RectTransform>();
        contentRT.anchorMin = new Vector2(0, 0.05f);
        contentRT.anchorMax = new Vector2(1, 0.88f);
        contentRT.offsetMin = new Vector2(12, 0);
        contentRT.offsetMax = new Vector2(-12, 0);

        // 닫기 버튼
        var (cBtn, _) = UIHelper.MakeButton("CloseBtn", inner.transform,
            UIColors.Button_Green, "닫기", UIConstants.Font_Button);
        cBtn.onClick.AddListener(() => probPopup.SetActive(false));
        var cbrt = cBtn.GetComponent<RectTransform>();
        cbrt.anchorMin = new Vector2(0.25f, 0.01f);
        cbrt.anchorMax = new Vector2(0.75f, 0.07f);
        cbrt.offsetMin = Vector2.zero;
        cbrt.offsetMax = Vector2.zero;

        SoundManager.Instance?.PlayButtonSFX();
    }
}
