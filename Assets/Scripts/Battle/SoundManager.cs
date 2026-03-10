using UnityEngine;
using System.Collections.Generic;

public class SoundManager : MonoBehaviour
{
    public static SoundManager Instance { get; private set; }

    AudioSource bgmSource;
    AudioSource sfxSource;

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

        bgmVolume = PlayerPrefs.GetFloat("BGMVolume", 0.5f);
        sfxVolume = PlayerPrefs.GetFloat("SFXVolume", 0.7f);
        bgmSource.volume = bgmVolume;
        sfxSource.volume = sfxVolume;
    }

    AudioClip LoadClip(string path)
    {
        if (clipCache.TryGetValue(path, out var cached)) return cached;
        var clip = Resources.Load<AudioClip>(path);
        clipCache[path] = clip;
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

    public void PlayHitSFX() => PlaySFX("hit");
    public void PlayGoldSFX() => PlaySFX("gold");
    public void PlayLevelUpSFX() => PlaySFX("levelup");
    public void PlayButtonSFX() => PlaySFX("button");

    public void SetBGMVolume(float v)
    {
        bgmVolume = Mathf.Clamp01(v);
        bgmSource.volume = bgmVolume;
        PlayerPrefs.SetFloat("BGMVolume", bgmVolume);
    }

    public void SetSFXVolume(float v)
    {
        sfxVolume = Mathf.Clamp01(v);
        sfxSource.volume = sfxVolume;
        PlayerPrefs.SetFloat("SFXVolume", sfxVolume);
    }
}
