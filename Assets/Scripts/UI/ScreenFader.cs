using UnityEngine;
using UnityEngine.UI;
using System.Collections;

/// <summary>
/// 스테이지 전환용 화면 페이드 아웃/인
/// Canvas sortingOrder를 최상위로 설정하여 모든 UI 위에 표시
/// </summary>
public class ScreenFader : MonoBehaviour
{
    public static ScreenFader Instance { get; private set; }

    Image fadeImage;
    RectTransform fadeRT;
    Canvas fadeCanvas;
    bool isFading;

    public bool IsFading => isFading;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        CreateFadeCanvas();
    }

    void CreateFadeCanvas()
    {
        fadeCanvas = gameObject.AddComponent<Canvas>();
        fadeCanvas.renderMode = RenderMode.ScreenSpaceOverlay;
        fadeCanvas.sortingOrder = 999;

        var scaler = gameObject.AddComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = UIConstants.ReferenceResolution;
        scaler.matchWidthOrHeight = UIConstants.MatchWidthOrHeight;

        var obj = UIHelper.MakeUI("FadeImage", fadeCanvas.transform);
        fadeImage = obj.AddComponent<Image>();
        fadeImage.color = new Color(0, 0, 0, 0);
        fadeImage.raycastTarget = false;
        fadeRT = obj.GetComponent<RectTransform>();
        UIHelper.FillParent(fadeRT);
    }

    /// <summary>
    /// 페이드 아웃 → onMidpoint 콜백 → 페이드 인
    /// </summary>
    public void FadeTransition(float fadeOutTime, float holdTime, float fadeInTime, System.Action onMidpoint)
    {
        if (isFading) return;
        StartCoroutine(FadeRoutine(fadeOutTime, holdTime, fadeInTime, onMidpoint));
    }

    IEnumerator FadeRoutine(float fadeOutTime, float holdTime, float fadeInTime, System.Action onMidpoint)
    {
        isFading = true;
        fadeImage.raycastTarget = true;

        // 탭 패널이 열려있으면 하단 제외
        UpdateFadeArea();

        // Fade out (투명 → 검정)
        float t = 0;
        while (t < fadeOutTime)
        {
            t += Time.unscaledDeltaTime;
            fadeImage.color = new Color(0, 0, 0, Mathf.Clamp01(t / fadeOutTime));
            yield return null;
        }
        fadeImage.color = Color.black;

        // 중간 콜백 (전장 정리, 재배치 등)
        onMidpoint?.Invoke();

        // Hold (완전 검정 유지)
        if (holdTime > 0)
            yield return new WaitForSecondsRealtime(holdTime);

        // Fade in (검정 → 투명)
        t = 0;
        while (t < fadeInTime)
        {
            t += Time.unscaledDeltaTime;
            fadeImage.color = new Color(0, 0, 0, 1f - Mathf.Clamp01(t / fadeInTime));
            yield return null;
        }
        fadeImage.color = new Color(0, 0, 0, 0);
        fadeImage.raycastTarget = false;
        isFading = false;

        // 페이드 끝나면 전체 화면으로 복원
        ResetFadeArea();
    }

    const float TAB_PANEL_TOP_ANCHOR = 0.48f;

    void UpdateFadeArea()
    {
        if (SkillUI.IsTabPanelOpen)
        {
            fadeRT.anchorMin = new Vector2(0, TAB_PANEL_TOP_ANCHOR);
            fadeRT.anchorMax = Vector2.one;
            fadeRT.offsetMin = Vector2.zero;
            fadeRT.offsetMax = Vector2.zero;
        }
        else
        {
            ResetFadeArea();
        }
    }

    void ResetFadeArea()
    {
        fadeRT.anchorMin = Vector2.zero;
        fadeRT.anchorMax = Vector2.one;
        fadeRT.offsetMin = Vector2.zero;
        fadeRT.offsetMax = Vector2.zero;
    }
}
