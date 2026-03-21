using UnityEngine;
using UnityEngine.UI;
using TMPro;

/// <summary>
/// 던전 패널: 던전 3종 선택 + 단계 선택 + 입장 버튼
/// MainHUD 던전 탭에서 Init(parent)으로 초기화
/// </summary>
public class DungeonPanel : MonoBehaviour
{
    DungeonType selectedType = DungeonType.Hero;
    int selectedFloor = 1;

    readonly Image[] typeButtonImgs = new Image[3];
    TextMeshProUGUI bestFloorText;
    TextMeshProUGUI remainingText;
    TextMeshProUGUI rewardTypeText;
    TextMeshProUGUI floorValueText;
    Button enterBtn;
    Button adBonusBtn;

    DungeonManager cachedDungeonMgr;

    static readonly string[] TypeNames  = { "영웅 던전", "탈것 던전", "스킬 던전" };
    static readonly string[] TypeRewards = { "보상: 보석", "보상: 소환석", "보상: 주문서" };
    static readonly Color[] TypeColors =
    {
        new Color(0.35f, 0.55f, 0.90f),  // Hero  — 파랑
        new Color(0.60f, 0.40f, 0.20f),  // Mount — 갈색
        new Color(0.55f, 0.25f, 0.75f),  // Skill — 보라
    };

    public void Init(Transform parent)
    {
        var content = UIHelper.MakeUI("DungeonContent", parent);
        var contentRT = content.GetComponent<RectTransform>();
        contentRT.anchorMin = new Vector2(0, 0);
        contentRT.anchorMax = new Vector2(1, 1);
        contentRT.offsetMin = new Vector2(UIConstants.Spacing_Medium, UIConstants.Spacing_Medium);
        contentRT.offsetMax = new Vector2(-UIConstants.Spacing_Medium, -UIConstants.Tab_Height);

        BuildTypeSelector(content.transform);
        BuildInfoPanel(content.transform);
        BuildFloorSelector(content.transform);
        BuildRewardLabel(content.transform);
        BuildEnterButton(content.transform);

        StartCoroutine(DeferredSubscribe());
        UpdateAllUI();
    }

    // ────────────────────────────────────────
    // Build
    // ────────────────────────────────────────

    void BuildTypeSelector(Transform parent)
    {
        float third = 1f / 3;
        for (int i = 0; i < 3; i++)
        {
            int idx = i;
            var (btn, img) = UIHelper.MakeSpriteButton($"DungType_{i}", parent,
                UISprites.Btn1_WS, TypeColors[i], "", UIConstants.Font_Button);
            btn.onClick.AddListener(() => SelectType((DungeonType)idx));
            typeButtonImgs[i] = img;

            var rt = btn.GetComponent<RectTransform>();
            rt.anchorMin = new Vector2(i * third + 0.01f,  0.80f);
            rt.anchorMax = new Vector2((i + 1) * third - 0.01f, 0.97f);
            rt.offsetMin = Vector2.zero;
            rt.offsetMax = Vector2.zero;

            var label = UIHelper.MakeText("Label", btn.transform, TypeNames[i],
                11f, TextAlignmentOptions.Center, Color.white);
            label.fontStyle = FontStyles.Bold;
            UIHelper.AddTextShadow(label);
            UIHelper.FillParent(label.GetComponent<RectTransform>());
        }
    }

    void BuildInfoPanel(Transform parent)
    {
        var infoBg = UIHelper.MakeSpritePanel("InfoBG", parent,
            UISprites.BoxBasic3, new Color(0.25f, 0.18f, 0.12f, 0.80f));
        var irt = infoBg.GetComponent<RectTransform>();
        irt.anchorMin = new Vector2(0.05f, 0.60f);
        irt.anchorMax = new Vector2(0.95f, 0.78f);
        irt.offsetMin = Vector2.zero;
        irt.offsetMax = Vector2.zero;

        bestFloorText = UIHelper.MakeText("BestFloor", infoBg.transform, "최고 단계: 0",
            UIConstants.Font_StatLabel, TextAlignmentOptions.Left, UIColors.Text_Gold);
        UIHelper.AddTextShadow(bestFloorText);
        var brt = bestFloorText.GetComponent<RectTransform>();
        brt.anchorMin = new Vector2(0.05f, 0.50f);
        brt.anchorMax = new Vector2(0.95f, 1.00f);
        brt.offsetMin = Vector2.zero;
        brt.offsetMax = Vector2.zero;

        remainingText = UIHelper.MakeText("Remaining", infoBg.transform, "잔여 입장: 3",
            UIConstants.Font_StatLabel, TextAlignmentOptions.Left, UIColors.Text_Secondary);
        var rrt = remainingText.GetComponent<RectTransform>();
        rrt.anchorMin = new Vector2(0.05f, 0.00f);
        rrt.anchorMax = new Vector2(0.95f, 0.50f);
        rrt.offsetMin = Vector2.zero;
        rrt.offsetMax = Vector2.zero;
    }

