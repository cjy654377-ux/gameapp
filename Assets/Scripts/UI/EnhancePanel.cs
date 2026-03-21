using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections.Generic;

/// <summary>
/// 영웅 패널: 편성 / 레벨업 / 장비 / 각성 서브탭
/// MainHUD 영웅 탭(index 0)에서 Init(parent, showHeroSelect)로 초기화
/// </summary>
public class EnhancePanel : MonoBehaviour
{
    int subTab; // 0=편성, 1=레벨업, 2=장비, 3=각성
    Button[] subTabBtns;
    TextMeshProUGUI[] subTabLabels;
    readonly GameObject[] subTabBadges = new GameObject[4];
    GameObject deckRoot;
    GameObject heroRoot;
    GameObject equipRoot;
    GameObject awakeningRoot;
    AwakeningPanel awakeningPanel;

    GameObject heroListContainer;
    readonly List<GameObject> heroListItems = new();

    GameObject equipListContainer;
    readonly List<GameObject> equipListItems = new();
    TextMeshProUGUI equipInfoText;

    System.Action<string> showHeroSelect;
    string _lastFailedEnhId;

    // ════════════════════════════════════════
    // 초기화
    // ════════════════════════════════════════

    public void Init(Transform parent, System.Action<string> showHeroSelectCallback)
    {
        showHeroSelect = showHeroSelectCallback;

        var content = UIHelper.MakeUI("EnhanceContent", parent);
        var contentRT = content.GetComponent<RectTransform>();
        contentRT.anchorMin = Vector2.zero;
        contentRT.anchorMax = Vector2.one;
        contentRT.offsetMin = Vector2.zero;
        contentRT.offsetMax = new Vector2(0, -UIConstants.Tab_Height);

        // 서브탭 바
        float subTabH = 30f;
        var subTabBarBg = UIHelper.MakeSpritePanel("SubTabBar", content.transform,
            UISprites.Board, UIColors.Background_Dark);
        var stbRT = subTabBarBg.GetComponent<RectTransform>();
        stbRT.anchorMin = new Vector2(0, 1);
        stbRT.anchorMax = new Vector2(1, 1);
        stbRT.pivot = new Vector2(0.5f, 1);
        stbRT.sizeDelta = new Vector2(0, subTabH);

        string[] subNames = { "편성", "레벨업", "장비", "각성" };
        subTabBtns   = new Button[4];
        subTabLabels = new TextMeshProUGUI[4];

        for (int s = 0; s < 4; s++)
        {
            float xMin = s * 0.25f;
            float xMax = (s + 1) * 0.25f;
            var (btn, btnImg) = UIHelper.MakeSpriteButton($"SubTab_{subNames[s]}", subTabBarBg.transform,
                UISprites.Btn1_WS, UIColors.Tab_Inactive, "", 0);
            if (UISprites.Btn1_WS != null) btnImg.color = Color.white;
            var brt = btn.GetComponent<RectTransform>();
            brt.anchorMin = new Vector2(xMin, 0);
            brt.anchorMax = new Vector2(xMax, 1);
            brt.offsetMin = new Vector2(3, 3);
            brt.offsetMax = new Vector2(-3, -3);

            var label = UIHelper.MakeText("Label", btn.transform, subNames[s],
                UIConstants.Font_Tab, TextAlignmentOptions.Center, UIColors.Text_Secondary);
            label.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(label.GetComponent<RectTransform>());

            subTabBtns[s]   = btn;
            subTabLabels[s] = label;

            // 뱃지 점
            var badge = UIHelper.MakeUI($"Badge_{s}", btn.transform);
            var badgeImg = badge.AddComponent<Image>();
            badgeImg.color = UIColors.Badge_Red;
            var badgeRT = badge.GetComponent<RectTransform>();
            badgeRT.anchorMin = new Vector2(1f, 1f);
            badgeRT.anchorMax = new Vector2(1f, 1f);
            badgeRT.pivot     = new Vector2(1f, 1f);
            badgeRT.anchoredPosition = new Vector2(-2f, -2f);
            badgeRT.sizeDelta = new Vector2(10f, 10f);
            badge.SetActive(false);
            subTabBadges[s] = badge;

            int captured = s;
            btn.onClick.AddListener(() => SwitchSubTab(captured));
        }

        // 편성 루트 (DeckUI)
        deckRoot = UIHelper.MakeUI("DeckRoot", content.transform);
        var deckRT = deckRoot.GetComponent<RectTransform>();
        deckRT.anchorMin = Vector2.zero;
        deckRT.anchorMax = new Vector2(1, 1);
        deckRT.offsetMin = Vector2.zero;
        deckRT.offsetMax = new Vector2(0, -subTabH);
        var deckUI = deckRoot.AddComponent<DeckUI>();
        deckUI.Init(deckRoot.transform);

        // 레벨업 루트
        heroRoot = UIHelper.MakeUI("HeroRoot", content.transform);
        var heroRT = heroRoot.GetComponent<RectTransform>();
        heroRT.anchorMin = Vector2.zero;
        heroRT.anchorMax = new Vector2(1, 1);
        heroRT.offsetMin = Vector2.zero;
        heroRT.offsetMax = new Vector2(0, -subTabH);
        BuildHeroContent(heroRoot.transform);
        heroRoot.SetActive(false);

        // 장비 루트
        equipRoot = UIHelper.MakeUI("EquipRoot", content.transform);
        var equipRT = equipRoot.GetComponent<RectTransform>();
        equipRT.anchorMin = Vector2.zero;
        equipRT.anchorMax = new Vector2(1, 1);
        equipRT.offsetMin = Vector2.zero;
        equipRT.offsetMax = new Vector2(0, -subTabH);
        BuildEquipmentContent(equipRoot.transform);
        equipRoot.SetActive(false);

        // 각성 루트
        awakeningRoot = UIHelper.MakeUI("AwakeningRoot", content.transform);
        var awakRT = awakeningRoot.GetComponent<RectTransform>();
        awakRT.anchorMin = Vector2.zero;
        awakRT.anchorMax = new Vector2(1, 1);
        awakRT.offsetMin = Vector2.zero;
        awakRT.offsetMax = new Vector2(0, -subTabH);
        awakeningPanel = awakeningRoot.AddComponent<AwakeningPanel>();
        awakeningPanel.Init(awakeningRoot.transform);
        awakeningRoot.SetActive(false);

        subTab = 0;
        UpdateSubTabVisuals();
    }

