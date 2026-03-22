using UnityEngine;

/// <summary>
/// Tutorial progression manager. Tracks steps via PlayerPrefs and shows overlay messages.
/// Steps (5탭 기준: 영웅0/소환1/전투2/던전3/상점4):
/// 0 -> 전투 시작: 화면 탭 안내
/// 1 -> 첫 웨이브 클리어: 골드 획득 안내
/// 2 -> 골드 50+: [영웅] 탭 편성 안내
/// 3 -> 덱 1명+: [소환] 탭 안내
/// 4 -> 덱 3명+: [던전] 탭 도전 안내
/// 5 -> 스킬 장착: 시너지 안내
/// 6 -> 5웨이브: 재화 6종 설명
/// 7 -> 10웨이브: 각성/탈것 시스템 안내
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
        "적이 나타났다!\n화면을 탭하여 공격하세요!",
        "웨이브 클리어!\n골드를 획득했습니다.",
        "하단의 <color=#FFD700>영웅</color> 탭을 눌러\n영웅을 편성해보세요.",
        "<color=#FFD700>소환</color> 탭에서\n새로운 영웅을 뽑아보세요!",
        "<color=#87CEEB>던전</color> 탭에 도전하여\n각성석과 소환석을 모으세요!",
        "스킬 <color=#FF6B6B>시너지</color>로\n전투력을 높여보세요!",
        "재화 6종을 모으세요:\n<color=#FFD700>골드·보석·소환석·주문서·각성석·명성</color>",
        "<color=#FF9900>각성 & 탈것</color>으로\n영웅을 더욱 강화하세요!",
    };

    float nextTutorialTime;   // 튜토리얼 간 3초 대기
    float battleStartRealtime = -1f; // step 0: 전투 시작 2초 후 체크

    // Cached references for safe unsubscribe
    GoldManager cachedGoldMgr;
    StageManager cachedStageMgr;

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

        if (cachedGoldMgr != null)
            cachedGoldMgr.OnGoldChanged += OnGoldChanged;
        if (cachedStageMgr != null)
            cachedStageMgr.OnStageChanged += OnStageChanged;

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
            case 0: // 전투 시작 2초 후
                if (BattleManager.Instance != null &&
                    BattleManager.Instance.CurrentState == BattleManager.BattleState.Fighting)
                {
                    if (battleStartRealtime < 0f)
                        battleStartRealtime = Time.realtimeSinceStartup;
                    if (Time.realtimeSinceStartup - battleStartRealtime >= 2f)
                        ShowStep(0);
                }
                break;
            case 3: // 소환 유도 (덱에 영웅 1명+)
                if (DeckManager.Instance != null && DeckManager.Instance.roster.Count >= 1)
                    ShowStep(3);
                break;
            case 4: // 던전 유도 (덱에 영웅 3명+)
                if (DeckManager.Instance != null && DeckManager.Instance.roster.Count >= 3)
                    ShowStep(4);
                break;
            case 5: // 시너지 유도 (스킬 장착)
                if (SkillManager.Instance != null && SkillManager.Instance.equippedSkills.Count > 0)
                    ShowStep(5);
                break;
            case 7: // 각성/탈것 유도 (10웨이브+)
                if (StageManager.Instance != null && StageManager.Instance.TotalWaveIndex >= 10)
                    ShowStep(7);
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
        else if (currentStep == 7 && wave >= 10)
            ShowStep(7);
    }

    void OnGoldChanged(int gold)
    {
        if (currentStep == 2 && gold >= 50 && !IsTutorialActive)
            ShowStep(2);
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