    void BuildFloorSelector(Transform parent)
    {
        var floorLabel = UIHelper.MakeText("FloorLabel", parent, "도전 단계",
            UIConstants.Font_StatLabel, TextAlignmentOptions.Center, UIColors.Text_Gold);
        var llrt = floorLabel.GetComponent<RectTransform>();
        llrt.anchorMin = new Vector2(0.05f, 0.50f);
        llrt.anchorMax = new Vector2(0.95f, 0.59f);
        llrt.offsetMin = Vector2.zero;
        llrt.offsetMax = Vector2.zero;

        // - 버튼
        var (minusBtn, _) = UIHelper.MakeSpriteButton("MinusBtn", parent,
            UISprites.Btn1_WS, UIColors.Button_Brown, "", UIConstants.Font_Button);
        minusBtn.onClick.AddListener(() => ChangeFloor(-1));
        var mrt = minusBtn.GetComponent<RectTransform>();
        mrt.anchorMin = new Vector2(0.05f, 0.36f);
        mrt.anchorMax = new Vector2(0.25f, 0.49f);
        mrt.offsetMin = Vector2.zero;
        mrt.offsetMax = Vector2.zero;
        var minusLabel = UIHelper.MakeText("L", minusBtn.transform, "-",
            22f, TextAlignmentOptions.Center, Color.white);
        minusLabel.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(minusLabel.GetComponent<RectTransform>());

        // 단계 값 표시
        var floorBg = UIHelper.MakeSpritePanel("FloorBG", parent,
            UISprites.BoxIcon1, UIColors.Panel_Inner);
        var frt = floorBg.GetComponent<RectTransform>();
        frt.anchorMin = new Vector2(0.28f, 0.36f);
        frt.anchorMax = new Vector2(0.72f, 0.49f);
        frt.offsetMin = Vector2.zero;
        frt.offsetMax = Vector2.zero;

        floorValueText = UIHelper.MakeText("FloorVal", floorBg.transform, "1",
            UIConstants.Font_HeaderMedium, TextAlignmentOptions.Center, Color.white);
        floorValueText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(floorValueText);
        UIHelper.FillParent(floorValueText.GetComponent<RectTransform>());

        // + 버튼
        var (plusBtn, _) = UIHelper.MakeSpriteButton("PlusBtn", parent,
            UISprites.Btn1_WS, UIColors.Button_Green, "", UIConstants.Font_Button);
        plusBtn.onClick.AddListener(() => ChangeFloor(1));
        var prt = plusBtn.GetComponent<RectTransform>();
        prt.anchorMin = new Vector2(0.75f, 0.36f);
        prt.anchorMax = new Vector2(0.95f, 0.49f);
        prt.offsetMin = Vector2.zero;
        prt.offsetMax = Vector2.zero;
        var plusLabel = UIHelper.MakeText("L", plusBtn.transform, "+",
            22f, TextAlignmentOptions.Center, Color.white);
        plusLabel.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(plusLabel.GetComponent<RectTransform>());
    }

    void BuildRewardLabel(Transform parent)
    {
        var rewardBg = UIHelper.MakeSpritePanel("RewardBG", parent,
            UISprites.BoxIcon1, UIColors.Panel_Inner);
        var rrt = rewardBg.GetComponent<RectTransform>();
        rrt.anchorMin = new Vector2(0.15f, 0.24f);
        rrt.anchorMax = new Vector2(0.85f, 0.33f);
        rrt.offsetMin = Vector2.zero;
        rrt.offsetMax = Vector2.zero;

        rewardTypeText = UIHelper.MakeText("RewardType", rewardBg.transform, TypeRewards[0],
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, UIColors.Text_Gold);
        UIHelper.FillParent(rewardTypeText.GetComponent<RectTransform>());
    }

