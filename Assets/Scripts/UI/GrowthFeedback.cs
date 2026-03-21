using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections;

/// <summary>
/// 성장 피드백 연출 싱글톤:
/// 1. 레벨업 → 이전/이후 스탯 비교 팝업 (스케일 팝인)
/// 2. 각성 → 별 파티클 + 골드 플래시
/// 3. 장비 드롭 → 희귀도 프레임 반짝 배너
/// (뽑기 결과 카드 뒤집기는 GachaPanel 내부 처리)
/// Canvas sortingOrder 200
/// </summary>
public class GrowthFeedback : MonoBehaviour
{
    public static GrowthFeedback Instance { get; private set; }

    Canvas canvas;

    // 레벨업 팝업
    GameObject levelPopup;
    TextMeshProUGUI lvPopupText;

    // 각성 플래시
    Image flashOverlay;

    // 장비 배너
    GameObject equipBanner;
    Image equipBannerBG;
    TextMeshProUGUI equipBannerText;
    RectTransform equipBannerRT;

    // 별 파티클 풀
    const int STAR_POOL = 8;
    readonly TextMeshProUGUI[] starTexts = new TextMeshProUGUI[STAR_POOL];

    // 캐시된 매니저
    HeroLevelManager cachedHLM;
    EquipmentManager cachedEM;

