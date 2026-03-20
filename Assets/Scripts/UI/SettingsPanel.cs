using UnityEngine;
using UnityEngine.UI;
using TMPro;

/// <summary>
/// 설정 패널: BGM/SFX 볼륨 슬라이더 + 데이터 초기화
/// MainHUD 상점 탭의 설정 서브탭에서 Init(parent)로 초기화 후 Refresh() 호출
/// </summary>
public class SettingsPanel : MonoBehaviour
{
    Slider bgmSlider;
    Slider sfxSlider;
    TextMeshProUGUI bgmValueText;
    TextMeshProUGUI sfxValueText;

    public void Init(Transform parent)
    {
        var content = UIHelper.MakeUI("SettingsContent", parent);
        var crt = content.GetComponent<RectTransform>();
        crt.anchorMin = Vector2.zero;
        crt.anchorMax = Vector2.one;
        crt.offsetMin = new Vector2(UIConstants.Spacing_Medium, UIConstants.Spacing_Medium);
        crt.offsetMax = new Vector2(-UIConstants.Spacing_Medium, 0);

        BuildVolumeSlider(content.transform, "BGM 볼륨", 0.7f, 1f,
            out bgmSlider, out bgmValueText, (val) =>
            {
                SoundManager.Instance?.SetBGMVolume(val);
                if (bgmValueText != null) bgmValueText.text = $"{Mathf.RoundToInt(val * 100)}%";
            });

        BuildVolumeSlider(content.transform, "SFX 볼륨", 0.4f, 1f,
            out sfxSlider, out sfxValueText, (val) =>
            {
                SoundManager.Instance?.SetSFXVolume(val);
                if (sfxValueText != null) sfxValueText.text = $"{Mathf.RoundToInt(val * 100)}%";
            });

        var (resetBtn, _) = UIHelper.MakeSpriteButton("ResetBtn", content.transform,
            UISprites.Btn4_WS, UIColors.Defeat_Red, "", UIConstants.Font_Button);
        var rbrt = resetBtn.GetComponent<RectTransform>();
        rbrt.anchorMin = new Vector2(0.15f, 0.05f);
        rbrt.anchorMax = new Vector2(0.85f, 0.2f);
        rbrt.offsetMin = Vector2.zero;
        rbrt.offsetMax = Vector2.zero;

        var resetText = UIHelper.MakeText("Label", resetBtn.transform, "데이터 초기화",
            UIConstants.Font_Button, TextAlignmentOptions.Center, Color.white);
        resetText.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(resetText.GetComponent<RectTransform>());

        resetBtn.onClick.AddListener(OnResetData);
    }

    public void Refresh()
    {
        var sm = SoundManager.Instance;
        if (sm == null) return;
        if (bgmSlider != null)
        {
            bgmSlider.SetValueWithoutNotify(sm.bgmVolume);
            if (bgmValueText != null) bgmValueText.text = $"{Mathf.RoundToInt(sm.bgmVolume * 100)}%";
        }
        if (sfxSlider != null)
        {
            sfxSlider.SetValueWithoutNotify(sm.sfxVolume);
            if (sfxValueText != null) sfxValueText.text = $"{Mathf.RoundToInt(sm.sfxVolume * 100)}%";
        }
    }

    void BuildVolumeSlider(Transform parent, string label, float yMin, float yMax,
        out Slider slider, out TextMeshProUGUI valueText, UnityEngine.Events.UnityAction<float> onChange)
    {
        var rowBg = UIHelper.MakeSpritePanel($"{label}Row", parent,
            UISprites.BoxBasic3, UIColors.Panel_Inner);
        var rrt = rowBg.GetComponent<RectTransform>();
        rrt.anchorMin = new Vector2(0, yMin);
        rrt.anchorMax = new Vector2(1, yMax);
        rrt.offsetMin = new Vector2(0, 2);
        rrt.offsetMax = new Vector2(0, -2);

        var labelText = UIHelper.MakeText("Label", rowBg.transform, label,
            UIConstants.Font_StatLabel, TextAlignmentOptions.MidlineLeft, UIColors.Text_DarkSecondary);
        labelText.fontStyle = FontStyles.Bold;
        var lrt = labelText.GetComponent<RectTransform>();
        lrt.anchorMin = new Vector2(0, 0);
        lrt.anchorMax = new Vector2(0.25f, 1);
        lrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
        lrt.offsetMax = Vector2.zero;

        var sliderObj = UIHelper.MakeUI("Slider", rowBg.transform);
        slider = sliderObj.AddComponent<Slider>();
        slider.minValue = 0;
        slider.maxValue = 1;
        slider.wholeNumbers = false;

        var srt = sliderObj.GetComponent<RectTransform>();
        srt.anchorMin = new Vector2(0.27f, 0.2f);
        srt.anchorMax = new Vector2(0.78f, 0.8f);
        srt.offsetMin = Vector2.zero;
        srt.offsetMax = Vector2.zero;

        var bgObj = UIHelper.MakePanel("Background", sliderObj.transform, UIColors.ProgressBar_BG);
        UIHelper.FillParent(bgObj.GetComponent<RectTransform>());
        slider.targetGraphic = bgObj;

        var fillArea = UIHelper.MakeUI("Fill Area", sliderObj.transform);
        var fart = fillArea.GetComponent<RectTransform>();
        fart.anchorMin = Vector2.zero;
        fart.anchorMax = Vector2.one;
        fart.offsetMin = Vector2.zero;
        fart.offsetMax = Vector2.zero;

        var fillObj = UIHelper.MakePanel("Fill", fillArea.transform, UIColors.ProgressBar_Fill);
        var fillRT = fillObj.GetComponent<RectTransform>();
        fillRT.anchorMin = Vector2.zero;
        fillRT.anchorMax = Vector2.one;
        fillRT.offsetMin = Vector2.zero;
        fillRT.offsetMax = Vector2.zero;
        slider.fillRect = fillRT;

        var handleArea = UIHelper.MakeUI("Handle Slide Area", sliderObj.transform);
        var hart = handleArea.GetComponent<RectTransform>();
        hart.anchorMin = Vector2.zero;
        hart.anchorMax = Vector2.one;
        hart.offsetMin = Vector2.zero;
        hart.offsetMax = Vector2.zero;

        var handleObj = UIHelper.MakePanel("Handle", handleArea.transform, Color.white);
        var hrt = handleObj.GetComponent<RectTransform>();
        hrt.sizeDelta = new Vector2(14, 0);
        slider.handleRect = hrt;

        valueText = UIHelper.MakeText("Value", rowBg.transform, "50%",
            UIConstants.Font_StatValue, TextAlignmentOptions.Center, UIColors.Text_Dark);
        valueText.fontStyle = FontStyles.Bold;
        var vrt = valueText.GetComponent<RectTransform>();
        vrt.anchorMin = new Vector2(0.80f, 0);
        vrt.anchorMax = new Vector2(1, 1);
        vrt.offsetMin = Vector2.zero;
        vrt.offsetMax = Vector2.zero;

        slider.onValueChanged.AddListener(onChange);
    }

    void OnResetData()
    {
        PlayerPrefs.DeleteAll();
        PlayerPrefs.Save();
        ToastNotification.Instance?.Show("데이터 초기화", "게임을 재시작합니다", UIColors.Defeat_Red);
    }
}
