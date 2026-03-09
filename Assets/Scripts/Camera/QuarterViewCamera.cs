using UnityEngine;

public class QuarterViewCamera : MonoBehaviour
{
    [Header("Camera Settings")]
    public float cameraSize = 6f;  // 세로 화면에 맞춰 확대
    public float followSpeed = 3f;
    public float lookAheadX = 1.5f;

    Camera cam;

    void Awake()
    {
        cam = GetComponent<Camera>();
        if (cam == null) cam = gameObject.AddComponent<Camera>();

        cam.orthographic = true;
        cam.orthographicSize = cameraSize;

        transform.position = new Vector3(0, 0, -10f);
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
        transform.position = new Vector3(newX, 0, -10f);
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
}
