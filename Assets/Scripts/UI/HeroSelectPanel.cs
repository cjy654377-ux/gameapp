using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections.Generic;

/// <summary>
/// 영웅 선택 팝업 (장비 장착용)
/// MainHUD.BuildUI()에서 Init(safeAreaRoot, onEquipped)으로 초기화
/// Show(equipItemId)로 표시
/// </summary>
public class HeroSelectPanel : MonoBehaviour
{
    GameObject popup;
    GameObject listContainer;
    readonly List<GameObject> listItems = new();
    string pendingEquipItemId;
    System.Action onEquipped;

    public void Init(Transform parent, System.Action onEquippedCallback)
    {
        onEquipped = onEquippedCallback;
        BuildPopup(parent);
    }

    public void Show(string equipItemId)
    {
        pendingEquipItemId = equipItemId;
        RefreshList();
        popup.SetActive(true);
        SoundManager.Instance?.PlayButtonSFX();
    }

    void Hide() => popup.SetActive(false);

    void BuildPopup(Transform parent)
    {
        popup = UIHelper.MakeUI("HeroSelectPopup", parent);
        var bg = popup.AddComponent<Image>();
        bg.color = UIColors.Overlay_Dark;
        UIHelper.FillParent(popup.GetComponent<RectTransform>());

        var tapClose = popup.AddComponent<Button>();
        tapClose.targetGraphic = bg;
        tapClose.onClick.AddListener(Hide);

        var panelBg = UIHelper.MakeSpritePanel("Panel", popup.transform,
            UISprites.BoxBasic1, UIColors.Background_Panel);
        var prt = panelBg.GetComponent<RectTransform>();
        prt.anchorMin = new Vector2(0.08f, 0.25f);
        prt.anchorMax = new Vector2(0.92f, 0.75f);
        prt.offsetMin = Vector2.zero;
        prt.offsetMax = Vector2.zero;

        var titleBar = UIHelper.MakeSpritePanel("TitleBar", panelBg.transform,
            UISprites.Board, UIColors.Background_Dark);
        var titleBarRT = titleBar.GetComponent<RectTransform>();
        titleBarRT.anchorMin = new Vector2(0, 0.88f);
        titleBarRT.anchorMax = new Vector2(1, 1);
        titleBarRT.offsetMin = Vector2.zero;
        titleBarRT.offsetMax = Vector2.zero;

        var titleText = UIHelper.MakeText("Title", titleBar.transform, "장비 장착할 영웅 선택",
            UIConstants.Font_HeaderMedium, TextAlignmentOptions.Center, Color.white);
        titleText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(titleText);
        var trt = titleText.GetComponent<RectTransform>();
        trt.anchorMin = new Vector2(0.05f, 0);
        trt.anchorMax = new Vector2(0.88f, 1);
        trt.offsetMin = Vector2.zero;
        trt.offsetMax = Vector2.zero;

        var closeObj = UIHelper.MakeUI("CloseBtn", titleBar.transform);
        var closeBtnImg = closeObj.AddComponent<Image>();
        if (UISprites.BtnX != null)
        {
            closeBtnImg.sprite = UISprites.BtnX;
            closeBtnImg.type = Image.Type.Simple;
            closeBtnImg.preserveAspect = true;
            closeBtnImg.color = Color.white;
        }
        else closeBtnImg.color = UIColors.Button_Brown;
        var closeBtn = closeObj.AddComponent<Button>();
        closeBtn.targetGraphic = closeBtnImg;
        var closeBtnRT = closeBtn.GetComponent<RectTransform>();
        closeBtnRT.anchorMin = new Vector2(1, 0.5f);
        closeBtnRT.anchorMax = new Vector2(1, 0.5f);
        closeBtnRT.pivot = new Vector2(1, 0.5f);
        closeBtnRT.sizeDelta = new Vector2(24, 24);
        closeBtnRT.anchoredPosition = new Vector2(-6, 0);
        closeBtn.onClick.AddListener(Hide);

        var scrollObj = UIHelper.MakeUI("HeroScroll", panelBg.transform);
        var scrollRT = scrollObj.GetComponent<RectTransform>();
        scrollRT.anchorMin = new Vector2(0, 0);
        scrollRT.anchorMax = new Vector2(1, 0.86f);
        scrollRT.offsetMin = new Vector2(UIConstants.Spacing_Small, UIConstants.Spacing_Small);
        scrollRT.offsetMax = new Vector2(-UIConstants.Spacing_Small, 0);

        var scrollRect = scrollObj.AddComponent<ScrollRect>();
        scrollRect.horizontal = false;
        scrollRect.vertical = true;

        var viewport = UIHelper.MakeUI("Viewport", scrollObj.transform);
        viewport.AddComponent<RectMask2D>();
        UIHelper.FillParent(viewport.GetComponent<RectTransform>());
        scrollRect.viewport = viewport.GetComponent<RectTransform>();

        listContainer = UIHelper.MakeUI("Content", viewport.transform);
        var hcRT = listContainer.GetComponent<RectTransform>();
        hcRT.anchorMin = new Vector2(0, 1);
        hcRT.anchorMax = new Vector2(1, 1);
        hcRT.pivot = new Vector2(0.5f, 1);
        hcRT.anchoredPosition = Vector2.zero;
        scrollRect.content = hcRT;

        popup.SetActive(false);
    }

