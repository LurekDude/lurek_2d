#!/usr/bin/env python3
"""
gen_icon.py — Generate assets/icon.ico (and .png) for the Luna2D engine.

Usage:
    python tools/gen_icon.py              # writes assets/icon.ico + assets/icon.png
    python tools/gen_icon.py --out custom.ico

The .ico file is embedded into luna2d.exe on Windows via build.rs + winresource.
The .png is a 256×256 high-resolution source kept alongside it.

Requires:  pip install Pillow
"""

from __future__ import annotations

import argparse
import math
import os
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw
    HAVE_PILLOW = True
except ImportError:
    HAVE_PILLOW = False

WORKSPACE = Path(__file__).resolve().parent.parent
ICO_OUTPUT = WORKSPACE / "assets" / "icon.ico"
PNG_OUTPUT = WORKSPACE / "assets" / "icon.png"


def lerp_color(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))


def generate_icon_image(size: int) -> Image.Image:
    """Draw a single icon frame: light blue gear-pacman eating a gray cube."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")

    s = size

    # Background circle (rounded square feeling)
    bg_r = int(s * 0.44)
    bx, by = s // 2, s // 2
    d.ellipse([bx - bg_r, by - bg_r, bx + bg_r, by + bg_r],
              fill=(22, 12, 48, 255))

    # Center of Pac-Man
    px, py = int(s * 0.45), int(s * 0.5)
    r = int(s * 0.3)

    # Glow light blue
    for gr in range(r + int(s * 0.12), r - 1, -2):
        alpha = max(0, int(35 * (1 - (gr - r) / (s * 0.12))))
        d.ellipse([px - gr, py - gr, px + gr, py + gr], fill=(130, 200, 250, alpha))

    # Draw gear teeth along the outer rim
    num_teeth = 12
    tooth_h = int(s * 0.06)
    tooth_w_angle = math.pi * 2 / (num_teeth * 2)

    start_angle = math.radians(35)
    end_angle = math.radians(360 - 35)

    pts = [(px, py)]
    steps = 200
    for i in range(steps + 1):
        angle = start_angle + (end_angle - start_angle) * i / steps
        angle_norm = angle % (math.pi * 2)
        rem = angle_norm % (math.pi * 2 / num_teeth)

        rad = r
        if rem > tooth_w_angle * 0.5 and rem < tooth_w_angle * 1.5:
            rad = r + tooth_h

        x = px + rad * math.cos(angle)
        y = py + rad * math.sin(angle)
        pts.append((x, y))

    d.polygon(pts, fill=(130, 200, 250, 255))

    # Eye
    eye_x, eye_y = px + int(r * 0.1), py - int(r * 0.5)
    eye_r = int(s * 0.04)
    d.ellipse([eye_x - eye_r, eye_y - eye_r, eye_x + eye_r, eye_y + eye_r], fill=(22, 12, 48, 255))

    # Draw the gray cube
    cx, cy = px + int(s * 0.35), py
    cr = int(s * 0.12)

    d.polygon([(cx, cy - cr), (cx + cr, cy - cr//2), (cx, cy), (cx - cr, cy - cr//2)], fill=(170, 170, 170, 255))
    d.polygon([(cx - cr, cy - cr//2), (cx, cy), (cx, cy + cr), (cx - cr, cy + cr//2)], fill=(130, 130, 130, 255))
    d.polygon([(cx, cy), (cx + cr, cy - cr//2), (cx + cr, cy + cr//2), (cx, cy + cr)], fill=(90, 90, 90, 255))

    return img


def generate_icon(ico_path: Path, png_path: Path) -> None:
    print("Generating Luna2D icon …")
    ico_path.parent.mkdir(parents=True, exist_ok=True)
    png_path.parent.mkdir(parents=True, exist_ok=True)

    # ICO sizes: Windows needs 16, 32, 48, 256
    ico_sizes = [16, 32, 48, 256]
    frames = [generate_icon_image(sz) for sz in ico_sizes]

    # Save ICO (Pillow uses the first image's format)
    frames[0].save(
        str(ico_path),
        format="ICO",
        sizes=[(sz, sz) for sz in ico_sizes],
        append_images=frames[1:],
    )
    print(f"  Written {ico_path}")

    # Save high-res PNG
    frames[-1].save(str(png_path), "PNG")
    print(f"  Written {png_path}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--ico", default=str(ICO_OUTPUT), metavar="FILE",
                        help=f"ICO output path (default: {ICO_OUTPUT})")
    parser.add_argument("--png", default=str(PNG_OUTPUT), metavar="FILE",
                        help=f"PNG output path (default: {PNG_OUTPUT})")
    args = parser.parse_args()

    if not HAVE_PILLOW:
        print("ERROR: Pillow is not installed.", file=sys.stderr)
        print("  Install it with:  pip install Pillow", file=sys.stderr)
        return 1

    generate_icon(Path(args.ico), Path(args.png))
    print("Done. Re-build the project — the .ico will be embedded via build.rs.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
