#!/usr/bin/env python3
"""
organize_demos.py — Three-in-one demos maintenance tool.

Does:
  1. Moves each demo into content/demos/<category>/<name>/
  2. Generates a placeholder 800×600 screen.png for demos that don't have one
  3. Rewrites content/demos/README.md as a single table with per-row thumbnails

Usage:
    python tools/content/demos/organize_demos.py [--no-move] [--no-png] [--no-readme] [--dry-run]
"""

import argparse
import shutil
import sys
from pathlib import Path

# ── Category map ──────────────────────────────────────────────────────────────
# Format: "demo_name": "category_folder"

CATEGORIES = {
    # ── Classic Arcade ────────────────────────────────────────────────────────
    "pong":            "arcade",
    "pac_man":         "arcade",
    "tetris":          "arcade",
    "snake":           "arcade",
    "space_invaders":  "arcade",
    "galaga":          "arcade",
    "asteroids":       "arcade",
    "centipede":       "arcade",
    "frogger":         "arcade",
    "donkey_kong":     "arcade",

    # ── Retro Classics (C-64 / Amiga) ────────────────────────────────────────
    "boulder_dash":    "retro",
    "giana_sisters":   "retro",
    "commando":        "retro",
    "paradroid":       "retro",
    "turrican":        "retro",
    "lemmings":        "retro",
    "cannon_fodder":   "retro",
    "sensible_soccer": "retro",
    "another_world":   "retro",
    "shadow_beast":    "retro",

    # ── Sports ────────────────────────────────────────────────────────────────
    "tennis_classic":      "sports",
    "track_and_field":     "sports",
    "ski_jump":            "sports",
    "boxing_ring":         "sports",
    "golf_classic":        "sports",
    "drift_racing":        "sports",
    "fishing":             "sports",
    "pinball":             "sports",
    "rhythm_game":         "sports",
    "trajectory_sports":   "sports",
    "sports_manager":      "sports",

    # ── Action / Platformer ────────────────────────────────────────────────────
    "platformer":       "action",
    "metroidvania":     "action",
    "bullet_hell":      "action",
    "horde_survivor":   "action",
    "roguelite":        "action",
    "soulslike":        "action",
    "fighting_game":    "action",
    "platform_fighter": "action",
    "vertical_climber": "action",
    "stealth":          "action",
    "infiltration":     "action",
    "sniper":           "action",
    "endless_runner":   "action",
    "brick_breaker":    "action",

    # ── Strategy / Puzzle ─────────────────────────────────────────────────────
    "physics_puzzle":  "strategy",
    "bridge_builder":  "strategy",
    "logic_game":      "strategy",
    "match3":          "strategy",
    "maze_defense":    "strategy",
    "hex_strategy":    "strategy",
    "tactical_battle": "strategy",
    "wargame":         "strategy",
    "rts":             "strategy",
    "deckbuilder":     "strategy",
    "card_game":       "strategy",
    "tower_defense":   "strategy",
    "party_games":     "strategy",

    # ── Simulation / Management ───────────────────────────────────────────────
    "physics_demo":    "simulation",
    "physics_sandbox": "simulation",
    "colony_sim":      "simulation",
    "idle_game":       "simulation",
    "tycoon":          "simulation",
    "zoo_tycoon":      "simulation",
    "hotel_manager":   "simulation",
    "tower_sim":       "simulation",
    "factory":         "simulation",
    "farming_sim":     "simulation",
    "mining":          "simulation",
    "railroad":        "simulation",
    "medical_sim":     "simulation",
    "god_game":        "simulation",
    "vehicle_builder": "simulation",
    "cooking_sim":     "simulation",
    "wildlife_photo":  "simulation",

    # ── RPG / Narrative ────────────────────────────────────────────────────────
    "roguelike":          "rpg",
    "adventure":          "rpg",
    "creature_collector": "rpg",
    "loot_rpg_demo":      "rpg",
    "visual_novel":       "rpg",
    "dialog_demo":        "rpg",
    "courtroom":          "rpg",
    "social_deduction":   "rpg",
    "alchemy":            "rpg",
    "merchant_demo":      "rpg",
    "horror":             "rpg",
    "survival_crafting":  "rpg",

    # ── Engine Showcase ────────────────────────────────────────────────────────
    "hello_world":         "showcase",
    "sprites":             "showcase",
    "demo_game":           "showcase",
    "particles_demo":      "showcase",
    "scene_demo":          "showcase",
    "tween_demo":          "showcase",
    "signal_demo":         "showcase",
    "patterns_demo":       "showcase",
    "minimap_demo":        "showcase",
    "nine_slice_demo":     "showcase",
    "overlay_demo":        "showcase",
    "postfx_demo":         "showcase",
    "localization_demo":   "showcase",
    "light_demo":          "showcase",
    "light_showcase":      "showcase",
    "terminal_demo":       "showcase",
    "automation_demo":     "showcase",
    "debugbridge_demo":    "showcase",
    "devtools_demo":       "showcase",
    "docs_demo":           "showcase",
    "modding_demo":        "showcase",
    "province_demo":       "showcase",
    "hacking_game":        "showcase",
    "music_composer":      "showcase",
}

