using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections.Generic;

/// <summary>
/// 훈련 패널: 번개 업그레이드 + 스킬 강화
/// MainHUD 훈련 탭(index 0)에서 Init(parent)로 초기화
/// </summary>
public class UpgradePanel : MonoBehaviour
{
    TextMeshProUGUI tapUpText;
    Button tapUpBtn;

    GameObject skillUpgradeContainer;
    readonly List<GameObject> skillUpgradeItems = new();

    // ════════════════════════════════════════
    // 초기화
    // ════════════════════════════════════════

    public void Init(Transform parent)
    {
        var content = UIHelper.MakeUI("UpgradeContent", parent);
        var contentRT = content.GetComponent<RectTransform>();
        contentRT.anchorMin = new Vector2(0, 0);
        contentRT.anchorMax = new Vector2(1, 1);
        contentRT.offsetMin = new Vector2(UIConstants.Spacing_Small, UIConstants.Spacing_Small);
        contentRT.offsetMax = new Vector2(-UIConstants.Spacing_Small, -UIConstants.Tab_Height);

        // 번개 업그레이드 (상단 25%)
        BuildUpgradeRow(content.transform, "번개", 0, 0.25f,
            ref tapUpText, ref tapUpBtn, () =>
            {
                var tap = TapDamageSystem.Instance;
                if (tap != null && !tap.UpgradeTapDamage())
                    ToastNotification.Instance?.Show("골드 부족!", $"{tap.UpgradeCost}G 필요", UIColors.Defeat_Red);
                Refresh();
            });

        // 스킬 강화 라벨
        var skillLabel = UIHelper.MakeText("SkillLabel", content.transform, "스킬 강화",
            UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, UIColors.Text_DarkGold);
        skillLabel.fontStyle = FontStyles.Bold;
        var slrt = skillLabel.GetComponent<RectTransform>();
        slrt.anchorMin = new Vector2(0, 0.7f);
        slrt.anchorMax = new Vector2(1, 0.75f);
        slrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
        slrt.offsetMax = Vector2.zero;

        // 스킬 강화 스크롤
        var scrollObj = UIHelper.MakeUI("SkillUpScroll", content.transform);
        var scrollRT = scrollObj.GetComponent<RectTransform>();
        scrollRT.anchorMin = new Vector2(0, 0);
        scrollRT.anchorMax = new Vector2(1, 0.7f);
        scrollRT.offsetMin = Vector2.zero;
        scrollRT.offsetMax = Vector2.zero;

        var scrollRect = scrollObj.AddComponent<ScrollRect>();
        scrollRect.horizontal = false;
        scrollRect.vertical = true;

        var viewport = UIHelper.MakeUI("Viewport", scrollObj.transform);
        viewport.AddComponent<RectMask2D>();
        UIHelper.FillParent(viewport.GetComponent<RectTransform>());
        scrollRect.viewport = viewport.GetComponent<RectTransform>();

        skillUpgradeContainer = UIHelper.MakeUI("Content", viewport.transform);
        var crt2 = skillUpgradeContainer.GetComponent<RectTransform>();
        crt2.anchorMin = new Vector2(0, 1);
        crt2.anchorMax = new Vector2(1, 1);
        crt2.pivot = new Vector2(0.5f, 1);
        crt2.anchoredPosition = Vector2.zero;
        scrollRect.content = crt2;
    }

    // ════════════════════════════════════════
    // 갱신
    // ════════════════════════════════════════

    public void Refresh()
    {
        RefreshSkillUpgradeUI();
        var tap = TapDamageSystem.Instance;
        if (tap != null && tapUpText != null)
            tapUpText.text = $"Lv.{tap.tapDamageLevel}  DMG:{tap.TapDamage:F0}";
        if (tap != null)
            SetUpgradeBtnCost(tapUpBtn, tap.UpgradeCost);
    }

    // ════════════════════════════════════════
    // 빌드 헬퍼
    // ════════════════════════════════════════

    void BuildUpgradeRow(Transform parent, string label, int index, float rowH,
        ref TextMeshProUGUI infoText, ref Button btn, UnityEngine.Events.UnityAction onClick)
    {
        float yMax = 1f - index * rowH;
        float yMin = yMax - rowH;

        var rowImg = UIHelper.MakeSpritePanel($"{label}Row", parent,
            UISprites.BoxBasic3, UIColors.Panel_Inner);
        var rrt = rowImg.GetComponent<RectTransform>();
        rrt.anchorMin = new Vector2(0, yMin);
        rrt.anchorMax = new Vector2(1, yMax);
        rrt.offsetMin = new Vector2(4, 2);
        rrt.offsetMax = new Vector2(-4, -2);

        var labelText = UIHelper.MakeText($"{label}Label", rowImg.transform, label,
            UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, UIColors.Text_Dark);
        labelText.fontStyle = FontStyles.Bold;
        var llrt = labelText.GetComponent<RectTransform>();
        llrt.anchorMin = new Vector2(0, 0);
        llrt.anchorMax = new Vector2(0.18f, 1);
        llrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
        llrt.offsetMax = Vector2.zero;

        infoText = UIHelper.MakeText($"{label}Info", rowImg.transform, "",
            UIConstants.Font_StatValue, TextAlignmentOptions.MidlineLeft, UIColors.Text_Dark);
        infoText.fontStyle = FontStyles.Bold;
        var irt = infoText.GetComponent<RectTransform>();
        irt.anchorMin = new Vector2(0.18f, 0);
        irt.anchorMax = new Vector2(0.65f, 1);
        irt.offsetMin = new Vector2(UIConstants.Spacing_Small, 0);
        irt.offsetMax = Vector2.zero;

        var (upgradeBtn, _) = UIHelper.MakeSpriteButton($"{label}Btn", rowImg.transform,
            UISprites.Btn2_WS, UIColors.Button_Green, "", UIConstants.Font_Cost);
        btn = upgradeBtn;
        btn.onClick.AddListener(onClick);

        var ubrt = btn.GetComponent<RectTransform>();
        ubrt.anchorMin = new Vector2(0.68f, 0.1f);
        ubrt.anchorMax = new Vector2(0.97f, 0.9f);
        ubrt.offsetMin = Vector2.zero;
        ubrt.offsetMax = Vector2.zero;

        var costText = UIHelper.MakeText("Cost", btn.transform, "",
            UIConstants.Font_Cost, TextAlignmentOptions.Center, Color.white);
        costText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(costText);
        UIHelper.FillParent(costText.GetComponent<RectTransform>());
    }

