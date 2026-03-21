using UnityEngine;
using UnityEngine.UI;
using TMPro;

/// <summary>
/// UI 오브젝트 생성 헬퍼. MainHUD 등에서 재사용.
/// </summary>
public static class UIHelper
{
    // ── Sprite 지원 오버로드 ────────────────────────────────────

    /// border가 있으면 Sliced, 없으면 Simple 타입을 결정한다.
    static Image.Type SpriteImageType(Sprite sprite)
    {
        if (sprite == null) return Image.Type.Simple;
        var b = sprite.border;
        return (b.x > 0 || b.y > 0 || b.z > 0 || b.w > 0)
            ? Image.Type.Sliced
            : Image.Type.Simple;
    }

    /// 스프라이트와 폴백 컬러를 Image에 적용 (중복 제거용)
    static void ApplySpriteToImage(Image img, Sprite sprite, Color fallbackColor, Image.Type? forceType = null)
    {
        if (sprite != null)
        {
            img.sprite = sprite;
            img.type = forceType ?? SpriteImageType(sprite);
            img.color = Color.white;
        }
        else
        {
            img.color = fallbackColor;
        }
    }

    /// <summary>
    /// 스프라이트가 있으면 Sliced/Simple 이미지로, 없으면 단색 폴백으로 패널을 생성한다.
    /// </summary>
    public static Image MakeSpritePanel(string name, Transform parent, Sprite sprite, Color fallbackColor)
    {
        var obj = MakeUI(name, parent);
        var img = obj.AddComponent<Image>();
        ApplySpriteToImage(img, sprite, fallbackColor);
        return img;
    }

    /// <summary>
    /// 스프라이트가 있으면 Sliced/Simple 버튼으로, 없으면 단색 버튼으로 생성한다.
    /// </summary>
    public static (Button btn, Image img) MakeSpriteButton(string name, Transform parent,
        Sprite sprite, Color fallbackColor, string label, float fontSize)
    {
        var obj = MakeUI(name, parent);
        var img = obj.AddComponent<Image>();
        ApplySpriteToImage(img, sprite, fallbackColor);
        var btn = obj.AddComponent<Button>();
        btn.targetGraphic = img;
        obj.AddComponent<ButtonFeedback>();

        if (!string.IsNullOrEmpty(label))
        {
            var txt = MakeText("Label", obj.transform, label, fontSize, TextAlignmentOptions.Center);
            txt.fontStyle = FontStyles.Bold;
            FillParent(txt.GetComponent<RectTransform>());
        }

        return (btn, img);
    }

    /// <summary>
    /// UISprites 기본 버튼으로 생성 (Btn1_WS 사용, 스프라이트 자동 적용)
    /// </summary>
    public static (Button btn, Image img) MakeSpriteButton(string name, Transform parent, string label, float fontSize)
    {
        return MakeSpriteButton(name, parent, UISprites.Btn1_WS, UIColors.Button_Green, label, fontSize);
    }

    /// <summary>
    /// Image.Type.Filled 방식 게이지를 생성한다. 배경/채우기 모두 스프라이트 우선.
    /// </summary>
    public static (Image bg, Image fill) MakeGauge(string name, Transform parent,
        Sprite bgSprite, Color bgFallback,
        Sprite fillSprite, Color fillFallback)
    {
        var bgImg = MakeSpritePanel($"{name}_BG", parent, bgSprite, bgFallback);

        var fillObj = MakeUI($"{name}_Fill", bgImg.transform);
        var fillImg = fillObj.AddComponent<Image>();
        // Gauge fill은 항상 Image.Type.Filled (Sliced 대신)
        fillImg.type = Image.Type.Filled;
        fillImg.fillMethod = Image.FillMethod.Horizontal;
        if (fillSprite != null)
        {
            fillImg.sprite = fillSprite;
            fillImg.color = Color.white;
        }
        else
        {
            fillImg.color = fillFallback;
        }
        FillParent(fillObj.GetComponent<RectTransform>());

        return (bgImg, fillImg);
    }

    /// <summary>
    /// 아이콘 이미지 오브젝트를 생성한다. 스프라이트 없으면 단색 패널.
    /// </summary>
    public static Image MakeIcon(string name, Transform parent, Sprite sprite, Color fallbackColor)
    {
        var obj = MakeUI(name, parent);
        var img = obj.AddComponent<Image>();
        ApplySpriteToImage(img, sprite, fallbackColor, Image.Type.Simple);
        img.preserveAspect = true;
        return img;
    }


    public static GameObject MakeUI(string name, Transform parent)
    {
        var obj = new GameObject(name, typeof(RectTransform));
        obj.transform.SetParent(parent, false);
        return obj;
    }

    static TMP_FontAsset _cachedKoreanFont;

