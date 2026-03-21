using UnityEngine;

public enum AuthProvider { Guest, Google, Apple }

/// <summary>
/// 로그인 / 인증 관리 (게스트/Google/Apple)
/// Firebase SDK 연동 전까지는 게스트 폴백으로 동작
/// </summary>
public class AuthManager : MonoBehaviour
{
    public static AuthManager Instance { get; private set; }

    public bool IsLoggedIn { get; private set; }
    public string UserId { get; private set; }
    public string DisplayName { get; private set; }
    public AuthProvider CurrentProvider { get; private set; }

    public event System.Action<bool> OnLoginResult;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }

        // 이전 세션 복원
        string savedId = PlayerPrefs.GetString(SaveKeys.AuthUserId, "");
        if (!string.IsNullOrEmpty(savedId))
        {
            UserId = savedId;
            DisplayName = PlayerPrefs.GetString(SaveKeys.AuthDisplayName, "모험가");
            CurrentProvider = (AuthProvider)PlayerPrefs.GetInt(SaveKeys.AuthProvider, 0);
            IsLoggedIn = true;
        }
    }

    /// <summary>
    /// 게스트 로그인 (deviceUniqueIdentifier)
    /// </summary>
    public void LoginAsGuest()
    {
        UserId = SystemInfo.deviceUniqueIdentifier;
        DisplayName = "모험가";
        CurrentProvider = AuthProvider.Guest;
        IsLoggedIn = true;
        SaveAuthState();
        OnLoginResult?.Invoke(true);
    }

    /// <summary>
    /// Google 로그인 (TODO: Firebase SDK 연동)
    /// </summary>
    public void LoginWithGoogle()
    {
        // TODO: Firebase Auth - GoogleSignIn
        // var credential = GoogleAuthProvider.GetCredential(googleIdToken, null);
        // FirebaseAuth.DefaultInstance.SignInWithCredentialAsync(credential)...
        Debug.Log("[AuthManager] Google 로그인 — Firebase SDK 필요");
        LoginAsGuest(); // 폴백
    }

    /// <summary>
    /// Apple 로그인 (TODO: Apple Sign In SDK)
    /// </summary>
    public void LoginWithApple()
    {
        // TODO: Apple Sign In SDK
        Debug.Log("[AuthManager] Apple 로그인 — SDK 필요");
        LoginAsGuest(); // 폴백
    }

    public void Logout()
    {
        IsLoggedIn = false;
        UserId = null;
        DisplayName = null;
        CurrentProvider = AuthProvider.Guest;
        PlayerPrefs.DeleteKey(SaveKeys.AuthUserId);
        PlayerPrefs.Save();
        OnLoginResult?.Invoke(false);
    }

    void SaveAuthState()
    {
        PlayerPrefs.SetString(SaveKeys.AuthUserId, UserId ?? "");
        PlayerPrefs.SetString(SaveKeys.AuthDisplayName, DisplayName ?? "");
        PlayerPrefs.SetInt(SaveKeys.AuthProvider, (int)CurrentProvider);
        PlayerPrefs.Save();
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }
}
