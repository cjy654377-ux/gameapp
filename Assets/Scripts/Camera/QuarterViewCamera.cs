using UnityEngine;

public class QuarterViewCamera : MonoBehaviour
{
    [Header("Camera Settings")]
    public float cameraSize = 4f;
    public float followSpeed = 3f;
    public float lookAheadX = 1f;

    private Camera cam;

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

        // Follow average X of alive allies
        float sumX = 0f;
        int count = 0;
        for (int i = 0; i < allies.Count; i++)
        {
            if (!allies[i].IsDead)
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
        if (cam == null) return 8f;
        return cam.orthographicSize * 2f;
    }
}
