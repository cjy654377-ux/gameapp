/// <summary>
/// 보상형 광고 종류 — 광고 포인트별 쿨타임/일일 횟수 분리 관리
/// </summary>
public enum AdRewardType
{
    GoldBoost,      // 골드 2배 (일정 시간)
    FreeSummon,     // 무료 소환 1회
    DungeonEntry,   // 던전 추가 입장권
    Revive,         // 전투 부활
    SkillReset,     // 스킬 쿨타임 초기화
    DailyDouble,    // 일일 보상 2배
    EquipDouble,    // 장비 드롭 2배 (일정 시간)
    FreeGem,        // 무료 보석
    EnhanceRetry,   // 강화 재시도 (비용 없이)
}