    void BuildEnterButton(Transform parent)
    {
        // 광고 +1회 버튼
        var (adBtn, _) = UIHelper.MakeSpriteButton("AdBonusBtn", parent,
            UISprites.Btn1_WS, UIColors.Button_Blue, "", UIConstants.Font_SmallInfo);
        adBtn.onClick.AddListener(OnAdBonusClicked);
        adBonusBtn = adBtn;
        var art = adBtn.GetComponent<RectTransform>();
        art.anchorMin = new Vector2(0.15f, 0.13f);
        art.anchorMax = new Vector2(0.85f, 0.20f);
        art.offsetMin = Vector2.zero;
        art.offsetMax = Vector2.zero;

        var adLabel = UIHelper.MakeText("Label", adBtn.transform, "광고 보고 +1회",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, Color.white);
        adLabel.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(adLabel.GetComponent<RectTransform>());

        // 입장 버튼
        var (btn, _2) = UIHelper.MakeSpriteButton("EnterBtn", parent,
            UISprites.Btn2_WS, UIColors.Button_Green, "", UIConstants.Font_Button);
        enterBtn = btn;
        btn.onClick.AddListener(OnEnterClicked);
        var rt = btn.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0.15f, 0.02f);
        rt.anchorMax = new Vector2(0.85f, 0.12f);
        rt.offsetMin = Vector2.zero;
        rt.offsetMax = Vector2.zero;