    void RefreshList()
    {
        if (listContainer == null) return;
        var dm = DeckManager.Instance;
        if (dm == null) return;

        for (int i = 0; i < listItems.Count; i++)
            if (listItems[i] != null) Object.Destroy(listItems[i]);
        listItems.Clear();

        float itemH = 48f;
        float spacing = 3f;
        float y = 0;

        EquipmentItem pendingItem = null;
        if (EquipmentManager.Instance != null)
        {
            var inv = EquipmentManager.Instance.Inventory;
            for (int i = 0; i < inv.Count; i++)
                if (inv[i].id == pendingEquipItemId) { pendingItem = inv[i]; break; }
        }

        if (pendingItem != null)
        {
            var infoImg = UIHelper.MakePanel("EquipInfo", listContainer.transform, new Color(0.85f, 0.78f, 0.68f));
            listItems.Add(infoImg.gameObject);
            var infoRT = infoImg.GetComponent<RectTransform>();
            infoRT.anchorMin = new Vector2(0, 1);
            infoRT.anchorMax = new Vector2(1, 1);
            infoRT.pivot = new Vector2(0.5f, 1);
            infoRT.anchoredPosition = new Vector2(0, y);
            infoRT.sizeDelta = new Vector2(0, 32f);

            string stars = new string('\u2605', pendingItem.rarity);
            string statStr = "";
            if (pendingItem.bonusAtk > 0) statStr += $"ATK+{pendingItem.bonusAtk:F0} ";
            if (pendingItem.bonusDef > 0) statStr += $"DEF+{pendingItem.bonusDef:F0} ";
            if (pendingItem.bonusHp > 0) statStr += $"HP+{pendingItem.bonusHp:F0}";

            var infoText = UIHelper.MakeText("Info", infoImg.transform,
                $"{stars} {pendingItem.itemName}  {statStr}",
                9f, TextAlignmentOptions.Center, UIColors.Text_DarkGold);
            UIHelper.FillParent(infoText.GetComponent<RectTransform>());

            y -= (32f + spacing);
        }

        for (int i = 0; i < dm.roster.Count; i++)
        {
            var preset = dm.roster[i];
            if (preset == null || preset.isEnemy) continue;
            string heroName = preset.characterName;
            Color rarityCol = GetStarGradeColor(preset.starGrade);
            string rarityLabel = GetStarGradeLabel(preset.starGrade);

            var itemImg = UIHelper.MakePanel($"Hero_{i}", listContainer.transform, new Color(0.92f, 0.88f, 0.82f));
            var item = itemImg.gameObject;
            listItems.Add(item);
            var irt = item.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0, 1);
            irt.anchorMax = new Vector2(1, 1);
            irt.pivot = new Vector2(0.5f, 1);
            irt.anchoredPosition = new Vector2(0, y);
            irt.sizeDelta = new Vector2(0, itemH);

            var rarityBar = UIHelper.MakeUI("RarityBar", item.transform);
            var rarityBarImg = rarityBar.AddComponent<Image>();
            rarityBarImg.color = rarityCol;
            var rbRT = rarityBar.GetComponent<RectTransform>();
            rbRT.anchorMin = new Vector2(0, 0);
            rbRT.anchorMax = new Vector2(0, 1);
            rbRT.pivot = new Vector2(0, 0.5f);
            rbRT.sizeDelta = new Vector2(4f, 0);
            rbRT.anchoredPosition = Vector2.zero;

            var badge = UIHelper.MakeUI("Badge", item.transform);
            var badgeImg = badge.AddComponent<Image>();
            badgeImg.color = rarityCol;
            var badgeRT = badge.GetComponent<RectTransform>();
            badgeRT.anchorMin = new Vector2(0, 0.55f);
            badgeRT.anchorMax = new Vector2(0, 1);
            badgeRT.pivot = new Vector2(0, 1);
            badgeRT.sizeDelta = new Vector2(32f, 0);
            badgeRT.anchoredPosition = new Vector2(8f, -2f);

            var badgeText = UIHelper.MakeText("BadgeLabel", badge.transform, rarityLabel,
                7f, TextAlignmentOptions.Center, UIColors.Text_Dark);
            badgeText.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(badgeText.GetComponent<RectTransform>());

            var nameText = UIHelper.MakeText("Name", item.transform, heroName,
                UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, rarityCol);
            nameText.fontStyle = FontStyles.Bold;
            var nrt = nameText.GetComponent<RectTransform>();
            nrt.anchorMin = new Vector2(0, 0);
            nrt.anchorMax = new Vector2(0.50f, 0.55f);
            nrt.offsetMin = new Vector2(8f, 0);
            nrt.offsetMax = Vector2.zero;

            int equipCount = EquipmentManager.Instance != null
                ? EquipmentManager.Instance.GetEquippedItems(heroName).Count : 0;
            string roleStr = preset.isHealer ? "힐러" : preset.isBuffer ? "버퍼" :
                preset.attackRange > 3f ? "원거리" : "근거리";
            var eqText = UIHelper.MakeText("Equip", item.transform,
                $"{roleStr} | 장비 {equipCount}개",
                8f, TextAlignmentOptions.Center, UIColors.Text_DarkSecondary);
            var ert = eqText.GetComponent<RectTransform>();
            ert.anchorMin = new Vector2(0.50f, 0);
            ert.anchorMax = new Vector2(0.76f, 1);
            ert.offsetMin = Vector2.zero;
            ert.offsetMax = Vector2.zero;

            var (btn, _) = UIHelper.MakeSpriteButton($"Select_{i}", item.transform,
                UISprites.Btn2_WS, UIColors.Button_Green, "", 10f);
            var btnRT = btn.GetComponent<RectTransform>();
            btnRT.anchorMin = new Vector2(0.77f, 0.12f);
            btnRT.anchorMax = new Vector2(0.97f, 0.88f);
            btnRT.offsetMin = Vector2.zero;
            btnRT.offsetMax = Vector2.zero;

            var btnText = UIHelper.MakeText("Label", btn.transform, "선택",
                UIConstants.Font_Cost, TextAlignmentOptions.Center, Color.white);
            btnText.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(btnText.GetComponent<RectTransform>());

            string capturedHero = heroName;
            btn.onClick.AddListener(() =>
            {
                EquipmentManager.Instance?.EquipItem(pendingEquipItemId, capturedHero);
                Hide();
                onEquipped?.Invoke();
                ToastNotification.Instance?.Show($"{capturedHero}에게 장비 장착!", "");
            });

            y -= (itemH + spacing);
        }

        var containerRT = listContainer.GetComponent<RectTransform>();
        containerRT.sizeDelta = new Vector2(0, Mathf.Abs(y));
    }

    static Color GetStarGradeColor(StarGrade starGrade) => starGrade switch
    {
        StarGrade.Star1 => UIColors.Rarity_Common,
        StarGrade.Star2 => UIColors.Rarity_Rare,
        StarGrade.Star3 => UIColors.Rarity_Epic,
        StarGrade.Star4 => UIColors.Rarity_Legendary,
        StarGrade.Star5 => UIColors.Rarity_Legendary,
        _               => UIColors.Text_DarkSecondary
    };

    static string GetStarGradeLabel(StarGrade starGrade) => starGrade switch
    {
        StarGrade.Star1 => "1성",
        StarGrade.Star2 => "2성",
        StarGrade.Star3 => "3성",
        StarGrade.Star4 => "4성",
        StarGrade.Star5 => "5성",
        _               => ""
    };
}
