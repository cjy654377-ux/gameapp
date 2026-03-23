using UnityEngine;

public class QuarterViewCamera : MonoBehaviour
{
    [Header("Camera Settings")]
    public float cameraSize = 6f;  // 세로 화면에 맞춰 확대
    public float followSpeed = 3f;
    public float lookAheadX = 1.5f;

    const float CAMERA_Z_DEPTH = -10f;

    Camera cam;

    void Awake()
    {
        cam = GetComponent<Camera>();
        if (cam == null) cam = gameObject.AddComponent<Camera>();

        cam.orthographic = true;
        cam.orthographicSize = cameraSize;

        transform.position = new Vector3(0, 0, CAMERA_Z_DEPTH);
        transform.rotation = Quaternion.identity;
    }

    void LateUpdate()
    {
        if (BattleManager.Instance == null) return;

        var allies = BattleManager.Instance.allyUnits;
        if (allies.Count == 0) return;

        float sumX = 0f;
        int count = 0;
        for (int i = 0; i < allies.Count; i++)
        {
            if (allies[i] != null && !allies[i].IsDead)
            {
                sumX += allies[i].transform.position.x;
                count++;
            }
        }
        if (count == 0) return;

        float targetX = sumX / count + lookAheadX;
        float newX = Mathf.Lerp(transform.position.x, targetX, followSpeed * Time.deltaTime);
        var pos = new Vector3(newX, 0, CAMERA_Z_DEPTH);
        ApplyShake(ref pos);
        transform.position = pos;
    }

    public float GetVisibleWidth()
    {
        if (cam == null) return 4.5f;
        return cam.orthographicSize * 2f * cam.aspect;
    }

    public float GetVisibleHeight()
    {
        if (cam == null) return 12f;
        return cam.orthographicSize * 2f;
    }

    // Camera shake
    float shakeTimer;
    float shakeIntensity;

    public void Shake(float duration = 0.3f, float intensity = 0.15f)
    {
        shakeTimer = duration;
        shakeIntensity = intensity;
    }

    void ApplyShake(ref Vector3 pos)
    {
        if (shakeTimer <= 0) return;
        shakeTimer -= Time.unscaledDeltaTime;
        float t = shakeTimer > 0 ? shakeIntensity : 0;
        pos.x += Random.Range(-t, t);
        pos.y += Random.Range(-t, t);
    }
}
