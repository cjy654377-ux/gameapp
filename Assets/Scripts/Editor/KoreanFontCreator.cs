#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;
using TMPro;

public class KoreanFontCreator
{
    [MenuItem("Game/Create Korean Font SDF")]
    public static void CreateKoreanFont()
    {
        // NanumSquareRoundB 폰트로 SDF 에셋 생성
        var font = AssetDatabase.LoadAssetAtPath<Font>("Assets/Fonts/NanumSquareRoundB.ttf");
        if (font == null)
        {
            Debug.LogError("NanumSquareRoundB.ttf not found!");
            return;
        }

        // TMP_FontAsset 생성
        var fontAsset = TMP_FontAsset.CreateFontAsset(font);
        if (fontAsset == null)
        {
            Debug.LogError("Failed to create TMP_FontAsset!");
            return;
        }

        fontAsset.name = "NanumSquareRoundB SDF";

        // Resources 폴더에 저장 (TMP가 자동으로 찾을 수 있도록)
        string dir = "Assets/Resources/Fonts & Materials";
        if (!AssetDatabase.IsValidFolder("Assets/Resources/Fonts & Materials"))
        {
            if (!AssetDatabase.IsValidFolder("Assets/Resources"))
                AssetDatabase.CreateFolder("Assets", "Resources");
            AssetDatabase.CreateFolder("Assets/Resources", "Fonts & Materials");
        }

        AssetDatabase.CreateAsset(fontAsset, $"{dir}/NanumSquareRoundB SDF.asset");

        // TMP Settings에서 기본 폰트로 설정
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
        Debug.Log($"Korean font SDF created: {fontAsset.name}");
    }
}
#endif
