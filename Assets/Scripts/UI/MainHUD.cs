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

    // 훈련 탭 업그레이드 UI
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

    // 분리된 패널 컴포넌트
    GachaPanel gachaPanel;
    ShopPanel shopPanel;
    EnhancePanel enhancePanel;
    HeroSelectPanel heroSelectPanel;
    UpgradePanel upgradePanel;

    // Hero select popup (for equipment) → HeroSelectPanel

    // Confirm dialog
    GameObject confirmPopup;
    TextMeshProUGUI confirmTitleText;
    TextMeshProUGUI confirmDescText;
    System.Action pendingConfirmAction;

    // Offline reward popup
    GameObject offlinePopup;
    TextMeshProUGUI offlineText;

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

        heroSelectPanel = safeAreaRoot.AddComponent<HeroSelectPanel>();
        heroSelectPanel.Init(safeAreaRoot.transform, () => enhancePanel?.Refresh());
        CreateBottomNavBar();
        CreateTabPanels();
        CreateOfflinePopup();
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
        // Board_20x20 스프라이트로 배경 — 어두운 나무 프레임
        var hudBg = UIHelper.MakeSpritePanel("HUDBg", hudBar.transform, UISprites.Board, UIColors.Background_Dark);
        UIHelper.FillParent(hudBg.GetComponent<RectTransform>());
        // Board 스프라이트 원본 색상 유지 (9-slice)
        var hudImg = hudBar.AddComponent<Image>();
        hudImg.color = Color.clear;
        UIHelper.SetAnchors(hudBar, new Vector2(0, 1), new Vector2(1, 1), new Vector2(0.5f, 1));
        hudBar.GetComponent<RectTransform>().sizeDelta = new Vector2(0, UIConstants.HUD_Height);

        // 스테이지 정보 영역 (왼쪽) — BoxBanner로 감싼다
        var stageContainer = UIHelper.MakeSpritePanel("StageBG", hudBar.transform, UISprites.BoxBanner, UIColors.Background_Dark);
        // BoxBanner 스프라이트 원본 색상 유지
        var scrt = stageContainer.GetComponent<RectTransform>();
        scrt.anchorMin = new Vector2(0, 0.08f);
        scrt.anchorMax = new Vector2(0.38f, 0.92f);
        scrt.offsetMin = new Vector2(4, 0);
        scrt.offsetMax = new Vector2(0, 0);

        // Area name (small, top)
        areaNameText = UIHelper.MakeText("AreaName", stageContainer.transform, "Grass Field",
            8f, TextAlignmentOptions.Center, UIColors.Text_Secondary);
        var anrt = areaNameText.GetComponent<RectTransform>();
        anrt.anchorMin = new Vector2(0, 0.55f);
        anrt.anchorMax = new Vector2(1, 1);
        anrt.offsetMin = new Vector2(4, 0);
        anrt.offsetMax = new Vector2(-4, -2);

        // Stage text — 밝은 크림색, 볼드
        stageText = UIHelper.MakeText("Stage", stageContainer.transform, "1-1",
            UIConstants.Font_HeaderMedium, TextAlignmentOptions.Center, Color.white);
        stageText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(stageText);
        var srt = stageText.GetComponent<RectTransform>();
        srt.anchorMin = new Vector2(0, 0);
        srt.anchorMax = new Vector2(0.35f, 0.58f);
        srt.offsetMin = new Vector2(4, 0);
        srt.offsetMax = Vector2.zero;

        // Progress bar (EXP_Gauge 스프라이트 활용)
        var (progBgImg, progFillImg) = UIHelper.MakeGauge(
            "Prog", stageContainer.transform,
            UISprites.EXP_BG,   UIColors.ProgressBar_BG,
            UISprites.EXP_Fill, UIColors.ProgressBar_Fill);

        var prt = progBgImg.GetComponent<RectTransform>();
        prt.anchorMin = new Vector2(0.36f, 0.12f);
        prt.anchorMax = new Vector2(0.98f, 0.52f);
        prt.offsetMin = Vector2.zero;
        prt.offsetMax = Vector2.zero;

        progressBarFill = progFillImg;

        var pfrt = progFillImg.GetComponent<RectTransform>();
        pfrt.anchorMin = Vector2.zero;
        pfrt.anchorMax = new Vector2(0.1f, 1);
        pfrt.offsetMin = Vector2.zero;
        pfrt.offsetMax = Vector2.zero;

        progressText = UIHelper.MakeText("ProgText", progBgImg.transform, "1/10",
            7f, TextAlignmentOptions.Center, Color.white);
        UIHelper.AddTextShadow(progressText);
        UIHelper.FillParent(progressText.GetComponent<RectTransform>());

        // Gold — BoxIcon1 컨테이너
        CreateResourceDisplay(hudBar.transform, "Gold", UISprites.IconGold,
            UIColors.Text_Gold, new Vector2(0.40f, 0.10f), new Vector2(0.68f, 0.90f),
            out goldText);

        // Gem — BoxIcon1 컨테이너
        CreateResourceDisplay(hudBar.transform, "Gem", UISprites.IconDiamond,
            UIColors.Text_Diamond, new Vector2(0.70f, 0.10f), new Vector2(0.98f, 0.90f),
            out gemText);
    }

    void CreateResourceDisplay(Transform parent, string name, Sprite iconSprite,
        Color iconColor, Vector2 anchorMin, Vector2 anchorMax, out TextMeshProUGUI valueText)
    {
        // BoxIcon1 스프라이트로 리소스 컨테이너
        var container = UIHelper.MakeSpritePanel($"{name}BG", parent,
            UISprites.BoxIcon1, UIColors.Panel_Inner);
        // BoxIcon1 스프라이트 원본 색상 유지
        var crt = container.GetComponent<RectTransform>();
        crt.anchorMin = anchorMin;
        crt.anchorMax = anchorMax;
        crt.offsetMin = new Vector2(2, 0);
        crt.offsetMax = new Vector2(-2, 0);

        // 아이콘
        if (iconSprite != null)
        {
            var iconImg = UIHelper.MakeIcon($"{name}Icon", container.transform, iconSprite, iconColor);
            var irt = iconImg.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0, 0.1f);
            irt.anchorMax = new Vector2(0, 0.9f);
            irt.pivot = new Vector2(0, 0.5f);
            irt.anchoredPosition = new Vector2(6, 0);
            irt.sizeDelta = new Vector2(20, 0);
        }
        else
        {
            var iconBg = UIHelper.MakePanel($"{name}Icon", container.transform, iconColor);
            var irt = iconBg.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0, 0.15f);
            irt.anchorMax = new Vector2(0, 0.85f);
            irt.pivot = new Vector2(0, 0.5f);
            irt.anchoredPosition = new Vector2(6, 0);
            irt.sizeDelta = new Vector2(18, 0);

            var iconText = UIHelper.MakeText($"{name}IconText", iconBg.transform,
                name == "Gold" ? "G" : "D",
                UIConstants.Font_LevelBadge, TextAlignmentOptions.Center, UIColors.Background_Dark);
            iconText.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(iconText.GetComponent<RectTransform>());
        }

        // 리소스 값 텍스트 — 밝은 색으로 어두운 배경 대비
        Color valueColor = name == "Gold" ? UIColors.Text_Gold : UIColors.Text_Diamond;
        valueText = UIHelper.MakeText($"{name}Text", container.transform, "0",
            UIConstants.Font_HUDResource, TextAlignmentOptions.Center, valueColor);
        valueText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(valueText);
        var vrt = valueText.GetComponent<RectTransform>();
        vrt.anchorMin = new Vector2(0.30f, 0);
        vrt.anchorMax = new Vector2(1, 1);
        vrt.offsetMin = Vector2.zero;
        vrt.offsetMax = new Vector2(-4, 0);
    }

    // ── Wave Banner (중앙 상단) ──
    void CreateWaveBanner()
    {
        waveBanner = UIHelper.MakeUI("WaveBanner", safeAreaRoot.transform);
        waveBannerCG = waveBanner.AddComponent<CanvasGroup>();

        // Board 스프라이트 — 어두운 나무 프레임 배너
        var bannerBgImg = UIHelper.MakeSpritePanel("BannerBG", waveBanner.transform,
            UISprites.Board, new Color(0.2f, 0.12f, 0.08f, 0.92f));
        UIHelper.FillParent(bannerBgImg.GetComponent<RectTransform>());
        // Board 스프라이트 원본 색상 유지
        var bannerBg = waveBanner.AddComponent<Image>();
        bannerBg.color = Color.clear;

        var rt = waveBanner.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0.15f, 0.77f);
        rt.anchorMax = new Vector2(0.85f, 0.84f);
        rt.offsetMin = Vector2.zero;
        rt.offsetMax = Vector2.zero;

        waveBannerText = UIHelper.MakeText("BannerText", waveBanner.transform, "WAVE 1",
            20f, TextAlignmentOptions.Center, UIColors.Text_Gold);
        waveBannerText.fontStyle = FontStyles.Bold;
        waveBannerText.enableVertexGradient = true;
        waveBannerText.colorGradient = new VertexGradient(
            new Color(1f, 0.92f, 0.55f), new Color(1f, 0.92f, 0.55f),
            new Color(0.95f, 0.72f, 0.25f), new Color(0.95f, 0.72f, 0.25f));
        UIHelper.AddTextOutline(waveBannerText, new Color(0.15f, 0.08f, 0.02f, 0.8f), new Vector2(1.5f, -1.5f));
        UIHelper.FillParent(waveBannerText.GetComponent<RectTransform>());

        waveBanner.SetActive(false);
    }

    // ── Kill Counter (좌측 중앙) ──
    void CreateKillCounter()
    {
        var container = UIHelper.MakeUI("KillCounter", safeAreaRoot.transform);
        var killBg = UIHelper.MakeSpritePanel("KillBG", container.transform,
            UISprites.BoxIcon1, new Color(0.15f, 0.08f, 0.05f, 0.85f));
        UIHelper.FillParent(killBg.GetComponent<RectTransform>());
        // BoxIcon1 스프라이트 원본 색상 유지
        var bg = container.AddComponent<Image>();
        bg.color = Color.clear;

        var rt = container.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0, 0.5f);
        rt.anchorMax = new Vector2(0, 0.5f);
        rt.pivot = new Vector2(0, 0.5f);
        rt.anchoredPosition = new Vector2(UIConstants.Spacing_Small, 50);
        rt.sizeDelta = new Vector2(62, 24);

        var iconText = UIHelper.MakeText("KillIcon", container.transform, "KILL",
            8f, TextAlignmentOptions.MidlineLeft, new Color(1f, 0.4f, 0.3f));
        iconText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(iconText);
        var irt = iconText.GetComponent<RectTransform>();
        irt.anchorMin = new Vector2(0, 0);
        irt.anchorMax = new Vector2(0.5f, 1);
        irt.offsetMin = new Vector2(UIConstants.Spacing_Small, 0);
        irt.offsetMax = Vector2.zero;

        killCountText = UIHelper.MakeText("KillCount", container.transform, "0",
            UIConstants.Font_Tab, TextAlignmentOptions.MidlineRight, Color.white);
        killCountText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(killCountText);
        var krt = killCountText.GetComponent<RectTransform>();
        krt.anchorMin = new Vector2(0.5f, 0);
        krt.anchorMax = new Vector2(1, 1);
        krt.offsetMin = Vector2.zero;
        krt.offsetMax = new Vector2(-UIConstants.Spacing_Small, 0);
    }


    // ── Bottom Nav Bar (하단) ──
    // 탭 아이콘용 SPUM 스프라이트 (인덱스)
    readonly Sprite[] tabSpriteIcons = new Sprite[TAB_COUNT];

    void CreateBottomNavBar()
    {
        var navBar = UIHelper.MakeUI("NavBar", safeAreaRoot.transform);
        // Board_20x20 — 어두운 나무 프레임 배경
        var navBg = UIHelper.MakeSpritePanel("NavBG", navBar.transform, UISprites.Board, UIColors.NavBar_BG);
        UIHelper.FillParent(navBg.GetComponent<RectTransform>());
        // Board 스프라이트 원본 색상 유지
        var navImg = navBar.AddComponent<Image>();
        navImg.color = Color.clear;
        UIHelper.SetAnchors(navBar, new Vector2(0, 0), new Vector2(1, 0), new Vector2(0.5f, 0));
        navBar.GetComponent<RectTransform>().sizeDelta = new Vector2(0, 58);

        // 탭 아이콘 스프라이트 할당 (SPUM 아이콘 활용)
        tabSpriteIcons[0] = UISprites.IconSword;     // 훈련
        tabSpriteIcons[1] = UISprites.IconSkill;     // 강화
        tabSpriteIcons[2] = UISprites.IconInven;     // 편성
        tabSpriteIcons[3] = UISprites.IconPotion1;   // 소환
        tabSpriteIcons[4] = UISprites.IconQuest;     // 상점

        float tabWidth = 1f / TAB_COUNT;
        for (int i = 0; i < TAB_COUNT; i++)
        {
            int idx = i;
            float xMin = i * tabWidth;
            float xMax = (i + 1) * tabWidth;

            // Btn1_WS 스프라이트로 탭 버튼
            var tabObj = UIHelper.MakeUI($"Tab_{tabNames[i]}", navBar.transform);
            var tabImg = tabObj.AddComponent<Image>();
            if (UISprites.Btn1_WS != null)
            {
                tabImg.sprite = UISprites.Btn1_WS;
                tabImg.type = Image.Type.Sliced;
                tabImg.color = Color.white; // 미선택: 밝은 톤
            }
            else
            {
                tabImg.color = UIColors.Tab_Inactive;
            }
            tabButtons[i] = tabObj.AddComponent<Button>();
            tabButtons[i].targetGraphic = tabImg;
            tabButtons[i].onClick.AddListener(() => OnTabClicked(idx));

            var trt = tabObj.GetComponent<RectTransform>();
            trt.anchorMin = new Vector2(xMin, 0);
            trt.anchorMax = new Vector2(xMax, 1);
            trt.offsetMin = new Vector2(2, 4);
            trt.offsetMax = new Vector2(-2, -4);

            // Active indicator (하단 골드 라인)
            var indicator = UIHelper.MakePanel("Indicator", tabObj.transform, UIColors.Text_Gold);
            var irt = indicator.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0.1f, 0);
            irt.anchorMax = new Vector2(0.9f, 0);
            irt.pivot = new Vector2(0.5f, 0);
            irt.sizeDelta = new Vector2(0, 3);
            indicator.gameObject.SetActive(false);
            tabIndicators[i] = indicator;

            // 아이콘 — SPUM 스프라이트 사용, 없으면 유니코드 폴백
            if (tabSpriteIcons[i] != null)
            {
                var iconImg = UIHelper.MakeIcon("Icon", tabObj.transform, tabSpriteIcons[i], Color.white);
                var icrt = iconImg.GetComponent<RectTransform>();
                icrt.anchorMin = new Vector2(0.10f, 0.32f);
                icrt.anchorMax = new Vector2(0.90f, 0.92f);
                icrt.offsetMin = Vector2.zero;
                icrt.offsetMax = Vector2.zero;
                // 미선택: 원래 색, 선택: 밝게 (UpdateTabVisuals에서 처리)
                tabIconTexts[i] = null; // 스프라이트 사용 시 텍스트 아이콘 불필요
            }
            else
            {
                tabIconTexts[i] = UIHelper.MakeText("Icon", tabObj.transform, tabIcons[i],
                    UIConstants.NavBar_IconSize, TextAlignmentOptions.Center, UIColors.Text_Secondary);
                tabIconTexts[i].fontStyle = FontStyles.Bold;
                var icrt = tabIconTexts[i].GetComponent<RectTransform>();
                icrt.anchorMin = new Vector2(0, 0.38f);
                icrt.anchorMax = new Vector2(1, 0.90f);
                icrt.offsetMin = Vector2.zero;
                icrt.offsetMax = Vector2.zero;
            }

            // Label — 밝은 크림색 (어두운 배경)
            tabLabels[i] = UIHelper.MakeText("Label", tabObj.transform, tabNames[i],
                9f, TextAlignmentOptions.Top, UIColors.Text_Secondary);
            tabLabels[i].fontStyle = FontStyles.Bold;
            var lrt = tabLabels[i].GetComponent<RectTransform>();
            lrt.anchorMin = new Vector2(0, 0);
            lrt.anchorMax = new Vector2(1, 0.35f);
            lrt.offsetMin = Vector2.zero;
            lrt.offsetMax = Vector2.zero;

            // Badge (빨간 알림 원)
            var badge = UIHelper.MakeUI($"Badge_{i}", tabObj.transform);
            var badgeImg = badge.AddComponent<Image>();
            badgeImg.color = UIColors.Defeat_Red;
            var bdrt = badge.GetComponent<RectTransform>();
            bdrt.anchorMin = new Vector2(0.68f, 0.68f);
            bdrt.anchorMax = new Vector2(0.68f, 0.68f);
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
        float navRatio = 58f / refH; // navBar height

        for (int i = 0; i < TAB_COUNT; i++)
        {
            var panel = UIHelper.MakeUI($"Panel_{tabNames[i]}", safeAreaRoot.transform);
            // BoxBasic1 — 밝은 나무 패널 배경
            var panelBg = UIHelper.MakeSpritePanel("PanelBG", panel.transform,
                UISprites.BoxBasic1, UIColors.Background_Panel);
            UIHelper.FillParent(panelBg.GetComponent<RectTransform>());
            // BoxBasic1 스프라이트 원본 색상 유지
            var panelImg = panel.AddComponent<Image>();
            panelImg.color = Color.clear;

            var prt = panel.GetComponent<RectTransform>();
            prt.anchorMin = new Vector2(0, navRatio);
            prt.anchorMax = new Vector2(1, 0.50f);
            prt.offsetMin = Vector2.zero;
            prt.offsetMax = Vector2.zero;

            // Header bar — Board 스프라이트 (진한 나무 프레임)
            var header = UIHelper.MakeSpritePanel("Header", panel.transform,
                UISprites.Board, UIColors.Background_Dark);
            // Board 스프라이트 원본 색상 유지
            var hrt = header.GetComponent<RectTransform>();
            hrt.anchorMin = new Vector2(0, 1);
            hrt.anchorMax = new Vector2(1, 1);
            hrt.pivot = new Vector2(0.5f, 1);
            hrt.sizeDelta = new Vector2(0, UIConstants.Tab_Height);

            var title = UIHelper.MakeText("Title", header.transform, tabNames[i],
                UIConstants.Font_HeaderMedium, TextAlignmentOptions.Center, Color.white);
            title.fontStyle = FontStyles.Bold;
            title.enableVertexGradient = true;
            title.colorGradient = new VertexGradient(
                new Color(1f, 0.97f, 0.90f), new Color(1f, 0.97f, 0.90f),
                new Color(0.88f, 0.78f, 0.60f), new Color(0.88f, 0.78f, 0.60f));
            UIHelper.AddTextShadow(title);
            UIHelper.FillParent(title.GetComponent<RectTransform>());

            // Close button — Button_X 스프라이트 (깔끔한 X)
            var closeObj = UIHelper.MakeUI("CloseBtn", header.transform);
            var closeImg = closeObj.AddComponent<Image>();
            if (UISprites.BtnX != null)
            {
                closeImg.sprite = UISprites.BtnX;
                closeImg.type = Image.Type.Simple;
                closeImg.preserveAspect = true;
                closeImg.color = Color.white;
            }
            else
            {
                closeImg.color = UIColors.Button_Brown;
            }
            var closeBtn = closeObj.AddComponent<Button>();
            closeBtn.targetGraphic = closeImg;
            closeBtn.onClick.AddListener(ClosePanel);
            var crt = closeBtn.GetComponent<RectTransform>();
            crt.anchorMin = new Vector2(1, 0.5f);
            crt.anchorMax = new Vector2(1, 0.5f);
            crt.pivot = new Vector2(1, 0.5f);
            crt.anchoredPosition = new Vector2(-6, 0);
            crt.sizeDelta = new Vector2(24, 24);

            if (UISprites.BtnX == null)
            {
                var xLabel = UIHelper.MakeText("X", closeObj.transform, "X",
                    12f, TextAlignmentOptions.Center, Color.white);
                xLabel.fontStyle = FontStyles.Bold;
                UIHelper.FillParent(xLabel.GetComponent<RectTransform>());
            }

            // 탭별 콘텐츠
            if (i == 0)
            {
                upgradePanel = panel.AddComponent<UpgradePanel>();
                upgradePanel.Init(panel.transform);
            }
            else if (i == 1)
            {
                enhancePanel = panel.AddComponent<EnhancePanel>();
                enhancePanel.Init(panel.transform, heroSelectPanel.Show);
            }
            else if (i == 2)
            {
                var deckUI = panel.AddComponent<DeckUI>();
                deckUI.Init(panel.transform);
            }
            else if (i == 3)
            {
                gachaPanel = panel.AddComponent<GachaPanel>();
                gachaPanel.Init(panel.transform, ShowConfirm);
            }
            else if (i == 4)
            {
                shopPanel = panel.AddComponent<ShopPanel>();
                shopPanel.Init(panel.transform, ShowConfirm);
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
        if (idx == 0) upgradePanel?.Refresh();
        if (idx == 1) enhancePanel?.Refresh();
        if (idx == 3) gachaPanel?.Refresh();
        if (idx == 4) shopPanel?.Refresh();
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
            var tabImg = tabButtons[i].GetComponent<Image>();

            if (UISprites.Btn1_WS != null)
            {
                // 선택: 확실한 어두운 tint + 축소 (눌린 느낌), 미선택: 원본
                tabImg.color = active ? new Color(0.85f, 0.85f, 0.85f) : Color.white;
                tabButtons[i].transform.localScale = active ? Vector3.one * 0.95f : Vector3.one;
            }
            else
            {
                tabImg.color = active ? UIColors.Tab_Active : UIColors.Tab_Inactive;
            }

            // 라벨: 선택=흰색, 미선택=크림색
            tabLabels[i].color = active ? Color.white : UIColors.Text_Secondary;
            tabLabels[i].fontStyle = FontStyles.Bold;

            // 아이콘 (텍스트 아이콘인 경우만)
            if (tabIconTexts[i] != null)
                tabIconTexts[i].color = active ? Color.white : UIColors.Text_Secondary;

            // 스프라이트 아이콘 색상 조정
            var iconImgObj = tabButtons[i].transform.Find("Icon");
            if (iconImgObj != null)
            {
                var iconImg = iconImgObj.GetComponent<Image>();
                if (iconImg != null && iconImg.sprite != null)
                    iconImg.color = active ? Color.white : new Color(0.85f, 0.82f, 0.78f);
            }

            tabIndicators[i].gameObject.SetActive(active);
        }
    }

    // ════════════════════════════════════════
    // UPDATES
    // ════════════════════════════════════════

    void UpdateGold(int gold)
    {
        if (goldText != null) goldText.text = UIHelper.FormatNumber(gold);
        if (activeTab == 0) upgradePanel?.Refresh();
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
            // Image.Type.Filled 이므로 fillAmount 사용 (anchorMax 조작은 Filled 타입에서 무효)
            progressBarFill.fillAmount = total > 0 ? (float)wave / total : 0f;
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
        {
            bossNameText.text = isAreaBoss ? $"AREA BOSS: {boss.unitName}" : $"BOSS: {boss.unitName}";
            bossNameText.color = isAreaBoss ? new Color(1f, 0.2f, 0.2f) : UIColors.Text_Gold;
        }

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
        rt.anchorMin = new Vector2(0.08f, 0.78f);
        rt.anchorMax = new Vector2(0.92f, 0.84f);
        rt.offsetMin = Vector2.zero;
        rt.offsetMax = Vector2.zero;

        // Boss_HP_Gauge1 스프라이트 배경
        var bossBg = UIHelper.MakeSpritePanel("BossBG", bossHpBarRoot.transform,
            UISprites.BossHP_BG, new Color(0.15f, 0.05f, 0.05f, 0.9f));
        UIHelper.FillParent(bossBg.GetComponent<RectTransform>());
        var bg = bossHpBarRoot.AddComponent<Image>();
        bg.color = Color.clear;

        // 이름 텍스트 — 볼드, 빨간 톤
        bossNameText = UIHelper.MakeText("BossName", bossHpBarRoot.transform, "BOSS",
            UIConstants.Font_StatLabel, TextAlignmentOptions.Center, UIColors.Text_Gold);
        bossNameText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextOutline(bossNameText, new Color(0, 0, 0, 0.6f), new Vector2(1, -1));
        var nameRt = bossNameText.GetComponent<RectTransform>();
        nameRt.anchorMin = new Vector2(0f, 1f);
        nameRt.anchorMax = new Vector2(1f, 1.8f);
        nameRt.offsetMin = Vector2.zero;
        nameRt.offsetMax = Vector2.zero;

        // HP바 fill
        var fillObj = UIHelper.MakeUI("Fill", bossHpBarRoot.transform);
        var fillRt = fillObj.GetComponent<RectTransform>();
        fillRt.anchorMin = new Vector2(0.02f, 0.15f);
        fillRt.anchorMax = new Vector2(0.98f, 0.85f);
        fillRt.offsetMin = Vector2.zero;
        fillRt.offsetMax = Vector2.zero;
        bossHpBarFill = fillObj.AddComponent<Image>();
        if (UISprites.BossHP_Fill != null)
        {
            bossHpBarFill.sprite = UISprites.BossHP_Fill;
            bossHpBarFill.type = Image.Type.Filled;
            bossHpBarFill.fillMethod = Image.FillMethod.Horizontal;
            bossHpBarFill.color = Color.white;
        }
        else
        {
            bossHpBarFill.color = new Color(0.9f, 0.15f, 0.15f);
            bossHpBarFill.type = Image.Type.Filled;
            bossHpBarFill.fillMethod = Image.FillMethod.Horizontal;
        }

        // HP 텍스트
        bossHpText = UIHelper.MakeText("BossHpText", bossHpBarRoot.transform, "",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, Color.white);
        bossHpText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(bossHpText);
        UIHelper.FillParent(bossHpText.GetComponent<RectTransform>());

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
    // 오프라인 보상 팝업
    // ════════════════════════════════════════

    void CreateOfflinePopup()
    {
        offlinePopup = UIHelper.MakeUI("OfflinePopup", safeAreaRoot.transform);
        var bg = offlinePopup.AddComponent<Image>();
        bg.color = UIColors.Overlay_Dark;
        UIHelper.FillParent(offlinePopup.GetComponent<RectTransform>());

        // Center panel — BoxBasic1 스프라이트
        var panelBg = UIHelper.MakeSpritePanel("Panel", offlinePopup.transform,
            UISprites.BoxBasic1, UIColors.Background_Panel);
        // BoxBasic1 스프라이트 원본 색상 유지
        var panel = panelBg;
        var prt = panel.GetComponent<RectTransform>();
        prt.anchorMin = new Vector2(0.1f, 0.35f);
        prt.anchorMax = new Vector2(0.9f, 0.65f);
        prt.offsetMin = Vector2.zero;
        prt.offsetMax = Vector2.zero;

        // Title — Board 배경 (진한 나무)
        var titleBanner = UIHelper.MakeSpritePanel("TitleBanner", panel.transform,
            UISprites.Board, UIColors.Background_Dark);
        // Board 스프라이트 원본 색상 유지
        var trt = titleBanner.GetComponent<RectTransform>();
        trt.anchorMin = new Vector2(0, 1f);
        trt.anchorMax = new Vector2(1, 1f);
        trt.pivot = new Vector2(0.5f, 1f);
        trt.sizeDelta = new Vector2(0, 36);

        var titleText = UIHelper.MakeText("Title", titleBanner.transform, "오프라인 보상",
            UIConstants.Font_HeaderLarge, TextAlignmentOptions.Center, Color.white);
        titleText.fontStyle = FontStyles.Bold;
        titleText.enableVertexGradient = true;
        titleText.colorGradient = new VertexGradient(
            new Color(1f, 0.97f, 0.90f), new Color(1f, 0.97f, 0.90f),
            new Color(0.88f, 0.78f, 0.60f), new Color(0.88f, 0.78f, 0.60f));
        UIHelper.AddTextShadow(titleText);
        UIHelper.FillParent(titleText.GetComponent<RectTransform>());

        // Reward text — 중앙, 어두운 색 (밝은 패널 대비)
        offlineText = UIHelper.MakeText("RewardText", panel.transform, "",
            UIConstants.Font_StatValue, TextAlignmentOptions.Center, UIColors.Text_Dark);
        offlineText.fontStyle = FontStyles.Bold;
        var rrt = offlineText.GetComponent<RectTransform>();
        rrt.anchorMin = new Vector2(0.05f, 0.3f);
        rrt.anchorMax = new Vector2(0.95f, 0.75f);
        rrt.offsetMin = Vector2.zero;
        rrt.offsetMax = Vector2.zero;

        // Confirm button — Btn2_WS (녹색)
        var (confirmBtn, _) = UIHelper.MakeSpriteButton("ConfirmBtn", panel.transform,
            UISprites.Btn2_WS, UIColors.Button_Green, "", UIConstants.Font_Button);
        var cbrt = confirmBtn.GetComponent<RectTransform>();
        cbrt.anchorMin = new Vector2(0.2f, 0f);
        cbrt.anchorMax = new Vector2(0.8f, 0f);
        cbrt.pivot = new Vector2(0.5f, 0f);
        cbrt.sizeDelta = new Vector2(0, 38);
        cbrt.anchoredPosition = new Vector2(0, 10);

        var confirmText = UIHelper.MakeText("Label", confirmBtn.transform, "확인",
            UIConstants.Font_Button, TextAlignmentOptions.Center, Color.white);
        confirmText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(confirmText);
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
    // 확인 팝업
    // ════════════════════════════════════════

    void CreateConfirmPopup()
    {
        confirmPopup = UIHelper.MakeUI("ConfirmPopup", safeAreaRoot.transform);
        var bg = confirmPopup.AddComponent<Image>();
        bg.color = UIColors.Overlay_Dark;
        UIHelper.FillParent(confirmPopup.GetComponent<RectTransform>());

        // 패널 — BoxBasic1 스프라이트
        var panelBg = UIHelper.MakeSpritePanel("Panel", confirmPopup.transform,
            UISprites.BoxBasic1, UIColors.Background_Panel);
        // BoxBasic1 스프라이트 원본 색상 유지
        var panel = panelBg;
        var prt = panel.GetComponent<RectTransform>();
        prt.anchorMin = new Vector2(0.1f, 0.36f);
        prt.anchorMax = new Vector2(0.9f, 0.64f);
        prt.offsetMin = Vector2.zero;
        prt.offsetMax = Vector2.zero;

        // 타이틀 — Board 스프라이트 (진한 나무)
        var titleBanner = UIHelper.MakeSpritePanel("TitleBanner", panel.transform,
            UISprites.Board, UIColors.Background_Dark);
        // Board 스프라이트 원본 색상 유지
        var trt2 = titleBanner.GetComponent<RectTransform>();
        trt2.anchorMin = new Vector2(0, 0.72f);
        trt2.anchorMax = new Vector2(1, 1);
        trt2.offsetMin = Vector2.zero;
        trt2.offsetMax = Vector2.zero;

        confirmTitleText = UIHelper.MakeText("Title", titleBanner.transform, "",
            UIConstants.Font_HeaderMedium, TextAlignmentOptions.Center, Color.white);
        confirmTitleText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(confirmTitleText);
        UIHelper.FillParent(confirmTitleText.GetComponent<RectTransform>());

        confirmDescText = UIHelper.MakeText("Desc", panel.transform, "",
            UIConstants.Font_StatValue, TextAlignmentOptions.Center, UIColors.Text_Dark);
        var drt = confirmDescText.GetComponent<RectTransform>();
        drt.anchorMin = new Vector2(0.05f, 0.32f);
        drt.anchorMax = new Vector2(0.95f, 0.72f);
        drt.offsetMin = Vector2.zero;
        drt.offsetMax = Vector2.zero;

        // YES 버튼 — Btn2_WS (녹색)
        var (yesBtn, _) = UIHelper.MakeSpriteButton("YesBtn", panel.transform,
            UISprites.Btn2_WS, UIColors.Button_Green, "", UIConstants.Font_Button);
        var ybrt = yesBtn.GetComponent<RectTransform>();
        ybrt.anchorMin = new Vector2(0.55f, 0.06f);
        ybrt.anchorMax = new Vector2(0.92f, 0.28f);
        ybrt.offsetMin = Vector2.zero;
        ybrt.offsetMax = Vector2.zero;
        var yesLabel = UIHelper.MakeText("Label", yesBtn.transform, "확인",
            UIConstants.Font_Button, TextAlignmentOptions.Center, Color.white);
        yesLabel.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(yesLabel);
        UIHelper.FillParent(yesLabel.GetComponent<RectTransform>());
        yesBtn.onClick.AddListener(() =>
        {
            confirmPopup.SetActive(false);
            pendingConfirmAction?.Invoke();
            pendingConfirmAction = null;
            SoundManager.Instance?.PlayButtonSFX();
        });

        // NO 버튼 — Btn4_WS (빨간색)
        var (noBtn, _) = UIHelper.MakeSpriteButton("NoBtn", panel.transform,
            UISprites.Btn4_WS, UIColors.Defeat_Red, "", UIConstants.Font_Button);
        var nbrt = noBtn.GetComponent<RectTransform>();
        nbrt.anchorMin = new Vector2(0.08f, 0.06f);
        nbrt.anchorMax = new Vector2(0.45f, 0.28f);
        nbrt.offsetMin = Vector2.zero;
        nbrt.offsetMax = Vector2.zero;
        var noLabel = UIHelper.MakeText("Label", noBtn.transform, "취소",
            UIConstants.Font_Button, TextAlignmentOptions.Center, Color.white);
        noLabel.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(noLabel);
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
            DailyLoginManager.RewardType.GachaTicket => "소환권 1장",
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

}
