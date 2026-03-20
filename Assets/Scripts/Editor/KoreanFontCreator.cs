#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;
using TMPro;
using TMPro.EditorUtilities;
using UnityEngine.TextCore.LowLevel;

public class KoreanFontCreator
{
    [MenuItem("Game/Create Korean Font SDF")]
    public static void CreateKoreanFont()
    {
        var font = AssetDatabase.LoadAssetAtPath<Font>("Assets/Fonts/NanumSquareRoundB.ttf");
        if (font == null)
        {
            Debug.LogError("NanumSquareRoundB.ttf not found!");
            return;
        }

        // 한글 문자 세트 구성
        string chars = "";
        for (int i = 32; i <= 126; i++) chars += (char)i;
        for (int i = 0xAC00; i <= 0xD7A3; i++) chars += (char)i;
        chars += "★☆●○×→←↑↓…·:;!?+-=/%()[]{}\"',.";

        // TMP_FontAsset 생성 (Dynamic으로 설정)
        var fontAsset = TMP_FontAsset.CreateFontAsset(font, 32, 5,
            GlyphRenderMode.SDFAA, 4096, 4096);
        fontAsset.name = "NanumSquareRoundB SDF";

        // Dynamic 폰트로 설정 (없는 글리프 자동 추가)
        fontAsset.atlasPopulationMode = AtlasPopulationMode.Dynamic;

        string dir = "Assets/Resources/Fonts";
        if (!AssetDatabase.IsValidFolder("Assets/Resources/Fonts"))
        {
            if (!AssetDatabase.IsValidFolder("Assets/Resources"))
                AssetDatabase.CreateFolder("Assets", "Resources");
            AssetDatabase.CreateFolder("Assets/Resources", "Fonts");
        }

        string path = $"{dir}/NanumSquareRoundB SDF.asset";
        if (AssetDatabase.LoadAssetAtPath<TMP_FontAsset>(path) != null)
            AssetDatabase.DeleteAsset(path);

        AssetDatabase.CreateAsset(fontAsset, path);

        // atlas texture도 서브에셋으로 저장
        if (fontAsset.atlasTextures != null && fontAsset.atlasTextures.Length > 0)
        {
            for (int i = 0; i < fontAsset.atlasTextures.Length; i++)
            {
                fontAsset.atlasTextures[i].name = $"NanumSquareRoundB Atlas {i}";
                AssetDatabase.AddObjectToAsset(fontAsset.atlasTextures[i], fontAsset);
            }
        }

        // material도 서브에셋으로 저장
        if (fontAsset.material != null)
        {
            fontAsset.material.name = "NanumSquareRoundB SDF Material";
            AssetDatabase.AddObjectToAsset(fontAsset.material, fontAsset);
        }

        // TMP Settings 기본 폰트 설정
        var settings = Resources.Load<TMP_Settings>("TMP Settings");
        if (settings != null)
        {
            var so = new SerializedObject(settings);
            var prop = so.FindProperty("m_defaultFontAsset");
            if (prop != null)
            {
                prop.objectReferenceValue = fontAsset;
                so.ApplyModifiedProperties();
                EditorUtility.SetDirty(settings);
            }
        }

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        Debug.Log($"Korean Dynamic SDF font created: {path}");
    }
}
#endif
