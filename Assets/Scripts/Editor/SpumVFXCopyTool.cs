using UnityEditor;
using UnityEngine;
using System.IO;

/// <summary>
/// SPUM 이펙트 프리팹을 Resources/VFX/ 폴더로 복사하는 에디터 유틸리티.
/// Menu: Tools > Copy SPUM VFX to Resources
/// </summary>
public static class SpumVFXCopyTool
{
    const string SRC = "Assets/SPUM/Ultimate Resource Bundle/Res/Effect/Prefabs";
    const string DST = "Assets/Resources/VFX";

    static readonly string[] targets =
    {
        "Eff_Damaged",
        "Eff_FireDamaged",
        "Eff_SaintDamaged",
        "Eff_Vampire",
        "Eff_Slow",
        "Eff_SaintHeal",
        "Eff_MagicCast",
        "Eff_SaintCast",
        "Eff_BashDamaged",
        "Eff_Critical",
        "Eff_Tonado",
    };

    [MenuItem("Tools/Copy SPUM VFX to Resources")]
    public static void CopyAll()
    {
        if (!AssetDatabase.IsValidFolder(DST))
        {
            AssetDatabase.CreateFolder("Assets/Resources", "VFX");
        }

        int copied = 0, skipped = 0;

        foreach (var name in targets)
        {
            string srcPath = $"{SRC}/{name}.prefab";
            string dstPath = $"{DST}/{name}.prefab";

            if (!File.Exists(srcPath))
            {
                Debug.LogWarning($"[SpumVFXCopyTool] 원본 없음: {srcPath}");
                skipped++;
                continue;
            }

            if (File.Exists(dstPath))
            {
                // 이미 있으면 덮어쓰기
                AssetDatabase.DeleteAsset(dstPath);
            }

            bool ok = AssetDatabase.CopyAsset(srcPath, dstPath);
            if (ok)
            {
                Debug.Log($"[SpumVFXCopyTool] 복사 완료: {dstPath}");
                copied++;
            }
            else
            {
                Debug.LogError($"[SpumVFXCopyTool] 복사 실패: {srcPath} → {dstPath}");
                skipped++;
            }
        }

        AssetDatabase.Refresh();
        EditorUtility.DisplayDialog(
            "SPUM VFX 복사 완료",
            $"복사: {copied}개\n건너뜀/실패: {skipped}개\n\n대상 폴더: {DST}",
            "확인"
        );
    }
}
