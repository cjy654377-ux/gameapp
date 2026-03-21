using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections.Generic;

/// <summary>
/// 각성 패널: 보유 영웅 목록 + 각성 단계 + 카피 수 + 각성 버튼
/// EnhancePanel 강화 탭의 3번째 서브탭에서 Init(parent)으로 초기화
/// </summary>
public class AwakeningPanel : MonoBehaviour
{
    GameObject listContainer;
    readonly List<GameObject> listItems = new();

    HeroLevelManager cachedHLM;
    GachaManager cachedGacha;

    public void Init(Transform parent)
    {
        var content = UIHelper.MakeUI("AwakeContent", parent);
        var contentRT = content.GetComponent<RectTransform>();
        contentRT.anchorMin = new Vector2(0, 0);
        contentRT.anchorMax = new Vector2(1, 1);
        contentRT.offsetMin = new Vector2(UIConstants.Spacing_Small, UIConstants.Spacing_Small);
        contentRT.offsetMax = new Vector2(-UIConstants.Spacing_Small, 0);

        var scrollObj = UIHelper.MakeUI("AwakeScroll", content.transform);
        UIHelper.FillParent(scrollObj.GetComponent<RectTransform>());

        var scrollRect = scrollObj.AddComponent<ScrollRect>();
        scrollRect.horizontal = false;
        scrollRect.vertical = true;

        var viewport = UIHelper.MakeUI("Viewport", scrollObj.transform);
        viewport.AddComponent<RectMask2D>();
        UIHelper.FillParent(viewport.GetComponent<RectTransform>());
        scrollRect.viewport = viewport.GetComponent<RectTransform>();

        listContainer = UIHelper.MakeUI("Content", viewport.transform);
        var lcRT = listContainer.GetComponent<RectTransform>();
        lcRT.anchorMin = new Vector2(0, 1);
        lcRT.anchorMax = new Vector2(1, 1);
        lcRT.pivot = new Vector2(0.5f, 1);
        lcRT.anchoredPosition = Vector2.zero;
        scrollRect.content = lcRT;

        StartCoroutine(DeferredSubscribe());
    }

    // ────────────────────────────────────────
    // 이벤트 구독
    // ────────────────────────────────────────

    System.Collections.IEnumerator DeferredSubscribe()
    {
        yield return null;

        cachedHLM   = HeroLevelManager.Instance;
        cachedGacha = GachaManager.Instance;

        if (cachedHLM != null)
            cachedHLM.OnHeroAwakened += OnHeroAwakened;
        if (cachedGacha != null)
            cachedGacha.OnDuplicatePulled += OnDuplicatePulled;

        Refresh();
    }

    void OnDestroy()
    {
        if (cachedHLM != null)
            cachedHLM.OnHeroAwakened -= OnHeroAwakened;
        if (cachedGacha != null)
            cachedGacha.OnDuplicatePulled -= OnDuplicatePulled;
    }

    void OnHeroAwakened(string heroName, int newStage)
    {
        Refresh();
        ToastNotification.Instance?.Show("각성 성공!", $"{heroName} 각성 {newStage}단계!", UIColors.Text_Gold);
    }

    void OnDuplicatePulled(CharacterPreset hero)
    {
        if (hero == null) return;
        var hlm = HeroLevelManager.Instance;
        string copies = hlm != null ? $" ({hlm.GetCopies(hero.characterName)}개 보유)" : "";
        ToastNotification.Instance?.Show("이미 보유한 영웅!", $"{hero.characterName} → 각성 재료로 전환{copies}", UIColors.Text_Diamond);
    }

    // ────────────────────────────────────────
    // UI 구성
    // ────────────────────────────────────────

