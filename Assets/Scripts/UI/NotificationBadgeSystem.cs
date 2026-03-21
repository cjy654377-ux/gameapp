using UnityEngine;

/// <summary>
/// 알림 뱃지 조건 계산 싱글톤.
/// 각 탭 / 서브탭 / 햄버거 메뉴의 뱃지 표시 여부를 중앙에서 관리.
/// MainHUD.UpdateBadges(), EnhancePanel, GachaPanel 에서 호출.
/// </summary>
public class NotificationBadgeSystem : MonoBehaviour
{
    public static NotificationBadgeSystem Instance { get; private set; }

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }
    }

    // ════════════════════════════════════════
    // 하단 탭 배지
    // ════════════════════════════════════════

    /// <summary>영웅 탭 (index 0): 레벨업 or 각성 가능한 영웅 수</summary>
    public int GetHeroBadgeCount()
    {
        var dm  = DeckManager.Instance;
        var hlm = HeroLevelManager.Instance;
        if (dm == null || hlm == null) return 0;

        int count = 0;
        for (int i = 0; i < dm.roster.Count; i++)
        {
            var p = dm.roster[i];
            if (p == null || p.isEnemy) continue;
            string name = p.characterName;
            int lv = hlm.GetLevel(name);
            bool canLevel = lv < HeroLevelManager.MAX_LEVEL &&
                            hlm.GetCopies(name) >= hlm.GetCopiesNeeded(lv);
            if (canLevel || hlm.CanAwaken(name)) count++;
        }
        return count;
    }

    /// <summary>소환 탭 (index 1): 무료 소환 가능 or 보석 >= 50</summary>
    public int GetGachaBadgeCount()
    {
        bool freeAvail = AdManager.Instance != null &&
                         AdManager.Instance.IsAdAvailable(AdManager.AdRewardType.FreeSummonHero);
        bool hasGems   = GemManager.Instance != null &&
                         GemManager.Instance.Gem >= GachaManager.SINGLE_PULL_COST;
        return (freeAvail || hasGems) ? 1 : 0;
    }

    /// <summary>던전 탭 (index 3): 입장 가능한 던전 있을 때</summary>
    public int GetDungeonBadgeCount()
    {
        var dm = DungeonManager.Instance;
        if (dm == null) return 0;
        return (dm.CanEnter(DungeonType.Hero)  ||
                dm.CanEnter(DungeonType.Mount) ||
                dm.CanEnter(DungeonType.Skill)) ? 1 : 0;
    }

    /// <summary>상점 탭 (index 4): 무료 보석 광고 가능 시</summary>
    public int GetShopBadgeCount()
    {
        return (AdManager.Instance != null &&
                AdManager.Instance.IsAdAvailable(AdManager.AdRewardType.FreeGem)) ? 1 : 0;
    }

    /// <summary>햄버거: 미수령 업적 + 미션 수</summary>
    public int GetHamburgerBadgeCount()
    {
        int count = 0;

        var am = AchievementManager.Instance;
        if (am != null)
        {
            var achs = am.GetAchievements();
            for (int i = 0; i < achs.Count; i++)
                if (achs[i].completed && !achs[i].claimed) count++;
        }

        var mm = DailyMissionManager.Instance;
        if (mm != null)
        {
            var missions = mm.GetMissions();
            for (int i = 0; i < missions.Count; i++)
                if (missions[i].currentCount >= missions[i].targetCount && !missions[i].claimed)
                    count++;
        }
        return count;
    }

    // ════════════════════════════════════════
    // 서브탭 배지 — EnhancePanel (영웅 탭 내부)
    // ════════════════════════════════════════
    // subtabIdx: 0=편성, 1=레벨업, 2=장비, 3=각성

    public bool GetHeroSubTabBadge(int subtabIdx)
    {
        var dm  = DeckManager.Instance;
        var hlm = HeroLevelManager.Instance;
        if (dm == null || hlm == null) return false;

        switch (subtabIdx)
        {
            case 1: // 레벨업
                for (int i = 0; i < dm.roster.Count; i++)
                {
                    var p = dm.roster[i];
                    if (p == null || p.isEnemy) continue;
                    string name = p.characterName;
                    int lv = hlm.GetLevel(name);
                    if (lv < HeroLevelManager.MAX_LEVEL &&
                        hlm.GetCopies(name) >= hlm.GetCopiesNeeded(lv))
                        return true;
                }
                return false;

            case 2: // 장비 — 장착 안 된 장비 있을 때
                var em = EquipmentManager.Instance;
                if (em == null) return false;
                var inv = em.Inventory;
                for (int i = 0; i < inv.Count; i++)
                    if (string.IsNullOrEmpty(inv[i].equippedTo)) return true;
                return false;

            case 3: // 각성
                for (int i = 0; i < dm.roster.Count; i++)
                {
                    var p = dm.roster[i];
                    if (p == null || p.isEnemy) continue;
                    if (hlm.CanAwaken(p.characterName)) return true;
                }
                return false;

            default: return false;
        }
    }

    // ════════════════════════════════════════
    // 서브탭 배지 — GachaPanel (소환 탭 내부)
    // ════════════════════════════════════════
    // subtabIdx: 0=영웅소환, 1=탈것, 2=스킬

    public bool GetGachaSubTabBadge(int subtabIdx)
    {
        switch (subtabIdx)
        {
            case 0: // 영웅소환 - 무료 가능 or 보석 >= 비용
                bool freeHero = AdManager.Instance != null &&
                                AdManager.Instance.IsAdAvailable(AdManager.AdRewardType.FreeSummonHero);
                bool hasGems  = GemManager.Instance != null &&
                                GemManager.Instance.Gem >= GachaManager.SINGLE_PULL_COST;
                return freeHero || hasGems;

            case 1: // 탈것 - 소환석 보유
                return SummonStoneManager.Instance != null &&
                       SummonStoneManager.Instance.Stone > 0;

            case 2: // 스킬 - 주문서 보유
                return SpellScrollManager.Instance != null &&
                       SpellScrollManager.Instance.Scroll > 0;

            default: return false;
        }
    }
}
