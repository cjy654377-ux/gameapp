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
    public static Sprite HPBar_BG    => Load("UI/HP_Gauge1");
    public static Sprite HPBar_Fill  => Load("UI/HP_Gauge2");
    public static Sprite BossHP_BG   => Load("UI/Boss_HP_Gauge1");
    public static Sprite BossHP_Fill => Load("UI/Boss_HP_Gauge2");
    public static Sprite EXP_BG      => Load("UI/EXP_Gauge1");
    public static Sprite EXP_Fill    => Load("UI/EXP_Gauge2");
    public static Sprite MP_BG       => Load("UI/MP_Gauge1");
    public static Sprite MP_Fill     => Load("UI/MP_Gauge2");

    // ── Board / Panel ──────────────────────────────────────────
    public static Sprite Board       => Load("UI/Board_20x20");
    public static Sprite BasicBG     => Load("UI/Basic_BG");
    public static Sprite BoxBasic1   => Load("UI/Box_Basic1");
    public static Sprite BoxBasic2   => Load("UI/Box_Basic2");
    public static Sprite BoxBasic3   => Load("UI/Box_Basic3");
    public static Sprite BoxBanner   => Load("UI/Box_Banner");
    public static Sprite BoxIcon1    => Load("UI/Box_Icon1");
    public static Sprite BoxIcon2    => Load("UI/Box_Icon2");
    public static Sprite BoxProfile  => Load("UI/Box_Profile");
    public static Sprite BoxInside   => Load("UI/Box_Inside");
    public static Sprite TitleInven  => Load("UI/Title_Inven");

    // ── Inventory ─────────────────────────────────────────────
    public static Sprite BoxInven    => Load("UI/Box_Inven");
    public static Sprite BoxInven_WS => Load("UI/Box_Inven_WS");

    // ── Button ─────────────────────────────────────────────────
    /// 기본 버튼 (Normal 상태, 15×15 슬라이스용)
    public static Sprite Btn1_15     => Load("UI/Button_Basic1_15x15");
    public static Sprite Btn2_15     => Load("UI/Button_Basic2_15x15");
    public static Sprite Btn3_15     => Load("UI/Button_Basic3_15x15");
    public static Sprite Btn4_15     => Load("UI/Button_Basic4_15x15");

    /// 기본 버튼 (Wide Stretch 변형)
    public static Sprite Btn1_WS     => Load("UI/Button_Basic1_WS");
    public static Sprite Btn2_WS     => Load("UI/Button_Basic2_WS");
    public static Sprite Btn3_WS     => Load("UI/Button_Basic3_WS");
    public static Sprite Btn4_WS     => Load("UI/Button_Basic4_WS");

    /// 아이콘 버튼 / 닫기 버튼
    public static Sprite BtnIcon1    => Load("UI/Button_Icon1");
    public static Sprite BtnIcon2    => Load("UI/Button_Icon2");
    public static Sprite BtnX        => Load("UI/Button_X");
    public static Sprite BtnX_WS     => Load("UI/Button_X_WS");
    public static Sprite BtnAuto     => Load("UI/Image_Auto");

    // ── Special Images ─────────────────────────────────────────
    public static Sprite ImageBoss    => Load("UI/Image_Boss");
    public static Sprite ImageSelect1 => Load("UI/Image_Select1");
    public static Sprite ImageSelect2 => Load("UI/Image_Select2");
    public static Sprite ImageAlarm   => Load("UI/Image_Alarm");

    // ── Result Screen ──────────────────────────────────────────
    public static Sprite ResultVictory   => Load("UI/Image_Victory");
    public static Sprite ResultFail      => Load("UI/Image_Fail");
    public static Sprite ResultBoard     => Load("UI/ResultBoard_111x90");
    public static Sprite ResultLvGauge1  => Load("UI/Level_Guage1");
    public static Sprite ResultLvGauge2  => Load("UI/Level_Guage2");
    public static Sprite ResultSelect    => Load("UI/Image_Select");
    public static Sprite BtnHome        => Load("UI/Button_Home");
    public static Sprite BtnRetry       => Load("UI/Button_Retry");
    public static Sprite BtnNext        => Load("UI/Button_next");

    // ── Icons (Theme1 / Basic) ─────────────────────────────────
    public static Sprite IconGold      => Load("UI/Icon_Gold");
    public static Sprite IconDiamond   => Load("UI/Icon_Diamond");
    public static Sprite IconEquip     => Load("UI/Icon_Equip");
    public static Sprite IconEquip_WS  => Load("UI/Icon_Equip_WS");
    public static Sprite IconInven     => Load("UI/Icon_Inven");
    public static Sprite IconInven_WS  => Load("UI/Icon_Inven_WS");
    public static Sprite IconQuest     => Load("UI/Icon_Quest");
    public static Sprite IconQuest_WS  => Load("UI/Icon_Quest_WS");
    public static Sprite IconSetting   => Load("UI/Icon_Setting");
    public static Sprite IconSetting_WS => Load("UI/Icon_Setting_WS");
    public static Sprite IconSkill     => Load("UI/Icon_Skill");
    public static Sprite IconSkill_WS  => Load("UI/Icon_Skill_WS");
    public static Sprite IconSword     => Load("UI/Icon_Sword");
    public static Sprite IconPost      => Load("UI/Icon_Post");
    public static Sprite IconPost_WS   => Load("UI/Icon_Post_WS");
    public static Sprite IconPotion1   => Load("UI/Icon_Potion1");
    public static Sprite IconPotion1_WS => Load("UI/Icon_Potion1_WS");
    public static Sprite IconPotion2   => Load("UI/Icon_Potion2");
    public static Sprite IconPotion2_WS => Load("UI/Icon_Potion2_WS");
    public static Sprite IconMoney     => Load("UI/Icon_Money");
    public static Sprite IconTime      => Load("UI/Icon_Time");

    // ── RPG GUI Atlas (커스텀 아틀라스) ──────────────────────────
    public static Sprite GUI_HPBar_Frame    => LoadAtlas("GUI_HPBar_Frame");
    public static Sprite GUI_HPBar_Fill     => LoadAtlas("GUI_HPBar_Fill");
    public static Sprite GUI_EXPBar_Frame   => LoadAtlas("GUI_EXPBar_Frame");
    public static Sprite GUI_EXPBar_Fill    => LoadAtlas("GUI_EXPBar_Fill");
    public static Sprite GUI_CoinIcon       => LoadAtlas("GUI_CoinIcon");
    public static Sprite GUI_DiamondIcon    => LoadAtlas("GUI_DiamondIcon");
    public static Sprite GUI_Panel_Large    => LoadAtlas("GUI_Panel_Large");
    public static Sprite GUI_Panel_Parchment => LoadAtlas("GUI_Panel_Parchment");
    public static Sprite GUI_TitleBar       => LoadAtlas("GUI_TitleBar");
    public static Sprite GUI_ItemSlot       => LoadAtlas("GUI_ItemSlot");
    public static Sprite GUI_BottomBar      => LoadAtlas("GUI_BottomBar");
    public static Sprite GUI_TabSlot        => LoadAtlas("GUI_TabSlot");

    // ── Tab Icons (Extra 아이콘) ─────────────────────────────────
    public static Sprite TabIcon_Train    => Load("UI/Tab_Icon_34"); // 망치 (훈련)
    public static Sprite TabIcon_Enhance  => Load("UI/Tab_Icon_35"); // 도끼 (강화)
    public static Sprite TabIcon_Deck     => Load("UI/Tab_Icon_31"); // 교차검 (편성)
    public static Sprite TabIcon_Summon   => Load("UI/Tab_Icon_22"); // 별 (소환)
    public static Sprite TabIcon_Shop     => Load("UI/Tab_Icon_9");  // 돈주머니 (상점)

    // ── Skill Icons ─────────────────────────────────────────────
    public static Sprite SkillIcon1 => Load("UI/Icon_Skill_1");
    public static Sprite SkillIcon2 => Load("UI/Icon_Skill_2");
    public static Sprite SkillIcon3 => Load("UI/Icon_Skill_3");
    public static Sprite SkillIcon4 => Load("UI/Icon_Skill_4");

    /// 스킬 효과 타입별 아이콘 매핑
    public static Sprite GetSkillIcon(SkillEffectType type)
    {
        return type switch
        {
            SkillEffectType.Damage   => SkillIcon1,  // 화염
            SkillEffectType.Burn     => SkillIcon1,  // 화염
            SkillEffectType.Freeze   => SkillIcon4,  // 번개/얼음
            SkillEffectType.Poison   => SkillIcon2,  // 독
            SkillEffectType.Slow     => SkillIcon4,  // 번개
            SkillEffectType.Heal     => SkillIcon3,  // 힐
            SkillEffectType.Buff_Atk => SkillIcon1,  // 공격 버프
            SkillEffectType.Buff_Def => SkillIcon3,  // 방어 버프
            _                        => SkillIcon1
        };
    }

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
            cache[path] = s;
        }
        return s;
    }

    static Sprite LoadAtlas(string spriteName)
    {
        string key = $"atlas_{spriteName}";
        if (!cache.TryGetValue(key, out Sprite s))
        {
            // 아틀라스에서 이름으로 서브스프라이트 로드
            var all = Resources.LoadAll<Sprite>("UI/CustomGUI/RPG_GUI_Atlas");
            s = null;
            if (all != null)
            {
                for (int i = 0; i < all.Length; i++)
                {
                    if (all[i].name == spriteName)
                    {
                        s = all[i];
                        break;
                    }
                }
            }
            cache[key] = s;
        }
        return s;
    }

    /// 캐시 강제 초기화 (씬 전환 시 호출 가능)
    public static void ClearCache() => cache.Clear();
}
