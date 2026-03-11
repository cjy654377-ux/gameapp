using UnityEngine;

public class EffectManager : MonoBehaviour
{
    public static EffectManager Instance { get; private set; }

    void Awake()
    {
        if (Instance != null && Instance != this) { Destroy(gameObject); return; }
        Instance = this;
    }

    public void SpawnHitEffect(Vector3 pos)
    {
        var go = CreateParticleObject("HitEffect", pos);
        var ps = go.GetComponent<ParticleSystem>();
        var main = ps.main;
        main.duration = 0.3f;
        main.startLifetime = 0.3f;
        main.startSpeed = 3f;
        main.startSize = 0.08f;
        main.startColor = new Color(1f, 0.2f, 0.1f, 1f);
        main.maxParticles = 10;
        main.loop = false;
        main.stopAction = ParticleSystemStopAction.Destroy;

        var emission = ps.emission;
        emission.rateOverTime = 0;
        emission.SetBursts(new[] { new ParticleSystem.Burst(0f, 10) });

        var shape = ps.shape;
        shape.shapeType = ParticleSystemShapeType.Sphere;
        shape.radius = 0.1f;

        var colorOverLifetime = ps.colorOverLifetime;
        colorOverLifetime.enabled = true;
        var gradient = new Gradient();
        gradient.SetKeys(
            new[] { new GradientColorKey(new Color(1f, 0.3f, 0.1f), 0f), new GradientColorKey(new Color(1f, 0.1f, 0f), 1f) },
            new[] { new GradientAlphaKey(1f, 0f), new GradientAlphaKey(0f, 1f) }
        );
        colorOverLifetime.color = gradient;

        var renderer = go.GetComponent<ParticleSystemRenderer>();
        renderer.material = GetDefaultParticleMaterial();

        ps.Play();
    }

    public void SpawnHealEffect(Vector3 pos)
    {
        var go = CreateParticleObject("HealEffect", pos);
        var ps = go.GetComponent<ParticleSystem>();
        var main = ps.main;
        main.duration = 0.6f;
        main.startLifetime = 0.6f;
        main.startSpeed = 1.5f;
        main.startSize = 0.06f;
        main.startColor = new Color(0.2f, 1f, 0.3f, 1f);
        main.maxParticles = 8;
        main.loop = false;
        main.stopAction = ParticleSystemStopAction.Destroy;
        main.gravityModifier = -0.5f;

        var emission = ps.emission;
        emission.rateOverTime = 0;
        emission.SetBursts(new[] { new ParticleSystem.Burst(0f, 8) });

        var shape = ps.shape;
        shape.shapeType = ParticleSystemShapeType.Sphere;
        shape.radius = 0.15f;

        var vel = ps.velocityOverLifetime;
        vel.enabled = true;
        vel.y = 1.5f;

        var colorOverLifetime = ps.colorOverLifetime;
        colorOverLifetime.enabled = true;
        var gradient = new Gradient();
        gradient.SetKeys(
            new[] { new GradientColorKey(new Color(0.3f, 1f, 0.4f), 0f), new GradientColorKey(new Color(0.1f, 0.8f, 0.2f), 1f) },
            new[] { new GradientAlphaKey(1f, 0f), new GradientAlphaKey(0f, 1f) }
        );
        colorOverLifetime.color = gradient;

        var renderer = go.GetComponent<ParticleSystemRenderer>();
        renderer.material = GetDefaultParticleMaterial();

        ps.Play();
    }

    public void SpawnLevelUpEffect(Vector3 pos)
    {
        var go = CreateParticleObject("LevelUpEffect", pos);
        var ps = go.GetComponent<ParticleSystem>();
        var main = ps.main;
        main.duration = 0.8f;
        main.startLifetime = 0.8f;
        main.startSpeed = 2.5f;
        main.startSize = 0.1f;
        main.startColor = new Color(1f, 0.9f, 0.2f, 1f);
        main.maxParticles = 15;
        main.loop = false;
        main.stopAction = ParticleSystemStopAction.Destroy;

        var emission = ps.emission;
        emission.rateOverTime = 0;
        emission.SetBursts(new[] { new ParticleSystem.Burst(0f, 15) });

        var shape = ps.shape;
        shape.shapeType = ParticleSystemShapeType.Cone;
        shape.angle = 15f;
        shape.radius = 0.1f;
        shape.rotation = new Vector3(-90f, 0f, 0f);

        var colorOverLifetime = ps.colorOverLifetime;
        colorOverLifetime.enabled = true;
        var gradient = new Gradient();
        gradient.SetKeys(
            new[] { new GradientColorKey(new Color(1f, 1f, 0.5f), 0f), new GradientColorKey(new Color(1f, 0.8f, 0f), 1f) },
            new[] { new GradientAlphaKey(1f, 0f), new GradientAlphaKey(0f, 1f) }
        );
        colorOverLifetime.color = gradient;

        var sizeOverLifetime = ps.sizeOverLifetime;
        sizeOverLifetime.enabled = true;
        sizeOverLifetime.size = new ParticleSystem.MinMaxCurve(1f, new AnimationCurve(
            new Keyframe(0f, 1f), new Keyframe(1f, 0f)
        ));

        var renderer = go.GetComponent<ParticleSystemRenderer>();
        renderer.material = GetDefaultParticleMaterial();

        ps.Play();
    }

