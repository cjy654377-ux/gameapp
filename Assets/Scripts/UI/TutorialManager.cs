using UnityEngine;

/// <summary>
/// Tutorial progression manager. Tracks steps via PlayerPrefs and shows overlay messages.
/// 0 -> 전투 시작 3초 후: 자동 전투 안내
/// 1 -> 첫 웨이브 클리어: 소환 탭 유도
/// 2 -> 첫 소환 후: 영웅 탭 편성 유도
/// 3 -> 덱 2명+: 스킬 장착 유도
/// 4 -> 스킬 2개+: 시너지 안내
/// 5 -> 10웨이브: 던전 안내
/// 6 -> 15웨이브 또는 던전 클리어: 각성 안내
/// 7 -> 20웨이브: 탈것 안내
/// </summary>
public class TutorialManager : MonoBehaviour
{
    public static TutorialManager Instance { get; private set; }

    public bool IsTutorialActive { get; private set; }

    public int CurrentStep => currentStep;
    int currentStep;
    bool tutorialComplete;
    TutorialOverlay overlay;

    const int TOTAL_STEPS = 8;

    static readonly string[] MESSAGES =
    {
        "전투가 자동으로 진행됩니다!\n영웅을 모아 더 강해지세요.",
        "첫 승리! 골드를 획득했어요.\n<color=#FFD700>소환</color> 탭에서 영웅을 뽑아볼까요?",
        "새 영웅 획득!\n<color=#FFD700>영웅</color> 탭에서 편성해보세요.",
        "편성 완료! 스킬도 장착해보세요.\n스킬 슬롯을 탭하세요.",
        "스킬 <color=#FF6B6B>시너지</color>를 확인해보세요!\n같은 속성 스킬을 모으면 보너스!",
        "<color=#87CEEB>던전</color>에 도전하면\n소환석과 각성석을 얻을 수 있어요!",
        "<color=#FF9900>각성</color>으로 영웅을 더 강화할 수 있어요.\n중복 영웅이 각성 재료가 됩니다!",
        "<color=#FF9900>탈것</color>을 장착하면\n이동속도와 스탯이 올라가요!",
    };

    // 각 스텝에서 자동으로 전환할 탭 인덱스 (-1=전환없음, 0=영웅, 1=소환, 3=던전)
    static readonly int[] STEP_TAB = { -1, 1, 0, -1, -1, 3, 0, 1 };

    float nextTutorialTime;   // 튜토리얼 간 3초 대기
    float battleStartRealtime = -1f; // step 0: 전투 시작 3초 후 체크

