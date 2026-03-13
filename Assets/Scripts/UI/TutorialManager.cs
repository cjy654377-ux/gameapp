using UnityEngine;

/// <summary>
/// Tutorial progression manager. Tracks steps via PlayerPrefs and shows overlay messages.
/// Steps:
/// 0 -> 전투 시작 시: "적이 나타났다! 화면을 탭하여 번개를 내려보세요!"
/// 1 -> 첫 웨이브 클리어 시: "웨이브 클리어! 골드를 획득했습니다."
/// 2 -> 골드 50 이상: "하단의 훈련 탭에서 번개를 강화하세요."
/// 3 -> 골드 사용 후(업그레이드 구매): "소환 탭에서 새로운 영웅을 뽑아보세요!"
/// 4 -> 보석 50 이상: "편성 탭에서 영웅을 배치하세요."
/// 5 -> 스킬 장착됨: "스킬 버튼으로 강력한 스킬을 사용하세요."
/// 6 -> 5웨이브 도달: "상점 탭에서 미션 보상을 확인하세요!"
/// </summary>
public class TutorialManager : MonoBehaviour
{
    public static TutorialManager Instance { get; private set; }

    public bool IsTutorialActive { get; private set; }

    public int CurrentStep => currentStep;
    int currentStep;
    bool tutorialComplete;
    TutorialOverlay overlay;

    const int TOTAL_STEPS = 7;

    static readonly string[] MESSAGES =
    {
        "적이 나타났다!\n화면을 탭하여 번개를 내려보세요!",
        "웨이브 클리어!\n골드를 획득했습니다.",
        "하단의 <color=#FFD700>훈련</color> 탭에서\n번개를 강화하세요.",
        "<color=#FFD700>소환</color> 탭에서\n새로운 영웅을 뽑아보세요!",
        "<color=#87CEEB>편성</color> 탭에서\n영웅을 배치하세요.",
        "스킬 버튼으로\n강력한 스킬을 사용하세요.",
        "<color=#FFD700>상점 > 미션</color> 탭에서\n미션 보상을 확인하세요!",
    };

    // Cached references for safe unsubscribe
    GoldManager cachedGoldMgr;
    GemManager cachedGemMgr;
    StageManager cachedStageMgr;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        currentStep = PlayerPrefs.GetInt("TutorialStep", 0);
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
        cachedGemMgr = GemManager.Instance;
        cachedStageMgr = StageManager.Instance;

        if (cachedGoldMgr != null)
            cachedGoldMgr.OnGoldChanged += OnGoldChanged;
        if (cachedGemMgr != null)
            cachedGemMgr.OnGemChanged += OnGemChanged;
        if (cachedStageMgr != null)
            cachedStageMgr.OnStageChanged += OnStageChanged;

        // 시작 시 step 0 즉시 체크
        CheckAndShowTutorial();
    }

    void OnDestroy()
    {
        if (cachedGoldMgr != null)
            cachedGoldMgr.OnGoldChanged -= OnGoldChanged;
        if (cachedGemMgr != null)
            cachedGemMgr.OnGemChanged -= OnGemChanged;
        if (cachedStageMgr != null)
            cachedStageMgr.OnStageChanged -= OnStageChanged;
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

        switch (currentStep)
        {
            case 0: // 전투 시작
                if (BattleManager.Instance != null &&
                    BattleManager.Instance.CurrentState == BattleManager.BattleState.Fighting)
                    ShowStep(0);
                break;
            case 3: // 소환 유도 (업그레이드 1회 이상)
                if (TapDamageSystem.Instance != null && TapDamageSystem.Instance.tapDamageLevel > 1)
                    ShowStep(3);
                break;
            case 4: // 편성 유도
                if (DeckManager.Instance != null && DeckManager.Instance.roster.Count > 3)
                    ShowStep(4);
                break;
            case 5: // 스킬 유도
                if (SkillManager.Instance != null && SkillManager.Instance.equippedSkills.Count > 0)
                    ShowStep(5);
                break;
        }
    }

    void OnStageChanged(int area, int stage, int wave)
    {
        if (IsTutorialActive) return;
        if (currentStep == 1)
            ShowStep(1);
        else if (currentStep == 6 && wave >= 5)
            ShowStep(6);
    }

    void OnGoldChanged(int gold)
    {
        if (currentStep == 2 && gold >= 50 && !IsTutorialActive)
            ShowStep(2);
    }

    void OnGemChanged(int gems)
    {
        // 보석 관련 튜토리얼은 제거됨 (step 3은 업그레이드 기반으로 변경)
    }

    void ShowStep(int step)
    {
        if (step >= TOTAL_STEPS || step != currentStep) return;
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

        currentStep++;
        PlayerPrefs.SetInt("TutorialStep", currentStep);
        PlayerPrefs.Save();
        IsTutorialActive = false;

        if (currentStep >= TOTAL_STEPS)
            tutorialComplete = true;
    }

    public void ResetTutorial()
    {
        currentStep = 0;
        tutorialComplete = false;
        PlayerPrefs.SetInt("TutorialStep", 0);
        PlayerPrefs.Save();
    }
}
