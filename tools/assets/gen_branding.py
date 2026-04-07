#!/usr/bin/env python3
"""
gen_branding.py — Generate all Luna2D SVG branding assets and convert to PNG.

Usage:
    python tools/gen_branding.py              # generate all SVGs + PNGs
    python tools/gen_branding.py --svg-only   # SVGs only, skip PNG conversion
    python tools/gen_branding.py --list       # list output files

Outputs:
    assets/svg/logo-simple.svg       256×256  Simple icon (app icon, favicon)
    assets/svg/logo-large.svg        512×512  Detailed icon with glow
    assets/svg/splash.svg            800×600  Engine splash screen
    assets/svg/banner.svg           1280×640  GitHub / social banner
    assets/svg/vscode-icon.svg       128×128  VS Code extension icon
    assets/icon.png                  256×256  PNG from logo-simple
    assets/icon-large.png            512×512  PNG from logo-large
    assets/splash.png                800×600  PNG from splash
    assets/banner.png               1280×640  PNG from banner
    assets/vscode-icon.png           128×128  PNG from vscode-icon

Requires: pip install Pillow cairosvg
  (cairosvg is optional — if unavailable, PNG conversion is skipped)

Design:
  - Luna Mark: one light-blue gear-pacman silhouette with an internal crescent cutout
  - Incoming Cube: blue isometric cube approaching the mouth
  - Colour palette: deep navy (#1a0e40), light blue (#82c8e8), gold (#d4a843), blue cube
"""

from __future__ import annotations

import argparse
import math
import os
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parent.parent.parent
SVG_DIR = WORKSPACE / "assets" / "svg"
ASSETS_DIR = WORKSPACE / "assets"

# ── Colour Palette ──────────────────────────────────────────────────────────
NAVY = "#1a0e40"
NAVY_DARK = "#0d0520"
GEAR_LIGHT = "#8ec8e8"
GEAR_MID = "#6aafe0"
GEAR_DARK = "#4a90c0"
EYE_COLOR = "#1a0e40"
GOLD = "#d4a843"
GOLD_LIGHT = "#e8c060"
CUBE_TOP = "#78b6f2"
CUBE_LEFT = "#4d87d2"
CUBE_RIGHT = "#2c5da8"
STAR_COLOR = "#e0e0ff"
BG_TOP = "#1e0a40"
BG_BOTTOM = "#050310"
SUBTITLE_COLOR = "#a0a0c0"
POWERED_COLOR = "#7878a0"


# ── Math Helpers ────────────────────────────────────────────────────────────

def gear_path(cx: float, cy: float, inner_r: float, outer_r: float,
              num_teeth: int, tooth_width_frac: float = 0.4,
              mouth_angle: float = 40.0, mouth_dir: float = 0.0) -> str:
    """
    Generate an SVG path for a gear-pacman shape.

    cx, cy: center
    inner_r: radius of the gear body circle
    outer_r: radius of the tooth tips
    num_teeth: number of gear teeth
    tooth_width_frac: fraction of tooth period that is "up" (0-1)
    mouth_angle: half-angle of the pacman mouth in degrees
    mouth_dir: direction the mouth faces in degrees (0 = right)
    """
    points = []
    steps = num_teeth * 20  # high resolution

    mouth_start = math.radians(mouth_dir - mouth_angle)
    mouth_end = math.radians(mouth_dir + mouth_angle)

    # Normalize to [0, 2pi)
    def norm_angle(a):
        return a % (2 * math.pi)

    for i in range(steps):
        angle = 2 * math.pi * i / steps
        na = norm_angle(angle)

        # Check if we're in the mouth region
        ms = norm_angle(mouth_start)
        me = norm_angle(mouth_end)
        in_mouth = False
        if ms < me:
            in_mouth = ms <= na <= me
        else:
            in_mouth = na >= ms or na <= me

        if in_mouth:
            continue

        # Determine if this angle hits a tooth or a valley
        tooth_period = 2 * math.pi / num_teeth
        phase = (angle % tooth_period) / tooth_period

        if phase < tooth_width_frac:
            # On a tooth
            r = outer_r
        else:
            r = inner_r

        x = cx + r * math.cos(angle)
        y = cy + r * math.sin(angle)
        points.append((x, y))

    if not points:
        return ""

    # Add the center point for the mouth wedge to create pacman shape
    # Insert center at beginning and end
    mouth_points = [(cx, cy)]
    path_parts = [f"M {mouth_points[0][0]:.1f} {mouth_points[0][1]:.1f}"]

    for px, py in points:
        path_parts.append(f"L {px:.1f} {py:.1f}")

    path_parts.append("Z")
    return " ".join(path_parts)


