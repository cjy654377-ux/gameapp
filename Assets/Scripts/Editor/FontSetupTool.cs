using UnityEditor;
using UnityEngine;
using TMPro;
using System.IO;

public static class FontSetupTool
{
    [MenuItem("Tools/Setup/Fix Korean Font")]
    static void FixKoreanFont()
    {
        // 1. 기존 깨진 fallback 제거
        var defaultFont = TMP_Settings.defaultFontAsset;
        if (defaultFont != null && defaultFont.fallbackFontAssetTable != null)
        {
            defaultFont.fallbackFontAssetTable.RemoveAll(f => f == null || f.material == null);
            EditorUtility.SetDirty(defaultFont);
        }

        // 2. 기존 SDF 에셋 삭제
        string sdfPath = "Assets/Resources/Fonts/NanumSquareRoundB SDF.asset";
        if (File.Exists(sdfPath))
            AssetDatabase.DeleteAsset(sdfPath);

        // 3. 폰트 로드
        var font = AssetDatabase.LoadAssetAtPath<Font>("Assets/Fonts/NanumSquareRoundB.ttf");
        if (font == null)
        {
            Debug.LogError("[FontSetup] NanumSquareRoundB.ttf not found");
            return;
        }

        // 4. SDF 에셋 새로 생성
        var fontAsset = TMP_FontAsset.CreateFontAsset(font);
        if (fontAsset == null)
        {
            Debug.LogError("[FontSetup] CreateFontAsset failed");
            return;
        }

        fontAsset.atlasPopulationMode = AtlasPopulationMode.Dynamic;

        string dir = "Assets/Resources/Fonts";
        if (!Directory.Exists(dir))
            Directory.CreateDirectory(dir);

        AssetDatabase.CreateAsset(fontAsset, sdfPath);

        // Material도 함께 저장
        if (fontAsset.material != null)
        {
            fontAsset.material.name = fontAsset.name + " Material";
            AssetDatabase.AddObjectToAsset(fontAsset.material, sdfPath);
        }
        if (fontAsset.atlasTexture != null)
        {
            fontAsset.atlasTexture.name = fontAsset.name + " Atlas";
            AssetDatabase.AddObjectToAsset(fontAsset.atlasTexture, sdfPath);
        }

        AssetDatabase.SaveAssets();

        // 5. fallback으로 등록
        if (defaultFont != null)
        {
            if (defaultFont.fallbackFontAssetTable == null)
                defaultFont.fallbackFontAssetTable = new System.Collections.Generic.List<TMP_FontAsset>();

            defaultFont.fallbackFontAssetTable.Add(fontAsset);
            EditorUtility.SetDirty(defaultFont);
            AssetDatabase.SaveAssets();
        }

        AssetDatabase.Refresh();
        Debug.Log("[FontSetup] Korean font fixed and registered as fallback.");
    }
}
