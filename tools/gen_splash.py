#!/usr/bin/env python3
"""
gen_splash.py — Generate assets/splash.png for the Luna2D engine.

Usage:
    python tools/gen_splash.py              # writes assets/splash.png
    python tools/gen_splash.py --out custom/path.png
    python tools/gen_splash.py --svg-only   # print SVG path and exit

Preferred pipeline (SVG → PNG):
    pip install cairosvg     # renders assets/splash.svg → PNG directly

Fallback pipeline (Pillow standalone renderer):
    pip install Pillow       # Pillow-based procedural renderer (no SVG)

The generated splash.png is embedded into the engine binary at compile time via
    include_bytes!("../../assets/splash.png")
Re-run this script whenever the SVG is updated, then re-run 'cargo build'.

The splash screen intentionally contains no version number so it never needs
to be regenerated on every release. Version is shown in the window title only.
"""

from __future__ import annotations

import argparse
import math
import os
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
    HAVE_PILLOW = True
except ImportError:
    HAVE_PILLOW = False

HAVE_CAIROSVG = False

# ── Paths ───────────────────────────────────────────────────────────────
WORKSPACE = Path(__file__).resolve().parent.parent
SVG_SOURCE = WORKSPACE / "assets" / "splash.svg"
OUTPUT_DEFAULT = WORKSPACE / "assets" / "splash.png"
ICON_OUTPUT_DEFAULT = WORKSPACE / "assets" / "icon.png"

WIDTH, HEIGHT = 800, 600


# ── Colour helpers ─────────────────────────────────────────────────────────────

def hex_color(h: str, alpha: int = 255) -> tuple[int, int, int, int]:
    h = h.lstrip("#")
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    return r, g, b, alpha


def lerp_color(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))


# ── Background gradient (top-to-bottom + radial influence) ────────────────────

def draw_background(img: Image.Image) -> None:
    draw = ImageDraw.Draw(img)
    top    = (30, 10, 64, 255)
    bottom = (5, 3, 16, 255)
    for y in range(HEIGHT):
        t = y / HEIGHT
        col = lerp_color(top, bottom, t)
        draw.line([(0, y), (WIDTH, y)], fill=col[:3])


# ── Stars ──────────────────────────────────────────────────────────────────────

def draw_stars(draw: ImageDraw.ImageDraw) -> None:
    import random
    rng = random.Random(42)  # deterministic

    for _ in range(120):
        x = rng.randint(0, WIDTH)
        y = rng.randint(0, HEIGHT - 120)    # keep bottom area clear
        size = rng.uniform(0.5, 2.2)
        alpha = rng.randint(100, 230)
        col = (230, 230, 255, alpha)
        r = size / 2
        draw.ellipse([x - r, y - r, x + r, y + r], fill=col)


# ── Moon ───────────────────────────────────────────────────────────────────────

