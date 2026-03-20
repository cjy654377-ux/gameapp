using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections.Generic;

/// <summary>
/// 상점 탭 패널: 상점/업적/미션/도감/아레나/설정 서브탭
/// MainHUD 상점 탭에서 Init(parent, showConfirm, settingsPanel)으로 초기화
/// </summary>
public class ShopPanel : MonoBehaviour
{
    // 서브탭
    int subTab; // 0=상점 1=업적 2=미션 3=도감 4=아레나 5=설정
    Button[] subTabBtns;
    TextMeshProUGUI[] subTabLabels;
    GameObject shopRoot, achieveRoot, missionRoot, collectionRoot, arenaRoot, settingsRoot;

    // 상점 리스트
    GameObject shopListContainer;
    readonly List<GameObject> shopListItems = new();

    // 업적 리스트
    GameObject achieveListContainer;
    readonly List<GameObject> achieveListItems = new();

    // 미션 리스트
    GameObject missionListContainer;
    readonly List<GameObject> missionListItems = new();

    // 도감
    TextMeshProUGUI collectionText;

    // 아레나
    TextMeshProUGUI arenaInfoText;
    Button arenaBattleBtn;

    // 설정 패널 참조
    SettingsPanel settingsPanel;

    // ShowConfirm 델리게이트 (MainHUD 확인 팝업)
    System.Action<string, string, System.Action> showConfirm;

    // ════════════════════════════════════════
    // 초기화
    // ════════════════════════════════════════

    public void Init(Transform parent, System.Action<string, string, System.Action> showConfirmCallback, SettingsPanel settings)
    {
        showConfirm = showConfirmCallback;
        settingsPanel = settings;

        var content = UIHelper.MakeUI("ShopContent", parent);
        var contentRT = content.GetComponent<RectTransform>();
        contentRT.anchorMin = Vector2.zero;
        contentRT.anchorMax = Vector2.one;
        contentRT.offsetMin = new Vector2(0, 0);
        contentRT.offsetMax = new Vector2(0, -UIConstants.Tab_Height);

        float subTabH = 28f;
        var shopSubBg = UIHelper.MakeSpritePanel("ShopSubTabBar", content.transform,
            UISprites.Board, UIColors.Background_Dark);
        var stbRT = shopSubBg.GetComponent<RectTransform>();
        stbRT.anchorMin = new Vector2(0, 1);
        stbRT.anchorMax = new Vector2(1, 1);
        stbRT.pivot = new Vector2(0.5f, 1);
        stbRT.sizeDelta = new Vector2(0, subTabH);

        string[] subNames = { "상점", "업적", "미션", "도감", "아레나", "설정" };
        int subCount = subNames.Length;
        subTabBtns = new Button[subCount];
        subTabLabels = new TextMeshProUGUI[subCount];

        for (int s = 0; s < subCount; s++)
        {
            float xMin = s / (float)subCount;
            float xMax = (s + 1) / (float)subCount;
            var (btn, btnImg) = UIHelper.MakeSpriteButton($"ShopSub_{subNames[s]}", shopSubBg.transform,
                UISprites.Btn1_WS, UIColors.Tab_Inactive, "", 0);
            if (UISprites.Btn1_WS != null) btnImg.color = Color.white;
            var brt = btn.GetComponent<RectTransform>();
            brt.anchorMin = new Vector2(xMin, 0);
            brt.anchorMax = new Vector2(xMax, 1);
            brt.offsetMin = new Vector2(1, 1);
            brt.offsetMax = new Vector2(-1, -1);

            var label = UIHelper.MakeText("Label", btn.transform, subNames[s],
                9f, TextAlignmentOptions.Center, UIColors.Text_Secondary);
            label.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(label.GetComponent<RectTransform>());

            subTabBtns[s] = btn;
            subTabLabels[s] = label;

            int captured = s;
            btn.onClick.AddListener(() => SwitchSubTab(captured));
        }

        shopRoot = MakeSubRoot("ShopRoot", content.transform, subTabH);
        BuildShopList(shopRoot.transform);

        achieveRoot = MakeSubRoot("AchieveRoot", content.transform, subTabH);
        BuildAchievementList(achieveRoot.transform);

        missionRoot = MakeSubRoot("MissionRoot", content.transform, subTabH);
        BuildMissionList(missionRoot.transform);

        collectionRoot = MakeSubRoot("CollectionRoot", content.transform, subTabH);
        BuildCollectionContent(collectionRoot.transform);

        arenaRoot = MakeSubRoot("ArenaRoot", content.transform, subTabH);
        BuildArenaContent(arenaRoot.transform);

        settingsRoot = MakeSubRoot("SettingsRoot", content.transform, subTabH);
        if (settingsPanel != null)
            settingsPanel.Init(settingsRoot.transform);

        subTab = 0;
        UpdateSubTabVisuals();
    }

