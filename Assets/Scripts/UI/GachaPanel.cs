using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// 소환(가챠) 패널: 영웅소환 / 탈것소환 / 스킬소환 서브탭
/// MainHUD 소환 탭에서 Init(parent, showConfirm)으로 초기화
/// </summary>
public class GachaPanel : MonoBehaviour
{
    const int SKILL_PULL_COST = 1; // 주문서 1개
    const float AD_INITIAL_HIDE_SEC = 1800f; // 세션 시작 후 30분간 무료 버튼 숨김

    TextMeshProUGUI gemText;
    TextMeshProUGUI resultText;
    TextMeshProUGUI skillScrollText;
    TextMeshProUGUI skillResultText;
    Button freeBtn;
    TextMeshProUGUI freeBtnText;
    TextMeshProUGUI pityText;

    RectTransform heroResultRT;
    RectTransform skillResultRT;

    // 서브탭
    GameObject heroSection;
    GameObject mountSection;
    GameObject skillSection;
    MountPanel mountPanel;
    Button heroTabBtn;
    Button mountTabBtn;
    Button skillTabBtn;

    System.Action<string, string, System.Action> showConfirm;

    // 서브탭 뱃지
    readonly GameObject[] gachaTabBadges = new GameObject[3];

    // 10연차 스킵
    bool _multiPullSkip;
    bool _multiPullRunning;

    public void Init(Transform parent, System.Action<string, string, System.Action> showConfirmCallback)
    {
        showConfirm = showConfirmCallback;

        // ── 서브탭 헤더 ──
        BuildSubTabs(parent);

        // ── 영웅 소환 영역 ──
        heroSection = UIHelper.MakeUI("HeroGachaContent", parent);
        var heroRT = heroSection.GetComponent<RectTransform>();
        heroRT.anchorMin = new Vector2(0, 0);
        heroRT.anchorMax = new Vector2(1, 1);
        heroRT.offsetMin = new Vector2(UIConstants.Spacing_Medium, UIConstants.Spacing_Medium);
        heroRT.offsetMax = new Vector2(-UIConstants.Spacing_Medium, -UIConstants.Tab_Height * 1.6f);

        BuildHeroSection(heroSection.transform);

        // ── 탈것 소환 영역 ──
        mountSection = UIHelper.MakeUI("MountSection", parent);
        var mountRT = mountSection.GetComponent<RectTransform>();
        mountRT.anchorMin = new Vector2(0, 0);
        mountRT.anchorMax = new Vector2(1, 1);
        mountRT.offsetMin = new Vector2(UIConstants.Spacing_Medium, UIConstants.Spacing_Medium);
        mountRT.offsetMax = new Vector2(-UIConstants.Spacing_Medium, -UIConstants.Tab_Height * 1.6f);

        mountPanel = mountSection.AddComponent<MountPanel>();
        mountPanel.Init(mountSection.transform, showConfirm);
        mountSection.SetActive(false);

        // ── 스킬 소환 영역 ──
        skillSection = UIHelper.MakeUI("SkillGachaContent", parent);
        var skillRT = skillSection.GetComponent<RectTransform>();
        skillRT.anchorMin = new Vector2(0, 0);
        skillRT.anchorMax = new Vector2(1, 1);
        skillRT.offsetMin = new Vector2(UIConstants.Spacing_Medium, UIConstants.Spacing_Medium);
        skillRT.offsetMax = new Vector2(-UIConstants.Spacing_Medium, -UIConstants.Tab_Height * 1.6f);

        BuildSkillSection(skillSection.transform);
        skillSection.SetActive(false);

        ShowHeroTab();
    }

    // ────────────────────────────────────────
    // 서브탭 바 (3탭)
    // ────────────────────────────────────────

