# tools/assets — Asset Generators

Scripts that **generate** engine branding and visual assets: the splash
screen, window icon, SVG logos, and other graphics assets embedded in
the engine binary.

Run after changing branding or when setting up a new development environment:

```powershell
# Regenerate both splash and icon
python tools/assets/gen_splash.py
python tools/assets/gen_icon.py
```

## Scripts

| Script | Purpose | Output |
|---|---|---|
| `gen_branding.py` | Generate all branding SVGs and optional PNG conversions | `assets/svg/*` |
| `gen_icon.py` | Regenerate window icon in multiple sizes | `assets/icon.ico` + `assets/icon.png` |
| `gen_splash.py` | Regenerate the engine splash screen | `assets/splash.png` |
| `gen_svg_assets.py` | Write hardcoded Luna2D SVG logo files inline | `assets/svg/*.svg` |

## Requirements

```powershell
pip install Pillow          # needed by gen_icon.py and gen_splash.py
pip install cairosvg        # optional — gen_splash.py uses it for higher-quality PNG
```

## Notes

The **runtime splash screen** is drawn procedurally in `src/engine/app.rs`
via `make_splash_commands()`. Regenerating `assets/splash.png` only affects
the PNG file on disk — you must also rebuild the engine to embed it.
