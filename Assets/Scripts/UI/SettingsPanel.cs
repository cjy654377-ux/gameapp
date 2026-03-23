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
    TextMeshProUGUI loginStatusText;

    bool damageNumbersVisible = true;
    bool screenLockPrevented = false;
    TextMeshProUGUI damageToggleText;
    TextMeshProUGUI lockToggleText;

    public void Init(Transform parent)
    {
        var content = UIHelper.MakeUI("SettingsContent", parent);
        var crt = content.GetComponent<RectTransform>();
        crt.anchorMin = Vector2.zero;
        crt.anchorMax = Vector2.one;
        crt.offsetMin = new Vector2(UIConstants.Spacing_Medium, UIConstants.Spacing_Medium);
        crt.offsetMax = new Vector2(-UIConstants.Spacing_Medium, 0);

        BuildVolumeSlider(content.transform, "BGM 볼륨", 0.75f, 0.97f,
            out bgmSlider, out bgmValueText, (val) =>
            {
                SoundManager.Instance?.SetBGMVolume(val);
                if (bgmValueText != null) bgmValueText.text = $"{Mathf.RoundToInt(val * 100)}%";
            });

        BuildVolumeSlider(content.transform, "SFX 볼륨", 0.52f, 0.74f,
            out sfxSlider, out sfxValueText, (val) =>
            {
                SoundManager.Instance?.SetSFXVolume(val);
                if (sfxValueText != null) sfxValueText.text = $"{Mathf.RoundToInt(val * 100)}%";
            });

        // 데미지 숫자 표시 토글
        AddToggleButton(content.transform, "DamageToggleBtn", "데미지 숫자 표시", 0.48f, 0.58f,
            ref damageToggleText, ref damageNumbersVisible, OnToggleDamageNumbers);

        // 화면 잠금 방지 토글
        AddToggleButton(content.transform, "LockToggleBtn", "화면 잠금 방지", 0.36f, 0.46f,
            ref lockToggleText, ref screenLockPrevented, OnToggleScreenLock);

        // 로그인 상태 텍스트
        loginStatusText = UIHelper.MakeText("LoginStatus", content.transform, "로그인 중...",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, UIColors.Text_Secondary);
        var lsrt = loginStatusText.GetComponent<RectTransform>();
        lsrt.anchorMin = new Vector2(0, 0.44f);
        lsrt.anchorMax = new Vector2(1, 0.51f);
        lsrt.offsetMin = lsrt.offsetMax = Vector2.zero;
        RefreshLoginStatus();

        // Google 로그인 버튼
        AddSettingsBtn(content.transform, "GoogleLoginBtn", "Google 로그인", UIColors.Button_Blue,
            new Vector2(0, 0.35f), new Vector2(1, 0.43f), OnGoogleLogin);

        // 클라우드 저장 버튼
        AddSettingsBtn(content.transform, "CloudSaveBtn", "☁ 클라우드 저장", UIColors.Button_Green,
            new Vector2(0, 0.25f), new Vector2(0.48f, 0.34f), OnCloudSave);

        // 클라우드 불러오기 버튼
        AddSettingsBtn(content.transform, "CloudLoadBtn", "☁ 불러오기", UIColors.Button_Brown,
            new Vector2(0.52f, 0.25f), new Vector2(1, 0.34f), OnCloudLoad);

        // 데이터 초기화
        var (resetBtn, _) = UIHelper.MakeSpriteButton("ResetBtn", content.transform,
            UISprites.Btn4_WS, UIColors.Defeat_Red, "", UIConstants.Font_Button);
        var rbrt = resetBtn.GetComponent<RectTransform>();
        rbrt.anchorMin = new Vector2(0.15f, 0.03f);
        rbrt.anchorMax = new Vector2(0.85f, 0.14f);
        rbrt.offsetMin = Vector2.zero;
        rbrt.offsetMax = Vector2.zero;
        var resetText = UIHelper.MakeText("Label", resetBtn.transform, "데이터 초기화",
            UIConstants.Font_Button, TextAlignmentOptions.Center, Color.white);
        resetText.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(resetText.GetComponent<RectTransform>());
        resetBtn.onClick.AddListener(OnResetData);
    }

    void AddSettingsBtn(Transform parent, string name, string label, Color color,
        Vector2 anchorMin, Vector2 anchorMax, UnityEngine.Events.UnityAction onClick)
    {
        var (btn, _) = UIHelper.MakeSpriteButton(name, parent,
            UISprites.Btn2_WS, color, "", UIConstants.Font_SmallInfo);
        var rt = btn.GetComponent<RectTransform>();
        rt.anchorMin = anchorMin;
        rt.anchorMax = anchorMax;
        rt.offsetMin = rt.offsetMax = Vector2.zero;
        var txt = UIHelper.MakeText("Label", btn.transform, label,
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, Color.white);
        txt.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(txt.GetComponent<RectTransform>());
        btn.onClick.AddListener(onClick);
    }

    void AddToggleButton(Transform parent, string name, string label, float yMin, float yMax,
        ref TextMeshProUGUI toggleText, ref bool toggleState, UnityEngine.Events.UnityAction onClick)
    {
        var rowBg = UIHelper.MakeSpritePanel($"{name}Row", parent,
            UISprites.BoxBasic3, UIColors.Panel_Inner);
        var rrt = rowBg.GetComponent<RectTransform>();
        rrt.anchorMin = new Vector2(0, yMin);
        rrt.anchorMax = new Vector2(1, yMax);
        rrt.offsetMin = new Vector2(0, 2);
        rrt.offsetMax = new Vector2(0, -2);

        var labelText = UIHelper.MakeText("Label", rowBg.transform, label,
            UIConstants.Font_StatValue, TextAlignmentOptions.MidlineLeft, UIColors.Text_Dark);
        labelText.fontStyle = FontStyles.Bold;
        var lrt = labelText.GetComponent<RectTransform>();
        lrt.anchorMin = new Vector2(0, 0);
        lrt.anchorMax = new Vector2(0.6f, 1);
        lrt.offsetMin = new Vector2(UIConstants.Spacing_Medium, 0);
        lrt.offsetMax = Vector2.zero;

        bool initialState = toggleState;
        var (toggleBtn, _) = UIHelper.MakeSpriteButton("Toggle", rowBg.transform,
            UISprites.Btn2_WS, initialState ? UIColors.Button_Green : UIColors.Button_Brown,
            "", UIConstants.Font_SmallInfo);
        var trt = toggleBtn.GetComponent<RectTransform>();
        trt.anchorMin = new Vector2(0.65f, 0.15f);
        trt.anchorMax = new Vector2(0.95f, 0.85f);
        trt.offsetMin = Vector2.zero;
        trt.offsetMax = Vector2.zero;

        var statusText = UIHelper.MakeText("Status", toggleBtn.transform, initialState ? "활성화" : "비활성화",
            UIConstants.Font_SmallInfo, TextAlignmentOptions.Center, Color.white);
        statusText.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(statusText.GetComponent<RectTransform>());
        toggleText = statusText;

        // 로컬 캡처용
        var capturedText = statusText;
        bool[] stateRef = { initialState };

        toggleBtn.onClick.AddListener(() =>
        {
            stateRef[0] = !stateRef[0];
            var btnImg = toggleBtn.GetComponent<Image>();
            btnImg.color = stateRef[0] ? UIColors.Button_Green : UIColors.Button_Brown;
            if (capturedText != null) capturedText.text = stateRef[0] ? "활성화" : "비활성화";
            onClick?.Invoke();
        });
    }

    void RefreshLoginStatus()
    {
        if (loginStatusText == null) return;
        var auth = AuthManager.Instance;
        if (auth == null || !auth.IsLoggedIn)
        {
            loginStatusText.text = "로그인 안됨";
            loginStatusText.color = UIColors.Text_Disabled;
        }
        else
        {
            string provider = auth.CurrentProvider switch
            {
                AuthProvider.Google => "Google",
                AuthProvider.Apple  => "Apple",
                _                   => "게스트"
            };
            loginStatusText.text = $"{auth.DisplayName}  ({provider})";
            loginStatusText.color = UIColors.Text_Secondary;
        }
    }

    void OnGoogleLogin()
    {
        AuthManager.Instance?.LoginWithGoogle();
        RefreshLoginStatus();
        ToastNotification.Instance?.Show("로그인", "Google 로그인 시도 중...", UIColors.Button_Blue);
    }

    void OnCloudSave()
    {
        var csm = CloudSaveManager.Instance;
        if (csm == null) return;
        csm.OnSaveComplete += OnSaveResult;
        csm.SaveToCloud();
    }

    void OnSaveResult(bool ok)
    {
        if (CloudSaveManager.Instance != null)
            CloudSaveManager.Instance.OnSaveComplete -= OnSaveResult;
        string msg = ok ? "클라우드 저장 완료" : "저장 실패 (로그인 필요)";
        Color col = ok ? UIColors.Button_Green : UIColors.Defeat_Red;
        ToastNotification.Instance?.Show("클라우드 저장", msg, col);
    }

    void OnCloudLoad()
    {
        var csm = CloudSaveManager.Instance;
        if (csm == null) return;
        csm.OnLoadComplete += OnLoadResult;
        csm.LoadFromCloud();
    }

    void OnLoadResult(bool ok)
    {
        if (CloudSaveManager.Instance != null)
            CloudSaveManager.Instance.OnLoadComplete -= OnLoadResult;
        string msg = ok ? "클라우드 불러오기 완료" : "Firestore SDK 필요 (준비 중)";
        Color col = ok ? UIColors.Button_Green : UIColors.Button_Brown;
        ToastNotification.Instance?.Show("클라우드 불러오기", msg, col);
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

        // 토글 상태 로드
        damageNumbersVisible = PlayerPrefs.GetInt(SaveKeys.ShowDamageNumbers, 1) == 1;
        screenLockPrevented = PlayerPrefs.GetInt(SaveKeys.ScreenLockPrevented, 0) == 1;

        if (damageToggleText != null)
            damageToggleText.text = damageNumbersVisible ? "활성화" : "비활성화";
        if (lockToggleText != null)
            lockToggleText.text = screenLockPrevented ? "활성화" : "비활성화";
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
            UIConstants.Font_StatValue, TextAlignmentOptions.MidlineLeft, UIColors.Text_Dark);
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
            UIConstants.Font_HeaderMedium, TextAlignmentOptions.Center, UIColors.Text_Dark);
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
        // 씬 리로드하여 메모리 값도 초기화
        UnityEngine.SceneManagement.SceneManager.LoadScene(
            UnityEngine.SceneManagement.SceneManager.GetActiveScene().buildIndex);
    }

    void OnToggleDamageNumbers()
    {
        PlayerPrefs.SetInt(SaveKeys.ShowDamageNumbers, damageNumbersVisible ? 1 : 0);
        PlayerPrefs.Save();
        ToastNotification.Instance?.Show("데미지 숫자",
            damageNumbersVisible ? "활성화됨" : "비활성화됨",
            UIColors.Button_Green);
    }

    void OnToggleScreenLock()
    {
        Screen.sleepTimeout = screenLockPrevented ? -1 : 0;
        PlayerPrefs.SetInt(SaveKeys.ScreenLockPrevented, screenLockPrevented ? 1 : 0);
        PlayerPrefs.Save();
        ToastNotification.Instance?.Show("화면 잠금",
            screenLockPrevented ? "방지 활성화" : "기본값으로 복원",
            UIColors.Button_Green);
    }

    void OnDestroy()
    {
        if (bgmSlider != null) bgmSlider.onValueChanged.RemoveAllListeners();
        if (sfxSlider != null) sfxSlider.onValueChanged.RemoveAllListeners();
    }
}
