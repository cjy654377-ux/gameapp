using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
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
    const float AUTO_BTN_H = 44f;
    const float SLOT_SIZE = 58f;
    const float SLOT_SPACING = 6f;

    GameObject[] slotObjects = new GameObject[SLOT_COUNT];
    Image[] cooldownOverlays = new Image[SLOT_COUNT];
    TextMeshProUGUI[] cooldownTexts = new TextMeshProUGUI[SLOT_COUNT];
    TextMeshProUGUI[] nameTexts = new TextMeshProUGUI[SLOT_COUNT];
    Image[] slotBgs = new Image[SLOT_COUNT];
    readonly Color[] readyColors = new Color[SLOT_COUNT];
    readonly Color[] cooldownColors = new Color[SLOT_COUNT];
    TextMeshProUGUI noSkillText;
    Button autoToggleButton;
    Image autoToggleImage;
    TextMeshProUGUI autoToggleText;
    GameObject slotsContainer;

    // Buff bar (left of skill slots)
    const int BUFF_ROW_COUNT = 4;
    readonly TextMeshProUGUI[] buffTexts = new TextMeshProUGUI[BUFF_ROW_COUNT];
    readonly Image[] buffIcons = new Image[BUFF_ROW_COUNT];
    float buffRefreshTimer;
    const float BUFF_REFRESH_INTERVAL = 0.5f;

    // 시너지 변화 피드백
    readonly System.Collections.Generic.List<string> prevSynergyNames = new();
    SkillSynergyManager cachedSynergyMgr;

    Canvas canvas;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        CreateCanvas();
        CreateSkillSlots();
        CreateAutoToggle();
        CreateBuffBar();
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
        cachedSynergyMgr = SkillSynergyManager.Instance;
        if (cachedSynergyMgr != null)
        {
            // 초기 시너지 스냅샷
            foreach (var s in cachedSynergyMgr.ActiveSynergies)
                prevSynergyNames.Add(s.synergyName);
            cachedSynergyMgr.OnSynergyChanged += OnSynergyChanged;
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

        // 스킬 없을 때 안내 텍스트
        float totalWidthHint = SLOT_COUNT * SLOT_SIZE + (SLOT_COUNT - 1) * SLOT_SPACING;
        noSkillText = UIHelper.MakeText("NoSkillHint", slotsContainer.transform,
            "스킬이 없습니다",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, new Color(0.8f, 0.8f, 0.8f, 0.85f));
        noSkillText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(noSkillText);
        var nstRT = noSkillText.GetComponent<RectTransform>();
        nstRT.anchorMin = new Vector2(0.5f, 0f);
        nstRT.anchorMax = new Vector2(0.5f, 0f);
        nstRT.pivot = new Vector2(0.5f, 0f);
        nstRT.sizeDelta = new Vector2(totalWidthHint, 26f);
        nstRT.anchoredPosition = new Vector2(0, UIConstants.NavBar_Height + UIConstants.Spacing_Large);
        noSkillText.gameObject.SetActive(false);
    }

    void CreateAutoToggle()
    {
        // 스킬 슬롯 4개 우측에 작은 오토 버튼 배치
        float totalWidth = SLOT_COUNT * SLOT_SIZE + (SLOT_COUNT - 1) * SLOT_SPACING;
        float rightEdge = totalWidth * 0.5f;

        var (btn, img) = UIHelper.MakeSpriteButton("AutoToggle", slotsContainer.transform,
            UISprites.Btn1_WS, UIColors.Button_Green, "A", UIConstants.Font_LevelBadge);
        autoToggleButton = btn;
        autoToggleImage = img;
        autoToggleButton.onClick.AddListener(OnAutoToggleClicked);
        autoToggleText = btn.GetComponentInChildren<TextMeshProUGUI>();
        autoToggleText.fontStyle = FontStyles.Bold;

        var toggleRT = btn.GetComponent<RectTransform>();
        toggleRT.anchorMin = new Vector2(0.5f, 0f);
        toggleRT.anchorMax = new Vector2(0.5f, 0f);
        toggleRT.pivot = new Vector2(0f, 0f);
        toggleRT.anchoredPosition = new Vector2(rightEdge - 4f, UIConstants.NavBar_Height + UIConstants.Spacing_Large + SLOT_SIZE * 0.25f);
        toggleRT.sizeDelta = new Vector2(AUTO_BTN_W, AUTO_BTN_H);
    }

    void CreateBuffBar()
    {
        float totalWidth = SLOT_COUNT * SLOT_SIZE + (SLOT_COUNT - 1) * SLOT_SPACING;
        float leftEdge = -totalWidth * 0.5f;
        const float ROW_H = 18f;
        const float ROW_W = 64f;
        float baseY = UIConstants.NavBar_Height + UIConstants.Spacing_Large;

        for (int i = 0; i < BUFF_ROW_COUNT; i++)
        {
            var row = UIHelper.MakeUI($"Buff_{i}", slotsContainer.transform);
            var bg = row.AddComponent<Image>();
            bg.color = new Color(0, 0, 0, 0.55f);

            var rt = row.GetComponent<RectTransform>();
            rt.anchorMin = new Vector2(0.5f, 0f);
            rt.anchorMax = new Vector2(0.5f, 0f);
            rt.pivot = new Vector2(1f, 0f);
            rt.anchoredPosition = new Vector2(leftEdge + 8f, baseY + i * (ROW_H + 2f)); // 8px SafeArea 안쪽
            rt.sizeDelta = new Vector2(ROW_W, ROW_H);

            // 좌단 아이콘
            buffIcons[i] = UIHelper.MakeIcon($"BuffIcon_{i}", row.transform, null, Color.white);
            buffIcons[i].preserveAspect = true;
            buffIcons[i].raycastTarget = false;
            var biRT = buffIcons[i].GetComponent<RectTransform>();
            biRT.anchorMin = new Vector2(0f, 0.1f);
            biRT.anchorMax = new Vector2(0f, 0.9f);
            biRT.pivot = new Vector2(0f, 0.5f);
            biRT.sizeDelta = new Vector2(14f, 0f);
            biRT.anchoredPosition = new Vector2(2f, 0f);

            buffTexts[i] = UIHelper.MakeText($"BuffText_{i}", row.transform, "",
                8f, TextAlignmentOptions.MidlineLeft, Color.white);
            buffTexts[i].raycastTarget = false;
            var btRT = buffTexts[i].GetComponent<RectTransform>();
            btRT.anchorMin = new Vector2(0f, 0f);
            btRT.anchorMax = new Vector2(1f, 1f);
            btRT.offsetMin = new Vector2(18f, 0f);
            btRT.offsetMax = Vector2.zero;
            row.SetActive(false);
        }
    }

    void Update()
    {
        buffRefreshTimer -= Time.unscaledDeltaTime;
        if (buffRefreshTimer > 0) return;
        buffRefreshTimer = BUFF_REFRESH_INTERVAL;
        RefreshBuffBar();
    }

    void RefreshBuffBar()
    {
        int row = 0;

        // 복수자 스택
        var sm = StageManager.Instance;
        if (sm != null && sm.RevengeStack > 0)
            SetBuffRow(row++, $"복수자 x{sm.RevengeStack}", new Color(1f, 0.5f, 0.2f), UISprites.IconPotion1);

        // 골드 부스트
        var gm = GoldManager.Instance;
        if (gm != null && gm.IsBoostActive)
        {
            int remain = Mathf.CeilToInt(gm.GetBoostTimeRemaining() / 60f);
            SetBuffRow(row++, $"2x {remain}m", new Color(1f, 0.85f, 0.2f), UISprites.IconGold);
        }

        // 시너지 ATK 보너스
        var ssm = SkillSynergyManager.Instance;
        if (ssm != null && ssm.GetAtkPercent() > 0)
            SetBuffRow(row++, $"ATK+{ssm.GetAtkPercent():F0}%", new Color(0.5f, 1f, 1f), UISprites.IconSkill);

        // 에리어 디버프 (Desert, Cave, Volcano, Abyss)
        if (sm != null && sm.CurrentAreaEnum != StageManager.GameArea.Grass)
        {
            string areaDebuff = sm.CurrentAreaEnum switch
            {
                StageManager.GameArea.Desert  => "모래폭풍",
                StageManager.GameArea.Cave    => "중갑 적",
                StageManager.GameArea.Volcano => "용암지대",
                StageManager.GameArea.Abyss   => "심연",
                _ => ""
            };
            if (!string.IsNullOrEmpty(areaDebuff))
                SetBuffRow(row++, areaDebuff, new Color(1f, 0.4f, 0.4f), UISprites.IconSword);
        }

        // 사용하지 않는 행 숨기기
        for (int i = row; i < BUFF_ROW_COUNT; i++)
        {
            if (buffTexts[i] != null && buffTexts[i].transform.parent != null)
                buffTexts[i].transform.parent.gameObject.SetActive(false);
        }
    }

    void SetBuffRow(int idx, string text, Color color, Sprite icon = null)
    {
        if (idx >= BUFF_ROW_COUNT || buffTexts[idx] == null) return;
        var rowGO = buffTexts[idx].transform.parent.gameObject;
        rowGO.SetActive(true);
        buffTexts[idx].text = text;
        buffTexts[idx].color = color;
        if (buffIcons[idx] != null)
        {
            buffIcons[idx].sprite = icon;
            buffIcons[idx].color = icon != null ? color : Color.clear;
        }
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

                // 길게 누르기 → 스킬 정보 팝업
                SkillInfoPopup.AddLongPress(slotObjects[i], skills[i]);

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

        bool anyActive = skills.Count > 0 && skills.Exists(s => s != null);
        if (noSkillText != null) noSkillText.gameObject.SetActive(!anyActive && !_isTabPanelOpen);
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

    void OnSynergyChanged()
    {
        var ssm = cachedSynergyMgr;
        if (ssm == null) return;

        // 추가된 시너지
        foreach (var s in ssm.ActiveSynergies)
        {
            if (!prevSynergyNames.Contains(s.synergyName))
            {
                string bonusStr = BuildBonusStr(s);
                ToastNotification.Instance?.Show($"⚡ {s.synergyName} 시너지 활성화!", bonusStr, new Color(0.3f, 0.8f, 1f));
            }
        }

        // 해제된 시너지
        foreach (var name in prevSynergyNames)
        {
            bool stillActive = false;
            foreach (var s in ssm.ActiveSynergies)
                if (s.synergyName == name) { stillActive = true; break; }
            if (!stillActive)
                ToastNotification.Instance?.Show($"⚡ {name} 시너지 해제됨", "", UIColors.Text_Disabled);
        }

        prevSynergyNames.Clear();
        foreach (var s in ssm.ActiveSynergies)
            prevSynergyNames.Add(s.synergyName);
    }

    static string BuildBonusStr(SkillSynergyData s)
    {
        var parts = new System.Collections.Generic.List<string>();
        if (s.bonus.bonusAtkPercent > 0) parts.Add($"ATK +{s.bonus.bonusAtkPercent:F0}%");
        if (s.bonus.bonusDefPercent > 0) parts.Add($"DEF +{s.bonus.bonusDefPercent:F0}%");
        if (s.bonus.bonusHpPercent  > 0) parts.Add($"HP +{s.bonus.bonusHpPercent:F0}%");
        if (s.bonus.bonusDmgPercent > 0) parts.Add($"DMG +{s.bonus.bonusDmgPercent:F0}%");
        if (s.bonus.cooldownReduction > 0) parts.Add($"CD -{s.bonus.cooldownReduction:F0}%");
        return parts.Count > 0 ? string.Join(" / ", parts) : s.description;
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
        if (autoToggleImage != null)
            autoToggleImage.color = isAuto ? UIColors.Button_Green : UIColors.Button_Gray;
    }


    void OnDestroy()
    {
        if (Instance == this) Instance = null;
        if (cachedSkillMgr != null)
        {
            cachedSkillMgr.OnCooldownChanged -= UpdateCooldown;
            cachedSkillMgr.OnSkillUsed -= OnSkillUsed;
        }
        if (cachedSynergyMgr != null)
            cachedSynergyMgr.OnSynergyChanged -= OnSynergyChanged;
    }
}
