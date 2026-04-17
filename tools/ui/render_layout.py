#!/usr/bin/env python3
"""Render Lurek2D TOML UI layout files to PNG wireframe previews.

Each widget is drawn as a colour-coded filled rectangle with a white border
and a label showing:  <widget_type> [id]

The output image has the same resolution as declared in the layout file:
  1. ``resolution = [width, height]``  top-level key  (preferred, explicit)
  2. ``root.w`` x ``root.h``           from the root widget size
  3. 1280 x 720                         hardcoded fallback

One PNG is written per input TOML file, in the same directory, with the same
stem: ``my_hud.toml`` -> ``my_hud.png``.

Requirements:
    pip install Pillow tomli          (Python < 3.11)
    Pillow is the only dependency on Python >= 3.11 (tomllib is built-in).

Usage:
    # Render a single layout file:
    python tools/ui/render_layout.py content/demos/my_game/hud.toml

    # Render all *.layout.toml files under content/:
    python tools/ui/render_layout.py --all content/

    # Render all *.layout.toml files under content/ recursively:
    python tools/ui/render_layout.py --all content/ --recursive

    # Preview: print what would be rendered without writing files:
    python tools/ui/render_layout.py --dry-run content/demos/my_game/hud.toml

Exit codes:
    0  - all files rendered successfully
    1  - one or more files failed to render (details printed to stderr)
"""

from __future__ import annotations

import argparse
import sys
import traceback
from pathlib import Path
from typing import Any

# ---------------------------------------------------------------------------
# TOML loading -- stdlib tomllib (Python >= 3.11) with tomli fallback
# ---------------------------------------------------------------------------
try:
    import tomllib  # type: ignore[import]
except ModuleNotFoundError:
    try:
        import tomli as tomllib  # type: ignore[import]
    except ModuleNotFoundError:
        print(
            "ERROR: tomllib not available.\n"
            "  Python >= 3.11 includes tomllib in the standard library.\n"
            "  For Python 3.9/3.10 run:  pip install tomli",
            file=sys.stderr,
        )
        sys.exit(1)

# ---------------------------------------------------------------------------
# Pillow
# ---------------------------------------------------------------------------
try:
    from PIL import Image, ImageDraw, ImageFont  # type: ignore[import]
except ModuleNotFoundError:
    print(
        "ERROR: Pillow not found.  Install it with:  pip install Pillow",
        file=sys.stderr,
    )
    sys.exit(1)

# ---------------------------------------------------------------------------
# Widget colour palette — each type has a visually distinct, saturated hue
# ---------------------------------------------------------------------------
_WIDGET_COLORS: dict[str, tuple[int, int, int, int]] = {
    # Interaction controls — warm blues / indigos
    "button":       ( 70, 130, 230, 220),
    "radiobutton":  ( 90, 100, 220, 220),
    "switch":       ( 50, 180, 200, 220),
    "spinbox":      ( 60, 150, 210, 220),
    # Text / input — near-white tints
    "textinput":    (200, 210, 230, 210),
    "label":        ( 40, 200, 120, 200),
    "combobox":     (160,  80, 220, 220),
    # Boolean — ambers
    "checkbox":     (220, 160,  30, 220),
    # Progress / ranges — greens
    "slider":       ( 30, 180,  80, 220),
    "progressbar":  ( 30, 160,  90, 220),
    "scrollbar":    ( 50, 140,  80, 200),
    # Containers — dark greys / navy, low alpha so children show
    "panel":        ( 45,  55,  90, 160),
    "scrollpanel":  ( 40,  60,  80, 160),
    "layout":       ( 35,  45,  70, 120),
    "splitpanel":   ( 50,  60,  85, 160),
    "dockpanel":    ( 45,  55,  80, 160),
    "guiwindow":    ( 55,  65, 100, 170),
    "dialog":       ( 60,  70, 120, 200),
    # Navigation / chrome — deep charcoals
    "menubar":      ( 30,  30,  45, 255),
    "menuitem":     ( 55,  60,  80, 230),
    "toolbar":      ( 35,  40,  60, 255),
    "tabbar":       ( 75,  75, 150, 230),
    "statusbar":    ( 30,  30,  45, 255),
    # Lists / trees — teals
    "listbox":      ( 40, 130, 150, 220),
    "treeview":     ( 40, 150, 120, 220),
    "guitable":     ( 50, 110, 140, 220),
    # Decorative / structure — neutral
    "separator":    (100, 100, 110, 200),
    "spacer":       (  0,   0,   0,   0),
    # Media / graphics
    "imagewidget":  ( 80, 120, 170, 220),
    "ninepatch":    ( 70, 110, 140, 220),
    # Misc
    "accordion":    (130,  60, 160, 220),
    "colorpicker":  (220,  80, 100, 220),
    "badge":        (220,  50,  50, 230),
    "tooltippanel": (210, 200, 130, 210),
}