    static GameObject MakeSubRoot(string name, Transform parent, float subTabH)
    {
        var root = UIHelper.MakeUI(name, parent);
        var rt = root.GetComponent<RectTransform>();
        rt.anchorMin = Vector2.zero;
        rt.anchorMax = Vector2.one;
        rt.offsetMin = Vector2.zero;
        rt.offsetMax = new Vector2(0, -subTabH);
        return root;
    }

    // ════════════════════════════════════════
    // 서브탭 전환
    // ════════════════════════════════════════

    void SwitchSubTab(int idx)
    {
        SoundManager.Instance?.PlayButtonSFX();
        subTab = idx;
        UpdateSubTabVisuals();
        RefreshCurrentSubTab();
    }

    void UpdateSubTabVisuals()
    {
        if (subTabBtns == null) return;
        for (int i = 0; i < subTabBtns.Length; i++)
        {
            bool active = (i == subTab);
            var img = subTabBtns[i].GetComponent<Image>();
            if (img.sprite != null)
            {
                img.color = active ? new Color(0.85f, 0.85f, 0.85f) : Color.white;
                subTabBtns[i].transform.localScale = active ? Vector3.one * 0.95f : Vector3.one;
            }
            else
                img.color = active ? UIColors.Tab_Active : UIColors.Tab_Inactive;
            subTabLabels[i].color = active ? Color.white : UIColors.Text_Secondary;
        }
        if (shopRoot != null) shopRoot.SetActive(subTab == 0);
        if (achieveRoot != null) achieveRoot.SetActive(subTab == 1);
        if (missionRoot != null) missionRoot.SetActive(subTab == 2);
        if (collectionRoot != null) collectionRoot.SetActive(subTab == 3);
        if (arenaRoot != null) arenaRoot.SetActive(subTab == 4);
        if (settingsRoot != null) settingsRoot.SetActive(subTab == 5);
    }

    void RefreshCurrentSubTab()
    {
        switch (subTab)
        {
            case 0: RefreshShopList(); break;
            case 1: RefreshAchievementUI(); break;
            case 2: RefreshMissionUI(); break;
            case 3: RefreshCollectionUI(); break;
            case 4: RefreshArenaUI(); break;
            case 5: settingsPanel?.Refresh(); break;
        }
    }

    public void Refresh()
    {
        UpdateSubTabVisuals();
        RefreshCurrentSubTab();
    }

    // ════════════════════════════════════════
    // 상점 리스트
    // ════════════════════════════════════════

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
        int reuse = 0;
        var items = shop.GetStockItems();
        float itemH = 44f, spacing = 2f, y = 0;
        int active = 0;

        for (int i = 0; i < items.Count; i++)
        {
            var shopItem = items[i];
            var item = ReuseOrCreate(shopListItems, ref reuse, $"Shop_{i}", shopListContainer.transform, new Color(0.92f, 0.88f, 0.82f));
            active++;
            var irt = item.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0, 1); irt.anchorMax = new Vector2(1, 1);
            irt.pivot = new Vector2(0.5f, 1);
            irt.anchoredPosition = new Vector2(0, y); irt.sizeDelta = new Vector2(0, itemH);

