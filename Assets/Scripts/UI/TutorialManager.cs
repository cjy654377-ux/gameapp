using UnityEngine;

/// <summary>
/// Tutorial progression manager. Tracks steps via PlayerPrefs and shows overlay messages.
/// Steps:
/// 0 -> "적이 나타났다! 화면을 탭하여 번개를 내려보세요!"
/// 1 -> "웨이브 클리어! 골드를 획득했습니다." (after first wave clear)
/// 2 -> "하단의 훈련 탭에서 번개를 강화하세요." (gold >= 50)
/// 3 -> "소환 탭에서 새로운 영웅을 뽑아보세요!" (gems >= 50)
/// 4 -> "스킬 버튼으로 강력한 스킬을 사용하세요." (first skill equipped)
/// </summary>
public class TutorialManager : MonoBehaviour
{
    public static TutorialManager Instance { get; private set; }

    public bool IsTutorialActive { get; private set; }

    public int CurrentStep => currentStep;
    int currentStep;
    bool tutorialComplete;
    TutorialOverlay overlay;

    // Cached flags to avoid repeated checks
    bool waitingForWaveClear;
    bool subscribedToEvents;

    const int TOTAL_STEPS = 5;

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

        // Create overlay
        var overlayObj = new GameObject("TutorialOverlay");
        overlayObj.transform.SetParent(transform);
        overlay = overlayObj.AddComponent<TutorialOverlay>();

        SubscribeToEvents();
    }

    void SubscribeToEvents()
    {
        if (subscribedToEvents) return;
        subscribedToEvents = true;

        if (GoldManager.Instance != null)
            GoldManager.Instance.OnGoldChanged += OnGoldChanged;

        if (GemManager.Instance != null)
            GemManager.Instance.OnGemChanged += OnGemChanged;

        if (StageManager.Instance != null)
            StageManager.Instance.OnStageChanged += OnStageChanged;
    }

    void OnDestroy()
    {
        if (GoldManager.Instance != null)
            GoldManager.Instance.OnGoldChanged -= OnGoldChanged;

        if (GemManager.Instance != null)
            GemManager.Instance.OnGemChanged -= OnGemChanged;

        if (StageManager.Instance != null)
            StageManager.Instance.OnStageChanged -= OnStageChanged;
    }

    void Update()
    {
        if (tutorialComplete || IsTutorialActive) return;
        CheckAndShowTutorial();
    }

    public void CheckAndShowTutorial()
    {
        if (tutorialComplete || IsTutorialActive) return;

        switch (currentStep)
        {
            case 0:
                // Show at game start
                if (BattleManager.Instance != null &&
                    BattleManager.Instance.CurrentState == BattleManager.BattleState.Fighting)
                {
                    ShowTutorial("적이 나타났다! 화면을 탭하여 번개를 내려보세요!");
                }
                break;

            case 1:
                // Triggered by OnStageChanged callback (wave clear)
                break;

            case 2:
                // Triggered by OnGoldChanged callback
                break;

            case 3:
                // Triggered by OnGemChanged callback
                break;

            case 4:
                // Check if skill equipped
                if (SkillManager.Instance != null &&
                    SkillManager.Instance.equippedSkills.Count > 0)
                {
                    ShowTutorial("스킬 버튼으로 강력한 스킬을 사용하세요.");
                }
                break;
        }
    }

    void OnStageChanged(int area, int stage, int wave)
    {
        if (currentStep == 1 && !IsTutorialActive)
        {
            ShowTutorial("웨이브 클리어! 골드를 획득했습니다.");
        }
    }

    void OnGoldChanged(int gold)
    {
        if (currentStep == 2 && gold >= 50 && !IsTutorialActive)
        {
            ShowTutorial("하단의 훈련 탭에서 번개를 강화하세요.");
        }
    }

    void OnGemChanged(int gems)
    {
        if (currentStep == 3 && gems >= 50 && !IsTutorialActive)
        {
            ShowTutorial("소환 탭에서 새로운 영웅을 뽑아보세요!");
        }
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

    /// <summary>
    /// Reset tutorial progress (for debug)
    /// </summary>
    public void ResetTutorial()
    {
        currentStep = 0;
        tutorialComplete = false;
        PlayerPrefs.SetInt("TutorialStep", 0);
        PlayerPrefs.Save();
    }
}
