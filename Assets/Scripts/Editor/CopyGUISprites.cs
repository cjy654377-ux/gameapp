#if UNITY_EDITOR
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

/// <summary>
/// SPUM Retro GUI Pack 스프라이트를 Assets/Resources/UI/ 에 복사하는 에디터 툴.
/// Game 메뉴 > Copy GUI Sprites 로 실행.
/// </summary>
public static class CopyGUISprites
{
    // ── 복사할 스프라이트 목록 (소스 경로, 대상 파일명) ──────────
    static readonly (string srcDir, string file)[] CoreSprites =
    {
        // Gauge / Bar
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/00_Basic", "HP_Gauge1.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/00_Basic", "HP_Gauge2.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/00_Basic", "Boss_HP_Gauge1.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/00_Basic", "Boss_HP_Gauge2.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/00_Basic", "EXP_Gauge1.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/00_Basic", "EXP_Gauge2.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/00_Basic", "MP_Gauge1.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/00_Basic", "MP_Gauge2.png"),

        // Board / Panel
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/00_Basic", "Board_20x20.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/00_Basic", "Image_Boss.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/00_Basic", "Image_Select1.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/00_Basic", "Image_Select2.png"),

        // Box & Button
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/01_Box&Btn", "Box_Basic1.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/01_Box&Btn", "Box_Basic2.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/01_Box&Btn", "Box_Basic3.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/01_Box&Btn", "Box_Banner.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/01_Box&Btn", "Box_Icon1.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/01_Box&Btn", "Box_Icon2.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/01_Box&Btn", "Box_Profile.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/01_Box&Btn", "Button_Basic1_15x15.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/01_Box&Btn", "Button_Basic2_15x15.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/01_Box&Btn", "Button_Basic3_15x15.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/01_Box&Btn", "Button_Basic4_15x15.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/01_Box&Btn", "Button_Basic1_WS.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/01_Box&Btn", "Button_Basic2_WS.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/01_Box&Btn", "Button_Basic3_WS.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/01_Box&Btn", "Button_Basic4_WS.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/01_Box&Btn", "Button_Icon1.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/01_Box&Btn", "Button_Icon2.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/01_Box&Btn", "Button_X.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/01_Box&Btn", "Button_X_WS.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/01_Box&Btn", "Image_Auto.png"),

        // Icons (Basic)
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/02_Icons/1_Basic", "Icon_Gold.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/02_Icons/1_Basic", "Icon_Diamond.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/02_Icons/1_Basic", "Icon_Equip.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/02_Icons/1_Basic", "Icon_Equip_WS.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/02_Icons/1_Basic", "Icon_Inven.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/02_Icons/1_Basic", "Icon_Inven_WS.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/02_Icons/1_Basic", "Icon_Quest.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/02_Icons/1_Basic", "Icon_Quest_WS.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/02_Icons/1_Basic", "Icon_Setting.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/02_Icons/1_Basic", "Icon_Setting_WS.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/02_Icons/1_Basic", "Icon_Skill.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/02_Icons/1_Basic", "Icon_Skill_WS.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/02_Icons/1_Basic", "Icon_Sword.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/02_Icons/1_Basic", "Icon_Post.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/02_Icons/1_Basic", "Icon_Post_WS.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/02_Icons/1_Basic", "Icon_Potion1.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/02_Icons/1_Basic", "Icon_Potion1_WS.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/02_Icons/1_Basic", "Icon_Potion2.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/02_Icons/1_Basic", "Icon_Potion2_WS.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/02_Icons/1_Basic", "Image_Alarm.png"),

        // Result Screen
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/05_ResultScreen", "Image_Victory.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/05_ResultScreen", "Image_Fail.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/05_ResultScreen", "ResultBoard_111x90.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/05_ResultScreen", "Level_Guage1.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/05_ResultScreen", "Level_Guage2.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/05_ResultScreen", "Image_Select.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/05_ResultScreen", "Button_Home.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/05_ResultScreen", "Button_Retry.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/05_ResultScreen", "Button_next.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/05_ResultScreen", "Icon_Money.png"),
        ("Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/01_UI_Images/05_ResultScreen", "Icon_Time.png"),
    };

    const string DestDir = "Assets/Resources/UI";

    // Flat 아이콘 소스 경로 (1~51)
    const string FlatIconDir = "Assets/SPUM/Retro UI Set/1_UI_Images/Theme1/02_Icons/0_Flat";

    // Theme2 System 아이콘 (131~207)
    const string Theme2UIDir = "Assets/SPUM/Retro UI Set/1_UI_Images/Theme2/06_UI";