            var nameText = UIHelper.MakeText("Name", item.transform, shopItem.displayName,
                UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, UIColors.Text_Dark);
            nameText.fontStyle = FontStyles.Bold;
            var nrt = nameText.GetComponent<RectTransform>();
            nrt.anchorMin = new Vector2(0, 0.5f); nrt.anchorMax = new Vector2(0.4f, 1);
            nrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0); nrt.offsetMax = Vector2.zero;

            var descText = UIHelper.MakeText("Desc", item.transform, shopItem.description,
                8f, TextAlignmentOptions.MidlineLeft, UIColors.Text_DarkSecondary);
            var drt = descText.GetComponent<RectTransform>();
            drt.anchorMin = new Vector2(0, 0); drt.anchorMax = new Vector2(0.4f, 0.5f);
            drt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0); drt.offsetMax = Vector2.zero;

            string priceStr = shopItem.gemCost > 0 ? $"{shopItem.gemCost} 보석" :
                              shopItem.goldCost > 0 ? $"{shopItem.goldCost}G" : "무료";
            var priceText = UIHelper.MakeText("Price", item.transform, priceStr,
                9f, TextAlignmentOptions.Center, UIColors.Text_DarkDiamond);
            var prt = priceText.GetComponent<RectTransform>();
            prt.anchorMin = new Vector2(0.4f, 0); prt.anchorMax = new Vector2(0.65f, 1);
            prt.offsetMin = Vector2.zero; prt.offsetMax = Vector2.zero;

            bool canBuy = shop.CanPurchase(shopItem);
            float cooldown = shop.GetRemainingCooldown(shopItem);
            string btnLabel = cooldown > 0 ? $"{Mathf.CeilToInt(cooldown / 60f)}분" : "구매";

            var (btn, shopBtnImg) = UIHelper.MakeSpriteButton($"Buy_{i}", item.transform,
                canBuy ? UISprites.Btn2_WS : UISprites.Btn1_WS,
                canBuy ? UIColors.Button_Green : UIColors.Button_Gray, "", 10f);
            if (!canBuy && shopBtnImg.sprite != null) shopBtnImg.color = new Color(0.70f, 0.70f, 0.70f);
            var btnRT = btn.GetComponent<RectTransform>();
            btnRT.anchorMin = new Vector2(0.68f, 0.1f); btnRT.anchorMax = new Vector2(0.97f, 0.9f);
            btnRT.offsetMin = Vector2.zero; btnRT.offsetMax = Vector2.zero;

            var btnText = UIHelper.MakeText("Label", btn.transform, btnLabel,
                UIConstants.Font_Cost, TextAlignmentOptions.Center,
                canBuy ? Color.white : UIColors.Text_Disabled);
            btnText.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(btnText.GetComponent<RectTransform>());

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
                    showConfirm?.Invoke("구매 확인", $"보석 {capturedItem.gemCost}개를 사용합니다.\n진행하시겠습니까?", () =>
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

            y -= (itemH + spacing);
        }

        TrimExcess(shopListItems, active);
        shopListContainer.GetComponent<RectTransform>().sizeDelta = new Vector2(0, Mathf.Abs(y));
    }

    // ════════════════════════════════════════
    // 업적 리스트
    // ════════════════════════════════════════

    void BuildAchievementList(Transform parent)
    {
        var scrollObj = UIHelper.MakeUI("AchieveScroll", parent);
        var scrollRT = scrollObj.GetComponent<RectTransform>();
        scrollRT.anchorMin = Vector2.zero; scrollRT.anchorMax = Vector2.one;
        scrollRT.offsetMin = new Vector2(UIConstants.Spacing_Small, UIConstants.Spacing_Small);
        scrollRT.offsetMax = new Vector2(-UIConstants.Spacing_Small, 0);

        var scrollRect = scrollObj.AddComponent<ScrollRect>();
        scrollRect.horizontal = false; scrollRect.vertical = true;

        var viewport = UIHelper.MakeUI("Viewport", scrollObj.transform);
        viewport.AddComponent<RectMask2D>();
        UIHelper.FillParent(viewport.GetComponent<RectTransform>());
        scrollRect.viewport = viewport.GetComponent<RectTransform>();

        achieveListContainer = UIHelper.MakeUI("Content", viewport.transform);
        var hcRT = achieveListContainer.GetComponent<RectTransform>();
        hcRT.anchorMin = new Vector2(0, 1); hcRT.anchorMax = new Vector2(1, 1);
        hcRT.pivot = new Vector2(0.5f, 1); hcRT.anchoredPosition = Vector2.zero;
        scrollRect.content = hcRT;
    }

    void RefreshAchievementUI()
    {
        if (achieveListContainer == null) return;
        var am = AchievementManager.Instance;
        if (am == null) return;

        RecycleList(achieveListItems);
        int reuse = 0;
        var achievements = am.GetAchievements();
        float itemH = 42f, spacing = 2f, y = 0;
        int active = 0;

        for (int i = 0; i < achievements.Count; i++)
        {
            var ach = achievements[i];
            Color bgColor = ach.claimed ? new Color(0.82f, 0.78f, 0.72f) :
                            ach.completed ? new Color(0.82f, 0.92f, 0.75f) : new Color(0.92f, 0.88f, 0.82f);

            var item = ReuseOrCreate(achieveListItems, ref reuse, $"Ach_{i}", achieveListContainer.transform, bgColor);
            active++;
            var irt = item.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0, 1); irt.anchorMax = new Vector2(1, 1);
            irt.pivot = new Vector2(0.5f, 1);
            irt.anchoredPosition = new Vector2(0, y); irt.sizeDelta = new Vector2(0, itemH);

            Color nameColor = ach.completed ? UIColors.Text_Dark : UIColors.Text_Disabled;
            var nameText = UIHelper.MakeText("Name", item.transform, ach.name,
                UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, nameColor);
            nameText.fontStyle = FontStyles.Bold;
            var nrt = nameText.GetComponent<RectTransform>();
            nrt.anchorMin = new Vector2(0, 0.5f); nrt.anchorMax = new Vector2(0.45f, 1);
            nrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0); nrt.offsetMax = Vector2.zero;

            var descText = UIHelper.MakeText("Desc", item.transform, ach.description,
                8f, TextAlignmentOptions.MidlineLeft, UIColors.Text_DarkSecondary);
            var drt = descText.GetComponent<RectTransform>();
            drt.anchorMin = new Vector2(0, 0); drt.anchorMax = new Vector2(0.45f, 0.5f);
            drt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0); drt.offsetMax = Vector2.zero;

            var rewardText = UIHelper.MakeText("Reward", item.transform, $"{ach.gemReward} 보석",
                9f, TextAlignmentOptions.Center, UIColors.Text_DarkDiamond);
            var rrt = rewardText.GetComponent<RectTransform>();
            rrt.anchorMin = new Vector2(0.45f, 0); rrt.anchorMax = new Vector2(0.68f, 1);
            rrt.offsetMin = Vector2.zero; rrt.offsetMax = Vector2.zero;

            string btnLabel;
            Sprite btnSprite;
            Color btnFallback;
            if (ach.claimed) { btnLabel = "완료"; btnSprite = UISprites.Btn1_WS; btnFallback = UIColors.Button_Gray; }
            else if (ach.completed) { btnLabel = "수령"; btnSprite = UISprites.Btn3_WS; btnFallback = UIColors.Button_Yellow; }
            else { btnLabel = "미달성"; btnSprite = UISprites.Btn1_WS; btnFallback = UIColors.Button_Gray; }

            var (btn, achBtnImg) = UIHelper.MakeSpriteButton($"AchBtn_{i}", item.transform, btnSprite, btnFallback, "", 10f);
            if (ach.claimed && achBtnImg.sprite != null) achBtnImg.color = new Color(0.70f, 0.70f, 0.70f);
            var btnRT = btn.GetComponent<RectTransform>();
            btnRT.anchorMin = new Vector2(0.70f, 0.1f); btnRT.anchorMax = new Vector2(0.97f, 0.9f);
            btnRT.offsetMin = Vector2.zero; btnRT.offsetMax = Vector2.zero;

            Color achBtnTextColor = ach.completed && !ach.claimed ? new Color(0.25f, 0.15f, 0.08f) : UIColors.Text_Disabled;
            var btnText = UIHelper.MakeText("Label", btn.transform, btnLabel,
                UIConstants.Font_Cost, TextAlignmentOptions.Center, achBtnTextColor);
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

        TrimExcess(achieveListItems, active);
        achieveListContainer.GetComponent<RectTransform>().sizeDelta = new Vector2(0, Mathf.Abs(y));
    }

    // ════════════════════════════════════════
    // 미션 리스트
    // ════════════════════════════════════════

    void BuildMissionList(Transform parent)
    {
        var scrollObj = UIHelper.MakeUI("MissionScroll", parent);
        var scrollRT = scrollObj.GetComponent<RectTransform>();
        scrollRT.anchorMin = Vector2.zero; scrollRT.anchorMax = Vector2.one;
        scrollRT.offsetMin = new Vector2(UIConstants.Spacing_Small, UIConstants.Spacing_Small);
        scrollRT.offsetMax = new Vector2(-UIConstants.Spacing_Small, 0);

        var scrollRect = scrollObj.AddComponent<ScrollRect>();
        scrollRect.horizontal = false; scrollRect.vertical = true;

        var viewport = UIHelper.MakeUI("Viewport", scrollObj.transform);
        viewport.AddComponent<RectMask2D>();
        UIHelper.FillParent(viewport.GetComponent<RectTransform>());
        scrollRect.viewport = viewport.GetComponent<RectTransform>();

        missionListContainer = UIHelper.MakeUI("Content", viewport.transform);
        var hcRT = missionListContainer.GetComponent<RectTransform>();
        hcRT.anchorMin = new Vector2(0, 1); hcRT.anchorMax = new Vector2(1, 1);
        hcRT.pivot = new Vector2(0.5f, 1); hcRT.anchoredPosition = Vector2.zero;
        scrollRect.content = hcRT;
    }

    void RefreshMissionUI()
    {
        if (missionListContainer == null) return;
        var mm = DailyMissionManager.Instance;
        if (mm == null) return;

        RecycleList(missionListItems);
        int reuse = 0;
        var missions = mm.GetMissions();
        float itemH = 42f, spacing = 2f, y = 0;
        int active = 0;

        for (int i = 0; i < missions.Count; i++)
        {
            var mission = missions[i];
            bool completed = mission.currentCount >= mission.targetCount;
            Color bgColor = mission.claimed ? new Color(0.82f, 0.78f, 0.72f) :
                            completed ? new Color(0.82f, 0.92f, 0.75f) : new Color(0.92f, 0.88f, 0.82f);

            var item = ReuseOrCreate(missionListItems, ref reuse, $"Mission_{i}", missionListContainer.transform, bgColor);
            active++;
            var irt = item.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0, 1); irt.anchorMax = new Vector2(1, 1);
            irt.pivot = new Vector2(0.5f, 1);
            irt.anchoredPosition = new Vector2(0, y); irt.sizeDelta = new Vector2(0, itemH);

            Color nameColor = completed ? UIColors.Text_Dark : UIColors.Text_Disabled;
            var nameText = UIHelper.MakeText("Name", item.transform, mission.name,
                UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, nameColor);
            nameText.fontStyle = FontStyles.Bold;
            var nrt = nameText.GetComponent<RectTransform>();
            nrt.anchorMin = new Vector2(0, 0.5f); nrt.anchorMax = new Vector2(0.4f, 1);
            nrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0); nrt.offsetMax = Vector2.zero;

            string progressStr = $"{mission.currentCount}/{mission.targetCount}";
            Color progColor = completed ? UIColors.Text_DarkGreen : UIColors.Text_DarkSecondary;
            var progText = UIHelper.MakeText("Progress", item.transform, progressStr,
                9f, TextAlignmentOptions.MidlineLeft, progColor);
            var prt = progText.GetComponent<RectTransform>();
            prt.anchorMin = new Vector2(0, 0); prt.anchorMax = new Vector2(0.4f, 0.5f);
            prt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0); prt.offsetMax = Vector2.zero;

            var rewardText = UIHelper.MakeText("Reward", item.transform, $"{mission.gemReward} 보석",
                9f, TextAlignmentOptions.Center, UIColors.Text_DarkDiamond);
            var rrt = rewardText.GetComponent<RectTransform>();
            rrt.anchorMin = new Vector2(0.4f, 0); rrt.anchorMax = new Vector2(0.65f, 1);
            rrt.offsetMin = Vector2.zero; rrt.offsetMax = Vector2.zero;

            string btnLabel;
            Sprite mBtnSprite; Color mBtnFallback;
            if (mission.claimed) { btnLabel = "완료"; mBtnSprite = UISprites.Btn1_WS; mBtnFallback = UIColors.Button_Gray; }
            else if (completed) { btnLabel = "수령"; mBtnSprite = UISprites.Btn3_WS; mBtnFallback = UIColors.Button_Yellow; }
            else { btnLabel = "진행중"; mBtnSprite = UISprites.Btn1_WS; mBtnFallback = UIColors.Button_Gray; }

            var (btn, mBtnImg) = UIHelper.MakeSpriteButton($"MissionBtn_{i}", item.transform, mBtnSprite, mBtnFallback, "", 10f);
            if (mission.claimed && mBtnImg.sprite != null) mBtnImg.color = new Color(0.70f, 0.70f, 0.70f);
            var btnRT = btn.GetComponent<RectTransform>();
            btnRT.anchorMin = new Vector2(0.68f, 0.1f); btnRT.anchorMax = new Vector2(0.97f, 0.9f);
            btnRT.offsetMin = Vector2.zero; btnRT.offsetMax = Vector2.zero;

            Color btnTextColor = completed && !mission.claimed ? new Color(0.25f, 0.15f, 0.08f) : UIColors.Text_Disabled;
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

        TrimExcess(missionListItems, active);
        missionListContainer.GetComponent<RectTransform>().sizeDelta = new Vector2(0, Mathf.Abs(y));
    }

    // ════════════════════════════════════════
    // 도감
    // ════════════════════════════════════════

    void BuildCollectionContent(Transform parent)
    {
        var content = UIHelper.MakeUI("CollectionContent", parent);
        var crt = content.GetComponent<RectTransform>();
        crt.anchorMin = Vector2.zero; crt.anchorMax = Vector2.one;
        crt.offsetMin = new Vector2(UIConstants.Spacing_Medium, UIConstants.Spacing_Medium);
        crt.offsetMax = new Vector2(-UIConstants.Spacing_Medium, 0);

        collectionText = UIHelper.MakeText("Info", content.transform, "",
            UIConstants.Font_StatValue, TextAlignmentOptions.TopLeft, UIColors.Text_Dark);
        UIHelper.FillParent(collectionText.GetComponent<RectTransform>());
    }

    void RefreshCollectionUI()
    {
        if (collectionText == null) return;
        var cm = CollectionManager.Instance;
        if (cm == null) { collectionText.text = "도감 로딩 중..."; return; }

        collectionText.text =
            $"<color=#FFD700>═══ 도감 ═══</color>\n\n" +
            $"<color=#7FD44C>영웅</color>  {cm.HeroCount}/{CollectionManager.TOTAL_HEROES}  ({cm.HeroProgress:P0})\n" +
            $"<color=#FF6B6B>몬스터</color>  {cm.MonsterCount}/{CollectionManager.TOTAL_MONSTERS}  ({cm.MonsterProgress:P0})\n" +
            $"<color=#87CEEB>장비</color>  {cm.EquipCount}/{CollectionManager.TOTAL_EQUIP_TYPES}  ({cm.EquipProgress:P0})\n\n" +
            $"<color=#FFD700>전체 완성도: {cm.TotalProgress:P0}</color>\n\n" +
            $"마일스톤 보상: 3/5/7/10/13종 달성 시 보석!";
    }

    // ════════════════════════════════════════
    // 아레나
    // ════════════════════════════════════════

    void BuildArenaContent(Transform parent)
    {
        var content = UIHelper.MakeUI("ArenaContent", parent);
        var crt = content.GetComponent<RectTransform>();
        crt.anchorMin = Vector2.zero; crt.anchorMax = Vector2.one;
        crt.offsetMin = new Vector2(UIConstants.Spacing_Medium, UIConstants.Spacing_Medium);
        crt.offsetMax = new Vector2(-UIConstants.Spacing_Medium, 0);

        arenaInfoText = UIHelper.MakeText("Info", content.transform, "",
            UIConstants.Font_StatValue, TextAlignmentOptions.TopLeft, UIColors.Text_Dark);
        var irt = arenaInfoText.GetComponent<RectTransform>();
        irt.anchorMin = new Vector2(0, 0.35f); irt.anchorMax = new Vector2(1, 1);
        irt.offsetMin = Vector2.zero; irt.offsetMax = Vector2.zero;

        var (btn, _) = UIHelper.MakeSpriteButton("BattleBtn", content.transform,
            UISprites.Btn2_WS, UIColors.Button_Green, "", UIConstants.Font_Button);
        arenaBattleBtn = btn;
        var brt = btn.GetComponent<RectTransform>();
        brt.anchorMin = new Vector2(0.2f, 0.08f); brt.anchorMax = new Vector2(0.8f, 0.28f);
        brt.offsetMin = Vector2.zero; brt.offsetMax = Vector2.zero;
        var btnText = UIHelper.MakeText("Label", btn.transform, "도전!",
            UIConstants.Font_Button, TextAlignmentOptions.Center, Color.white);
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
            $"포인트: {am.ArenaPoints}P\n연승: {am.WinStreak}\n" +
            $"남은 도전: {am.RemainingAttempts}/{10}\n\n" +
            $"상대 난이도: {am.GetDifficulty() + 1}단계";

        if (arenaBattleBtn != null)
        {
            var img = arenaBattleBtn.GetComponent<Image>();
            if (img.sprite != null)
                img.color = am.CanBattle ? Color.white : new Color(0.70f, 0.70f, 0.70f);
            else
                img.color = am.CanBattle ? UIColors.Button_Green : UIColors.Button_Gray;
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
    // 정적 헬퍼 (MainHUD와 동일)
    // ════════════════════════════════════════

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
}
