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
    """Draw a single icon frame: crescent moon on dark purple background."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")

    s = size

    # Background circle (rounded square feeling)
    bg_r = int(s * 0.44)
    bx, by = s // 2, s // 2
    d.ellipse([bx - bg_r, by - bg_r, bx + bg_r, by + bg_r],
              fill=(22, 12, 48, 255))

    # Moon body
    moon_cx, moon_cy = int(s * 0.52), int(s * 0.46)
    moon_r = int(s * 0.30)

    # Glow
    for gr in range(moon_r + int(s * 0.12), moon_r - 1, -2):
        alpha = max(0, int(35 * (1 - (gr - moon_r) / (s * 0.12))))
        d.ellipse([moon_cx - gr, moon_cy - gr, moon_cx + gr, moon_cy + gr],
                  fill=(245, 220, 80, alpha))

    # Moon fill
    d.ellipse([moon_cx - moon_r, moon_cy - moon_r,
               moon_cx + moon_r, moon_cy + moon_r],
              fill=(248, 218, 74, 255))

    # Crescent cutout
    cut_cx = moon_cx + int(moon_r * 0.65)
    cut_cy = moon_cy - int(moon_r * 0.28)
    cut_r  = int(moon_r * 0.88)
    d.ellipse([cut_cx - cut_r, cut_cy - cut_r,
               cut_cx + cut_r, cut_cy + cut_r],
              fill=(22, 12, 48, 255))

    # Tiny star (top-left of icon)
    def star4(cx, cy, r):
        pts = []
        for i in range(8):
            angle = math.pi / 4 * i - math.pi / 4
            rad = r if i % 2 == 0 else r * 0.4
            pts.append((cx + rad * math.cos(angle), cy + rad * math.sin(angle)))
        d.polygon(pts, fill=(245, 220, 80, 200))

    star4(int(s * 0.24), int(s * 0.28), int(s * 0.065))
    star4(int(s * 0.70), int(s * 0.72), int(s * 0.04))
    star4(int(s * 0.18), int(s * 0.65), int(s * 0.03))

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
