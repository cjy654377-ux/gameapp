#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;
using System.IO;

public static class ProceduralSFXGenerator
{
    const int SAMPLE_RATE = 44100;

    [MenuItem("Game/Generate SFX")]
    public static void GenerateAll()
    {
        string dir = Application.dataPath + "/Resources/Sounds/SFX";
        Directory.CreateDirectory(dir);

        GenerateHit(dir);
        GenerateGold(dir);
        GenerateLevelUp(dir);
        GenerateButton(dir);
        GenerateBossAppear(dir);
        GenerateSkill(dir);
        GenerateGacha(dir);
        GenerateEquip(dir);
        GenerateDefeat(dir);
        GenerateWaveClear(dir);

        AssetDatabase.Refresh();
        Debug.Log("[ProceduralSFXGenerator] Generated 10 SFX files.");
    }

    // ═══════════════════════════════════════
    // Individual generators
    // ═══════════════════════════════════════

    static void GenerateHit(string dir)
    {
        // 0.1s white noise burst, decaying amplitude
        int samples = (int)(SAMPLE_RATE * 0.1f);
        float[] data = new float[samples];
        for (int i = 0; i < samples; i++)
        {
            float t = (float)i / samples;
            float decay = 1f - t;
            data[i] = Random.Range(-1f, 1f) * decay;
        }
        WriteWav(Path.Combine(dir, "hit.wav"), data);
    }

    static void GenerateGold(string dir)
    {
        // 0.15s ascending 3-note (C5=523, E5=659, G5=784)
        int samples = (int)(SAMPLE_RATE * 0.15f);
        float[] data = new float[samples];
        float[] freqs = { 523f, 659f, 784f };
        int noteSamples = samples / 3;
        for (int i = 0; i < samples; i++)
        {
            int noteIdx = Mathf.Min(i / noteSamples, 2);
            float t = (float)i / SAMPLE_RATE;
            float env = 1f - ((float)(i % noteSamples) / noteSamples) * 0.3f;
            data[i] = Mathf.Sin(2f * Mathf.PI * freqs[noteIdx] * t) * env * 0.8f;
        }
        WriteWav(Path.Combine(dir, "gold.wav"), data);
    }

    static void GenerateLevelUp(string dir)
    {
        // 0.3s ascending arpeggio C4-E4-G4-C5
        int samples = (int)(SAMPLE_RATE * 0.3f);
        float[] data = new float[samples];
        float[] freqs = { 261.63f, 329.63f, 392f, 523.25f };
        int noteSamples = samples / 4;
        for (int i = 0; i < samples; i++)
        {
            int noteIdx = Mathf.Min(i / noteSamples, 3);
            float t = (float)i / SAMPLE_RATE;
            float env = 1f - ((float)(i % noteSamples) / noteSamples) * 0.4f;
            data[i] = Mathf.Sin(2f * Mathf.PI * freqs[noteIdx] * t) * env * 0.7f;
        }
        WriteWav(Path.Combine(dir, "levelup.wav"), data);
    }

    static void GenerateButton(string dir)
    {
        // 0.05s short sine pop at 800Hz
        int samples = (int)(SAMPLE_RATE * 0.05f);
        float[] data = new float[samples];
        for (int i = 0; i < samples; i++)
        {
            float t = (float)i / SAMPLE_RATE;
            float env = 1f - (float)i / samples;
            data[i] = Mathf.Sin(2f * Mathf.PI * 800f * t) * env * 0.6f;
        }
        WriteWav(Path.Combine(dir, "button.wav"), data);
    }

    static void GenerateBossAppear(string dir)
    {
        // 0.5s low rumble (80Hz) + stinger (440Hz)
        int samples = (int)(SAMPLE_RATE * 0.5f);
        float[] data = new float[samples];
        for (int i = 0; i < samples; i++)
        {
            float t = (float)i / SAMPLE_RATE;
            float progress = (float)i / samples;
            // Low rumble throughout
            float rumble = Mathf.Sin(2f * Mathf.PI * 80f * t) * 0.5f;
            // Stinger appears in second half
            float stinger = 0f;
            if (progress > 0.4f)
            {
                float stingerEnv = (1f - progress) / 0.6f;
                stinger = Mathf.Sin(2f * Mathf.PI * 440f * t) * stingerEnv * 0.6f;
            }
            float env = progress < 0.1f ? progress / 0.1f : 1f - (progress - 0.1f) * 0.3f;
            data[i] = (rumble + stinger) * env;
        }
        WriteWav(Path.Combine(dir, "boss_appear.wav"), data);
    }

    static void GenerateSkill(string dir)
    {
        // 0.2s frequency sweep 200Hz->2000Hz
        int samples = (int)(SAMPLE_RATE * 0.2f);
        float[] data = new float[samples];
        float phase = 0f;
        for (int i = 0; i < samples; i++)
        {
            float progress = (float)i / samples;
            float freq = Mathf.Lerp(200f, 2000f, progress);
            phase += 2f * Mathf.PI * freq / SAMPLE_RATE;
            float env = 1f - progress * 0.5f;
            data[i] = Mathf.Sin(phase) * env * 0.7f;
        }
        WriteWav(Path.Combine(dir, "skill.wav"), data);
    }