    public void Refresh()
    {
        if (listContainer == null) return;

        var dm  = DeckManager.Instance;
        var hlm = HeroLevelManager.Instance;
        if (dm == null) return;

        // 기존 아이템 재활용
        RecycleList(listItems);
        int reuse = 0;

        const float ITEM_H   = 52f;
        const float SPACING  = 3f;
        float y = 0;
        int count = 0;

        for (int i = 0; i < dm.roster.Count; i++)
        {
            var preset = dm.roster[i];
            if (preset == null || preset.isEnemy) continue;

            string heroName = preset.characterName;
            int star      = hlm != null ? hlm.GetStarRank(heroName)        : 1;
            int awakening = hlm != null ? hlm.GetAwakeningStage(heroName)   : 0;
            int copies    = hlm != null ? hlm.GetCopies(heroName)           : 0;
            int needed    = hlm != null ? hlm.GetAwakeningCopiesNeeded(star) : 999;
            bool canAwaken = hlm != null && hlm.CanAwaken(heroName);

            var item = ReuseOrCreate(listItems, ref reuse,
                $"Awake_{heroName}", listContainer.transform,
                canAwaken ? new Color(0.90f, 0.95f, 0.85f) : new Color(0.90f, 0.87f, 0.82f));
            count++;

            var irt = item.GetComponent<RectTransform>();
            irt.anchorMin = new Vector2(0, 1);
            irt.anchorMax = new Vector2(1, 1);
            irt.pivot     = new Vector2(0.5f, 1);
            irt.anchoredPosition = new Vector2(0, y);
            irt.sizeDelta = new Vector2(0, ITEM_H);

            // 영웅 이름 + 성급
            string starStr = new string('\u2605', star) + new string('\u2606', 5 - star);
            var nameText = UIHelper.MakeText("Name", item.transform, heroName,
                UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, UIColors.Text_Dark);
            nameText.fontStyle = FontStyles.Bold;
            var nrt = nameText.GetComponent<RectTransform>();
            nrt.anchorMin = new Vector2(0, 0.55f);
            nrt.anchorMax = new Vector2(0.35f, 1);
            nrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
            nrt.offsetMax = Vector2.zero;

            var starText = UIHelper.MakeText("Star", item.transform, starStr,
                UIConstants.Font_SmallInfo, TextAlignmentOptions.MidlineLeft,
                UIColors.Text_DarkGold);
            var srt = starText.GetComponent<RectTransform>();
            srt.anchorMin = new Vector2(0, 0.05f);
            srt.anchorMax = new Vector2(0.35f, 0.55f);
            srt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
            srt.offsetMax = Vector2.zero;

            // 각성 단계 ★/☆ 시각화
            bool isMaxAwake = awakening >= HeroLevelManager.MAX_AWAKENING;
            string awakeStars = new string('\u2605', awakening)
                              + new string('\u2606', HeroLevelManager.MAX_AWAKENING - awakening);
            string awakeStr = isMaxAwake
                ? $"<color=#FFD700>{awakeStars}</color>"
                : $"<color=#FFD700>{new string('\u2605', awakening)}</color><color=#8B6914>{new string('\u2606', HeroLevelManager.MAX_AWAKENING - awakening)}</color>";
            var awakeText = UIHelper.MakeText("Awake", item.transform, awakeStr,
                UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, UIColors.Text_Dark);
            var art = awakeText.GetComponent<RectTransform>();
            art.anchorMin = new Vector2(0.36f, 0.5f);
            art.anchorMax = new Vector2(0.66f, 1);
            art.offsetMin = Vector2.zero;
            art.offsetMax = Vector2.zero;

            // 카피 게이지 (블록 표시)
            Color copyColor = copies >= needed ? UIColors.Text_DarkGreen : UIColors.Text_DarkSecondary;
            string copyStr;
            if (isMaxAwake)
            {
                copyStr = $"카피: {copies}";
            }
            else if (needed > 0 && needed <= 10)
            {
                int filled = Mathf.Min(copies, needed);
                int empty  = needed - filled;
                string bar = $"<color=#2E7D32>{new string('\u25A0', filled)}</color><color=#8B6914>{new string('\u25A1', empty)}</color>";
                copyStr = $"{bar} {copies}/{needed}";
            }
            else
            {
                copyStr = $"카피: {copies}/{needed}";
            }
            var copyText = UIHelper.MakeText("Copy", item.transform, copyStr,
                UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, copyColor);
            var crt = copyText.GetComponent<RectTransform>();
            crt.anchorMin = new Vector2(0.36f, 0);
            crt.anchorMax = new Vector2(0.66f, 0.5f);
            crt.offsetMin = Vector2.zero;
            crt.offsetMax = Vector2.zero;

            // 각성 버튼
            bool isMax = awakening >= HeroLevelManager.MAX_AWAKENING;
            Color btnColor   = isMax    ? UIColors.Button_Gray
                             : canAwaken ? UIColors.Button_Green
                             : UIColors.Button_Gray;
            Sprite btnSprite = canAwaken && !isMax ? UISprites.Btn2_WS : UISprites.Btn1_WS;
            string btnLabel  = isMax ? "MAX" : "각성";

            var (btn, btnImg) = UIHelper.MakeSpriteButton($"Awaken_{heroName}", item.transform,
                btnSprite, btnColor, "", 10f);
            btn.interactable = canAwaken && !isMax;
            if (!btn.interactable && btnImg.sprite != null)
                btnImg.color = new Color(0.70f, 0.70f, 0.70f);
            var brt = btn.GetComponent<RectTransform>();
            brt.anchorMin = new Vector2(0.68f, 0.1f);
            brt.anchorMax = new Vector2(0.97f, 0.9f);
            brt.offsetMin = Vector2.zero;
            brt.offsetMax = Vector2.zero;

            string capturedName = heroName;
            btn.onClick.AddListener(() => OnAwakenClicked(capturedName));

            var btnLabelText = UIHelper.MakeText("Label", btn.transform, btnLabel,
                10f, TextAlignmentOptions.Center, Color.white);
            btnLabelText.fontStyle = FontStyles.Bold;
            UIHelper.AddTextShadow(btnLabelText);
            UIHelper.FillParent(btnLabelText.GetComponent<RectTransform>());

            y -= (ITEM_H + SPACING);
        }

        // 콘텐츠 높이 조정
        var contentRT = listContainer.GetComponent<RectTransform>();
        contentRT.sizeDelta = new Vector2(0, count * (ITEM_H + SPACING));

        // 남은 아이템 숨기기
        for (int i = reuse; i < listItems.Count; i++)
            if (listItems[i] != null) listItems[i].SetActive(false);
    }

