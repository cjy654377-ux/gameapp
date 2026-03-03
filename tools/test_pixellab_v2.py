#!/usr/bin/env python3
"""PixelLab API v2 테스트 - 4분류별 1종씩, walk/attack/death 애니메이션"""

from __future__ import annotations
import base64
import json
import requests
import time
from pathlib import Path
from io import BytesIO

API_KEY = "24c256db-0109-4fcd-9fb1-61ea8f7430d5"
BASE_URL = "https://api.pixellab.ai/v1"
HEADERS = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json",
}
OUT_DIR = Path(__file__).parent / "pixellab_v2_test"
OUT_DIR.mkdir(exist_ok=True)

# 4분류별 1종
MONSTERS = {
    "goblin": {
        "description": "tiny cute green goblin with pointy ears, holding a small wooden club, chibi proportions, side view facing right, pixel art",
        "type": "biped",
        "size": 64,
    },
    "thunder_wolf": {
        "description": "small cute dark wolf with yellow-blue fur, sharp little fangs, chibi proportions, side view facing right, pixel art",
        "type": "quadruped",
        "size": 64,
    },
    "slime": {
        "description": "tiny cute round blue jelly slime with big adorable eyes, bouncy transparent gel body, chibi, side view, pixel art",
        "type": "nonstandard",
        "size": 64,
    },
    "flame_dragon": {
        "description": "small cute red baby dragon with tiny wings, golden belly, chibi proportions, side view facing right, pixel art",
        "type": "boss",
        "size": 64,
    },
}

ACTIONS = {
    "walk": {
        "goblin": "walking forward, swinging arms, carrying club",
        "thunder_wolf": "walking forward, trotting, four legs moving",
        "slime": "bouncing forward, squishing and stretching body",
        "flame_dragon": "walking forward, wings folded, waddling cute",
    },
    "attack": {
        "goblin": "swinging wooden club overhead, attack slash, aggressive",
        "thunder_wolf": "lunging bite attack, jaw open wide, pouncing",
        "slime": "jumping forward attack, body slamming, squishing flat",
        "flame_dragon": "breathing fire, mouth open, small flame burst",
    },
    "death": {
        "goblin": "falling down, collapsing, defeated, lying flat",
        "thunder_wolf": "collapsing sideways, falling down, defeated",
        "slime": "melting into puddle, deflating, dissolving flat",
        "flame_dragon": "falling over, wings drooping, collapsing defeated",
    },
}


def save_b64(b64_str, path):
    data = base64.b64decode(b64_str)
    path.write_bytes(data)
    print(f"    Saved: {path.name} ({len(data)} bytes)")


def check_balance():
    r = requests.get(f"{BASE_URL}/balance", headers=HEADERS, timeout=10)
    bal = r.json()
    print(f"Balance: ${bal.get('usd', 0):.4f}")
    return bal


def generate_idle(monster_id, info):
    """Step 1: Generate idle sprite with transparent background."""
    print(f"\n[{monster_id}] Step 1: Generating idle (Pixflux, {info['size']}x{info['size']})...")
    payload = {
        "description": info["description"],
        "image_size": {"width": info["size"], "height": info["size"]},
        "text_guidance_scale": 8.0,
        "no_background": True,
        "view": "side",
        "direction": "east",
        "outline": "single color black outline",
        "shading": "detailed shading",
        "detail": "medium detail",
        "seed": hash(monster_id) % 2147483647,
    }
    r = requests.post(f"{BASE_URL}/generate-image-pixflux", headers=HEADERS, json=payload, timeout=60)
    if r.status_code != 200:
        print(f"    ERROR {r.status_code}: {r.text[:200]}")
        return None
    data = r.json()
    print(f"    Usage: ${data.get('usage', {}).get('usd', '?')}")
    b64 = data["image"]["base64"]
    save_b64(b64, OUT_DIR / f"{monster_id}_idle.png")
    return b64


def estimate_skeleton(monster_id, idle_b64, size):
    """Step 2: Auto-detect skeleton from idle image."""
    print(f"[{monster_id}] Step 2: Estimating skeleton...")
    payload = {
        "image": {"type": "base64", "base64": idle_b64},
        "image_size": {"width": size, "height": size},
    }
    r = requests.post(f"{BASE_URL}/estimate-skeleton", headers=HEADERS, json=payload, timeout=30)
    if r.status_code != 200:
        print(f"    ERROR {r.status_code}: {r.text[:200]}")
        return None
    data = r.json()
    keypoints = data.get("keypoints", [])
    print(f"    Found {len(keypoints)} keypoints")
    # Save keypoints for reference
    kp_path = OUT_DIR / f"{monster_id}_skeleton.json"
    with open(kp_path, "w") as f:
        json.dump(keypoints, f, indent=2)
    return keypoints


