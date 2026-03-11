#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEngine;

/// <summary>
/// Build automation for Android APK and iOS.
/// Menu: Game/Build/Android APK, Game/Build/iOS
/// </summary>
public static class BuildScript
{
    static readonly string[] scenes = { "Assets/Scenes/BattleScene.unity" };

    [MenuItem("Game/Build/Android APK")]
    public static void BuildAndroidAPK()
    {
        // Ensure output directory exists
        System.IO.Directory.CreateDirectory("Builds/Android");

        // Set Android-specific settings
        PlayerSettings.SetScriptingBackend(NamedBuildTarget.Android, ScriptingImplementation.IL2CPP);
        PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;

        var options = new BuildPlayerOptions
        {
            scenes = scenes,
            locationPathName = "Builds/Android/game.apk",
            target = BuildTarget.Android,
            options = BuildOptions.None
        };

        var report = BuildPipeline.BuildPlayer(options);
        LogBuildResult(report, "Android APK");
    }

    [MenuItem("Game/Build/iOS")]
    public static void BuildiOS()
    {
        // Ensure output directory exists
        System.IO.Directory.CreateDirectory("Builds/iOS");

        // Set iOS-specific settings
        PlayerSettings.SetScriptingBackend(NamedBuildTarget.iOS, ScriptingImplementation.IL2CPP);
        PlayerSettings.iOS.targetOSVersionString = "14.0";

        var options = new BuildPlayerOptions
        {
            scenes = scenes,
            locationPathName = "Builds/iOS",
            target = BuildTarget.iOS,
            options = BuildOptions.None
        };

        var report = BuildPipeline.BuildPlayer(options);
        LogBuildResult(report, "iOS");
    }

    static void LogBuildResult(BuildReport report, string platform)
    {
        if (report.summary.result == BuildResult.Succeeded)
        {
            Debug.Log($"[BuildScript] {platform} build succeeded! Size: {report.summary.totalSize / (1024 * 1024)}MB, Path: {report.summary.outputPath}");
        }
        else
        {
            Debug.LogError($"[BuildScript] {platform} build failed with {report.summary.totalErrors} error(s).");
        }
    }
}
#endif
