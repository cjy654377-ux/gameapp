using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using System.Collections;

/// <summary>
/// 버튼 터치 시 scale 0.95 + 복귀 연출.
/// Button 컴포넌트와 같은 GameObject에 추가하거나 UIHelper.MakeSpriteButton에서 자동 추가.
/// </summary>
[RequireComponent(typeof(Button))]
public class ButtonFeedback : MonoBehaviour, IPointerDownHandler, IPointerUpHandler
{
    const float PRESS_SCALE = 0.92f;
    const float PRESS_DURATION = 0.07f;
    const float RELEASE_DURATION = 0.09f;

    Vector3 originalScale;
    Coroutine currentAnim;

    void Awake()
    {
        originalScale = transform.localScale;
    }

    public void OnPointerDown(PointerEventData eventData)
    {
        if (currentAnim != null) StopCoroutine(currentAnim);
        currentAnim = StartCoroutine(ScaleTo(originalScale * PRESS_SCALE, PRESS_DURATION));
    }

    public void OnPointerUp(PointerEventData eventData)
    {
        if (currentAnim != null) StopCoroutine(currentAnim);
        currentAnim = StartCoroutine(ScaleTo(originalScale, RELEASE_DURATION));
    }

    IEnumerator ScaleTo(Vector3 target, float duration)
    {
        Vector3 start = transform.localScale;
        float t = 0;
        while (t < duration)
        {
            t += Time.unscaledDeltaTime;
            transform.localScale = Vector3.Lerp(start, target, t / duration);
            yield return null;
        }
        transform.localScale = target;
    }

    void OnDisable()
    {
        transform.localScale = originalScale;
    }
}