    // ────────────────────────────────────────
    // 버튼 액션
    // ────────────────────────────────────────

    void OnAwakenClicked(string heroName)
    {
        var hlm = HeroLevelManager.Instance;
        if (hlm == null) return;

        if (!hlm.CanAwaken(heroName))
        {
            int star   = hlm.GetStarRank(heroName);
            int needed = hlm.GetAwakeningCopiesNeeded(star);
            int copies = hlm.GetCopies(heroName);
            ToastNotification.Instance?.Show("각성 불가", $"카피 {needed}개 필요 (보유: {copies}개)", UIColors.Defeat_Red);
            return;
        }

        SoundManager.Instance?.PlayButtonSFX();
        bool success = hlm.TryAwaken(heroName);

        if (!success)
        {
            // 각성 실패 → 광고 재시도 팝업
            ShowAwakeningRetryPopup(heroName);
        }
        // OnHeroAwakened 이벤트로 Refresh가 자동 호출됨
    }

    void ShowAwakeningRetryPopup(string heroName)
    {
        var popup = UIHelper.MakeUI("RetryPopup", null);
        popup.name = "AwakeningRetryPopup";
        popup.transform.SetAsLastSibling();

        var canvas = popup.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvas.sortingOrder = 100;

        var scaler = popup.AddComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = UIConstants.ReferenceResolution;
        scaler.matchWidthOrHeight = UIConstants.MatchWidthOrHeight;

        // 배경
        var bgImg = UIHelper.MakePanel("BG", popup.transform, new Color(0, 0, 0, 0.7f));
        UIHelper.FillParent(bgImg.GetComponent<RectTransform>());
        bgImg.GetComponent<Image>().raycastTarget = true;

        // 컨테이너
        var container = UIHelper.MakeUI("Container", popup.transform);
        var crt = container.GetComponent<RectTransform>();
        crt.anchorMin = new Vector2(0.5f, 0.5f);
        crt.anchorMax = new Vector2(0.5f, 0.5f);
        crt.pivot = Vector2.one * 0.5f;
        crt.sizeDelta = new Vector2(280f, 200f);

        var contentBg = UIHelper.MakeSpritePanel("ContentBG", container.transform,
            UISprites.BoxBasic3, UIColors.Panel_Dark);
        UIHelper.FillParent(contentBg.GetComponent<RectTransform>());

        // 텍스트
        var titleText = UIHelper.MakeText("Title", container.transform,
            "각성 실패",
            14f, TextAlignmentOptions.Center, UIColors.Text_Gold);
        var trt = titleText.GetComponent<RectTransform>();
        trt.anchorMin = new Vector2(0.1f, 0.65f);
        trt.anchorMax = new Vector2(0.9f, 0.85f);
        titleText.fontStyle = FontStyles.Bold;

        var descText = UIHelper.MakeText("Desc", container.transform,
            "광고를 시청하고\n성공률 +20%로 재시도하시겠습니까?",
            11f, TextAlignmentOptions.Center, UIColors.Text_Secondary);
        var drt = descText.GetComponent<RectTransform>();
        drt.anchorMin = new Vector2(0.1f, 0.35f);
        drt.anchorMax = new Vector2(0.9f, 0.65f);

        // 취소 버튼
        var (cancelBtn, _) = UIHelper.MakeSpriteButton("Cancel", container.transform,
            UISprites.Btn1_WS, UIColors.Button_Gray, "", 10f);
        var cbrt = cancelBtn.GetComponent<RectTransform>();
        cbrt.anchorMin = new Vector2(0.05f, 0.05f);
        cbrt.anchorMax = new Vector2(0.45f, 0.25f);
        UIHelper.MakeText("Label", cancelBtn.transform, "취소",
            10f, TextAlignmentOptions.Center, Color.white);
        cancelBtn.onClick.AddListener(() => Object.Destroy(popup));

        // 재시도 버튼
        var (retryBtn, _2) = UIHelper.MakeSpriteButton("Retry", container.transform,
            UISprites.Btn2_WS, UIColors.Button_Green, "", 10f);
        var rbrt = retryBtn.GetComponent<RectTransform>();
        rbrt.anchorMin = new Vector2(0.55f, 0.05f);
        rbrt.anchorMax = new Vector2(0.95f, 0.25f);
        UIHelper.MakeText("Label", retryBtn.transform, "광고 보고 재시도",
            10f, TextAlignmentOptions.Center, Color.white);

        retryBtn.onClick.AddListener(() =>
        {
            Object.Destroy(popup);
            OnRetryWithAdClicked(heroName);
        });
    }

