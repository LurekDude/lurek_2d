#!/usr/bin/env python3
"""
gen_coverage_gaps.py — Generate an API gap report for Lurek2D.

Reads rust_api_data.json and lua_api_data.json, then produces a Markdown report
showing three categories of issues:

  1. Rust methods that exist publicly but are NOT exposed to Lua (no matching entry in
     lua_api_data.json). This highlights functionality that game developers cannot access.

  2. Rust public items with missing or very short docstrings (< 25 chars). These will
     produce "(undocumented)" entries in rust-api.md.

  3. Lua API functions and classes with missing descriptions. These will appear without
     helpful documentation in lua-api.md.

Usage:
    python tools/gen_coverage_gaps.py                    # -> docs/reports/coverage_gaps.md
    python tools/gen_coverage_gaps.py --output FILE      # custom output path
    python tools/gen_coverage_gaps.py --rust-input FILE  # custom Rust JSON
    python tools/gen_coverage_gaps.py --lua-input FILE   # custom Lua JSON

Exit codes:
    0 — success
    1 — fatal error (missing input)
"""

import argparse
import json
import re
import sys
from pathlib import Path

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent.parent
RUST_INPUT = WORKSPACE_ROOT / "logs" / "rust_api_data.json"
LUA_INPUT = WORKSPACE_ROOT / "logs" / "lua_api_data.json"
OUTPUT_FILE = WORKSPACE_ROOT / "docs" / "reports" / "coverage_gaps.md"

