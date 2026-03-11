using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// Slide-down toast notifications at the top of screen.
/// Queued system: one notification at a time, slides in/out.
/// Canvas sortingOrder 250.
/// </summary>
public class ToastNotification : MonoBehaviour
{
    public static ToastNotification Instance { get; private set; }

    Canvas canvas;
    RectTransform panelRT;
    Image panelBG;
    Image accentBar;
    TextMeshProUGUI titleText;
    TextMeshProUGUI subtitleText;

    readonly Queue<(string title, string subtitle, Color accent)> queue = new();
    bool isShowing;

    const float SLIDE_DURATION = 0.3f;
    const float HOLD_DURATION = 3f;
    const float PANEL_HEIGHT = 80f;
    const float HIDE_Y = 100f;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        BuildUI();
    }

    void Start()
    {
        // Wire to achievement system
        if (AchievementManager.Instance != null)
            AchievementManager.Instance.OnAchievementCompleted += OnAchievementCompleted;
    }

    void OnDestroy()
    {
        if (AchievementManager.Instance != null)
            AchievementManager.Instance.OnAchievementCompleted -= OnAchievementCompleted;
    }

    void OnAchievementCompleted(string id)
    {
        var achievements = AchievementManager.Instance?.GetAchievements();
        if (achievements == null) return;

        for (int i = 0; i < achievements.Count; i++)
        {
            if (achievements[i].id == id)
            {
                Show(
                    "업적 달성! " + achievements[i].name,
                    achievements[i].gemReward + " 보석 획득 가능",
                    UIColors.Text_Gold
                );
                break;
            }
        }
    }

    void BuildUI()
    {
        // Canvas
        var canvasObj = UIHelper.MakeUI("ToastCanvas", transform);
        canvas = canvasObj.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvas.sortingOrder = 250;
        var scaler = canvasObj.AddComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = new Vector2(390, 844);
        scaler.matchWidthOrHeight = 0.5f;
        canvasObj.AddComponent<GraphicRaycaster>();

        // Panel
        panelBG = UIHelper.MakePanel("ToastPanel", canvasObj.transform, UIColors.Background_Panel);
        var panelObj = panelBG.gameObject;
        panelRT = panelObj.GetComponent<RectTransform>();
        panelRT.anchorMin = new Vector2(0.05f, 1f);
        panelRT.anchorMax = new Vector2(0.95f, 1f);
        panelRT.pivot = new Vector2(0.5f, 1f);
        panelRT.sizeDelta = new Vector2(0, PANEL_HEIGHT);
        panelRT.anchoredPosition = new Vector2(0, HIDE_Y); // hidden above screen

        // Accent bar on left
        var barImg = UIHelper.MakePanel("AccentBar", panelObj.transform, UIColors.Text_Gold);
        accentBar = barImg;
        var barRT = barImg.GetComponent<RectTransform>();
        barRT.anchorMin = new Vector2(0, 0);
        barRT.anchorMax = new Vector2(0, 1);
        barRT.pivot = new Vector2(0, 0.5f);
        barRT.sizeDelta = new Vector2(4, 0);
        barRT.anchoredPosition = Vector2.zero;

        // Title text
        titleText = UIHelper.MakeText(
            "Title", panelObj.transform,
            "", 16f,
            TextAlignmentOptions.Left,
            UIColors.Text_Primary
        );
        titleText.fontStyle = FontStyles.Bold;
        var titleRT = titleText.GetComponent<RectTransform>();
        titleRT.anchorMin = new Vector2(0, 0.5f);
        titleRT.anchorMax = new Vector2(1, 1);
        titleRT.offsetMin = new Vector2(14, 0);
        titleRT.offsetMax = new Vector2(-10, -8);

        // Subtitle text
        subtitleText = UIHelper.MakeText(
            "Subtitle", panelObj.transform,
            "", 14f,
            TextAlignmentOptions.Left,
            UIColors.Text_Secondary
        );
        var subRT = subtitleText.GetComponent<RectTransform>();
        subRT.anchorMin = new Vector2(0, 0);
        subRT.anchorMax = new Vector2(1, 0.5f);
        subRT.offsetMin = new Vector2(14, 8);
        subRT.offsetMax = new Vector2(-10, 0);

        panelObj.SetActive(false);
    }

    public void Show(string title, string subtitle, Color? accentColor = null)
    {
        var color = accentColor ?? UIColors.Text_Gold;
        queue.Enqueue((title, subtitle, color));

        if (!isShowing)
            StartCoroutine(ProcessQueue());
    }

    IEnumerator ProcessQueue()
    {
        isShowing = true;

        while (queue.Count > 0)
        {
            var (title, subtitle, accent) = queue.Dequeue();

            titleText.text = title;
            subtitleText.text = subtitle;
            accentBar.color = accent;

            panelBG.gameObject.SetActive(true);

            // Slide in (from y=HIDE_Y to y=0)
            yield return SlidePanel(HIDE_Y, 0, SLIDE_DURATION);

            // Hold
            yield return new WaitForSeconds(HOLD_DURATION);

            // Slide out (from y=0 to y=HIDE_Y)
            yield return SlidePanel(0, HIDE_Y, SLIDE_DURATION);

            panelBG.gameObject.SetActive(false);
        }

        isShowing = false;
    }

    IEnumerator SlidePanel(float fromY, float toY, float duration)
    {
        float elapsed = 0;
        while (elapsed < duration)
        {
            elapsed += Time.unscaledDeltaTime;
            float t = Mathf.SmoothStep(0, 1, elapsed / duration);
            float y = Mathf.Lerp(fromY, toY, t);
            panelRT.anchoredPosition = new Vector2(0, y);
            yield return null;
        }
        panelRT.anchoredPosition = new Vector2(0, toY);
    }
}
