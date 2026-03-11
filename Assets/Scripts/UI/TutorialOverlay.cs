using UnityEngine;
using UnityEngine.UI;
using TMPro;

/// <summary>
/// Tutorial overlay UI. Full-screen dark panel with message and confirm button.
/// Canvas sortingOrder 300 to appear above everything.
/// </summary>
public class TutorialOverlay : MonoBehaviour
{
    Canvas canvas;
    GameObject panel;
    TextMeshProUGUI messageText;
    Button confirmButton;
    Button fullScreenButton;

    bool isShowing;

    void Awake()
    {
        BuildUI();
        panel.SetActive(false);
    }

    void BuildUI()
    {
        // Canvas
        var canvasObj = UIHelper.MakeUI("TutorialCanvas", transform);
        canvas = canvasObj.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvas.sortingOrder = 300;
        canvasObj.AddComponent<CanvasScaler>().uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        var scaler = canvasObj.GetComponent<CanvasScaler>();
        scaler.referenceResolution = UIConstants.ReferenceResolution;
        scaler.matchWidthOrHeight = UIConstants.MatchWidthOrHeight;
        canvasObj.AddComponent<GraphicRaycaster>();

        // Dark overlay panel (full screen)
        var panelImg = UIHelper.MakePanel("DarkPanel", canvasObj.transform, new Color(0, 0, 0, 0.6f));
        panel = panelImg.gameObject;
        var panelRT = panel.GetComponent<RectTransform>();
        UIHelper.FillParent(panelRT);

        // Full screen tap button (invisible, behind text)
        var tapObj = UIHelper.MakeUI("FullScreenTap", panel.transform);
        var tapImg = tapObj.AddComponent<Image>();
        tapImg.color = Color.clear;
        fullScreenButton = tapObj.AddComponent<Button>();
        fullScreenButton.targetGraphic = tapImg;
        var tapRT = tapObj.GetComponent<RectTransform>();
        UIHelper.FillParent(tapRT);
        fullScreenButton.onClick.AddListener(Hide);

        // Message container (centered)
        var container = UIHelper.MakeUI("MessageContainer", panel.transform);
        var containerRT = container.GetComponent<RectTransform>();
        containerRT.anchorMin = new Vector2(0.1f, 0.35f);
        containerRT.anchorMax = new Vector2(0.9f, 0.65f);
        containerRT.offsetMin = Vector2.zero;
        containerRT.offsetMax = Vector2.zero;

        // Message text
        messageText = UIHelper.MakeText(
            "MessageText", container.transform,
            "", 20f,
            TextAlignmentOptions.Center,
            UIColors.Text_Primary
        );
        var msgRT = messageText.GetComponent<RectTransform>();
        msgRT.anchorMin = new Vector2(0, 0.4f);
        msgRT.anchorMax = new Vector2(1, 1);
        msgRT.offsetMin = Vector2.zero;
        msgRT.offsetMax = Vector2.zero;
        messageText.textWrappingMode = TextWrappingModes.Normal;

        // Confirm button
        var (btn, btnImg) = UIHelper.MakeButton(
            "ConfirmButton", container.transform,
            UIColors.Button_Green,
            "확인", 16f
        );
        confirmButton = btn;
        var btnRT = btnImg.GetComponent<RectTransform>();
        btnRT.anchorMin = new Vector2(0.25f, 0f);
        btnRT.anchorMax = new Vector2(0.75f, 0.35f);
        btnRT.offsetMin = Vector2.zero;
        btnRT.offsetMax = Vector2.zero;
        confirmButton.onClick.AddListener(Hide);
    }

    public void ShowMessage(string text)
    {
        if (messageText == null) return;
        messageText.text = text;
        panel.SetActive(true);
        isShowing = true;
    }

    public void Hide()
    {
        if (!isShowing) return;
        isShowing = false;
        panel.SetActive(false);

        if (TutorialManager.Instance != null)
            TutorialManager.Instance.CompleteTutorialStep(TutorialManager.Instance.CurrentStep);
    }
}