        var label = UIHelper.MakeText("Label", btn.transform, "입  장",
            UIConstants.Font_Button, TextAlignmentOptions.Center, Color.white);
        label.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(label);
        UIHelper.FillParent(label.GetComponent<RectTransform>());
    }

    // ────────────────────────────────────────
    // Event subscriptions
    // ────────────────────────────────────────

    System.Collections.IEnumerator DeferredSubscribe()
    {
        yield return null;
        cachedDungeonMgr = DungeonManager.Instance;
        if (cachedDungeonMgr != null)
        {
            cachedDungeonMgr.OnDungeonCleared += OnDungeonCleared;
            cachedDungeonMgr.OnEntriesChanged  += OnEntriesChanged;
        }
    }

    void OnDestroy()
    {
        if (cachedDungeonMgr != null)
        {
            cachedDungeonMgr.OnDungeonCleared -= OnDungeonCleared;
            cachedDungeonMgr.OnEntriesChanged  -= OnEntriesChanged;
        }
    }

    void OnDungeonCleared(DungeonType type, int reward)
    {
        if (type == selectedType)
            Refresh();
        ToastNotification.Instance?.Show("던전 클리어!", $"{reward} 획득!", UIColors.Text_Gold);
    }

    void OnEntriesChanged(DungeonType type, int remaining)
    {
        if (type == selectedType)
            RefreshInfo();
    }

    // ────────────────────────────────────────
    // Interaction
    // ────────────────────────────────────────

    void SelectType(DungeonType type)
    {
        selectedType = type;
        // 단계 재설정: 최소 1, 최대 bestFloor+1
        int bestFloor = GetBestFloorForSelected();
        selectedFloor = Mathf.Clamp(selectedFloor, 1, Mathf.Max(1, bestFloor + 1));
        SoundManager.Instance?.PlayButtonSFX();
        UpdateAllUI();
    }

    void ChangeFloor(int delta)
    {
        int bestFloor = GetBestFloorForSelected();
        int maxFloor  = Mathf.Max(1, bestFloor + 1);
        selectedFloor = Mathf.Clamp(selectedFloor + delta, 1, maxFloor);
        if (floorValueText != null)
            floorValueText.text = selectedFloor.ToString();
    }

    void OnEnterClicked()
    {
        var dm = DungeonManager.Instance;
        if (dm == null) return;

        if (!dm.CanEnter(selectedType))
        {
            ToastNotification.Instance?.Show("입장 불가", "오늘 입장 횟수를 모두 사용했습니다.", UIColors.Defeat_Red);
            return;
        }

        // DungeonData 임시 생성
        var data = ScriptableObject.CreateInstance<DungeonData>();
        data.dungeonType = selectedType;
        data.stage       = selectedFloor;
        data.baseReward  = 10 + (selectedFloor - 1) * 5;

        if (dm.TryEnter(data))
        {
            SoundManager.Instance?.PlayButtonSFX();
            // Task #28에서 BattleManager 연동 시 씬 전환 추가 예정
            ToastNotification.Instance?.Show("던전 입장", $"{TypeNames[(int)selectedType]} {selectedFloor}단계", UIColors.Button_Green);
            RefreshInfo();
        }
        else
        {
            ToastNotification.Instance?.Show("입장 실패", "잠시 후 다시 시도하세요.", UIColors.Defeat_Red);
        }

        Destroy(data);
    }

    void OnAdBonusClicked()
    {
        var dm = DungeonManager.Instance;
        if (dm == null) return;

        // 광고 시청 후 추가 입장 제공
        if (AdManager.Instance != null)
        {
            AdManager.Instance.ShowRewardedAd(
                AdManager.AdRewardType.DungeonEntry,
                () =>
                {
                    if (dm.AddBonusEntry(selectedType))
                    {
                        ToastNotification.Instance?.Show("보너스 입장!", "광고 덕분에 +1회 추가!", UIColors.Button_Green);
                        RefreshInfo();
                    }
                    else
                    {
                        ToastNotification.Instance?.Show("보너스 입장 불가", "일일 광고 제한을 초과했습니다.", UIColors.Defeat_Red);
                    }
                }
            );
        }
    }

    // ────────────────────────────────────────
    // Refresh helpers
    // ────────────────────────────────────────

    public void Refresh()
    {
        UpdateAllUI();
    }

    void UpdateAllUI()
    {
        RefreshTypeButtons();
        RefreshInfo();
        RefreshFloorSelector();
        RefreshRewardLabel();
    }

    void RefreshTypeButtons()
    {
        for (int i = 0; i < 3; i++)
        {
            if (typeButtonImgs[i] == null) continue;
            bool active = (i == (int)selectedType);
            typeButtonImgs[i].color = active ? TypeColors[i] : TypeColors[i] * 0.55f;
            typeButtonImgs[i].transform.localScale = active ? Vector3.one : Vector3.one * 0.92f;
        }
    }

    void RefreshInfo()
    {
        var dm = DungeonManager.Instance;
        int bestFloor  = GetBestFloorForSelected();
        int remaining  = dm != null ? dm.GetRemainingEntries(selectedType) : 0;

        if (bestFloorText  != null) bestFloorText.text  = $"최고 단계: {(bestFloor > 0 ? bestFloor.ToString() : "-")}";
        if (remainingText  != null) remainingText.text  = $"잔여 입장: {remaining}회";

        // 입장 버튼 활성 여부
        if (enterBtn != null)
            enterBtn.interactable = remaining > 0;

        // 광고 보너스 버튼 활성 여부 (입장 횟수 0일 때만 표시)
        if (adBonusBtn != null)
            adBonusBtn.interactable = (remaining == 0);
    }

    void RefreshFloorSelector()
    {
        int bestFloor = GetBestFloorForSelected();
        int maxFloor  = Mathf.Max(1, bestFloor + 1);
        selectedFloor = Mathf.Clamp(selectedFloor, 1, maxFloor);
        if (floorValueText != null)
            floorValueText.text = selectedFloor.ToString();
    }

    void RefreshRewardLabel()
    {
        if (rewardTypeText != null)
            rewardTypeText.text = TypeRewards[(int)selectedType];
    }

    int GetBestFloorForSelected()
    {
        // DungeonManager는 bestFloor를 직접 노출하지 않으므로 PlayerPrefs에서 직접 읽기
        // (DungeonManager 내부 키와 동일)
        string key = selectedType switch
        {
            DungeonType.Hero  => SaveKeys.DungeonBestFloorHero,
            DungeonType.Mount => SaveKeys.DungeonBestFloorMount,
            DungeonType.Skill => SaveKeys.DungeonBestFloorSkill,
            _                 => SaveKeys.DungeonBestFloorHero
        };
        return PlayerPrefs.GetInt(key, 0);
    }
}