def combined_mark_svg(
    cx: float,
    cy: float,
    inner_r: float,
    outer_r: float,
    num_teeth: int,
    *,
    gear_fill: str = "url(#gearGrad)",
    gear_filter: str | None = None,
    tooth_width_frac: float = 0.45,
    mouth_angle: float = 32.0,
    cutout_dx: float = 0.0,
    cutout_dy: float = 0.0,
    cutout_r: float | None = None,
    cutout_fill: str = NAVY_DARK,
    cutout_opacity: float = 1.0,
    eye_dx: float = 0.0,
    eye_dy: float = 0.0,
    eye_r: float = 0.0,
 ) -> str:
    """Generate the single Luna mark: one gear-pacman with an internal crescent cutout."""
    gear = gear_path(
        cx,
        cy,
        inner_r,
        outer_r,
        num_teeth,
        tooth_width_frac=tooth_width_frac,
        mouth_angle=mouth_angle,
        mouth_dir=0,
    )
    filter_attr = f' filter="{gear_filter}"' if gear_filter else ""
    cutout_r = cutout_r if cutout_r is not None else inner_r * 0.86

    parts = [f'<path d="{gear}" fill="{gear_fill}"{filter_attr}/>']
    parts.append(
        f'<circle cx="{cx + cutout_dx:.1f}" cy="{cy + cutout_dy:.1f}" '
        f'r="{cutout_r:.1f}" fill="{cutout_fill}" opacity="{cutout_opacity:.2f}"/>'
    )
    if eye_r > 0.0:
        parts.append(
            f'<circle cx="{cx + eye_dx:.1f}" cy="{cy + eye_dy:.1f}" '
            f'r="{eye_r:.1f}" fill="{EYE_COLOR}"/>'
        )
    return "\n  ".join(parts)


def cube_svg(cx: float, cy: float, size: float) -> str:
    """Generate SVG polygons for an isometric cube."""
    s = size
    # Top face
    top = f'<polygon points="{cx:.1f},{cy - s:.1f} {cx + s:.1f},{cy - s*0.5:.1f} {cx:.1f},{cy:.1f} {cx - s:.1f},{cy - s*0.5:.1f}" fill="{CUBE_TOP}"/>'
    # Left face
    left = f'<polygon points="{cx - s:.1f},{cy - s*0.5:.1f} {cx:.1f},{cy:.1f} {cx:.1f},{cy + s:.1f} {cx - s:.1f},{cy + s*0.5:.1f}" fill="{CUBE_LEFT}"/>'
    # Right face
    right = f'<polygon points="{cx:.1f},{cy:.1f} {cx + s:.1f},{cy - s*0.5:.1f} {cx + s:.1f},{cy + s*0.5:.1f} {cx:.1f},{cy + s:.1f}" fill="{CUBE_RIGHT}"/>'
    return f"{top}\n  {left}\n  {right}"


def stars_svg(width: int, height: int, count: int = 120, seed: int = 42,
              max_y_frac: float = 0.8) -> str:
    """Generate random star dots (deterministic via seed)."""
    import random
    rng = random.Random(seed)
    parts = []
    for _ in range(count):
        x = rng.uniform(0, width)
        y = rng.uniform(0, height * max_y_frac)
        r = rng.uniform(0.3, 1.5)
        alpha = rng.uniform(0.3, 0.9)
        parts.append(
            f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.1f}" '
            f'fill="{STAR_COLOR}" opacity="{alpha:.2f}"/>'
        )
    return "\n    ".join(parts)


def sparkle_svg(cx: float, cy: float, size: float, color: str = GOLD_LIGHT) -> str:
    """Generate a 4-pointed sparkle/star."""
    s = size
    return (
        f'<polygon points="{cx:.0f},{cy - s:.0f} {cx + s*0.2:.0f},{cy:.0f} '
        f'{cx:.0f},{cy + s:.0f} {cx - s*0.2:.0f},{cy:.0f}" fill="{color}" opacity="0.7"/>'
    )


