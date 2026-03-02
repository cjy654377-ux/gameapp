#!/usr/bin/env python3
"""
Post-Processing Script for Pixel Art Assets
=============================================
tools/raw/ 폴더의 원본 이미지를 후처리하여 최종 에셋으로 변환합니다.
배경 제거, 크롭, 리사이즈 (Nearest-Neighbor) 수행.

사용법:
  python tools/post_process.py                    # 전체 후처리
  python tools/post_process.py --category monsters # 몬스터만
  python tools/post_process.py --ids slime,goblin  # 특정 ID만
  python tools/post_process.py --no-rembg          # rembg 없이 (단순 흑배경 제거)
"""

import argparse
import json
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("ERROR: pip install Pillow")
    sys.exit(1)

SCRIPT_DIR = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent
PROMPTS_FILE = SCRIPT_DIR / "monster_prompts.json"
RAW_DIR = SCRIPT_DIR / "raw"
ASSETS_DIR = PROJECT_DIR / "assets" / "images"


def remove_background(img: Image.Image, use_rembg: bool = True) -> Image.Image:
    if use_rembg:
        try:
            from rembg import remove
            from io import BytesIO
            buf = BytesIO()
            img.save(buf, format="PNG")
            buf.seek(0)
            result = remove(buf.read())
            return Image.open(BytesIO(result)).convert("RGBA")
        except ImportError:
            print("  WARNING: rembg not installed, using simple method")

    # Simple black bg removal
    img = img.convert("RGBA")
    data = img.getdata()
    new_data = []
    for r, g, b, a in data:
        if r < 15 and g < 15 and b < 15:
            new_data.append((0, 0, 0, 0))
        else:
            new_data.append((r, g, b, a))
    img.putdata(new_data)
    return img


def crop_to_content(img: Image.Image, padding: int = 2) -> Image.Image:
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    bbox = img.getbbox()
    if bbox is None:
        return img
    x0, y0, x1, y1 = bbox
    x0, y0 = max(0, x0 - padding), max(0, y0 - padding)
    x1, y1 = min(img.width, x1 + padding), min(img.height, y1 + padding)
    return img.crop((x0, y0, x1, y1))


def make_square(img: Image.Image) -> Image.Image:
    w, h = img.size
    size = max(w, h)
    new_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    new_img.paste(img, ((size - w) // 2, (size - h) // 2), img)
    return new_img


def process_monster(monster_id: str, target_px: int, use_rembg: bool) -> bool:
    raw_path = RAW_DIR / "monsters" / f"{monster_id}_raw.png"
    output_path = ASSETS_DIR / "monsters" / f"{monster_id}.png"

    if not raw_path.exists():
        print(f"  SKIP: {monster_id} (no raw file)")
        return False

    img = Image.open(raw_path)
    img = remove_background(img, use_rembg)
    img = crop_to_content(img)
    img = make_square(img)
    img = img.resize((target_px, target_px), Image.NEAREST)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(output_path, "PNG")
    print(f"  OK: {monster_id} → {target_px}x{target_px}px")
    return True


def process_projectile(element: str, use_rembg: bool) -> bool:
    raw_path = RAW_DIR / "projectiles" / f"{element}_raw.png"
    output_path = ASSETS_DIR / "effects" / f"projectile_{element}.png"

    if not raw_path.exists():
        return False

    img = Image.open(raw_path)
    img = remove_background(img, use_rembg)
    img = crop_to_content(img)
    img = make_square(img)
    img = img.resize((16, 16), Image.NEAREST)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(output_path, "PNG")
    print(f"  OK: projectile_{element} → 16x16px")
    return True


def process_background(bg_id: str, target_w: int, target_h: int) -> bool:
    raw_path = RAW_DIR / "backgrounds" / f"{bg_id}_raw.png"
    output_path = ASSETS_DIR / "backgrounds" / f"{bg_id}.png"

    if not raw_path.exists():
        return False

    img = Image.open(raw_path)
    img = img.resize((target_w, target_h), Image.NEAREST)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(output_path, "PNG")
    print(f"  OK: {bg_id} → {target_w}x{target_h}px")
    return True


def main():
    parser = argparse.ArgumentParser(description="Post-process raw pixel art images")
    parser.add_argument("--category", choices=["monsters", "projectiles", "backgrounds", "hero", "all"],
                        default="all")
    parser.add_argument("--ids", type=str, default=None)
    parser.add_argument("--no-rembg", action="store_true")
    args = parser.parse_args()

    with open(PROMPTS_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)

    use_rembg = not args.no_rembg
    filter_ids = set(args.ids.split(",")) if args.ids else None
    total = ok = 0

    if args.category in ("monsters", "all"):
        print("=== MONSTERS ===")
        for mid, m in data["monsters"].items():
            if filter_ids and mid not in filter_ids:
                continue
            total += 1
            if process_monster(mid, m["target_px"], use_rembg):
                ok += 1

    if args.category in ("projectiles", "all"):
        print("=== PROJECTILES ===")
        for el in data["projectiles"]:
            if filter_ids and el not in filter_ids:
                continue
            total += 1
            if process_projectile(el, use_rembg):
                ok += 1

    if args.category in ("backgrounds", "all"):
        print("=== BACKGROUNDS ===")
        for bg_id, bg in data["backgrounds"].items():
            if filter_ids and bg_id not in filter_ids:
                continue
            total += 1
            w, h = bg["target_size"]
            if process_background(bg_id, w, h):
                ok += 1

    print(f"\n=== DONE: {ok}/{total} processed ===")


if __name__ == "__main__":
    main()
