using UnityEngine;

/// <summary>
/// UI_SPEC.md 크기/간격 상수 중앙 관리
/// 기준 해상도: 390 x 844 (iPhone), Match 0.5
/// </summary>
public static class UIConstants
{
    // Reference Resolution
    public static readonly Vector2 ReferenceResolution = new Vector2(390, 844);
    public const float MatchWidthOrHeight = 0.5f;

    // HUD Bar
    public const float HUD_Height = 46f;
    public const float HUD_AvatarSize = 36f;
    public const float HUD_AvatarBorder = 2f;
    public const float HUD_IconSize = 16f;
    public const float HUD_ProgressHeight = 5f;

    // Bottom Nav Bar
    public const float NavBar_Height = 58f;
    public const float NavBar_IconSize = 20f;
    public const float NavBar_BorderTop = 1f;

    // Tab Bar
    public const float Tab_Height = 32f;
    public const float SubTab_Height = 30f;

    // Panel
    public const float Panel_BorderWidth = 2f;
    public const float Panel_CornerRadius = 8f;
    public const float Panel_Padding = 12f;
    public const float Panel_ContentPadding = 16f;

    // Button
    public const float Button_MinWidth = 100f;
    public const float Button_MinHeight = 44f;
    public const float Button_CTAWidth = 160f;
    public const float Button_CTAHeight = 50f;
    public const float Button_CornerRadius = 8f;
    public const float Button_PressedScale = 0.95f;

    // Stat Upgrade Row
    public const float StatRow_Height = 56f;
    public const float StatRow_IconSize = 40f;
    public const float StatRow_Padding = 6f;

    // Item Grid
    public const float Grid_Padding = 32f;
    public const int Grid_Columns = 4;
    public const float Grid_CellBorder = 1.5f;

    // Summon Card
    public const float Summon_Height = 160f;
    public const float Summon_IconSize = 100f;
    public const float Summon_ProgressHeight = 12f;
    public const float Summon_ButtonHeight = 44f;

    // Font Sizes
    public const float Font_HeaderLarge = 18f;
    public const float Font_HeaderMedium = 15f;
    public const float Font_StatValue = 16f;
    public const float Font_StatLabel = 12f;
    public const float Font_Button = 14f;
    public const float Font_Tab = 12f;
    public const float Font_LevelBadge = 9f;
    public const float Font_Cost = 11f;
    public const float Font_SmallInfo = 9f;
    public const float Font_NavLabel = 9f;
    public const float Font_HUDResource = 12f;

    // Spacing
    public const float Spacing_Small = 4f;
    public const float Spacing_Medium = 8f;
    public const float Spacing_Large = 12f;
    public const float Spacing_XLarge = 16f;

    // Touch Target
    public const float MinTouchTarget = 44f;
}