# Rust modules that are deliberately not exposed to Lua (engine internals, CLI, etc.)
_INTERNAL_MODULES = {
    "main", "lib", "root",
    # Engine internals
    "engine::app", "engine::error_screen", "engine::debug_overlay",
    "engine::resource_keys", "engine::config",
    "engine::log_messages", "engine::messages",
    # Internal Rust→Lua conversion helpers (never user-visible)
    "serial::lua_table", "thread::channel",
    "event::event_queue",
    # Internal domain helpers not in the Lua surface
    "savegame::save_data", "savegame::save_manager", "image::visualization::animation", "image::visualization::audio", "image::visualization::camera", "image::visualization::easing", "image::visualization::facade", "image::visualization::geometry", "image::visualization::graph", "image::visualization::image_ops", "image::visualization::noise", "image::visualization::procgen", "image::visualization::ui", "globe::draw", "globe::lighting", "globe::loader", "globe::projection", "log::facade", "math::sphere", "particle::visualization", "app::app", "filesystem::zip_mount",
    "data::bin_pack", "data::pack", "data::toml_convert",
    "entity::universe",
    # Internal platform/engine converters
    "input::keyboard", "input::gamepad",
    # Internal particle sub-helpers
    "particle::emission", "particle::math",
    # Low-level raycaster sub-helpers (wrapped by higher-level Lua API)
    "raycaster::lighting", "raycaster::minimap_overlay",
    "raycaster::projection", "raycaster::segment", "raycaster::visibility",
    # Internal tilemap helpers (coords exposed via higher-level tilemap API)
    "tilemap::coords", "tilemap::tmx",
    # Window sub-modules (wrapped by lurek.window)
    "window::management", "window::viewport",
    # DataFrame/serial internal format helpers
    "dataframe::serial", "dataframe::sql",
    "serial::csv", "serial::json", "serial::toml", "serial::yaml",
    # Pathfinding internal algorithms (wrapped by lurek.pathfind)
    "pathfinding::astar", "pathfinding::graph_path", "pathfinding::hpa",
    # Procgen internal algorithms (wrapped by lurek.procgen)
    "procgen::cellular", "procgen::flood_fill", "procgen::noise_ext",
    "procgen::poisson", "procgen::voronoi",
    # Math sub-modules exposed via renamed Lua bindings
    # (e.g. simplex_noise_2d → lurek.math.simplex2d, polygon functions → lurek.math.*)
    "math::noise_functions",
    # Compute ops/spatial are exposed as Array instance methods (via dispatch_arith! and add_method),
    # not as free lurek.compute.* functions — they are fully accessible to Lua via array:method()
    "compute::ops",
    "compute::spatial",
    # Debug bridge internals (TCP server internals, not Lua-exposed)
    "debugbridge::server", "debugbridge::bridge",
    # Engine docs quality scoring (internal engine tooling)
    "docs::report",
    # Image serialization helper (internal; save is handled by lurek.image.save)
    "image::serial",
    "image::visualization",
    # Localization internal helpers (wrapped by lurek.i18n.*)
    "localization::interpolation", "localization::plural",
    "i18n::interpolation", "i18n::plural",
    # Log internal enabled_for check (not Lua-exposed)
    "log",
    # Tween state internal helpers (wrapped by lurek.tween.*)
    "tween::state",
    # Additional internal modules
    "animation::render",
    "app::error_screen",
    "ecs::universe",
    "math::color",
    "parallax::render",
    "pathfind::astar",
    "pathfind::graph_path",
    "pathfind::hpa",
    "save::save_data",
    "save::save_manager",
    # Aseprite JSON parser — called internally by lurek.animation.loadAnimation
    "animation::aseprite",
    # compute::analytics functions are exposed as Array instance methods (Array:histogram() etc.)
    "compute::analytics",
    # effect::presets — internal helper; presets accessible through lurek.effect API
    "effect::presets",
    # Network transport layer — called from network runtime thread, not Lua surface
    "network::http",
    "network::message",
    # physics::cellular palette — internal color helper for cellular automaton rendering
    "physics::cellular",
    # procgen noise primitives — already wrapped as lurek.procgen.noiseMap / noiseMapParallel
    "procgen::noise",
    # procgen world_graph — already wrapped as lurek.procgen.worldGraph
    "procgen::world_graph",
    # graph_nav — A* / Dijkstra on Graph structs; LuaGraph is private in graph_api,
    # graph traversal should use lurek.graph node/edge iteration
    "pathfind::graph_nav",
    # wgpu uniform mapping — internal GPU pipeline helper
    "render::postfx_pipeline",
    # Engine message resolution — internal human-readable error lookup
    "runtime::messages",
    # Sprite atlas JSON parser — called internally by lurek.render loadSplineAtlas
    "sprite::atlas",
    # LDtk file format parser — called internally by lurek.tilemap.loadLdtk
    "tilemap::ldtk",
    # FFT algorithm helpers — next_power_of_two, fft, ifft, fft_magnitude are called
    # inside lurek.compute.fft / .ifft / .fftMagnitude closures in compute_api.rs
    "compute::fft",
    # Linear algebra algorithm helpers — eigenvalue_power is called inside
    # lurek.compute.eigenvalues in compute_api.rs; not a standalone Lua API
    "compute::linalg",
    # Voronoi algorithm — voronoi_from_points is called inside lurek.math.voronoi
    # in math_api.rs (re-exported via crate::math::voronoi_from_points)
    "math::voronoi",
    # Lobby UDP broadcast helper — broadcast_lobby is called inside lurek.network.createLobby
    # and discover_lobbies in network_api.rs; not a standalone Lua function
    "network::lobby",
    # Bidirectional A★ algorithm — bidirectional_astar is called inside
    # lurek.pathfind.findPathBidirectional in pathfind_api.rs
    "pathfind::bidir",
    # Collision geometry primitives — test_point_aabb is an internal AABB check
    # used inside physics_api.rs closures; not exposed as a standalone Lua function
    "physics::collision_helpers",
    # ANSI escape code helpers — parse_ansi_spans and strip_ansi_codes are called
    # inside lurek.terminal.stripAnsi / .parseAnsi in terminal_api.rs
    "terminal::ansi",
    # Widget tree builder helpers — load_layout_def / load_layout_toml are called
    # inside lurek.ui.loadLayout / .loadLayoutToml closures in ui_api.rs
    "ui::layout_loader",
}

# Minimum description length to be considered "documented"
_MIN_DESC_LENGTH = 25