def crescent_path(cx: float, cy: float, outer_r: float, inner_r: float,
                  offset_x: float = 0, offset_y: float = 0) -> str:
    """SVG path for a crescent moon (outer circle minus offset inner circle)."""
    # Use two arcs: outer full circle, then inner circle subtracted
    # Outer arc (clockwise)
    ox = cx
    oy = cy
    # Inner arc center (offset to create crescent)
    ix = cx + offset_x
    iy = cy + offset_y

    return (
        f'M {ox:.1f} {oy - outer_r:.1f} '
        f'A {outer_r:.1f} {outer_r:.1f} 0 1 1 {ox:.1f} {oy + outer_r:.1f} '
        f'A {outer_r:.1f} {outer_r:.1f} 0 1 1 {ox:.1f} {oy - outer_r:.1f} Z '
        f'M {ix:.1f} {iy - inner_r:.1f} '
        f'A {inner_r:.1f} {inner_r:.1f} 0 1 0 {ix:.1f} {iy + inner_r:.1f} '
        f'A {inner_r:.1f} {inner_r:.1f} 0 1 0 {ix:.1f} {iy - inner_r:.1f} Z'
    )


def orbit_path(cx: float, cy: float, rx: float, ry: float,
               dash: str = "6 4") -> str:
    """SVG ellipse path for an orbit ring."""
    return (
        f'<ellipse cx="{cx:.0f}" cy="{cy:.0f}" rx="{rx:.0f}" ry="{ry:.0f}" '
        f'fill="none" stroke="{SUBTITLE_COLOR}" stroke-width="1" '
        f'stroke-dasharray="{dash}" opacity="0.4"/>'
    )


# ── SVG Generators ──────────────────────────────────────────────────────────

def gen_logo_simple(size: int = 256) -> str:
    """256×256 simple icon for app icon and favicon."""
    cx, cy = size / 2, size / 2
    mark_cx = cx - size * 0.02
    gear_inner = size * 0.30
    gear_outer = size * 0.38
    teeth = 12
    body = combined_mark_svg(
        mark_cx,
        cy,
        gear_inner,
        gear_outer,
        teeth,
        gear_fill="url(#gearGrad)",
        cutout_dx=size * 0.11,
        cutout_dy=-size * 0.02,
        cutout_r=size * 0.24,
        cutout_fill=NAVY,
        eye_dx=-size * 0.06,
        eye_dy=-size * 0.15,
        eye_r=size * 0.04,
    )

    # Cube in the mouth area
    cube_cx = mark_cx + size * 0.26
    cube_cy = cy - size * 0.02
    cube_size = size * 0.09

    return f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {size} {size}" width="{size}" height="{size}">
  <defs>
    <radialGradient id="gearGrad" cx="40%" cy="35%" r="60%">
      <stop offset="0%" stop-color="{GEAR_LIGHT}"/>
      <stop offset="100%" stop-color="{GEAR_MID}"/>
    </radialGradient>
  </defs>

  <!-- Incoming cube -->
  {cube_svg(cube_cx, cube_cy, cube_size)}

  <!-- Single Luna mark -->
  {body}
</svg>'''


def gen_logo_large(size: int = 512) -> str:
    """512×512 detailed icon with glow effects."""
    cx, cy = size / 2, size / 2
    mark_cx = cx - size * 0.02
    gear_inner = size * 0.28
    gear_outer = size * 0.36
    teeth = 14
    body = combined_mark_svg(
        mark_cx,
        cy,
        gear_inner,
        gear_outer,
        teeth,
        gear_fill="url(#gearGrad)",
        cutout_dx=size * 0.10,
        cutout_dy=-size * 0.02,
        cutout_r=size * 0.23,
        cutout_fill=NAVY_DARK,
        cutout_opacity=0.95,
        eye_dx=-size * 0.06,
        eye_dy=-size * 0.13,
        eye_r=size * 0.035,
    )

    cube_cx = mark_cx + size * 0.24
    cube_cy = cy - size * 0.02
    cube_size = size * 0.08

    return f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {size} {size}" width="{size}" height="{size}">
  <defs>
    <radialGradient id="gearGrad" cx="40%" cy="35%" r="60%">
      <stop offset="0%" stop-color="{GEAR_LIGHT}"/>
      <stop offset="100%" stop-color="{GEAR_MID}"/>
    </radialGradient>
  </defs>

  <!-- Incoming cube -->
  {cube_svg(cube_cx, cube_cy, cube_size)}

    <!-- Single Luna mark -->
    {body}

    <!-- Eye highlight -->
    <circle cx="{mark_cx - size*0.068:.0f}" cy="{cy - size*0.14:.0f}"
      r="{size * 0.01:.0f}" fill="white" opacity="0.3"/>

  <!-- Sparkles -->
  {sparkle_svg(cx - size*0.35, cy - size*0.1, size*0.03)}
  {sparkle_svg(cx + size*0.38, cy + size*0.25, size*0.02)}
</svg>'''


