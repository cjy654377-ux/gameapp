using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections.Generic;

/// <summary>
/// 햄버거 메뉴 패널 (☰): 업적 / 미션 / 도감 / 아레나 / 설정
/// MainHUD 상단 HUD 바 ☰ 버튼 클릭 시 전체화면 오버레이로 표시
/// </summary>
public class HamburgerPanel : MonoBehaviour
{
    int subTab; // 0=업적 1=미션 2=도감 3=아레나 4=퀘스트 5=친구 6=설정
    Button[] subTabBtns;
    TextMeshProUGUI[] subTabLabels;
    GameObject achieveRoot, missionRoot, collectionRoot, arenaRoot, questRoot, friendRoot, settingsRoot;

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

    // 퀘스트
    TextMeshProUGUI questInfoText;
    readonly List<GameObject> questListItems = new();
    GameObject questListContainer;
    TextMeshProUGUI weeklyBossInfoText;
    Button weeklyBossBattleBtn;

    // 친구
    TextMeshProUGUI friendInfoText;
    Button friendGiftBtn;
    Button friendReinfBtn;

    // ════════════════════════════════════════
    // 초기화
    // ════════════════════════════════════════

    public void Init(Transform parent)
    {
        var content = UIHelper.MakeUI("HamburgerContent", parent);
        var contentRT = content.GetComponent<RectTransform>();
        contentRT.anchorMin = Vector2.zero;
        contentRT.anchorMax = Vector2.one;
        contentRT.offsetMin = Vector2.zero;
        contentRT.offsetMax = Vector2.zero;

        float subTabH = UIConstants.SubTab_Height;
        var subTabBarBg = UIHelper.MakeSpritePanel("SubTabBar", content.transform,
            UISprites.BoxBasic3, UIColors.Background_Dark);
        var stbRT = subTabBarBg.GetComponent<RectTransform>();
        stbRT.anchorMin = new Vector2(0, 1);
        stbRT.anchorMax = new Vector2(1, 1);
        stbRT.pivot = new Vector2(0.5f, 1);
        stbRT.sizeDelta = new Vector2(0, subTabH);

        string[] subNames = { "업적", "미션", "도감", "아레나", "퀘스트", "친구", "설정" };
        Sprite[] subIcons = {
            UISprites.IconQuest,        // 업적
            UISprites.FlatIcon(3),      // 미션
            UISprites.IconInven,        // 도감
            UISprites.SpumIcon(136),    // 아레나 (방패+검)
            UISprites.IconQuest,        // 퀘스트
            UISprites.FlatIcon(10),     // 친구
            UISprites.IconSetting       // 설정
        };
        int subCount = subNames.Length;
        subTabBtns   = new Button[subCount];
        subTabLabels = new TextMeshProUGUI[subCount];

        for (int s = 0; s < subCount; s++)
        {
            float xMin = s / (float)subCount;
            float xMax = (s + 1) / (float)subCount;
            var (btn, btnImg) = UIHelper.MakeSpriteButton($"HamSub_{subNames[s]}", subTabBarBg.transform,
                UISprites.Btn1_WS, UIColors.Tab_Inactive, "", 0);
            if (UISprites.Btn1_WS != null) btnImg.color = Color.white;
            var brt = btn.GetComponent<RectTransform>();
            brt.anchorMin = new Vector2(xMin, 0);
            brt.anchorMax = new Vector2(xMax, 1);
            brt.offsetMin = new Vector2(1, 1);
            brt.offsetMax = new Vector2(-1, -1);

            // 아이콘 (좌측)
            if (subIcons[s] != null)
            {
                var icon = UIHelper.MakeIcon($"Icon_{s}", btn.transform, subIcons[s], new Color(0.85f, 0.82f, 0.78f));
                var irt = icon.GetComponent<RectTransform>();
                irt.anchorMin = new Vector2(0, 0.1f);
                irt.anchorMax = new Vector2(0, 0.9f);
                irt.pivot = new Vector2(0, 0.5f);
                irt.anchoredPosition = new Vector2(2, 0);
                irt.sizeDelta = new Vector2(14, 0);
            }

            // 라벨 (아이콘 오른쪽)
            var label = UIHelper.MakeText("Label", btn.transform, subNames[s],
                8f, TextAlignmentOptions.Center, UIColors.Text_Secondary);
            label.fontStyle = FontStyles.Bold;
            var lrt = label.GetComponent<RectTransform>();
            lrt.anchorMin = new Vector2(0.3f, 0);
            lrt.anchorMax = Vector2.one;
            lrt.offsetMin = Vector2.zero;
            lrt.offsetMax = Vector2.zero;

            subTabBtns[s]   = btn;
            subTabLabels[s] = label;

            int captured = s;
            btn.onClick.AddListener(() => SwitchSubTab(captured));
        }

        achieveRoot    = MakeSubRoot("AchieveRoot",    content.transform, subTabH);
        missionRoot    = MakeSubRoot("MissionRoot",    content.transform, subTabH);
        collectionRoot = MakeSubRoot("CollectionRoot", content.transform, subTabH);
        arenaRoot      = MakeSubRoot("ArenaRoot",      content.transform, subTabH);
        questRoot      = MakeSubRoot("QuestRoot",      content.transform, subTabH);
        friendRoot     = MakeSubRoot("FriendRoot",     content.transform, subTabH);
        settingsRoot   = MakeSubRoot("SettingsRoot",   content.transform, subTabH);

        BuildAchievementList(achieveRoot.transform);
        BuildMissionList(missionRoot.transform);
        BuildCollectionContent(collectionRoot.transform);
        BuildArenaContent(arenaRoot.transform);
        BuildQuestContent(questRoot.transform);
        BuildFriendContent(friendRoot.transform);
        var sp = settingsRoot.AddComponent<SettingsPanel>();
        sp.Init(settingsRoot.transform);

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
            img.color = active ? UIColors.Tab_Active : UIColors.Tab_Inactive;
            subTabLabels[i].color = active ? UIColors.Text_Gold : UIColors.Text_TabInactive;
            subTabLabels[i].fontStyle = active ? FontStyles.Bold : FontStyles.Normal;
        }
        if (achieveRoot    != null) achieveRoot.SetActive(subTab == 0);
        if (missionRoot    != null) missionRoot.SetActive(subTab == 1);
        if (collectionRoot != null) collectionRoot.SetActive(subTab == 2);
        if (arenaRoot      != null) arenaRoot.SetActive(subTab == 3);
        if (questRoot      != null) questRoot.SetActive(subTab == 4);
        if (friendRoot     != null) friendRoot.SetActive(subTab == 5);
        if (settingsRoot   != null) settingsRoot.SetActive(subTab == 6);
    }

    void RefreshCurrentSubTab()
    {
        switch (subTab)
        {
            case 0: RefreshAchievementUI(); break;
            case 1: RefreshMissionUI();     break;
            case 2: RefreshCollectionUI();  break;
            case 3: RefreshArenaUI();       break;
            case 4: RefreshQuestUI();       break;
            case 5: RefreshFriendUI();      break;
        }
    }

    public void Refresh()
    {
        UpdateSubTabVisuals();
        RefreshCurrentSubTab();
    }

    // ════════════════════════════════════════
    // 업적 리스트
    // ════════════════════════════════════════

    void BuildAchievementList(Transform parent)
    {
        // 일괄 수령 버튼
        var (claimAllBtn, _) = UIHelper.MakeSpriteButton("ClaimAllBtn", parent,
            UISprites.Btn2_WS, UIColors.Button_Green, "", UIConstants.Font_SmallInfo);
        claimAllBtn.onClick.AddListener(OnClaimAllAchievements);
        var cbrt = claimAllBtn.GetComponent<RectTransform>();
        cbrt.anchorMin = new Vector2(0.05f, 0.92f);
        cbrt.anchorMax = new Vector2(0.95f, 0.99f);
        cbrt.offsetMin = cbrt.offsetMax = Vector2.zero;
        var cbLabel = UIHelper.MakeText("Label", claimAllBtn.transform, "전부 수령",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, Color.white);
        cbLabel.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(cbLabel.GetComponent<RectTransform>());

        var scrollObj = UIHelper.MakeUI("AchieveScroll", parent);
        var scrollRT = scrollObj.GetComponent<RectTransform>();
        scrollRT.anchorMin = Vector2.zero; scrollRT.anchorMax = Vector2.one;
        scrollRT.offsetMin = new Vector2(UIConstants.Spacing_Small, UIConstants.Spacing_Small);
        scrollRT.offsetMax = new Vector2(-UIConstants.Spacing_Small, -0.08f);

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

        UIListPool.RecycleList(achieveListItems);
        int reuse = 0;
        var achievements = am.GetAchievements();
        float itemH = 42f, spacing = 2f, y = 0;
        int active = 0;

        for (int i = 0; i < achievements.Count; i++)
        {
            var ach = achievements[i];
            Color bgColor = ach.claimed ? UIColors.ListItem_Claimed :
                            ach.completed ? UIColors.ListItem_Completed : UIColors.ListItem_Normal;

            var item = UIListPool.ReuseOrCreate(achieveListItems, ref reuse, $"Ach_{i}", achieveListContainer.transform, bgColor);
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
            Sprite btnSprite; Color btnFallback;
            if (ach.claimed)        { btnLabel = "완료";  btnSprite = UISprites.Btn1_WS; btnFallback = UIColors.Button_Gray; }
            else if (ach.completed) { btnLabel = "수령";  btnSprite = UISprites.Btn3_WS; btnFallback = UIColors.Button_Yellow; }
            else                    { btnLabel = "미달성"; btnSprite = UISprites.Btn1_WS; btnFallback = UIColors.Button_Gray; }

            var (btn, achBtnImg) = UIHelper.MakeSpriteButton($"AchBtn_{i}", item.transform, btnSprite, btnFallback, "", 10f);
            if (ach.claimed && achBtnImg.sprite != null) achBtnImg.color = UIColors.Button_Disabled;
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

        UIListPool.TrimExcess(achieveListItems, active);
        achieveListContainer.GetComponent<RectTransform>().sizeDelta = new Vector2(0, Mathf.Abs(y));
    }

    void OnClaimAllAchievements()
    {
        var am = AchievementManager.Instance;
        if (am == null) return;
        var achievements = am.GetAchievements();
        int claimedCount = 0;
        for (int i = 0; i < achievements.Count; i++)
        {
            var ach = achievements[i];
            if (ach.completed && !ach.claimed)
            {
                am.ClaimReward(ach.id);
                claimedCount++;
            }
        }
        if (claimedCount > 0)
        {
            ToastNotification.Instance?.Show("전부 수령!", $"보상 {claimedCount}개 수령", UIColors.Text_Gold);
            SoundManager.Instance?.PlayGoldSFX();
            RefreshAchievementUI();
        }
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

        UIListPool.RecycleList(missionListItems);
        int reuse = 0;
        var missions = mm.GetMissions();
        float itemH = 42f, spacing = 2f, y = 0;
        int active = 0;

        for (int i = 0; i < missions.Count; i++)
        {
            var mission = missions[i];
            bool completed = mission.currentCount >= mission.targetCount;
            Color bgColor = mission.claimed ? UIColors.ListItem_Claimed :
                            completed ? UIColors.ListItem_Completed : UIColors.ListItem_Normal;

            var item = UIListPool.ReuseOrCreate(missionListItems, ref reuse, $"Mission_{i}", missionListContainer.transform, bgColor);
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
            if (mission.claimed)  { btnLabel = "완료";  mBtnSprite = UISprites.Btn1_WS; mBtnFallback = UIColors.Button_Gray; }
            else if (completed)   { btnLabel = "수령";  mBtnSprite = UISprites.Btn3_WS; mBtnFallback = UIColors.Button_Yellow; }
            else                  { btnLabel = "진행중"; mBtnSprite = UISprites.Btn1_WS; mBtnFallback = UIColors.Button_Gray; }

            var (btn, mBtnImg) = UIHelper.MakeSpriteButton($"MissionBtn_{i}", item.transform, mBtnSprite, mBtnFallback, "", 10f);
            if (mission.claimed && mBtnImg.sprite != null) mBtnImg.color = UIColors.Button_Disabled;
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

        UIListPool.TrimExcess(missionListItems, active);
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
                img.color = am.CanBattle ? Color.white : UIColors.Button_Disabled;
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
    // 퀘스트 (일일 퀘스트 + 주간 보스)
    // ════════════════════════════════════════

    void BuildQuestContent(Transform parent)
    {
        float pad = UIConstants.Spacing_Medium;

        // ── 일일 퀘스트 헤더 ──
        var headerContainer = UIHelper.MakeUI("QuestHeaderRow", parent);
        var hcrt = headerContainer.GetComponent<RectTransform>();
        hcrt.anchorMin = new Vector2(0, 0.80f); hcrt.anchorMax = new Vector2(1, 0.90f);
        hcrt.offsetMin = hcrt.offsetMax = Vector2.zero;

        var header = UIHelper.MakeText("QuestHeader", headerContainer.transform, "일일 퀘스트",
            UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, UIColors.Text_Gold);
        header.fontStyle = FontStyles.Bold;
        var hrt = header.GetComponent<RectTransform>();
        hrt.anchorMin = Vector2.zero; hrt.anchorMax = new Vector2(0.5f, 1);
        hrt.offsetMin = new Vector2(pad, 0); hrt.offsetMax = Vector2.zero;

        var (claimQuestBtn, _) = UIHelper.MakeSpriteButton("ClaimQuestBtn", headerContainer.transform,
            UISprites.Btn2_WS, UIColors.Button_Green, "", UIConstants.Font_SmallInfo);
        claimQuestBtn.onClick.AddListener(OnClaimAllQuests);
        var cqrt = claimQuestBtn.GetComponent<RectTransform>();
        cqrt.anchorMin = new Vector2(0.5f, 0.1f); cqrt.anchorMax = new Vector2(1, 0.9f);
        cqrt.offsetMin = new Vector2(2, 0); cqrt.offsetMax = new Vector2(-pad, 0);
        var cqLabel = UIHelper.MakeText("Label", claimQuestBtn.transform, "전부 수령",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, Color.white);
        cqLabel.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(cqLabel.GetComponent<RectTransform>());

        // ── 퀘스트 리스트 컨테이너 ──
        questListContainer = UIHelper.MakeUI("QuestList", parent);
        var clrt = questListContainer.GetComponent<RectTransform>();
        clrt.anchorMin = new Vector2(0, 0.52f); clrt.anchorMax = new Vector2(1, 0.80f);
        clrt.offsetMin = new Vector2(pad, 0); clrt.offsetMax = new Vector2(-pad, 0);

        // ── 주간 보스 섹션 ──
        var bossHeader = UIHelper.MakeText("BossHeader", parent, "주간 보스",
            UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, UIColors.Defeat_Red);
        bossHeader.fontStyle = FontStyles.Bold;
        var bhrt = bossHeader.GetComponent<RectTransform>();
        bhrt.anchorMin = new Vector2(0, 0.42f); bhrt.anchorMax = new Vector2(1, 0.51f);
        bhrt.offsetMin = new Vector2(pad, 0); bhrt.offsetMax = Vector2.zero;

        weeklyBossInfoText = UIHelper.MakeText("BossInfo", parent, "",
            UIConstants.Font_StatValue, TextAlignmentOptions.MidlineLeft, UIColors.Text_Dark);
        var birt = weeklyBossInfoText.GetComponent<RectTransform>();
        birt.anchorMin = new Vector2(0, 0.28f); birt.anchorMax = new Vector2(1, 0.42f);
        birt.offsetMin = new Vector2(pad, 0); birt.offsetMax = new Vector2(-pad, 0);

        var (wbBtn, _) = UIHelper.MakeSpriteButton("WeeklyBossBtn", parent,
            UISprites.Btn2_WS, UIColors.Defeat_Red, "", UIConstants.Font_Button);
        weeklyBossBattleBtn = wbBtn;
        var wbrt = wbBtn.GetComponent<RectTransform>();
        wbrt.anchorMin = new Vector2(0.15f, 0.10f); wbrt.anchorMax = new Vector2(0.85f, 0.24f);
        wbrt.offsetMin = Vector2.zero; wbrt.offsetMax = Vector2.zero;
        var wbLabel = UIHelper.MakeText("Label", wbBtn.transform, "보스 도전!",
            UIConstants.Font_Button, TextAlignmentOptions.Center, Color.white);
        wbLabel.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(wbLabel);
        UIHelper.FillParent(wbLabel.GetComponent<RectTransform>());
        wbBtn.onClick.AddListener(OnWeeklyBossBattle);
    }

    void RefreshQuestUI()
    {
        // 일일 퀘스트 리스트
        if (questListContainer != null)
        {
            UIListPool.RecycleList(questListItems);
            int reuse = 0;
            var qm = DailyQuestManager.Instance;
            if (qm != null)
            {
                var quests = qm.GetQuests();
                float itemH = 28f, spacing = 2f;
                float totalH = questListContainer.GetComponent<RectTransform>().rect.height;
                float y = 0;
                int active = 0;

                for (int i = 0; i < quests.Count; i++)
                {
                    var q = quests[i];
                    bool done = q.currentCount >= q.targetCount;
                    Color bg = q.claimed ? UIColors.ListItem_Claimed :
                               done ? UIColors.ListItem_Completed : UIColors.ListItem_Normal;

                    var item = UIListPool.ReuseOrCreate(questListItems, ref reuse, $"Q_{i}", questListContainer.transform, bg);
                    active++;
                    var irt = item.GetComponent<RectTransform>();
                    irt.anchorMin = new Vector2(0, 1); irt.anchorMax = new Vector2(1, 1);
                    irt.pivot = new Vector2(0.5f, 1);
                    irt.anchoredPosition = new Vector2(0, y);
                    irt.sizeDelta = new Vector2(0, itemH);

                    string rewardLabel = q.rewardType switch {
                        DailyQuestManager.RewardType.Gold   => $"골드 {q.rewardAmount}",
                        DailyQuestManager.RewardType.Gem    => $"보석 {q.rewardAmount}",
                        DailyQuestManager.RewardType.Scroll => $"주문서 {q.rewardAmount}",
                        _ => ""
                    };

                    var nameT = UIHelper.MakeText("Name", item.transform, q.name,
                        UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft,
                        done ? UIColors.Text_Dark : UIColors.Text_Disabled);
                    var nrt = nameT.GetComponent<RectTransform>();
                    nrt.anchorMin = new Vector2(0, 0); nrt.anchorMax = new Vector2(0.40f, 1);
                    nrt.offsetMin = new Vector2(4, 0); nrt.offsetMax = Vector2.zero;

                    var progT = UIHelper.MakeText("Prog", item.transform,
                        $"{q.currentCount}/{q.targetCount}",
                        9f, TextAlignmentOptions.Center,
                        done ? UIColors.Text_DarkGreen : UIColors.Text_DarkSecondary);
                    var prt = progT.GetComponent<RectTransform>();
                    prt.anchorMin = new Vector2(0.40f, 0); prt.anchorMax = new Vector2(0.60f, 1);
                    prt.offsetMin = prt.offsetMax = Vector2.zero;

                    var rewT = UIHelper.MakeText("Rew", item.transform, rewardLabel,
                        9f, TextAlignmentOptions.Center, UIColors.Text_DarkDiamond);
                    var rrt = rewT.GetComponent<RectTransform>();
                    rrt.anchorMin = new Vector2(0.60f, 0); rrt.anchorMax = new Vector2(0.76f, 1);
                    rrt.offsetMin = rrt.offsetMax = Vector2.zero;

                    string btnLbl; Sprite btnSpr; Color btnCol;
                    if (q.claimed)   { btnLbl = "완료"; btnSpr = UISprites.Btn1_WS; btnCol = UIColors.Button_Gray; }
                    else if (done)   { btnLbl = "수령"; btnSpr = UISprites.Btn3_WS; btnCol = UIColors.Button_Yellow; }
                    else             { btnLbl = "진행"; btnSpr = UISprites.Btn1_WS; btnCol = UIColors.Button_Gray; }

                    var (btn, _) = UIHelper.MakeSpriteButton($"QBtn_{i}", item.transform, btnSpr, btnCol, "", 9f);
                    var brt = btn.GetComponent<RectTransform>();
                    brt.anchorMin = new Vector2(0.78f, 0.1f); brt.anchorMax = new Vector2(0.98f, 0.9f);
                    brt.offsetMin = brt.offsetMax = Vector2.zero;
                    var btnT = UIHelper.MakeText("L", btn.transform, btnLbl,
                        UIConstants.Font_Cost, TextAlignmentOptions.Center,
                        done && !q.claimed ? new Color(0.25f, 0.15f, 0.08f) : UIColors.Text_Disabled);
                    btnT.fontStyle = FontStyles.Bold;
                    UIHelper.FillParent(btnT.GetComponent<RectTransform>());

                    if (done && !q.claimed)
                    {
                        string capturedId = q.id;
                        btn.onClick.AddListener(() =>
                        {
                            qm.ClaimReward(capturedId);
                            SoundManager.Instance?.PlayGoldSFX();
                            ToastNotification.Instance?.Show("퀘스트 완료!", "", UIColors.Text_Diamond);
                            RefreshQuestUI();
                        });
                    }
                    y -= (itemH + spacing);
                }
                UIListPool.TrimExcess(questListItems, active);
            }
        }

        // 주간 보스
        if (weeklyBossInfoText != null)
        {
            var wbm = WeeklyBossManager.Instance;
            if (wbm == null) { weeklyBossInfoText.text = "로딩 중..."; return; }

            var (awake, gem) = wbm.GetRewardPreview();
            weeklyBossInfoText.text =
                $"<b>{wbm.GetBossName()}</b>\n" +
                $"HP: {wbm.GetBossHP():N0}  보상: 각성석 {awake} + 보석 {gem}\n" +
                (wbm.IsDefeated ? "<color=#7FD44C>이번 주 격파 완료!</color>" :
                 wbm.CanAttempt ? "도전 가능!" : "이번 주 도전 완료");

            if (weeklyBossBattleBtn != null)
            {
                weeklyBossBattleBtn.interactable = wbm.CanAttempt;
                var img = weeklyBossBattleBtn.GetComponent<UnityEngine.UI.Image>();
                img.color = wbm.CanAttempt ? Color.white : new Color(0.6f, 0.6f, 0.6f);
            }
        }
    }

    void OnWeeklyBossBattle()
    {
        var wbm = WeeklyBossManager.Instance;
        if (wbm == null || !wbm.CanAttempt) return;

        SoundManager.Instance?.PlayButtonSFX();
        bool won = wbm.AttemptBoss();
        if (!won)
            ToastNotification.Instance?.Show("패배...", "다음 주에 다시 도전하세요", UIColors.Defeat_Red);
        RefreshQuestUI();
    }

    void OnClaimAllQuests()
    {
        var qm = DailyQuestManager.Instance;
        if (qm == null) return;
        var quests = qm.GetQuests();
        int claimedCount = 0;
        for (int i = 0; i < quests.Count; i++)
        {
            var q = quests[i];
            if (q.currentCount >= q.targetCount && !q.claimed)
            {
                qm.ClaimReward(q.id);
                claimedCount++;
            }
        }
        if (claimedCount > 0)
        {
            ToastNotification.Instance?.Show("전부 수령!", $"보상 {claimedCount}개 수령", UIColors.Text_Gold);
            SoundManager.Instance?.PlayGoldSFX();
            RefreshQuestUI();
        }
    }

    // ════════════════════════════════════════
    // 친구 시스템
    // ════════════════════════════════════════

    void BuildFriendContent(Transform parent)
    {
        float pad = UIConstants.Spacing_Medium;

        var header = UIHelper.MakeText("FriendHeader", parent, "친구 목록",
            UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, UIColors.Text_Gold);
        header.fontStyle = FontStyles.Bold;
        var hrt = header.GetComponent<RectTransform>();
        hrt.anchorMin = new Vector2(0, 0.88f); hrt.anchorMax = new Vector2(1, 0.97f);
        hrt.offsetMin = new Vector2(pad, 0); hrt.offsetMax = Vector2.zero;

        friendInfoText = UIHelper.MakeText("FriendInfo", parent, "",
            UIConstants.Font_StatValue, TextAlignmentOptions.TopLeft, UIColors.Text_Dark);
        var irt = friendInfoText.GetComponent<RectTransform>();
        irt.anchorMin = new Vector2(0, 0.50f); irt.anchorMax = new Vector2(1, 0.87f);
        irt.offsetMin = new Vector2(pad, 0); irt.offsetMax = new Vector2(-pad, 0);

        // 일일 선물 버튼
        var (giftBtn, _) = UIHelper.MakeSpriteButton("GiftBtn", parent,
            UISprites.Btn3_WS, UIColors.Button_Yellow, "", UIConstants.Font_SmallInfo);
        friendGiftBtn = giftBtn;
        var grt = giftBtn.GetComponent<RectTransform>();
        grt.anchorMin = new Vector2(0.05f, 0.34f); grt.anchorMax = new Vector2(0.48f, 0.46f);
        grt.offsetMin = grt.offsetMax = Vector2.zero;
        var gLabel = UIHelper.MakeText("Label", giftBtn.transform, $"선물 수령 (+{FriendManager.DAILY_GIFT_GOLD}골드)",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, new Color(0.25f, 0.15f, 0.08f));
        gLabel.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(gLabel.GetComponent<RectTransform>());
        giftBtn.onClick.AddListener(OnFriendGift);

        // 원군 요청 버튼
        var (reinfBtn, _2) = UIHelper.MakeSpriteButton("ReinfBtn", parent,
            UISprites.Btn2_WS, UIColors.Button_Blue, "", UIConstants.Font_SmallInfo);
        friendReinfBtn = reinfBtn;
        var rrt = reinfBtn.GetComponent<RectTransform>();
        rrt.anchorMin = new Vector2(0.52f, 0.34f); rrt.anchorMax = new Vector2(0.95f, 0.46f);
        rrt.offsetMin = rrt.offsetMax = Vector2.zero;
        var rLabel = UIHelper.MakeText("Label", reinfBtn.transform, "원군 요청 (30초)",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, Color.white);
        rLabel.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(rLabel.GetComponent<RectTransform>());
        reinfBtn.onClick.AddListener(OnFriendReinforcement);
    }

    void RefreshFriendUI()
    {
        var fm = FriendManager.Instance;
        if (friendInfoText == null || fm == null) return;

        var friends = fm.GetFriends();
        var sb = new System.Text.StringBuilder();
        for (int i = 0; i < friends.Count; i++)
        {
            var f = friends[i];
            sb.AppendLine($"  {f.name}  <color=#87CEEB>Lv.{f.level}</color>  [{f.heroPresetName.Replace("Ally_", "")}]");
        }
        friendInfoText.text = sb.ToString();

        if (friendGiftBtn != null)
        {
            friendGiftBtn.interactable = fm.CanClaimGift;
            var img = friendGiftBtn.GetComponent<UnityEngine.UI.Image>();
            if (img.sprite != null)
                img.color = fm.CanClaimGift ? Color.white : new Color(0.6f, 0.6f, 0.6f);
            else
                img.color = fm.CanClaimGift ? UIColors.Button_Yellow : UIColors.Button_Gray;
        }
        if (friendReinfBtn != null)
        {
            friendReinfBtn.interactable = fm.CanCallReinforcement;
            var img = friendReinfBtn.GetComponent<UnityEngine.UI.Image>();
            if (img.sprite != null)
                img.color = fm.CanCallReinforcement ? Color.white : new Color(0.6f, 0.6f, 0.6f);
            else
                img.color = fm.CanCallReinforcement ? UIColors.Button_Blue : UIColors.Button_Gray;
        }
    }

    void OnFriendGift()
    {
        SoundManager.Instance?.PlayGoldSFX();
        FriendManager.Instance?.ClaimDailyGift();
        RefreshFriendUI();
    }

    void OnFriendReinforcement()
    {
        var fm = FriendManager.Instance;
        if (fm == null || !fm.CanCallReinforcement)
        {
            ToastNotification.Instance?.Show("원군 불가", "오늘 이미 요청했습니다", UIColors.Button_Gray);
            return;
        }
        SoundManager.Instance?.PlayButtonSFX();
        fm.RequestReinforcement();
        RefreshFriendUI();
    }

    // ════════════════════════════════════════
    // 미수령 보상 카운트 (메인HUD 배지용)
    // ════════════════════════════════════════

    public int GetUnclaimedRewardCount()
    {
        int count = 0;
        var am = AchievementManager.Instance;
        if (am != null)
        {
            var achs = am.GetAchievements();
            for (int i = 0; i < achs.Count; i++)
                if (achs[i].completed && !achs[i].claimed) count++;
        }
        var mm = DailyMissionManager.Instance;
        if (mm != null)
        {
            var missions = mm.GetMissions();
            for (int i = 0; i < missions.Count; i++)
                if (missions[i].currentCount >= missions[i].targetCount && !missions[i].claimed)
                    count++;
        }
        var qm = DailyQuestManager.Instance;
        if (qm != null)
        {
            var quests = qm.GetQuests();
            for (int i = 0; i < quests.Count; i++)
                if (quests[i].currentCount >= quests[i].targetCount && !quests[i].claimed)
                    count++;
        }
        return count;
    }

    // ════════════════════════════════════════
    void OnDestroy()
    {
        if (subTabBtns != null)
        {
            for (int i = 0; i < subTabBtns.Length; i++)
                if (subTabBtns[i] != null)
                    subTabBtns[i].onClick.RemoveAllListeners();
        }
        if (arenaBattleBtn != null)
            arenaBattleBtn.onClick.RemoveListener(OnArenaBattle);
    }
}