def draw_moon(img: Image.Image) -> None:
    """Draw a light blue gear-pacman eating a gray cube in the upper-right region."""
    moon_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    d = ImageDraw.Draw(moon_layer)

    px, py = 500, 180
    r = 100

    # Glow light blue
    for gr in range(r + 40, r - 1, -2):
        alpha = max(0, int(40 * (1 - (gr - r) / 40)))
        d.ellipse([px - gr, py - gr, px + gr, py + gr], fill=(130, 200, 250, alpha))

    # Draw gear teeth along the outer rim
    num_teeth = 12
    tooth_h = 20
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
    eye_r = 15
    d.ellipse([eye_x - eye_r, eye_y - eye_r, eye_x + eye_r, eye_y + eye_r], fill=(22, 12, 48, 255))

    # Draw the gray cube
    cx, cy = px + 120, py
    cr = 40

    d.polygon([(cx, cy - cr), (cx + cr, cy - cr//2), (cx, cy), (cx - cr, cy - cr//2)], fill=(170, 170, 170, 255))
    d.polygon([(cx - cr, cy - cr//2), (cx, cy), (cx, cy + cr), (cx - cr, cy + cr//2)], fill=(130, 130, 130, 255))
    d.polygon([(cx, cy), (cx + cr, cy - cr//2), (cx + cr, cy + cr//2), (cx, cy + cr)], fill=(90, 90, 90, 255))

    img.alpha_composite(moon_layer)


# ── Orbit arc ─────────────────────────────────────────────────────────────────

def draw_orbit(draw: ImageDraw.ImageDraw) -> None:
    # Dashed ellipse around the moon area
    cx, cy, rx, ry = 530, 210, 190, 52
    steps = 180
    prev_x, prev_y = None, None
    for i in range(steps + 1):
        angle = 2 * math.pi * i / steps
        x = cx + rx * math.cos(angle)
        y = cy + ry * math.sin(angle)
        if prev_x is not None and i % 5 < 3:  # dash pattern
            draw.line([prev_x, prev_y, x, y], fill=(100, 70, 180, 60), width=1)
        prev_x, prev_y = x, y


# ── Decorative 4-point star ────────────────────────────────────────────────────

def draw_star4(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, color) -> None:
    """Four-pointed sparkle/star."""
    pts = []
    for i in range(8):
        angle = math.pi / 4 * i - math.pi / 2
        radius = r if i % 2 == 0 else r * 0.38
        pts.append((cx + radius * math.cos(angle), cy + radius * math.sin(angle)))
    draw.polygon(pts, fill=color)


# ── Title text ────────────────────────────────────────────────────────────────

def draw_title(img: Image.Image) -> None:
    """Render 'LUNA2D' and subtitle using bitmap drawing (no font file needed)."""
    draw = ImageDraw.Draw(img)

    # Try to use a system font; gracefully fall back to default
    font_title = None
    font_sub = None
    font_small = None
    font_paths_title = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "C:/Windows/Fonts/arialbd.ttf",
        "C:/Windows/Fonts/segoeuib.ttf",
    ]
    font_paths_regular = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "C:/Windows/Fonts/arial.ttf",
        "C:/Windows/Fonts/segoeui.ttf",
    ]

    for p in font_paths_title:
        if os.path.exists(p):
            try:
                font_title = ImageFont.truetype(p, 84)
                font_sub = ImageFont.truetype(p, 24)
                font_small = ImageFont.truetype(p, 13)
            except Exception:
                pass
            break
    if font_title is None:
        for p in font_paths_regular:
            if os.path.exists(p):
                try:
                    font_title = ImageFont.truetype(p, 84)
                    font_sub = ImageFont.truetype(p, 24)
                    font_small = ImageFont.truetype(p, 13)
                except Exception:
                    pass
                break

    if font_title is None:
        font_title = ImageFont.load_default()
        font_sub = font_title
        font_small = font_title

    title = "LUNA2D"
    subtitle = "2D GAME ENGINE"
    powered = "Powered by Rust  ·  Lua 5.4  ·  tiny-skia"

    # ── Glow effect: draw title blurred in a separate layer ──────────────
    glow_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow_layer)
    for ox in range(-3, 4):
        for oy in range(-3, 4):
            if ox * ox + oy * oy <= 9:
                bbox = gd.textbbox((0, 0), title, font=font_title)
                tw = bbox[2] - bbox[0]
                gd.text((WIDTH // 2 - tw // 2 + ox, 240 + oy), title,
                        font=font_title, fill=(245, 217, 80, 80))
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=8))
    img.alpha_composite(glow_layer)

    # ── Solid title ───────────────────────────────────────────────────────
    bbox = draw.textbbox((0, 0), title, font=font_title)
    tw = bbox[2] - bbox[0]
    tx = WIDTH // 2 - tw // 2
    draw.text((tx, 240), title, font=font_title, fill=(245, 217, 80, 255))

    # ── Horizontal rule ───────────────────────────────────────────────────
    draw.line([(180, 345), (620, 345)], fill=(90, 60, 160, 130), width=1)

    # ── Subtitle ──────────────────────────────────────────────────────────
    bbox2 = draw.textbbox((0, 0), subtitle, font=font_sub)
    sw = bbox2[2] - bbox2[0]
    draw.text((WIDTH // 2 - sw // 2, 358), subtitle,
              font=font_sub, fill=(168, 144, 208, 220))

    # ── Decorative stars beside title ────────────────────────────────────
    star_y = 285
    left_x = tx - 32
    right_x = tx + tw + 16
    draw_star4(draw, left_x, star_y, 10, (200, 160, 30, 190))
    draw_star4(draw, right_x, star_y, 10, (200, 160, 30, 190))

    # ── "Powered by" line ─────────────────────────────────────────────────
    bbox3 = draw.textbbox((0, 0), powered, font=font_small)
    pw = bbox3[2] - bbox3[0]
    draw.text((WIDTH // 2 - pw // 2, 412), powered,
              font=font_small, fill=(100, 80, 150, 180))


# ── SVG → PNG rendering (preferred) ─────────────────────────────────────────────

def render_svg_to_png(svg_path: Path, output: Path) -> bool:
    """Render svg_path to output using cairosvg. Returns True on success."""
    if not HAVE_CAIROSVG:
        return False
    if not svg_path.exists():
        print(f"  WARNING: SVG source not found: {svg_path}", file=sys.stderr)
        return False
    output.parent.mkdir(parents=True, exist_ok=True)
    cairosvg.svg2png(
        url=str(svg_path),
        write_to=str(output),
        output_width=WIDTH,
        output_height=HEIGHT,
    )
    return True


# ── Main generation ───────────────────────────────────────────────────────────

def generate_splash(output: Path, *, prefer_svg: bool = True) -> None:
    # ── Path 1: SVG → PNG via cairosvg ─────────────────────────────────
    if prefer_svg and HAVE_CAIROSVG and SVG_SOURCE.exists():
        print(f"Rendering splash from SVG: {SVG_SOURCE} → {output}")
        if render_svg_to_png(SVG_SOURCE, output):
            size_kb = output.stat().st_size // 1024
            print(f"  Written {output}  ({size_kb} KB)  [SVG path]")
            return
        print("  SVG render failed, falling back to Pillow renderer.", file=sys.stderr)

    # ── Path 2: Pillow standalone renderer ─────────────────────────────
    print(f"Generating Luna2D splash screen ({WIDTH}×{HEIGHT}) …  [Pillow path]")
    img = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 255))

    draw_background(img)

    draw_layer = ImageDraw.Draw(img, "RGBA")
    draw_stars(draw_layer)
    draw_orbit(draw_layer)

    draw_moon(img)

    draw_layer = ImageDraw.Draw(img, "RGBA")
    draw_star4(draw_layer, 260, 270, 12, (200, 160, 30, 180))
    draw_star4(draw_layer, 545, 278, 10, (200, 160, 30, 160))

    draw_title(img)

    # Convert to RGB for PNG (no transparency needed for splash)
    output.parent.mkdir(parents=True, exist_ok=True)
    img.convert("RGB").save(str(output), "PNG", optimize=True)
    size_kb = output.stat().st_size // 1024
    print(f"  Written {output}  ({size_kb} KB)")


# ── CLI ───────────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--out", metavar="FILE", default=str(OUTPUT_DEFAULT),
                        help=f"Output PNG path (default: {OUTPUT_DEFAULT})")
    parser.add_argument("--svg-only", action="store_true",
                        help="Print the SVG source path and exit (no rendering)")
    parser.add_argument("--pillow-only", action="store_true",
                        help="Force Pillow renderer even when cairosvg is available")
    args = parser.parse_args()

    if args.svg_only:
        print(SVG_SOURCE)
        return 0

    prefer_svg = not args.pillow_only

    if not prefer_svg or not HAVE_CAIROSVG:
        if not HAVE_PILLOW:
            print("ERROR: Neither cairosvg nor Pillow is installed.", file=sys.stderr)
            print("  SVG path:    pip install cairosvg  (recommended)", file=sys.stderr)
            print("  Pillow path: pip install Pillow", file=sys.stderr)
            return 1

    generate_splash(Path(args.out), prefer_svg=prefer_svg)
    print("Done. Re-run 'cargo build' to embed the updated splash into the binary.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