_DEFAULT_COLOR: tuple[int, int, int, int] = (140, 140, 160, 200)
_FALLBACK_RESOLUTION: tuple[int, int] = (1280, 720)
_BORDER_COLOR: tuple[int, int, int, int] = (255, 255, 255, 200)
_BORDER_WIDTH: int = 1      # 1-pixel crisp border
_TEXT_COLOR: tuple[int, int, int, int] = (255, 255, 255, 255)
_TEXT_SHADOW: tuple[int, int, int, int] = (0, 0, 0, 220)
_BG_COLOR: tuple[int, int, int, int] = (22, 22, 32, 255)
# Minimum widget size to draw a label inside it
_MIN_LABEL_W: int = 16
_MIN_LABEL_H: int = 10


def _widget_color(widget_type: str) -> tuple[int, int, int, int]:
    return _WIDGET_COLORS.get(widget_type.lower(), _DEFAULT_COLOR)


# ---------------------------------------------------------------------------
# Layout resolution detection
# ---------------------------------------------------------------------------
def _layout_resolution(data: dict[str, Any]) -> tuple[int, int]:
    """Determine output image resolution from layout TOML data.

    Priority:
      1. Top-level ``resolution = [w, h]``
      2. ``root.w`` and ``root.h``
      3. Hardcoded fallback 1280 x 720
    """
    res = data.get("resolution")
    if res and len(res) == 2:
        w, h = int(res[0]), int(res[1])
        if w > 0 and h > 0:
            return w, h

    root = data.get("root", {})
    rw = root.get("w", 0.0)
    rh = root.get("h", 0.0)
    if rw and rh and float(rw) > 0 and float(rh) > 0:
        return int(float(rw)), int(float(rh))

    return _FALLBACK_RESOLUTION


# ---------------------------------------------------------------------------
# Widget tree renderer
# ---------------------------------------------------------------------------
def _load_font(size: int) -> ImageFont.ImageFont:
    """Try to load a decent font; fall back to PIL default."""
    # Try common system fonts
    candidates = [
        "DejaVuSans.ttf",
        "arial.ttf",
        "Arial.ttf",
        "LiberationSans-Regular.ttf",
        "FreeSans.ttf",
        "Verdana.ttf",
    ]
    for name in candidates:
        try:
            return ImageFont.truetype(name, size)
        except (IOError, OSError):
            pass
    return ImageFont.load_default()


_FONT_CACHE: dict[int, ImageFont.ImageFont] = {}


def _font(size: int) -> ImageFont.ImageFont:
    if size not in _FONT_CACHE:
        _FONT_CACHE[size] = _load_font(size)
    return _FONT_CACHE[size]


