using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections.Generic;

/// <summary>
/// 소환(가챠) 패널: 1회/10연 소환 버튼 + 결과 표시
/// MainHUD 소환 탭에서 Init(parent, showConfirm)으로 초기화
/// </summary>
public class GachaPanel : MonoBehaviour
{
    TextMeshProUGUI gemText;
    TextMeshProUGUI resultText;

    // 서브탭
    GameObject heroSection;
    GameObject mountSection;
    MountPanel mountPanel;
    Button heroTabBtn;
    Button mountTabBtn;

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

        var content = heroSection;
        var contentRT = heroRT;

        // 보석 보유량 표시
        var gemContainer = UIHelper.MakeSpritePanel("GemContainer", content.transform,
            UISprites.BoxIcon1, UIColors.Panel_Inner);
        var gcrt = gemContainer.GetComponent<RectTransform>();
        gcrt.anchorMin = new Vector2(0.2f, 0.86f);
        gcrt.anchorMax = new Vector2(0.8f, 0.98f);
        gcrt.offsetMin = Vector2.zero;
        gcrt.offsetMax = Vector2.zero;

        if (UISprites.IconDiamond != null)
        {
            var gemIcon = UIHelper.MakeIcon("GemIcon", gemContainer.transform, UISprites.IconDiamond, UIColors.Text_Diamond);
            var girt = gemIcon.GetComponent<RectTransform>();
            girt.anchorMin = new Vector2(0.05f, 0.1f);
            girt.anchorMax = new Vector2(0.05f, 0.9f);
            girt.pivot = new Vector2(0, 0.5f);
            girt.sizeDelta = new Vector2(18, 0);
        }

        gemText = UIHelper.MakeText("GemInfo", gemContainer.transform, "보석: 0",
            UIConstants.Font_StatLabel, TextAlignmentOptions.Center, UIColors.Text_Diamond);
        gemText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(gemText);
        UIHelper.FillParent(gemText.GetComponent<RectTransform>());

        // 1회 소환 버튼
        var (singleBtn, _) = UIHelper.MakeSpriteButton("SinglePull", content.transform,
            UISprites.Btn2_WS, UIColors.Button_Green, "", UIConstants.Font_Button);
        singleBtn.onClick.AddListener(OnSinglePull);
        var sbrt = singleBtn.GetComponent<RectTransform>();
        sbrt.anchorMin = new Vector2(0.05f, 0.50f);
        sbrt.anchorMax = new Vector2(0.47f, 0.82f);
        sbrt.offsetMin = Vector2.zero;
        sbrt.offsetMax = Vector2.zero;
        var sText = UIHelper.MakeText("Label", singleBtn.transform,
            $"1회 소환\n{GachaManager.SINGLE_PULL_COST} 보석",
            11f, TextAlignmentOptions.Center, Color.white);
        sText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(sText);
        UIHelper.FillParent(sText.GetComponent<RectTransform>());

        // 10연 소환 버튼
        var (multiBtn, _) = UIHelper.MakeSpriteButton("MultiPull", content.transform,
            UISprites.Btn3_WS, UIColors.Button_Yellow, "", UIConstants.Font_Button);
        multiBtn.onClick.AddListener(OnMultiPull);
        var mbrt = multiBtn.GetComponent<RectTransform>();
        mbrt.anchorMin = new Vector2(0.53f, 0.50f);
        mbrt.anchorMax = new Vector2(0.95f, 0.82f);
        mbrt.offsetMin = Vector2.zero;
        mbrt.offsetMax = Vector2.zero;
        var mText = UIHelper.MakeText("Label", multiBtn.transform,
            $"10연차\n{GachaManager.MULTI_PULL_COST} 보석",
            11f, TextAlignmentOptions.Center, new Color(0.20f, 0.12f, 0.05f));
        mText.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(mText.GetComponent<RectTransform>());

        // 확률 정보 버튼
        var (probBtn, _) = UIHelper.MakeSpriteButton("ProbInfoBtn", content.transform,
            UISprites.Btn1_WS, UIColors.Button_Brown, "", UIConstants.Font_SmallInfo);
        probBtn.onClick.AddListener(ShowProbabilityInfo);
        var pbrt = probBtn.GetComponent<RectTransform>();
        pbrt.anchorMin = new Vector2(0.25f, 0.40f);
        pbrt.anchorMax = new Vector2(0.75f, 0.50f);
        pbrt.offsetMin = Vector2.zero;
        pbrt.offsetMax = Vector2.zero;
        var probLabel = UIHelper.MakeText("Label", probBtn.transform, "확률 정보 보기",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, UIColors.Text_Secondary);
        UIHelper.FillParent(probLabel.GetComponent<RectTransform>());

        // 결과 표시 영역
        var resultBg = UIHelper.MakeSpritePanel("ResultBG", content.transform,
            UISprites.BoxBasic3, new Color(0.30f, 0.22f, 0.15f, 0.7f));
        var rbrt = resultBg.GetComponent<RectTransform>();
        rbrt.anchorMin = new Vector2(0.05f, 0.02f);
        rbrt.anchorMax = new Vector2(0.95f, 0.38f);
        rbrt.offsetMin = Vector2.zero;
        rbrt.offsetMax = Vector2.zero;