    void BuildSubTabs(Transform parent)
    {
        var bar = UIHelper.MakeUI("SubTabBar", parent);
        var barRT = bar.GetComponent<RectTransform>();
        barRT.anchorMin = new Vector2(0f, 0.90f);
        barRT.anchorMax = new Vector2(1f, 0.98f);
        barRT.offsetMin = barRT.offsetMax = Vector2.zero;

        string[] labels = { "영웅 소환", "탈것", "스킬" };
        Sprite[] gachaTabIcons = { UISprites.IconDiamond, UISprites.SpumIcon(136), UISprites.IconSkill };
        Button[] buttons = new Button[3];

        for (int i = 0; i < 3; i++)
        {
            float xMin = i * (1f / 3f) + 0.01f;
            float xMax = (i + 1) * (1f / 3f) - 0.01f;
            var (btn, _) = UIHelper.MakeSpriteButton($"GachaTab_{i}", bar.transform,
                UISprites.Btn1_WS, UIColors.Panel_Inner, "", UIConstants.Font_SmallInfo);
            var brt = btn.GetComponent<RectTransform>();
            brt.anchorMin = new Vector2(xMin, 0.05f);
            brt.anchorMax = new Vector2(xMax, 0.95f);
            brt.offsetMin = brt.offsetMax = Vector2.zero;

            var gachaIcon = UIHelper.MakeIcon("TabIcon", btn.transform, gachaTabIcons[i], Color.white);
            var gicRT = gachaIcon.GetComponent<RectTransform>();
            gicRT.anchorMin = new Vector2(0.03f, 0.1f);
            gicRT.anchorMax = new Vector2(0.27f, 0.9f);
            gicRT.offsetMin = gicRT.offsetMax = Vector2.zero;

            var tabLabel = UIHelper.MakeText("Label", btn.transform, labels[i],
                UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, UIColors.Text_Secondary);
            var tlRT = tabLabel.GetComponent<RectTransform>();
            tlRT.anchorMin = new Vector2(0.27f, 0f);
            tlRT.anchorMax = new Vector2(1f, 1f);
            tlRT.offsetMin = tlRT.offsetMax = Vector2.zero;

            buttons[i] = btn;
        }

        heroTabBtn  = buttons[0];
        mountTabBtn = buttons[1];
        skillTabBtn = buttons[2];

        heroTabBtn.onClick.AddListener(ShowHeroTab);
        mountTabBtn.onClick.AddListener(ShowMountTab);
        skillTabBtn.onClick.AddListener(ShowSkillTab);

        // 뱃지 점
        for (int i = 0; i < 3; i++)
        {
            var badge = UIHelper.MakeUI($"GachaBadge_{i}", buttons[i].transform);
            var badgeImg = badge.AddComponent<Image>();
            badgeImg.color = UIColors.Badge_Red;
            var badgeRT = badge.GetComponent<RectTransform>();
            badgeRT.anchorMin = new Vector2(1f, 1f);
            badgeRT.anchorMax = new Vector2(1f, 1f);
            badgeRT.pivot     = new Vector2(1f, 1f);
            badgeRT.anchoredPosition = new Vector2(-2f, -2f);
            badgeRT.sizeDelta = new Vector2(10f, 10f);
            badge.SetActive(false);
            gachaTabBadges[i] = badge;
        }
    }

    void RefreshGachaTabBadges()
    {
        var nbs = NotificationBadgeSystem.Instance;
        if (nbs == null) return;
        for (int i = 0; i < 3; i++)
        {
            if (gachaTabBadges[i] != null)
                gachaTabBadges[i].SetActive(nbs.GetGachaSubTabBadge(i));
        }
    }

    void ShowHeroTab()
    {
        SoundManager.Instance?.PlayButtonSFX();
        heroSection?.SetActive(true);
        mountSection?.SetActive(false);
        skillSection?.SetActive(false);
        SetSubTabActive(heroTabBtn,  true);
        SetSubTabActive(mountTabBtn, false);
        SetSubTabActive(skillTabBtn, false);
        RefreshPityText();
        RefreshGachaTabBadges();
    }

    void ShowMountTab()
    {
        SoundManager.Instance?.PlayButtonSFX();
        heroSection?.SetActive(false);
        mountSection?.SetActive(true);
        skillSection?.SetActive(false);
        SetSubTabActive(heroTabBtn,  false);
        SetSubTabActive(mountTabBtn, true);
        SetSubTabActive(skillTabBtn, false);
        mountPanel?.Refresh();
        RefreshGachaTabBadges();
    }

    void ShowSkillTab()
    {
        SoundManager.Instance?.PlayButtonSFX();
        heroSection?.SetActive(false);
        mountSection?.SetActive(false);
        skillSection?.SetActive(true);
        SetSubTabActive(heroTabBtn,  false);
        SetSubTabActive(mountTabBtn, false);
        SetSubTabActive(skillTabBtn, true);
        RefreshSkillScrollText();
        RefreshGachaTabBadges();
    }

    static void SetSubTabActive(Button btn, bool active)
    {
        if (btn == null) return;
        var img = btn.GetComponent<UnityEngine.UI.Image>();
        if (img != null) img.color = active ? UIColors.Button_Brown : UIColors.Panel_Inner;
        var txt = btn.GetComponentInChildren<TextMeshProUGUI>();
        if (txt != null) txt.color = active ? Color.white : UIColors.Text_Secondary;
    }

    // ────────────────────────────────────────
    // 영웅 소환 UI
    // ────────────────────────────────────────

