using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// Generic object pool to reduce GC from Instantiate/Destroy.
/// Usage:
///   var obj = ObjectPool.Instance.Get("Bullet", () => Instantiate(bulletPrefab));
///   ObjectPool.Instance.Return("Bullet", obj);
/// </summary>
public class ObjectPool : MonoBehaviour
{
    public static ObjectPool Instance { get; private set; }

    readonly Dictionary<string, Queue<GameObject>> pools = new();

    void Awake()
    {
        if (Instance == null) Instance = this;
        else { Destroy(gameObject); return; }
    }

    /// <summary>
    /// Get an object from the pool, or create one via createFunc if pool is empty.
    /// </summary>
    public GameObject Get(string poolName, System.Func<GameObject> createFunc)
    {
        if (pools.TryGetValue(poolName, out var queue) && queue.Count > 0)
        {
            var obj = queue.Dequeue();
            if (obj == null)
            {
                // Object was destroyed externally, create new
                return createFunc();
            }
            obj.SetActive(true);
            return obj;
        }
        return createFunc();
    }

    /// <summary>
    /// Return an object to the pool. Object is deactivated.
    /// </summary>
    public void Return(string poolName, GameObject obj)
    {
        if (obj == null) return;

        obj.SetActive(false);
        if (!pools.ContainsKey(poolName))
            pools[poolName] = new Queue<GameObject>();
        pools[poolName].Enqueue(obj);
    }

    /// <summary>
    /// Pre-warm a pool with a number of instances.
    /// </summary>
    public void Prewarm(string poolName, int count, System.Func<GameObject> createFunc)
    {
        if (!pools.ContainsKey(poolName))
            pools[poolName] = new Queue<GameObject>();

        var queue = pools[poolName];
        for (int i = 0; i < count; i++)
        {
            var obj = createFunc();
            obj.SetActive(false);
            queue.Enqueue(obj);
        }
    }

    /// <summary>
    /// Clear a specific pool, destroying all pooled objects.
    /// </summary>
    public void ClearPool(string poolName)
    {
        if (!pools.TryGetValue(poolName, out var queue)) return;

        while (queue.Count > 0)
        {
            var obj = queue.Dequeue();
            if (obj != null) Destroy(obj);
        }
        pools.Remove(poolName);
    }

    /// <summary>
    /// Clear all pools.
    /// </summary>
    public void ClearAll()
    {
        foreach (var kvp in pools)
        {
            while (kvp.Value.Count > 0)
            {
                var obj = kvp.Value.Dequeue();
                if (obj != null) Destroy(obj);
            }
        }
        pools.Clear();
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }
}
