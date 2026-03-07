using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class BattleHUD : MonoBehaviour
{
    public static BattleHUD Instance { get; private set; }

    [Header("Result Panel")]
    private GameObject resultPanel;
    private TextMeshProUGUI resultText;
    private TextMeshProUGUI resultSubText;
    private Button retryButton;

    [Header("Stage Info")]
    private TextMeshProUGUI stageText;

    private Canvas canvas;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        CreateCanvas();
        CreateStageText();
        CreateResultPanel();

        resultPanel.SetActive(false);
    }

    void Start()
    {
        if (BattleManager.Instance != null)
            BattleManager.Instance.OnBattleStateChanged += OnBattleStateChanged;
    }

    void CreateCanvas()
    {
        canvas = gameObject.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvas.sortingOrder = 100;

        var scaler = gameObject.AddComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = new Vector2(1920, 1080);

        gameObject.AddComponent<GraphicRaycaster>();
    }

    void CreateStageText()
    {
        var stageObj = CreateUIObject("StageText", canvas.transform);
        stageText = stageObj.AddComponent<TextMeshProUGUI>();
        stageText.text = "STAGE 1";
        stageText.fontSize = 36;
        stageText.alignment = TextAlignmentOptions.Center;
        stageText.color = Color.white;

        var rt = stageObj.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0.5f, 1f);
        rt.anchorMax = new Vector2(0.5f, 1f);
        rt.pivot = new Vector2(0.5f, 1f);
        rt.anchoredPosition = new Vector2(0, -20);
        rt.sizeDelta = new Vector2(400, 50);
    }

    void CreateResultPanel()
    {
        // Dark overlay
        resultPanel = CreateUIObject("ResultPanel", canvas.transform);
        var panelImg = resultPanel.AddComponent<Image>();
        panelImg.color = new Color(0, 0, 0, 0.7f);
        var panelRT = resultPanel.GetComponent<RectTransform>();
        panelRT.anchorMin = Vector2.zero;
        panelRT.anchorMax = Vector2.one;
        panelRT.sizeDelta = Vector2.zero;

        // Result text (VICTORY / DEFEAT)
        var textObj = CreateUIObject("ResultText", resultPanel.transform);
        resultText = textObj.AddComponent<TextMeshProUGUI>();
        resultText.fontSize = 72;
        resultText.alignment = TextAlignmentOptions.Center;
        resultText.fontStyle = FontStyles.Bold;

        var textRT = textObj.GetComponent<RectTransform>();
        textRT.anchorMin = new Vector2(0.5f, 0.5f);
        textRT.anchorMax = new Vector2(0.5f, 0.5f);
        textRT.pivot = new Vector2(0.5f, 0.5f);
        textRT.anchoredPosition = new Vector2(0, 50);
        textRT.sizeDelta = new Vector2(600, 100);

        // Sub text
        var subObj = CreateUIObject("SubText", resultPanel.transform);
        resultSubText = subObj.AddComponent<TextMeshProUGUI>();
        resultSubText.fontSize = 32;
        resultSubText.alignment = TextAlignmentOptions.Center;
        resultSubText.color = new Color(0.8f, 0.8f, 0.8f);

        var subRT = subObj.GetComponent<RectTransform>();
        subRT.anchorMin = new Vector2(0.5f, 0.5f);
        subRT.anchorMax = new Vector2(0.5f, 0.5f);
        subRT.pivot = new Vector2(0.5f, 0.5f);
        subRT.anchoredPosition = new Vector2(0, -20);
        subRT.sizeDelta = new Vector2(600, 50);

        // Retry button
        var btnObj = CreateUIObject("RetryButton", resultPanel.transform);
        var btnImg = btnObj.AddComponent<Image>();
        btnImg.color = new Color(0.3f, 0.5f, 0.8f);
        retryButton = btnObj.AddComponent<Button>();
        retryButton.targetGraphic = btnImg;
        retryButton.onClick.AddListener(OnRetryClicked);

        var btnRT = btnObj.GetComponent<RectTransform>();
        btnRT.anchorMin = new Vector2(0.5f, 0.5f);
        btnRT.anchorMax = new Vector2(0.5f, 0.5f);
        btnRT.pivot = new Vector2(0.5f, 0.5f);
        btnRT.anchoredPosition = new Vector2(0, -100);
        btnRT.sizeDelta = new Vector2(200, 60);

        var btnTextObj = CreateUIObject("BtnText", btnObj.transform);
        var btnText = btnTextObj.AddComponent<TextMeshProUGUI>();
        btnText.text = "RETRY";
        btnText.fontSize = 28;
        btnText.alignment = TextAlignmentOptions.Center;
        btnText.color = Color.white;
        var btnTextRT = btnTextObj.GetComponent<RectTransform>();
        btnTextRT.anchorMin = Vector2.zero;
        btnTextRT.anchorMax = Vector2.one;
        btnTextRT.sizeDelta = Vector2.zero;
    }

    void OnBattleStateChanged(BattleManager.BattleState state)
    {
        if (state == BattleManager.BattleState.Victory)
        {
            resultPanel.SetActive(true);
            resultText.text = "VICTORY";
            resultText.color = new Color(1f, 0.85f, 0.2f);
            resultSubText.text = "All enemies defeated!";
        }
        else if (state == BattleManager.BattleState.Defeat)
        {
            resultPanel.SetActive(true);
            resultText.text = "DEFEAT";
            resultText.color = new Color(0.8f, 0.2f, 0.2f);
            resultSubText.text = "Your team has fallen...";
        }
    }

    void OnRetryClicked()
    {
        UnityEngine.SceneManagement.SceneManager.LoadScene(
            UnityEngine.SceneManagement.SceneManager.GetActiveScene().buildIndex);
    }

    public void SetStageText(string text)
    {
        if (stageText != null) stageText.text = text;
    }

    GameObject CreateUIObject(string name, Transform parent)
    {
        var obj = new GameObject(name, typeof(RectTransform));
        obj.transform.SetParent(parent, false);
        return obj;
    }

    void OnDestroy()
    {
        if (BattleManager.Instance != null)
            BattleManager.Instance.OnBattleStateChanged -= OnBattleStateChanged;
    }
}
