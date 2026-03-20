using UnityEngine;
using UnityEngine.UI;
using TMPro;

/// <summary>
/// UI 오브젝트 생성 헬퍼. MainHUD 등에서 재사용.
/// </summary>
public static class UIHelper
{
    public static GameObject MakeUI(string name, Transform parent)
    {
        var obj = new GameObject(name, typeof(RectTransform));
        obj.transform.SetParent(parent, false);
        return obj;
    }

    public static TextMeshProUGUI MakeText(string name, Transform parent, string text, float size, TextAlignmentOptions align, Color color)
    {
        var obj = MakeUI(name, parent);
        var tmp = obj.AddComponent<TextMeshProUGUI>();
        tmp.text = text;
        tmp.fontSize = size;
        tmp.alignment = align;
        tmp.color = color;
        return tmp;
    }

    public static TextMeshProUGUI MakeText(string name, Transform parent, string text, float size, TextAlignmentOptions align)
    {
        return MakeText(name, parent, text, size, align, UIColors.Text_Primary);
    }

    public static Image MakePanel(string name, Transform parent, Color bgColor)
    {
        var obj = MakeUI(name, parent);
        var img = obj.AddComponent<Image>();
        img.color = bgColor;
        return img;
    }

    public static (Button btn, Image img) MakeButton(string name, Transform parent, Color bgColor, string label, float fontSize)
    {
        var obj = MakeUI(name, parent);
        var img = obj.AddComponent<Image>();
        img.color = bgColor;
        var btn = obj.AddComponent<Button>();
        btn.targetGraphic = img;

        if (!string.IsNullOrEmpty(label))
        {
            var txt = MakeText("Label", obj.transform, label, fontSize, TextAlignmentOptions.Center);
            txt.fontStyle = FontStyles.Bold;
            FillParent(txt.GetComponent<RectTransform>());
        }

        return (btn, img);
    }

    public static void SetAnchors(GameObject obj, Vector2 anchorMin, Vector2 anchorMax, Vector2 pivot)
    {
        var rt = obj.GetComponent<RectTransform>();
        rt.anchorMin = anchorMin;
        rt.anchorMax = anchorMax;
        rt.pivot = pivot;
        rt.anchoredPosition = Vector2.zero;
    }

    public static void FillParent(RectTransform rt)
    {
        rt.anchorMin = Vector2.zero;
        rt.anchorMax = Vector2.one;
        rt.offsetMin = Vector2.zero;
        rt.offsetMax = Vector2.zero;
    }

    public static string FormatNumber(int n)
    {
        if (n >= 1000000) return (n / 1000000f).ToString("F1") + "M";
        if (n >= 1000) return (n / 1000f).ToString("F1") + "K";
        return n.ToString();
    }
}
