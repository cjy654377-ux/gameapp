#!/usr/bin/env python3
"""PixelLab API 3종 테스트 - idle 생성 + attack 애니메이션"""

import base64
import json
import requests
from pathlib import Path
from io import BytesIO

API_KEY = "24c256db-0109-4fcd-9fb1-61ea8f7430d5"
BASE_URL = "https://api.pixellab.ai/v1"
HEADERS = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json",
}
OUT_DIR = Path(__file__).parent / "pixellab_test"
OUT_DIR.mkdir(exist_ok=True)

MONSTERS = {
    "slime": {
        "description": "round blue jelly slime with big cute eyes, bouncy body, transparent gel, side view facing right, dark fantasy pixel art",
        "size": 64,
    },
    "goblin": {
        "description": "small green-skinned goblin with pointy ears, holding a wooden club, mischievous grin, side view facing right, dark fantasy pixel art",
        "size": 64,
    },
    "thunder_wolf": {
        "description": "fierce dark wolf, yellow-blue fur, sharp fangs, muscular body, side view facing right, dark fantasy pixel art",
        "size": 64,
    },
}

ATTACK_ACTIONS = {
    "slime": "bouncing attack, jumping forward, squishing body",
    "goblin": "swinging wooden club overhead, attack slash",
    "thunder_wolf": "lunging bite attack, jaw open wide",
}


def save_base64_image(b64: str, path: Path):
    img_data = base64.b64decode(b64)
    path.write_bytes(img_data)
    print(f"  Saved: {path} ({len(img_data)} bytes)")


def generate_idle(monster_id: str, desc: str, size: int):
    """Generate idle sprite, return base64 image."""
    print(f"\n[{monster_id}] Generating idle ({size}x{size})...")
    payload = {
        "description": desc,
        "image_size": {"width": size, "height": size},
        "text_guidance_scale": 8.0,
        "seed": hash(monster_id) % 2147483647,
    }
    r = requests.post(f"{BASE_URL}/generate-image-pixflux", headers=HEADERS, json=payload, timeout=60)
    if r.status_code != 200:
        print(f"  ERROR {r.status_code}: {r.text[:200]}")
        return None
    data = r.json()
    print(f"  Usage: ${data.get('usage', {}).get('usd', '?')}")
    b64 = data["image"]["base64"]
    save_base64_image(b64, OUT_DIR / f"{monster_id}_idle.png")
    return b64


def generate_attack_animation(monster_id: str, desc: str, action: str, init_image_b64: str):
    """Generate attack animation spritesheet using animate-with-text."""
    print(f"[{monster_id}] Generating attack animation...")
    payload = {
        "image": {"type": "base64", "base64": init_image_b64},
        "reference_image": {"type": "base64", "base64": init_image_b64},
        "image_size": {"width": 64, "height": 64},
        "description": desc,
        "action": action,
        "n_frames": 8,
        "text_guidance_scale": 6.0,
        "seed": hash(monster_id) % 2147483647,
    }
    r = requests.post(f"{BASE_URL}/animate-with-text", headers=HEADERS, json=payload, timeout=120)
    if r.status_code != 200:
        print(f"  ERROR {r.status_code}: {r.text[:300]}")
        return
    data = r.json()
    print(f"  Usage: ${data.get('usage', {}).get('usd', '?')}")
    # Save each frame
    frames = data.get("images", [])
    print(f"  Frames: {len(frames)}")
    for i, frame in enumerate(frames):
        save_base64_image(frame["base64"], OUT_DIR / f"{monster_id}_attack_f{i:02d}.png")


def main():
    print("=== PixelLab API Test ===")

    # Check balance
    r = requests.get(f"{BASE_URL}/balance", headers=HEADERS, timeout=10)
    print(f"Balance: {r.json()}")

    for mid, info in MONSTERS.items():
        # 1. Generate idle
        idle_b64 = generate_idle(mid, info["description"], info["size"])
        if idle_b64 is None:
            continue

        # 2. Generate attack animation from idle
        generate_attack_animation(mid, info["description"], ATTACK_ACTIONS[mid], idle_b64)

    print("\n=== Done! Check tools/pixellab_test/ ===")


if __name__ == "__main__":
    main()
