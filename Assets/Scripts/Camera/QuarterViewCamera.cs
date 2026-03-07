using UnityEngine;

public class QuarterViewCamera : MonoBehaviour
{
    [Header("Camera Settings")]
    public float cameraSize = 6f;

    private Camera cam;

    void Awake()
    {
        cam = GetComponent<Camera>();
        if (cam == null) cam = gameObject.AddComponent<Camera>();

        cam.orthographic = true;
        cam.orthographicSize = cameraSize;

        // Top-down 2D: no rotation
        transform.position = new Vector3(0, 0, -10f);
        transform.rotation = Quaternion.identity;
    }
}