    void OnRetryWithAdClicked(string heroName)
    {
        if (AdManager.Instance != null)
        {
            AdManager.Instance.ShowRewardedAd(
                AdManager.AdRewardType.EnhanceRetry,
                () =>
                {
                    var hlm = HeroLevelManager.Instance;
                    if (hlm != null)
                    {
                        // 성공률 +20% 적용 후 재시도 (구현 필요: HeroLevelManager.TryAwaken(heroName, bonusSuccessRate))
                        // 임시: 100% 성공으로 처리
                        hlm.TryAwaken(heroName);
                    }
                }
            );
        }
    }

    // ────────────────────────────────────────
    // List pooling helpers
    // ────────────────────────────────────────

    static void RecycleList(List<GameObject> items)
    {
        for (int i = 0; i < items.Count; i++)
            if (items[i] != null) items[i].SetActive(false);
    }

    static GameObject ReuseOrCreate(List<GameObject> pool, ref int reuseIdx,
        string name, Transform parent, Color bgColor)
    {
        GameObject obj;
        if (reuseIdx < pool.Count && pool[reuseIdx] != null)
        {
            obj = pool[reuseIdx];
            obj.SetActive(true);
            foreach (Transform child in obj.transform)
                Object.Destroy(child.gameObject);
        }
        else
        {
            obj = UIHelper.MakePanel(name, parent, bgColor).gameObject;
            pool.Add(obj);
        }
        reuseIdx++;
        return obj;
    }
}
