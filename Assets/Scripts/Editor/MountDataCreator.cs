#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

public class MountDataCreator
{
    [MenuItem("Game/Create All Mount Data")]
    public static void CreateAllMounts()
    {
        string dir = "Assets/Data/Mounts";
        if (!AssetDatabase.IsValidFolder("Assets/Data"))
            AssetDatabase.CreateFolder("Assets", "Data");
        if (!AssetDatabase.IsValidFolder(dir))
            AssetDatabase.CreateFolder("Assets/Data", "Mounts");

        Create(dir, "Mount_Horse1", new MountDef {
            mountName = "기본 말", starGrade = StarGrade.Star1,
            folder = "Horse1", speed = 10f
        });
        Create(dir, "Mount_Horse2", new MountDef {
            mountName = "갈색 말", starGrade = StarGrade.Star2,
            folder = "Horse2", speed = 15f, hp = 5f
        });
        Create(dir, "Mount_BlackHorse", new MountDef {
            mountName = "흑마", starGrade = StarGrade.Star3,
            folder = "BlackHorse", speed = 20f, atk = 10f
        });
        Create(dir, "Mount_RedHorse", new MountDef {
            mountName = "적마", starGrade = StarGrade.Star4,
            folder = "RedHorse", speed = 25f, hp = 10f, atk = 15f
        });

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        Debug.Log($"[MountDataCreator] 4종 탈것 에셋 생성 완료: {dir}");
    }

    struct MountDef
    {
        public string mountName;
        public StarGrade starGrade;
        public string folder;
        public float speed, hp, atk;
    }

    static void Create(string dir, string fileName, MountDef def)
    {
        var data = ScriptableObject.CreateInstance<MountData>();
        data.mountName         = def.mountName;
        data.starGrade         = def.starGrade;
        data.horseSpriteFolder = def.folder;
        data.speedBonus        = def.speed;
        data.hpBonusPercent    = def.hp;
        data.atkBonusPercent   = def.atk;
        AssetDatabase.CreateAsset(data, $"{dir}/{fileName}.asset");
    }
}
#endif
