using UnityEditor;
using UnityEngine;
using System.Reflection;

public static class GameViewHelper
{
    [MenuItem("Tools/Setup/Set Portrait Game View (390x844)")]
    static void SetPortraitGameView()
    {
        // Game View 윈도우에서 해상도를 강제 설정
        var gameViewType = System.Type.GetType("UnityEditor.GameView,UnityEditor");
        var window = EditorWindow.GetWindow(gameViewType);

        // PlayerSettings도 세로 고정
        PlayerSettings.defaultInterfaceOrientation = UIOrientation.Portrait;

        Debug.Log("[GameView] Portrait mode set. Please select 390x844 in Game View resolution dropdown.");
        Debug.Log("[GameView] Game View > Resolution dropdown > + > Type: Fixed Resolution > 390 x 844");
    }
}