    [MenuItem("Game/Copy GUI Sprites")]
    public static void CopyAll()
    {
        // 대상 폴더 생성
        if (!AssetDatabase.IsValidFolder(DestDir))
        {
            Directory.CreateDirectory(Path.Combine(Application.dataPath, "../", DestDir));
            AssetDatabase.Refresh();
        }

        var copied = new List<string>();
        var skipped = new List<string>();
        var missing = new List<string>();

        // 핵심 스프라이트 복사
        foreach (var (srcDir, file) in CoreSprites)
        {
            string src = $"{srcDir}/{file}";
            string dst = $"{DestDir}/{file}";
            CopyAsset(src, dst, copied, skipped, missing);
        }

        // Flat 아이콘 (Icon_Flat__1 ~ 51)
        for (int i = 1; i <= 51; i++)
        {
            string file = $"Icon_Flat__{i}.png";
            string src  = $"{FlatIconDir}/{file}";
            string dst  = $"{DestDir}/{file}";
            CopyAsset(src, dst, copied, skipped, missing);
        }

        // Theme2 UI 아이콘 (Spum_Icon131 ~ 207)
        for (int i = 131; i <= 207; i++)
        {
            string file = $"Spum_Icon{i}.png";
            string src  = $"{Theme2UIDir}/{file}";
            string dst  = $"{DestDir}/{file}";
            CopyAsset(src, dst, copied, skipped, missing);
        }

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();

        // 복사 후 Sprite 타입 + border 동기화
        SetSpriteImportSettings(BuildSrcDirMap());

        string report =
            $"[CopyGUISprites] 완료\n" +
            $"  복사: {copied.Count}개\n" +
            $"  스킵(이미 존재): {skipped.Count}개\n" +
            $"  누락(소스 없음): {missing.Count}개";

        if (missing.Count > 0)
            report += "\n  누락 목록:\n    " + string.Join("\n    ", missing);

        Debug.Log(report);
        EditorUtility.DisplayDialog("Copy GUI Sprites", report, "확인");
    }

    [MenuItem("Game/Copy GUI Sprites (Force Overwrite)")]
    public static void CopyAllForce()
    {
        // 기존 Resources/UI 내 png 전부 삭제 후 재복사
        if (AssetDatabase.IsValidFolder(DestDir))
        {
            var guids = AssetDatabase.FindAssets("t:Texture2D", new[] { DestDir });
            foreach (var guid in guids)
            {
                string path = AssetDatabase.GUIDToAssetPath(guid);
                AssetDatabase.DeleteAsset(path);
            }
            AssetDatabase.Refresh();
        }
        CopyAll();
    }

    // ── 내부 헬퍼 ──────────────────────────────────────────────

    static void CopyAsset(string src, string dst,
        List<string> copied, List<string> skipped, List<string> missing)
    {
        if (!File.Exists(Path.Combine(Application.dataPath, "..", src)))
        {
            missing.Add(src);
            return;
        }

        if (File.Exists(Path.Combine(Application.dataPath, "..", dst)))
        {
            skipped.Add(dst);
            return;
        }

        bool ok = AssetDatabase.CopyAsset(src, dst);
        if (ok)
            copied.Add(dst);
        else
            missing.Add(src); // 복사 실패도 누락으로 처리
    }

    /// Resources/UI 내 모든 PNG를 Sprite 타입, FilterMode.Point 로 설정.
    /// srcDirMap을 넘기면 파일명 기준으로 원본 border 값을 적용한다.
    static void SetSpriteImportSettings(Dictionary<string, string> srcDirMap = null)
    {
        var guids = AssetDatabase.FindAssets("t:Texture2D", new[] { DestDir });
        int changed = 0;
        foreach (var guid in guids)
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);
            var importer = AssetImporter.GetAtPath(path) as TextureImporter;
            if (importer == null) continue;

            bool dirty = false;

            if (importer.textureType != TextureImporterType.Sprite)
            {
                importer.textureType = TextureImporterType.Sprite;
                dirty = true;
            }

            if (importer.filterMode != FilterMode.Point)
            {
                importer.filterMode = FilterMode.Point;
                dirty = true;
            }

            if (importer.spritePivot != new Vector2(0.5f, 0.5f))
            {
                importer.spritePivot = new Vector2(0.5f, 0.5f);
                dirty = true;
            }

            // 원본 border 값 동기화
            if (srcDirMap != null)
            {
                string fileName = Path.GetFileName(path);
                if (srcDirMap.TryGetValue(fileName, out string srcDir))
                {
                    string srcPath = $"{srcDir}/{fileName}";
                    var srcImporter = AssetImporter.GetAtPath(srcPath) as TextureImporter;
                    if (srcImporter != null)
                    {
                        var srcBorder = srcImporter.spriteBorder;
                        if (importer.spriteBorder != srcBorder)
                        {
                            importer.spriteBorder = srcBorder;
                            dirty = true;
                        }
                    }
                }
            }

            if (dirty)
            {
                importer.SaveAndReimport();
                changed++;
            }
        }

        Debug.Log($"[CopyGUISprites] {guids.Length}개 스캔 / {changed}개 설정 변경 완료 (Sprite/Point/Border)");
    }

    /// 소스 경로 맵 빌드: 파일명 → 소스 폴더
    static Dictionary<string, string> BuildSrcDirMap()
    {
        var map = new Dictionary<string, string>();
        foreach (var (srcDir, file) in CoreSprites)
        {
            if (!map.ContainsKey(file))
                map[file] = srcDir;
        }
        // Flat / Theme2 아이콘은 border 없으므로 생략
        return map;
    }

    /// 임포트 설정 재적용 (border 동기화 포함)
    [MenuItem("Game/Fix GUI Sprite Import Settings")]
    public static void FixImportSettings()
    {
        SetSpriteImportSettings(BuildSrcDirMap());
        AssetDatabase.Refresh();
    }
}
#endif
