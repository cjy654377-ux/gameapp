using UnityEngine;
using UnityEngine.UI;
using TMPro;

/// <summary>
/// 덱 편성 UI — 하단 절반만 사용, 전투 화면 위에 반투명 표시
/// 상단: 8슬롯 덱 (1줄 스크롤)
/// 하단: 보유 영웅 목록 (스크롤)
/// </summary>
public class DeckUI : MonoBehaviour
{
    public static DeckUI Instance { get; private set; }

    GameObject root;

    readonly GameObject[] deckSlotObjs = new GameObject[DeckManager.MAX_DECK_SIZE];
    readonly Image[] deckSlotBgs = new Image[DeckManager.MAX_DECK_SIZE];
    readonly TextMeshProUGUI[] deckSlotTexts = new TextMeshProUGUI[DeckManager.MAX_DECK_SIZE];
    readonly Image[] deckSlotBorders = new Image[DeckManager.MAX_DECK_SIZE];

    GameObject rosterContainer;
    readonly System.Collections.Generic.List<GameObject> rosterItems = new();
    TextMeshProUGUI deckHeaderText;

    int selectedDeckSlot = -1;
    readonly Color[] slotRarityColors = new Color[DeckManager.MAX_DECK_SIZE];

    const float SLOT_SIZE = 52f;
    const float SLOT_SPACING = 5f;
    const float ROSTER_ITEM_H = 48f;
    const float ROSTER_ITEM_SPACING = 3f;

    static readonly Color COLOR_HEADER_BG   = new Color(0.38f, 0.28f, 0.18f, 0.80f);
    static readonly Color COLOR_DIVIDER      = new Color(0.50f, 0.38f, 0.25f);
    static readonly Color COLOR_SLOT_EMPTY   = new Color(0.80f, 0.80f, 0.80f);
    static readonly Color COLOR_ITEM_IN_DECK = new Color(0.88f, 0.94f, 0.85f);
    static readonly Color COLOR_NAME_DARK    = new Color(0.17f, 0.09f, 0.04f);
    static readonly Color COLOR_STAT_MID     = new Color(0.35f, 0.24f, 0.16f);
    static readonly Color COLOR_SELECT_BORDER  = new Color(0.5f,  0.85f, 0.3f,  0.6f);
    static readonly Color COLOR_ITEM_FALLBACK_DECK = new Color(0.35f, 0.45f, 0.28f);
    static readonly Color COLOR_ITEM_FALLBACK_FREE = new Color(0.55f, 0.45f, 0.32f);
    static readonly Color COLOR_BTN_DIM        = new Color(0.70f, 0.70f, 0.70f);
    static readonly Color COLOR_LABEL_DISABLED = new Color(0.60f, 0.60f, 0.60f);