    void BuildHeroSection(Transform parent)
    {
        // 보석 보유량
        var gemContainer = UIHelper.MakeSpritePanel("GemContainer", parent,
            UISprites.BoxIcon1, UIColors.Panel_Inner);
        var gcrt = gemContainer.GetComponent<RectTransform>();
        gcrt.anchorMin = new Vector2(0.2f, 0.86f);
        gcrt.anchorMax = new Vector2(0.8f, 0.98f);
        gcrt.offsetMin = gcrt.offsetMax = Vector2.zero;

        gemText = UIHelper.MakeText("GemInfo", gemContainer.transform, "보석: 0",
            UIConstants.Font_StatLabel, TextAlignmentOptions.Center, UIColors.Text_Diamond);
        gemText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(gemText);
        UIHelper.FillParent(gemText.GetComponent<RectTransform>());

        // 1회 소환 버튼
        var (singleBtn, _) = UIHelper.MakeSpriteButton("SinglePull", parent,
            UISprites.Btn2_WS, UIColors.Button_Green, "", UIConstants.Font_Button);
        singleBtn.onClick.AddListener(OnSinglePull);
        var sbrt = singleBtn.GetComponent<RectTransform>();
        sbrt.anchorMin = new Vector2(0.05f, 0.72f);
        sbrt.anchorMax = new Vector2(0.47f, 0.86f);
        sbrt.offsetMin = sbrt.offsetMax = Vector2.zero;
        var sText = UIHelper.MakeText("Label", singleBtn.transform,
            $"1회 소환\n{GachaManager.SINGLE_PULL_COST} 보석",
            11f, TextAlignmentOptions.Center, Color.white);
        sText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(sText);
        UIHelper.FillParent(sText.GetComponent<RectTransform>());

        // 10연 소환 버튼
        var (multiBtn, _2) = UIHelper.MakeSpriteButton("MultiPull", parent,
            UISprites.Btn3_WS, UIColors.Button_Yellow, "", UIConstants.Font_Button);
        multiBtn.onClick.AddListener(OnMultiPull);
        var mbrt = multiBtn.GetComponent<RectTransform>();
        mbrt.anchorMin = new Vector2(0.53f, 0.72f);
        mbrt.anchorMax = new Vector2(0.95f, 0.86f);
        mbrt.offsetMin = mbrt.offsetMax = Vector2.zero;
        var mText = UIHelper.MakeText("Label", multiBtn.transform,
            $"10연차\n{GachaManager.MULTI_PULL_COST} 보석",
            11f, TextAlignmentOptions.Center, new Color(0.20f, 0.12f, 0.05f));
        mText.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(mText.GetComponent<RectTransform>());

        // 100연 소환 버튼 (할인 강조)
        var (hundredBtn, _h) = UIHelper.MakeSpriteButton("HundredPull", parent,
            UISprites.Btn3_WS, new Color(0.85f, 0.15f, 0.10f), "", UIConstants.Font_Button);
        hundredBtn.onClick.AddListener(OnHundredPull);
        var hbrt = hundredBtn.GetComponent<RectTransform>();
        hbrt.anchorMin = new Vector2(0.05f, 0.56f);
        hbrt.anchorMax = new Vector2(0.95f, 0.70f);
        hbrt.offsetMin = hbrt.offsetMax = Vector2.zero;
        var hText = UIHelper.MakeText("Label", hundredBtn.transform,
            $"100연차  {GachaManager.HUNDRED_PULL_COST} 보석  (<s>4500</s> → 할인!)",
            10f, TextAlignmentOptions.Center, Color.white);
        hText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(hText);
        UIHelper.FillParent(hText.GetComponent<RectTransform>());

        // 천장 정보 표시
        pityText = UIHelper.MakeText("PityInfo", parent, "천장까지 0회",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, new Color(1f, 0.84f, 0f, 1f));
        pityText.fontStyle = FontStyles.Bold;
        var pityRT = pityText.GetComponent<RectTransform>();
        pityRT.anchorMin = new Vector2(0.05f, 0.50f);
        pityRT.anchorMax = new Vector2(0.95f, 0.56f);
        pityRT.offsetMin = pityRT.offsetMax = Vector2.zero;
        UIHelper.AddTextShadow(pityText);

        // 확률 정보 버튼
        var (probBtn, _3) = UIHelper.MakeSpriteButton("ProbInfoBtn", parent,
            UISprites.Btn1_WS, UIColors.Button_Brown, "", UIConstants.Font_SmallInfo);
        probBtn.onClick.AddListener(ShowProbabilityInfo);
        var pbrt = probBtn.GetComponent<RectTransform>();
        pbrt.anchorMin = new Vector2(0.52f, 0.41f);
        pbrt.anchorMax = new Vector2(0.95f, 0.50f);
        pbrt.offsetMin = pbrt.offsetMax = Vector2.zero;
        var probLabel = UIHelper.MakeText("Label", probBtn.transform, "확률 정보",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, UIColors.Text_Secondary);
        UIHelper.FillParent(probLabel.GetComponent<RectTransform>());

        // 무료 소환 (광고) 버튼
        var (freePullBtn, _4) = UIHelper.MakeSpriteButton("FreePull", parent,
            UISprites.Btn1_WS, UIColors.Button_Blue, "", UIConstants.Font_SmallInfo);
        freePullBtn.onClick.AddListener(OnFreePull);
        freeBtn = freePullBtn;
        var fbrt = freePullBtn.GetComponent<RectTransform>();
        fbrt.anchorMin = new Vector2(0.05f, 0.41f);
        fbrt.anchorMax = new Vector2(0.48f, 0.50f);
        fbrt.offsetMin = fbrt.offsetMax = Vector2.zero;
        freeBtnText = UIHelper.MakeText("Label", freePullBtn.transform, "무료 보상",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, Color.white);
        UIHelper.FillParent(freeBtnText.GetComponent<RectTransform>());

        // 결과 표시
        var resultBg = UIHelper.MakeSpritePanel("ResultBG", parent,
            UISprites.BoxIcon1, new Color(0.30f, 0.22f, 0.15f, 0.7f));
        heroResultRT = resultBg.GetComponent<RectTransform>();
        heroResultRT.anchorMin = new Vector2(0.05f, 0.02f);
        heroResultRT.anchorMax = new Vector2(0.95f, 0.40f);
        heroResultRT.offsetMin = heroResultRT.offsetMax = Vector2.zero;

        resultText = UIHelper.MakeText("Result", resultBg.transform, "",
            10f, TextAlignmentOptions.Center, Color.white);
        UIHelper.AddTextShadow(resultText);
        UIHelper.FillParent(resultText.GetComponent<RectTransform>());

        // 탭하면 연차 애니메이션 스킵
        var skipBtn = resultBg.gameObject.AddComponent<Button>();
        skipBtn.transition = Selectable.Transition.None;
        skipBtn.onClick.AddListener(() => _multiPullSkip = true);
    }

