using UnityEngine;
using System.Collections.Generic;

public enum UISoundType
{
    button_click,
    tab_switch,
    popup,
    levelup,
    awakening,
    gacha_reveal,
    achievement
}

public class SoundManager : MonoBehaviour
{
    public static SoundManager Instance { get; private set; }

    AudioSource bgmSource;
    AudioSource sfxSource;
    AudioSource uiSource;

    public float bgmVolume = 0.5f;
    public float sfxVolume = 0.7f;

    readonly Dictionary<string, AudioClip> clipCache = new();

    void Awake()
    {
        if (Instance != null && Instance != this) { Destroy(gameObject); return; }
        Instance = this;
        DontDestroyOnLoad(gameObject);

        bgmSource = gameObject.AddComponent<AudioSource>();
        bgmSource.loop = true;
        bgmSource.playOnAwake = false;

        sfxSource = gameObject.AddComponent<AudioSource>();
        sfxSource.loop = false;
        sfxSource.playOnAwake = false;

        uiSource = gameObject.AddComponent<AudioSource>();
        uiSource.loop = false;
        uiSource.playOnAwake = false;

        bgmVolume = PlayerPrefs.GetFloat(SaveKeys.BgmVolume, 0.5f);
        sfxVolume = PlayerPrefs.GetFloat(SaveKeys.SfxVolume, 0.7f);
        bgmSource.volume = bgmVolume;
        sfxSource.volume = sfxVolume;
        uiSource.volume = sfxVolume;
    }

    AudioClip LoadClip(string path)
    {
        if (clipCache.TryGetValue(path, out var cached)) return cached;
        var clip = Resources.Load<AudioClip>(path);
        if (clip != null) clipCache[path] = clip;
        return clip;
    }

    public void PlayBGM(string clipName)
    {
        var clip = LoadClip("Sounds/BGM/" + clipName);
        if (clip == null) return;
        if (bgmSource.clip == clip && bgmSource.isPlaying) return;
        bgmSource.clip = clip;
        bgmSource.Play();
    }

    public void StopBGM()
    {
        bgmSource.Stop();
    }

    public void PlaySFX(string clipName)
    {
        var clip = LoadClip("Sounds/SFX/" + clipName);
        if (clip == null) return;
        sfxSource.PlayOneShot(clip, sfxVolume);
    }

    public void PlaySFXAtPoint(string clipName, Vector3 pos)
    {
        var clip = LoadClip("Sounds/SFX/" + clipName);
        if (clip == null) return;
        AudioSource.PlayClipAtPoint(clip, pos, sfxVolume);
    }

    public void PlayUISound(UISoundType soundType)
    {
        string clipName = "ui_" + soundType.ToString().ToLower();
        var clip = LoadClip("Sounds/SFX/" + clipName);
        if (clip == null) return;
        uiSource.PlayOneShot(clip, sfxVolume);
    }

    public void PlayHitSFX() => PlaySFX("hit");
    public void PlayGoldSFX() => PlaySFX("gold");
    public void PlayLevelUpSFX() => PlaySFX("levelup");
    public void PlayButtonSFX() => PlaySFX("button");
    public void PlayBossAppearSFX() => PlaySFX("boss_appear");
    public void PlaySkillSFX() => PlaySFX("skill");
    public void PlayGachaSFX() => PlaySFX("gacha");
    public void PlayEquipSFX() => PlaySFX("equip");
    public void PlayDefeatSFX() => PlaySFX("defeat");
    public void PlayWaveClearSFX() => PlaySFX("wave_clear");

    public void SetBGMVolume(float v)
    {
        bgmVolume = Mathf.Clamp01(v);
        bgmSource.volume = bgmVolume;
        PlayerPrefs.SetFloat(SaveKeys.BgmVolume, bgmVolume);
    }

    public void SetSFXVolume(float v)
    {
        sfxVolume = Mathf.Clamp01(v);
        sfxSource.volume = sfxVolume;
        uiSource.volume = sfxVolume;
        PlayerPrefs.SetFloat(SaveKeys.SfxVolume, sfxVolume);
    }

    // ═══ 에리어별 BGM ═══
    static readonly string[] AREA_BGM = { "", "bgm_grass", "bgm_desert", "bgm_cave" };
    int currentAreaBGM = -1;

    public void PlayAreaBGM(int area)
    {
        if (area == currentAreaBGM) return;
        currentAreaBGM = area;
        string clipName = area > 0 && area < AREA_BGM.Length ? AREA_BGM[area] : AREA_BGM[1];
        PlayBGM(clipName);
    }

    public void PlayArenaBGM()
    {
        currentAreaBGM = -1;
        PlayBGM("bgm_arena");
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }
}