CATEGORY_LABELS = {
    "arcade":     "Classic Arcade",
    "retro":      "Retro Classics",
    "sports":     "Sports",
    "action":     "Action / Platformer",
    "strategy":   "Strategy / Puzzle",
    "simulation": "Simulation / Management",
    "rpg":        "RPG / Narrative",
    "showcase":   "Engine Showcase",
}

CATEGORY_ORDER = ["arcade", "retro", "sports", "action", "strategy", "simulation", "rpg", "showcase"]

# ── Description map ────────────────────────────────────────────────────────────

DESCRIPTIONS = {
    "pong":             "Classic 2-player paddle game — first to 7 wins",
    "pac_man":          "Grid maze, 4 ghosts, dots and power pellets",
    "tetris":           "7 tetrominos, rotation, ghost piece, line clearing",
    "snake":            "Growing snake — eat food, avoid yourself",
    "space_invaders":   "11×5 invader grid, destructible barriers",
    "galaga":           "Formation enemies with dive attacks and capture beam",
    "asteroids":        "Vector wireframe ship with inertia and splitting rocks",
    "centipede":        "Mushroom field, segmented centipede, bouncing spider",
    "frogger":          "Lane crossing, log riding, 5 lily-pad homes",
    "donkey_kong":      "Sloped platforms, rolling barrels, ladders",
    "boulder_dash":     "Dig through a cave, collect diamonds to escape",
    "giana_sisters":    "Side-scrolling platformer — gems, enemies, exit",
    "commando":         "Vertical-scroll top-down shooter with grenades",
    "paradroid":        "Space station shooter with robot transfer minigame",
    "turrican":         "Run-and-gun platformer with continuous energy beam",
    "lemmings":         "Assign jobs to guide lemmings to the exit",
    "cannon_fodder":    "3-man squad auto-fire shooter across 5 missions",
    "sensible_soccer":  "5v5 top-down football with CPU team AI",
    "another_world":    "3-scene cinematic platformer with shield deflection",
    "shadow_beast":     "Atmospheric parallax side-scroller — 3 stages",
    "tennis_classic":   "Top-down tennis — topspin, full scoring (Deuce/Adv)",
    "track_and_field":  "4 Olympic events: sprint, long jump, hurdles, hammer",
    "ski_jump":         "3-phase ski jump — crouch, fly, land",
    "boxing_ring":      "3-round boxing — jab, hook, block, CPU opponent",
    "golf_classic":     "9-hole golf with wind, water, bunkers, trees",
    "drift_racing":     "Top-down drift racing with physics",
    "fishing":          "Fishing minigame with rod physics",
    "pinball":          "Classic pinball machine",
    "rhythm_game":      "Musical rhythm note matching",
    "trajectory_sports":"Trajectory-based sports game",
    "sports_manager":   "Sports team management sim",
    "platformer":       "Side-scrolling character controller",
    "metroidvania":     "Exploration platformer with locked areas",
    "bullet_hell":      "Bullet-hell shoot-em-up",
    "horde_survivor":   "Vampire Survivors-style horde defense",
    "roguelite":        "Action roguelite with procedural runs",
    "soulslike":        "Stamina-based combat action game",
    "fighting_game":    "2-player fighting game",
    "platform_fighter":  "Smash-style platform fighting",
    "vertical_climber": "Vertical climbing platformer",
    "stealth":          "Stealth infiltration game",
    "infiltration":     "Stealth infiltration game (alternate)",
    "sniper":           "Precision sniping stealth game",
    "endless_runner":   "Auto-scrolling obstacle runner",
    "brick_breaker":    "Breakout-style brick-breaking game",
    "physics_puzzle":   "Physics-based puzzle game",
    "bridge_builder":   "Structural bridge building puzzle",
    "logic_game":       "Logic circuit puzzle game",
    "match3":           "Match-3 gem swapping puzzle",
    "maze_defense":     "Maze-building tower defense",
    "hex_strategy":     "Hex-grid turn-based strategy",
    "tactical_battle":  "Grid-based tactical combat",
    "wargame":          "Hex-grid military wargame",
    "rts":              "Real-time strategy base building",
    "deckbuilder":      "Roguelike deckbuilding card game",
    "card_game":        "Collectible card battles",
    "tower_defense":    "Tower placement defense game",
    "party_games":      "Multi-minigame party collection",
    "physics_demo":     "Rigid bodies, sensors, collisions demo",
    "physics_sandbox":  "Interactive physics sandbox",
    "colony_sim":       "Ant colony management sim",
    "idle_game":        "Incremental idle clicker",
    "tycoon":           "Theme park tycoon management",
    "zoo_tycoon":       "Zoo management tycoon",
    "hotel_manager":    "Hotel management tycoon",
    "tower_sim":        "Corporate tower building sim",
    "factory":          "Factory automation conveyor sim",
    "farming_sim":      "Crop planting and harvesting sim",
    "mining":           "Dig-down mining resource game",
    "railroad":         "Train network railroad tycoon",
    "medical_sim":      "Medical diagnosis triage game",
    "god_game":         "God simulation with worshippers",
    "vehicle_builder":  "Vehicle construction physics",
    "cooking_sim":      "Multi-step recipe cooking sim",
    "wildlife_photo":   "Wildlife photography safari",
    "roguelike":        "Turn-based dungeon roguelike",
    "adventure":        "Point-and-click adventure game",
    "creature_collector":"Monster catching and battling",
    "loot_rpg_demo":    "RPG loot and inventory demo",
    "visual_novel":     "Visual novel story engine demo",
    "dialog_demo":      "Typewriter text and branching dialog",
    "courtroom":        "Courtroom debate evidence game",
    "social_deduction": "Among Us-style social deduction",
    "alchemy":          "Potion brewing with ingredient combos",
    "merchant_demo":    "Shop and trading system demo",
    "horror":           "First-person horror exploration",
    "survival_crafting":"Survival crafting game",
    "hello_world":      "Minimal game: shapes, text, keyboard",
    "sprites":          "Sprite movement and mouse input",
    "demo_game":        "Complete shooting gallery game",
    "particles_demo":   "Particle emitter systems showcase",
    "scene_demo":       "Multi-screen state machine demo",
    "tween_demo":       "All easing curves side-by-side",
    "signal_demo":      "Pub-sub event bus demo",
    "patterns_demo":    "6 game design patterns in Lua",
    "minimap_demo":     "Fog-of-war overhead minimap demo",
    "nine_slice_demo":  "Scalable 9-patch UI panels demo",
    "overlay_demo":     "Z-ordered render layers demo",
    "postfx_demo":      "Post-processing effects stack",
    "localization_demo":"Multi-language string system demo",
    "light_demo":       "2D dynamic lighting demo",
    "light_showcase":   "Advanced lighting effects gallery",
    "terminal_demo":    "In-game developer terminal",
    "automation_demo":  "Automated input replay demo",
    "debugbridge_demo": "TCP debug server (JSON-RPC) demo",
    "devtools_demo":    "Runtime diagnostics overlay",
    "docs_demo":        "In-game API browser",
    "modding_demo":     "Mod discovery and loading demo",
    "province_demo":    "Province map strategy demo",
    "hacking_game":     "Network-hacking puzzle game",
    "music_composer":   "Music sequencer and composer",
}