    // ────────────────────────────────────────
    // 스킬 소환 UI
    // ────────────────────────────────────────

    void BuildSkillSection(Transform parent)
    {
        // 주문서 보유량
        var scrollContainer = UIHelper.MakeSpritePanel("ScrollContainer", parent,
            UISprites.BoxIcon1, UIColors.Panel_Inner);
        var scrt = scrollContainer.GetComponent<RectTransform>();
        scrt.anchorMin = new Vector2(0.2f, 0.86f);
        scrt.anchorMax = new Vector2(0.8f, 0.98f);
        scrt.offsetMin = scrt.offsetMax = Vector2.zero;

        skillScrollText = UIHelper.MakeText("ScrollInfo", scrollContainer.transform, "주문서: 0",
            UIConstants.Font_StatLabel, TextAlignmentOptions.Center, new Color(0.88f, 0.68f, 1.00f));
        skillScrollText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(skillScrollText);
        UIHelper.FillParent(skillScrollText.GetComponent<RectTransform>());

        // 스킬 소환 버튼 (주문서 1개)
        var (pullBtn, _) = UIHelper.MakeSpriteButton("SkillPull", parent,
            UISprites.Btn2_WS, UIColors.Button_Green, "", UIConstants.Font_Button);
        pullBtn.onClick.AddListener(OnSkillPull);
        var pbrt = pullBtn.GetComponent<RectTransform>();
        pbrt.anchorMin = new Vector2(0.15f, 0.55f);
        pbrt.anchorMax = new Vector2(0.85f, 0.82f);
        pbrt.offsetMin = pbrt.offsetMax = Vector2.zero;
        var pText = UIHelper.MakeText("Label", pullBtn.transform,
            $"스킬 소환\n주문서 {SKILL_PULL_COST}개",
            11f, TextAlignmentOptions.Center, Color.white);
        pText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(pText);
        UIHelper.FillParent(pText.GetComponent<RectTransform>());

        // 확률 정보
        var (infoBtn, _2) = UIHelper.MakeSpriteButton("SkillProbBtn", parent,
            UISprites.Btn1_WS, UIColors.Button_Brown, "", UIConstants.Font_SmallInfo);
        infoBtn.onClick.AddListener(ShowSkillProbInfo);
        var ibrt = infoBtn.GetComponent<RectTransform>();
        ibrt.anchorMin = new Vector2(0.25f, 0.46f);
        ibrt.anchorMax = new Vector2(0.75f, 0.54f);
        ibrt.offsetMin = ibrt.offsetMax = Vector2.zero;
        var infoLabel = UIHelper.MakeText("Label", infoBtn.transform, "스킬 확률 보기",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, UIColors.Text_Secondary);
        UIHelper.FillParent(infoLabel.GetComponent<RectTransform>());

        // 결과 표시
        var resultBg = UIHelper.MakeSpritePanel("SkillResultBG", parent,
            UISprites.BoxBasic3, new Color(0.15f, 0.10f, 0.30f, 0.7f));
        skillResultRT = resultBg.GetComponent<RectTransform>();
        skillResultRT.anchorMin = new Vector2(0.05f, 0.02f);
        skillResultRT.anchorMax = new Vector2(0.95f, 0.42f);
        skillResultRT.offsetMin = skillResultRT.offsetMax = Vector2.zero;

        skillResultText = UIHelper.MakeText("SkillResult", resultBg.transform, "",
            10f, TextAlignmentOptions.Center, Color.white);
        UIHelper.AddTextShadow(skillResultText);
        UIHelper.FillParent(skillResultText.GetComponent<RectTransform>());
    }

