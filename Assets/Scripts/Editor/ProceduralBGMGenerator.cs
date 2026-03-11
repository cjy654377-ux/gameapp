#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;
using System.IO;

public static class ProceduralBGMGenerator
{
    const int SAMPLE_RATE = 44100;

    [MenuItem("Game/Generate BGM")]
    public static void GenerateAll()
    {
        string dir = Application.dataPath + "/Resources/Sounds/BGM";
        Directory.CreateDirectory(dir);

        GenerateBattleGrass(dir);
        GenerateBattleDesert(dir);
        GenerateBattleCave(dir);

        AssetDatabase.Refresh();
        Debug.Log("[ProceduralBGMGenerator] Generated 3 BGM files.");
    }

    // ═══════════════════════════════════════
    // battle_grass: C major pentatonic, 120BPM, upbeat
    // ═══════════════════════════════════════

    static void GenerateBattleGrass(string dir)
    {
        int totalSamples = SAMPLE_RATE * 8;
        float[] data = new float[totalSamples];
        float bpm = 120f;
        float beatDur = 60f / bpm;

        // C major pentatonic: C4, D4, E4, G4, A4, C5
        float[] melody = { 261.63f, 293.66f, 329.63f, 392f, 440f, 523.25f };
        // Bass: C3, G2
        float bassC = 130.81f;
        float bassG = 98f;

        // Simple melody pattern (16 eighth notes per 4 bars = 32 eighth notes for 8s)
        int eighthSamples = (int)(beatDur * 0.5f * SAMPLE_RATE);
        int totalEighths = totalSamples / eighthSamples;

        // Pseudo-random but deterministic melody
        int[] melodyPattern = { 0, 2, 4, 3, 2, 4, 5, 3, 4, 2, 0, 2, 3, 4, 5, 4,
                                0, 2, 3, 4, 5, 4, 3, 2, 0, 2, 4, 5, 4, 3, 2, 0 };

        for (int i = 0; i < totalSamples; i++)
        {
            float t = (float)i / SAMPLE_RATE;
            int eighthIdx = i / eighthSamples;
            if (eighthIdx >= melodyPattern.Length) eighthIdx = eighthIdx % melodyPattern.Length;

            float localT = (float)(i % eighthSamples) / eighthSamples;

            // Melody: sine with envelope
            float melodyFreq = melody[melodyPattern[eighthIdx]];
            float melodyEnv = localT < 0.05f ? localT / 0.05f : Mathf.Max(0f, 1f - (localT - 0.05f) * 1.5f);
            float melodyVal = Mathf.Sin(2f * Mathf.PI * melodyFreq * t) * melodyEnv * 0.35f;

            // Bass: alternates C and G every beat
            int beatIdx = (int)(t / beatDur);
            float bassFreq = beatIdx % 2 == 0 ? bassC : bassG;
            float bassLocalT = (t % beatDur) / beatDur;
            float bassEnv = Mathf.Max(0f, 1f - bassLocalT * 0.8f);
            // Square-ish bass
            float bassPhase = (t * bassFreq) % 1f;
            float bassVal = (bassPhase < 0.5f ? 0.5f : -0.5f) * bassEnv * 0.25f;

            // Simple kick on each beat
            float kickLocalT = t % beatDur;
            float kick = 0f;
            if (kickLocalT < 0.08f)
            {
                float kickFreq = Mathf.Lerp(150f, 60f, kickLocalT / 0.08f);
                kick = Mathf.Sin(2f * Mathf.PI * kickFreq * kickLocalT) * (1f - kickLocalT / 0.08f) * 0.3f;
            }

            data[i] = Mathf.Clamp(melodyVal + bassVal + kick, -1f, 1f);
        }
        WriteWav(Path.Combine(dir, "battle_grass.wav"), data);
    }

    // ═══════════════════════════════════════
    // battle_desert: D minor harmonic, 100BPM, mysterious
    // ═══════════════════════════════════════

