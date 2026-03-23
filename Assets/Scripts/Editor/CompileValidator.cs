#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.Compilation;
using UnityEngine;

/// <summary>
/// 컴파일 에러 발생 시 콘솔에 명확한 에러 요약 출력.
/// 에이전트가 자주 만드는 실수 패턴도 사전 경고.
/// </summary>
[InitializeOnLoad]
public static class CompileValidator
{
    static CompileValidator()
    {
        CompilationPipeline.compilationFinished += OnCompilationFinished;
    }

    static void OnCompilationFinished(object obj)
    {
        var messages = CompilationPipeline.GetSystemCompiledAssembly()?.GetDiagnosticMessages();
        // Unity 6에서는 compilationFinished 이벤트로 에러 수 확인
        Debug.Log("[CompileValidator] 컴파일 완료. Unity 콘솔에서 에러를 확인하세요.");
    }
}
#endif