    public static TextMeshProUGUI MakeText(string name, Transform parent, string text, float size, TextAlignmentOptions align, Color color)
    {
        var obj = MakeUI(name, parent);
        var tmp = obj.AddComponent<TextMeshProUGUI>();
        // 한글 폰트 강제 지정
        if (_cachedKoreanFont == null)
            _cachedKoreanFont = Resources.Load<TMP_FontAsset>("Fonts/NanumSquareRoundB SDF");
        if (_cachedKoreanFont == null)
            _cachedKoreanFont = Resources.Load<TMP_FontAsset>("Fonts & Materials/NanumSquareRoundB SDF");
        if (_cachedKoreanFont != null)
            tmp.font = _cachedKoreanFont;
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

    /// <summary>
    /// 텍스트에 Outline 컴포넌트를 추가하여 가독성을 높인다.
    /// </summary>
    public static Outline AddTextOutline(TextMeshProUGUI tmp, Color outlineColor, Vector2 distance)
    {
        var outline = tmp.gameObject.AddComponent<Outline>();
        outline.effectColor = outlineColor;
        outline.effectDistance = distance;
        return outline;
    }

    /// <summary>
    /// 텍스트에 기본 어두운 Outline을 추가 (밝은 텍스트 가독성용).
    /// </summary>
    public static Outline AddTextShadow(TextMeshProUGUI tmp)
    {
        return AddTextOutline(tmp, new Color(0, 0, 0, 0.5f), new Vector2(1, -1));
    }

    /// <summary>
    /// 9-slice 스프라이트 패널 + LayoutGroup 패딩이 적용된 컨테이너.
    /// </summary>
    public static (Image panel, RectTransform contentArea) MakeFramedPanel(
        string name, Transform parent, Sprite sprite, Color fallbackColor, RectOffset padding)
    {
        var panel = MakeSpritePanel(name, parent, sprite, fallbackColor);

        var contentObj = MakeUI("Content", panel.transform);
        var contentRT = contentObj.GetComponent<RectTransform>();
        contentRT.anchorMin = Vector2.zero;
        contentRT.anchorMax = Vector2.one;
        contentRT.offsetMin = new Vector2(padding.left, padding.bottom);
        contentRT.offsetMax = new Vector2(-padding.right, -padding.top);

        return (panel, contentRT);
    }

    public static string FormatNumber(int n)
    {
        if (n >= 1000000) return (n / 1000000f).ToString("F1") + "M";
        if (n >= 1000) return (n / 1000f).ToString("F1") + "K";
        return n.ToString();
    }

    /// <summary>
    /// 아이콘 + 수량 텍스트를 가로로 배치한 재화 표시 (금, 보석 등)
    /// </summary>
    public static (Image icon, TextMeshProUGUI text) MakeResourceDisplay(
        string name, Transform parent, Sprite iconSprite, int amount, float fontSize = 24f)
    {
        var container = MakeUI(name, parent);
        var containerRT = container.GetComponent<RectTransform>();
        var hLayout = container.AddComponent<HorizontalLayoutGroup>();
        hLayout.spacing = 8f;
        hLayout.childForceExpandHeight = false;
        hLayout.childForceExpandWidth = false;

        var icon = MakeIcon("Icon", container.transform, iconSprite, Color.white);
        icon.GetComponent<RectTransform>().sizeDelta = new Vector2(40, 40);

        var txt = MakeText("Amount", container.transform, FormatNumber(amount), fontSize, TextAlignmentOptions.Left, UIColors.Text_Primary);
        var txtRT = txt.GetComponent<RectTransform>();
        txtRT.sizeDelta = new Vector2(100, 40);

        return (icon, txt);
    }

    /// <summary>
    /// 성급별 별 표시 (1~5성, 빈 별/채운 별로 표현)
    /// </summary>
    public static Transform MakeStarRating(string name, Transform parent, int starGrade, float starSize = 24f)
    {
        var container = MakeUI(name, parent);
        var containerRT = container.GetComponent<RectTransform>();
        containerRT.sizeDelta = new Vector2(starSize * 5 + 4, starSize);

        var hLayout = container.AddComponent<HorizontalLayoutGroup>();
        hLayout.spacing = 4f;
        hLayout.childForceExpandHeight = false;
        hLayout.childForceExpandWidth = false;

        // 빈별 색상과 채운별 색상
        Color emptyColor = new Color(0.6f, 0.6f, 0.6f, 0.5f);
        Color fillColor = new Color(1f, 0.84f, 0f, 1f); // 금색

        for (int i = 1; i <= 5; i++)
        {
            var starObj = MakeUI($"Star{i}", container.transform);
            var starImg = starObj.AddComponent<Image>();
            starImg.sprite = Resources.Load<Sprite>("UI/Icon_Star") ?? null;
            starImg.type = Image.Type.Simple;
            starImg.preserveAspect = true;
            starImg.color = (i <= starGrade) ? fillColor : emptyColor;

            var starRT = starObj.GetComponent<RectTransform>();
            starRT.sizeDelta = new Vector2(starSize, starSize);
        }

        return container.transform;
    }
}