    // ════════════════════════════════════════
    // Unity 생명주기
    // ════════════════════════════════════════

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        BuildCanvas();
        BuildLevelPopup();
        BuildFlashOverlay();
        BuildEquipBanner();
        BuildStarPool();
    }

    void Start()
    {
        StartCoroutine(DeferredSubscribe());
    }

    IEnumerator DeferredSubscribe()
    {
        yield return null;
        cachedHLM = HeroLevelManager.Instance;
        cachedEM  = EquipmentManager.Instance;

        if (cachedHLM != null)
        {
            cachedHLM.OnHeroLevelUp   += OnHeroLevelUp;
            cachedHLM.OnHeroAwakened  += OnHeroAwakened;
        }
        if (cachedEM != null)
            cachedEM.OnEquipmentDropped += OnEquipmentDropped;
    }

    void OnDestroy()
    {
        if (cachedHLM != null)
        {
            cachedHLM.OnHeroLevelUp  -= OnHeroLevelUp;
            cachedHLM.OnHeroAwakened -= OnHeroAwakened;
        }
        if (cachedEM != null)
            cachedEM.OnEquipmentDropped -= OnEquipmentDropped;
    }

    // ════════════════════════════════════════
    // 이벤트 핸들러
    // ════════════════════════════════════════

    void OnHeroLevelUp(string heroName, int newLevel)
    {
        var hlm = HeroLevelManager.Instance;
        if (hlm == null) return;

        // 이전 레벨 기준 보너스 (이미 올라갔으므로 -1)
        int prevLv = newLevel - 1;
        float prevAtk = (prevLv - 1) * 0.05f * 100f;
        float prevHp  = (prevLv - 1) * 0.04f * 100f;
        float curAtk  = hlm.GetAtkBonus(heroName) * 100f;
        float curHp   = hlm.GetHpBonus(heroName)  * 100f;

        string msg =
            $"<size=20><b>{heroName}</b></size>\n" +
            $"<color=#FFD700>Lv.{prevLv} → Lv.{newLevel}</color>\n\n" +
            $"ATK +{curAtk:F0}%  <color=#888>(+{curAtk - prevAtk:F0}%)</color>\n" +
            $"HP  +{curHp:F0}%  <color=#888>(+{curHp - prevHp:F0}%)</color>";

        ShowLevelPopup(msg);
    }

    void OnHeroAwakened(string heroName, int awakenLevel)
    {
        StartCoroutine(AwakenEffect(heroName, awakenLevel));
    }

    void OnEquipmentDropped(EquipmentItem item)
    {
        StartCoroutine(EquipDropEffect(item));
    }

    // ════════════════════════════════════════
    // 레벨업 팝업
    // ════════════════════════════════════════

    void ShowLevelPopup(string msg)
    {
        if (levelPopup == null) return;
        lvPopupText.text = msg;
        levelPopup.SetActive(true);
        StartCoroutine(PopupIn(levelPopup.GetComponent<RectTransform>(), 2.5f));
    }

    IEnumerator PopupIn(RectTransform rt, float holdSec)
    {
        // Scale in 0→1
        float t = 0;
        while (t < 0.2f)
        {
            t += Time.unscaledDeltaTime;
            float s = Mathf.SmoothStep(0, 1, t / 0.2f);
            rt.localScale = Vector3.one * s;
            yield return null;
        }
        rt.localScale = Vector3.one;

        yield return new WaitForSecondsRealtime(holdSec);

        // Scale out 1→0
        t = 0;
        while (t < 0.15f)
        {
            t += Time.unscaledDeltaTime;
            float s = Mathf.SmoothStep(1, 0, t / 0.15f);
            rt.localScale = Vector3.one * s;
            yield return null;
        }
        rt.gameObject.SetActive(false);
    }

    // ════════════════════════════════════════
    // 각성 연출
    // ════════════════════════════════════════

    IEnumerator AwakenEffect(string heroName, int awakenLevel)
    {
        string stars = new string('★', awakenLevel) + new string('☆', Mathf.Max(0, 5 - awakenLevel));

        // 골드 플래시
        flashOverlay.gameObject.SetActive(true);
        flashOverlay.color = new Color(1f, 0.85f, 0.1f, 0f);

        float t = 0;
        while (t < 0.15f)
        {
            t += Time.unscaledDeltaTime;
            flashOverlay.color = new Color(1f, 0.85f, 0.1f, Mathf.Lerp(0, 0.55f, t / 0.15f));
            yield return null;
        }

        SoundManager.Instance?.PlayLevelUpSFX();

        t = 0;
        while (t < 0.4f)
        {
            t += Time.unscaledDeltaTime;
            flashOverlay.color = new Color(1f, 0.85f, 0.1f, Mathf.Lerp(0.55f, 0f, t / 0.4f));
            yield return null;
        }
        flashOverlay.gameObject.SetActive(false);

        // 별 파티클 폭발
        StartCoroutine(StarBurst(awakenLevel));

        // 토스트
        ToastNotification.Instance?.Show(
            $"{heroName} 각성 {awakenLevel}단계!",
            stars,
            UIColors.Rarity_Legendary
        );
    }

    IEnumerator StarBurst(int count)
    {
        int spawned = Mathf.Min(count * 2, STAR_POOL);
        for (int i = 0; i < spawned; i++)
        {
            var st = starTexts[i];
            if (st == null) continue;
            st.gameObject.SetActive(true);
            st.color = UIColors.Rarity_Legendary;
            var rt = st.GetComponent<RectTransform>();
            rt.anchoredPosition = new Vector2(
                Random.Range(-120f, 120f),
                Random.Range(-80f, 80f)
            );
            StartCoroutine(FloatStar(rt, st));
        }
        yield return null;
    }

    IEnumerator FloatStar(RectTransform rt, TextMeshProUGUI txt)
    {
        Vector2 startPos = rt.anchoredPosition;
        float t = 0;
        while (t < 0.9f)
        {
            t += Time.unscaledDeltaTime;
            rt.anchoredPosition = startPos + Vector2.up * (t * 160f);
            txt.color = new Color(1f, 0.85f, 0.1f, Mathf.Lerp(1, 0, t / 0.9f));
            yield return null;
        }
        rt.gameObject.SetActive(false);
    }

    // ════════════════════════════════════════
    // 장비 드롭 반짝 배너
    // ════════════════════════════════════════

    IEnumerator EquipDropEffect(EquipmentItem item)
    {
        if (equipBanner == null) yield break;

        Color rarityColor = RarityColor(item.rarity);
        string rarityLabel = RarityLabel(item.rarity);
        string slotIcon = SlotIcon(item.slot);

        equipBannerBG.color = rarityColor;
        equipBannerText.text = $"{slotIcon} [{rarityLabel}] {item.itemName} 획득!";
        equipBanner.SetActive(true);

        // 반짝 (알파 깜빡)
        for (int i = 0; i < 3; i++)
        {
            float t = 0;
            while (t < 0.12f)
            {
                t += Time.unscaledDeltaTime;
                float a = Mathf.PingPong(t * 16f, 1f);
                equipBannerBG.color = new Color(rarityColor.r, rarityColor.g, rarityColor.b, 0.6f + a * 0.4f);
                yield return null;
            }
        }
        equipBannerBG.color = rarityColor;

        yield return new WaitForSecondsRealtime(2f);

        // 슬라이드 아웃 위로
        float elapsed = 0;
        Vector2 startAP = equipBannerRT.anchoredPosition;
        while (elapsed < 0.25f)
        {
            elapsed += Time.unscaledDeltaTime;
            equipBannerRT.anchoredPosition = Vector2.Lerp(startAP, startAP + Vector2.up * 60f, elapsed / 0.25f);
            yield return null;
        }
        equipBanner.SetActive(false);
        equipBannerRT.anchoredPosition = startAP;
    }

    // ════════════════════════════════════════
    // UI 빌드
    // ════════════════════════════════════════

    void BuildCanvas()
    {
        var go = UIHelper.MakeUI("GrowthFeedbackCanvas", transform);
        canvas = go.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvas.sortingOrder = 200;
        var scaler = go.AddComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = UIConstants.ReferenceResolution;
        scaler.matchWidthOrHeight = UIConstants.MatchWidthOrHeight;
    }

    void BuildLevelPopup()
    {
        var root = canvas.transform;
        var popupObj = UIHelper.MakeUI("LevelPopup", root);
        var rt = popupObj.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0.5f, 0.5f);
        rt.anchorMax = new Vector2(0.5f, 0.5f);
        rt.pivot = Vector2.one * 0.5f;
        rt.sizeDelta = new Vector2(260f, 160f);
        rt.localScale = Vector3.zero;

        var bg = UIHelper.MakeSpritePanel("BG", popupObj.transform, UISprites.BoxBasic3, UIColors.Background_Panel);
        UIHelper.FillParent(bg.GetComponent<RectTransform>());

        var border = UIHelper.MakePanel("Border", popupObj.transform, UIColors.Rarity_Rare);
        var brt = border.GetComponent<RectTransform>();
        brt.anchorMin = Vector2.zero; brt.anchorMax = Vector2.one;
        brt.offsetMin = new Vector2(-2, -2); brt.offsetMax = new Vector2(2, 2);
        border.transform.SetAsFirstSibling();

        lvPopupText = UIHelper.MakeText("Msg", popupObj.transform, "",
            12f, TextAlignmentOptions.Center, UIColors.Text_Primary);
        UIHelper.FillParent(lvPopupText.GetComponent<RectTransform>());

        var closeBtn = UIHelper.MakePanel("CloseBtn", popupObj.transform, UIColors.Button_Green);
        var cbrt = closeBtn.GetComponent<RectTransform>();
        cbrt.anchorMin = new Vector2(0.3f, 0.04f);
        cbrt.anchorMax = new Vector2(0.7f, 0.22f);
        cbrt.offsetMin = Vector2.zero; cbrt.offsetMax = Vector2.zero;
        var btn = closeBtn.gameObject.AddComponent<Button>();
        btn.onClick.AddListener(() => popupObj.SetActive(false));
        var closeTxt = UIHelper.MakeText("Label", closeBtn.transform, "확인",
            11f, TextAlignmentOptions.Center, Color.white);
        closeTxt.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(closeTxt.GetComponent<RectTransform>());

        popupObj.SetActive(false);
        levelPopup = popupObj;
    }

    void BuildFlashOverlay()
    {
        var root = canvas.transform;
        var flashObj = UIHelper.MakeUI("FlashOverlay", root);
        UIHelper.FillParent(flashObj.GetComponent<RectTransform>());
        flashOverlay = flashObj.AddComponent<Image>();
        flashOverlay.color = new Color(1f, 0.85f, 0.1f, 0f);
        flashOverlay.raycastTarget = false;
        flashObj.SetActive(false);
    }

    void BuildStarPool()
    {
        var root = canvas.transform;
        for (int i = 0; i < STAR_POOL; i++)
        {
            var st = UIHelper.MakeText($"Star_{i}", root, "★",
                22f, TextAlignmentOptions.Center, UIColors.Rarity_Legendary);
            st.fontStyle = FontStyles.Bold;
            var rt = st.GetComponent<RectTransform>();
            rt.anchorMin = new Vector2(0.5f, 0.5f);
            rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.pivot = Vector2.one * 0.5f;
            rt.sizeDelta = new Vector2(28f, 28f);
            st.raycastTarget = false;
            st.gameObject.SetActive(false);
            starTexts[i] = st;
        }
    }

    void BuildEquipBanner()
    {
        var root = canvas.transform;
        var bannerObj = UIHelper.MakeUI("EquipBanner", root);
        equipBannerRT = bannerObj.GetComponent<RectTransform>();
        equipBannerRT.anchorMin = new Vector2(0.05f, 0f);
        equipBannerRT.anchorMax = new Vector2(0.95f, 0f);
        equipBannerRT.pivot = new Vector2(0.5f, 0f);
        equipBannerRT.sizeDelta = new Vector2(0, 44f);
        equipBannerRT.anchoredPosition = new Vector2(0, 90f);

        equipBannerBG = UIHelper.MakePanel("BG", bannerObj.transform, UIColors.Rarity_Rare);
        UIHelper.FillParent(equipBannerBG.GetComponent<RectTransform>());

        equipBannerText = UIHelper.MakeText("Label", bannerObj.transform, "",
            12f, TextAlignmentOptions.Center, Color.white);
        equipBannerText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(equipBannerText);
        UIHelper.FillParent(equipBannerText.GetComponent<RectTransform>());

        bannerObj.SetActive(false);
        equipBanner = bannerObj;
    }

    // ════════════════════════════════════════
    // 유틸
    // ════════════════════════════════════════

    static Color RarityColor(int rarity) => rarity switch
    {
        5 => UIColors.Rarity_Legendary,
        4 => UIColors.Rarity_Epic,
        3 => UIColors.Rarity_Rare,
        2 => UIColors.Rarity_Uncommon,
        _ => UIColors.Rarity_Common,
    };

    static string RarityLabel(int rarity) => rarity switch
    {
        5 => "전설",
        4 => "에픽",
        3 => "레어",
        2 => "언커먼",
        _ => "일반",
    };

    static string SlotIcon(EquipmentSlot slot) => slot switch
    {
        EquipmentSlot.Weapon  => "⚔",
        EquipmentSlot.Shield  => "◈",
        EquipmentSlot.Helmet  => "▲",
        EquipmentSlot.Armor   => "■",
        EquipmentSlot.Cloth   => "◇",
        _                     => "◆",
    };
}
