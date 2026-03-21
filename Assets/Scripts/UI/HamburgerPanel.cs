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
    int subTab; // 0=업적 1=미션 2=도감 3=아레나 4=설정
    Button[] subTabBtns;
    TextMeshProUGUI[] subTabLabels;
    GameObject achieveRoot, missionRoot, collectionRoot, arenaRoot, settingsRoot;

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

        float subTabH = 30f;
        var subTabBarBg = UIHelper.MakeSpritePanel("SubTabBar", content.transform,
            UISprites.Board, UIColors.Background_Dark);
        var stbRT = subTabBarBg.GetComponent<RectTransform>();
        stbRT.anchorMin = new Vector2(0, 1);
        stbRT.anchorMax = new Vector2(1, 1);
        stbRT.pivot = new Vector2(0.5f, 1);
        stbRT.sizeDelta = new Vector2(0, subTabH);

        string[] subNames = { "업적", "미션", "도감", "아레나", "설정" };
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

            var label = UIHelper.MakeText("Label", btn.transform, subNames[s],
                9f, TextAlignmentOptions.Center, UIColors.Text_Secondary);
            label.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(label.GetComponent<RectTransform>());

            subTabBtns[s]   = btn;
            subTabLabels[s] = label;

            int captured = s;
            btn.onClick.AddListener(() => SwitchSubTab(captured));
        }

        achieveRoot    = MakeSubRoot("AchieveRoot",    content.transform, subTabH);
        missionRoot    = MakeSubRoot("MissionRoot",    content.transform, subTabH);
        collectionRoot = MakeSubRoot("CollectionRoot", content.transform, subTabH);
        arenaRoot      = MakeSubRoot("ArenaRoot",      content.transform, subTabH);
        settingsRoot   = MakeSubRoot("SettingsRoot",   content.transform, subTabH);

        BuildAchievementList(achieveRoot.transform);
        BuildMissionList(missionRoot.transform);
        BuildCollectionContent(collectionRoot.transform);
        BuildArenaContent(arenaRoot.transform);
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
        if (settingsRoot   != null) settingsRoot.SetActive(subTab == 4);
    }

    void RefreshCurrentSubTab()
    {
        switch (subTab)
        {
            case 0: RefreshAchievementUI(); break;
            case 1: RefreshMissionUI();     break;
            case 2: RefreshCollectionUI();  break;
            case 3: RefreshArenaUI();       break;
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
            Color bgColor = ach.claimed ? UIColors.ListItem_Claimed :
                            ach.completed ? UIColors.ListItem_Completed : UIColors.ListItem_Normal;

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
            Sprite btnSprite; Color btnFallback;
            if (ach.claimed)        { btnLabel = "완료";  btnSprite = UISprites.Btn1_WS; btnFallback = UIColors.Button_Gray; }
            else if (ach.completed) { btnLabel = "수령";  btnSprite = UISprites.Btn3_WS; btnFallback = UIColors.Button_Yellow; }
            else                    { btnLabel = "미달성"; btnSprite = UISprites.Btn1_WS; btnFallback = UIColors.Button_Gray; }

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
            Color bgColor = mission.claimed ? UIColors.ListItem_Claimed :
                            completed ? UIColors.ListItem_Completed : UIColors.ListItem_Normal;

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
            if (mission.claimed)  { btnLabel = "완료";  mBtnSprite = UISprites.Btn1_WS; mBtnFallback = UIColors.Button_Gray; }
            else if (completed)   { btnLabel = "수령";  mBtnSprite = UISprites.Btn3_WS; mBtnFallback = UIColors.Button_Yellow; }
            else                  { btnLabel = "진행중"; mBtnSprite = UISprites.Btn1_WS; mBtnFallback = UIColors.Button_Gray; }

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
        return count;
    }

    // ════════════════════════════════════════
    // 리스트 관리 유틸
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