    public void SpawnGoldPickupEffect(Vector3 pos)
    {
        var go = CreateParticleObject("GoldPickupEffect", pos);
        var ps = go.GetComponent<ParticleSystem>();
        var main = ps.main;
        main.duration = 0.4f;
        main.startLifetime = 0.4f;
        main.startSpeed = 2f;
        main.startSize = 0.05f;
        main.startColor = new Color(1f, 0.84f, 0f, 1f);
        main.maxParticles = 6;
        main.loop = false;
        main.stopAction = ParticleSystemStopAction.Destroy;

        var emission = ps.emission;
        emission.rateOverTime = 0;
        emission.SetBursts(new[] { new ParticleSystem.Burst(0f, 6) });

        var shape = ps.shape;
        shape.shapeType = ParticleSystemShapeType.Sphere;
        shape.radius = 0.05f;

        var colorOverLifetime = ps.colorOverLifetime;
        colorOverLifetime.enabled = true;
        var gradient = new Gradient();
        gradient.SetKeys(
            new[] { new GradientColorKey(new Color(1f, 0.9f, 0.3f), 0f), new GradientColorKey(new Color(1f, 0.7f, 0f), 1f) },
            new[] { new GradientAlphaKey(1f, 0f), new GradientAlphaKey(0f, 1f) }
        );
        colorOverLifetime.color = gradient;

        var renderer = go.GetComponent<ParticleSystemRenderer>();
        renderer.material = GetDefaultParticleMaterial();

        ps.Play();
    }

    public void SpawnLightningEffect(Vector3 pos)
    {
        var go = CreateParticleObject("LightningEffect", pos);
        var ps = go.GetComponent<ParticleSystem>();
        var main = ps.main;
        main.duration = 0.25f;
        main.startLifetime = 0.25f;
        main.startSpeed = 5f;
        main.startSize = new ParticleSystem.MinMaxCurve(0.05f, 0.12f);
        main.startColor = new ParticleSystem.MinMaxGradient(
            new Color(0.6f, 0.85f, 1f, 1f),
            new Color(1f, 1f, 1f, 1f)
        );
        main.maxParticles = 12;
        main.loop = false;
        main.stopAction = ParticleSystemStopAction.Destroy;
        main.simulationSpeed = 2f;

        var emission = ps.emission;
        emission.rateOverTime = 0;
        emission.SetBursts(new[] { new ParticleSystem.Burst(0f, 12) });

        var shape = ps.shape;
        shape.shapeType = ParticleSystemShapeType.Sphere;
        shape.radius = 0.15f;

        var colorOverLifetime = ps.colorOverLifetime;
        colorOverLifetime.enabled = true;
        var gradient = new Gradient();
        gradient.SetKeys(
            new[] {
                new GradientColorKey(Color.white, 0f),
                new GradientColorKey(new Color(0.5f, 0.8f, 1f), 0.3f),
                new GradientColorKey(new Color(0.3f, 0.6f, 1f), 1f)
            },
            new[] {
                new GradientAlphaKey(1f, 0f),
                new GradientAlphaKey(1f, 0.2f),
                new GradientAlphaKey(0f, 1f)
            }
        );
        colorOverLifetime.color = gradient;

        var sizeOverLifetime = ps.sizeOverLifetime;
        sizeOverLifetime.enabled = true;
        sizeOverLifetime.size = new ParticleSystem.MinMaxCurve(1f, new AnimationCurve(
            new Keyframe(0f, 1f), new Keyframe(0.5f, 1.5f), new Keyframe(1f, 0f)
        ));

        var renderer = go.GetComponent<ParticleSystemRenderer>();
        renderer.material = GetDefaultParticleMaterial();

        ps.Play();
    }

    GameObject CreateParticleObject(string name, Vector3 pos)
    {
        var go = new GameObject(name);
        go.transform.position = pos;
        var ps = go.AddComponent<ParticleSystem>();
        ps.Stop(true, ParticleSystemStopBehavior.StopEmittingAndClear);
        return go;
    }

    Material _cachedParticleMaterial;

    Material GetDefaultParticleMaterial()
    {
        if (_cachedParticleMaterial == null)
            _cachedParticleMaterial = new Material(Shader.Find("Particles/Standard Unlit"));
        return _cachedParticleMaterial;
    }