def _collect_lua_names(lua_data: dict) -> set[str]:
    """Collect all (module, name) pairs from the Lua API data for cross-reference."""
    names: set[str] = set()
    for mod_name, mod_data in lua_data.items():
        for fn in mod_data.get("functions", []):
            lua_name = fn.get("lua_name") or fn.get("name") or ""
            if lua_name:
                # lua_name may already be fully qualified (e.g. "lurek.math.inBack"); avoid double prefix
                names.add(lua_name if lua_name.startswith("lurek.") else f"{mod_name}.{lua_name}")
        for cls_name, cls_data in mod_data.get("classes", {}).items():
            if cls_name == "mlua":
                continue  # skip spurious mlua pseudo-class entries
            names.add(f"{mod_name}.{cls_name}")
            for method in cls_data.get("methods", []):
                mname = method.get("lua_name") or method.get("name") or ""
                if mname:
                    names.add(f"{mod_name}.{cls_name}:{mname}")
    return names


def _rust_public_fns(rust_data: dict) -> list[dict]:
    """Return all public Rust function items from all non-internal modules."""
    results = []
    for mod_path, mod_data in rust_data["rust_api"]["modules"].items():
        if mod_path in _INTERNAL_MODULES:
            continue
        for item in mod_data.get("items", []):
            if item.get("kind") == "fn":
                results.append({
                    "module": mod_path,
                    "name": item["name"],
                    "desc": item.get("description", "") or "",
                    "file": item.get("file", ""),
                    "line": item.get("line", 0),
                })
    return results


def _rust_undocumented(rust_data: dict) -> list[dict]:
    """Return all Rust public items with missing/short docstrings."""
    results = []
    for mod_path, mod_data in sorted(rust_data["rust_api"]["modules"].items()):
        if mod_path in _INTERNAL_MODULES:
            continue
        for item in mod_data.get("items", []):
            desc = (item.get("description", "") or "").strip()
            if len(desc) < _MIN_DESC_LENGTH:
                results.append({
                    "module": mod_path,
                    "kind": item.get("kind", "fn"),
                    "name": item["name"],
                    "desc": desc,
                    "file": item.get("file", ""),
                    "line": item.get("line", 0),
                })
    return results


def _lua_undocumented(lua_data: dict) -> list[dict]:
    """Return all Lua API items (functions, classes, methods) with missing descriptions."""
    results = []
    for mod_name, mod_data in sorted(lua_data.items()):
        # Module-level description
        mod_desc = (mod_data.get("description", "") or "").strip()
        if len(mod_desc) < _MIN_DESC_LENGTH:
            results.append({
                "module": mod_name,
                "kind": "module",
                "name": f"lurek.{mod_name}",
                "desc": mod_desc,
            })

        for fn in mod_data.get("functions", []):
            desc = (fn.get("description", "") or "").strip()
            if len(desc) < _MIN_DESC_LENGTH:
                lua_name = fn.get("lua_name") or fn.get("name") or "?"
                results.append({
                    "module": mod_name,
                    "kind": "function",
                    # lua_name may already be fully qualified; avoid double prefix
                    "name": lua_name if lua_name.startswith("lurek.") else f"lurek.{mod_name}.{lua_name}",
                    "desc": desc,
                })

        for cls_name, cls_data in sorted(mod_data.get("classes", {}).items()):
            if cls_name == "mlua":
                continue  # skip spurious mlua pseudo-class entries
            cls_desc = (cls_data.get("description", "") or "").strip()
            if len(cls_desc) < _MIN_DESC_LENGTH:
                results.append({
                    "module": mod_name,
                    "kind": "class",
                    "name": f"lurek.{mod_name}.{cls_name}",
                    "desc": cls_desc,
                })
            for method in cls_data.get("methods", []):
                mdesc = (method.get("description", "") or "").strip()
                if len(mdesc) < _MIN_DESC_LENGTH:
                    mname = method.get("lua_name") or method.get("name") or "?"
                    # lua_name is already "ClassName:methodName"; avoid double class prefix
                    display = mname if mname.startswith(f"{cls_name}:") else f"{cls_name}:{mname}"
                    results.append({
                        "module": mod_name,
                        "kind": "method",
                        "name": display,
                        "desc": mdesc,
                    })
    return results


