using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class SkillUI : MonoBehaviour
{
    public static SkillUI Instance { get; private set; }

    /// <summary>
    /// Set to true when MainHUD tab panels are open.
    /// Other scripts can set this to hide/show skill slots accordingly.
    /// </summary>
    public static bool IsTabPanelOpen
    {
        get => _isTabPanelOpen;
        set
        {
            _isTabPanelOpen = value;
            if (Instance != null)
            {
                if (value) Instance.HideSkillSlots();
                else Instance.ShowSkillSlots();
            }
        }
    }
    static bool _isTabPanelOpen;

    const int SLOT_COUNT = 4;
    const int CANVAS_SORT_ORDER = 50;
    const float READY_COLOR_MULT = 0.70f;
    const float COOLDOWN_COLOR_MULT = 0.18f;
    const float AUTO_BTN_W = 56f;
    const float AUTO_BTN_H = 36f;
    const float SLOT_SIZE = 58f;
    const float SLOT_SPACING = 6f;

    GameObject[] slotObjects = new GameObject[SLOT_COUNT];
    Image[] cooldownOverlays = new Image[SLOT_COUNT];
    TextMeshProUGUI[] cooldownTexts = new TextMeshProUGUI[SLOT_COUNT];
    TextMeshProUGUI[] nameTexts = new TextMeshProUGUI[SLOT_COUNT];
    Image[] slotBgs = new Image[SLOT_COUNT];
    readonly Color[] readyColors = new Color[SLOT_COUNT];
    readonly Color[] cooldownColors = new Color[SLOT_COUNT];
    Button autoToggleButton;
    TextMeshProUGUI autoToggleText;
    GameObject slotsContainer;

    Canvas canvas;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        CreateCanvas();
        CreateSkillSlots();
        CreateAutoToggle();
    }

    SkillManager cachedSkillMgr;

    void Start()
    {
        StartCoroutine(DeferredSubscribe());
    }

    System.Collections.IEnumerator DeferredSubscribe()
    {
        yield return null;
        cachedSkillMgr = SkillManager.Instance;
        if (cachedSkillMgr != null)
        {
            cachedSkillMgr.OnCooldownChanged += UpdateCooldown;
            cachedSkillMgr.OnSkillUsed += OnSkillUsed;
            RefreshSlots();
        }
        if (_isTabPanelOpen) HideSkillSlots();
    }

    void CreateCanvas()
    {
        canvas = gameObject.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvas.sortingOrder = CANVAS_SORT_ORDER;

        var scaler = gameObject.AddComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = UIConstants.ReferenceResolution;
        scaler.matchWidthOrHeight = UIConstants.MatchWidthOrHeight;

        gameObject.AddComponent<GraphicRaycaster>();
    }

    void CreateSkillSlots()
    {
        // Container for all skill slots (for easy show/hide)
        slotsContainer = UIHelper.MakeUI("SlotsContainer", canvas.transform);
        var containerRT = slotsContainer.GetComponent<RectTransform>();
        containerRT.anchorMin = Vector2.zero;
        containerRT.anchorMax = Vector2.one;
        containerRT.sizeDelta = Vector2.zero;
        containerRT.anchoredPosition = Vector2.zero;

        float slotSize = SLOT_SIZE;
        float spacing = SLOT_SPACING;
        float totalWidth = SLOT_COUNT * slotSize + (SLOT_COUNT - 1) * spacing;
        float startX = -totalWidth * 0.5f + slotSize * 0.5f;

        for (int i = 0; i < SLOT_COUNT; i++)
        {
            var slot = UIHelper.MakeUI($"SkillSlot_{i}", slotsContainer.transform);
            slotObjects[i] = slot;

            var rt = slot.GetComponent<RectTransform>();
            rt.anchorMin = new Vector2(0.5f, 0f);
            rt.anchorMax = new Vector2(0.5f, 0f);
            rt.pivot = new Vector2(0.5f, 0f);
            rt.anchoredPosition = new Vector2(startX + i * (slotSize + spacing), UIConstants.NavBar_Height + UIConstants.Spacing_Large);
            rt.sizeDelta = new Vector2(slotSize, slotSize);

            // Border frame (dark outline)
            var border = UIHelper.MakePanel("Border", slot.transform, new Color(0, 0, 0, 0.8f));
            var brt = border.GetComponent<RectTransform>();
            brt.anchorMin = Vector2.zero;
            brt.anchorMax = Vector2.one;
            brt.offsetMin = new Vector2(-2, -2);
            brt.offsetMax = new Vector2(2, 2);

            var bg = slot.AddComponent<Image>();
            bg.color = UIColors.Panel_Inner;
            slotBgs[i] = bg;

            var btn = slot.AddComponent<Button>();
            int slotIdx = i;
            btn.onClick.AddListener(() => OnSlotClicked(slotIdx));
            btn.targetGraphic = bg;

            // Skill name (icon char + name, lower half)
            nameTexts[i] = UIHelper.MakeText("Name", slot.transform, "",
                UIConstants.Font_StatLabel, TextAlignmentOptions.Center);
            var nameRT = nameTexts[i].GetComponent<RectTransform>();
            UIHelper.FillParent(nameRT);
            nameRT.anchoredPosition = new Vector2(0, 4);

            // Cooldown overlay (top-down fill)
            var cdObj = UIHelper.MakeUI("CooldownOverlay", slot.transform);
            cooldownOverlays[i] = cdObj.AddComponent<Image>();
            cooldownOverlays[i].color = new Color(0, 0, 0, 0.72f);
            cooldownOverlays[i].type = Image.Type.Filled;
            cooldownOverlays[i].fillMethod = Image.FillMethod.Vertical;
            cooldownOverlays[i].fillOrigin = 1; // top-down
            cooldownOverlays[i].fillAmount = 0f;
            UIHelper.FillParent(cdObj.GetComponent<RectTransform>());

            // Cooldown timer text (large center number)
            cooldownTexts[i] = UIHelper.MakeText("Timer", slot.transform, "",
                18f, TextAlignmentOptions.Center, Color.white);
            cooldownTexts[i].fontStyle = FontStyles.Bold;
            UIHelper.AddTextShadow(cooldownTexts[i]);
            UIHelper.FillParent(cooldownTexts[i].GetComponent<RectTransform>());
        }
    }

    void CreateAutoToggle()
    {
        // 스킬 슬롯 4개 우측에 작은 오토 버튼 배치
        float totalWidth = SLOT_COUNT * SLOT_SIZE + (SLOT_COUNT - 1) * SLOT_SPACING;
        float rightEdge = totalWidth * 0.5f;

        var (btn, img) = UIHelper.MakeButton("AutoToggle", slotsContainer.transform,
            UIColors.Button_Green, "A", UIConstants.Font_LevelBadge);
        autoToggleButton = btn;
        autoToggleButton.onClick.AddListener(OnAutoToggleClicked);
        autoToggleText = btn.GetComponentInChildren<TextMeshProUGUI>();
        autoToggleText.fontStyle = FontStyles.Bold;

        var toggleRT = btn.GetComponent<RectTransform>();
        toggleRT.anchorMin = new Vector2(0.5f, 0f);
        toggleRT.anchorMax = new Vector2(0.5f, 0f);
        toggleRT.pivot = new Vector2(0f, 0f);
        toggleRT.anchoredPosition = new Vector2(rightEdge + UIConstants.Spacing_Small, UIConstants.NavBar_Height + UIConstants.Spacing_Large + SLOT_SIZE * 0.25f);
        toggleRT.sizeDelta = new Vector2(28f, 28f);
    }


    /// <summary>
    /// Hide all skill slot UI elements (call when tab panels open)
    /// </summary>
    public void HideSkillSlots()
    {
        if (slotsContainer != null)
            slotsContainer.SetActive(false);
        if (autoToggleButton != null)
            autoToggleButton.gameObject.SetActive(false);
    }

    /// <summary>
    /// Show all skill slot UI elements (call when tab panels close)
    /// </summary>
    public void ShowSkillSlots()
    {
        if (slotsContainer != null)
            slotsContainer.SetActive(true);
        if (autoToggleButton != null)
            autoToggleButton.gameObject.SetActive(true);
    }

    public void RefreshSlots()
    {
        if (SkillManager.Instance == null) return;
        var skills = SkillManager.Instance.equippedSkills;

        for (int i = 0; i < SLOT_COUNT; i++)
        {
            if (i < skills.Count && skills[i] != null)
            {
                slotObjects[i].SetActive(true);
                nameTexts[i].text = $"{skills[i].iconChar}\n<size=10>{skills[i].skillName}</size>";

                Color rarityColor = skills[i].starGrade switch
                {
                    StarGrade.Star1 => UIColors.Rarity_Common,
                    StarGrade.Star2 => UIColors.Rarity_Rare,
                    StarGrade.Star3 => UIColors.Rarity_Epic,
                    StarGrade.Star4 => UIColors.Rarity_Legendary,
                    StarGrade.Star5 => UIColors.Rarity_Legendary,
                    _ => UIColors.Rarity_Common
                };
                readyColors[i] = new Color(rarityColor.r * READY_COLOR_MULT, rarityColor.g * READY_COLOR_MULT, rarityColor.b * READY_COLOR_MULT, 0.95f);
                cooldownColors[i] = new Color(rarityColor.r * COOLDOWN_COLOR_MULT, rarityColor.g * COOLDOWN_COLOR_MULT, rarityColor.b * COOLDOWN_COLOR_MULT, 0.9f);
                slotBgs[i].color = readyColors[i];
            }
            else
            {
                slotObjects[i].SetActive(false);
            }
        }
    }

    void UpdateCooldown(int slot, float remaining, float total)
    {
        if (slot < 0 || slot >= SLOT_COUNT) return;

        if (remaining <= 0f)
        {
            cooldownOverlays[slot].fillAmount = 0f;
            cooldownTexts[slot].text = "<size=10>준비!</size>";
            cooldownTexts[slot].color = new Color(0.6f, 1f, 0.5f);
            slotBgs[slot].color = readyColors[slot];
        }
        else
        {
            cooldownOverlays[slot].fillAmount = remaining / total;
            cooldownTexts[slot].text = Mathf.CeilToInt(remaining).ToString();
            cooldownTexts[slot].color = Color.white;
            slotBgs[slot].color = cooldownColors[slot];
        }
    }

    void OnSkillUsed(int slot)
    {
        if (slot >= 0 && slot < SLOT_COUNT && slotBgs[slot] != null)
            StartCoroutine(FlashSlot(slot));
    }

    System.Collections.IEnumerator FlashSlot(int slot)
    {
        var original = slotBgs[slot].color;
        slotBgs[slot].color = Color.white;
        yield return new WaitForSeconds(0.1f);
        slotBgs[slot].color = original;
    }

    void OnSlotClicked(int slot)
    {
        if (SkillManager.Instance != null)
            SkillManager.Instance.UseSkill(slot);
    }

    void OnAutoToggleClicked()
    {
        if (SkillManager.Instance == null) return;
        SkillManager.Instance.autoUse = !SkillManager.Instance.autoUse;

        bool isAuto = SkillManager.Instance.autoUse;
        autoToggleText.text = "A";
        autoToggleButton.GetComponent<Image>().color = isAuto ? UIColors.Button_Green : UIColors.Button_Gray;
    }


    void OnDestroy()
    {
        if (cachedSkillMgr != null)
        {
            cachedSkillMgr.OnCooldownChanged -= UpdateCooldown;
            cachedSkillMgr.OnSkillUsed -= OnSkillUsed;
        }
    }
}