    /// <summary>
    /// 보스 등장 이펙트 — 빨간 원형 충격파
    /// </summary>
    public void SpawnBossAppearEffect(Vector3 pos)
    {
        var go = CreateParticleObject("BossAppearEffect", pos);
        var ps = go.GetComponent<ParticleSystem>();
        var main = ps.main;
        main.duration = 1f;
        main.startLifetime = 0.8f;
        main.startSpeed = 4f;
        main.startSize = new ParticleSystem.MinMaxCurve(0.08f, 0.2f);
        main.startColor = new Color(1f, 0.15f, 0.1f, 1f);
        main.maxParticles = 30;
        main.loop = false;
        main.stopAction = ParticleSystemStopAction.Destroy;

        var emission = ps.emission;
        emission.rateOverTime = 0;
        emission.SetBursts(new[] { new ParticleSystem.Burst(0f, 30) });

        var shape = ps.shape;
        shape.shapeType = ParticleSystemShapeType.Circle;
        shape.radius = 0.5f;

        var colorOverLifetime = ps.colorOverLifetime;
        colorOverLifetime.enabled = true;
        var gradient = new Gradient();
        gradient.SetKeys(
            new[] { new GradientColorKey(new Color(1f, 0.3f, 0.1f), 0f), new GradientColorKey(new Color(0.8f, 0f, 0f), 1f) },
            new[] { new GradientAlphaKey(1f, 0f), new GradientAlphaKey(0f, 1f) }
        );
        colorOverLifetime.color = gradient;

        var sizeOverLifetime = ps.sizeOverLifetime;
        sizeOverLifetime.enabled = true;
        sizeOverLifetime.size = new ParticleSystem.MinMaxCurve(1f, new AnimationCurve(
            new Keyframe(0f, 0.5f), new Keyframe(0.3f, 1.5f), new Keyframe(1f, 0f)
        ));

        var renderer = go.GetComponent<ParticleSystemRenderer>();
        renderer.material = GetDefaultParticleMaterial();
        renderer.sortingOrder = 50;

        ps.Play();
    }

    /// <summary>
    /// 스킬 발동 이펙트 — 유닛 주변 링 파티클
    /// </summary>
    public void SpawnSkillActivateEffect(Vector3 pos, Color color)
    {
        var go = CreateParticleObject("SkillActivateEffect", pos);
        var ps = go.GetComponent<ParticleSystem>();
        var main = ps.main;
        main.duration = 0.5f;
        main.startLifetime = 0.5f;
        main.startSpeed = 2f;
        main.startSize = 0.06f;
        main.startColor = color;
        main.maxParticles = 12;
        main.loop = false;
        main.stopAction = ParticleSystemStopAction.Destroy;
        main.gravityModifier = -0.3f;

        var emission = ps.emission;
        emission.rateOverTime = 0;
        emission.SetBursts(new[] { new ParticleSystem.Burst(0f, 12) });

        var shape = ps.shape;
        shape.shapeType = ParticleSystemShapeType.Circle;
        shape.radius = 0.4f;

        var colorOverLifetime = ps.colorOverLifetime;
        colorOverLifetime.enabled = true;
        var gradient = new Gradient();
        gradient.SetKeys(
            new[] { new GradientColorKey(color, 0f), new GradientColorKey(Color.white, 1f) },
            new[] { new GradientAlphaKey(1f, 0f), new GradientAlphaKey(0f, 1f) }
        );
        colorOverLifetime.color = gradient;

        var renderer = go.GetComponent<ParticleSystemRenderer>();
        renderer.material = GetDefaultParticleMaterial();
        renderer.sortingOrder = 80;

        ps.Play();
    }

    /// <summary>
    /// 가챠 뽑기 이펙트 — 금빛 폭발
    /// </summary>
    public void SpawnGachaEffect(Vector3 pos)
    {
        var go = CreateParticleObject("GachaEffect", pos);
        var ps = go.GetComponent<ParticleSystem>();
        var main = ps.main;
        main.duration = 1.2f;
        main.startLifetime = 1f;
        main.startSpeed = 3f;
        main.startSize = new ParticleSystem.MinMaxCurve(0.05f, 0.15f);
        main.startColor = new Color(1f, 0.85f, 0.2f, 1f);
        main.maxParticles = 25;
        main.loop = false;
        main.stopAction = ParticleSystemStopAction.Destroy;

        var emission = ps.emission;
        emission.rateOverTime = 0;
        emission.SetBursts(new[] {
            new ParticleSystem.Burst(0f, 15),
            new ParticleSystem.Burst(0.2f, 10)
        });

        var shape = ps.shape;
        shape.shapeType = ParticleSystemShapeType.Cone;
        shape.angle = 30f;
        shape.radius = 0.2f;

        var colorOverLifetime = ps.colorOverLifetime;
        colorOverLifetime.enabled = true;
        var gradient = new Gradient();
        gradient.SetKeys(
            new[] { new GradientColorKey(new Color(1f, 1f, 0.6f), 0f), new GradientColorKey(new Color(1f, 0.7f, 0f), 1f) },
            new[] { new GradientAlphaKey(1f, 0f), new GradientAlphaKey(0f, 1f) }
        );
        colorOverLifetime.color = gradient;

        var renderer = go.GetComponent<ParticleSystemRenderer>();
        renderer.material = GetDefaultParticleMaterial();
        renderer.sortingOrder = 90;

        ps.Play();
    }

    void OnDestroy()
    {
        if (_cachedParticleMaterial != null)
            Destroy(_cachedParticleMaterial);
    }
}