    // ════════════════════════════════════════
    // 서브탭 전환
    // ════════════════════════════════════════

    void SwitchSubTab(int subIdx)
    {
        SoundManager.Instance?.PlayButtonSFX();
        subTab = subIdx;
        UpdateSubTabVisuals();
        switch (subIdx)
        {
            case 1: RefreshHeroUI();       break;
            case 2: RefreshEquipmentUI();  break;
            case 3: awakeningPanel?.Refresh(); break;
        }
    }

    void RefreshSubTabBadges()
    {
        var nbs = NotificationBadgeSystem.Instance;
        if (nbs == null) return;
        for (int i = 0; i < 4; i++)
        {
            if (subTabBadges[i] != null)
                subTabBadges[i].SetActive(nbs.GetHeroSubTabBadge(i));
        }
    }

    void UpdateSubTabVisuals()
    {
        if (subTabBtns == null) return;
        for (int i = 0; i < 4; i++)
        {
            bool active = (i == subTab);
            var img = subTabBtns[i].GetComponent<Image>();
            img.color = active ? UIColors.Tab_Active : UIColors.Tab_Inactive;
            subTabLabels[i].color = active ? UIColors.Text_Gold : UIColors.Text_TabInactive;
            subTabLabels[i].fontStyle = active ? FontStyles.Bold : FontStyles.Normal;
        }
        RefreshSubTabBadges();
        if (deckRoot      != null) deckRoot.SetActive(subTab == 0);
        if (heroRoot      != null) heroRoot.SetActive(subTab == 1);
        if (equipRoot     != null) equipRoot.SetActive(subTab == 2);
        if (awakeningRoot != null) awakeningRoot.SetActive(subTab == 3);
    }

    public void Refresh()
    {
        UpdateSubTabVisuals();
        switch (subTab)
        {
            case 1: RefreshHeroUI();       break;
            case 2: RefreshEquipmentUI();  break;
            case 3: awakeningPanel?.Refresh(); break;
        }
    }

