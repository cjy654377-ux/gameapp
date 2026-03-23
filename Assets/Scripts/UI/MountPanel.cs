using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections.Generic;

/// <summary>
/// 탈것 패널: 보유 탈것 목록 + 장착/해제 + 뽑기
/// GachaPanel 서브탭으로 Init(parent, showConfirm) 패턴 사용
/// </summary>
public class MountPanel : MonoBehaviour
{
    // ─── UI refs ───────────────────────────────────────
    TextMeshProUGUI stoneText;
    TextMeshProUGUI pullResultText;
    Transform listContent;

    readonly List<MountItemRow> rows = new();
    System.Action<string, string, System.Action> showConfirm;

    MountManager cachedMM;
    SummonStoneManager cachedSM;

    // 레이아웃 상수
    const float ROW_HEIGHT        = 0.11f;
    const float ROW_GAP           = 0.005f;
    const float LIST_TOP          = 0.84f;
    const float LIST_BOTTOM       = 0.20f;

    // ─── Init ──────────────────────────────────────────

    public void Init(Transform parent, System.Action<string, string, System.Action> showConfirmCallback)
    {
        showConfirm = showConfirmCallback;

        var content = UIHelper.MakeUI("MountContent", parent);
        UIHelper.FillParent(content.GetComponent<RectTransform>());

        BuildStoneBar(content.transform);
        BuildPullButton(content.transform);
        BuildResultArea(content.transform);
        BuildMountList(content.transform);

        SubscribeEvents();
        Refresh();
    }

    // ─── Build UI ──────────────────────────────────────

    void BuildStoneBar(Transform parent)
    {
        var bar = UIHelper.MakeSpritePanel("StoneBar", parent,
            UISprites.BoxIcon1, UIColors.Panel_Inner);
        var rt = bar.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0.05f, 0.92f);
        rt.anchorMax = new Vector2(0.95f, 0.99f);
        rt.offsetMin = rt.offsetMax = Vector2.zero;

        var stoneIcon = UIHelper.MakeIcon("StoneIcon", bar.transform, UISprites.SpumIcon(136), Color.white);
        var siRT = stoneIcon.GetComponent<RectTransform>();
        siRT.anchorMin = new Vector2(0.05f, 0.1f);
        siRT.anchorMax = new Vector2(0.22f, 0.9f);
        siRT.offsetMin = siRT.offsetMax = Vector2.zero;