    static Color GetRarityColor(StarGrade grade) => grade switch
    {
        StarGrade.Star1 => UIColors.Rarity_Common,
        StarGrade.Star2 => UIColors.Rarity_Uncommon,
        StarGrade.Star3 => UIColors.Rarity_Rare,
        StarGrade.Star4 => UIColors.Rarity_Epic,
        StarGrade.Star5 => UIColors.Rarity_Legendary,
        _               => UIColors.Rarity_Common
    };

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }
    }

    void OnEnable() => Refresh();

    public void Init(Transform parentPanel)
    {
        if (root != null) return;
        BuildUI(parentPanel);
    }

    void BuildUI(Transform parent)
    {
        root = UIHelper.MakeUI("DeckContent", parent);
        var rootRT = root.GetComponent<RectTransform>();
        rootRT.anchorMin = new Vector2(0, 0);
        rootRT.anchorMax = new Vector2(1, 1);
        rootRT.offsetMin = Vector2.zero;
        rootRT.offsetMax = new Vector2(0, -UIConstants.Tab_Height);

        CreateDeckSection();
        CreateDivider();
        CreateRosterSection();
    }

    // 슬롯 바디 스프라이트 이미지 (캐릭터 초상화용)
    readonly Image[] deckSlotPortraits = new Image[DeckManager.MAX_DECK_SIZE];

    // 섹션 헤더 (BoxBanner 스타일) 생성 헬퍼
    GameObject CreateSectionHeader(string objName, string text, float yMin, float yMax)
    {
        var headerImg = UIHelper.MakeSpritePanel(objName, root.transform, UISprites.BoxIcon1, COLOR_HEADER_BG);
        var hbrt = headerImg.GetComponent<RectTransform>();
        hbrt.anchorMin = new Vector2(0.02f, yMin);
        hbrt.anchorMax = new Vector2(0.98f, yMax);
        hbrt.offsetMin = Vector2.zero;
        hbrt.offsetMax = Vector2.zero;
        var label = UIHelper.MakeText("Label", headerImg.transform, text,
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, UIColors.Text_Secondary);
        label.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(label.GetComponent<RectTransform>());
        return headerImg.gameObject;
    }

    void CreateDeckSection()
    {
        var headerBg = CreateSectionHeader("DeckHeaderBG", "편성 (3/8)", 0.88f, 0.98f);
        deckHeaderText = headerBg.GetComponentInChildren<TextMeshProUGUI>();

        // 8슬롯 1줄 스크롤
        var scrollObj = UIHelper.MakeUI("DeckScroll", root.transform);
        var scrollRT = scrollObj.GetComponent<RectTransform>();
        scrollRT.anchorMin = new Vector2(0, 0.56f);
        scrollRT.anchorMax = new Vector2(1, 0.88f);
        scrollRT.offsetMin = new Vector2(UIConstants.Spacing_Small, 2);
        scrollRT.offsetMax = new Vector2(-UIConstants.Spacing_Small, -2);

        var scrollRect = scrollObj.AddComponent<ScrollRect>();
        scrollRect.horizontal = true;
        scrollRect.vertical = false;

        var viewport = UIHelper.MakeUI("Viewport", scrollObj.transform);
        viewport.AddComponent<RectMask2D>();
        UIHelper.FillParent(viewport.GetComponent<RectTransform>());
        scrollRect.viewport = viewport.GetComponent<RectTransform>();

        var content = UIHelper.MakeUI("Content", viewport.transform);
        var contentRT = content.GetComponent<RectTransform>();
        contentRT.anchorMin = new Vector2(0, 0);
        contentRT.anchorMax = new Vector2(0, 1);
        contentRT.pivot = new Vector2(0, 0.5f);
        float totalW = DeckManager.MAX_DECK_SIZE * (SLOT_SIZE + SLOT_SPACING);
        contentRT.sizeDelta = new Vector2(totalW, 0);
        scrollRect.content = contentRT;

        for (int i = 0; i < DeckManager.MAX_DECK_SIZE; i++)
        {
            int idx = i;
            var slot = UIHelper.MakeUI($"Slot_{i}", content.transform);
            deckSlotObjs[i] = slot;

            // BoxProfile 스프라이트로 슬롯 배경
            var bg = slot.AddComponent<Image>();
            if (UISprites.BoxProfile != null)
            {
                bg.sprite = UISprites.BoxProfile;
                bg.type = Image.Type.Sliced;
                bg.color = Color.white;
            }
            else
            {
                bg.color = UIColors.Panel_Inner;
            }
            deckSlotBgs[i] = bg;

            var btn = slot.AddComponent<Button>();
            btn.targetGraphic = bg;
            btn.onClick.AddListener(() => OnDeckSlotClicked(idx));

            var rt = slot.GetComponent<RectTransform>();
            rt.anchorMin = new Vector2(0, 0);
            rt.anchorMax = new Vector2(0, 1);
            rt.pivot = new Vector2(0, 0.5f);
            rt.anchoredPosition = new Vector2(i * (SLOT_SIZE + SLOT_SPACING), 0);
            rt.sizeDelta = new Vector2(SLOT_SIZE, 0);

            // 캐릭터 초상화 이미지 (바디 스프라이트)
            var portraitObj = UIHelper.MakeUI("Portrait", slot.transform);
            var portraitImg = portraitObj.AddComponent<Image>();
            portraitImg.preserveAspect = true;
            portraitImg.raycastTarget = false;
            portraitImg.color = Color.clear; // 초기엔 숨김
            var prt = portraitObj.GetComponent<RectTransform>();
            prt.anchorMin = new Vector2(0.1f, 0.15f);
            prt.anchorMax = new Vector2(0.9f, 0.75f);
            prt.offsetMin = Vector2.zero;
            prt.offsetMax = Vector2.zero;
            deckSlotPortraits[i] = portraitImg;

            // 선택 테두리
            var borderObj = UIHelper.MakeUI("Border", slot.transform);
            var borderImg = borderObj.AddComponent<Image>();
            borderImg.color = Color.clear;
            borderImg.raycastTarget = false;
            UIHelper.FillParent(borderObj.GetComponent<RectTransform>());
            deckSlotBorders[i] = borderImg;

            // 이름 (하단에 배치)
            deckSlotTexts[i] = UIHelper.MakeText("Name", slot.transform, "",
                8f, TextAlignmentOptions.Bottom, Color.white);
            deckSlotTexts[i].textWrappingMode = TextWrappingModes.Normal;
            deckSlotTexts[i].fontStyle = FontStyles.Bold;
            var nrt = deckSlotTexts[i].GetComponent<RectTransform>();
            nrt.anchorMin = new Vector2(0, 0);
            nrt.anchorMax = new Vector2(1, 0.22f);
            nrt.offsetMin = new Vector2(1, 1);
            nrt.offsetMax = new Vector2(-1, 0);
        }
    }

    void CreateDivider()
    {
        var divider = UIHelper.MakePanel("Divider", root.transform, COLOR_DIVIDER);
        var drt = divider.GetComponent<RectTransform>();
        drt.anchorMin = new Vector2(0.04f, 0.55f);
        drt.anchorMax = new Vector2(0.96f, 0.55f);
        drt.pivot = new Vector2(0.5f, 0.5f);
        drt.sizeDelta = new Vector2(0, 2);
    }

    void CreateRosterSection()
    {
        CreateSectionHeader("RosterHeaderBG", "보유 영웅", 0.47f, 0.54f);

        var scrollObj = UIHelper.MakeUI("RosterScroll", root.transform);
        var scrollRT = scrollObj.GetComponent<RectTransform>();
        scrollRT.anchorMin = new Vector2(0, 0);
        scrollRT.anchorMax = new Vector2(1, 0.46f);
        scrollRT.offsetMin = new Vector2(UIConstants.Spacing_Small, UIConstants.Spacing_Small);
        scrollRT.offsetMax = new Vector2(-UIConstants.Spacing_Small, 0);

        var scrollRect = scrollObj.AddComponent<ScrollRect>();
        scrollRect.horizontal = false;
        scrollRect.vertical = true;

        var viewport = UIHelper.MakeUI("Viewport", scrollObj.transform);
        viewport.AddComponent<RectMask2D>();
        UIHelper.FillParent(viewport.GetComponent<RectTransform>());
        scrollRect.viewport = viewport.GetComponent<RectTransform>();

        rosterContainer = UIHelper.MakeUI("Content", viewport.transform);
        var contentRT = rosterContainer.GetComponent<RectTransform>();
        contentRT.anchorMin = new Vector2(0, 1);
        contentRT.anchorMax = new Vector2(1, 1);
        contentRT.pivot = new Vector2(0.5f, 1);
        contentRT.anchoredPosition = Vector2.zero;
        scrollRect.content = contentRT;
    }

    // ═══════════════════════════════════════
    // REFRESH
    // ═══════════════════════════════════════

    public void Refresh()
    {
        if (DeckManager.Instance == null || root == null) return;
        RefreshDeckSlots();
        RefreshRoster();
        UpdateSelectionVisuals();
    }

    void RefreshDeckSlots()
    {
        var dm = DeckManager.Instance;
        int count = 0;

        for (int i = 0; i < DeckManager.MAX_DECK_SIZE; i++)
        {
            var preset = dm.GetSlot(i);
            if (preset != null)
            {
                count++;
                if (UISprites.BoxProfile != null)
                    deckSlotBgs[i].color = Color.white;
                else
                    deckSlotBgs[i].color = UIColors.Panel_Inner;
                deckSlotTexts[i].text = preset.characterName;
                deckSlotTexts[i].color = Color.white;
                slotRarityColors[i] = GetRarityColor(preset.starGrade);

                // 캐릭터 바디 스프라이트 표시
                if (deckSlotPortraits[i] != null)
                {
                    var bodySprite = LoadCharacterPortrait(preset);
                    if (bodySprite != null)
                    {
                        deckSlotPortraits[i].sprite = bodySprite;
                        deckSlotPortraits[i].color = Color.white;
                    }
                    else
                    {
                        deckSlotPortraits[i].sprite = null;
                        deckSlotPortraits[i].color = Color.clear;
                    }
                }
            }
            else
            {
                if (UISprites.BoxProfile != null)
                    deckSlotBgs[i].color = COLOR_SLOT_EMPTY;
                else
                    deckSlotBgs[i].color = UIColors.Background_Dark;
                deckSlotTexts[i].text = "+";
                deckSlotTexts[i].color = UIColors.Text_Disabled;
                slotRarityColors[i] = Color.clear;

                if (deckSlotPortraits[i] != null)
                {
                    deckSlotPortraits[i].sprite = null;
                    deckSlotPortraits[i].color = Color.clear;
                }
            }
        }

        if (deckHeaderText != null)
            deckHeaderText.text = $"편성 ({count}/{DeckManager.MAX_DECK_SIZE})";
    }

    /// <summary>
    /// CharacterPreset의 바디 스프라이트를 로드하여 초상화로 사용.
    /// 반복 호출 방지를 위해 로컬 캐시 사용.
    /// </summary>
    static readonly System.Collections.Generic.Dictionary<string, Sprite> portraitCache = new();

    static Sprite LoadCharacterPortrait(CharacterPreset preset)
    {
        if (preset == null || string.IsNullOrEmpty(preset.bodySprite)) return null;
        if (portraitCache.TryGetValue(preset.bodySprite, out var cached)) return cached;

        var sprites = Resources.LoadAll<Sprite>($"Addons/Legacy/0_Unit/0_Sprite/1_Body/{preset.bodySprite}");
        if (sprites == null || sprites.Length == 0)
        {
            portraitCache[preset.bodySprite] = null;
            return null;
        }
        // "Body" 서브스프라이트 찾기, 없으면 첫 번째
        Sprite result = sprites[0];
        for (int i = 0; i < sprites.Length; i++)
        {
            if (sprites[i].name.Contains("Body")) { result = sprites[i]; break; }
        }
        portraitCache[preset.bodySprite] = result;
        return result;
    }

    void RefreshRoster()
    {
        for (int i = 0; i < rosterItems.Count; i++)
            if (rosterItems[i] != null) Destroy(rosterItems[i]);
        rosterItems.Clear();

        var dm = DeckManager.Instance;
        if (dm == null) return;

        float y = 0;

        for (int i = 0; i < dm.roster.Count; i++)
        {
            var preset = dm.roster[i];
            if (preset == null || preset.isEnemy) continue;

            int idx = i;
            bool inDeck = dm.IsInDeck(preset);

            var item = UIHelper.MakeUI($"Hero_{preset.characterName}", rosterContainer.transform);
            rosterItems.Add(item);

            // BoxBasic3 배경 — 밝은 톤으로 텍스트 대비 확보
            var itemBg = item.AddComponent<Image>();
            if (UISprites.BoxBasic3 != null)
            {
                itemBg.sprite = UISprites.BoxBasic3;
                itemBg.type = Image.Type.Simple; // BoxBasic3는 border=0이므로 Sliced 사용 불가
                itemBg.color = inDeck ? COLOR_ITEM_IN_DECK : Color.white;
            }
            else
            {
                itemBg.color = inDeck ? COLOR_ITEM_FALLBACK_DECK : COLOR_ITEM_FALLBACK_FREE;
            }

            var itemBtn = item.AddComponent<Button>();
            itemBtn.targetGraphic = itemBg;
            itemBtn.onClick.AddListener(() => OnRosterItemClicked(idx));

            var irt = item.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0, 1);
            irt.anchorMax = new Vector2(1, 1);
            irt.pivot = new Vector2(0.5f, 1);
            irt.anchoredPosition = new Vector2(0, y);
            irt.sizeDelta = new Vector2(0, ROSTER_ITEM_H);

            // 좌측 성급 색 띠
            var strip = UIHelper.MakePanel("RarityStrip", item.transform, GetRarityColor(preset.starGrade));
            var stripRT = strip.GetComponent<RectTransform>();
            stripRT.anchorMin = new Vector2(0, 0.08f);
            stripRT.anchorMax = new Vector2(0.022f, 0.92f);
            stripRT.offsetMin = Vector2.zero;
            stripRT.offsetMax = Vector2.zero;

            // Role icon
            var roleText = UIHelper.MakeText("Role", item.transform, GetRoleIcon(preset),
                UIConstants.Font_Tab, TextAlignmentOptions.Center);
            var rrt = roleText.GetComponent<RectTransform>();
            rrt.anchorMin = new Vector2(0.025f, 0);
            rrt.anchorMax = new Vector2(0.12f, 1);
            rrt.offsetMin = Vector2.zero;
            rrt.offsetMax = Vector2.zero;

            // Name — 진한 갈색으로 확실한 대비
            var nameText = UIHelper.MakeText("Info", item.transform, preset.characterName,
                UIConstants.Font_SmallInfo, TextAlignmentOptions.MidlineLeft, COLOR_NAME_DARK);
            nameText.fontStyle = FontStyles.Bold;
            var nrt = nameText.GetComponent<RectTransform>();
            nrt.anchorMin = new Vector2(0.13f, 0.48f);
            nrt.anchorMax = new Vector2(0.60f, 1);
            nrt.offsetMin = Vector2.zero;
            nrt.offsetMax = Vector2.zero;

            // 성급 별 표시 (MakeStarRating)
            var starTr = UIHelper.MakeStarRating("Stars", item.transform, (int)preset.starGrade, 8f);
            var starRT = starTr.GetComponent<RectTransform>();
            starRT.anchorMin = new Vector2(0.13f, 0.02f);
            starRT.anchorMax = new Vector2(0.60f, 0.46f);
            starRT.sizeDelta = Vector2.zero;
            starRT.anchoredPosition = Vector2.zero;

            // 상태 버튼 — 스프라이트 사용
            string statusStr = inDeck ? "해제" : "편성";
            Sprite statusSprite = inDeck ? UISprites.Btn1_WS : UISprites.Btn2_WS;
            Color statusFallback = inDeck ? UIColors.Button_Brown : UIColors.Button_Green;
            var (statusBtn, statusBtnImg) = UIHelper.MakeSpriteButton("Status", item.transform,
                statusSprite, statusFallback, "", 9f);
            statusBtn.onClick.AddListener(() => OnRosterItemClicked(idx));
            var strt2 = statusBtn.GetComponent<RectTransform>();
            strt2.anchorMin = new Vector2(0.70f, 0.12f);
            strt2.anchorMax = new Vector2(0.97f, 0.88f);
            strt2.offsetMin = Vector2.zero;
            strt2.offsetMax = Vector2.zero;
            var statusLabel = UIHelper.MakeText("Label", statusBtn.transform, statusStr,
                10f, TextAlignmentOptions.Center, Color.white);
            statusLabel.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(statusLabel.GetComponent<RectTransform>());

            y -= (ROSTER_ITEM_H + ROSTER_ITEM_SPACING);
        }

        var contentRT = rosterContainer.GetComponent<RectTransform>();
        contentRT.sizeDelta = new Vector2(0, Mathf.Abs(y));
    }

    // ═══════════════════════════════════════
    // INTERACTIONS
    // ═══════════════════════════════════════

    void OnDeckSlotClicked(int slotIndex)
    {
        var dm = DeckManager.Instance;
        if (dm == null) return;

        var preset = dm.GetSlot(slotIndex);
        if (preset != null)
        {
            if (selectedDeckSlot == slotIndex)
            {
                dm.RemoveFromDeck(slotIndex);
                selectedDeckSlot = -1;
            }
            else
            {
                selectedDeckSlot = slotIndex;
            }
        }
        else
        {
            selectedDeckSlot = -1;
        }
        Refresh();
    }

    void OnRosterItemClicked(int rosterIndex)
    {
        var dm = DeckManager.Instance;
        if (dm == null || rosterIndex >= dm.roster.Count) return;

        var preset = dm.roster[rosterIndex];
        if (preset == null) return;

        if (dm.IsInDeck(preset))
        {
            dm.RemoveFromDeck(dm.GetSlotIndex(preset));
            selectedDeckSlot = -1;
        }
        else if (selectedDeckSlot >= 0)
        {
            dm.SetSlot(selectedDeckSlot, preset);
            selectedDeckSlot = -1;
        }
        else
        {
            dm.AddToDeck(preset);
        }
        Refresh();
    }

    void UpdateSelectionVisuals()
    {
        for (int i = 0; i < DeckManager.MAX_DECK_SIZE; i++)
        {
            bool selected = (i == selectedDeckSlot);
            if (deckSlotBorders[i] == null) continue;

            if (selected)
            {
                deckSlotBorders[i].color = COLOR_SELECT_BORDER;
            }
            else if (slotRarityColors[i] != Color.clear)
            {
                var rc = slotRarityColors[i];
                deckSlotBorders[i].color = new Color(rc.r, rc.g, rc.b, 0.85f);
            }
            else
            {
                deckSlotBorders[i].color = Color.clear;
            }
        }
    }

    static string GetRoleIcon(CharacterPreset preset)
    {
        if (preset.isHealer) return "<color=#7FD44C>+</color>";
        if (preset.isBuffer) return "<color=#87CEEB>▲</color>";
        if (preset.attackAnimType == AttackAnimType.Bow) return "<color=#FFD700>→</color>";
        if (preset.attackAnimType == AttackAnimType.Magic) return "<color=#6B3FA0>◇</color>";
        return "<color=#CC3333>⚔</color>";
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }
}
