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

    GameObject[] slotObjects = new GameObject[4];
    Image[] cooldownOverlays = new Image[4];
    TextMeshProUGUI[] cooldownTexts = new TextMeshProUGUI[4];
    TextMeshProUGUI[] nameTexts = new TextMeshProUGUI[4];
    Image[] slotBgs = new Image[4];
    readonly Color[] readyColors = new Color[4];
    readonly Color[] cooldownColors = new Color[4];
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
        canvas.sortingOrder = 50;

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

        float slotSize = UIConstants.MinTouchTarget;
        float spacing = UIConstants.Spacing_Medium;
        float totalWidth = 4 * slotSize + 3 * spacing;
        float startX = -totalWidth * 0.5f + slotSize * 0.5f;

        for (int i = 0; i < 4; i++)
        {
            var slot = UIHelper.MakeUI($"SkillSlot_{i}", slotsContainer.transform);
            slotObjects[i] = slot;

            var rt = slot.GetComponent<RectTransform>();
            rt.anchorMin = new Vector2(0.5f, 0f);
            rt.anchorMax = new Vector2(0.5f, 0f);
            rt.pivot = new Vector2(0.5f, 0f);
            rt.anchoredPosition = new Vector2(startX + i * (slotSize + spacing), UIConstants.NavBar_Height + UIConstants.Spacing_Medium);
            rt.sizeDelta = new Vector2(slotSize, slotSize);

            var bg = slot.AddComponent<Image>();
            bg.color = UIColors.Panel_Inner;
            slotBgs[i] = bg;

            var btn = slot.AddComponent<Button>();
            int slotIdx = i;
            btn.onClick.AddListener(() => OnSlotClicked(slotIdx));
            btn.targetGraphic = bg;

            // Skill name
            nameTexts[i] = UIHelper.MakeText("Name", slot.transform, "",
                UIConstants.Font_Tab, TextAlignmentOptions.Center);
            var nameRT = nameTexts[i].GetComponent<RectTransform>();
            UIHelper.FillParent(nameRT);
            nameRT.anchoredPosition = new Vector2(0, 3);

            // Cooldown overlay
            var cdObj = UIHelper.MakeUI("CooldownOverlay", slot.transform);
            cooldownOverlays[i] = cdObj.AddComponent<Image>();
            cooldownOverlays[i].color = UIColors.Overlay_Dark;
            cooldownOverlays[i].type = Image.Type.Filled;
            cooldownOverlays[i].fillMethod = Image.FillMethod.Vertical;
            cooldownOverlays[i].fillOrigin = 0;
            cooldownOverlays[i].fillAmount = 0f;
            UIHelper.FillParent(cdObj.GetComponent<RectTransform>());

            // Cooldown timer text
            cooldownTexts[i] = UIHelper.MakeText("Timer", slot.transform, "",
                UIConstants.Font_StatValue, TextAlignmentOptions.Center);
            UIHelper.FillParent(cooldownTexts[i].GetComponent<RectTransform>());
        }
    }

    void CreateAutoToggle()
    {
        var (btn, img) = UIHelper.MakeButton("AutoToggle", canvas.transform,
            UIColors.Button_Green, "자동", UIConstants.Font_Tab);
        autoToggleButton = btn;
        autoToggleButton.onClick.AddListener(OnAutoToggleClicked);
        autoToggleText = btn.GetComponentInChildren<TextMeshProUGUI>();

        var toggleRT = btn.GetComponent<RectTransform>();
        toggleRT.anchorMin = new Vector2(1f, 0f);
        toggleRT.anchorMax = new Vector2(1f, 0f);
        toggleRT.pivot = new Vector2(1f, 0f);
        toggleRT.anchoredPosition = new Vector2(-UIConstants.Spacing_Medium, UIConstants.NavBar_Height + UIConstants.Spacing_Medium);
        toggleRT.sizeDelta = new Vector2(60f, 30f);
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

        for (int i = 0; i < 4; i++)
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
                readyColors[i] = new Color(rarityColor.r * 0.6f, rarityColor.g * 0.6f, rarityColor.b * 0.6f, 0.95f);
                cooldownColors[i] = new Color(rarityColor.r * 0.15f, rarityColor.g * 0.15f, rarityColor.b * 0.15f, 0.9f);
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
        if (slot < 0 || slot >= 4) return;

        if (remaining <= 0f)
        {
            cooldownOverlays[slot].fillAmount = 0f;
            cooldownTexts[slot].text = "";
            slotBgs[slot].color = readyColors[slot];
        }
        else
        {
            cooldownOverlays[slot].fillAmount = remaining / total;
            cooldownTexts[slot].text = Mathf.CeilToInt(remaining).ToString();
            slotBgs[slot].color = cooldownColors[slot];
        }
    }

    void OnSkillUsed(int slot)
    {
        if (slot >= 0 && slot < 4 && slotBgs[slot] != null)
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
        autoToggleText.text = isAuto ? "자동" : "수동";
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
