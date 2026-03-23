using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;

/// <summary>
/// UI 리스트 아이템 재활용 유틸리티
/// RecycleList / ReuseOrCreate / TrimExcess 공용화
/// </summary>
public static class UIListPool
{
    public static void RecycleList(List<GameObject> items)
    {
        for (int i = 0; i < items.Count; i++)
            if (items[i] != null) items[i].SetActive(false);
    }

    public static GameObject ReuseOrCreate(List<GameObject> items, ref int reuseIdx,
        string name, Transform parent, Color color, Sprite sprite = null)
    {
        if (sprite == null) sprite = UISprites.BoxBasic3;

        while (reuseIdx < items.Count)
        {
            var candidate = items[reuseIdx++];
            if (candidate == null) continue;
            for (int c = candidate.transform.childCount - 1; c >= 0; c--)
                Object.Destroy(candidate.transform.GetChild(c).gameObject);
            candidate.SetActive(true);
            candidate.name = name;
            candidate.GetComponent<Image>().color = color;
            return candidate;
        }
        var img = UIHelper.MakeSpritePanel(name, parent, sprite, color);
        items.Add(img.gameObject);
        return img.gameObject;
    }

    public static void TrimExcess(List<GameObject> items, int activeCount)
    {
        for (int i = items.Count - 1; i >= activeCount; i--)
        {
            if (items[i] != null) Object.Destroy(items[i]);
            items.RemoveAt(i);
        }
    }
}
