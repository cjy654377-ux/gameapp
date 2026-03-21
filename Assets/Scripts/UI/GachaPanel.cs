using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections.Generic;

/// <summary>
/// 소환(가챠) 패널: 영웅소환 / 탈것소환 / 스킬소환 서브탭
/// MainHUD 소환 탭에서 Init(parent, showConfirm)으로 초기화
/// </summary>
public class GachaPanel : MonoBehaviour
{
    const int SKILL_PULL_COST = 1; // 주문서 1개

    TextMeshProUGUI gemText;
    TextMeshProUGUI resultText;
    TextMeshProUGUI skillScrollText;
    TextMeshProUGUI skillResultText;
    Button freeBtn;
    TextMeshProUGUI freeBtnText;

    // 서브탭
    GameObject heroSection;
    GameObject mountSection;
    GameObject skillSection;
    MountPanel mountPanel;
    Button heroTabBtn;
    Button mountTabBtn;
    Button skillTabBtn;

    System.Action<string, string, System.Action> showConfirm;

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
            UIHelper.MakeText("Label", btn.transform, labels[i],
                UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, UIColors.Text_Secondary);
            buttons[i] = btn;
        }

        heroTabBtn  = buttons[0];
        mountTabBtn = buttons[1];
        skillTabBtn = buttons[2];

        heroTabBtn.onClick.AddListener(ShowHeroTab);
        mountTabBtn.onClick.AddListener(ShowMountTab);
        skillTabBtn.onClick.AddListener(ShowSkillTab);
    }

    void ShowHeroTab()
    {
        heroSection?.SetActive(true);
        mountSection?.SetActive(false);
        skillSection?.SetActive(false);
        SetSubTabActive(heroTabBtn,  true);
        SetSubTabActive(mountTabBtn, false);
        SetSubTabActive(skillTabBtn, false);
    }

    void ShowMountTab()
    {
        heroSection?.SetActive(false);
        mountSection?.SetActive(true);
        skillSection?.SetActive(false);
        SetSubTabActive(heroTabBtn,  false);
        SetSubTabActive(mountTabBtn, true);
        SetSubTabActive(skillTabBtn, false);
        mountPanel?.Refresh();
    }

    void ShowSkillTab()
    {
        heroSection?.SetActive(false);
        mountSection?.SetActive(false);
        skillSection?.SetActive(true);
        SetSubTabActive(heroTabBtn,  false);
        SetSubTabActive(mountTabBtn, false);
        SetSubTabActive(skillTabBtn, true);
        RefreshSkillScrollText();
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
        sbrt.anchorMin = new Vector2(0.05f, 0.50f);
        sbrt.anchorMax = new Vector2(0.47f, 0.82f);
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
        mbrt.anchorMin = new Vector2(0.53f, 0.50f);
        mbrt.anchorMax = new Vector2(0.95f, 0.82f);
        mbrt.offsetMin = mbrt.offsetMax = Vector2.zero;
        var mText = UIHelper.MakeText("Label", multiBtn.transform,
            $"10연차\n{GachaManager.MULTI_PULL_COST} 보석",
            11f, TextAlignmentOptions.Center, new Color(0.20f, 0.12f, 0.05f));
        mText.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(mText.GetComponent<RectTransform>());

        // 확률 정보 버튼
        var (probBtn, _3) = UIHelper.MakeSpriteButton("ProbInfoBtn", parent,
            UISprites.Btn1_WS, UIColors.Button_Brown, "", UIConstants.Font_SmallInfo);
        probBtn.onClick.AddListener(ShowProbabilityInfo);
        var pbrt = probBtn.GetComponent<RectTransform>();
        pbrt.anchorMin = new Vector2(0.25f, 0.40f);
        pbrt.anchorMax = new Vector2(0.75f, 0.50f);
        pbrt.offsetMin = pbrt.offsetMax = Vector2.zero;
        var probLabel = UIHelper.MakeText("Label", probBtn.transform, "확률 정보 보기",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, UIColors.Text_Secondary);
        UIHelper.FillParent(probLabel.GetComponent<RectTransform>());

        // 무료 소환 (광고) 버튼
        var (freePullBtn, _4) = UIHelper.MakeSpriteButton("FreePull", parent,
            UISprites.Btn1_WS, UIColors.Button_Blue, "", UIConstants.Font_SmallInfo);
        freePullBtn.onClick.AddListener(OnFreePull);
        freeBtn = freePullBtn;
        var fbrt = freePullBtn.GetComponent<RectTransform>();
        fbrt.anchorMin = new Vector2(0.05f, 0.30f);
        fbrt.anchorMax = new Vector2(0.95f, 0.38f);
        fbrt.offsetMin = fbrt.offsetMax = Vector2.zero;
        freeBtnText = UIHelper.MakeText("Label", freePullBtn.transform, "무료 소환 (광고)",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, Color.white);
        UIHelper.FillParent(freeBtnText.GetComponent<RectTransform>());

        // 결과 표시
        var resultBg = UIHelper.MakeSpritePanel("ResultBG", parent,
            UISprites.BoxBasic3, new Color(0.30f, 0.22f, 0.15f, 0.7f));
        var rbrt = resultBg.GetComponent<RectTransform>();
        rbrt.anchorMin = new Vector2(0.05f, 0.02f);
        rbrt.anchorMax = new Vector2(0.95f, 0.38f);
        rbrt.offsetMin = rbrt.offsetMax = Vector2.zero;

        resultText = UIHelper.MakeText("Result", resultBg.transform, "",
            10f, TextAlignmentOptions.Center, Color.white);
        UIHelper.AddTextShadow(resultText);
        UIHelper.FillParent(resultText.GetComponent<RectTransform>());
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
        var rbrt = resultBg.GetComponent<RectTransform>();
        rbrt.anchorMin = new Vector2(0.05f, 0.02f);
        rbrt.anchorMax = new Vector2(0.95f, 0.42f);
        rbrt.offsetMin = rbrt.offsetMax = Vector2.zero;

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

    // ────────────────────────────────────────
    // 갱신
    // ────────────────────────────────────────

    public void Refresh()
    {
        if (gemText != null && GemManager.Instance != null)
            gemText.text = $"보석: {GemManager.Instance.Gem}";
        mountPanel?.Refresh();
        RefreshSkillScrollText();
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
            ToastNotification.Instance?.Show("보석 부족!", $"{cost}보석 필요", UIColors.Defeat_Red);
            return;
        }
        showConfirm?.Invoke("소환 확인", $"보석 {cost}개를 사용합니다.\n진행하시겠습니까?", DoSinglePull);
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
            ToastNotification.Instance?.Show("보석 부족!", $"{cost}보석 필요", UIColors.Defeat_Red);
            return;
        }
        showConfirm?.Invoke("10연 소환 확인", $"보석 {cost}개를 사용합니다.\n진행하시겠습니까?", DoMultiPull);
    }

    void DoMultiPull()
    {
        if (GachaManager.Instance == null) return;
        var results = GachaManager.Instance.MultiPull();
        if (results != null)
        {
            var sb = new System.Text.StringBuilder();
            var seen = new System.Collections.Generic.HashSet<string>();
            for (int i = 0; i < results.Length; i++)
            {
                if (results[i] == null) continue;
                string name = results[i].characterName;
                if (!seen.Add(name)) continue;

                string hex = UnityEngine.ColorUtility.ToHtmlStringRGB(GetRarityColor(results[i].starGrade));
                int cnt = 0;
                for (int j = 0; j < results.Length; j++)
                    if (results[j] != null && results[j].characterName == name) cnt++;
                string suffix = cnt > 1 ? $"×{cnt}" : "";
                sb.Append($"<color=#{hex}>{name}</color>{suffix}  ");
            }
            if (resultText != null)
                resultText.text = sb.ToString().TrimEnd();
        }
        else
        {
            if (resultText != null)
                resultText.text = "<color=#CC3333>보석이 부족합니다</color>";
        }
        Refresh();
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
                success =>
                {
                    if (success)
                        DoFreePull();
                }
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

        if (AdManager.Instance != null && AdManager.Instance.IsAdAvailable(AdManager.AdRewardType.FreeSummonHero))
        {
            freeBtn.interactable = true;
            freeBtnText.text = "무료 소환 (광고)";
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
}