    void RefreshSkillScrollText()
    {
        if (skillScrollText == null) return;
        int scrolls = SpellScrollManager.Instance != null ? SpellScrollManager.Instance.Scroll : 0;
        skillScrollText.text = $"주문서: {scrolls}";
    }

    void RefreshPityText()
    {
        if (pityText == null) return;
        var gm = GachaManager.Instance;
        if (gm == null)
        {
            pityText.text = "천장까지 0회";
            return;
        }
        int remaining = gm.PityRemaining;
        pityText.text = remaining > 0 ? $"천장까지 {remaining}회" : "천장 달성!";
    }

    // ────────────────────────────────────────
    // 갱신
    // ────────────────────────────────────────

    public void Refresh()
    {
        if (gemText != null && GemManager.Instance != null)
            gemText.text = $"보석: {GemManager.Instance.Gem}";
        mountPanel?.Refresh();
        RefreshSkillScrollText();
        RefreshPityText();
    }

    // ────────────────────────────────────────
    // 영웅 소환 액션
    // ────────────────────────────────────────

    void OnSinglePull()
    {
        if (GachaManager.Instance == null) return;
        int cost = GachaManager.SINGLE_PULL_COST;
        if (GemManager.Instance != null && GemManager.Instance.Gem < cost)
        {
            ToastNotification.Instance?.Show("보석 부족!", $"{cost}보석 필요 — 던전에서 획득하세요", UIColors.Defeat_Red);
            MainHUD.Instance?.SwitchToTab(3);
            return;
        }
        showConfirm?.Invoke("소환 확인", $"보석 {cost}개를 사용합니다.\n진행하시겠습니까?", () =>
        {
            DoSinglePull();
            RefreshPityText();
        });
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
                isDuplicate = count > 1 || (count == 1 &&
                    HeroLevelManager.Instance != null &&
                    HeroLevelManager.Instance.GetCopies(hero.characterName) > 0);
            }