def generate_report(rust_data: dict, lua_data: dict) -> str:
    # lua_api_data.json nests the modules under ["lua_api"]["modules"];
    # fall back to treating the whole dict as the modules map for older formats.
    lua_modules = lua_data.get("lua_api", {}).get("modules", lua_data)
    lua_names = _collect_lua_names(lua_modules)
    rust_fns = _rust_public_fns(rust_data)
    rust_bad_docs = _rust_undocumented(rust_data)
    lua_bad_docs = _lua_undocumented(lua_modules)

    # Section 1: Rust fns not in Lua
    # Matching: try exact substring, then underscore-stripped (camelCase), then ease_ prefix stripped
    unexposed: list[dict] = []
    for item in rust_fns:
        fn_name_lower = item["name"].lower()
        mod_lower = item["module"].split("::")[-1].lower()
        # Normalize by removing underscores (handles snake_case vs camelCase)
        fn_no_us = fn_name_lower.replace("_", "")
        # Handle easing convention: ease_in_* -> in*, ease_out_* -> out*
        fn_ease = re.sub(r"^ease_", "", fn_name_lower).replace("_", "")
        found = any(
            fn_name_lower in lua_key.lower()
            or fn_no_us in lua_key.lower().replace("_", "")
            or fn_ease in lua_key.lower().replace("_", "")
            or mod_lower + "." + fn_name_lower in lua_key.lower()
            for lua_key in lua_names
        )
        if not found:
            unexposed.append(item)

    lines: list[str] = []
    lines.append("# Lurek2D API Coverage Gaps")
    lines.append("")
    lines.append("*Auto-generated by `tools/gen_coverage_gaps.py`. Do not edit manually.*")
    lines.append("")
    lines.append("This report identifies three categories of coverage issues:")
    lines.append("")
    lines.append("1. **Rust→Lua Gaps** — Public Rust functions not exposed to the Lua API")
    lines.append("2. **Rust Docstring Issues** — Rust public items with missing/short docstrings")
    lines.append("3. **Lua Docstring Issues** — Lua API items with missing descriptions")
    lines.append("")
    lines.append("---")
    lines.append("")

    # ── Section 1: Unexposed Rust functions ──────────────────────────────────
    lines.append(f"## 1. Rust→Lua Gaps ({len(unexposed)} items)")
    lines.append("")
    lines.append("These public Rust functions are **not exposed** to the `lurek.*` Lua API.")
    lines.append("This may be intentional (engine internals) or an oversight.")
    lines.append("")

    if unexposed:
        by_mod: dict[str, list] = {}
        for item in unexposed:
            by_mod.setdefault(item["module"], []).append(item)
        for mod in sorted(by_mod.keys()):
            lines.append(f"### `{mod}`")
            lines.append("")
            for item in sorted(by_mod[mod], key=lambda x: x["name"]):
                loc = f"`{item['file']}:{item['line']}`" if item["file"] else ""
                desc_note = f" — {item['desc'][:60]}" if item["desc"] else ""
                lines.append(f"- `{item['name']}`{desc_note} {loc}")
            lines.append("")
    else:
        lines.append("*All public Rust functions appear to be exposed to Lua.*")
        lines.append("")

    lines.append("---")
    lines.append("")

    # ── Section 2: Rust docstring issues ─────────────────────────────────────
    lines.append(f"## 2. Rust Docstring Issues ({len(rust_bad_docs)} items)")
    lines.append("")
    lines.append(f"Public Rust items with missing or very short descriptions (< {_MIN_DESC_LENGTH} chars).")
    lines.append("These appear as `// (undocumented)` in `docs/reports/rust-api.md`.")
    lines.append("")

    if rust_bad_docs:
        by_mod2: dict[str, list] = {}
        for item in rust_bad_docs:
            by_mod2.setdefault(item["module"], []).append(item)
        for mod in sorted(by_mod2.keys()):
            lines.append(f"### `{mod}`")
            lines.append("")
            for item in sorted(by_mod2[mod], key=lambda x: (x["kind"], x["name"])):
                kind = item["kind"]
                name = item["name"]
                loc = f"`{item['file']}:{item['line']}`" if item["file"] else ""
                lines.append(f"- `{kind}` **{name}** {loc}")
            lines.append("")
    else:
        lines.append("*All public Rust items have adequate docstrings.*")
        lines.append("")

    lines.append("---")
    lines.append("")

    # ── Section 3: Lua docstring issues ──────────────────────────────────────
    lines.append(f"## 3. Lua Docstring Issues ({len(lua_bad_docs)} items)")
    lines.append("")
    lines.append(f"Lua API items with missing or very short descriptions (< {_MIN_DESC_LENGTH} chars).")
    lines.append("These appear without documentation in `docs/lua-api.md` and IntelliSense.")
    lines.append("")

    if lua_bad_docs:
        by_mod3: dict[str, list] = {}
        for item in lua_bad_docs:
            by_mod3.setdefault(item["module"], []).append(item)
        for mod in sorted(by_mod3.keys()):
            lines.append(f"### `{mod}`")
            lines.append("")
            for item in sorted(by_mod3[mod], key=lambda x: (x["kind"], x["name"])):
                kind = item["kind"]
                name = item["name"]
                desc = item["desc"]
                if desc:
                    lines.append(f"- `{kind}` **`{name}`** — *\"{desc}\"* (too short)")
                else:
                    lines.append(f"- `{kind}` **`{name}`** — *(no description)*")
            lines.append("")
    else:
        lines.append("*All Lua API items have adequate descriptions.*")
        lines.append("")

    lines.append("---")
    lines.append("")
    lines.append("## Fixing These Issues")
    lines.append("")
    lines.append("**Rust docstrings:** Add `///` doc comments above `pub fn`, `pub struct`, `pub enum`.")
    lines.append("Then run: `python tools/gen_rust_api_data.py`")
    lines.append("")
    lines.append("**Lua docstrings:** Add `/// description` above the `lurek.set(\"name\", ...)` call")
    lines.append("in the appropriate `src/lua_api/*_api.rs` file.")
    lines.append("Then run: `python tools/gen_lua_api_data.py`")
    lines.append("")
    lines.append("**Rust→Lua gaps:** If the function should be in Lua, add a binding in `src/lua_api/`.")
    lines.append("If it's intentionally internal, add its module to `_INTERNAL_MODULES` in this script.")
    lines.append("")
    lines.append("*Re-generate this file: `python tools/gen_coverage_gaps.py`*")

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate Lurek2D API coverage gap report.")
    parser.add_argument("--rust-input", default=str(RUST_INPUT))
    parser.add_argument("--lua-input", default=str(LUA_INPUT))
    parser.add_argument("--output", default=str(OUTPUT_FILE))
    args = parser.parse_args()

    rust_path = Path(args.rust_input)
    lua_path = Path(args.lua_input)

    if not rust_path.exists():
        print(f"[ERROR] Rust input not found: {rust_path}", file=sys.stderr)
        print("Run: python tools/gen_rust_api_data.py", file=sys.stderr)
        return 1
    if not lua_path.exists():
        print(f"[ERROR] Lua input not found: {lua_path}", file=sys.stderr)
        print("Run: python tools/gen_lua_api_data.py", file=sys.stderr)
        return 1

    rust_data = json.loads(rust_path.read_text(encoding="utf-8"))
    lua_data = json.loads(lua_path.read_text(encoding="utf-8"))

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    content = generate_report(rust_data, lua_data)
    output_path.write_text(content, encoding="utf-8")

    lines = content.count("\n")
    try:
        rel = output_path.relative_to(WORKSPACE_ROOT)
    except ValueError:
        rel = output_path
    print(f"[OK] Coverage gap report → {rel} ({lines} lines)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
