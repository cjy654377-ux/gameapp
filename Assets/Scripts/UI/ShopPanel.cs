using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections.Generic;

/// <summary>
/// 상점 패널: 상점 아이템 목록 + 구매
/// MainHUD 상점 탭에서 Init(parent, showConfirm)으로 초기화
/// </summary>
public class ShopPanel : MonoBehaviour
{
    GameObject shopListContainer;
    readonly List<GameObject> shopListItems = new();
    Button freeGemBtn;
    TextMeshProUGUI freeGemBtnText;

    System.Action<string, string, System.Action> showConfirm;

    // ════════════════════════════════════════
    // 초기화
    // ════════════════════════════════════════

    public void Init(Transform parent, System.Action<string, string, System.Action> showConfirmCallback, SettingsPanel _ignored = null)
    {
        showConfirm = showConfirmCallback;

        var content = UIHelper.MakeUI("ShopContent", parent);
        var contentRT = content.GetComponent<RectTransform>();
        contentRT.anchorMin = Vector2.zero;
        contentRT.anchorMax = Vector2.one;
        contentRT.offsetMin = Vector2.zero;
        contentRT.offsetMax = new Vector2(0, -UIConstants.Tab_Height);

        BuildFreeGemButton(content.transform);
        BuildShopList(content.transform);
    }

    public void Refresh()
    {
        RefreshFreeGemButton();
        RefreshShopList();
    }

    // ════════════════════════════════════════
    // 무료 보석 버튼
    // ════════════════════════════════════════

    void BuildFreeGemButton(Transform parent)
    {
        var container = UIHelper.MakeUI("FreeGemContainer", parent);
        var crt = container.GetComponent<RectTransform>();
        crt.anchorMin = new Vector2(0, 1);
        crt.anchorMax = new Vector2(1, 1);
        crt.pivot = new Vector2(0.5f, 1);
        crt.sizeDelta = new Vector2(0, 60f);
        crt.anchoredPosition = new Vector2(0, 0);

        var (btn, _) = UIHelper.MakeSpriteButton("FreeGemBtn", container.transform,
            UISprites.Btn2_WS, UIColors.Button_Blue, "", UIConstants.Font_Button);
        freeGemBtn = btn;
        btn.onClick.AddListener(OnFreeGemClicked);

        var brt = btn.GetComponent<RectTransform>();
        brt.anchorMin = new Vector2(0.05f, 0.1f);
        brt.anchorMax = new Vector2(0.95f, 0.9f);
        brt.offsetMin = Vector2.zero;
        brt.offsetMax = Vector2.zero;

        freeGemBtnText = UIHelper.MakeText("Label", btn.transform, "무료 보상 - 보석 10개",
            UIConstants.Font_Button, TextAlignmentOptions.Center, Color.white);
        freeGemBtnText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(freeGemBtnText);
        UIHelper.FillParent(freeGemBtnText.GetComponent<RectTransform>());

        RefreshFreeGemButton();
    }

    void OnFreeGemClicked()
    {
        // 광고 가능 여부 체크
        if (AdManager.Instance != null && !AdManager.Instance.IsAdAvailable(AdManager.AdRewardType.FreeGem))
        {
            string cooldownText = AdManager.Instance.GetCooldownText(AdManager.AdRewardType.FreeGem);
            ToastNotification.Instance?.Show("무료 보석 재시도", cooldownText, UIColors.Text_Gold);
            return;
        }

        // 광고 시청
        if (AdManager.Instance != null)
        {
            AdManager.Instance.ShowRewardedAd(
                AdManager.AdRewardType.FreeGem,
                () =>
                {
                    GemManager.Instance?.AddGem(10);
                    ToastNotification.Instance?.Show("무료 보석!", "보석 10개 획득!", UIColors.Text_Gold);
                    RefreshFreeGemButton();
                    Refresh();
                }
            );
        }
    }