            if (resultText != null)
            {
                string hexColor = UnityEngine.ColorUtility.ToHtmlStringRGB(GetRarityColor(hero.starGrade));
                string starLabel = GetStarLabel(hero.starGrade);
                if (isDuplicate)
                    resultText.text = $"<color=#{hexColor}>[{starLabel}] {hero.characterName}</color>\n중복 → 각성 재료 +1";
                else
                    resultText.text = $"<color=#7FD44C>NEW!</color> <color=#{hexColor}>[{starLabel}] {hero.characterName}</color> 획득!";
            }
            if (heroResultRT != null)
            {
                SoundManager.Instance?.PlayUISound(UISoundType.gacha_reveal);
                StartCoroutine(CardFlip(heroResultRT, GetRarityColor(hero.starGrade)));
            }
        }
        else
        {
            if (resultText != null)
                resultText.text = "<color=#CC3333>보석이 부족합니다</color>";
        }
        Refresh();
    }

    void OnMultiPull()
    {
        if (GachaManager.Instance == null) return;
        int cost = GachaManager.MULTI_PULL_COST;
        if (GemManager.Instance != null && GemManager.Instance.Gem < cost)
        {
            ToastNotification.Instance?.Show("보석 부족!", $"{cost}보석 필요 — 던전에서 획득하세요", UIColors.Defeat_Red);
            MainHUD.Instance?.SwitchToTab(3);
            return;
        }
        showConfirm?.Invoke("10연 소환 확인", $"보석 {cost}개를 사용합니다.\n진행하시겠습니까?", () =>
        {
            DoMultiPull();
            RefreshPityText();
        });
    }

    void DoMultiPull()
    {
        if (GachaManager.Instance == null) return;
        var results = GachaManager.Instance.MultiPull();
        if (results != null)
        {
            SoundManager.Instance?.PlayUISound(UISoundType.gacha_reveal);
            StartCoroutine(ShowMultiResults(results));
        }
        else
        {
            if (resultText != null)
                resultText.text = "<color=#CC3333>보석이 부족합니다</color>";
        }
        Refresh();
    }

    void Update()
    {
        if (_multiPullRunning && Input.GetMouseButtonDown(0))
            _multiPullSkip = true;
    }

    IEnumerator ShowMultiResults(CharacterPreset[] results)
    {
        _multiPullSkip = false;
        _multiPullRunning = true;
        if (resultText == null || heroResultRT == null) { _multiPullRunning = false; yield break; }
        resultText.text = "";

        // 전체 결과 문자열 미리 생성 (스킵용)
        var allSb = new System.Text.StringBuilder();
        for (int k = 0; k < results.Length; k++)
        {
            if (results[k] == null) continue;
            string hexK = UnityEngine.ColorUtility.ToHtmlStringRGB(GetRarityColor(results[k].starGrade));
            allSb.Append($"<color=#{hexK}>{results[k].characterName}</color>  ");
        }

        var sb = new System.Text.StringBuilder();
        for (int i = 0; i < results.Length; i++)
        {
            if (results[i] == null) continue;

            // 스킵: 즉시 전부 표시
            if (_multiPullSkip)
            {
                resultText.text = allSb.ToString().TrimEnd();
                heroResultRT.localScale = Vector3.one;
                yield break;
            }

            string hex = UnityEngine.ColorUtility.ToHtmlStringRGB(GetRarityColor(results[i].starGrade));
            sb.Append($"<color=#{hex}>{results[i].characterName}</color>  ");
            resultText.text = sb.ToString().TrimEnd();

            // 카드 뒤집기: scaleX 1→0→1
            SoundManager.Instance?.PlayUISound(UISoundType.gacha_reveal);
            float t = 0;
            while (t < 0.08f && !_multiPullSkip)
            {
                t += Time.unscaledDeltaTime;
                heroResultRT.localScale = new Vector3(Mathf.Lerp(1f, 0f, t / 0.08f), 1f, 1f);
                yield return null;
            }
            var img = heroResultRT.GetComponent<Image>();
            if (img != null)
            {
                Color rc = GetRarityColor(results[i].starGrade);
                img.color = new Color(rc.r * 0.4f, rc.g * 0.4f, rc.b * 0.4f, 0.85f);
            }
            t = 0;
            while (t < 0.1f && !_multiPullSkip)
            {
                t += Time.unscaledDeltaTime;
                heroResultRT.localScale = new Vector3(Mathf.Lerp(0f, 1f, t / 0.1f), 1f, 1f);
                yield return null;
            }
            heroResultRT.localScale = Vector3.one;

            if (!_multiPullSkip)
                yield return new WaitForSecondsRealtime(0.2f);
        }
        _multiPullRunning = false;
    }

    void OnHundredPull()
    {
        if (GachaManager.Instance == null) return;
        int cost = GachaManager.HUNDRED_PULL_COST;
        if (GemManager.Instance != null && GemManager.Instance.Gem < cost)
        {
            ToastNotification.Instance?.Show("보석 부족!", $"{cost}보석 필요", UIColors.Defeat_Red);
            MainHUD.Instance?.SwitchToTab(3);
            return;
        }
        showConfirm?.Invoke("100연 소환 확인", $"보석 {cost}개를 사용합니다.\n(4500→4000 할인 적용)\n진행하시겠습니까?", () =>
        {
            var results = GachaManager.Instance?.HundredPull();
            if (results != null)
                StartCoroutine(ShowHundredResults(results));
            else if (resultText != null)
                resultText.text = "<color=#CC3333>보석이 부족합니다</color>";
            Refresh();
            RefreshPityText();
        });
    }

    IEnumerator ShowHundredResults(CharacterPreset[] results)
    {
        _multiPullSkip = false;
        _multiPullRunning = true;
        if (resultText == null || heroResultRT == null) { _multiPullRunning = false; yield break; }

        // 성급별 집계
        int[] counts = new int[6]; // index = StarGrade int (1~5)
        for (int i = 0; i < results.Length; i++)
            if (results[i] != null) counts[(int)results[i].starGrade]++;

        // 요약 결과 문자열
        string summary = BuildHundredSummary(counts);

        // 스킵 없이 바로 표시하되, 짧은 연출 후 공개
        resultText.text = "";
        heroResultRT.localScale = Vector3.one;

        // 1초 동안 카운팅 연출 (스킵 가능)
        float elapsed = 0f;
        while (elapsed < 1.0f && !_multiPullSkip)
        {
            elapsed += Time.unscaledDeltaTime;
            resultText.text = $"집계 중... ({Mathf.FloorToInt(elapsed / 1.0f * 100)}%)";
            yield return null;
        }

        resultText.text = summary;
        _multiPullRunning = false;
    }

    static string BuildHundredSummary(int[] counts)
    {
        var sb = new System.Text.StringBuilder();
        sb.AppendLine("<size=13><b>── 100연 소환 결과 ──</b></size>");
        if (counts[5] > 0) sb.AppendLine($"<color=#FFD700>★★★★★  {counts[5]}개</color>");
        if (counts[4] > 0) sb.AppendLine($"<color=#FF8C00>★★★★☆  {counts[4]}개</color>");
        if (counts[3] > 0) sb.AppendLine($"<color=#9B59B6>★★★☆☆  {counts[3]}개</color>");
        if (counts[2] > 0) sb.AppendLine($"<color=#3498DB>★★☆☆☆  {counts[2]}개</color>");
        if (counts[1] > 0) sb.AppendLine($"<color=#AAAAAA>★☆☆☆☆  {counts[1]}개</color>");
        return sb.ToString().TrimEnd();
    }

    void OnFreePull()
    {
        if (GachaManager.Instance == null) return;

        // 광고 가능 여부 체크
        if (AdManager.Instance != null && !AdManager.Instance.IsAdAvailable(AdManager.AdRewardType.FreeSummonHero))
        {
            string cooldownText = AdManager.Instance.GetCooldownText(AdManager.AdRewardType.FreeSummonHero);
            ToastNotification.Instance?.Show("무료 소환 재시도", cooldownText, UIColors.Text_Gold);
            return;
        }

        // 광고 시청
        if (AdManager.Instance != null)
        {
            AdManager.Instance.ShowRewardedAd(
                AdManager.AdRewardType.FreeSummonHero,
                () => DoFreePull()
            );
        }
    }

    void DoFreePull()
    {
        if (GachaManager.Instance == null) return;
        var hero = GachaManager.Instance.FreeSinglePull();
        if (hero != null)
        {
            bool isDuplicate = false;
            var dm = DeckManager.Instance;
            if (dm != null)
            {
                int count = 0;
                for (int i = 0; i < dm.roster.Count; i++)
                    if (dm.roster[i] == hero) count++;
                isDuplicate = count > 1 || (count == 1 &&
                    HeroLevelManager.Instance != null &&
                    HeroLevelManager.Instance.GetCopies(hero.characterName) > 0);
            }

            if (resultText != null)
            {
                string hexColor = UnityEngine.ColorUtility.ToHtmlStringRGB(GetRarityColor(hero.starGrade));
                string starLabel = GetStarLabel(hero.starGrade);
                if (isDuplicate)
                    resultText.text = $"<color=#{hexColor}>[{starLabel}] {hero.characterName}</color>\n중복 → 각성 재료 +1";
                else
                    resultText.text = $"<color=#7FD44C>NEW!</color> <color=#{hexColor}>[{starLabel}] {hero.characterName}</color> 획득!";
            }
            ToastNotification.Instance?.Show("무료 소환!", $"{hero.characterName} 획득", GetRarityColor(hero.starGrade));
        }
        else
        {
            ToastNotification.Instance?.Show("무료 소환 실패", "영웅 풀이 비어있습니다", UIColors.Defeat_Red);
        }
        RefreshFreePullButton();
        Refresh();
    }

    void RefreshFreePullButton()
    {
        if (freeBtn == null || freeBtnText == null) return;

        // 세션 시작 후 30분간 숨김
        if (UnityEngine.Time.realtimeSinceStartup < AD_INITIAL_HIDE_SEC)
        {
            freeBtn.gameObject.SetActive(false);
            return;
        }
        freeBtn.gameObject.SetActive(true);

        if (AdManager.Instance != null && AdManager.Instance.IsAdAvailable(AdManager.AdRewardType.FreeSummonHero))
        {
            freeBtn.interactable = true;
            freeBtnText.text = "무료 보상";
            freeBtnText.color = Color.white;
        }
        else if (AdManager.Instance != null)
        {
            freeBtn.interactable = false;
            freeBtnText.text = AdManager.Instance.GetCooldownText(AdManager.AdRewardType.FreeSummonHero);
            freeBtnText.color = UIColors.Text_Secondary;
        }
    }

    // ────────────────────────────────────────
    // 스킬 소환 액션
    // ────────────────────────────────────────

    void OnSkillPull()
    {
        var sm = SpellScrollManager.Instance;
        if (sm == null || sm.Scroll < SKILL_PULL_COST)
        {
            ToastNotification.Instance?.Show("주문서 부족!", $"주문서 {SKILL_PULL_COST}개 필요", UIColors.Defeat_Red);
            return;
        }
        showConfirm?.Invoke("스킬 소환", $"주문서 {SKILL_PULL_COST}개를 사용합니다.\n진행하시겠습니까?", DoSkillPull);
    }

    void DoSkillPull()
    {
        var sm = SpellScrollManager.Instance;
        if (sm == null || !sm.SpendScroll(SKILL_PULL_COST)) return;

        var allSkills = Resources.LoadAll<SkillData>("Skills");
        if (allSkills == null || allSkills.Length == 0)
        {
            if (skillResultText != null)
                skillResultText.text = "<color=#CC3333>스킬 데이터 없음</color>";
            RefreshSkillScrollText();
            return;
        }

        var skill = allSkills[Random.Range(0, allSkills.Length)];
        string hex = UnityEngine.ColorUtility.ToHtmlStringRGB(GetRarityColor(skill.starGrade));
        string starLabel = GetStarLabel(skill.starGrade);
        if (skillResultText != null)
            skillResultText.text = $"<color=#{hex}>[{starLabel}]</color> {skill.iconChar} <color=#{hex}>{skill.skillName}</color> 획득!";

        if (skillResultRT != null)
        {
            SoundManager.Instance?.PlayUISound(UISoundType.gacha_reveal);
            StartCoroutine(CardFlip(skillResultRT, GetRarityColor(skill.starGrade)));
        }

        ToastNotification.Instance?.Show("스킬 소환!", $"{skill.skillName} 획득", GetRarityColor(skill.starGrade));
        RefreshSkillScrollText();
    }

    void ShowProbabilityInfo()
    {
        var sb = new System.Text.StringBuilder();
        sb.AppendLine("<b>영웅 소환 확률</b>");
        sb.AppendLine("★1 (일반) : 60.00%");
        sb.AppendLine("★2 (고급) : 30.00%");
        sb.AppendLine("★3 (희귀) :  9.00%");
        sb.AppendLine("★4 (영웅) :  0.97%");
        sb.AppendLine("★5 (전설) :  0.03%");
        ToastNotification.Instance?.Show("소환 확률", sb.ToString().Trim(), UIColors.Text_Gold);
    }

    void ShowSkillProbInfo()
    {
        ToastNotification.Instance?.Show("스킬 소환 확률", "보유 스킬 중 무작위 획득\n(주문서 1개 소모)", UIColors.Text_Gold);
    }

    // ────────────────────────────────────────
    // 색상/레이블 헬퍼
    // ────────────────────────────────────────

    static Color GetRarityColor(StarGrade grade) => grade switch
    {
        StarGrade.Star5 => UIColors.Rarity_Legendary,
        StarGrade.Star4 => UIColors.Rarity_Epic,
        StarGrade.Star3 => UIColors.Rarity_Rare,
        StarGrade.Star2 => UIColors.Rarity_Uncommon,
        _               => UIColors.Rarity_Common,
    };

    static string GetStarLabel(StarGrade grade) => grade switch
    {
        StarGrade.Star5 => "★★★★★",
        StarGrade.Star4 => "★★★★",
        StarGrade.Star3 => "★★★",
        StarGrade.Star2 => "★★",
        _               => "★",
    };

    void OnDestroy()
    {
        if (heroTabBtn != null) heroTabBtn.onClick.RemoveListener(ShowHeroTab);
        if (mountTabBtn != null) mountTabBtn.onClick.RemoveListener(ShowMountTab);
        if (skillTabBtn != null) skillTabBtn.onClick.RemoveListener(ShowSkillTab);
        if (freeBtn != null) freeBtn.onClick.RemoveListener(OnFreePull);
    }

    // ════════════════════════════════════════
    // 카드 뒤집기 연출
    // ════════════════════════════════════════

    System.Collections.IEnumerator CardFlip(RectTransform rt, Color glowColor)
    {
        // Scale X: 1 → 0 (카드 뒤집는 중, 0.15초)
        float t = 0;
        Vector3 orig = rt.localScale;
        while (t < 0.15f)
        {
            t += Time.unscaledDeltaTime;
            float s = Mathf.Lerp(1f, 0f, t / 0.15f);
            rt.localScale = new Vector3(s, orig.y, orig.z);
            yield return null;
        }

        // 배경색 변경 (성급 색 적용)
        var img = rt.GetComponent<Image>();
        if (img != null) img.color = new Color(glowColor.r * 0.4f, glowColor.g * 0.4f, glowColor.b * 0.4f, 0.85f);

        // Scale X: 0 → 1 (카드 앞면, 0.15초) — 총 0.3초
        t = 0;
        while (t < 0.15f)
        {
            t += Time.unscaledDeltaTime;
            float s = Mathf.Lerp(0f, 1f, t / 0.15f);
            rt.localScale = new Vector3(s, orig.y, orig.z);
            yield return null;
        }
        rt.localScale = orig;

        // 글로우 펄스
        if (img != null)
        {
            t = 0;
            Color baseColor = img.color;
            while (t < 0.4f)
            {
                t += Time.unscaledDeltaTime;
                float pulse = Mathf.Sin(t * Mathf.PI * 5f) * 0.15f;
                img.color = new Color(
                    Mathf.Clamp01(baseColor.r + pulse),
                    Mathf.Clamp01(baseColor.g + pulse),
                    Mathf.Clamp01(baseColor.b + pulse),
                    baseColor.a
                );
                yield return null;
            }
            img.color = baseColor;
        }
    }
}
