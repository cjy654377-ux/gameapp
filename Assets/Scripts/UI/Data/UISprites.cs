using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// SPUM Retro GUI Pack 스프라이트 런타임 로드 + 캐싱 유틸리티.
/// CopyGUISprites 에디터 툴로 Resources/UI/ 폴더에 복사 후 사용.
/// 스프라이트가 없을 경우 null을 반환하며, UI는 단색 폴백으로 렌더링됨.
/// </summary>
public static class UISprites
{
    static readonly Dictionary<string, Sprite> cache = new();

    // ── Gauge / Bar ────────────────────────────────────────────
    public static Sprite BossHP_BG   => Load("UI/Boss_HP_Gauge1");
    public static Sprite BossHP_Fill => Load("UI/Boss_HP_Gauge2");
    public static Sprite EXP_BG      => Load("UI/EXP_Gauge1");
    public static Sprite EXP_Fill    => Load("UI/EXP_Gauge2");

    // ── Board / Panel ──────────────────────────────────────────
    public static Sprite Board       => Load("UI/Board_20x20");
    public static Sprite BoxBasic1   => Load("UI/Box_Basic1");
    public static Sprite BoxBasic3   => Load("UI/Box_Basic3");
    public static Sprite BoxBanner   => Load("UI/Box_Banner");
    public static Sprite BoxIcon1    => Load("UI/Box_Icon1");
    public static Sprite BoxProfile  => Load("UI/Box_Profile");


    // ── Button ─────────────────────────────────────────────────
    /// 기본 버튼 (Wide Stretch 변형)
    public static Sprite Btn1_WS     => Load("UI/Button_Basic1_WS");
    public static Sprite Btn2_WS     => Load("UI/Button_Basic2_WS");
    public static Sprite Btn3_WS     => Load("UI/Button_Basic3_WS");
    public static Sprite Btn4_WS     => Load("UI/Button_Basic4_WS");

    /// 닫기 버튼
    public static Sprite BtnX        => Load("UI/Button_X");



    // ── Icons (Theme1 / Basic) ─────────────────────────────────
    public static Sprite IconGold      => Load("UI/Icon_Gold");
    public static Sprite IconDiamond   => Load("UI/Icon_Diamond");
    public static Sprite IconInven     => Load("UI/Icon_Inven");
    public static Sprite IconQuest     => Load("UI/Icon_Quest");
    public static Sprite IconSkill     => Load("UI/Icon_Skill");
    public static Sprite IconSword     => Load("UI/Icon_Sword");
    public static Sprite IconPotion1   => Load("UI/Icon_Potion1");
    public static Sprite IconPotion2   => Load("UI/Icon_Potion2");
    public static Sprite IconSetting   => Load("UI/Icon_Setting");
    public static Sprite IconEquip     => Load("UI/Icon_Equip");
    public static Sprite IconPost      => Load("UI/Icon_Post");
    public static Sprite IconMoney     => Load("UI/Icon_Money");
    public static Sprite IconTime      => Load("UI/Icon_Time");

    // ── Icons (Theme2 / System) ────────────────────────────────
    /// 숫자 인덱스 아이콘 (Spum_Icon131 ~ Spum_Icon207). 범위 밖이면 null.
    public static Sprite SpumIcon(int index)
    {
        if (index < 131 || index > 207) return null;
        return Load($"UI/Spum_Icon{index}");
    }

    // ── Flat (White) Icons ─────────────────────────────────────
    /// Icon_Flat__1 ~ Icon_Flat__51. 범위 밖이면 null.
    public static Sprite FlatIcon(int index)
    {
        if (index < 1 || index > 51) return null;
        return Load($"UI/Icon_Flat__{index}");
    }

    // ── 편의 메서드: 스프라이트 존재 여부 확인 ──────────────────
    public static bool Has(string path) => Load(path) != null;

    // ── 내부 캐싱 로더 ─────────────────────────────────────────
    static Sprite Load(string path)
    {
        if (!cache.TryGetValue(path, out Sprite s))
        {
            s = Resources.Load<Sprite>(path);
            cache[path] = s; // null도 캐싱해서 반복 로드 방지
        }
        return s;
    }

    /// 캐시 강제 초기화 (씬 전환 시 호출 가능)
    public static void ClearCache() => cache.Clear();
}
