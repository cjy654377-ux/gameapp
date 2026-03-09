using UnityEngine;

/// <summary>
/// UI_SPEC.md 컬러 팔레트 중앙 관리
/// </summary>
public static class UIColors
{
    // Background
    public static readonly Color Background_Main = HexColor("#1E0F06");
    public static readonly Color Background_Panel = HexColor("#2D1A0A");
    public static readonly Color Background_Dark = HexColor("#150B03");

    // Panel / Border
    public static readonly Color Panel_Border = HexColor("#8B6327");
    public static readonly Color Panel_Inner = HexColor("#3A2010");
    public static readonly Color Panel_Selected = HexColor("#4A6B1A");
    public static readonly Color Tab_Active = HexColor("#C8A86B");
    public static readonly Color Tab_Inactive = HexColor("#2D1A0A");

    // Button
    public static readonly Color Button_Green = HexColor("#4CAF50");
    public static readonly Color Button_Green_Top = HexColor("#5DC054");
    public static readonly Color Button_Green_Bottom = HexColor("#3A8C3E");
    public static readonly Color Button_Green_Border = HexColor("#2E7D32");
    public static readonly Color Button_Yellow = HexColor("#F5C518");
    public static readonly Color Button_Yellow_Top = HexColor("#FFD740");
    public static readonly Color Button_Yellow_Bottom = HexColor("#E6AC00");
    public static readonly Color Button_Yellow_Border = HexColor("#B8860B");
    public static readonly Color Button_Gray = HexColor("#6B6B6B");
    public static readonly Color Button_Brown = HexColor("#7B5230");
    public static readonly Color Button_Brown_Top = HexColor("#8B6340");
    public static readonly Color Button_Brown_Bottom = HexColor("#5C3A20");
    public static readonly Color Button_Brown_Border = HexColor("#A07845");

    // Rarity
    public static readonly Color Rarity_Common = HexColor("#607080");
    public static readonly Color Rarity_Uncommon = HexColor("#3A7A3A");
    public static readonly Color Rarity_Rare = HexColor("#6B3FA0");
    public static readonly Color Rarity_Locked = HexColor("#252525");

    // Text
    public static readonly Color Text_Primary = Color.white;
    public static readonly Color Text_Secondary = HexColor("#D4C09A");
    public static readonly Color Text_Gold = HexColor("#FFD700");
    public static readonly Color Text_Green = HexColor("#7FD44C");
    public static readonly Color Text_Disabled = HexColor("#888888");
    public static readonly Color Text_TabActive = HexColor("#3D1F00");
    public static readonly Color Text_Diamond = HexColor("#87CEEB");

    // Progress Bar
    public static readonly Color ProgressBar_BG = HexColor("#1A1A1A");
    public static readonly Color ProgressBar_Fill = HexColor("#5DC054");
    public static readonly Color ProgressBar_Border = HexColor("#2E2E2E");

    // Defeat
    public static readonly Color Defeat_Red = HexColor("#CC3333");
    public static readonly Color Overlay_Dark = new Color(0, 0, 0, 0.7f);

    static Color HexColor(string hex)
    {
        ColorUtility.TryParseHtmlString(hex, out Color c);
        return c;
    }
}
