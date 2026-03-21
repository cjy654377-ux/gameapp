/// <summary>
/// PlayerPrefs 키 이름 상수. 매직 스트링 제거용.
/// </summary>
public static class SaveKeys
{
    // 경제
    public const string Gold              = "Gold";
    public const string Gem               = "Gem";
    public const string GoldBoostEndTime  = "Gold_BoostEndTime";

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
    public const string ArenaRankRewardPrefix = "ArenaRankReward_";

    // 튜토리얼
    public const string TutorialStep = "TutorialStep";

    // 재화 (소환석/주문서)
    public const string SummonStone = "SummonStone";
    public const string SpellScroll = "SpellScroll";

    // 던전 입장 횟수 (일일 초기화)
    public const string DungeonHeroEntries  = "Dungeon_HeroEntries";
    public const string DungeonMountEntries = "Dungeon_MountEntries";
    public const string DungeonSkillEntries = "Dungeon_SkillEntries";
    public const string DungeonLastResetDate = "Dungeon_LastResetDate";

    // 광고 추가 입장 횟수 (일일 초기화, 최대 3회)
    public const string DungeonAdBonusCount = "Dungeon_AdBonusCount";
    public const string DungeonAdBonusDate  = "Dungeon_AdBonusDate";

    // 던전 최고 층수 (타입별)
    public const string DungeonBestFloorHero  = "dung_best_Hero";
    public const string DungeonBestFloorMount = "dung_best_Mount";
    public const string DungeonBestFloorSkill = "dung_best_Skill";

    // 탈것
    public const string MountOwned    = "Mount_Owned";
    public const string MountEquipped = "Mount_Equipped";

    // 프리픽스 키 (동적 접미사)
    public const string SkillLevelPrefix      = "SkillLv_";
    public const string HeroLevelPrefix       = "HeroLevel_";
    public const string HeroCopiesPrefix      = "HeroCopies_";
    public const string HeroStarPrefix        = "HeroStar_";
    public const string HeroAwakeningPrefix   = "HeroAwaken_";
    public const string DeckSlotPrefix        = "Deck_";
    public const string AchievementPrefix     = "Ach_";
    public const string AchievementClaimedPrefix = "AchClaimed_";
    public const string DailyMissionCurPrefix     = "DM_";
    public const string DailyMissionClaimedPrefix = "DM_claimed_";

    // 광고
    public const string AdCooldownPrefix  = "Ad_CD_";   // + AdRewardType 이름
    public const string AdDailyCountPrefix = "Ad_Day_"; // + AdRewardType 이름
    public const string AdDailyResetDate  = "Ad_DailyReset";

    // 무료 소환 (광고) - 4시간 쿨타임
    public const string FreeGachaLastTime = "FreeGacha_LastTime";

    // 천장 (pity)
    public const string PityCounter = "Gacha_PityCounter";

    // 첫 뽑기 보장
    public const string FirstPullDone      = "Gacha_FirstPullDone";
    public const string FirstMultiPullDone = "Gacha_FirstMultiPullDone";

    // 명성 (아레나 전용 통화)
    public const string Reputation = "Reputation";

    // 각성석 (던전 고단계 보상, 영웅 각성 재료)
    public const string AwakeningStone = "AwakeningStone";

    // 일일 퀘스트
    public const string DailyQuestDate          = "DQ_Date";
    public const string DailyQuestCurPrefix     = "DQ_Cur_";
    public const string DailyQuestClaimedPrefix = "DQ_Claimed_";

    // 주간 보스
    public const string WeeklyBossWeek     = "WB_Week";
    public const string WeeklyBossAttempt  = "WB_Attempt";
    public const string WeeklyBossDefeated = "WB_Defeated";

    // 친구 시스템
    public const string FriendGiftDate          = "Friend_GiftDate";
    public const string FriendReinforcementDate = "Friend_ReinfDate";

    // 통계
    public const string StatsTotalKills       = "Stats_TotalKills";
    public const string StatsTotalGoldEarned  = "Stats_TotalGoldEarned";
    public const string StatsHighestWave      = "Stats_HighestWave";
    public const string StatsTotalPlayTime    = "Stats_TotalPlayTime";
    public const string StatsTotalPulls       = "Stats_TotalPulls";
}