# ── Placeholder PNG palette per category ─────────────────────────────────────

CATEGORY_COLORS = {
    "arcade":     ((18, 18, 80), (60, 60, 200), "CLASSIC ARCADE"),
    "retro":      ((30, 15, 40), (160, 80, 220), "RETRO CLASSICS"),
    "sports":     ((10, 50, 10), (60, 180, 60), "SPORTS"),
    "action":     ((60, 10, 10), (220, 60, 60), "ACTION"),
    "strategy":   ((10, 40, 50), (40, 160, 180), "STRATEGY"),
    "simulation": ((40, 30, 10), (200, 160, 40), "SIMULATION"),
    "rpg":        ((20, 20, 40), (120, 90, 200), "RPG"),
    "showcase":   ((15, 35, 15), (40, 180, 100), "SHOWCASE"),
}


# ── Utilities ────────────────────────────────────────────────────────────────

def label(name: str) -> str:
    return name.replace("_", " ").title()


def make_placeholder(dest: Path, category: str, demo_name: str, dry_run: bool) -> None:
    """Generate an 800×600 placeholder PNG with category colour and demo name."""
    if dry_run:
        print(f"  [dry-run] would generate placeholder: {dest}")
        return
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        print("  [warn] Pillow not installed — skipping placeholder generation")
        return

    bg, fg, cat_text = CATEGORY_COLORS.get(category, ((20, 20, 20), (180, 180, 180), category.upper()))
    w, h = 800, 600
    img = Image.new("RGB", (w, h), bg)
    draw = ImageDraw.Draw(img)

    # Grid lines (subtle)
    grid_col = tuple(min(255, c + 15) for c in bg)
    for x in range(0, w, 80):
        draw.line([(x, 0), (x, h)], fill=grid_col, width=1)
    for y in range(0, h, 60):
        draw.line([(0, y), (w, y)], fill=grid_col, width=1)

    # Corner accent
    accent = tuple(min(255, c + 60) for c in fg)
    draw.rectangle([0, 0, 8, h], fill=accent)
    draw.rectangle([w - 8, 0, w, h], fill=accent)
    draw.rectangle([0, 0, w, 8], fill=accent)
    draw.rectangle([0, h - 8, w, h], fill=accent)

    # Category label (small, top)
    try:
        font_big  = ImageFont.truetype("arial.ttf", 56)
        font_med  = ImageFont.truetype("arial.ttf", 28)
        font_small = ImageFont.truetype("arial.ttf", 20)
    except OSError:
        font_big  = ImageFont.load_default()
        font_med  = font_big
        font_small = font_big

    # Category banner
    draw.rectangle([0, 0, w, 52], fill=tuple(int(c * 0.6) for c in fg))
    _text_center(draw, cat_text, w // 2, 26, font_small, (220, 220, 220))

    # Demo name — big centred
    dname = label(demo_name)
    _text_center(draw, dname, w // 2, h // 2 - 20, font_big, fg)

    # Subtitle
    _text_center(draw, "Lurek2D Demo", w // 2, h // 2 + 55, font_med,
                 tuple(min(255, c + 40) for c in fg))

    # "No screenshot yet" notice
    _text_center(draw, "[ screenshot not yet captured ]", w // 2, h - 40, font_small,
                 (120, 120, 120))

    dest.parent.mkdir(parents=True, exist_ok=True)
    img.save(str(dest), "PNG")
    print(f"  generated placeholder: {dest.relative_to(dest.parents[3])}")


def _text_center(draw, text: str, cx: int, cy: int, font, color) -> None:
    try:
        bbox = draw.textbbox((0, 0), text, font=font)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        draw.text((cx - tw // 2, cy - th // 2), text, font=font, fill=color)
    except Exception:
        draw.text((cx, cy), text, font=font, fill=color)


# ── Step 1 : Move demos into category subfolders ──────────────────────────────

def reorganize(demos_dir: Path, dry_run: bool) -> dict:
    """
    Move content/demos/<name>/ → content/demos/<category>/<name>/
    Returns mapping {name: new_relative_path} for use by README writer.
    """
    moved = {}
    for name, category in CATEGORIES.items():
        src = demos_dir / name
        if not src.is_dir():
            print(f"  [skip] {name} — source not found")
            continue
        dest = demos_dir / category / name
        if dest.exists():
            print(f"  [skip] {name} — already at {category}/{name}")
            moved[name] = f"{category}/{name}"
            continue
        if dry_run:
            print(f"  [dry-run] mv {name} -> {category}/{name}")
        else:
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(src), str(dest))
            print(f"  moved {name} -> {category}/{name}")
        moved[name] = f"{category}/{name}"
    return moved


# ── Step 2 : Generate placeholder PNGs ───────────────────────────────────────

def gen_placeholders(demos_dir: Path, moved: dict, dry_run: bool) -> None:
    for name, rel_path in moved.items():
        png = demos_dir / rel_path / "screen.png"
        if png.exists():
            continue
        category = CATEGORIES.get(name, "showcase")
        make_placeholder(png, category, name, dry_run)


# ── Step 3 : Rewrite README ────────────────────────────────────────────────────

README_HEADER = """\
# Lurek2D Demos

{total} fully playable demo games, organized by category.
Every demo is self-contained: run with `cargo run -- content/demos/<category>/<name>`.

For API reference code (not runnable games), see [`content/examples/`](../content/examples/).

---

## Running a Demo

```bash
cargo run -- content/demos/<category>/<name>          # debug build
cargo run --release -- content/demos/<category>/<name>  # release build
luna content/demos/<category>/<name>                  # installed binary
```

---

"""

TABLE_SECTION = """\
## {label}

| Preview | Demo | Description |
|:-------:|------|-------------|
{rows}

"""

ROW_TEMPLATE = "| {thumb} | [{name}]({rel_path}) | {desc} |"

FOOTER = """\
---

## See Also

- [`content/examples/`](../content/examples/) — API reference code (one `.lua` file per module)
- [`content/library/`](../content/library/) — Reusable pure-Lua gameplay libraries
- [Getting Started](../docs/getting_started.md) — Build your first game with Lurek2D
"""


def write_readme(demos_dir: Path, moved: dict, dry_run: bool) -> None:
    sections = []

    for cat in CATEGORY_ORDER:
        cat_label = CATEGORY_LABELS[cat]
        rows = []
        for name, cat2 in CATEGORIES.items():
            if cat2 != cat:
                continue
            rel_path = moved.get(name, f"{cat}/{name}")
            png_rel = f"{rel_path}/screen.png"
            png_abs = demos_dir / rel_path / "screen.png"

            if png_abs.exists():
                thumb = f'<img src="{png_rel}" width="160" height="120" alt="{label(name)}">'
            else:
                thumb = "*(no screenshot)*"

            desc = DESCRIPTIONS.get(name, "")
            rows.append(ROW_TEMPLATE.format(
                thumb=thumb,
                name=label(name),
                rel_path=rel_path,
                desc=desc,
            ))

        if rows:
            sections.append(TABLE_SECTION.format(
                label=cat_label,
                rows="\n".join(rows),
            ))

    total = len(CATEGORIES)
    content = README_HEADER.format(total=total) + "".join(sections) + FOOTER

    out = demos_dir / "README.md"
    if dry_run:
        print(f"  [dry-run] would write {out} ({len(content)} chars)")
    else:
        out.write_text(content, encoding="utf-8")
        print(f"  wrote {out} ({len(content)} chars, {content.count(chr(10))} lines)")


# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--no-move",   action="store_true", help="Skip reorganizing into subfolders")
    parser.add_argument("--no-png",    action="store_true", help="Skip placeholder PNG generation")
    parser.add_argument("--no-readme", action="store_true", help="Skip README rewrite")
    parser.add_argument("--dry-run",   action="store_true", help="Print what would happen, don't touch disk")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent.parent
    demos_dir = repo_root / "content" / "demos"

    if not demos_dir.is_dir():
        print(f"ERROR: content/demos/ not found at {demos_dir}", file=sys.stderr)
        sys.exit(1)

    # Step 1 — Reorganize
    if not args.no_move:
        print("\n[1/3] Reorganizing demo folders...")
        moved = reorganize(demos_dir, args.dry_run)
    else:
        print("\n[1/3] Skipping reorganization (--no-move).")
        # Build 'moved' from current disk state
        moved = {}
        for name, cat in CATEGORIES.items():
            dest = demos_dir / cat / name
            if dest.exists():
                moved[name] = f"{cat}/{name}"
            elif (demos_dir / name).exists():
                moved[name] = name  # still flat
            else:
                pass  # missing

    # Step 2 — Placeholders
    if not args.no_png:
        print("\n[2/3] Generating placeholder PNGs...")
        gen_placeholders(demos_dir, moved, args.dry_run)
    else:
        print("\n[2/3] Skipping PNGs (--no-png).")

    # Step 3 — README
    if not args.no_readme:
        print("\n[3/3] Rewriting content/demos/README.md...")
        write_readme(demos_dir, moved, args.dry_run)
    else:
        print("\n[3/3] Skipping README (--no-readme).")

    print("\nDone.")


if __name__ == "__main__":
    main()
