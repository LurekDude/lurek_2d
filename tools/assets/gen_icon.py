#!/usr/bin/env python3
"""
gen_icon.py — Generate assets/icon.ico (and .png) for the Luna2D engine.

Usage:
    python tools/gen_icon.py              # writes assets/icon.ico + assets/icon.png
    python tools/gen_icon.py --ico custom.ico --png custom.png

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

WORKSPACE = Path(__file__).resolve().parent.parent.parent
ICO_OUTPUT = WORKSPACE / "assets" / "icon.ico"
PNG_OUTPUT = WORKSPACE / "assets" / "icon.png"


def lerp_color(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))


def build_gear_points(
    cx: float,
    cy: float,
    inner_r: float,
    outer_r: float,
    mouth_half: float,
    n_teeth: int,
    arc_steps: int = 4,
) -> list[tuple[float, float]]:
    """Pac-Man gear polygon with explicit radial rise/fall walls (cog, not sun)."""
    sweep = math.tau - 2 * mouth_half
    per_tooth = sweep / n_teeth
    tooth_frac = 0.50
    gap_frac = 1.0 - tooth_frac
    pts: list[tuple[float, float]] = [(cx, cy)]
    for i in range(n_teeth):
        a_rise = mouth_half + i * per_tooth
        a_fall = a_rise + tooth_frac * per_tooth
        a_next = a_fall + gap_frac * per_tooth
        # radial rise wall: inner → outer at same angle
        pts.append((cx + inner_r * math.cos(a_rise), cy + inner_r * math.sin(a_rise)))
        pts.append((cx + outer_r * math.cos(a_rise), cy + outer_r * math.sin(a_rise)))
        # tooth top arc
        for j in range(1, arc_steps):
            a = a_rise + j / arc_steps * (a_fall - a_rise)
            pts.append((cx + outer_r * math.cos(a), cy + outer_r * math.sin(a)))
        # radial fall wall: outer → inner at same angle
        pts.append((cx + outer_r * math.cos(a_fall), cy + outer_r * math.sin(a_fall)))
        pts.append((cx + inner_r * math.cos(a_fall), cy + inner_r * math.sin(a_fall)))
        # gap arc
        for j in range(1, arc_steps):
            a = a_fall + j / arc_steps * (a_next - a_fall)
            pts.append((cx + inner_r * math.cos(a), cy + inner_r * math.sin(a)))
    # close at end of last gap
    a_end = math.tau - mouth_half
    pts.append((cx + inner_r * math.cos(a_end), cy + inner_r * math.sin(a_end)))
    return pts


def draw_cube(draw: ImageDraw.ImageDraw, cx: float, cy: float, size: float) -> None:
    draw.polygon(
        [(cx, cy - size), (cx + size, cy - size * 0.5), (cx, cy), (cx - size, cy - size * 0.5)],
        fill=(120, 182, 242, 255),
    )
    draw.polygon(
        [(cx - size, cy - size * 0.5), (cx, cy), (cx, cy + size), (cx - size, cy + size * 0.5)],
        fill=(77, 135, 210, 255),
    )
    draw.polygon(
        [(cx, cy), (cx + size, cy - size * 0.5), (cx + size, cy + size * 0.5), (cx, cy + size)],
        fill=(44, 93, 168, 255),
    )


def generate_icon_image(size: int) -> Image.Image:
    """Draw a single icon frame: the latest Luna mark eating the incoming cube."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")

    s = float(size)
    cx = s * 0.50
    cy = s * 0.50

    # Disc sized relative to the GEAR so gear teeth fill the circle properly.
    # Gear centre shifted left so the open mouth + cube fit inside on the right.
    px = s * 0.40
    py = s * 0.50
    gear_outer = s * 0.31         # teeth reach close to disc edge
    gear_inner = gear_outer * (44 / 62)

    disc_r = s * 0.44
    halo_r = disc_r + s * 0.04
    rim_r  = disc_r + s * 0.015

    # 0. Dark ring background
    d.ellipse([cx - halo_r, cy - halo_r, cx + halo_r, cy + halo_r], fill=(18, 8, 48, 255))
    d.ellipse([cx - rim_r,  cy - rim_r,  cx + rim_r,  cy + rim_r],  fill=(28, 16, 68, 255))
    d.ellipse([cx - disc_r, cy - disc_r, cx + disc_r, cy + disc_r], fill=(12, 6, 32, 255))

    # 1. Gear body — 9-tooth cog, mouth opens right (±36°)
    d.polygon(
        build_gear_points(px, py, gear_inner, gear_outer, math.radians(36), 9),
        fill=(142, 200, 232, 255),
    )

    # 2. Dark crescent cutout — same proportions as app.rs (offset right of gear centre)
    cutout_x = px + gear_outer * (16 / 62)
    cutout_y = py - gear_outer * (2 / 62)
    cutout_r = gear_outer * (35 / 62)
    d.ellipse(
        [cutout_x - cutout_r, cutout_y - cutout_r, cutout_x + cutout_r, cutout_y + cutout_r],
        fill=(12, 6, 32, 255),
    )

    # 3. Cube sitting in the open mouth, on the horizontal axis
    cube_size = gear_outer * (12 / 62)
    cube_cx   = px + gear_outer * (78 / 62)
    draw_cube(d, cube_cx, py, cube_size)

    # 4. Eye in the crescent (left-of-cutout blue area)
    eye_x = px - gear_outer * (15 / 62)
    eye_y = py - gear_outer * (24 / 62)
    eye_r = max(1.0, gear_outer * (6 / 62))
    d.ellipse(
        [eye_x - eye_r, eye_y - eye_r, eye_x + eye_r, eye_y + eye_r],
        fill=(22, 12, 48, 255),
    )

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
