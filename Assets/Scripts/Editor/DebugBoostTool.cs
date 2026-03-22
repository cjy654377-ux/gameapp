#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

public static class DebugBoostTool
{
    [MenuItem("Tools/Debug/Boost Ally Stats (Lv50)")]
    static void BoostStats()
    {
        PlayerPrefs.SetInt(SaveKeys.UpgradeHp, 50);
        PlayerPrefs.SetInt(SaveKeys.UpgradeAtk, 50);
        PlayerPrefs.SetInt(SaveKeys.UpgradeDef, 50);
        PlayerPrefs.SetInt(SaveKeys.TapDamageLevel, 50);
        PlayerPrefs.SetInt(SaveKeys.Gold, 99999);
        PlayerPrefs.SetInt(SaveKeys.TotalWaveIndex, 0);
        PlayerPrefs.Save();
        Debug.Log("[DebugBoost] All upgrades Lv50, Gold=99999, Stage reset to 1-1.");
    }

    [MenuItem("Tools/Debug/Reset Tutorial Only")]
    static void ResetTutorial()
    {
        PlayerPrefs.SetInt(SaveKeys.TutorialStep, 0);
        PlayerPrefs.Save();
        Debug.Log("[DebugBoost] Tutorial reset to step 0.");
    }

    [MenuItem("Tools/Debug/Reset All Progress")]
    static void ResetAll()
    {
        PlayerPrefs.SetInt(SaveKeys.UpgradeHp, 0);
        PlayerPrefs.SetInt(SaveKeys.UpgradeAtk, 0);
        PlayerPrefs.SetInt(SaveKeys.UpgradeDef, 0);
        PlayerPrefs.SetInt(SaveKeys.TapDamageLevel, 1);
        PlayerPrefs.SetInt(SaveKeys.TotalWaveIndex, 0);
        PlayerPrefs.SetInt(SaveKeys.Gold, 0);
        PlayerPrefs.Save();
        Debug.Log("[DebugBoost] All progress reset to 0.");
    }
}
#endif
