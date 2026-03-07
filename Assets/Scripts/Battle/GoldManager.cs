using UnityEngine;

public class GoldManager : MonoBehaviour
{
    public static GoldManager Instance { get; private set; }

    public int Gold { get; private set; }
    public event System.Action<int> OnGoldChanged;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(gameObject);

        Gold = PlayerPrefs.GetInt("Gold", 0);
    }

    public void AddGold(int amount)
    {
        Gold += amount;
        PlayerPrefs.SetInt("Gold", Gold);
        OnGoldChanged?.Invoke(Gold);
    }

    public bool SpendGold(int amount)
    {
        if (Gold < amount) return false;
        Gold -= amount;
        PlayerPrefs.SetInt("Gold", Gold);
        OnGoldChanged?.Invoke(Gold);
        return true;
    }
}
