using UnityEngine;

public class DamagePopup : MonoBehaviour
{
    private SpriteRenderer sr;
    private float disappearTimer;
    private Color spriteColor;
    private Vector3 moveVector;

    public static DamagePopup Create(Vector3 position, float amount, bool isHeal = false)
    {
        GameObject go = new GameObject("DamagePopup");
        go.transform.position = position;

        var popup = go.AddComponent<DamagePopup>();
        popup.sr = go.AddComponent<SpriteRenderer>();
        popup.sr.sortingOrder = 100;

        var style = isHeal ? DamageNumberStyle.Heal : DamageNumberStyle.Damage;
        string text = isHeal ? "+" + Mathf.RoundToInt(amount) : Mathf.RoundToInt(amount).ToString();

        popup.sr.sprite = PixelNumberFont.CreateNumberSprite(text, style);
        popup.sr.color = Color.white;
        popup.spriteColor = Color.white;
        popup.disappearTimer = 0.8f;
        popup.moveVector = new Vector3(Random.Range(-0.3f, 0.3f), 0.8f, 0f);

        go.transform.position += Vector3.up * 0.5f;
        go.transform.localScale = Vector3.one * 0.12f;

        return popup;
    }

    // Gold drop용 오버로드
    public static DamagePopup CreateGold(Vector3 position, int amount)
    {
        GameObject go = new GameObject("GoldPopup");
        go.transform.position = position;

        var popup = go.AddComponent<DamagePopup>();
        popup.sr = go.AddComponent<SpriteRenderer>();
        popup.sr.sortingOrder = 100;

        popup.sr.sprite = PixelNumberFont.CreateNumberSprite("+" + amount, DamageNumberStyle.Gold);
        popup.sr.color = Color.white;
        popup.spriteColor = Color.white;
        popup.disappearTimer = 0.8f;
        popup.moveVector = new Vector3(Random.Range(-0.2f, 0.2f), 0.6f, 0f);

        go.transform.position += Vector3.up * 0.5f;
        go.transform.localScale = Vector3.one * 0.1f;

        return popup;
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
                Destroy(gameObject);
        }
    }
}
