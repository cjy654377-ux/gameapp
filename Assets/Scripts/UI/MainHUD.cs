using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections;
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
    TextMeshProUGUI stoneText;
    TextMeshProUGUI scrollText;
    // 재화 컨테이너 (탭별 표시/숨김용)
    GameObject goldContainer;
    GameObject gemContainer;
    GameObject stoneContainer;
    GameObject scrollContainer;
    TextMeshProUGUI awakeStoneText;
    GameObject awakeStoneContainer;
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

    // Revenge stack UI
    GameObject revengeIcon;
    TextMeshProUGUI revengeText;

    // Combat Power
    TextMeshProUGUI combatPowerText;


    // Bottom Nav
    readonly string[] tabNames = { "영웅", "소환", "전투", "던전", "상점" };
    readonly string[] tabIcons = { "★", "◆", "⚔", "⛩", "$" };
    const int TAB_COUNT = 5;
    readonly Button[] tabButtons = new Button[TAB_COUNT];
    readonly Image[] tabIndicators = new Image[TAB_COUNT];
    readonly TextMeshProUGUI[] tabLabels = new TextMeshProUGUI[TAB_COUNT];
    readonly TextMeshProUGUI[] tabIconTexts = new TextMeshProUGUI[TAB_COUNT];

    // Tab overlay panels
    readonly GameObject[] tabPanels = new GameObject[TAB_COUNT];
    readonly CanvasGroup[] tabPanelCGs = new CanvasGroup[TAB_COUNT];
    int activeTab = -1;

    // Badge notifications
    readonly GameObject[] tabBadges = new GameObject[TAB_COUNT];
    readonly TextMeshProUGUI[] tabBadgeTexts = new TextMeshProUGUI[TAB_COUNT];

    // 햄버거 메뉴
    GameObject hamburgerOverlay;
    HamburgerPanel hamburgerPanel;
    GameObject hamburgerBadge;
    TextMeshProUGUI hamburgerBadgeText;

    // 훈련 탭 업그레이드 UI
    // Boss HP bar
    GameObject bossHpBarRoot;
    Image bossHpBarFill;
    TextMeshProUGUI bossNameText;
    TextMeshProUGUI bossHpText;
    BattleUnit trackedBoss;

    // 아군 HP 위기 경고 비네트
    Image vignetteImage;
    const float VIGNETTE_HP_THRESHOLD = 0.20f;
    float vignettePhase;

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
    DungeonPanel dungeonPanel;

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
    SummonStoneManager cachedStoneMgr;
    SpellScrollManager cachedScrollMgr;
    StageManager cachedStageMgr;
    BattleManager cachedBattleMgr;
    OfflineRewardManager cachedOfflineMgr;
    UpgradeManager cachedUpgradeMgr;
    HeroLevelManager cachedHeroLevelMgr;
    System.Action<string, int> _onHeroLevelUp;
    AwakeningStoneManager cachedAwakeStoneMgr;

    void Start()
    {
        StartCoroutine(DeferredSubscribe());
    }

    System.Collections.IEnumerator DeferredSubscribe()
    {
        yield return null;

        cachedGoldMgr   = GoldManager.Instance;
        cachedGemMgr    = GemManager.Instance;
        cachedStoneMgr  = SummonStoneManager.Instance;
        cachedScrollMgr = SpellScrollManager.Instance;
        cachedStageMgr  = StageManager.Instance;
        cachedBattleMgr = BattleManager.Instance;

        if (cachedGoldMgr != null)
            cachedGoldMgr.OnGoldChanged += UpdateGold;
        if (cachedGemMgr != null)
            cachedGemMgr.OnGemChanged += UpdateGem;
        if (cachedStoneMgr != null)
            cachedStoneMgr.OnStoneChanged += UpdateStone;
        if (cachedScrollMgr != null)
            cachedScrollMgr.OnScrollChanged += UpdateScroll;
        if (cachedStageMgr != null)
        {
            cachedStageMgr.OnStageChanged += OnStageChanged;
            cachedStageMgr.OnBossSpawned += OnBossSpawned;
            cachedStageMgr.OnWaveCleared += OnWaveCleared;
            cachedStageMgr.OnRevengeStackChanged += UpdateRevengeUI;
        }
        if (cachedBattleMgr != null)
            cachedBattleMgr.OnBattleStateChanged += OnBattleStateChanged;

        cachedOfflineMgr = OfflineRewardManager.Instance;
        if (cachedOfflineMgr != null)
            cachedOfflineMgr.OnOfflineReward += OnOfflineReward;

        cachedUpgradeMgr = UpgradeManager.Instance;
        if (cachedUpgradeMgr != null)
            cachedUpgradeMgr.OnUpgraded += UpdateCombatPower;

        cachedHeroLevelMgr = HeroLevelManager.Instance;
        if (cachedHeroLevelMgr != null)
        {
            _onHeroLevelUp = (_, __) => UpdateCombatPower();
            cachedHeroLevelMgr.OnHeroLevelUp += _onHeroLevelUp;
        }

        cachedAwakeStoneMgr = AwakeningStoneManager.Instance;
        if (cachedAwakeStoneMgr != null)
            cachedAwakeStoneMgr.OnStoneChanged += UpdateAwakeStone;

        UpdateGold(cachedGoldMgr != null ? cachedGoldMgr.Gold : 0);
        UpdateGem(cachedGemMgr != null ? cachedGemMgr.Gem : 0);
        UpdateStone(cachedStoneMgr != null ? cachedStoneMgr.Stone : 0);
        UpdateScroll(cachedScrollMgr != null ? cachedScrollMgr.Scroll : 0);
        UpdateAwakeStone(cachedAwakeStoneMgr != null ? cachedAwakeStoneMgr.Stone : 0);
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

        // 아군 HP 위기 비네트
        UpdateVignette();
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
        CreateRevengeIcon();

        heroSelectPanel = safeAreaRoot.AddComponent<HeroSelectPanel>();
        heroSelectPanel.Init(safeAreaRoot.transform, () => enhancePanel?.Refresh());
        CreateBottomNavBar();
        CreateTabPanels();
        CreateOfflinePopup();
        CreateConfirmPopup();
        CreateBossHpBar();
        CreateVignette();
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

        // 스테이지 정보 영역 (왼쪽 26%) — BoxBanner로 감싼다
        var stageContainer = UIHelper.MakeSpritePanel("StageBG", hudBar.transform, UISprites.BoxBanner, UIColors.Background_Dark);
        var scrt = stageContainer.GetComponent<RectTransform>();
        scrt.anchorMin = new Vector2(0, 0.06f);
        scrt.anchorMax = new Vector2(0.26f, 0.94f);
        scrt.offsetMin = new Vector2(3, 0);
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

        // Combat Power (전투력) — 프로그레스바 위 우측
        combatPowerText = UIHelper.MakeText("CombatPower", stageContainer.transform, "⚔ -",
            7f, TextAlignmentOptions.MidlineLeft, new Color(1f, 0.85f, 0.4f));
        UIHelper.AddTextShadow(combatPowerText);
        var cprt = combatPowerText.GetComponent<RectTransform>();
        cprt.anchorMin = new Vector2(0.36f, 0.52f);
        cprt.anchorMax = new Vector2(1f, 0.9f);
        cprt.offsetMin = new Vector2(2, 0);
        cprt.offsetMax = Vector2.zero;

        // Gold
        CreateResourceDisplay(hudBar.transform, "Gold", UISprites.IconGold,
            UIColors.Text_Gold, new Vector2(0.27f, 0.08f), new Vector2(0.44f, 0.92f),
            out goldText, out goldContainer);

        // Gem (보석)
        CreateResourceDisplay(hudBar.transform, "Gem", UISprites.IconDiamond,
            UIColors.Text_Diamond, new Vector2(0.45f, 0.08f), new Vector2(0.62f, 0.92f),
            out gemText, out gemContainer);

        // 소환석
        CreateResourceDisplay(hudBar.transform, "Stone", UISprites.IconPotion1,
            new Color(0.55f, 0.88f, 1.00f), new Vector2(0.63f, 0.08f), new Vector2(0.80f, 0.92f),
            out stoneText, out stoneContainer);

        // 주문서
        CreateResourceDisplay(hudBar.transform, "Scroll", UISprites.IconSkill,
            new Color(0.88f, 0.68f, 1.00f), new Vector2(0.77f, 0.08f), new Vector2(0.88f, 0.92f),
            out scrollText, out scrollContainer);

        // 각성석 (영웅탭 전용, gem 위치 공유)
        CreateResourceDisplay(hudBar.transform, "AwakeStone", UISprites.IconSword,
            new Color(1.00f, 0.70f, 0.30f), new Vector2(0.45f, 0.08f), new Vector2(0.62f, 0.92f),
            out awakeStoneText, out awakeStoneContainer);

        // 햄버거 버튼 (☰)
        var hamBtn = UIHelper.MakeUI("HamburgerBtn", hudBar.transform);
        var hamImg = hamBtn.AddComponent<Image>();
        hamImg.color = UIColors.Panel_Inner;
        var hamButton = hamBtn.AddComponent<Button>();
        hamButton.targetGraphic = hamImg;
        hamButton.onClick.AddListener(ToggleHamburger);
        var hamRT = hamBtn.GetComponent<RectTransform>();
        hamRT.anchorMin = new Vector2(0.89f, 0.06f);
        hamRT.anchorMax = new Vector2(0.99f, 0.94f);
        hamRT.offsetMin = Vector2.zero;
        hamRT.offsetMax = Vector2.zero;

        var hamLabel = UIHelper.MakeText("Icon", hamBtn.transform, "☰",
            14f, TextAlignmentOptions.Center, UIColors.Text_Gold);
        hamLabel.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(hamLabel.GetComponent<RectTransform>());

        // 햄버거 배지
        hamburgerBadge = UIHelper.MakeUI("HamBadge", hamBtn.transform);
        var hamBadgeImg = hamburgerBadge.AddComponent<Image>();
        hamBadgeImg.color = UIColors.Defeat_Red;
        var hbRT = hamburgerBadge.GetComponent<RectTransform>();
        hbRT.anchorMin = new Vector2(0.65f, 0.65f);
        hbRT.anchorMax = new Vector2(0.65f, 0.65f);
        hbRT.pivot = new Vector2(0.5f, 0.5f);
        hbRT.sizeDelta = new Vector2(14, 14);
        hamburgerBadgeText = UIHelper.MakeText("Count", hamburgerBadge.transform, "",
            7f, TextAlignmentOptions.Center, Color.white);
        UIHelper.FillParent(hamburgerBadgeText.GetComponent<RectTransform>());
        hamburgerBadge.SetActive(false);
    }

    void CreateResourceDisplay(Transform parent, string name, Sprite iconSprite,
        Color iconColor, Vector2 anchorMin, Vector2 anchorMax, out TextMeshProUGUI valueText,
        out GameObject containerOut)
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

        // 아이콘 (14px — 좁은 컨테이너에 맞게 축소)
        if (iconSprite != null)
        {
            var iconImg = UIHelper.MakeIcon($"{name}Icon", container.transform, iconSprite, iconColor);
            var irt = iconImg.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0, 0.1f);
            irt.anchorMax = new Vector2(0, 0.9f);
            irt.pivot = new Vector2(0, 0.5f);
            irt.anchoredPosition = new Vector2(3, 0);
            irt.sizeDelta = new Vector2(14, 0);
        }
        else
        {
            var iconBg = UIHelper.MakePanel($"{name}Icon", container.transform, iconColor);
            var irt = iconBg.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0, 0.18f);
            irt.anchorMax = new Vector2(0, 0.82f);
            irt.pivot = new Vector2(0, 0.5f);
            irt.anchoredPosition = new Vector2(3, 0);
            irt.sizeDelta = new Vector2(14, 0);

            string fallbackChar = name switch { "Gold" => "G", "Gem" => "◆", "Stone" => "○", _ => "S" };
            var iconText = UIHelper.MakeText($"{name}IconText", iconBg.transform,
                fallbackChar, UIConstants.Font_LevelBadge, TextAlignmentOptions.Center, UIColors.Background_Dark);
            iconText.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(iconText.GetComponent<RectTransform>());
        }

        // 리소스 값 텍스트
        Color valueColor = name switch
        {
            "Gold"   => UIColors.Text_Gold,
            "Gem"    => UIColors.Text_Diamond,
            "Stone"  => new Color(0.55f, 0.88f, 1.00f),
            "Scroll" => new Color(0.88f, 0.68f, 1.00f),
            _        => Color.white
        };
        valueText = UIHelper.MakeText($"{name}Text", container.transform, "0",
            UIConstants.Font_HUDResource, TextAlignmentOptions.Center, valueColor);
        valueText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(valueText);
        var vrt = valueText.GetComponent<RectTransform>();
        vrt.anchorMin = new Vector2(0.32f, 0);
        vrt.anchorMax = new Vector2(1, 1);
        vrt.offsetMin = Vector2.zero;
        vrt.offsetMax = new Vector2(-3, 0);
        containerOut = container.gameObject;
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

    void CreateRevengeIcon()
    {
        revengeIcon = UIHelper.MakeUI("RevengeIcon", safeAreaRoot.transform);
        var bg = UIHelper.MakeSpritePanel("RevengeBG", revengeIcon.transform,
            UISprites.BoxIcon1, new Color(0.5f, 0.05f, 0.05f, 0.9f));
        UIHelper.FillParent(bg.GetComponent<RectTransform>());

        var rt = revengeIcon.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0, 0.5f);
        rt.anchorMax = new Vector2(0, 0.5f);
        rt.pivot = new Vector2(0, 0.5f);
        rt.anchoredPosition = new Vector2(UIConstants.Spacing_Small, 22);
        rt.sizeDelta = new Vector2(72, 22);

        revengeText = UIHelper.MakeText("RevengeText", revengeIcon.transform, "복수자 x1",
            UIConstants.Font_Tab, TextAlignmentOptions.Center, new Color(1f, 0.6f, 0.4f));
        revengeText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(revengeText);
        UIHelper.FillParent(revengeText.GetComponent<RectTransform>());

        revengeIcon.SetActive(false);
    }

    void UpdateRevengeUI(int stack)
    {
        if (revengeIcon == null) return;
        if (stack <= 0)
        {
            revengeIcon.SetActive(false);
            return;
        }
        revengeIcon.SetActive(true);
        if (revengeText != null)
            revengeText.text = $"복수자 x{stack}";
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
        tabSpriteIcons[0] = UISprites.IconSkill;     // 영웅
        tabSpriteIcons[1] = UISprites.IconPotion1;   // 소환
        tabSpriteIcons[2] = UISprites.IconSword;     // 전투 (center)
        tabSpriteIcons[3] = UISprites.IconInven;     // 던전
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
            // center(전투) 탭은 위로 돌출
            if (i == 2)
            {
                trt.offsetMin = new Vector2(1, -8);
                trt.offsetMax = new Vector2(-1, -4);
            }
            else
            {
                trt.offsetMin = new Vector2(2, 4);
                trt.offsetMax = new Vector2(-2, -4);
            }

            // Active indicator (하단 골드 라인 — 5px)
            var indicator = UIHelper.MakePanel("Indicator", tabObj.transform, UIColors.Text_Gold);
            var irt = indicator.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0.05f, 0);
            irt.anchorMax = new Vector2(0.95f, 0);
            irt.pivot = new Vector2(0.5f, 0);
            irt.sizeDelta = new Vector2(0, 5);
            indicator.gameObject.SetActive(false);
            tabIndicators[i] = indicator;

            // 아이콘 — 7탭 기준으로 아이콘 영역 조정 (0.15~0.85 가로, 0.35~0.90 세로)
            if (tabSpriteIcons[i] != null)
            {
                var iconImg = UIHelper.MakeIcon("Icon", tabObj.transform, tabSpriteIcons[i], new Color(0.85f, 0.82f, 0.78f));
                var icrt = iconImg.GetComponent<RectTransform>();
                icrt.anchorMin = new Vector2(0.15f, 0.35f);
                icrt.anchorMax = new Vector2(0.85f, 0.90f);
                icrt.offsetMin = Vector2.zero;
                icrt.offsetMax = Vector2.zero;
                tabIconTexts[i] = null;
            }
            else
            {
                tabIconTexts[i] = UIHelper.MakeText("Icon", tabObj.transform, tabIcons[i],
                    14f, TextAlignmentOptions.Center, UIColors.Text_Secondary);
                tabIconTexts[i].fontStyle = FontStyles.Bold;
                var icrt = tabIconTexts[i].GetComponent<RectTransform>();
                icrt.anchorMin = new Vector2(0, 0.38f);
                icrt.anchorMax = new Vector2(1, 0.90f);
                icrt.offsetMin = Vector2.zero;
                icrt.offsetMax = Vector2.zero;
            }

            // Label — 7탭 가독성을 위해 8f 사용
            tabLabels[i] = UIHelper.MakeText("Label", tabObj.transform, tabNames[i],
                UIConstants.Font_NavLabel, TextAlignmentOptions.Top, UIColors.Text_Secondary);
            tabLabels[i].fontStyle = FontStyles.Bold;
            var lrt = tabLabels[i].GetComponent<RectTransform>();
            lrt.anchorMin = new Vector2(0, 0.02f);
            lrt.anchorMax = new Vector2(1, 0.36f);
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
                enhancePanel = panel.AddComponent<EnhancePanel>();
                enhancePanel.Init(panel.transform, heroSelectPanel.Show);
            }
            else if (i == 1)
            {
                gachaPanel = panel.AddComponent<GachaPanel>();
                gachaPanel.Init(panel.transform, ShowConfirm);
            }
            else if (i == 2)
            {
                // 전투 탭: 패널 없음 (클릭 시 패널 닫힘)
            }
            else if (i == 3)
            {
                dungeonPanel = panel.AddComponent<DungeonPanel>();
                dungeonPanel.Init(panel.transform);
            }
            else if (i == 4)
            {
                shopPanel = panel.AddComponent<ShopPanel>();
                shopPanel.Init(panel.transform, ShowConfirm);
            }

            tabPanels[i] = panel;
            var cg = panel.AddComponent<CanvasGroup>();
            cg.alpha = 1f;
            tabPanelCGs[i] = cg;
            panel.SetActive(false);
        }

        // 햄버거 오버레이 생성
        CreateHamburgerOverlay();
    }

    void CreateHamburgerOverlay()
    {
        float refH = UIConstants.ReferenceResolution.y;
        float navRatio = 58f / refH;
        float hudRatio = UIConstants.HUD_Height / refH;

        hamburgerOverlay = UIHelper.MakeUI("HamburgerOverlay", safeAreaRoot.transform);
        var overlayBg = UIHelper.MakeSpritePanel("OverlayBG", hamburgerOverlay.transform,
            UISprites.BoxBasic1, UIColors.Background_Panel);
        UIHelper.FillParent(overlayBg.GetComponent<RectTransform>());
        var hrt = hamburgerOverlay.GetComponent<RectTransform>();
        hrt.anchorMin = new Vector2(0, navRatio);
        hrt.anchorMax = new Vector2(1, 1 - hudRatio);
        hrt.offsetMin = Vector2.zero;
        hrt.offsetMax = Vector2.zero;

        // 헤더
        var header = UIHelper.MakeSpritePanel("Header", hamburgerOverlay.transform,
            UISprites.Board, UIColors.Background_Dark);
        var hhrt = header.GetComponent<RectTransform>();
        hhrt.anchorMin = new Vector2(0, 1);
        hhrt.anchorMax = new Vector2(1, 1);
        hhrt.pivot = new Vector2(0.5f, 1);
        hhrt.sizeDelta = new Vector2(0, UIConstants.Tab_Height);

        var title = UIHelper.MakeText("Title", header.transform, "메뉴",
            UIConstants.Font_HeaderMedium, TextAlignmentOptions.Center, Color.white);
        title.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(title.GetComponent<RectTransform>());

        var closeBtn2 = UIHelper.MakeUI("CloseBtn", header.transform);
        var closeImg2 = closeBtn2.AddComponent<Image>();
        closeImg2.color = UIColors.Button_Brown;
        var closeBtnComp = closeBtn2.AddComponent<Button>();
        closeBtnComp.targetGraphic = closeImg2;
        closeBtnComp.onClick.AddListener(() => {
            SoundManager.Instance?.PlayUISound(UISoundType.button_click);
            hamburgerOverlay.SetActive(false);
        });
        var cbrt = closeBtn2.GetComponent<RectTransform>();
        cbrt.anchorMin = new Vector2(1, 0.5f);
        cbrt.anchorMax = new Vector2(1, 0.5f);
        cbrt.pivot = new Vector2(1, 0.5f);
        cbrt.anchoredPosition = new Vector2(-6, 0);
        cbrt.sizeDelta = new Vector2(24, 24);
        var closeLabel = UIHelper.MakeText("X", closeBtn2.transform, "X",
            12f, TextAlignmentOptions.Center, Color.white);
        closeLabel.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(closeLabel.GetComponent<RectTransform>());

        // HamburgerPanel 컴포넌트 (컨텐츠 영역)
        var hamContent = UIHelper.MakeUI("HamContent", hamburgerOverlay.transform);
        var hcRT = hamContent.GetComponent<RectTransform>();
        hcRT.anchorMin = Vector2.zero;
        hcRT.anchorMax = Vector2.one;
        hcRT.offsetMin = Vector2.zero;
        hcRT.offsetMax = new Vector2(0, -UIConstants.Tab_Height);
        hamburgerPanel = hamContent.AddComponent<HamburgerPanel>();
        hamburgerPanel.Init(hamContent.transform);

        hamburgerOverlay.SetActive(false);
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
            var stageMgr = StageManager.Instance;
            if (stageMgr != null)
            {
                stageMgr.RewindAndRestart();
                // 복수자 스택 메시지 (RewindAndRestart가 스택을 올린 직후)
                ShowRevengeBanner(stageMgr.RevengeStack);
            }
        }
    }

    void ShowRevengeBanner(int stack)
    {
        if (waveBanner == null || waveBannerText == null || stack <= 0) return;
        int atkPct = stack * 8;
        waveBannerText.text = $"복수자의 분노가 타오릅니다! (ATK+{atkPct}%)";
        waveBannerText.color = new Color(1f, 0.45f, 0.1f);

        var outline = waveBanner.GetComponent<Outline>();
        if (outline != null) outline.effectColor = new Color(0.7f, 0.1f, 0f, 0.8f);

        if (waveBannerCG != null) waveBannerCG.alpha = 1f;
        waveBanner.SetActive(true);
        waveBannerTimer = 2.5f;
    }

    /// <summary>외부에서 탭 전환 (재화 부족 안내 바로가기 등)</summary>
    public void SwitchToTab(int idx) => OnTabClicked(idx);

    Coroutine highlightCoroutine;
    int highlightTabIndex = -1;

    /// <summary>튜토리얼용 탭 버튼 깜빡 하이라이트</summary>
    public void HighlightTab(int tabIndex)
    {
        StopHighlight();
        if (tabIndex < 0 || tabIndex >= TAB_COUNT || tabButtons[tabIndex] == null) return;
        highlightTabIndex = tabIndex;
        highlightCoroutine = StartCoroutine(TabBlinkRoutine(tabIndex));
    }

    public void StopHighlight()
    {
        if (highlightCoroutine != null)
        {
            StopCoroutine(highlightCoroutine);
            highlightCoroutine = null;
        }
        if (highlightTabIndex >= 0 && highlightTabIndex < TAB_COUNT && tabButtons[highlightTabIndex] != null)
        {
            var img = tabButtons[highlightTabIndex].GetComponent<UnityEngine.UI.Image>();
            if (img != null) img.color = highlightTabIndex == activeTab
                ? new Color(1.00f, 0.92f, 0.68f) : Color.white;
        }
        highlightTabIndex = -1;
    }

    System.Collections.IEnumerator TabBlinkRoutine(int tabIndex)
    {
        var img = tabButtons[tabIndex].GetComponent<UnityEngine.UI.Image>();
        if (img == null) yield break;
        Color normalColor = tabIndex == activeTab ? new Color(1.00f, 0.92f, 0.68f) : Color.white;
        Color highlightColor = new Color(1f, 0.85f, 0.2f);
        while (true)
        {
            img.color = highlightColor;
            yield return new WaitForSecondsRealtime(0.5f);
            img.color = normalColor;
            yield return new WaitForSecondsRealtime(0.5f);
        }
    }

    void OnTabClicked(int idx)
    {
        SoundManager.Instance?.PlayUISound(UISoundType.tab_switch);
        // 전투 탭(i==2): 패널 없음 → 열린 패널만 닫기
        if (idx == 2) { StartCoroutine(ClosePanelFade()); return; }
        if (activeTab == idx) { StartCoroutine(ClosePanelFade()); return; }
        StartCoroutine(SwitchTabFade(idx));
        // 탭 버튼 스케일 피드백
        if (idx < tabButtons.Length && tabButtons[idx] != null)
            StartCoroutine(ButtonPressFeedback(tabButtons[idx].transform));
    }

    IEnumerator ClosePanelFade()
    {
        if (activeTab >= 0 && tabPanelCGs[activeTab] != null)
        {
            var cg = tabPanelCGs[activeTab];
            float t = 0;
            while (t < 0.15f) { t += Time.unscaledDeltaTime; cg.alpha = Mathf.Lerp(1, 0, t / 0.15f); yield return null; }
            cg.alpha = 1f;
        }
        ClosePanel();
    }

    IEnumerator SwitchTabFade(int idx)
    {
        // 현재 패널 페이드 아웃
        if (activeTab >= 0 && tabPanelCGs[activeTab] != null)
        {
            var cg = tabPanelCGs[activeTab];
            float t = 0;
            while (t < 0.15f) { t += Time.unscaledDeltaTime; cg.alpha = Mathf.Lerp(1, 0, t / 0.15f); yield return null; }
            cg.alpha = 1f;
        }
        ClosePanel();

        // 새 패널 페이드 인
        activeTab = idx;
        tabPanels[idx].SetActive(true);
        SkillUI.IsTabPanelOpen = true;
        UpdateTabVisuals();
        UpdateCurrencyDisplay(idx);
        if (idx == 0) enhancePanel?.Refresh();
        if (idx == 1) gachaPanel?.Refresh();
        if (idx == 3) dungeonPanel?.Refresh();
        if (idx == 4) shopPanel?.Refresh();

        if (tabPanelCGs[idx] != null)
        {
            var cg = tabPanelCGs[idx];
            cg.alpha = 0f;
            float t = 0;
            while (t < 0.15f) { t += Time.unscaledDeltaTime; cg.alpha = Mathf.Lerp(0, 1, t / 0.15f); yield return null; }
            cg.alpha = 1f;
        }
    }

    IEnumerator ButtonPressFeedback(Transform btnTransform)
    {
        float t = 0;
        while (t < 0.08f) { t += Time.unscaledDeltaTime; float s = Mathf.Lerp(1f, 0.95f, t / 0.08f); btnTransform.localScale = Vector3.one * s; yield return null; }
        t = 0;
        while (t < 0.08f) { t += Time.unscaledDeltaTime; float s = Mathf.Lerp(0.95f, 1f, t / 0.08f); btnTransform.localScale = Vector3.one * s; yield return null; }
        btnTransform.localScale = Vector3.one;
    }

    void ToggleHamburger()
    {
        if (hamburgerOverlay == null) return;
        SoundManager.Instance?.PlayUISound(UISoundType.button_click);
        bool nowActive = !hamburgerOverlay.activeSelf;
        hamburgerOverlay.SetActive(nowActive);
        if (nowActive) hamburgerPanel?.Refresh();
    }

    void ClosePanel()
    {
        SoundManager.Instance?.PlayUISound(UISoundType.button_click);
        if (activeTab >= 0)
            tabPanels[activeTab].SetActive(false);
        activeTab = -1;
        SkillUI.IsTabPanelOpen = false;
        UpdateTabVisuals();
        UpdateCurrencyDisplay(-1); // 전투 화면: 골드만
    }

    void UpdateTabVisuals()
    {
        for (int i = 0; i < TAB_COUNT; i++)
        {
            bool active = (i == activeTab);
            var tabImg = tabButtons[i].GetComponent<Image>();

            if (UISprites.Btn1_WS != null)
            {
                // 선택: 따뜻한 골드 tint, 미선택: 일반 흰색
                tabImg.color = active ? new Color(1.00f, 0.92f, 0.68f) : Color.white;
                tabButtons[i].transform.localScale = Vector3.one; // 크기 변화 없음
            }
            else
            {
                tabImg.color = active ? UIColors.Tab_Active : UIColors.Tab_Inactive;
            }

            // 라벨: 선택=밝은 골드, 미선택=크림색
            tabLabels[i].color = active ? UIColors.Text_Gold : UIColors.Text_Secondary;
            tabLabels[i].fontStyle = FontStyles.Bold;

            // 아이콘 (텍스트 아이콘인 경우만)
            if (tabIconTexts[i] != null)
                tabIconTexts[i].color = active ? UIColors.Text_Gold : UIColors.Text_Secondary;

            // 스프라이트 아이콘 색상 조정
            var iconImgObj = tabButtons[i].transform.Find("Icon");
            if (iconImgObj != null)
            {
                var iconImg = iconImgObj.GetComponent<Image>();
                if (iconImg != null && iconImg.sprite != null)
                    iconImg.color = active ? UIColors.Text_Gold : new Color(0.85f, 0.82f, 0.78f);
            }

            tabIndicators[i].gameObject.SetActive(active);
        }
    }

    // ════════════════════════════════════════
    // UPDATES
    // ════════════════════════════════════════

    // 탭별 재화 컨텍스트 표시
    void UpdateCurrencyDisplay(int tabIdx)
    {
        // -1: 전투(패널 없음) / 2: 전투탭 → 골드만
        // 0: 영웅 → 골드+각성석
        // 1: 소환 → 보석+소환석+주문서
        // 3: 던전 → 골드
        // 4: 상점 → 골드+보석
        bool showGold       = (tabIdx != 1);                  // 소환탭만 골드 숨김
        bool showGem        = (tabIdx == 1 || tabIdx == 4);   // 소환, 상점
        bool showStone      = (tabIdx == 1);                   // 소환
        bool showScroll     = (tabIdx == 1);                   // 소환
        bool showAwakeStone = (tabIdx == 0);                   // 영웅

        if (goldContainer      != null) goldContainer.SetActive(showGold);
        if (gemContainer       != null) gemContainer.SetActive(showGem);
        if (stoneContainer     != null) stoneContainer.SetActive(showStone);
        if (scrollContainer    != null) scrollContainer.SetActive(showScroll);
        if (awakeStoneContainer != null) awakeStoneContainer.SetActive(showAwakeStone);
    }

    void UpdateAwakeStone(int stone)
    {
        if (awakeStoneText != null) awakeStoneText.text = UIHelper.FormatNumber(stone);
    }

    void UpdateGold(int gold)
    {
        if (goldText != null) goldText.text = UIHelper.FormatNumber(gold);
    }

    void UpdateGem(int gem)
    {
        if (gemText != null) gemText.text = UIHelper.FormatNumber(gem);
    }

    void UpdateStone(int stone)
    {
        if (stoneText != null) stoneText.text = UIHelper.FormatNumber(stone);
    }

    void UpdateScroll(int scroll)
    {
        if (scrollText != null) scrollText.text = UIHelper.FormatNumber(scroll);
    }

    void UpdateProgress(int wave)
    {
        // 에리어 전체 진행도로 변경: 현재 에리어 내 완료 웨이브 / 에리어 총 웨이브
        var sm = StageManager.Instance;
        if (sm == null) return;

        int wavesPerArea = sm.wavesPerStage * sm.stagesPerArea;
        int completedInArea = sm.TotalWaveIndex % wavesPerArea;
        int remaining = wavesPerArea - completedInArea;

        if (progressBarFill != null)
            progressBarFill.fillAmount = wavesPerArea > 0 ? (float)completedInArea / wavesPerArea : 0f;

        if (progressText != null)
            progressText.text = remaining > 0 ? $"▶{remaining}w" : "NEXT!";
    }

    void UpdateCombatPower()
    {
        if (combatPowerText == null) return;
        var bm = BattleManager.Instance;
        if (bm == null || bm.allyUnits.Count == 0) { combatPowerText.text = "⚔ -"; return; }

        int totalCp = 0;
        for (int i = 0; i < bm.allyUnits.Count; i++)
        {
            var u = bm.allyUnits[i];
            if (u != null)
                totalCp += Mathf.RoundToInt(u.maxHp + u.atk * 3f + u.def * 2f);
        }
        combatPowerText.text = $"⚔ {UIHelper.FormatNumber(totalCp)}";
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

    void OnWaveCleared()
    {
        if (waveBanner == null || waveBannerText == null) return;

        waveBannerText.text = "WAVE CLEAR!";
        waveBannerText.color = UIColors.Button_Yellow;

        var outline = waveBanner.GetComponent<Outline>();
        if (outline != null) outline.effectColor = new Color(0.6f, 0.4f, 0f, 0.8f);

        if (waveBannerCG != null) waveBannerCG.alpha = 1f;
        waveBanner.SetActive(true);
        waveBannerTimer = 1.5f;

        // 골드 텍스트 분수
        SpawnGoldFountain();
    }

    void SpawnGoldFountain()
    {
        var cam = Camera.main;
        if (cam == null) return;

        float centerX = cam.transform.position.x;
        float centerY = cam.transform.position.y;
        const int COUNT = 6;

        for (int i = 0; i < COUNT; i++)
        {
            float x = centerX + Random.Range(-2f, 2f);
            float y = centerY + Random.Range(-0.5f, 1f);
            int goldAmt = Random.Range(5, 30);
            DamagePopup.CreateGold(new Vector3(x, y, 0), goldAmt);
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
            if (items[i] != null) Object.Destroy(items[i]);
            items.RemoveAt(i);
        }
    }

    void UpdateBadges()
    {
        var nbs = NotificationBadgeSystem.Instance;
        if (nbs == null) return;

        SetBadge(0, nbs.GetHeroBadgeCount());
        SetBadge(1, nbs.GetGachaBadgeCount());
        SetBadge(3, nbs.GetDungeonBadgeCount());
        SetBadge(4, nbs.GetShopBadgeCount());

        int hamburgerCount = nbs.GetHamburgerBadgeCount();
        if (hamburgerBadge != null)
        {
            hamburgerBadge.SetActive(hamburgerCount > 0);
            if (hamburgerBadgeText != null) hamburgerBadgeText.text = hamburgerCount.ToString();
        }
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

    void CreateVignette()
    {
        // 전체 화면 덮는 빨간 비네트 (가장자리만 보이도록 중앙 투명)
        // ScreenFader와 별도 캔버스가 아닌 기존 canvas 안에 생성
        var vigObj = UIHelper.MakeUI("CrisisVignette", canvas.transform);
        vignetteImage = vigObj.AddComponent<Image>();
        vignetteImage.color = new Color(1f, 0f, 0f, 0f);
        vignetteImage.raycastTarget = false;
        var rt = vigObj.GetComponent<RectTransform>();
        rt.anchorMin = Vector2.zero;
        rt.anchorMax = Vector2.one;
        rt.offsetMin = Vector2.zero;
        rt.offsetMax = Vector2.zero;
    }

    void UpdateVignette()
    {
        if (vignetteImage == null) return;

        var bm = BattleManager.Instance;
        if (bm == null) { vignetteImage.color = new Color(1f, 0f, 0f, 0f); return; }

        // 아군 중 HP 20% 이하 유닛 체크
        bool inCrisis = false;
        var allies = bm.allyUnits;
        for (int i = 0; i < allies.Count; i++)
        {
            var u = allies[i];
            if (u == null || u.IsDead) continue;
            if (u.maxHp > 0 && u.CurrentHp / u.maxHp <= VIGNETTE_HP_THRESHOLD)
            {
                inCrisis = true;
                break;
            }
        }

        if (inCrisis)
        {
            vignettePhase += Time.unscaledDeltaTime * 3f;
            float alpha = (Mathf.Sin(vignettePhase) * 0.5f + 0.5f) * 0.28f;
            vignetteImage.color = new Color(1f, 0f, 0f, alpha);
        }
        else
        {
            vignettePhase = 0f;
            var c = vignetteImage.color;
            if (c.a > 0f)
                vignetteImage.color = new Color(1f, 0f, 0f, Mathf.Max(0f, c.a - Time.unscaledDeltaTime * 2f));
        }
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
        HideBossHpBar(); // 보스 이벤트 구독 해제

        if (cachedGoldMgr != null)
            cachedGoldMgr.OnGoldChanged -= UpdateGold;
        if (cachedGemMgr != null)
            cachedGemMgr.OnGemChanged -= UpdateGem;
        if (cachedStoneMgr != null)
            cachedStoneMgr.OnStoneChanged -= UpdateStone;
        if (cachedScrollMgr != null)
            cachedScrollMgr.OnScrollChanged -= UpdateScroll;
        if (cachedStageMgr != null)
        {
            cachedStageMgr.OnStageChanged -= OnStageChanged;
            cachedStageMgr.OnBossSpawned -= OnBossSpawned;
            cachedStageMgr.OnWaveCleared -= OnWaveCleared;
            cachedStageMgr.OnRevengeStackChanged -= UpdateRevengeUI;
        }
        if (cachedBattleMgr != null)
            cachedBattleMgr.OnBattleStateChanged -= OnBattleStateChanged;
        if (cachedOfflineMgr != null)
            cachedOfflineMgr.OnOfflineReward -= OnOfflineReward;
        if (cachedUpgradeMgr != null)
            cachedUpgradeMgr.OnUpgraded -= UpdateCombatPower;
        if (cachedHeroLevelMgr != null && _onHeroLevelUp != null)
            cachedHeroLevelMgr.OnHeroLevelUp -= _onHeroLevelUp;
        if (cachedAwakeStoneMgr != null)
            cachedAwakeStoneMgr.OnStoneChanged -= UpdateAwakeStone;
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
            SoundManager.Instance?.PlayUISound(UISoundType.button_click);
            offlinePopup.SetActive(false);
        });

        offlinePopup.SetActive(false);
    }

    void OnOfflineReward(int gold, int gem, int exp, int fragments, float minutes)
    {
        if (offlinePopup == null || offlineText == null) return;
        if (gold <= 0 && gem <= 0 && exp <= 0 && fragments <= 0) return;

        int mins = Mathf.FloorToInt(minutes);
        string timeStr = mins >= 60 ? $"{mins / 60}시간 {mins % 60}분" : $"{mins}분";

        int currentWave = StageManager.Instance != null ? StageManager.Instance.CurrentWave : 0;
        string waveStr = currentWave > 0 ? $"\n현재 웨이브: <color=#AADDFF>Wave {currentWave}</color>" : "";

        var orm = OfflineRewardManager.Instance;
        int copies = orm != null ? orm.LastCopiesReward : 0;

        string rewardStr = $"접속하지 않은 {timeStr} 동안\n";
        if (gold > 0) rewardStr += $"<color=#FFD700>골드 +{gold}</color>  ";
        if (gem > 0) rewardStr += $"<color=#87CEEB>보석 +{gem}</color>\n";
        if (exp > 0) rewardStr += $"<color=#FFAAFF>경험치 +{exp}</color>  ";
        if (copies > 0) rewardStr += $"<color=#AAFFAA>영웅 카드 +{copies}</color>\n";
        if (fragments > 0) rewardStr += $"<color=#FFCCAA>장비 조각 +{fragments}</color>";
        rewardStr += waveStr;

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
            SoundManager.Instance?.PlayUISound(UISoundType.button_click);
            confirmPopup.SetActive(false);
            pendingConfirmAction?.Invoke();
            pendingConfirmAction = null;
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
            SoundManager.Instance?.PlayUISound(UISoundType.button_click);
            confirmPopup.SetActive(false);
            pendingConfirmAction = null;
        });

        confirmPopup.SetActive(false);
    }

    public void ShowConfirmDialog(string title, string desc, System.Action onConfirm)
        => ShowConfirm(title, desc, onConfirm);

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
