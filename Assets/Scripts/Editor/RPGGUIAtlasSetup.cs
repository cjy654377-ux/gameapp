#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.U2D.Sprites;
using UnityEngine;
using System.Collections.Generic;

public class RPGGUIAtlasSetup
{
    const string ATLAS_PATH = "Assets/Art/UI/RPG_GUI_Atlas.png";

    [MenuItem("Game/Setup RPG GUI Atlas")]
    public static void Setup()
    {
        if (!System.IO.File.Exists(ATLAS_PATH))
        {
            Debug.LogError($"[RPGGUIAtlas] File not found: {ATLAS_PATH}");
            return;
        }
        AssetDatabase.ImportAsset(ATLAS_PATH, ImportAssetOptions.ForceUpdate);

        var importer = AssetImporter.GetAtPath(ATLAS_PATH) as TextureImporter;
        if (importer == null)
        {
            Debug.LogError("[RPGGUIAtlas] TextureImporter not found");
            return;
        }

        importer.textureType = TextureImporterType.Sprite;
        importer.spriteImportMode = SpriteImportMode.Multiple;
        importer.filterMode = FilterMode.Point;
        importer.textureCompression = TextureImporterCompression.Uncompressed;
        importer.maxTextureSize = 2048;
        importer.spritePixelsPerUnit = 100;
        importer.SaveAndReimport();

        // ISpriteEditorDataProvider로 슬라이스 설정
        var factory = new SpriteDataProviderFactories();
        factory.Init();
        var provider = factory.GetSpriteEditorDataProviderFromObject(importer);
        provider.InitSpriteEditorDataProvider();

        var rects = new List<SpriteRect>();

        // 2048x2048 이미지 슬라이스
        AddRect(rects, "GUI_HPBar_Frame", 30, 50, 970, 85, 35, 15, 35, 15);
        AddRect(rects, "GUI_HPBar_Fill", 75, 70, 880, 45, 5, 5, 5, 5);
        AddRect(rects, "GUI_EXPBar_Frame", 1050, 50, 970, 85, 35, 15, 35, 15);
        AddRect(rects, "GUI_EXPBar_Fill", 1095, 70, 880, 45, 5, 5, 5, 5);
        AddRect(rects, "GUI_CoinIcon", 620, 200, 280, 280, 0, 0, 0, 0);
        AddRect(rects, "GUI_DiamondIcon", 1100, 200, 280, 280, 0, 0, 0, 0);
        AddRect(rects, "GUI_Panel_Large", 30, 530, 930, 1030, 55, 55, 55, 55);
        AddRect(rects, "GUI_Panel_Parchment", 100, 630, 790, 830, 25, 25, 25, 25);
        AddRect(rects, "GUI_TitleBar", 1020, 540, 960, 130, 45, 15, 45, 15);
        AddRect(rects, "GUI_ItemSlot", 1020, 720, 280, 280, 22, 22, 22, 22);
        AddRect(rects, "GUI_BottomBar", 30, 1620, 960, 130, 45, 15, 45, 15);
        AddRect(rects, "GUI_TabSlot", 1020, 1620, 260, 260, 20, 20, 20, 20);

        provider.SetSpriteRects(rects.ToArray());
        provider.Apply();

        var assetImporter = provider.targetObject as AssetImporter;
        assetImporter?.SaveAndReimport();

        // Resources에 복사
        CopyToResources(rects.Count);
    }

    static void AddRect(List<SpriteRect> list, string name,
        int imgX, int imgY, int w, int h,
        int borderL, int borderB, int borderR, int borderT)
    {
        int unityY = 2048 - imgY - h;
        var sr = new SpriteRect
        {
            name = name,
            rect = new Rect(imgX, unityY, w, h),
            alignment = SpriteAlignment.Center,
            pivot = new Vector2(0.5f, 0.5f),
            border = new Vector4(borderL, borderB, borderR, borderT),
            spriteID = GUID.Generate()
        };
        list.Add(sr);
    }

    static void CopyToResources(int count)
    {
        string destDir = "Assets/Resources/UI/CustomGUI";
        if (!AssetDatabase.IsValidFolder("Assets/Resources/UI/CustomGUI"))
        {
            if (!AssetDatabase.IsValidFolder("Assets/Resources/UI"))
                AssetDatabase.CreateFolder("Assets/Resources", "UI");
            AssetDatabase.CreateFolder("Assets/Resources/UI", "CustomGUI");
        }

        string destPath = $"{destDir}/RPG_GUI_Atlas.png";
        if (AssetDatabase.LoadAssetAtPath<Texture2D>(destPath) != null)
            AssetDatabase.DeleteAsset(destPath);

        AssetDatabase.CopyAsset(ATLAS_PATH, destPath);
        AssetDatabase.ImportAsset(destPath, ImportAssetOptions.ForceUpdate);

        // 임포트 설정 동기화
        var srcImporter = AssetImporter.GetAtPath(ATLAS_PATH) as TextureImporter;
        var destImporter = AssetImporter.GetAtPath(destPath) as TextureImporter;
        if (destImporter != null && srcImporter != null)
        {
            EditorUtility.CopySerialized(srcImporter, destImporter);
            destImporter.SaveAndReimport();
        }

        Debug.Log($"[RPGGUIAtlas] {count}개 스프라이트 슬라이스 + Resources 복사 완료");
    }
}
#endif