def gen_splash(width: int = 800, height: int = 600) -> str:
    """800×600 splash screen with logo, title, and starfield."""
    logo_cx = width * 0.56
    logo_cy = height * 0.30
    gear_inner = 80
    gear_outer = 105
    teeth = 12
    body = combined_mark_svg(
        logo_cx,
        logo_cy,
        gear_inner,
        gear_outer,
        teeth,
        gear_fill="url(#gearGrad)",
        cutout_dx=26,
        cutout_dy=-6,
        cutout_r=66,
        cutout_fill=BG_TOP,
        cutout_opacity=1.0,
        eye_dx=-14,
        eye_dy=-36,
        eye_r=12,
    )

    cube_cx = logo_cx + 136
    cube_cy = logo_cy - 6
    cube_size = 24

    title_y = height * 0.60
    subtitle_y = height * 0.70
    powered_y = height * 0.80

    return f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="{width}" height="{height}">
  <defs>
    <linearGradient id="bgGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="{BG_TOP}"/>
      <stop offset="100%" stop-color="{BG_BOTTOM}"/>
    </linearGradient>
    <radialGradient id="gearGrad" cx="40%" cy="35%" r="60%">
      <stop offset="0%" stop-color="{GEAR_LIGHT}"/>
      <stop offset="100%" stop-color="{GEAR_MID}"/>
    </radialGradient>
    <linearGradient id="titleGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="{GOLD_LIGHT}"/>
      <stop offset="100%" stop-color="{GOLD}"/>
    </linearGradient>
    <filter id="textGlow">
      <feGaussianBlur stdDeviation="3" result="blur"/>
      <feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
  </defs>

  <!-- Background gradient -->
  <rect width="{width}" height="{height}" fill="url(#bgGrad)"/>

  <!-- Stars -->
  <g>
    {stars_svg(width, height, 150, 42, 0.85)}
  </g>

  <!-- Incoming cube -->
  {cube_svg(cube_cx, cube_cy, cube_size)}

  <!-- Single Luna mark -->
  {body}

  <!-- Sparkles around logo -->
  {sparkle_svg(logo_cx - 160, logo_cy - 20, 8)}
  {sparkle_svg(logo_cx + 170, logo_cy + 60, 6)}
  {sparkle_svg(logo_cx - 120, logo_cy + 70, 5)}

  <!-- Title: LUNA2D -->
  <text x="{width / 2:.0f}" y="{title_y:.0f}" text-anchor="middle"
        font-family="'Segoe UI', 'Helvetica Neue', Arial, sans-serif"
        font-size="72" font-weight="bold" letter-spacing="8"
        fill="url(#titleGrad)" filter="url(#textGlow)">LUNA2D</text>

  <!-- Decorative line -->
  <line x1="{width/2 - 120:.0f}" y1="{title_y + 18:.0f}"
        x2="{width/2 + 120:.0f}" y2="{title_y + 18:.0f}"
        stroke="{SUBTITLE_COLOR}" stroke-width="1" opacity="0.5"/>

  <!-- Subtitle -->
  <text x="{width / 2:.0f}" y="{subtitle_y:.0f}" text-anchor="middle"
        font-family="'Segoe UI', 'Helvetica Neue', Arial, sans-serif"
        font-size="20" letter-spacing="6"
        fill="{SUBTITLE_COLOR}">2D GAME ENGINE</text>

  <!-- Powered by line -->
  <text x="{width / 2:.0f}" y="{powered_y:.0f}" text-anchor="middle"
        font-family="'Segoe UI', 'Helvetica Neue', Arial, sans-serif"
        font-size="13" letter-spacing="1"
        fill="{POWERED_COLOR}">Powered by Rust  ·  LuaJIT  ·  wgpu</text>

  <!-- Sparkles around title -->
  {sparkle_svg(width/2 - 200, title_y - 20, 10, GOLD_LIGHT)}
  {sparkle_svg(width/2 + 200, title_y - 15, 8, GOLD_LIGHT)}
