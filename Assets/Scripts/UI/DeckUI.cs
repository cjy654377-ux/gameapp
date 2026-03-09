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

    const float SLOT_SIZE = 44f;
    const float SLOT_SPACING = 5f;
    const float ROSTER_ITEM_H = 40f;

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

    void CreateDeckSection()
    {
        // 헤더
        deckHeaderText = UIHelper.MakeText("DeckHeader", root.transform, "편성 (3/8)",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.MidlineLeft, UIColors.Text_Secondary);
        var hrt = deckHeaderText.GetComponent<RectTransform>();
        hrt.anchorMin = new Vector2(0, 0.88f);
        hrt.anchorMax = new Vector2(1, 1f);
        hrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
        hrt.offsetMax = Vector2.zero;

        // 8슬롯 1줄 스크롤
        var scrollObj = UIHelper.MakeUI("DeckScroll", root.transform);
        var scrollRT = scrollObj.GetComponent<RectTransform>();
        scrollRT.anchorMin = new Vector2(0, 0.58f);
        scrollRT.anchorMax = new Vector2(1, 0.88f);
        scrollRT.offsetMin = new Vector2(UIConstants.Spacing_Small, 0);
        scrollRT.offsetMax = new Vector2(-UIConstants.Spacing_Small, 0);

        var scrollRect = scrollObj.AddComponent<ScrollRect>();
        scrollRect.horizontal = true;
        scrollRect.vertical = false;

        var viewport = UIHelper.MakeUI("Viewport", scrollObj.transform);
        var vpImg = viewport.AddComponent<Image>();
        vpImg.color = Color.clear;
        viewport.AddComponent<Mask>().showMaskGraphic = false;
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

            var bg = slot.AddComponent<Image>();
            bg.color = UIColors.Panel_Inner;
            deckSlotBgs[i] = bg;

            var btn = slot.AddComponent<Button>();
            btn.targetGraphic = bg;
            btn.onClick.AddListener(() => OnDeckSlotClicked(idx));

            var outline = slot.AddComponent<Outline>();
            outline.effectColor = UIColors.Panel_Border;
            outline.effectDistance = new Vector2(1, 1);

            var rt = slot.GetComponent<RectTransform>();
            rt.anchorMin = new Vector2(0, 0);
            rt.anchorMax = new Vector2(0, 1);
            rt.pivot = new Vector2(0, 0.5f);
            rt.anchoredPosition = new Vector2(i * (SLOT_SIZE + SLOT_SPACING), 0);
            rt.sizeDelta = new Vector2(SLOT_SIZE, 0);

            // 선택 테두리
            var borderObj = UIHelper.MakeUI("Border", slot.transform);
            var borderImg = borderObj.AddComponent<Image>();
            borderImg.color = Color.clear;
            borderImg.raycastTarget = false;
            UIHelper.FillParent(borderObj.GetComponent<RectTransform>());
            deckSlotBorders[i] = borderImg;

            // 이름
            deckSlotTexts[i] = UIHelper.MakeText("Name", slot.transform, "",
                9f, TextAlignmentOptions.Center);
            deckSlotTexts[i].enableWordWrapping = true;
            UIHelper.FillParent(deckSlotTexts[i].GetComponent<RectTransform>());
        }
    }

    void CreateDivider()
    {
        var divider = UIHelper.MakePanel("Divider", root.transform, UIColors.Panel_Border);
        var drt = divider.GetComponent<RectTransform>();
        drt.anchorMin = new Vector2(0.02f, 0.56f);
        drt.anchorMax = new Vector2(0.98f, 0.56f);
        drt.pivot = new Vector2(0.5f, 0.5f);
        drt.sizeDelta = new Vector2(0, 1);
    }

    void CreateRosterSection()
    {
        var header = UIHelper.MakeText("RosterHeader", root.transform, "보유 영웅",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.MidlineLeft, UIColors.Text_Secondary);
        var hrt = header.GetComponent<RectTransform>();
        hrt.anchorMin = new Vector2(0, 0.48f);
        hrt.anchorMax = new Vector2(1, 0.56f);
        hrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
        hrt.offsetMax = Vector2.zero;

        var scrollObj = UIHelper.MakeUI("RosterScroll", root.transform);
        var scrollRT = scrollObj.GetComponent<RectTransform>();
        scrollRT.anchorMin = new Vector2(0, 0);
        scrollRT.anchorMax = new Vector2(1, 0.48f);
        scrollRT.offsetMin = new Vector2(UIConstants.Spacing_Small, UIConstants.Spacing_Small);
        scrollRT.offsetMax = new Vector2(-UIConstants.Spacing_Small, 0);

        var scrollRect = scrollObj.AddComponent<ScrollRect>();
        scrollRect.horizontal = false;
        scrollRect.vertical = true;

        var viewport = UIHelper.MakeUI("Viewport", scrollObj.transform);
        var vpImg = viewport.AddComponent<Image>();
        vpImg.color = Color.clear;
        viewport.AddComponent<Mask>().showMaskGraphic = false;
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
                deckSlotBgs[i].color = UIColors.Panel_Inner;
                deckSlotTexts[i].text = $"{GetRoleIcon(preset)}\n{preset.characterName}";
                deckSlotTexts[i].color = UIColors.Text_Primary;
            }
            else
            {
                deckSlotBgs[i].color = UIColors.Background_Dark;
                deckSlotTexts[i].text = "+";
                deckSlotTexts[i].color = UIColors.Text_Disabled;
            }
        }

        if (deckHeaderText != null)
            deckHeaderText.text = $"편성 ({count}/{DeckManager.MAX_DECK_SIZE})";
    }

    void RefreshRoster()
    {
        for (int i = 0; i < rosterItems.Count; i++)
            if (rosterItems[i] != null) Destroy(rosterItems[i]);
        rosterItems.Clear();

        var dm = DeckManager.Instance;
        if (dm == null) return;

        float y = 0;
        float spacing = 3f;

        for (int i = 0; i < dm.roster.Count; i++)
        {
            var preset = dm.roster[i];
            if (preset == null || preset.isEnemy) continue;

            int idx = i;
            bool inDeck = dm.IsInDeck(preset);

            var item = UIHelper.MakeUI($"Hero_{preset.characterName}", rosterContainer.transform);
            rosterItems.Add(item);

            var itemBg = item.AddComponent<Image>();
            itemBg.color = inDeck ? UIColors.Background_Dark : UIColors.Panel_Inner;

            var itemBtn = item.AddComponent<Button>();
            itemBtn.targetGraphic = itemBg;
            itemBtn.onClick.AddListener(() => OnRosterItemClicked(idx));

            if (inDeck)
            {
                var itemOutline = item.AddComponent<Outline>();
                itemOutline.effectColor = UIColors.Panel_Selected;
                itemOutline.effectDistance = new Vector2(1, 1);
            }

            var irt = item.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0, 1);
            irt.anchorMax = new Vector2(1, 1);
            irt.pivot = new Vector2(0.5f, 1);
            irt.anchoredPosition = new Vector2(0, y);
            irt.sizeDelta = new Vector2(0, ROSTER_ITEM_H);

            // Role icon
            var roleText = UIHelper.MakeText("Role", item.transform, GetRoleIcon(preset),
                UIConstants.Font_Tab, TextAlignmentOptions.Center);
            var rrt = roleText.GetComponent<RectTransform>();
            rrt.anchorMin = new Vector2(0, 0);
            rrt.anchorMax = new Vector2(0.1f, 1);
            rrt.offsetMin = Vector2.zero;
            rrt.offsetMax = Vector2.zero;

            // Name
            var nameText = UIHelper.MakeText("Info", item.transform, preset.characterName,
                UIConstants.Font_SmallInfo, TextAlignmentOptions.MidlineLeft);
            nameText.fontStyle = FontStyles.Bold;
            var nrt = nameText.GetComponent<RectTransform>();
            nrt.anchorMin = new Vector2(0.11f, 0.5f);
            nrt.anchorMax = new Vector2(0.55f, 1);
            nrt.offsetMin = Vector2.zero;
            nrt.offsetMax = Vector2.zero;

            // Stats
            var statText = UIHelper.MakeText("Stats", item.transform,
                $"HP:{preset.maxHp:F0} ATK:{preset.atk:F0}",
                9f, TextAlignmentOptions.MidlineLeft, UIColors.Text_Secondary);
            var strt = statText.GetComponent<RectTransform>();
            strt.anchorMin = new Vector2(0.11f, 0);
            strt.anchorMax = new Vector2(0.55f, 0.5f);
            strt.offsetMin = Vector2.zero;
            strt.offsetMax = Vector2.zero;

            // 상태
            string statusStr = inDeck ? "편성됨" : "추가";
            Color statusColor = inDeck ? UIColors.Text_Green : UIColors.Text_Gold;
            var statusText = UIHelper.MakeText("Status", item.transform, statusStr,
                UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, statusColor);
            statusText.fontStyle = FontStyles.Bold;
            var strt2 = statusText.GetComponent<RectTransform>();
            strt2.anchorMin = new Vector2(0.75f, 0);
            strt2.anchorMax = new Vector2(1, 1);
            strt2.offsetMin = Vector2.zero;
            strt2.offsetMax = Vector2.zero;

            y -= (ROSTER_ITEM_H + spacing);
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
            if (deckSlotBorders[i] != null)
                deckSlotBorders[i].color = selected ? UIColors.Panel_Selected : Color.clear;
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
}
