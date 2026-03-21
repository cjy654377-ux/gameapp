using UnityEngine;

public class DamagePopup : MonoBehaviour
{
    private SpriteRenderer sr;
    private float disappearTimer;
    private Color spriteColor;
    private Vector3 moveVector;
    private string poolName = POOL_DMG;

    const string POOL_DMG = "DmgPopup";
    const string POOL_GOLD = "GoldPopup";

    public static DamagePopup Create(Vector3 position, float amount, bool isHeal = false)
    {
        string text = isHeal ? "+" + Mathf.RoundToInt(amount) : Mathf.RoundToInt(amount).ToString();
        return Create(position, amount, isHeal, text);
    }

    public static DamagePopup Create(Vector3 position, float amount, bool isHeal, string customText)
    {
        var go = GetFromPool(POOL_DMG);
        go.transform.position = position + Vector3.up * 0.5f;

        var popup = go.GetComponent<DamagePopup>();
        popup.sr.sortingOrder = 100;

        var style = isHeal ? DamageNumberStyle.Heal : DamageNumberStyle.Damage;
        popup.sr.sprite = PixelNumberFont.CreateNumberSprite(customText, style);
        popup.sr.color = Color.white;
        popup.spriteColor = Color.white;
        popup.disappearTimer = 0.9f;
        popup.moveVector = new Vector3(Random.Range(-0.3f, 0.3f), 1.0f, 0f);
        go.transform.localScale = Vector3.one * 0.16f;

        return popup;
    }

    public static DamagePopup CreateGold(Vector3 position, int amount)
    {
        var go = GetFromPool(POOL_GOLD);
        go.transform.position = position + Vector3.up * 0.5f;

        var popup = go.GetComponent<DamagePopup>();
        popup.sr.sortingOrder = 100;
        popup.poolName = POOL_GOLD;

        popup.sr.sprite = PixelNumberFont.CreateNumberSprite("+" + amount, DamageNumberStyle.Gold);
        popup.sr.color = Color.white;
        popup.spriteColor = Color.white;
        popup.disappearTimer = 0.9f;
        popup.moveVector = new Vector3(Random.Range(-0.2f, 0.2f), 0.8f, 0f);
        go.transform.localScale = Vector3.one * 0.13f;

        return popup;
    }

    static GameObject GetFromPool(string poolName)
    {
        var pool = ObjectPool.Instance;
        if (pool != null)
        {
            return pool.Get(poolName, () => CreateNewPopupObject());
        }
        return CreateNewPopupObject();
    }

    static GameObject CreateNewPopupObject()
    {
        var go = new GameObject("DamagePopup");
        go.AddComponent<SpriteRenderer>();
        go.AddComponent<DamagePopup>();
        return go;
    }

    void Awake()
    {
        sr = GetComponent<SpriteRenderer>();
        if (sr == null) sr = gameObject.AddComponent<SpriteRenderer>();
    }

    void Update()
    {
        transform.position += moveVector * Time.deltaTime;
        moveVector -= moveVector * 3f * Time.deltaTime;

        disappearTimer -= Time.deltaTime;
        if (disappearTimer < 0)
        {
            spriteColor.a -= 3f * Time.deltaTime;
            sr.color = spriteColor;

            if (spriteColor.a <= 0)
                ReturnToPool();
        }
    }

    void ReturnToPool()
    {
        var pool = ObjectPool.Instance;
        if (pool != null)
        {
            sr.sprite = null;
            gameObject.SetActive(false);
            pool.Return(poolName, gameObject);
            poolName = POOL_DMG; // reset for reuse
        }
        else
        {
            Destroy(gameObject);
        }
    }
}