def _draw_widget(
    draw: ImageDraw.ImageDraw,
    widget: dict[str, Any],
    parent_x: float,
    parent_y: float,
    img_w: int,
    img_h: int,
    depth: int = 0,
) -> None:
    """Recursively draw a widget and its children onto `draw`."""
    wtype = widget.get("widget_type", "panel").lower()
    wid   = widget.get("id", "")

    x = parent_x + float(widget.get("x", 0.0))
    y = parent_y + float(widget.get("y", 0.0))
    w = float(widget.get("w", 0.0))
    h = float(widget.get("h", 0.0))

    # Auto-size: fill parent when w/h == 0 (simplified: use remaining parent space)
    if w <= 0:
        w = max(img_w - x, 4.0)
    if h <= 0:
        h = max(img_h - y, 4.0)

    # 1-pixel inset — border and fill stay entirely INSIDE the declared x/y/w/h rect
    INSET = 1
    x0 = int(x) + INSET
    y0 = int(y) + INSET
    x1 = int(x + w) - INSET
    y1 = int(y + h) - INSET

    # Clamp to image bounds
    x0c = max(0, x0)
    y0c = max(0, y0)
    x1c = min(img_w - 1, x1)
    y1c = min(img_h - 1, y1)

    if x1c <= x0c or y1c <= y0c:
        # Off-screen or zero size — still recurse children (may be visible)
        _draw_children(draw, widget, parent_x + float(widget.get("x", 0.0)),
                       parent_y + float(widget.get("y", 0.0)), img_w, img_h, depth)
        return

    # Fill
    color = _widget_color(wtype)
    if color[3] > 0:
        draw.rectangle([x0c, y0c, x1c, y1c], fill=color)

    # 1-pixel border
    draw.rectangle(
        [x0c, y0c, x1c, y1c],
        outline=_BORDER_COLOR,
        width=_BORDER_WIDTH,
    )

    # ── Treeview: draw indent-level markers ──────────────────────────────────
    if wtype == "treeview":
        # Simulate 3 collapsed tree rows
        for i, (indent, has_child) in enumerate([(0, True), (1, True), (2, False)]):
            row_y = y0c + 4 + i * 14
            if row_y + 10 > y1c:
                break
            ix = x0c + 4 + indent * 12
            if has_child:
                # Triangle marker ▶
                draw.polygon(
                    [(ix, row_y + 2), (ix + 6, row_y + 5), (ix, row_y + 8)],
                    fill=(180, 220, 200, 200),
                )
            draw.line([(ix + 10, row_y + 5), (x1c - 4, row_y + 5)],
                      fill=(160, 200, 180, 160), width=1)

    # Label: show only  [id]  or bare widget_type when no id
    pw = x1c - x0c
    ph = y1c - y0c
    if pw >= _MIN_LABEL_W and ph >= _MIN_LABEL_H:
        label = f"[{wid}]" if wid else wtype

        # Pick font size based on widget height
        fsize = max(7, min(11, ph // 3))
        font  = _font(fsize)

        # Center the label in the widget
        try:
            bb = draw.textbbox((0, 0), label, font=font)
            tw = bb[2] - bb[0]
            th = bb[3] - bb[1]
        except AttributeError:
            tw, th = draw.textsize(label, font=font)  # type: ignore[attr-defined]

        tx = x0c + (pw - tw) // 2
        ty = y0c + (ph - th) // 2

        # Shadow + label
        draw.text((tx + 1, ty + 1), label, font=font, fill=_TEXT_SHADOW)
        draw.text((tx, ty),         label, font=font, fill=_TEXT_COLOR)

    _draw_children(draw, widget, parent_x + float(widget.get("x", 0.0)),
                   parent_y + float(widget.get("y", 0.0)), img_w, img_h, depth)


def _draw_children(
    draw: ImageDraw.ImageDraw,
    widget: dict[str, Any],
    parent_x: float,
    parent_y: float,
    img_w: int,
    img_h: int,
    depth: int,
) -> None:
    for child in widget.get("children", []):
        _draw_widget(draw, child, parent_x, parent_y, img_w, img_h, depth + 1)


# ---------------------------------------------------------------------------
# Public render function
# ---------------------------------------------------------------------------
def render_layout(toml_path: Path, dry_run: bool = False) -> Path:
    """Parse *toml_path* and write a PNG wireframe preview next to it.

    Parameters
    ----------
    toml_path:
        Path to a ``.toml`` UI layout file.
    dry_run:
        When ``True``, skip writing the PNG and just return the *would-be* output path.

    Returns
    -------
    Path
        The path of the written (or would-be written) PNG file.

    Raises
    ------
    ValueError
        If the TOML file does not contain a ``[root]`` section.
    """
    data: dict[str, Any] = tomllib.loads(toml_path.read_text(encoding="utf-8"))

    if "root" not in data:
        raise ValueError(f"{toml_path}: missing [root] section — not a valid layout file")

    img_w, img_h = _layout_resolution(data)
    out_path = toml_path.with_suffix(".png")

    if dry_run:
        print(f"  [dry-run] would write {out_path}  ({img_w}x{img_h})")
        return out_path

    # Create image with dark background
    img  = Image.new("RGBA", (img_w, img_h), _BG_COLOR)
    draw = ImageDraw.Draw(img, "RGBA")

    _draw_widget(draw, data["root"], 0.0, 0.0, img_w, img_h)

    # Draw resolution watermark in bottom-left corner (avoids top-corner content)
    watermark = f"{img_w}x{img_h}  {toml_path.stem}"
    fnt = _font(10)
    draw.text((4, img_h - 4), watermark, font=fnt, fill=(150, 150, 160, 160), anchor="lb")

    img.save(str(out_path), "PNG")
    return out_path


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def _collect_files(paths: list[str], recursive: bool) -> list[Path]:
    """Expand paths to a list of .toml files."""
    result: list[Path] = []
    for raw in paths:
        p = Path(raw)
        if p.is_file():
            result.append(p)
        elif p.is_dir():
            pattern = "**/*.layout.toml" if recursive else "*.layout.toml"
            found = sorted(p.glob(pattern))
            if not found:
                # Also try plain *.toml if no *.layout.toml found
                pattern2 = "**/*.toml" if recursive else "*.toml"
                found = [
                    f for f in sorted(p.glob(pattern2))
                    if "root" in _try_read_toml(f)
                ]
            result.extend(found)
        else:
            print(f"WARNING: {raw} does not exist — skipping", file=sys.stderr)
    return result


def _try_read_toml(path: Path) -> dict:
    try:
        return tomllib.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "paths",
        nargs="*",
        metavar="PATH",
        help="TOML layout file(s) or director(ies) to render",
    )
    parser.add_argument(
        "--all",
        dest="scan_dirs",
        nargs="*",
        metavar="DIR",
        default=None,
        help="Scan directories for *.layout.toml files (default: content/)",
    )
    parser.add_argument(
        "--recursive",
        action="store_true",
        help="Recurse into subdirectories when scanning",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print what would be rendered without writing files",
    )
    args = parser.parse_args()

    # Collect input files
    input_paths: list[str] = list(args.paths)
    if args.scan_dirs is not None:
        dirs = args.scan_dirs if args.scan_dirs else ["content/"]
        input_paths.extend(dirs)

    if not input_paths:
        parser.print_help()
        return 0

    files = _collect_files(input_paths, recursive=args.recursive)
    if not files:
        print("No layout TOML files found.", file=sys.stderr)
        return 1

    failures: list[str] = []
    for f in files:
        try:
            out = render_layout(f, dry_run=args.dry_run)
            if not args.dry_run:
                print(f"  rendered  {out}")
        except Exception as exc:
            msg = f"  FAILED    {f}: {exc}"
            print(msg, file=sys.stderr)
            if "--verbose" in sys.argv or "-v" in sys.argv:
                traceback.print_exc()
            failures.append(str(f))

    if failures:
        print(f"\n{len(failures)} file(s) failed to render.", file=sys.stderr)
        return 1

    total = len(files)
    if not args.dry_run:
        print(f"\nDone. {total} layout(s) rendered.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