    // Cached references for safe unsubscribe
    GoldManager cachedGoldMgr;
    StageManager cachedStageMgr;
    GachaManager cachedGachaMgr;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        currentStep = PlayerPrefs.GetInt(SaveKeys.TutorialStep, 0);
        tutorialComplete = currentStep >= TOTAL_STEPS;
    }

    void Start()
    {
        if (tutorialComplete) return;

        var overlayObj = new GameObject("TutorialOverlay");
        overlayObj.transform.SetParent(transform);
        overlay = overlayObj.AddComponent<TutorialOverlay>();

        StartCoroutine(DeferredSubscribe());
    }

    System.Collections.IEnumerator DeferredSubscribe()
    {
        yield return null;

        cachedGoldMgr = GoldManager.Instance;
        cachedStageMgr = StageManager.Instance;
        cachedGachaMgr = GachaManager.Instance;

        if (cachedGoldMgr != null)
            cachedGoldMgr.OnGoldChanged += OnGoldChanged;
        if (cachedStageMgr != null)
            cachedStageMgr.OnStageChanged += OnStageChanged;
        if (cachedGachaMgr != null)
            cachedGachaMgr.OnHeroPulled += OnHeroPulled;

        // 시작 시 step 0 즉시 체크
        CheckAndShowTutorial();
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
        if (cachedGoldMgr != null)
            cachedGoldMgr.OnGoldChanged -= OnGoldChanged;
        if (cachedStageMgr != null)
            cachedStageMgr.OnStageChanged -= OnStageChanged;
        if (cachedGachaMgr != null)
            cachedGachaMgr.OnHeroPulled -= OnHeroPulled;
    }

    int checkFrameSkip;

    void Update()
    {
        if (tutorialComplete || IsTutorialActive) return;

        // 매 프레임 체크 불필요, 30프레임마다
        if (++checkFrameSkip < 30) return;
        checkFrameSkip = 0;
        CheckAndShowTutorial();
    }

    public void CheckAndShowTutorial()
    {
        if (tutorialComplete || IsTutorialActive) return;
        if (Time.realtimeSinceStartup < nextTutorialTime) return;

        switch (currentStep)
        {
            case 0: // 전투 시작 3초 후
                if (BattleManager.Instance != null &&
                    BattleManager.Instance.CurrentState == BattleManager.BattleState.Fighting)
                {
                    if (battleStartRealtime < 0f)
                        battleStartRealtime = Time.realtimeSinceStartup;
                    if (Time.realtimeSinceStartup - battleStartRealtime >= 3f)
                        ShowStep(0);
                }
                break;
            case 3: // 덱 2명+ → 스킬 장착 유도
                if (DeckManager.Instance != null && DeckManager.Instance.roster.Count >= 2)
                    ShowStep(3);
                break;
            case 4: // 스킬 2개+ → 시너지 안내
                if (SkillManager.Instance != null && SkillManager.Instance.equippedSkills.Count >= 2)
                    ShowStep(4);
                break;
            case 5: // 10웨이브 → 던전 안내
                if (StageManager.Instance != null && StageManager.Instance.TotalWaveIndex >= 10)
                    ShowStep(5);
                break;
            case 6: // 15웨이브 → 각성 안내
                if (StageManager.Instance != null && StageManager.Instance.TotalWaveIndex >= 15)
                    ShowStep(6);
                break;
            case 7: // 20웨이브 → 탈것 안내
                if (StageManager.Instance != null && StageManager.Instance.TotalWaveIndex >= 20)
                    ShowStep(7);
                break;
        }
    }

    void OnStageChanged(int area, int stage, int wave)
    {
        if (IsTutorialActive) return;
        if (currentStep == 1)
            ShowStep(1);
    }

    void OnGoldChanged(int gold) { } // 더 이상 골드 기반 트리거 없음

    void OnHeroPulled(CharacterPreset hero)
    {
        if (currentStep == 2 && !IsTutorialActive)
            ShowStep(2);
    }

    void ShowStep(int step)
    {
        if (step >= TOTAL_STEPS || step != currentStep) return;

        int tab = STEP_TAB[step];
        if (tab >= 0 && MainHUD.Instance != null)
        {
            MainHUD.Instance.SwitchToTab(tab);
            MainHUD.Instance.HighlightTab(tab);
        }

        ShowTutorial(MESSAGES[step]);
    }

    public void ShowTutorial(string message)
    {
        if (overlay == null || IsTutorialActive) return;
        IsTutorialActive = true;
        overlay.ShowMessage(message);
    }

    public void CompleteTutorialStep(int step)
    {
        if (step != currentStep) return;

        MainHUD.Instance?.StopHighlight();

        currentStep++;
        PlayerPrefs.SetInt(SaveKeys.TutorialStep, currentStep);
        PlayerPrefs.Save();
        IsTutorialActive = false;
        nextTutorialTime = Time.realtimeSinceStartup + 3f; // 다음 튜토리얼까지 3초 대기

        if (currentStep >= TOTAL_STEPS)
            tutorialComplete = true;
    }

    public void ResetTutorial()
    {
        currentStep = 0;
        tutorialComplete = false;
        PlayerPrefs.SetInt(SaveKeys.TutorialStep, 0);
        PlayerPrefs.Save();
    }
}