    static void GenerateGacha(string dir)
    {
        // 0.4s sparkle (random high freq pings)
        int samples = (int)(SAMPLE_RATE * 0.4f);
        float[] data = new float[samples];
        // Create several random ping events
        int pingCount = 8;
        float[] pingTimes = new float[pingCount];
        float[] pingFreqs = new float[pingCount];
        for (int p = 0; p < pingCount; p++)
        {
            pingTimes[p] = Random.Range(0f, 0.4f);
            pingFreqs[p] = Random.Range(2000f, 6000f);
        }
        for (int i = 0; i < samples; i++)
        {
            float t = (float)i / SAMPLE_RATE;
            float val = 0f;
            for (int p = 0; p < pingCount; p++)
            {
                float dt = t - pingTimes[p];
                if (dt >= 0f && dt < 0.05f)
                {
                    float env = 1f - dt / 0.05f;
                    val += Mathf.Sin(2f * Mathf.PI * pingFreqs[p] * dt) * env * 0.3f;
                }
            }
            data[i] = Mathf.Clamp(val, -1f, 1f);
        }
        WriteWav(Path.Combine(dir, "gacha.wav"), data);
    }

    static void GenerateEquip(string dir)
    {
        // 0.1s metallic clink (two sine bursts 1200Hz + 2400Hz)
        int samples = (int)(SAMPLE_RATE * 0.1f);
        float[] data = new float[samples];
        for (int i = 0; i < samples; i++)
        {
            float t = (float)i / SAMPLE_RATE;
            float env = 1f - (float)i / samples;
            env *= env; // sharper decay
            float s1 = Mathf.Sin(2f * Mathf.PI * 1200f * t);
            float s2 = Mathf.Sin(2f * Mathf.PI * 2400f * t);
            data[i] = (s1 * 0.5f + s2 * 0.5f) * env * 0.8f;
        }
        WriteWav(Path.Combine(dir, "equip.wav"), data);
    }

    static void GenerateDefeat(string dir)
    {
        // 0.3s descending tone 440Hz->220Hz
        int samples = (int)(SAMPLE_RATE * 0.3f);
        float[] data = new float[samples];
        float phase = 0f;
        for (int i = 0; i < samples; i++)
        {
            float progress = (float)i / samples;
            float freq = Mathf.Lerp(440f, 220f, progress);
            phase += 2f * Mathf.PI * freq / SAMPLE_RATE;
            float env = 1f - progress * 0.6f;
            data[i] = Mathf.Sin(phase) * env * 0.7f;
        }
        WriteWav(Path.Combine(dir, "defeat.wav"), data);
    }

    static void GenerateWaveClear(string dir)
    {
        // 0.3s ascending C-E-G chord
        int samples = (int)(SAMPLE_RATE * 0.3f);
        float[] data = new float[samples];
        float[] freqs = { 261.63f, 329.63f, 392f };
        for (int i = 0; i < samples; i++)
        {
            float t = (float)i / SAMPLE_RATE;
            float progress = (float)i / samples;
            // Staggered entry: each note starts slightly later
            float val = 0f;
            for (int n = 0; n < freqs.Length; n++)
            {
                float onset = n * 0.03f;
                if (t >= onset)
                {
                    float localT = t - onset;
                    float env = Mathf.Max(0f, 1f - (localT / 0.27f) * 0.4f);
                    val += Mathf.Sin(2f * Mathf.PI * freqs[n] * localT) * env * 0.3f;
                }
            }
            data[i] = val;
        }
        WriteWav(Path.Combine(dir, "wave_clear.wav"), data);
    }

    // ═══════════════════════════════════════
    // WAV writer
    // ═══════════════════════════════════════

    static void WriteWav(string path, float[] samples)
    {
        int sampleCount = samples.Length;
        int byteRate = SAMPLE_RATE * 2; // 16-bit mono
        int dataSize = sampleCount * 2;

        using (var stream = new FileStream(path, FileMode.Create))
        using (var writer = new BinaryWriter(stream))
        {
            // RIFF header
            writer.Write(System.Text.Encoding.ASCII.GetBytes("RIFF"));
            writer.Write(36 + dataSize);
            writer.Write(System.Text.Encoding.ASCII.GetBytes("WAVE"));

            // fmt chunk
            writer.Write(System.Text.Encoding.ASCII.GetBytes("fmt "));
            writer.Write(16);            // chunk size
            writer.Write((short)1);      // PCM
            writer.Write((short)1);      // mono
            writer.Write(SAMPLE_RATE);
            writer.Write(byteRate);
            writer.Write((short)2);      // block align
            writer.Write((short)16);     // bits per sample

            // data chunk
            writer.Write(System.Text.Encoding.ASCII.GetBytes("data"));
            writer.Write(dataSize);

            for (int i = 0; i < sampleCount; i++)
            {
                float clamped = Mathf.Clamp(samples[i], -1f, 1f);
                short pcm = (short)(clamped * 32767f);
                writer.Write(pcm);
            }
        }
    }
}
#endif