</svg>'''


def gen_banner(width: int = 1280, height: int = 640) -> str:
    """1280×640 GitHub / social media banner."""
    logo_cx = width * 0.22
    logo_cy = height * 0.42
    gear_inner = 100
    gear_outer = 130
    teeth = 14
    body = combined_mark_svg(
        logo_cx,
        logo_cy,
        gear_inner,
        gear_outer,
        teeth,
        gear_fill="url(#gearGrad)",
        mouth_angle=30,
        cutout_dx=32,
        cutout_dy=-6,
        cutout_r=82,
        cutout_fill=BG_TOP,
        eye_dx=-16,
        eye_dy=-46,
        eye_r=14,
    )

    cube_cx = logo_cx + 150
    cube_cy = logo_cy - 8
    cube_size = 26

    return f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="{width}" height="{height}">
  <defs>
    <linearGradient id="bgGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="{BG_TOP}"/>
      <stop offset="100%" stop-color="{BG_BOTTOM}"/>
    </linearGradient>
    <radialGradient id="gearGrad" cx="40%" cy="35%" r="60%">
      <stop offset="0%" stop-color="{GEAR_LIGHT}"/>
      <stop offset="100%" stop-color="{GEAR_MID}"/>
    </radialGradient>
    <linearGradient id="titleGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="{GOLD_LIGHT}"/>
      <stop offset="100%" stop-color="{GOLD}"/>
    </linearGradient>
  </defs>

  <!-- Background -->
  <rect width="{width}" height="{height}" fill="url(#bgGrad)"/>

  <!-- Stars -->
  <g>
    {stars_svg(width, height, 200, 99, 0.9)}
  </g>

  <!-- Incoming cube -->
  {cube_svg(cube_cx, cube_cy, cube_size)}

  {body}

  {sparkle_svg(logo_cx - 170, logo_cy - 30, 10)}
  {sparkle_svg(logo_cx + 190, logo_cy + 80, 8)}

  <!-- Right side: text content -->
  <text x="{width * 0.62:.0f}" y="{height * 0.32:.0f}" text-anchor="middle"
        font-family="'Segoe UI', 'Helvetica Neue', Arial, sans-serif"
        font-size="80" font-weight="bold" letter-spacing="6"
        fill="url(#titleGrad)">LUNA2D</text>

  <text x="{width * 0.62:.0f}" y="{height * 0.43:.0f}" text-anchor="middle"
        font-family="'Segoe UI', 'Helvetica Neue', Arial, sans-serif"
        font-size="24" letter-spacing="8"
        fill="{SUBTITLE_COLOR}">2D GAME ENGINE</text>

  <line x1="{width*0.45:.0f}" y1="{height*0.48:.0f}"
        x2="{width*0.79:.0f}" y2="{height*0.48:.0f}"
        stroke="{SUBTITLE_COLOR}" stroke-width="1" opacity="0.3"/>

  <!-- Feature highlights -->
  <text x="{width * 0.62:.0f}" y="{height * 0.58:.0f}" text-anchor="middle"
        font-family="'Segoe UI', 'Helvetica Neue', Arial, sans-serif"
        font-size="16" fill="{POWERED_COLOR}">Rust + Lua  ·  GPU Rendering  ·  ~20 MB  ·  AI-First</text>

  <text x="{width * 0.62:.0f}" y="{height * 0.66:.0f}" text-anchor="middle"
        font-family="'Segoe UI', 'Helvetica Neue', Arial, sans-serif"
        font-size="14" fill="{POWERED_COLOR}" opacity="0.7">wgpu · rapier2d · rodio · LuaJIT</text>

  <!-- Sparkles around title -->
  {sparkle_svg(width*0.45, height*0.25, 12, GOLD_LIGHT)}
  {sparkle_svg(width*0.80, height*0.28, 9, GOLD_LIGHT)}
</svg>'''


