using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class SkillUI : MonoBehaviour
{
    public static SkillUI Instance { get; private set; }

    GameObject[] slotObjects = new GameObject[4];
    Image[] cooldownOverlays = new Image[4];
    TextMeshProUGUI[] cooldownTexts = new TextMeshProUGUI[4];
    TextMeshProUGUI[] nameTexts = new TextMeshProUGUI[4];
    Image[] slotBgs = new Image[4];
    Button autoToggleButton;
    TextMeshProUGUI autoToggleText;

    Canvas canvas;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        CreateCanvas();
        CreateSkillSlots();
        CreateAutoToggle();
    }

    void Start()
    {
        if (SkillManager.Instance != null)
        {
            SkillManager.Instance.OnCooldownChanged += UpdateCooldown;
            SkillManager.Instance.OnSkillUsed += OnSkillUsed;
            RefreshSlots();
        }
    }

    void CreateCanvas()
    {
        canvas = gameObject.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvas.sortingOrder = 99;

        var scaler = gameObject.AddComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = new Vector2(1920, 1080);

        gameObject.AddComponent<GraphicRaycaster>();
    }

    void CreateSkillSlots()
    {
        float slotSize = 90f;
        float spacing = 10f;
        float totalWidth = 4 * slotSize + 3 * spacing;
        float startX = -totalWidth * 0.5f + slotSize * 0.5f;

        for (int i = 0; i < 4; i++)
        {
            var slot = CreateUIObject($"SkillSlot_{i}", canvas.transform);
            slotObjects[i] = slot;

            // Position at bottom center
            var rt = slot.GetComponent<RectTransform>();
            rt.anchorMin = new Vector2(0.5f, 0f);
            rt.anchorMax = new Vector2(0.5f, 0f);
            rt.pivot = new Vector2(0.5f, 0f);
            rt.anchoredPosition = new Vector2(startX + i * (slotSize + spacing), 20f);
            rt.sizeDelta = new Vector2(slotSize, slotSize);

            // Background with rarity border
            var bg = slot.AddComponent<Image>();
            bg.color = new Color(0.15f, 0.15f, 0.2f, 0.9f);
            slotBgs[i] = bg;

            // Button for manual use
            var btn = slot.AddComponent<Button>();
            int slotIdx = i;
            btn.onClick.AddListener(() => OnSlotClicked(slotIdx));
            btn.targetGraphic = bg;

            // Skill icon/name text
            var nameObj = CreateUIObject("Name", slot.transform);
            nameTexts[i] = nameObj.AddComponent<TextMeshProUGUI>();
            nameTexts[i].fontSize = 16;
            nameTexts[i].alignment = TextAlignmentOptions.Center;
            nameTexts[i].color = Color.white;
            var nameRT = nameObj.GetComponent<RectTransform>();
            nameRT.anchorMin = Vector2.zero;
            nameRT.anchorMax = Vector2.one;
            nameRT.sizeDelta = Vector2.zero;
            nameRT.anchoredPosition = new Vector2(0, 5);

            // Cooldown overlay
            var cdObj = CreateUIObject("CooldownOverlay", slot.transform);
            cooldownOverlays[i] = cdObj.AddComponent<Image>();
            cooldownOverlays[i].color = new Color(0, 0, 0, 0.6f);
            cooldownOverlays[i].type = Image.Type.Filled;
            cooldownOverlays[i].fillMethod = Image.FillMethod.Vertical;
            cooldownOverlays[i].fillOrigin = 0;
            cooldownOverlays[i].fillAmount = 0f;
            var cdRT = cdObj.GetComponent<RectTransform>();
            cdRT.anchorMin = Vector2.zero;
            cdRT.anchorMax = Vector2.one;
            cdRT.sizeDelta = Vector2.zero;

            // Cooldown timer text
            var timerObj = CreateUIObject("Timer", slot.transform);
            cooldownTexts[i] = timerObj.AddComponent<TextMeshProUGUI>();
            cooldownTexts[i].fontSize = 24;
            cooldownTexts[i].alignment = TextAlignmentOptions.Center;
            cooldownTexts[i].color = Color.white;
            cooldownTexts[i].text = "";
            var timerRT = timerObj.GetComponent<RectTransform>();
            timerRT.anchorMin = Vector2.zero;
            timerRT.anchorMax = Vector2.one;
            timerRT.sizeDelta = Vector2.zero;
        }
    }

    void CreateAutoToggle()
    {
        var toggleObj = CreateUIObject("AutoToggle", canvas.transform);
        var toggleImg = toggleObj.AddComponent<Image>();
        toggleImg.color = new Color(0.2f, 0.6f, 0.3f, 0.9f);
        autoToggleButton = toggleObj.AddComponent<Button>();
        autoToggleButton.targetGraphic = toggleImg;
        autoToggleButton.onClick.AddListener(OnAutoToggleClicked);

        var toggleRT = toggleObj.GetComponent<RectTransform>();
        toggleRT.anchorMin = new Vector2(0.5f, 0f);
        toggleRT.anchorMax = new Vector2(0.5f, 0f);
        toggleRT.pivot = new Vector2(0.5f, 0f);
        toggleRT.anchoredPosition = new Vector2(250f, 45f);
        toggleRT.sizeDelta = new Vector2(80f, 40f);

        var textObj = CreateUIObject("Text", toggleObj.transform);
        autoToggleText = textObj.AddComponent<TextMeshProUGUI>();
        autoToggleText.text = "AUTO";
        autoToggleText.fontSize = 20;
        autoToggleText.alignment = TextAlignmentOptions.Center;
        autoToggleText.color = Color.white;
        autoToggleText.fontStyle = FontStyles.Bold;
        var textRT = textObj.GetComponent<RectTransform>();
        textRT.anchorMin = Vector2.zero;
        textRT.anchorMax = Vector2.one;
        textRT.sizeDelta = Vector2.zero;
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
                nameTexts[i].text = $"{skills[i].iconChar}\n<size=12>{skills[i].skillName}</size>";

                // Rarity color border
                Color rarityColor = skills[i].rarity switch
                {
                    SkillRarity.Common => new Color(0.5f, 0.5f, 0.5f),
                    SkillRarity.Rare => new Color(0.3f, 0.5f, 1f),
                    SkillRarity.Epic => new Color(0.6f, 0.2f, 0.8f),
                    SkillRarity.Legendary => new Color(1f, 0.7f, 0.1f),
                    _ => Color.gray
                };
                slotBgs[i].color = new Color(rarityColor.r * 0.3f, rarityColor.g * 0.3f, rarityColor.b * 0.3f, 0.9f);
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
        }
        else
        {
            cooldownOverlays[slot].fillAmount = remaining / total;
            cooldownTexts[slot].text = Mathf.CeilToInt(remaining).ToString();
        }
    }

    void OnSkillUsed(int slot)
    {
        // Flash effect
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
        autoToggleText.text = isAuto ? "AUTO" : "MANUAL";
        autoToggleButton.GetComponent<Image>().color =
            isAuto ? new Color(0.2f, 0.6f, 0.3f, 0.9f) : new Color(0.5f, 0.3f, 0.3f, 0.9f);
    }

    GameObject CreateUIObject(string name, Transform parent)
    {
        var obj = new GameObject(name, typeof(RectTransform));
        obj.transform.SetParent(parent, false);
        return obj;
    }

    void OnDestroy()
    {
        if (SkillManager.Instance != null)
        {
            SkillManager.Instance.OnCooldownChanged -= UpdateCooldown;
            SkillManager.Instance.OnSkillUsed -= OnSkillUsed;
        }
    }
}