        stoneText = UIHelper.MakeText("StoneInfo", bar.transform, "0",
            UIConstants.Font_StatLabel, TextAlignmentOptions.Center, UIColors.Text_Gold);
        stoneText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(stoneText);
        var stRT = stoneText.GetComponent<RectTransform>();
        stRT.anchorMin = new Vector2(0.22f, 0f);
        stRT.anchorMax = new Vector2(1f, 1f);
        stRT.offsetMin = stRT.offsetMax = Vector2.zero;
    }

    void BuildPullButton(Transform parent)
    {
        var (btn, _) = UIHelper.MakeSpriteButton("PullBtn", parent,
            UISprites.Btn2_WS, UIColors.Button_Green, "", UIConstants.Font_Button);
        btn.onClick.AddListener(OnPull);
        var rt = btn.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0.05f, 0.84f);
        rt.anchorMax = new Vector2(0.95f, 0.92f);
        rt.offsetMin = rt.offsetMax = Vector2.zero;

        var label = UIHelper.MakeText("Label", btn.transform,
            $"탈것 소환  (소환석 {MountManager.PULL_COST}개)",
            UIConstants.Font_Button, TextAlignmentOptions.Center, Color.white);
        label.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(label);
        UIHelper.FillParent(label.GetComponent<RectTransform>());
    }

    void BuildResultArea(Transform parent)
    {
        var bg = UIHelper.MakeSpritePanel("ResultBG", parent,
            UISprites.BoxBasic3, new Color(0.20f, 0.15f, 0.08f, 0.7f));
        var rt = bg.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0.05f, 0.76f);
        rt.anchorMax = new Vector2(0.95f, 0.84f);
        rt.offsetMin = rt.offsetMax = Vector2.zero;

        pullResultText = UIHelper.MakeText("Result", bg.transform, "",
            9f, TextAlignmentOptions.Center, Color.white);
        UIHelper.FillParent(pullResultText.GetComponent<RectTransform>());
    }

    void BuildMountList(Transform parent)
    {
        var bg = UIHelper.MakeSpritePanel("ListBG", parent,
            UISprites.BoxBasic3, new Color(0.15f, 0.10f, 0.05f, 0.6f));
        var bgrt = bg.GetComponent<RectTransform>();
        bgrt.anchorMin = new Vector2(0.02f, 0.01f);
        bgrt.anchorMax = new Vector2(0.98f, 0.75f);
        bgrt.offsetMin = bgrt.offsetMax = Vector2.zero;

        listContent = bg.transform;
    }

    // ─── Data Binding ──────────────────────────────────

    public void Refresh()
    {
        RefreshStoneText();
        RefreshList();
    }

    void RefreshStoneText()
    {
        if (stoneText == null) return;
        int stones = SummonStoneManager.Instance != null ? SummonStoneManager.Instance.Stone : 0;
        stoneText.text = $"{stones}";
    }

    void RefreshList()
    {
        if (listContent == null) return;

        // 기존 행 제거
        foreach (var r in rows) if (r != null) Destroy(r.gameObject);
        rows.Clear();

        var mm = MountManager.Instance;
        if (mm == null) return;

        // 성급 내림차순 정렬 (5성 → 1성)
        var sorted = new System.Collections.Generic.List<string>(mm.OwnedMountNames);
        sorted.Sort((a, b) =>
        {
            var da = mm.GetMountData(a);
            var db = mm.GetMountData(b);
            int sa = da != null ? (int)da.starGrade : 0;
            int sb2 = db != null ? (int)db.starGrade : 0;
            return sb2.CompareTo(sa);
        });

        if (sorted.Count == 0)
        {
            var empty = UIHelper.MakeText("Empty", listContent, "보유한 탈것이 없습니다.\n소환 버튼으로 획득하세요!",
                UIConstants.Font_StatLabel, TextAlignmentOptions.Center, UIColors.Text_Secondary);
            var ert = empty.GetComponent<RectTransform>();
            ert.anchorMin = new Vector2(0.05f, 0.3f);
            ert.anchorMax = new Vector2(0.95f, 0.7f);
            ert.offsetMin = ert.offsetMax = Vector2.zero;
            return;
        }

        int maxVisible = Mathf.FloorToInt((LIST_TOP - LIST_BOTTOM) / (ROW_HEIGHT + ROW_GAP));
        int count = Mathf.Min(sorted.Count, maxVisible);

        for (int i = 0; i < count; i++)
        {
            string name = sorted[i];
            bool equipped = name == mm.EquippedMountName;

            float yMax = 1f - (ROW_GAP + (ROW_HEIGHT + ROW_GAP) * i);
            float yMin = yMax - ROW_HEIGHT;

            var row = UIHelper.MakeUI($"MountRow_{i}", listContent);
            var rowRT = row.GetComponent<RectTransform>();
            rowRT.anchorMin = new Vector2(0.02f, yMin);
            rowRT.anchorMax = new Vector2(0.98f, yMax);
            rowRT.offsetMin = rowRT.offsetMax = Vector2.zero;

            var rowBg = UIHelper.MakeSpritePanel("RowBG", row.transform, UISprites.BoxBasic1,
                equipped ? UIColors.Button_Yellow : UIColors.Panel_Inner);
            UIHelper.FillParent(rowBg.GetComponent<RectTransform>());

            var item = row.AddComponent<MountItemRow>();
            item.Init(name, equipped, showConfirm, this);
            rows.Add(item);
        }
    }

    // ─── Gacha ─────────────────────────────────────────

    void OnPull()
    {
        var sm = SummonStoneManager.Instance;
        if (sm == null || sm.Stone < MountManager.PULL_COST)
        {
            ToastNotification.Instance?.Show("소환석 부족!",
                $"소환석 {MountManager.PULL_COST}개 필요", UIColors.Defeat_Red);
            return;
        }
        DoPull();
    }

    void DoPull()
    {
        if (MountManager.Instance == null) return;
        bool ok = MountManager.Instance.PullMount();
        if (pullResultText != null)
            pullResultText.text = ok ? "탈것 소환 성공!" : "<color=#CC3333>소환 실패</color>";
    }

    // ─── Events ────────────────────────────────────────

    void SubscribeEvents()
    {
        cachedMM = MountManager.Instance;
        if (cachedMM == null) return;
        cachedMM.OnMountPulled   += OnMountPulled;
        cachedMM.OnMountEquipped += OnMountEquipped;

        cachedSM = SummonStoneManager.Instance;
        if (cachedSM != null) cachedSM.OnStoneChanged += OnStoneChanged;
    }

    void UnsubscribeEvents()
    {
        if (cachedMM != null)
        {
            cachedMM.OnMountPulled   -= OnMountPulled;
            cachedMM.OnMountEquipped -= OnMountEquipped;
        }
        if (cachedSM != null) cachedSM.OnStoneChanged -= OnStoneChanged;
    }

    void OnMountPulled(MountData data)
    {
        if (data != null && pullResultText != null)
            pullResultText.text = $"<color=#FFD700>{data.mountName}</color> 획득!";
        Refresh();
    }

    void OnMountEquipped(MountData data)  => Refresh();
    void OnStoneChanged(int v)            => RefreshStoneText();

    void OnDestroy() => UnsubscribeEvents();
}

// ─── Row Component ───────────────────────────────────────────────────────────