    void RefreshFreeGemButton()
    {
        if (freeGemBtn == null || freeGemBtnText == null) return;

        if (AdManager.Instance != null && AdManager.Instance.IsAdAvailable(AdManager.AdRewardType.FreeGem))
        {
            freeGemBtn.interactable = true;
            freeGemBtnText.text = "무료 보상 - 보석 10개";
            freeGemBtnText.color = Color.white;
        }
        else if (AdManager.Instance != null)
        {
            freeGemBtn.interactable = false;
            freeGemBtnText.text = AdManager.Instance.GetCooldownText(AdManager.AdRewardType.FreeGem);
            freeGemBtnText.color = UIColors.Text_Secondary;
        }
    }

    // ════════════════════════════════════════
    // 상점 리스트
    // ════════════════════════════════════════

    void BuildShopList(Transform parent)
    {
        var scrollObj = UIHelper.MakeUI("ShopScroll", parent);
        var scrollRT = scrollObj.GetComponent<RectTransform>();
        scrollRT.anchorMin = Vector2.zero;
        scrollRT.anchorMax = Vector2.one;
        scrollRT.offsetMin = new Vector2(UIConstants.Spacing_Small, UIConstants.Spacing_Small);
        scrollRT.offsetMax = new Vector2(-UIConstants.Spacing_Small, 0);

        var scrollRect = scrollObj.AddComponent<ScrollRect>();
        scrollRect.horizontal = false;
        scrollRect.vertical = true;

        var viewport = UIHelper.MakeUI("Viewport", scrollObj.transform);
        viewport.AddComponent<RectMask2D>();
        UIHelper.FillParent(viewport.GetComponent<RectTransform>());
        scrollRect.viewport = viewport.GetComponent<RectTransform>();

        shopListContainer = UIHelper.MakeUI("Content", viewport.transform);
        var hcRT = shopListContainer.GetComponent<RectTransform>();
        hcRT.anchorMin = new Vector2(0, 1);
        hcRT.anchorMax = new Vector2(1, 1);
        hcRT.pivot = new Vector2(0.5f, 1);
        hcRT.anchoredPosition = Vector2.zero;
        scrollRect.content = hcRT;
    }

    void RefreshShopList()
    {
        if (shopListContainer == null) return;
        var shop = ShopManager.Instance;
        if (shop == null) return;

        UIListPool.RecycleList(shopListItems);
        int reuse = 0;
        var items = shop.GetStockItems();
        float itemH = 52f, spacing = 4f, y = 0;
        int active = 0;

        for (int i = 0; i < items.Count; i++)
        {
            var shopItem = items[i];
            var item = UIListPool.ReuseOrCreate(shopListItems, ref reuse, $"Shop_{i}", shopListContainer.transform, UIColors.ListItem_Normal);
            active++;
            // BoxBasic1 배경
            var shopItemImg = item.GetComponent<Image>();
            if (UISprites.BoxBasic1 != null) { shopItemImg.sprite = UISprites.BoxBasic1; shopItemImg.type = Image.Type.Sliced; shopItemImg.color = new Color(0.96f, 0.92f, 0.86f); }
            var irt = item.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0, 1); irt.anchorMax = new Vector2(1, 1);
            irt.pivot = new Vector2(0.5f, 1);
            irt.anchoredPosition = new Vector2(0, y); irt.sizeDelta = new Vector2(0, itemH);

            // 재화 아이콘 (좌단)
            Sprite currencyIcon = shopItem.gemCost > 0 ? UISprites.IconDiamond :
                                  shopItem.goldCost > 0 ? UISprites.IconGold : UISprites.FlatIcon(1);
            var shopIcon = UIHelper.MakeIcon("CurrencyIcon", item.transform, currencyIcon, Color.white);
            var siRT = shopIcon.GetComponent<RectTransform>();
            siRT.anchorMin = new Vector2(0.01f, 0.15f);
            siRT.anchorMax = new Vector2(0.09f, 0.85f);
            siRT.offsetMin = siRT.offsetMax = Vector2.zero;
            shopIcon.raycastTarget = false;

            var nameText = UIHelper.MakeText("Name", item.transform, shopItem.displayName,
                UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, UIColors.Text_Dark);
            nameText.fontStyle = FontStyles.Bold;
            nameText.overflowMode = TextOverflowModes.Ellipsis;
            nameText.enableAutoSizing = true;
            nameText.fontSizeMin = 7f;
            nameText.fontSizeMax = UIConstants.Font_StatLabel;
            var nrt = nameText.GetComponent<RectTransform>();
            nrt.anchorMin = new Vector2(0.10f, 0.5f); nrt.anchorMax = new Vector2(0.55f, 1);
            nrt.offsetMin = new Vector2(UIConstants.Spacing_Small, 0); nrt.offsetMax = Vector2.zero;

            var descText = UIHelper.MakeText("Desc", item.transform, shopItem.description,
                8f, TextAlignmentOptions.MidlineLeft, UIColors.Text_DarkSecondary);
            descText.overflowMode = TextOverflowModes.Ellipsis;
            descText.enableAutoSizing = true;
            descText.fontSizeMin = 6f;
            descText.fontSizeMax = 8f;
            var drt = descText.GetComponent<RectTransform>();
            drt.anchorMin = new Vector2(0, 0); drt.anchorMax = new Vector2(0.55f, 0.5f);
            drt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0); drt.offsetMax = Vector2.zero;

