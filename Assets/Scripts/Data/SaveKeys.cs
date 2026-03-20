/// <summary>
/// PlayerPrefs 키 이름 상수. 매직 스트링 제거용.
/// </summary>
public static class SaveKeys
{
    // 경제
    public const string Gold            = "Gold";
    public const string Gem             = "Gem";

    // 스테이지
    public const string TotalWaveIndex  = "TotalWaveIndex";

    // 글로벌 업그레이드
    public const string UpgradeHp       = "UpgradeHp";
    public const string UpgradeAtk      = "UpgradeAtk";
    public const string UpgradeDef      = "UpgradeDef";
    public const string TapDamageLevel  = "TapDamageLevel";

    // 사운드
    public const string BgmVolume       = "BGMVolume";
    public const string SfxVolume       = "SFXVolume";

    // 오프라인 보상
    public const string LastPlayTime    = "LastPlayTime";

    // 장비/스킬
    public const string EquipmentInventory  = "Equipment_Inventory";
    public const string EquippedSkills      = "EquippedSkills";

    // 도감
    public const string CollectionHeroes   = "Collection_Heroes";
    public const string CollectionMonsters = "Collection_Monsters";
    public const string CollectionEquips   = "Collection_Equips";

    // 스테이지 보상
    public const string ClearedStages = "ClearedStages";

    // 업적
    public const string AchievementKillCount = "AchievementKillCount";

    // 일일 미션
    public const string DailyMissionDate = "DailyMission_Date";

    // 아레나
    public const string ArenaPoints    = "ArenaPoints";
    public const string ArenaWinStreak = "ArenaWinStreak";
    public const string ArenaAttempts  = "ArenaAttempts";
    public const string ArenaLastReset = "ArenaLastReset";

    // 튜토리얼
    public const string TutorialStep = "TutorialStep";

    // 프리픽스 키 (동적 접미사)
    public const string SkillLevelPrefix      = "SkillLv_";
    public const string HeroLevelPrefix       = "HeroLevel_";
    public const string HeroCopiesPrefix      = "HeroCopies_";
    public const string HeroStarPrefix        = "HeroStar_";
    public const string DeckSlotPrefix        = "Deck_";
    public const string AchievementPrefix     = "Ach_";
    public const string AchievementClaimedPrefix = "AchClaimed_";
    public const string DailyMissionCurPrefix     = "DM_";
    public const string DailyMissionClaimedPrefix = "DM_claimed_";
}