    // ════════════════════════════════════════
    // 레벨업 서브탭
    // ════════════════════════════════════════

    void BuildHeroContent(Transform parent)
    {
        var content = UIHelper.MakeUI("HeroContent", parent);
        var contentRT = content.GetComponent<RectTransform>();
        contentRT.anchorMin = new Vector2(0, 0);
        contentRT.anchorMax = new Vector2(1, 1);
        contentRT.offsetMin = new Vector2(UIConstants.Spacing_Small, UIConstants.Spacing_Small);
        contentRT.offsetMax = new Vector2(-UIConstants.Spacing_Small, -UIConstants.Tab_Height);

        var scrollObj = UIHelper.MakeUI("HeroScroll", content.transform);
        UIHelper.FillParent(scrollObj.GetComponent<RectTransform>());

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
                $"Hero_{heroName}", heroListContainer.transform, new Color(0.92f, 0.88f, 0.82f));
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

            var nameText = UIHelper.MakeText("Name", item.transform, heroName,
                UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, UIColors.Text_Dark);
            nameText.fontStyle = FontStyles.Bold;
            var nrt = nameText.GetComponent<RectTransform>();
            nrt.anchorMin = new Vector2(0, 0.5f);
            nrt.anchorMax = new Vector2(0.3f, 1);
            nrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
            nrt.offsetMax = Vector2.zero;

            int star = hlm != null ? hlm.GetStarRank(heroName) : 1;
            string starStr = new string('\u2605', star);
            var lvText = UIHelper.MakeText("Lv", item.transform, $"Lv.{level} {starStr}",
                UIConstants.Font_SmallInfo, TextAlignmentOptions.MidlineLeft, UIColors.Text_DarkGold);
            lvText.fontStyle = FontStyles.Bold;
            var lvrt = lvText.GetComponent<RectTransform>();
            lvrt.anchorMin = new Vector2(0, 0);
            lvrt.anchorMax = new Vector2(0.3f, 0.5f);
            lvrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
            lvrt.offsetMax = Vector2.zero;

            var copyText = UIHelper.MakeText("Copies", item.transform, $"카드: {copies}/{needed}",
                9f, TextAlignmentOptions.Center, copies >= needed ? UIColors.Text_DarkGreen : UIColors.Text_DarkSecondary);
            var cprt = copyText.GetComponent<RectTransform>();
            cprt.anchorMin = new Vector2(0.32f, 0);
            cprt.anchorMax = new Vector2(0.65f, 1);
            cprt.offsetMin = Vector2.zero;
            cprt.offsetMax = Vector2.zero;

            bool canLevelUp = hlm != null && copies >= needed && level < HeroLevelManager.MAX_LEVEL;
            string btnLabel = level >= HeroLevelManager.MAX_LEVEL ? "MAX" : "강화";
            Color btnColor = canLevelUp ? UIColors.Button_Green : UIColors.Button_Gray;

            Sprite heroBtnSprite = canLevelUp ? UISprites.Btn2_WS : UISprites.Btn1_WS;
            var (btn, heroBtnImg) = UIHelper.MakeSpriteButton($"LvUp_{heroName}", item.transform,
                heroBtnSprite, btnColor, "", 10f);
            if (!canLevelUp && heroBtnImg.sprite != null) heroBtnImg.color = new Color(0.70f, 0.70f, 0.70f);
            var btnRT = btn.GetComponent<RectTransform>();
            btnRT.anchorMin = new Vector2(0.68f, 0.1f);
            btnRT.anchorMax = new Vector2(0.97f, 0.9f);
            btnRT.offsetMin = Vector2.zero;
            btnRT.offsetMax = Vector2.zero;

            var btnText = UIHelper.MakeText("Label", btn.transform, btnLabel,
                UIConstants.Font_Cost, TextAlignmentOptions.Center,
                canLevelUp ? Color.white : UIColors.Text_Disabled);
            btnText.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(btnText.GetComponent<RectTransform>());

