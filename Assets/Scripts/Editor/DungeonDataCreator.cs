#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

public class DungeonDataCreator
{
    [MenuItem("Game/Create Default Dungeon Data")]
    public static void CreateDefaultDungeons()
    {
        string dir = "Assets/Data/Dungeons";
        if (!AssetDatabase.IsValidFolder("Assets/Data"))
            AssetDatabase.CreateFolder("Assets", "Data");
        if (!AssetDatabase.IsValidFolder(dir))
            AssetDatabase.CreateFolder("Assets/Data", "Dungeons");

        CreateDungeon(dir, "Dungeon_Hero",  DungeonType.Hero,  "영웅 던전",  10, 50);
        CreateDungeon(dir, "Dungeon_Mount", DungeonType.Mount, "탈것 던전", 10, 1);
        CreateDungeon(dir, "Dungeon_Skill", DungeonType.Skill, "스킬 던전",  10, 1);

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        Debug.Log($"[DungeonDataCreator] 3종 던전 에셋 생성: {dir}");
    }

    static void CreateDungeon(string dir, string fileName, DungeonType type, string name, int maxStage, int baseReward)
    {
        string path = $"{dir}/{fileName}.asset";
        if (AssetDatabase.LoadAssetAtPath<DungeonData>(path) != null)
        {
            Debug.Log($"[DungeonDataCreator] {fileName} 이미 존재, 스킵");
            return;
        }
        var data = ScriptableObject.CreateInstance<DungeonData>();
        data.dungeonType = type;
        data.stage       = 1;
        data.baseReward  = baseReward;
        AssetDatabase.CreateAsset(data, path);
    }
}
#endif
