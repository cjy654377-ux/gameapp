using UnityEngine;
using System.Collections.Generic;

public class BattleSetup : MonoBehaviour
{
    const float CAM_HEIGHT_MULT = 2f;
    const float BATTLE_ZONE_HEIGHT_RATIO = 0.6f;
    const float UNIT_POSITION_CENTER = 0.5f;
    const float UNIT_CLAMP_RATIO = 0.5f;
    const float DEFAULT_CAM_HEIGHT = 10f;

    [Header("Fallback Ally Presets (DeckManager 없을 때)")]
    public List<CharacterPreset> allyPresets = new();

    [Header("Spawn Settings")]
    public float allyStartX = -1f;
    public float unitSpacingY = 1.0f;

    void Start()
    {
        EnsureSystem<ScreenFader>("ScreenFader");
        EnsureSystem<TapDamageSystem>("TapDamageSystem");
        EnsureSystem<GemManager>("GemManager");
        EnsureSystem<OfflineRewardManager>("OfflineRewardManager");
        EnsureSystem<StageRewardSystem>("StageRewardSystem");
        EnsureSystem<HeroLevelManager>("HeroLevelManager");
        EnsureSystem<GachaManager>("GachaManager");
        EnsureSystem<EquipmentManager>("EquipmentManager");
        EnsureSystem<EffectManager>("EffectManager");
        EnsureSystem<SoundManager>("SoundManager");
        EnsureSystem<ShopManager>("ShopManager");
        EnsureSystem<AchievementManager>("AchievementManager");
        EnsureSystem<TutorialManager>("TutorialManager");
        EnsureSystem<ObjectPool>("ObjectPool");
        EnsureSystem<ToastNotification>("ToastNotification");

        // 프리셋 자동 로드 (Inspector 할당이 깨진 경우)
        AutoLoadAllyPresets();

        // DeckManager가 없으면 생성 + fallback 프리셋을 로스터로
        if (DeckManager.Instance == null)
        {
            var deckObj = new GameObject("DeckManager");
            var dm = deckObj.AddComponent<DeckManager>();
            dm.roster.AddRange(allyPresets);
            dm.Initialize();
        }
        else if (DeckManager.Instance.roster.Count == 0 || DeckManager.Instance.roster.TrueForAll(p => p == null))
        {
            DeckManager.Instance.roster.Clear();
            DeckManager.Instance.roster.AddRange(allyPresets);
            DeckManager.Instance.Initialize();
        }

        // 가챠 풀에 아군 프리셋 설정
        if (GachaManager.Instance != null && (GachaManager.Instance.HeroPoolCount == 0 || !HasValidHeroes()))
        {
            GachaManager.Instance.SetHeroPool(allyPresets.ToArray());
        }

        // 이전 세션 잔해 제거
        foreach (var gd in FindObjectsByType<GoldDrop>(FindObjectsSortMode.None))
            if (gd != null) Destroy(gd.gameObject);

        SpawnAllies();

        if (StageManager.Instance != null)
            StageManager.Instance.StartFirstWave();
    }

    void AutoLoadAllyPresets()
    {
        // allyPresets에 유효한 프리셋이 없으면 자동 로드
        bool hasValid = false;
        for (int i = 0; i < allyPresets.Count; i++)
            if (allyPresets[i] != null) { hasValid = true; break; }

        if (!hasValid)
        {
            allyPresets.Clear();
            #if UNITY_EDITOR
            var guids = UnityEditor.AssetDatabase.FindAssets("t:CharacterPreset", new[] { "Assets/Data/Presets" });
            foreach (var guid in guids)
            {
                string path = UnityEditor.AssetDatabase.GUIDToAssetPath(guid);
                var p = UnityEditor.AssetDatabase.LoadAssetAtPath<CharacterPreset>(path);
                if (p != null && !p.isEnemy)
                    allyPresets.Add(p);
            }
            #else
            var all = Resources.LoadAll<CharacterPreset>("Presets");
            foreach (var p in all)
                if (p != null && !p.isEnemy) allyPresets.Add(p);
            #endif
            Debug.Log($"[BattleSetup] AutoLoad allies: {allyPresets.Count}");
        }
    }

    bool HasValidHeroes()
    {
        // GachaManager의 히어로 풀에 유효한 프리셋이 있는지
        return GachaManager.Instance != null && GachaManager.Instance.HeroPoolCount > 0;
    }

    void EnsureSystem<T>(string name) where T : MonoBehaviour
    {
        if (FindFirstObjectByType<T>() == null)
        {
            var obj = new GameObject(name);
            obj.AddComponent<T>();
        }
    }

    void SpawnAllies()
    {
        var factory = CharacterFactory.Instance;
        if (factory == null) return;

        var manager = BattleManager.Instance;
        if (manager == null) return;

        List<CharacterPreset> presets;
        if (DeckManager.Instance != null)
            presets = DeckManager.Instance.GetActiveDeck();
        else
            presets = allyPresets;

        if (presets.Count == 0) return;

        float battleZoneH = GetBattleZoneHeight();

        for (int i = 0; i < presets.Count; i++)
        {
            float yOffset = (i - (presets.Count - 1) * UNIT_POSITION_CENTER) * unitSpacingY;
            yOffset = Mathf.Clamp(yOffset, -battleZoneH * UNIT_CLAMP_RATIO, battleZoneH * UNIT_CLAMP_RATIO);
            Vector3 pos = new Vector3(allyStartX, yOffset, 0);
            var unit = factory.CreateCharacter(presets[i], pos, BattleUnit.Team.Ally);

            // 통합 스탯 보너스 적용
            UpgradeManager.ApplyAllBonuses(unit);

            manager.allyUnits.Add(unit);
        }

        manager.StartBattle();
    }

    float GetBattleZoneHeight()
    {
        float camH = Camera.main != null ? Camera.main.orthographicSize * CAM_HEIGHT_MULT : DEFAULT_CAM_HEIGHT;
        return camH * BATTLE_ZONE_HEIGHT_RATIO;
    }
}