            if (canLevelUp)
            {
                string capturedName = heroName;
                btn.onClick.AddListener(() =>
                {
                    if (HeroLevelManager.Instance != null)
                    {
                        if (HeroLevelManager.Instance.TryLevelUp(capturedName))
                            SoundManager.Instance?.PlayUISound(UISoundType.levelup);
                        RefreshHeroUI();
                    }
                });
                // 꾹 누르기: 10회 연속 강화
                AddLongPressUpgrade(btn.gameObject, capturedName, 10);
            }

            y -= (itemH + spacing);
        }

        TrimExcess(heroListItems, activeHeroCount);
        var containerRT = heroListContainer.GetComponent<RectTransform>();
        containerRT.sizeDelta = new Vector2(0, Mathf.Abs(y));
    }

    // ════════════════════════════════════════
    // 장비 서브탭
    // ════════════════════════════════════════

    void BuildEquipmentContent(Transform parent)
    {
        var content = UIHelper.MakeUI("EquipContent", parent);
        var contentRT = content.GetComponent<RectTransform>();
        contentRT.anchorMin = new Vector2(0, 0);
        contentRT.anchorMax = new Vector2(1, 1);
        contentRT.offsetMin = new Vector2(UIConstants.Spacing_Small, UIConstants.Spacing_Small);
        contentRT.offsetMax = new Vector2(-UIConstants.Spacing_Small, -UIConstants.Tab_Height);

        equipInfoText = UIHelper.MakeText("EquipInfo", content.transform, "장비: 0개",
            UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, UIColors.Text_DarkSecondary);
        equipInfoText.fontStyle = FontStyles.Bold;
        var irt = equipInfoText.GetComponent<RectTransform>();
        irt.anchorMin = new Vector2(0, 0.88f);
        irt.anchorMax = new Vector2(0.55f, 1);
        irt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
        irt.offsetMax = Vector2.zero;

        // 일괄 분해 버튼 (Star1/Star2 장비 전부)
        var (dismantleAllBtn, _da) = UIHelper.MakeSpriteButton("DismantleAllBtn", content.transform,
            UISprites.Btn1_WS, UIColors.Defeat_Red, "", UIConstants.Font_SmallInfo);
        var daRT = dismantleAllBtn.GetComponent<RectTransform>();
        daRT.anchorMin = new Vector2(0.57f, 0.90f);
        daRT.anchorMax = new Vector2(0.98f, 0.99f);
        daRT.offsetMin = daRT.offsetMax = Vector2.zero;
        var daLabel = UIHelper.MakeText("Label", dismantleAllBtn.transform, "일괄 분해 (★1~2)",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, Color.white);
        UIHelper.FillParent(daLabel.GetComponent<RectTransform>());
        dismantleAllBtn.onClick.AddListener(OnDismantleAllClicked);

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

    void OnDismantleAllClicked()
    {
        var em = EquipmentManager.Instance;
        if (em == null) return;

        var (count, gold) = em.PreviewDismantleAll(2);
        if (count == 0)
        {
            ToastNotification.Instance?.Show("분해할 장비 없음", "★1~2 비장착 장비가 없습니다", UIColors.Button_Gray);
            return;
        }

        MainHUD.Instance?.ShowConfirmDialog(
            "일괄 분해",
            $"★1~2 장비 {count}개를 분해하시겠습니까?\n→ 골드 {gold} 획득",
            () =>
            {
                em.DismantleAll(2);
                SoundManager.Instance?.PlayGoldSFX();
                ToastNotification.Instance?.Show("일괄 분해 완료!", $"+{gold}G", UIColors.Text_Gold);
                RefreshEquipmentUI();
            });
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

        Color[] rarityColors = {
            UIColors.Text_DarkSecondary,
            UIColors.Text_DarkSecondary,
            UIColors.Rarity_Common,
            new Color(0.3f, 0.6f, 1f),
            UIColors.Rarity_Rare,
            UIColors.Text_DarkGold
        };

        for (int i = 0; i < inv.Count; i++)
        {
            var equip = inv[i];
            Color rarityCol = equip.rarity >= 0 && equip.rarity < rarityColors.Length
                ? rarityColors[equip.rarity] : UIColors.Text_DarkSecondary;

            var item = ReuseOrCreate(equipListItems, ref equipReuse,
                $"Equip_{i}", equipListContainer.transform, new Color(0.92f, 0.88f, 0.82f));
            activeEquipCount++;
            var ert = item.GetComponent<RectTransform>();
            ert.anchorMin = new Vector2(0, 1);
            ert.anchorMax = new Vector2(1, 1);
            ert.pivot = new Vector2(0.5f, 1);
            ert.anchoredPosition = new Vector2(0, y);
            ert.sizeDelta = new Vector2(0, itemH);

            string stars = new string('★', equip.rarity);
            var nameText = UIHelper.MakeText("Name", item.transform, equip.itemName,
                UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, rarityCol);
            nameText.fontStyle = FontStyles.Bold;
            var nrt = nameText.GetComponent<RectTransform>();
            nrt.anchorMin = new Vector2(0, 0.5f);
            nrt.anchorMax = new Vector2(0.4f, 1);
            nrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
            nrt.offsetMax = Vector2.zero;

            var starText = UIHelper.MakeText("Stars", item.transform, stars,
                8f, TextAlignmentOptions.MidlineLeft, UIColors.Text_DarkGold);
            var srt = starText.GetComponent<RectTransform>();
            srt.anchorMin = new Vector2(0, 0);
            srt.anchorMax = new Vector2(0.4f, 0.5f);
            srt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
            srt.offsetMax = Vector2.zero;

            string statStr = "";
            if (equip.bonusAtk > 0) statStr += $"ATK+{equip.bonusAtk:F0} ";
            if (equip.bonusDef > 0) statStr += $"DEF+{equip.bonusDef:F0} ";
            if (equip.bonusHp > 0) statStr += $"HP+{equip.bonusHp:F0}";
            var statText = UIHelper.MakeText("Stats", item.transform, statStr,
                8f, TextAlignmentOptions.Center, UIColors.Text_Dark);
            var strt = statText.GetComponent<RectTransform>();
            strt.anchorMin = new Vector2(0.4f, 0);
            strt.anchorMax = new Vector2(0.7f, 1);
            strt.offsetMin = Vector2.zero;
            strt.offsetMax = Vector2.zero;

            bool isEquipped = !string.IsNullOrEmpty(equip.equippedTo);
            string btnLabel = isEquipped ? equip.equippedTo : "장착";
            Color btnColor = isEquipped ? UIColors.Button_Brown : UIColors.Button_Green;

            Sprite eqBtnSprite = isEquipped ? UISprites.Btn1_WS : UISprites.Btn2_WS;
            var (btn, _) = UIHelper.MakeSpriteButton($"Btn_{i}", item.transform, eqBtnSprite, btnColor, "", 9f);
            var btnRT = btn.GetComponent<RectTransform>();
            btnRT.anchorMin = new Vector2(0.72f, 0.05f);
            btnRT.anchorMax = new Vector2(0.97f, 0.48f);
            btnRT.offsetMin = Vector2.zero;
            btnRT.offsetMax = Vector2.zero;

            var btnText = UIHelper.MakeText("Label", btn.transform, btnLabel,
                8f, TextAlignmentOptions.Center, isEquipped ? new Color(0.25f, 0.15f, 0.08f) : Color.white);
            btnText.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(btnText.GetComponent<RectTransform>());

            string capturedId = equip.id;
            if (isEquipped)
            {
                btn.onClick.AddListener(() =>
                {
                    SoundManager.Instance?.PlayButtonSFX();
                    EquipmentManager.Instance?.UnequipItem(capturedId);
                    RefreshEquipmentUI();
                });
            }
            else
            {
                btn.onClick.AddListener(() =>
                {
                    SoundManager.Instance?.PlayButtonSFX();
                    showHeroSelect?.Invoke(capturedId);
                });
            }

            if (!isEquipped)
            {
                var materials = em.GetEnhanceMaterials(equip.id);
                bool canEnhance = materials.Count > 0 && equip.rarity < 5;

                bool showRetry = (_lastFailedEnhId == equip.id);
                if (showRetry)
                {
                    // 강화 실패 후: 광고 재시도 버튼 표시
                    bool adAvail = AdManager.Instance != null &&
                                   AdManager.Instance.IsAdAvailable(AdManager.AdRewardType.EnhanceRetry);
                    var (retryBtn, _4) = UIHelper.MakeSpriteButton($"Retry_{i}", item.transform,
                        adAvail ? UISprites.Btn2_WS : UISprites.Btn1_WS,
                        adAvail ? UIColors.Button_Blue : UIColors.Button_Gray, "", 6f);
                    var retryRT = retryBtn.GetComponent<RectTransform>();
                    retryRT.anchorMin = new Vector2(0.72f, 0.52f);
                    retryRT.anchorMax = new Vector2(0.84f, 0.95f);
                    retryRT.offsetMin = Vector2.zero;
                    retryRT.offsetMax = Vector2.zero;

                    string retryLabel = adAvail ? "무료\n재시도" : "쿨다운";
                    var retryText = UIHelper.MakeText("Label", retryBtn.transform, retryLabel,
                        6f, TextAlignmentOptions.Center,
                        adAvail ? Color.white : UIColors.Text_Disabled);
                    retryText.fontStyle = FontStyles.Bold;
                    UIHelper.FillParent(retryText.GetComponent<RectTransform>());

                    if (adAvail)
                    {
                        retryBtn.onClick.AddListener(() =>
                        {
                            AdManager.Instance?.ShowRewardedAd(AdManager.AdRewardType.EnhanceRetry, () =>
                            {
                                EquipmentManager.Instance?.BoostNextEnhance(0.20f);
                                ToastNotification.Instance?.Show("성공률 UP!", "+20% 보너스 적용됨", UIColors.Button_Blue);
                                RefreshEquipmentUI();
                            });
                        });
                    }
                }
                else
                {
                    // 일반 강화 버튼
                    var (enhBtn, _3) = UIHelper.MakeSpriteButton($"Enh_{i}", item.transform,
                        canEnhance ? UISprites.Btn2_WS : UISprites.Btn1_WS,
                        canEnhance ? UIColors.Button_Green : UIColors.Button_Gray, "", 7f);
                    if (!canEnhance && _3.sprite != null) _3.color = new Color(0.70f, 0.70f, 0.70f);
                    var enhBtnRT = enhBtn.GetComponent<RectTransform>();
                    enhBtnRT.anchorMin = new Vector2(0.72f, 0.52f);
                    enhBtnRT.anchorMax = new Vector2(0.84f, 0.95f);
                    enhBtnRT.offsetMin = Vector2.zero;
                    enhBtnRT.offsetMax = Vector2.zero;

                    string enhRate = canEnhance
                        ? $"강화\n{Mathf.RoundToInt(em.GetEnhanceSuccessRate(equip.rarity) * 100f)}%"
                        : "강화";
                    var enhBtnText = UIHelper.MakeText("Label", enhBtn.transform, enhRate,
                        6f, TextAlignmentOptions.Center,
                        canEnhance ? Color.white : UIColors.Text_Disabled);
                    enhBtnText.fontStyle = FontStyles.Bold;
                    UIHelper.FillParent(enhBtnText.GetComponent<RectTransform>());

                    if (canEnhance)
                    {
                        string enhId = equip.id;
                        string matId = materials[0].id;
                        float rate = em.GetEnhanceSuccessRate(equip.rarity);
                        enhBtn.onClick.AddListener(() =>
                        {
                            var emI = EquipmentManager.Instance;
                            if (emI == null) return;
                            if (emI.EnhanceItem(enhId, matId))
                            {
                                _lastFailedEnhId = null;
                                ToastNotification.Instance?.Show("강화 성공!", "등급 상승!", UIColors.Text_Gold);
                            }
                            else if (emI.LastEnhanceFailed)
                            {
                                _lastFailedEnhId = enhId;
                                int pct = Mathf.RoundToInt(rate * 100f);
                                ToastNotification.Instance?.Show("강화 실패!", $"성공률 {pct}% — 재료 소모됨", UIColors.Defeat_Red);
                            }
                            RefreshEquipmentUI();
                        });
                    }
                }

                var (disBtn, _2) = UIHelper.MakeSpriteButton($"Dis_{i}", item.transform,
                    UISprites.Btn4_WS, UIColors.Defeat_Red, "", 7f);
                var disBtnRT = disBtn.GetComponent<RectTransform>();
                disBtnRT.anchorMin = new Vector2(0.85f, 0.52f);
                disBtnRT.anchorMax = new Vector2(0.97f, 0.95f);
                disBtnRT.offsetMin = Vector2.zero;
                disBtnRT.offsetMax = Vector2.zero;

                string disLabel = $"{equip.rarity * 50}G";
                var disBtnText = UIHelper.MakeText("Label", disBtn.transform, disLabel,
                    7f, TextAlignmentOptions.Center, Color.white);
                disBtnText.fontStyle = FontStyles.Bold;
                UIHelper.FillParent(disBtnText.GetComponent<RectTransform>());

                string disId = equip.id;
                disBtn.onClick.AddListener(() =>
                {
                    int gold = EquipmentManager.Instance != null
                        ? EquipmentManager.Instance.DismantleItem(disId) : 0;
                    if (gold > 0)
                        ToastNotification.Instance?.Show("분해 완료!", $"+{gold}G", UIColors.Text_Gold);
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
    // 리스트 관리 유틸
    // ════════════════════════════════════════

    static void RecycleList(List<GameObject> items)
    {
        for (int i = 0; i < items.Count; i++)
            if (items[i] != null) items[i].SetActive(false);
    }

    static GameObject ReuseOrCreate(List<GameObject> items, ref int reuseIdx,
        string name, Transform parent, Color bgColor)
    {
        GameObject go;
        if (reuseIdx < items.Count && items[reuseIdx] != null)
        {
            go = items[reuseIdx];
            go.SetActive(true);
            for (int c = go.transform.childCount - 1; c >= 0; c--)
                Object.Destroy(go.transform.GetChild(c).gameObject);
        }
        else
        {
            var img = UIHelper.MakePanel(name, parent, bgColor);
            go = img.gameObject;
            items.Add(go);
        }
        reuseIdx++;
        return go;
    }

    static void TrimExcess(List<GameObject> items, int activeCount)
    {
        for (int i = activeCount; i < items.Count; i++)
            if (items[i] != null) items[i].SetActive(false);
    }

    // ════════════════════════════════════════
    // 꾹 누르기 (Long Press) — 연속 강화
    // ════════════════════════════════════════

    Coroutine _longPressRoutine;

    void AddLongPressUpgrade(GameObject btnGO, string heroName, int times)
    {
        var et = btnGO.AddComponent<EventTrigger>();

        var downEntry = new EventTrigger.Entry { eventID = EventTriggerType.PointerDown };
        downEntry.callback.AddListener(_ =>
        {
            if (_longPressRoutine != null) StopCoroutine(_longPressRoutine);
            _longPressRoutine = StartCoroutine(BulkLevelUpRoutine(heroName, times));
        });
        et.triggers.Add(downEntry);

        var upEntry = new EventTrigger.Entry { eventID = EventTriggerType.PointerUp };
        upEntry.callback.AddListener(_ =>
        {
            if (_longPressRoutine != null) { StopCoroutine(_longPressRoutine); _longPressRoutine = null; }
        });
        et.triggers.Add(upEntry);
    }

    System.Collections.IEnumerator BulkLevelUpRoutine(string heroName, int times)
    {
        yield return new WaitForSecondsRealtime(0.5f); // 0.5초 꾹 누르기 threshold

        var hlm = HeroLevelManager.Instance;
        if (hlm == null) { _longPressRoutine = null; yield break; }

        int done = 0;
        for (int i = 0; i < times; i++)
        {
            if (!hlm.TryLevelUp(heroName)) break;
            done++;
            yield return new WaitForSecondsRealtime(0.07f);
        }

        if (done > 0)
        {
            ToastNotification.Instance?.Show($"일괄 강화 완료!", $"{done}회 레벨업", UIColors.Button_Green);
            RefreshHeroUI();
        }
        _longPressRoutine = null;
    }

    void OnDestroy()
    {
        if (_longPressRoutine != null) { StopCoroutine(_longPressRoutine); _longPressRoutine = null; }
        if (subTabBtns != null)
        {
            for (int i = 0; i < subTabBtns.Length; i++)
                if (subTabBtns[i] != null)
                    subTabBtns[i].onClick.RemoveAllListeners();
        }
    }
}
