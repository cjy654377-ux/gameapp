using UnityEngine;

/// <summary>
/// UI 컬러 팔레트 — 나무/고동색 기반
/// </summary>
public static class UIColors
{
    // Background (어두운 나무색)
    public static readonly Color Background_Main = HexColor("#2B1810");
    public static readonly Color Background_Panel = HexColor("#3D2415");
    public static readonly Color Background_Dark = HexColor("#1E110A");

    // Panel / Border (따뜻한 나무 톤)
    public static readonly Color Panel_Border = HexColor("#A07040");
    public static readonly Color Panel_Inner = HexColor("#4A2C18");
    public static readonly Color Panel_Selected = HexColor("#5A7A2A");

    // Tab (고동색 나무 기반)
    public static readonly Color Tab_Active = HexColor("#5C3520");   // 선택: 눌린 어두운 나무
    public static readonly Color Tab_Inactive = HexColor("#7A4E30"); // 미선택: 밝은 나무색

    // NavBar 배경
    public static readonly Color NavBar_BG = HexColor("#3A2010");    // 하단 바 배경

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
    public static readonly Color Rarity_Epic = HexColor("#E07020");
    public static readonly Color Rarity_Legendary = HexColor("#FFD700");
    public static readonly Color Rarity_Locked = HexColor("#252525");

    // Text (밝은 색 — 어두운 배경에서 잘 보이도록, 기존 호환)
    public static readonly Color Text_Primary = Color.white;
    public static readonly Color Text_Secondary = HexColor("#E8D5B5"); // 밝은 크림색
    public static readonly Color Text_Gold = HexColor("#FFD700");
    public static readonly Color Text_Green = HexColor("#7FD44C");
    public static readonly Color Text_Disabled = HexColor("#999999");
    public static readonly Color Text_TabActive = Color.white;
    public static readonly Color Text_TabInactive = HexColor("#E0C8A0"); // 밝은 베이지
    public static readonly Color Text_Diamond = HexColor("#87CEEB");

    // Text Dark (밝은 나무 패널 위에서 잘 보이는 어두운 색)
    public static readonly Color Text_Dark = HexColor("#2B1810");          // 어두운 나무색
    public static readonly Color Text_DarkSecondary = HexColor("#5A3D28"); // 중간 고동색
    public static readonly Color Text_DarkGold = HexColor("#8B6914");      // 진한 골드
    public static readonly Color Text_DarkGreen = HexColor("#2E7D32");     // 진한 초록
    public static readonly Color Text_DarkDiamond = HexColor("#1565C0");   // 진한 파랑

    // Progress Bar
    public static readonly Color ProgressBar_BG = HexColor("#2A1A0E");
    public static readonly Color ProgressBar_Fill = HexColor("#5DC054");
    public static readonly Color ProgressBar_Border = HexColor("#4A3020");

    // List Items (밝은 톤 — 텍스트 대비 확보)
    public static readonly Color ListItem_Normal = new Color(0.92f, 0.88f, 0.82f);
    public static readonly Color ListItem_Completed = new Color(0.82f, 0.92f, 0.75f);
    public static readonly Color ListItem_Claimed = new Color(0.82f, 0.78f, 0.72f);

    // Defeat
    public static readonly Color Defeat_Red = HexColor("#CC3333");
    public static readonly Color Overlay_Dark = new Color(0, 0, 0, 0.7f);

    static Color HexColor(string hex)
    {
        ColorUtility.TryParseHtmlString(hex, out Color c);
        return c;
    }
}
