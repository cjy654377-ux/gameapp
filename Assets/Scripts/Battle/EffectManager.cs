using UnityEngine;

public class EffectManager : MonoBehaviour
{
    public static EffectManager Instance { get; private set; }

    // Cached gradients (allocated once, reused forever)
    static Gradient hitGradient;
    static Gradient healGradient;
    static Gradient levelUpGradient;
    static Gradient goldGradient;
    static Gradient lightningGradient;
    static Gradient bossGradient;
    static Gradient gachaGradient;
    static AnimationCurve shrinkCurve;
    static AnimationCurve pulseCurve;
    static AnimationCurve lightningCurve;

    Material _cachedParticleMaterial;

    void Awake()
    {
        if (Instance != null && Instance != this) { Destroy(gameObject); return; }
        Instance = this;
        EnsureGradients();
    }

    static void EnsureGradients()
    {
        if (hitGradient != null) return;

        hitGradient = MakeGradient(
            new Color(1f, 0.3f, 0.1f), new Color(1f, 0.1f, 0f));
        healGradient = MakeGradient(
            new Color(0.3f, 1f, 0.4f), new Color(0.1f, 0.8f, 0.2f));
        levelUpGradient = MakeGradient(
            new Color(1f, 1f, 0.5f), new Color(1f, 0.8f, 0f));
        goldGradient = MakeGradient(
            new Color(1f, 0.9f, 0.3f), new Color(1f, 0.7f, 0f));
        bossGradient = MakeGradient(
            new Color(1f, 0.3f, 0.1f), new Color(0.8f, 0f, 0f));
        gachaGradient = MakeGradient(
            new Color(1f, 1f, 0.6f), new Color(1f, 0.7f, 0f));

        lightningGradient = new Gradient();
        lightningGradient.SetKeys(
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

        shrinkCurve = new AnimationCurve(
            new Keyframe(0f, 1f), new Keyframe(1f, 0f));
        pulseCurve = new AnimationCurve(
            new Keyframe(0f, 0.5f), new Keyframe(0.3f, 1.5f), new Keyframe(1f, 0f));
        lightningCurve = new AnimationCurve(
            new Keyframe(0f, 1f), new Keyframe(0.5f, 1.5f), new Keyframe(1f, 0f));
    }

    static Gradient MakeGradient(Color start, Color end)
    {
        var g = new Gradient();
        g.SetKeys(
            new[] { new GradientColorKey(start, 0f), new GradientColorKey(end, 1f) },
            new[] { new GradientAlphaKey(1f, 0f), new GradientAlphaKey(0f, 1f) }
        );
        return g;
    }

    // ═══ Public API ═══

    public void SpawnHitEffect(Vector3 pos)
    {
        SpawnBurst(pos, new EffectConfig
        {
            name = "HitEffect",
            duration = 0.3f,
            speed = 3f,
            size = 0.08f,
            color = new Color(1f, 0.2f, 0.1f),
            count = 10,
            shapeType = ParticleSystemShapeType.Sphere,
            radius = 0.1f,
            gradient = hitGradient,
        });
    }

    public void SpawnHealEffect(Vector3 pos)
    {
        SpawnBurst(pos, new EffectConfig
        {
            name = "HealEffect",
            duration = 0.6f,
            speed = 1.5f,
            size = 0.06f,
            color = new Color(0.2f, 1f, 0.3f),
            count = 8,
            shapeType = ParticleSystemShapeType.Sphere,
            radius = 0.15f,
            gradient = healGradient,
            gravity = -0.5f,
            velocityY = 1.5f,
        });
    }

    public void SpawnLevelUpEffect(Vector3 pos)
    {
        SpawnBurst(pos, new EffectConfig
        {
            name = "LevelUpEffect",
            duration = 0.8f,
            speed = 2.5f,
            size = 0.1f,
            color = new Color(1f, 0.9f, 0.2f),
            count = 15,
            shapeType = ParticleSystemShapeType.Cone,
            radius = 0.1f,
            coneAngle = 15f,
            shapeRotation = new Vector3(-90f, 0f, 0f),
            gradient = levelUpGradient,
            sizeCurve = shrinkCurve,
        });
    }

    public void SpawnGoldPickupEffect(Vector3 pos)
    {
        SpawnBurst(pos, new EffectConfig
        {
            name = "GoldPickupEffect",
            duration = 0.4f,
            speed = 2f,
            size = 0.05f,
            color = new Color(1f, 0.84f, 0f),
            count = 6,
            shapeType = ParticleSystemShapeType.Sphere,
            radius = 0.05f,
            gradient = goldGradient,
        });
    }

    public void SpawnLightningEffect(Vector3 pos)
    {
        SpawnBurst(pos, new EffectConfig
        {
            name = "LightningEffect",
            duration = 0.25f,
            speed = 5f,
            size = 0.08f,
            color = new Color(0.6f, 0.85f, 1f),
            count = 12,
            shapeType = ParticleSystemShapeType.Sphere,
            radius = 0.15f,
            gradient = lightningGradient,
            simulationSpeed = 2f,
            sizeCurve = lightningCurve,
        });
    }

    public void SpawnBossAppearEffect(Vector3 pos)
    {
        SpawnBurst(pos, new EffectConfig
        {
            name = "BossAppearEffect",
            duration = 1f,
            speed = 4f,
            size = 0.14f,
            color = new Color(1f, 0.15f, 0.1f),
            count = 30,
            shapeType = ParticleSystemShapeType.Circle,
            radius = 0.5f,
            gradient = bossGradient,
            sizeCurve = pulseCurve,
            sortingOrder = 50,
        });
    }

    public void SpawnSkillActivateEffect(Vector3 pos, Color color)
    {
        // Dynamic gradient for skill color
        var grad = MakeGradient(color, Color.white);

        SpawnBurst(pos, new EffectConfig
        {
            name = "SkillActivateEffect",
            duration = 0.5f,
            speed = 2f,
            size = 0.06f,
            color = color,
            count = 12,
            shapeType = ParticleSystemShapeType.Circle,
            radius = 0.4f,
            gradient = grad,
            gravity = -0.3f,
            sortingOrder = 80,
        });
    }

    public void SpawnGachaEffect(Vector3 pos)
    {
        var go = CreateParticleObject("GachaEffect", pos);
        var ps = go.GetComponent<ParticleSystem>();
        var main = ps.main;
        main.duration = 1.2f;
        main.startLifetime = 1f;
        main.startSpeed = 3f;
        main.startSize = new ParticleSystem.MinMaxCurve(0.05f, 0.15f);
        main.startColor = new Color(1f, 0.85f, 0.2f);
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

        ApplyGradient(ps, gachaGradient);

        var renderer = go.GetComponent<ParticleSystemRenderer>();
        renderer.material = GetDefaultParticleMaterial();
        renderer.sortingOrder = 90;

        ps.Play();
    }

    // ═══ Common burst spawner ═══

    struct EffectConfig
    {
        public string name;
        public float duration;
        public float speed;
        public float size;
        public Color color;
        public int count;
        public ParticleSystemShapeType shapeType;
        public float radius;
        public float coneAngle;
        public Vector3 shapeRotation;
        public Gradient gradient;
        public float gravity;
        public float velocityY;
        public float simulationSpeed;
        public AnimationCurve sizeCurve;
        public int sortingOrder;
    }

    void SpawnBurst(Vector3 pos, EffectConfig cfg)
    {
        var go = CreateParticleObject(cfg.name, pos);
        var ps = go.GetComponent<ParticleSystem>();

        var main = ps.main;
        main.duration = cfg.duration;
        main.startLifetime = cfg.duration;
        main.startSpeed = cfg.speed;
        main.startSize = cfg.size;
        main.startColor = cfg.color;
        main.maxParticles = cfg.count;
        main.loop = false;
        main.stopAction = ParticleSystemStopAction.Destroy;

        if (cfg.gravity != 0f) main.gravityModifier = cfg.gravity;
        if (cfg.simulationSpeed > 0f) main.simulationSpeed = cfg.simulationSpeed;

        var emission = ps.emission;
        emission.rateOverTime = 0;
        emission.SetBursts(new[] { new ParticleSystem.Burst(0f, (short)cfg.count) });

        var shape = ps.shape;
        shape.shapeType = cfg.shapeType;
        shape.radius = cfg.radius;
        if (cfg.coneAngle > 0f) shape.angle = cfg.coneAngle;
        if (cfg.shapeRotation != Vector3.zero) shape.rotation = cfg.shapeRotation;

        if (cfg.velocityY != 0f)
        {
            var vel = ps.velocityOverLifetime;
            vel.enabled = true;
            vel.y = cfg.velocityY;
        }

        if (cfg.gradient != null)
            ApplyGradient(ps, cfg.gradient);

        if (cfg.sizeCurve != null)
        {
            var sol = ps.sizeOverLifetime;
            sol.enabled = true;
            sol.size = new ParticleSystem.MinMaxCurve(1f, cfg.sizeCurve);
        }

        var renderer = go.GetComponent<ParticleSystemRenderer>();
        renderer.material = GetDefaultParticleMaterial();
        if (cfg.sortingOrder > 0) renderer.sortingOrder = cfg.sortingOrder;

        ps.Play();
    }

    static void ApplyGradient(ParticleSystem ps, Gradient gradient)
    {
        var col = ps.colorOverLifetime;
        col.enabled = true;
        col.color = gradient;
    }

    GameObject CreateParticleObject(string name, Vector3 pos)
    {
        var go = new GameObject(name);
        go.transform.position = pos;
        var ps = go.AddComponent<ParticleSystem>();
        ps.Stop(true, ParticleSystemStopBehavior.StopEmittingAndClear);
        return go;
    }

    Material GetDefaultParticleMaterial()
    {
        if (_cachedParticleMaterial == null)
            _cachedParticleMaterial = new Material(Shader.Find("Particles/Standard Unlit"));
        return _cachedParticleMaterial;
    }

    void OnDestroy()
    {
        if (Instance == this) Instance = null;
        if (_cachedParticleMaterial != null)
            Destroy(_cachedParticleMaterial);
    }

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
    static void ResetStatics()
    {
        hitGradient = null;
        healGradient = null;
        levelUpGradient = null;
        goldGradient = null;
        lightningGradient = null;
        bossGradient = null;
        gachaGradient = null;
        shrinkCurve = null;
        pulseCurve = null;
        lightningCurve = null;
    }
}