    static void GenerateBattleDesert(string dir)
    {
        int totalSamples = SAMPLE_RATE * 8;
        float[] data = new float[totalSamples];
        float bpm = 100f;
        float beatDur = 60f / bpm;

        // D minor harmonic scale: D4, E4, F4, G4, A4, Bb4, C#5, D5
        float[] scale = { 293.66f, 329.63f, 349.23f, 392f, 440f, 466.16f, 554.37f, 587.33f };

        int eighthSamples = (int)(beatDur * 0.5f * SAMPLE_RATE);

        // Mysterious pattern with jumps
        int[] melodyPattern = { 0, 4, 6, 5, 3, 1, 0, 6, 5, 7, 6, 4, 2, 0, 5, 3,
                                0, 6, 5, 4, 3, 2, 6, 0, 7, 5, 3, 1, 0, 4, 6, 7 };

        // Bass drone on D2
        float bassDrone = 73.42f;

        for (int i = 0; i < totalSamples; i++)
        {
            float t = (float)i / SAMPLE_RATE;
            int eighthIdx = (i / eighthSamples) % melodyPattern.Length;
            float localT = (float)(i % eighthSamples) / eighthSamples;

            // Melody with slight vibrato
            float melodyFreq = scale[melodyPattern[eighthIdx]];
            float vibrato = 1f + Mathf.Sin(2f * Mathf.PI * 5f * t) * 0.005f;
            float melodyEnv = localT < 0.08f ? localT / 0.08f : Mathf.Max(0f, 1f - (localT - 0.08f) * 1.2f);
            float melodyVal = Mathf.Sin(2f * Mathf.PI * melodyFreq * vibrato * t) * melodyEnv * 0.3f;

            // Drone bass
            float droneVal = Mathf.Sin(2f * Mathf.PI * bassDrone * t) * 0.2f;
            // Add fifth for richness
            droneVal += Mathf.Sin(2f * Mathf.PI * bassDrone * 1.5f * t) * 0.1f;

            // Subtle percussion on beats 1 and 3
            int beatIdx = (int)(t / beatDur);
            float beatLocalT = t % beatDur;
            float perc = 0f;
            if (beatIdx % 2 == 0 && beatLocalT < 0.06f)
            {
                perc = Random.Range(-0.15f, 0.15f) * (1f - beatLocalT / 0.06f);
            }

            data[i] = Mathf.Clamp(melodyVal + droneVal + perc, -1f, 1f);
        }
        WriteWav(Path.Combine(dir, "battle_desert.wav"), data);
    }

    // ═══════════════════════════════════════
    // battle_cave: A minor, 80BPM, dark ambient with low drone
    // ═══════════════════════════════════════

    static void GenerateBattleCave(string dir)
    {
        int totalSamples = SAMPLE_RATE * 8;
        float[] data = new float[totalSamples];
        float bpm = 80f;
        float beatDur = 60f / bpm;

        // A minor scale notes for sparse melody: A3, C4, D4, E4, G4
        float[] notes = { 220f, 261.63f, 293.66f, 329.63f, 392f };

        // Very sparse note pattern (some slots = -1 for silence)
        int quarterSamples = (int)(beatDur * SAMPLE_RATE);
        // 32 quarters in 8s at 80BPM
        int[] pattern = { 0, -1, -1, 2, -1, 1, -1, -1, 4, -1, 3, -1, -1, 1, -1, 0,
                          -1, 2, -1, -1, 3, -1, -1, 4, -1, 1, 0, -1, -1, 2, -1, -1 };

        // Low drone: A1 = 55Hz
        float droneFreq = 55f;

        for (int i = 0; i < totalSamples; i++)
        {
            float t = (float)i / SAMPLE_RATE;
            int quarterIdx = (i / quarterSamples) % pattern.Length;
            float localT = (float)(i % quarterSamples) / quarterSamples;

            // Sparse melody with long decay
            float melodyVal = 0f;
            if (pattern[quarterIdx] >= 0)
            {
                float freq = notes[pattern[quarterIdx]];
                float env = localT < 0.05f ? localT / 0.05f : Mathf.Exp(-localT * 3f);
                melodyVal = Mathf.Sin(2f * Mathf.PI * freq * t) * env * 0.25f;
            }

            // Dark low drone with slow LFO
            float lfo = 1f + Mathf.Sin(2f * Mathf.PI * 0.3f * t) * 0.3f;
            float drone = Mathf.Sin(2f * Mathf.PI * droneFreq * t) * 0.2f * lfo;
            // Sub-harmonics
            drone += Mathf.Sin(2f * Mathf.PI * droneFreq * 0.5f * t) * 0.1f;

            // Occasional water drip effect (noise bursts)
            float drip = 0f;
            float dripCycle = t % 2.5f;
            if (dripCycle > 2.0f && dripCycle < 2.02f)
            {
                float dripT = (dripCycle - 2.0f) / 0.02f;
                drip = Mathf.Sin(2f * Mathf.PI * 3000f * dripT * 0.02f) * (1f - dripT) * 0.15f;
            }

            data[i] = Mathf.Clamp(melodyVal + drone + drip, -1f, 1f);
        }
        WriteWav(Path.Combine(dir, "battle_cave.wav"), data);
    }

    // ═══════════════════════════════════════
    // WAV writer
    // ═══════════════════════════════════════

    static void WriteWav(string path, float[] samples)
    {
        int sampleCount = samples.Length;
        int byteRate = SAMPLE_RATE * 2;
        int dataSize = sampleCount * 2;

        using (var stream = new FileStream(path, FileMode.Create))
        using (var writer = new BinaryWriter(stream))
        {
            writer.Write(System.Text.Encoding.ASCII.GetBytes("RIFF"));
            writer.Write(36 + dataSize);
            writer.Write(System.Text.Encoding.ASCII.GetBytes("WAVE"));

            writer.Write(System.Text.Encoding.ASCII.GetBytes("fmt "));
            writer.Write(16);
            writer.Write((short)1);
            writer.Write((short)1);
            writer.Write(SAMPLE_RATE);
            writer.Write(byteRate);
            writer.Write((short)2);
            writer.Write((short)16);

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
