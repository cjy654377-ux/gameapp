using UnityEditor;
using UnityEngine;

public static class DebugBoostTool
{
    [MenuItem("Tools/Debug/Boost Ally Stats (Lv50)")]
    static void BoostStats()
    {
        PlayerPrefs.SetInt("UpgradeHp", 50);
        PlayerPrefs.SetInt("UpgradeAtk", 50);
        PlayerPrefs.SetInt("UpgradeDef", 50);
        PlayerPrefs.DeleteKey("UpgradeSpeed");
        PlayerPrefs.SetInt("TapDamageLevel", 50);
        PlayerPrefs.SetInt("Gold", 99999);
        PlayerPrefs.SetInt("TotalWaveIndex", 0);
        PlayerPrefs.Save();
        Debug.Log("[DebugBoost] All upgrades Lv50, Gold=99999, Stage reset to 1-1.");
    }

    [MenuItem("Tools/Debug/Reset All Progress")]
    static void ResetAll()
    {
        PlayerPrefs.SetInt("UpgradeHp", 0);
        PlayerPrefs.SetInt("UpgradeAtk", 0);
        PlayerPrefs.SetInt("UpgradeDef", 0);
        PlayerPrefs.DeleteKey("UpgradeSpeed");
        PlayerPrefs.SetInt("TapDamageLevel", 1);
        PlayerPrefs.SetInt("TotalWaveIndex", 0);
        PlayerPrefs.SetInt("Gold", 0);
        PlayerPrefs.Save();
        Debug.Log("[DebugBoost] All progress reset to 0.");
    }
}