    void SetUpgradeBtnCost(Button b, int cost)
    {
        if (b == null) return;
        var text = b.GetComponentInChildren<TextMeshProUGUI>();
        if (text != null) text.text = $"{cost}G";
        bool canAfford = GoldManager.Instance != null && GoldManager.Instance.Gold >= cost;
        var img = b.GetComponent<Image>();
        if (img.sprite != null)
            img.color = canAfford ? Color.white : new Color(0.70f, 0.70f, 0.70f);
        else
            img.color = canAfford ? UIColors.Button_Green : UIColors.Button_Gray;
    }

    // ════════════════════════════════════════
    // 스킬 강화 목록
    // ════════════════════════════════════════

    void RefreshSkillUpgradeUI()
    {
        if (skillUpgradeContainer == null) return;
        var sm = SkillManager.Instance;
        var sum = SkillUpgradeManager.Instance;
        if (sm == null) return;

        RecycleList(skillUpgradeItems);
        int reuse = 0;
        float itemH = 38f;
        float spacing = 2f;
        float y = 0;
        int activeCount = 0;

        for (int i = 0; i < sm.equippedSkills.Count && i < 4; i++)
        {
            var skill = sm.equippedSkills[i];
            if (skill == null) continue;

            var item = ReuseOrCreate(skillUpgradeItems, ref reuse,
                $"SkillUp_{i}", skillUpgradeContainer.transform, new Color(0.92f, 0.88f, 0.82f));
            activeCount++;
            var irt = item.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0, 1);
            irt.anchorMax = new Vector2(1, 1);
            irt.pivot = new Vector2(0.5f, 1);
            irt.anchoredPosition = new Vector2(0, y);
            irt.sizeDelta = new Vector2(0, itemH);

            int level = sum != null ? sum.GetLevel(skill.skillName) : 1;
            int cost = sum != null ? sum.GetUpgradeCost(skill.skillName) : 0;
            bool canUp = sum != null && sum.CanUpgrade(skill.skillName);
            float dmgMult = sum != null ? sum.GetDamageMultiplier(skill.skillName) : 1f;

            var nameText = UIHelper.MakeText("Name", item.transform,
                $"{skill.iconChar} {skill.skillName}",
                UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, UIColors.Text_Dark);
            nameText.fontStyle = FontStyles.Bold;
            var nrt = nameText.GetComponent<RectTransform>();
            nrt.anchorMin = new Vector2(0, 0);
            nrt.anchorMax = new Vector2(0.35f, 1);
            nrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
            nrt.offsetMax = Vector2.zero;

            string info = $"Lv.{level} DMG:{dmgMult:P0}";
            var infoText = UIHelper.MakeText("Info", item.transform, info,
                9f, TextAlignmentOptions.Center, UIColors.Text_DarkGold);
            var inrt = infoText.GetComponent<RectTransform>();
            inrt.anchorMin = new Vector2(0.35f, 0);
            inrt.anchorMax = new Vector2(0.65f, 1);
            inrt.offsetMin = Vector2.zero;
            inrt.offsetMax = Vector2.zero;

            string btnLabel = level >= SkillUpgradeManager.MAX_SKILL_LEVEL ? "MAX" : $"{cost}G";
            var (btn, skillBtnImg) = UIHelper.MakeSpriteButton($"Up_{i}", item.transform,
                canUp ? UISprites.Btn2_WS : UISprites.Btn1_WS,
                canUp ? UIColors.Button_Green : UIColors.Button_Gray, "", 10f);
            if (!canUp && skillBtnImg.sprite != null) skillBtnImg.color = new Color(0.70f, 0.70f, 0.70f);
            var brt = btn.GetComponent<RectTransform>();
            brt.anchorMin = new Vector2(0.68f, 0.1f);
            brt.anchorMax = new Vector2(0.97f, 0.9f);
            brt.offsetMin = Vector2.zero;
            brt.offsetMax = Vector2.zero;
            var btnText = UIHelper.MakeText("Label", btn.transform, btnLabel,
                UIConstants.Font_Cost, TextAlignmentOptions.Center,
                canUp ? Color.white : UIColors.Text_Disabled);
            btnText.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(btnText.GetComponent<RectTransform>());

            if (canUp)
            {
                string capturedName = skill.skillName;
                btn.onClick.AddListener(() =>
                {
                    if (sum != null && !sum.TryUpgrade(capturedName))
                        ToastNotification.Instance?.Show("골드 부족!", "", UIColors.Defeat_Red);
                    Refresh();
                });
            }

            y -= (itemH + spacing);
        }

        TrimExcess(skillUpgradeItems, activeCount);
        var containerRT = skillUpgradeContainer.GetComponent<RectTransform>();
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
}
