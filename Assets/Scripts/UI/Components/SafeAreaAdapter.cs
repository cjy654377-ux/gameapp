using UnityEngine;

/// <summary>
/// SafeArea 자동 대응 컴포넌트.
/// Portrait 고정이므로 Awake에서 1회만 적용.
/// </summary>
[RequireComponent(typeof(RectTransform))]
public class SafeAreaAdapter : MonoBehaviour
{
    void Awake()
    {
        var rt = GetComponent<RectTransform>();
        var safeArea = Screen.safeArea;

        var anchorMin = safeArea.position;
        var anchorMax = safeArea.position + safeArea.size;

        anchorMin.x /= Screen.width;
        anchorMin.y /= Screen.height;
        anchorMax.x /= Screen.width;
        anchorMax.y /= Screen.height;

        rt.anchorMin = anchorMin;
        rt.anchorMax = anchorMax;
    }
}