            string priceStr = shopItem.gemCost > 0 ? $"◆{shopItem.gemCost} 보석" :
                              shopItem.goldCost > 0 ? $"★{shopItem.goldCost}G" : "무료";
            var priceText = UIHelper.MakeText("Price", item.transform, priceStr,
                11f, TextAlignmentOptions.Center, UIColors.Text_Gold);
            priceText.fontStyle = FontStyles.Bold;
            UIHelper.AddTextShadow(priceText);
            var prt = priceText.GetComponent<RectTransform>();
            prt.anchorMin = new Vector2(0.4f, 0); prt.anchorMax = new Vector2(0.65f, 1);
            prt.offsetMin = Vector2.zero; prt.offsetMax = Vector2.zero;

            bool canBuy = shop.CanPurchase(shopItem);
            float cooldown = shop.GetRemainingCooldown(shopItem);
            string btnLabel = cooldown > 0 ? $"{Mathf.CeilToInt(cooldown / 60f)}분" : "구매";

            var (btn, shopBtnImg) = UIHelper.MakeSpriteButton($"Buy_{i}", item.transform,
                canBuy ? UISprites.Btn2_WS : UISprites.Btn1_WS,
                canBuy ? UIColors.Button_Green : UIColors.Button_Gray, "", 10f);
            if (!canBuy && shopBtnImg.sprite != null) shopBtnImg.color = UIColors.Button_Disabled;
            var btnRT = btn.GetComponent<RectTransform>();
            btnRT.anchorMin = new Vector2(0.68f, 0.1f); btnRT.anchorMax = new Vector2(0.97f, 0.9f);
            btnRT.offsetMin = Vector2.zero; btnRT.offsetMax = Vector2.zero;

            var btnText = UIHelper.MakeText("Label", btn.transform, btnLabel,
                UIConstants.Font_Cost, TextAlignmentOptions.Center,
                canBuy ? Color.white : UIColors.Text_Disabled);
            btnText.fontStyle = FontStyles.Bold;
            UIHelper.FillParent(btnText.GetComponent<RectTransform>());

            var capturedItem = shopItem;
            btn.onClick.AddListener(() =>
            {
                if (!shop.CanPurchase(capturedItem))
                {
                    string currency = capturedItem.gemCost > 0 ? "보석" : "골드";
                    ToastNotification.Instance?.Show($"{currency} 부족!", "", UIColors.Defeat_Red);
                    return;
                }
                if (capturedItem.gemCost > 0)
                {
                    showConfirm?.Invoke("구매 확인", $"보석 {capturedItem.gemCost}개를 사용합니다.\n진행하시겠습니까?", () =>
                    {
                        shop.Purchase(capturedItem);
                        SoundManager.Instance?.PlayGoldSFX();
                        RefreshShopList();
                    });
                }
                else
                {
                    shop.Purchase(capturedItem);
                    SoundManager.Instance?.PlayGoldSFX();
                    RefreshShopList();
                }
            });

            y -= (itemH + spacing);
        }

        UIListPool.TrimExcess(shopListItems, active);
        shopListContainer.GetComponent<RectTransform>().sizeDelta = new Vector2(0, Mathf.Abs(y));
    }

    void OnDestroy()
    {
        if (freeGemBtn != null) freeGemBtn.onClick.RemoveListener(OnFreeGemClicked);
    }
}
