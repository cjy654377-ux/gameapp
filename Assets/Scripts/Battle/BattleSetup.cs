using UnityEngine;
using System.Collections.Generic;

public class BattleSetup : MonoBehaviour
{
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

        // DeckManager가 없으면 생성 + fallback 프리셋을 로스터로
        if (DeckManager.Instance == null)
        {
            var deckObj = new GameObject("DeckManager");
            var dm = deckObj.AddComponent<DeckManager>();
            dm.roster.AddRange(allyPresets);
            dm.Initialize();
        }

        // 가챠 풀에 아군 프리셋 설정
        if (GachaManager.Instance != null && GachaManager.Instance.HeroPoolCount == 0)
        {
            var allPresets = Resources.LoadAll<CharacterPreset>("Presets");
            if (allPresets == null || allPresets.Length == 0)
            {
                // fallback: allyPresets 사용
                GachaManager.Instance.SetHeroPool(allyPresets.ToArray());
            }
        }

        SpawnAllies();

        if (StageManager.Instance != null)
            StageManager.Instance.StartFirstWave();
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
            float yOffset = (i - (presets.Count - 1) * 0.5f) * unitSpacingY;
            yOffset = Mathf.Clamp(yOffset, -battleZoneH * 0.5f, battleZoneH * 0.5f);
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
        float camH = Camera.main != null ? Camera.main.orthographicSize * 2f : 10f;
        return camH * 0.6f;
    }
}