/// <summary>탈것 목록 한 행: 이름 + 성급 + 보너스 + 장착 버튼</summary>
public class MountItemRow : MonoBehaviour
{
    public void Init(string mountName, bool equipped,
        System.Action<string, string, System.Action> showConfirm,
        MountPanel owner)
    {
        // 이름 텍스트
        var mountData = MountManager.Instance?.GetMountData(mountName);
        Color rarityColor = GetRarityColor(mountData?.starGrade ?? StarGrade.Star1);
        string starStr = mountData != null ? new string('\u2605', (int)mountData.starGrade) : "";
        string displayName = $"<color=#{UnityEngine.ColorUtility.ToHtmlStringRGB(rarityColor)}>{starStr}</color> {mountName}";
        var nameText = UIHelper.MakeText("Name", transform, displayName,
            UIConstants.Font_StatLabel, TextAlignmentOptions.Left,
            equipped ? UIColors.Text_Gold : Color.white);
        nameText.fontStyle = FontStyles.Bold;
        UIHelper.AddTextShadow(nameText);
        var nrt = nameText.GetComponent<RectTransform>();
        nrt.anchorMin = new Vector2(0.02f, 0.5f);
        nrt.anchorMax = new Vector2(0.55f, 1.0f);
        nrt.offsetMin = nrt.offsetMax = Vector2.zero;

        // 보너스 텍스트
        string bonusStr = GetBonusText(mountName);
        var bonusText = UIHelper.MakeText("Bonus", transform, bonusStr,
            8f, TextAlignmentOptions.Left, UIColors.Text_Secondary);
        var brt = bonusText.GetComponent<RectTransform>();
        brt.anchorMin = new Vector2(0.02f, 0.0f);
        brt.anchorMax = new Vector2(0.55f, 0.5f);
        brt.offsetMin = brt.offsetMax = Vector2.zero;

        // 장착/해제 버튼
        string btnLabel = equipped ? "해제" : "장착";
        Color btnColor  = equipped ? UIColors.Defeat_Red : UIColors.Button_Green;
        var (btn, _) = UIHelper.MakeSpriteButton("EquipBtn", transform,
            UISprites.Btn2_WS, btnColor, "", 8f);
        var btnRT = btn.GetComponent<RectTransform>();
        btnRT.anchorMin = new Vector2(0.62f, 0.1f);
        btnRT.anchorMax = new Vector2(0.98f, 0.9f);
        btnRT.offsetMin = btnRT.offsetMax = Vector2.zero;

        var btnText = UIHelper.MakeText("Label", btn.transform, btnLabel,
            8f, TextAlignmentOptions.Center, Color.white);
        btnText.fontStyle = FontStyles.Bold;
        UIHelper.FillParent(btnText.GetComponent<RectTransform>());

        string capturedName = mountName;
        bool capturedEquipped = equipped;
        btn.onClick.AddListener(() =>
        {
            if (capturedEquipped)
            {
                MountManager.Instance?.UnequipMount();
                owner?.Refresh();
            }
            else
            {
                MountManager.Instance?.EquipMount(capturedName);
                owner?.Refresh();
            }
        });
    }

    static string GetBonusText(string mountName)
    {
        var mm = MountManager.Instance;
        if (mm == null) return "";

        // allMounts에서 해당 mount 찾기
        // MountManager의 private 필드에 접근 불가하므로, EquipMount 후 GetMountBonus 활용
        // 대신 임시로 장착 후 확인하는 방식 대신 직접 allMounts를 참조
        // → 간단하게 MountManager에 GetMountDataPublic 추가 없이 처리
        // 현재 장착 탈것이면 Bonus 읽기, 아니면 빈 문자열
        if (mountName == mm.EquippedMountName)
        {
            mm.GetMountBonus(out float sp, out float hp, out float atk);
            return BuildBonusStr(sp, hp, atk);
        }
        return ""; // 미장착 탈것은 상세 보너스 표시 생략
    }

    static string BuildBonusStr(float sp, float hp, float atk)
    {
        var sb = new System.Text.StringBuilder();
        if (sp  > 0) sb.Append($"SPD+{sp}%  ");
        if (hp  > 0) sb.Append($"HP+{hp}%  ");
        if (atk > 0) sb.Append($"ATK+{atk}%");
        return sb.ToString().Trim();
    }

    static Color GetRarityColor(StarGrade grade) => grade switch
    {
        StarGrade.Star5 => UIColors.Rarity_Legendary,
        StarGrade.Star4 => UIColors.Rarity_Epic,
        StarGrade.Star3 => UIColors.Rarity_Rare,
        StarGrade.Star2 => UIColors.Rarity_Uncommon,
        _               => UIColors.Rarity_Common,
    };

    void OnDestroy()
    {
        // 모든 버튼은 동적 생성되며, 부모 GameObject 파괴 시 함께 정리됨
    }
}