def animate_with_skeleton(monster_id, idle_b64, keypoints, action_name, size):
    """Step 3-A: Animate using skeleton (for biped/quadruped)."""
    print(f"[{monster_id}] Step 3-A: Skeleton animation ({action_name})...")

    # Create 4 frames of skeleton poses by shifting keypoints
    frames_kp = []
    for frame_idx in range(4):
        frame_points = []
        for kp in keypoints:
            shifted = dict(kp)
            # Simple pose variation based on frame
            if action_name == "walk":
                if "LEG" in kp["label"] or "KNEE" in kp["label"]:
                    offset = [0, -3, 0, 3][frame_idx] if "RIGHT" in kp["label"] else [0, 3, 0, -3][frame_idx]
                    shifted["y"] = kp["y"] + offset
            elif action_name == "attack":
                if "ARM" in kp["label"] or "ELBOW" in kp["label"]:
                    offset = [0, -5, -8, -3][frame_idx] if "RIGHT" in kp["label"] else [0, 2, 5, 1][frame_idx]
                    shifted["y"] = kp["y"] + offset
            elif action_name == "death":
                # Gradually lower all points
                drop = frame_idx * 3
                shifted["y"] = kp["y"] + drop
            frame_points.append(shifted)
        frames_kp.append(frame_points)

    payload = {
        "reference_image": {"type": "base64", "base64": idle_b64},
        "skeleton_keypoints": frames_kp,
        "image_size": {"width": size, "height": size},
        "guidance_scale": 4.0,
        "view": "side",
        "direction": "east",
        "seed": hash(monster_id + action_name) % 2147483647,
    }
    r = requests.post(f"{BASE_URL}/animate-with-skeleton", headers=HEADERS, json=payload, timeout=120)
    if r.status_code != 200:
        print(f"    ERROR {r.status_code}: {r.text[:300]}")
        return False
    data = r.json()
    print(f"    Usage: ${data.get('usage', {}).get('usd', '?')}")
    frames = data.get("images", [])
    print(f"    Frames: {len(frames)}")
    for i, frame in enumerate(frames):
        save_b64(frame["base64"], OUT_DIR / f"{monster_id}_{action_name}_f{i:02d}.png")
    return True


def animate_with_text(monster_id, idle_b64, action_name, action_desc, size):
    """Step 3-B: Animate using text (for nonstandard/boss)."""
    print(f"[{monster_id}] Step 3-B: Text animation ({action_name})...")
    desc = MONSTERS[monster_id]["description"]
    payload = {
        "description": desc,
        "action": action_desc,
        "reference_image": {"type": "base64", "base64": idle_b64},
        "image": {"type": "base64", "base64": idle_b64},
        "image_size": {"width": 64, "height": 64},
        "n_frames": 6,
        "text_guidance_scale": 8.0,
        "image_guidance_scale": 1.4,
        "view": "side",
        "direction": "east",
        "seed": hash(monster_id + action_name) % 2147483647,
    }
    r = requests.post(f"{BASE_URL}/animate-with-text", headers=HEADERS, json=payload, timeout=120)
    if r.status_code != 200:
        print(f"    ERROR {r.status_code}: {r.text[:300]}")
        return False
    data = r.json()
    print(f"    Usage: ${data.get('usage', {}).get('usd', '?')}")
    frames = data.get("images", [])
    print(f"    Frames: {len(frames)}")
    for i, frame in enumerate(frames):
        save_b64(frame["base64"], OUT_DIR / f"{monster_id}_{action_name}_f{i:02d}.png")
    return True


def main():
    print("=== PixelLab v2 Test: 4 Types x 3 Animations ===\n")
    check_balance()

    for monster_id, info in MONSTERS.items():
        # Step 1: Generate idle
        idle_b64 = generate_idle(monster_id, info)
        if idle_b64 is None:
            continue
        time.sleep(1)

        # Step 2: Estimate skeleton (for biped/quadruped)
        keypoints = None
        if info["type"] in ("biped", "quadruped"):
            keypoints = estimate_skeleton(monster_id, idle_b64, info["size"])
            time.sleep(1)

        # Step 3: Generate walk/attack/death animations
        for action_name in ["walk", "attack", "death"]:
            action_desc = ACTIONS[action_name][monster_id]

            if info["type"] in ("biped", "quadruped") and keypoints:
                animate_with_skeleton(monster_id, idle_b64, keypoints, action_name, info["size"])
            else:
                animate_with_text(monster_id, idle_b64, action_name, action_desc, info["size"])

            time.sleep(2)

    print("\n=== Done! Check tools/pixellab_v2_test/ ===")
    check_balance()


if __name__ == "__main__":
    main()