        resultText = UIHelper.MakeText("Result", resultBg.transform, "",
            10f, TextAlignmentOptions.Center, Color.white);
        UIHelper.AddTextShadow(resultText);
        UIHelper.FillParent(resultText.GetComponent<RectTransform>());

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

        ShowHeroTab();
    }

    void BuildSubTabs(Transform parent)
    {
        var bar = UIHelper.MakeUI("SubTabBar", parent);
        var barRT = bar.GetComponent<RectTransform>();
        barRT.anchorMin = new Vector2(0, 1f - UIConstants.Tab_Height / 400f);
        barRT.anchorMax = new Vector2(1, 1f);
        // 상단 고정 서브탭 바 (탭 높이 절반)
        barRT.anchorMin = new Vector2(0f, 0.90f);
        barRT.anchorMax = new Vector2(1f, 0.98f);
        barRT.offsetMin = barRT.offsetMax = Vector2.zero;

        // 영웅 소환 탭 버튼
        var (hBtn, _) = UIHelper.MakeSpriteButton("HeroTab", bar.transform,
            UISprites.Btn1_WS, UIColors.Button_Brown, "", UIConstants.Font_SmallInfo);
        var hrt = hBtn.GetComponent<RectTransform>();
        hrt.anchorMin = new Vector2(0.02f, 0.05f);
        hrt.anchorMax = new Vector2(0.49f, 0.95f);
        hrt.offsetMin = hrt.offsetMax = Vector2.zero;
        UIHelper.MakeText("Label", hBtn.transform, "영웅 소환",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, Color.white);
        hBtn.onClick.AddListener(ShowHeroTab);
        heroTabBtn = hBtn;

        // 탈것 탭 버튼
        var (mBtn, _) = UIHelper.MakeSpriteButton("MountTab", bar.transform,
            UISprites.Btn1_WS, UIColors.Panel_Inner, "", UIConstants.Font_SmallInfo);
        var mrt = mBtn.GetComponent<RectTransform>();
        mrt.anchorMin = new Vector2(0.51f, 0.05f);
        mrt.anchorMax = new Vector2(0.98f, 0.95f);
        mrt.offsetMin = mrt.offsetMax = Vector2.zero;
        UIHelper.MakeText("Label", mBtn.transform, "탈것",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, UIColors.Text_Secondary);
        mBtn.onClick.AddListener(ShowMountTab);
        mountTabBtn = mBtn;
    }

    void ShowHeroTab()
    {
        if (heroSection  != null) heroSection.SetActive(true);
        if (mountSection != null) mountSection.SetActive(false);
        SetSubTabActive(heroTabBtn, true);
        SetSubTabActive(mountTabBtn, false);
    }

    void ShowMountTab()
    {
        if (heroSection  != null) heroSection.SetActive(false);
        if (mountSection != null) mountSection.SetActive(true);
        SetSubTabActive(heroTabBtn, false);
        SetSubTabActive(mountTabBtn, true);
        mountPanel?.Refresh();
    }

    static void SetSubTabActive(Button btn, bool active)
    {
        if (btn == null) return;
        var img = btn.GetComponent<UnityEngine.UI.Image>();
        if (img != null) img.color = active ? UIColors.Button_Brown : UIColors.Panel_Inner;
        var txt = btn.GetComponentInChildren<TextMeshProUGUI>();
        if (txt != null) txt.color = active ? Color.white : UIColors.Text_Secondary;
    }

    public void Refresh()
    {
        if (gemText != null && GemManager.Instance != null)
            gemText.text = $"보석: {GemManager.Instance.Gem}";
        mountPanel?.Refresh();
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
                if (isDuplicate)
                    resultText.text = $"<color=#FFD700>{hero.characterName}</color> 중복! 강화 카드 +1";
                else
                    resultText.text = $"<color=#7FD44C>NEW!</color> {hero.characterName} 획득!";
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
            if (resultText != null)
                resultText.text = resultStr.Trim();
        }
        else
        {
            if (resultText != null)
                resultText.text = "<color=#CC3333>보석이 부족합니다</color>";
        }
        Refresh();
    }

    void ShowProbabilityInfo()
    {
        // 확률 표 팝업 (MainHUD의 ShowProbabilityInfo와 동일 로직을 인라인으로 위임)
        // 추후 ProbabilityInfoPanel로 분리 가능
        var sb = new System.Text.StringBuilder();
        sb.AppendLine("<b>소환 확률</b>");
        sb.AppendLine("★1 (일반) : 60.00%");
        sb.AppendLine("★2 (고급) : 30.00%");
        sb.AppendLine("★3 (희귀) :  9.00%");
        sb.AppendLine("★4 (영웅) :  0.97%");
        sb.AppendLine("★5 (전설) :  0.03%");
        ToastNotification.Instance?.Show("소환 확률", sb.ToString().Trim(), UIColors.Text_Gold);
    }
}