def gen_vscode_icon(size: int = 128) -> str:
    """128×128 VS Code extension icon."""
    cx, cy = size / 2, size / 2
    body = combined_mark_svg(
        cx,
        cy,
        size * 0.28,
        size * 0.36,
        10,
        cutout_dx=size * 0.09,
        cutout_dy=-size * 0.02,
        cutout_r=size * 0.22,
        cutout_fill=NAVY_DARK,
        eye_dx=-size * 0.05,
        eye_dy=-size * 0.14,
        eye_r=size * 0.04,
    )
    cube_cx = cx + size * 0.22
    cube_cy = cy - size * 0.02
    cube_size = size * 0.07

    return f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {size} {size}" width="{size}" height="{size}">
  <defs>
    <radialGradient id="gearGrad" cx="40%" cy="35%" r="60%">
      <stop offset="0%" stop-color="{GEAR_LIGHT}"/>
      <stop offset="100%" stop-color="{GEAR_MID}"/>
    </radialGradient>
    <radialGradient id="bgGrad" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="{NAVY}"/>
      <stop offset="100%" stop-color="{NAVY_DARK}"/>
    </radialGradient>
  </defs>

  <!-- Rounded background -->
  <rect x="4" y="4" width="{size-8}" height="{size-8}" rx="16" ry="16" fill="url(#bgGrad)"/>

  <!-- Incoming cube -->
  {cube_svg(cube_cx, cube_cy, cube_size)}

  <!-- Single Luna mark -->
  {body}
</svg>'''


# ── PNG Conversion ──────────────────────────────────────────────────────────

def convert_svg_to_png(svg_path: Path, png_path: Path, width: int, height: int) -> bool:
    """Convert SVG to PNG using cairosvg if available."""
    try:
        import cairosvg
        cairosvg.svg2png(
            url=str(svg_path),
            write_to=str(png_path),
            output_width=width,
            output_height=height,
        )
        return True
        except (ImportError, OSError):
        return False


# ── Main ────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Generate Luna2D branding assets")
    parser.add_argument("--svg-only", action="store_true", help="Generate SVGs only")
    parser.add_argument("--list", action="store_true", help="List output files and exit")
    args = parser.parse_args()

    outputs = {
        "assets/svg/logo-simple.svg": (gen_logo_simple, 256, 256),
        "assets/svg/logo-large.svg": (gen_logo_large, 512, 512),
        "assets/svg/splash.svg": (gen_splash, 800, 600),
        "assets/svg/banner.svg": (gen_banner, 1280, 640),
        "assets/svg/vscode-icon.svg": (gen_vscode_icon, 128, 128),
    }

    png_map = {
        "assets/svg/logo-simple.svg": ("assets/icon.png", 256, 256),
        "assets/svg/logo-large.svg": ("assets/icon-large.png", 512, 512),
        "assets/svg/splash.svg": ("assets/splash.png", 800, 600),
        "assets/svg/banner.svg": ("assets/banner.png", 1280, 640),
        "assets/svg/vscode-icon.svg": ("assets/vscode-icon.png", 128, 128),
    }

    if args.list:
        print("SVG outputs:")
        for path in outputs:
            print(f"  {path}")
        print("\nPNG outputs:")
        for svg, (png, w, h) in png_map.items():
            print(f"  {png} ({w}×{h})")
        return

    # Create directories
    SVG_DIR.mkdir(parents=True, exist_ok=True)

    # Generate SVGs
    for rel_path, (gen_fn, w, h) in outputs.items():
        out_path = WORKSPACE / rel_path
        svg_content = gen_fn(w, h) if gen_fn.__code__.co_argcount == 2 else gen_fn(w)
        out_path.write_text(svg_content, encoding="utf-8")
        print(f"  SVG: {rel_path}")

    if args.svg_only:
        print("\nDone (SVG only).")
        return

    # Convert to PNG
    print()
    converted = 0
    for svg_rel, (png_rel, w, h) in png_map.items():
        svg_path = WORKSPACE / svg_rel
        png_path = WORKSPACE / png_rel
        if convert_svg_to_png(svg_path, png_path, w, h):
            print(f"  PNG: {png_rel}")
            converted += 1

    if converted == 0:
        print("  [!] cairosvg not installed — PNG conversion skipped.")
        print("      Install with: pip install cairosvg")
        print("      Or convert manually: open SVGs in a browser and export.")
    else:
        print(f"\nDone. {len(outputs)} SVGs + {converted} PNGs generated.")


if __name__ == "__main__":
    main()
