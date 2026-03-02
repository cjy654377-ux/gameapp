#!/usr/bin/env python3
"""
Pixel Art Asset Generator for GameApp
======================================
Draw Things HTTP API를 통해 픽셀아트 게임 에셋을 일괄 생성합니다.

사용법:
  python tools/generate_pixel_art.py --category monsters
  python tools/generate_pixel_art.py --category all
  python tools/generate_pixel_art.py --category monsters --ids slime,goblin
  python tools/generate_pixel_art.py --category all --dry-run
  python tools/generate_pixel_art.py --status  # Draw Things 연결 확인

필수 조건:
  - Draw Things 앱 실행 + API Server 활성화 (localhost:7860)
  - 픽셀아트 모델 로드 (예: Pixel Art XL, SD 1.5 pixel art checkpoint)
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import sys
import time
from io import BytesIO
from pathlib import Path
from typing import Optional

try:
    import requests
except ImportError:
    print("ERROR: requests 패키지가 필요합니다. pip install requests")
    sys.exit(1)

try:
    from PIL import Image
except ImportError:
    print("ERROR: Pillow 패키지가 필요합니다. pip install Pillow")
    sys.exit(1)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

SCRIPT_DIR = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent
PROMPTS_FILE = SCRIPT_DIR / "monster_prompts.json"
RAW_DIR = SCRIPT_DIR / "raw"
ASSETS_DIR = PROJECT_DIR / "assets" / "images"

DRAW_THINGS_URL = "http://127.0.0.1:7860"

# Default generation parameters
DEFAULT_PARAMS = {
    "width": 512,
    "height": 512,
    "steps": 20,      # SD 1.5: 20-25 steps
    "cfg": 7.0,       # SD 1.5: CFG 7 recommended
    "seed": -1,       # random
}

# ---------------------------------------------------------------------------
# Prompt Builder
# ---------------------------------------------------------------------------

def load_prompts() -> dict:
    with open(PROMPTS_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


def build_monster_prompt(meta: dict, monster: dict,
                         pose: str = "idle") -> tuple[str, str]:
    """Build positive and negative prompts for a monster.
    pose: 'idle' or 'attack'
    """
    size_prompt = meta["size_prompts"].get(monster["size"], "")
    rarity_detail = meta["rarity_detail"].get(str(monster["rarity"]), "")
    style_prefix = meta["style_prefix"]
    pose_suffix = meta["attack_suffix"] if pose == "attack" else meta["idle_suffix"]

    positive = (
        f"{style_prefix}, "
        f"{monster['description']}, "
        f"{size_prompt}, {rarity_detail}, "
        f"{pose_suffix}"
    )
    negative = meta["common_negative"]
    return positive, negative


def build_projectile_prompt(meta: dict, proj: dict) -> tuple[str, str]:
    positive = (
        f"pixel art, 16x16 game projectile sprite, side view, "
        f"{proj['description']}, "
        f"black background, centered, clean edges, crisp pixels, no anti-aliasing"
    )
    return positive, meta["common_negative"]


def build_background_prompt(meta: dict, bg: dict) -> tuple[str, str]:
    positive = (
        f"16bitscene, {bg['description']}, "
        f"side scrolling, dark fantasy tone, wide landscape"
    )
    return positive, meta["common_negative"]


def build_hero_prompt(meta: dict, hero: dict) -> tuple[str, str]:
    positive = (
        f"pixelsprite, {hero['description']}, "
        f"side view facing right, dark fantasy tone, white background, centered"
    )
    return positive, meta["common_negative"]


# ---------------------------------------------------------------------------
# Draw Things API Client
# ---------------------------------------------------------------------------

def check_connection() -> bool:
    """Check if Draw Things API is running."""
    try:
        r = requests.get(f"{DRAW_THINGS_URL}/sdapi/v1/options", timeout=5)
        return r.status_code == 200
    except Exception:
        return False


def generate_image(positive: str, negative: str, width: int = 512,
                   height: int = 512, steps: int = 20,
                   cfg: float = 7.5, seed: int = -1) -> Image.Image | None:
    """Call Draw Things API to generate an image."""
    payload = {
        "prompt": positive,
        "negative_prompt": negative,
        "width": width,
        "height": height,
        "steps": steps,
        "guidance_scale": cfg,
        "seed": seed,
    }

    try:
        r = requests.post(
            f"{DRAW_THINGS_URL}/sdapi/v1/txt2img",
            json=payload,
            timeout=300,
        )
        r.raise_for_status()
        data = r.json()

        # Draw Things returns base64 encoded images
        if "images" in data and data["images"]:
            img_data = base64.b64decode(data["images"][0])
            return Image.open(BytesIO(img_data))
        else:
            print(f"  WARNING: No images in response: {list(data.keys())}")
            return None

    except requests.exceptions.ConnectionError:
        print("  ERROR: Draw Things에 연결할 수 없습니다. API Server가 켜져있는지 확인하세요.")
        return None
    except Exception as e:
        print(f"  ERROR: {e}")
        return None


def generate_image_img2img(init_image: Image.Image, positive: str, negative: str,
                           denoising_strength: float = 0.5, width: int = 512,
                           height: int = 512, steps: int = 20,
                           cfg: float = 7.5, seed: int = -1) -> Image.Image | None:
    """Call Draw Things img2img API to generate a variation of an existing image."""
    # Encode init_image to base64
    buf = BytesIO()
    init_image.save(buf, format="PNG")
    buf.seek(0)
    init_b64 = base64.b64encode(buf.read()).decode("utf-8")

    payload = {
        "prompt": positive,
        "negative_prompt": negative,
        "init_images": [init_b64],
        "denoising_strength": denoising_strength,
        "width": width,
        "height": height,
        "steps": steps,
        "guidance_scale": cfg,
        "seed": seed,
    }

    try:
        r = requests.post(
            f"{DRAW_THINGS_URL}/sdapi/v1/img2img",
            json=payload,
            timeout=300,
        )
        r.raise_for_status()
        data = r.json()

        if "images" in data and data["images"]:
            img_data = base64.b64decode(data["images"][0])
            return Image.open(BytesIO(img_data))
        else:
            print(f"  WARNING: No images in img2img response: {list(data.keys())}")
            return None

    except requests.exceptions.ConnectionError:
        print("  ERROR: Draw Things에 연결할 수 없습니다.")
        return None
    except Exception as e:
        print(f"  ERROR (img2img): {e}")
        return None


# ---------------------------------------------------------------------------
# Post-Processing
# ---------------------------------------------------------------------------

def remove_background(img: Image.Image) -> Image.Image:
    """Remove background using rembg if available, otherwise use simple approach."""
    try:
        from rembg import remove
        # Convert to bytes, process, convert back
        buf = BytesIO()
        img.save(buf, format="PNG")
        buf.seek(0)
        result = remove(buf.read())
        return Image.open(BytesIO(result)).convert("RGBA")
    except ImportError:
        # Fallback: simple black background removal
        return remove_solid_background(img)


def remove_solid_background(img: Image.Image) -> Image.Image:
    """Simple background removal for pixel art on white or black bg."""
    img = img.convert("RGBA")
    data = img.getdata()
    new_data = []
    for pixel in data:
        r, g, b, a = pixel
        # White background removal (near-white)
        if r > 240 and g > 240 and b > 240:
            new_data.append((0, 0, 0, 0))
        # Black background removal (near-black)
        elif r < 15 and g < 15 and b < 15:
            new_data.append((0, 0, 0, 0))
        else:
            new_data.append(pixel)
    img.putdata(new_data)
    return img


def resize_nearest(img: Image.Image, target_w: int, target_h: int) -> Image.Image:
    """Resize using nearest-neighbor to preserve pixel art crispness."""
    return img.resize((target_w, target_h), Image.NEAREST)


def crop_to_content(img: Image.Image, padding: int = 2) -> Image.Image:
    """Crop image to non-transparent content with padding."""
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    bbox = img.getbbox()
    if bbox is None:
        return img
    x0, y0, x1, y1 = bbox
    x0 = max(0, x0 - padding)
    y0 = max(0, y0 - padding)
    x1 = min(img.width, x1 + padding)
    y1 = min(img.height, y1 + padding)
    return img.crop((x0, y0, x1, y1))


def make_square(img: Image.Image) -> Image.Image:
    """Pad image to make it square, centered."""
    w, h = img.size
    size = max(w, h)
    new_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    offset_x = (size - w) // 2
    offset_y = (size - h) // 2
    new_img.paste(img, (offset_x, offset_y), img)
    return new_img


# ---------------------------------------------------------------------------
# Generation Pipeline
# ---------------------------------------------------------------------------

def _post_process_sprite(img: Image.Image, target: int) -> Image.Image:
    """Common post-processing for monster/hero sprites."""
    img = remove_background(img)
    img = crop_to_content(img)
    img = make_square(img)
    img = resize_nearest(img, target, target)
    return img


def generate_monster(monster_id: str, monster: dict, meta: dict,
                     dry_run: bool = False, skip_existing: bool = True,
                     phase: str = "both") -> bool:
    """Generate idle + attack sprites for a single monster.
    phase: 'idle', 'attack', or 'both'
    """
    target = monster["target_px"]
    seed = hash(monster_id) % 2147483647
    denoising = meta.get("denoising_by_size", {}).get(monster["size"], 0.5)

    poses = []
    if phase in ("idle", "both"):
        poses.append("idle")
    if phase in ("attack", "both"):
        poses.append("attack")

    all_ok = True
    idle_raw_img = None

    for pose in poses:
        suffix = "" if pose == "idle" else f"_{pose}"
        output_path = ASSETS_DIR / "monsters" / f"{monster_id}{suffix}.png"
        raw_path = RAW_DIR / "monsters" / f"{monster_id}_{pose}_raw.png"

        if skip_existing and output_path.exists():
            try:
                check = Image.open(output_path)
                if check.size[0] > 1 and check.size[1] > 1:
                    print(f"  SKIP: {monster_id} ({pose}, already {check.size})")
                    # Load idle raw for potential attack img2img
                    if pose == "idle":
                        idle_raw = RAW_DIR / "monsters" / f"{monster_id}_idle_raw.png"
                        if idle_raw.exists():
                            idle_raw_img = Image.open(idle_raw)
                    continue
            except Exception:
                pass

        positive, negative = build_monster_prompt(meta, monster, pose)

        if dry_run:
            print(f"  [DRY RUN] {monster_id} ({pose})")
            print(f"    Prompt: {positive[:140]}...")
            continue

        print(f"  Generating: {monster_id} ({pose}, {monster['size']}, {monster['element']}, {monster['rarity']}★)...")

        if pose == "idle":
            # txt2img for idle
            img = generate_image(positive, negative,
                                 width=DEFAULT_PARAMS["width"],
                                 height=DEFAULT_PARAMS["height"],
                                 steps=DEFAULT_PARAMS["steps"],
                                 cfg=DEFAULT_PARAMS["cfg"],
                                 seed=seed)
            if img is None:
                all_ok = False
                continue
            idle_raw_img = img.copy()
        else:
            # attack: img2img from idle raw image
            if idle_raw_img is None:
                # Try to load from saved raw
                idle_raw_path = RAW_DIR / "monsters" / f"{monster_id}_idle_raw.png"
                if idle_raw_path.exists():
                    idle_raw_img = Image.open(idle_raw_path)
                else:
                    # No idle available, generate idle first
                    print(f"    → idle raw not found, generating idle first...")
                    idle_pos, idle_neg = build_monster_prompt(meta, monster, "idle")
                    idle_raw_img = generate_image(
                        idle_pos, idle_neg,
                        width=DEFAULT_PARAMS["width"],
                        height=DEFAULT_PARAMS["height"],
                        steps=DEFAULT_PARAMS["steps"],
                        cfg=DEFAULT_PARAMS["cfg"],
                        seed=seed)
                    if idle_raw_img is None:
                        print(f"    → idle 생성 실패, attack 스킵")
                        all_ok = False
                        continue
                    # Save idle raw
                    idle_raw_save = RAW_DIR / "monsters" / f"{monster_id}_idle_raw.png"
                    idle_raw_save.parent.mkdir(parents=True, exist_ok=True)
                    idle_raw_img.save(idle_raw_save)

            img = generate_image_img2img(
                idle_raw_img, positive, negative,
                denoising_strength=denoising,
                width=DEFAULT_PARAMS["width"],
                height=DEFAULT_PARAMS["height"],
                steps=DEFAULT_PARAMS["steps"],
                cfg=DEFAULT_PARAMS["cfg"],
                seed=seed)
            if img is None:
                all_ok = False
                continue

        # Save raw
        raw_path.parent.mkdir(parents=True, exist_ok=True)
        img.save(raw_path)

        # Post-process
        processed = _post_process_sprite(img, target)

        output_path.parent.mkdir(parents=True, exist_ok=True)
        processed.save(output_path, "PNG")
        print(f"  OK: {monster_id}_{pose} → {target}x{target}px")

        time.sleep(1)  # small delay between poses

    return all_ok


def generate_projectile(element: str, proj: dict, meta: dict,
                        dry_run: bool = False) -> bool:
    """Generate a single projectile sprite."""
    output_path = ASSETS_DIR / "effects" / f"projectile_{element}.png"
    raw_path = RAW_DIR / "projectiles" / f"{element}_raw.png"

    positive, negative = build_projectile_prompt(meta, proj)

    if dry_run:
        print(f"  [DRY RUN] projectile_{element}")
        return True

    print(f"  Generating projectile: {element}...")
    img = generate_image(positive, negative, width=256, height=256, steps=15)
    if img is None:
        return False

    raw_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(raw_path)

    img = remove_background(img)
    img = crop_to_content(img)
    img = make_square(img)
    img = resize_nearest(img, 16, 16)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(output_path, "PNG")
    print(f"  OK: projectile_{element} → {output_path}")
    return True


def generate_background(bg_id: str, bg: dict, meta: dict,
                        dry_run: bool = False) -> bool:
    """Generate a single background image."""
    output_path = ASSETS_DIR / "backgrounds" / f"{bg_id}.png"
    raw_path = RAW_DIR / "backgrounds" / f"{bg_id}_raw.png"

    positive, negative = build_background_prompt(meta, bg)
    target_w, target_h = bg["target_size"]

    if dry_run:
        print(f"  [DRY RUN] bg: {bg_id}")
        return True

    print(f"  Generating background: {bg_id}...")
    # Generate at 16:9 aspect ratio
    img = generate_image(positive, negative, width=768, height=432, steps=25)
    if img is None:
        return False

    raw_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(raw_path)

    # Resize to target (no bg removal for backgrounds)
    img = resize_nearest(img, target_w, target_h)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(output_path, "PNG")
    print(f"  OK: {bg_id} → {output_path} ({target_w}x{target_h})")
    return True


def generate_hero_asset(hero_id: str, hero: dict, meta: dict,
                        dry_run: bool = False) -> bool:
    """Generate hero portrait or full body."""
    hero_dir = ASSETS_DIR / "hero"
    output_path = hero_dir / f"{hero_id}.png"
    raw_path = RAW_DIR / "hero" / f"{hero_id}_raw.png"

    positive, negative = build_hero_prompt(meta, hero)

    if dry_run:
        print(f"  [DRY RUN] hero: {hero_id}")
        return True

    print(f"  Generating hero: {hero_id}...")

    if "target_size" in hero:
        w, h = hero["target_size"]
        gen_w, gen_h = 384, 768  # portrait aspect
    else:
        w = h = hero["target_px"]
        gen_w = gen_h = 512

    img = generate_image(positive, negative, width=gen_w, height=gen_h)
    if img is None:
        return False

    raw_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(raw_path)

    img = remove_background(img)
    img = crop_to_content(img)
    if "target_size" in hero:
        img = resize_nearest(img, w, h)
    else:
        img = make_square(img)
        img = resize_nearest(img, w, h)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(output_path, "PNG")
    print(f"  OK: hero/{hero_id} → {output_path}")
    return True


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Pixel Art Asset Generator for GameApp")
    parser.add_argument("--category", choices=["monsters", "projectiles", "backgrounds", "hero", "all"],
                        default="all", help="에셋 카테고리")
    parser.add_argument("--ids", type=str, default=None,
                        help="특정 ID만 생성 (쉼표 구분, 예: slime,goblin)")
    parser.add_argument("--dry-run", action="store_true",
                        help="프롬프트만 출력하고 실제 생성하지 않음")
    parser.add_argument("--no-skip", action="store_true",
                        help="기존 이미지가 있어도 재생성")
    parser.add_argument("--status", action="store_true",
                        help="Draw Things 연결 상태 확인")
    parser.add_argument("--delay", type=float, default=1.0,
                        help="생성 간 딜레이(초)")
    parser.add_argument("--steps", type=int, default=20,
                        help="Sampling steps")
    parser.add_argument("--cfg", type=float, default=7.5,
                        help="CFG scale")
    args = parser.parse_args()

    # Update defaults
    DEFAULT_PARAMS["steps"] = args.steps
    DEFAULT_PARAMS["cfg"] = args.cfg

    if args.status:
        connected = check_connection()
        if connected:
            print("Draw Things API: CONNECTED (localhost:7860)")
        else:
            print("Draw Things API: NOT CONNECTED")
            print("  → Draw Things 앱 실행 후 설정 → API Server 활성화")
        return

    # Load prompts
    data = load_prompts()
    meta = data["_meta"]

    # Check connection (unless dry-run)
    if not args.dry_run and not check_connection():
        print("ERROR: Draw Things API에 연결할 수 없습니다.")
        print("  1. Draw Things 앱 실행")
        print("  2. 설정(⚙️) → API Server 활성화")
        print("  3. 포트: 7860 확인")
        sys.exit(1)

    filter_ids = set(args.ids.split(",")) if args.ids else None
    skip_existing = not args.no_skip
    total = 0
    success = 0

    # Monsters — idle first, then attack (img2img needs idle as base)
    if args.category in ("monsters", "all"):
        monster_items = [(mid, m) for mid, m in data["monsters"].items()
                         if not filter_ids or mid in filter_ids]

        if monster_items:
            print("\n=== MONSTERS (idle) ===")
            for mid, m in monster_items:
                total += 1
                if generate_monster(mid, m, meta, args.dry_run, skip_existing, phase="idle"):
                    success += 1
                if not args.dry_run:
                    time.sleep(args.delay)

            print("\n=== MONSTERS (attack via img2img) ===")
            for mid, m in monster_items:
                generate_monster(mid, m, meta, args.dry_run, skip_existing, phase="attack")
                if not args.dry_run:
                    time.sleep(args.delay)

    # Projectiles
    if args.category in ("projectiles", "all"):
        print("\n=== PROJECTILES ===")
        for element, proj in data["projectiles"].items():
            if filter_ids and element not in filter_ids:
                continue
            total += 1
            if generate_projectile(element, proj, meta, args.dry_run):
                success += 1
            if not args.dry_run:
                time.sleep(args.delay)

    # Backgrounds
    if args.category in ("backgrounds", "all"):
        print("\n=== BACKGROUNDS ===")
        for bg_id, bg in data["backgrounds"].items():
            if filter_ids and bg_id not in filter_ids:
                continue
            total += 1
            if generate_background(bg_id, bg, meta, args.dry_run):
                success += 1
            if not args.dry_run:
                time.sleep(args.delay)

    # Hero
    if args.category in ("hero", "all"):
        print("\n=== HERO ===")
        for hero_id, hero in data["hero"].items():
            if filter_ids and hero_id not in filter_ids:
                continue
            total += 1
            if generate_hero_asset(hero_id, hero, meta, args.dry_run):
                success += 1
            if not args.dry_run:
                time.sleep(args.delay)

    print(f"\n=== COMPLETE: {success}/{total} assets generated ===")


if __name__ == "__main__":
    main()
