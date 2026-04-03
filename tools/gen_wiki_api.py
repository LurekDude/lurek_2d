#!/usr/bin/env python3
"""
gen_wiki_api.py — Generate wiki/API-Reference.md from docs/API/api_data.json.

Produces the game-developer-facing API Reference in the cheatsheet format
shown in the Luna2D wiki. Every function appears as a one-liner with its
call expression, return type, and description. All content is auto-generated
from the master api_data.json — do not edit wiki/API-Reference.md by hand.

Format per function:
    luna.module.fn( params )  -> ReturnType  -- description

Format per method:
    ClassName:method( params )  -> ReturnType  -- description

Usage:
    python tools/gen_wiki_api.py                # -> wiki/API-Reference.md
    python tools/gen_wiki_api.py --output FILE  # custom output path
    python tools/gen_wiki_api.py --input FILE   # custom input path

Exit codes:
    0 — success
    1 — fatal error
"""

import argparse
import json
import re
import sys
from pathlib import Path

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent
INPUT_FILE = WORKSPACE_ROOT / "docs" / "API" / "api_data.json"
OUTPUT_FILE = WORKSPACE_ROOT / "wiki" / "API-Reference.md"

# Canonical module display order
_MODULE_ORDER = [
    "graphics", "graphics_ext", "audio", "keyboard", "mouse", "gamepad",
    "touch", "timer", "math", "math_ext", "physics", "filesystem", "window",
    "event", "system", "thread", "particle", "tilemap", "scene", "entity",
    "pathfinding", "ai", "data", "image", "sound", "compute", "dataframe",
    "graph", "dialog", "postfx", "minimap", "savegame", "log", "modding",
    "localization", "debug", "stats", "inventory", "crafting", "cardgame",
    "combat", "input",
]

# Module descriptions used when the module doc from source is missing/thin
_MODULE_FALLBACK_DESC: dict = {
    "graphics": "Immediate-mode 2D rendering: images, shapes, text, canvas, shaders, blend modes, transforms.",
    "graphics_ext": "Extended graphics: lights, texture atlases, viewports, sprite sheets, draw layers.",
    "audio": "Sound playback: load audio files, play/pause/stop, volume, pitch, looping, panning.",
    "keyboard": "Keyboard state: key held/pressed/released queries.",
    "mouse": "Mouse state: position, button state, cursor control.",
    "gamepad": "Gamepad/joystick: button state, axes, rumble, connection queries.",
    "touch": "Touch input: multi-touch tracking, pressure, delta.",
    "timer": "Frame timing: delta time, FPS, sleep, scheduled callbacks.",
    "math": "Core math: vectors, random, interpolation, geometry utilities.",
    "math_ext": "Extended math: curves, easing, noise, bitwise operations.",
    "physics": "2D physics simulation via rapier2d: bodies, colliders, joints, sensors, raycasts.",
    "filesystem": "Game filesystem: read/write files, directory listing, save paths, sandboxed I/O.",
    "window": "Window management: size, title, fullscreen, cursor, display info.",
    "event": "Event queue: push/poll custom events between systems.",
    "system": "System info: OS, clipboard, locale, memory, Luna2D version.",
    "thread": "Background threads and inter-thread channels for Lua coroutines.",
    "particle": "CPU particle system: emitters, modifiers, rendering.",
    "tilemap": "Tile maps: chunk loading, tile queries, navigation grid.",
    "scene": "Depth-sorted scene management for 2D layers.",
    "entity": "Lightweight entity/component system with universe, tags, and blueprints.",
    "pathfinding": "Grid-based A* and flow-field pathfinding.",
    "ai": "AI subsystems: FSM, behavior tree, steering, Q-learning, squad, utility AI, GOAP.",
    "data": "Data utilities: TOML/JSON parsing, encoding, hashing, compression.",
    "image": "CPU-side image manipulation: pixel read/write, procedural generation.",
    "sound": "Low-level audio source management and mixer control.",
    "compute": "Dense NdArray numerical computing: element ops, reductions, convolutions.",
    "dataframe": "Tabular data: DataFrame construction, column ops, filtering, CSV.",
    "graph": "Directed graph: nodes, edges, item flow, Dijkstra pathfinding.",
    "dialog": "Branching dialog system: trees, choices, variables, scripted events.",
    "postfx": "Post-processing effects: screen-space filters applied after draw.",
    "minimap": "Minimap rendering from tile data.",
    "savegame": "Save/load game state: named slots, versioned tables, autosave.",
    "log": "Structured game logging: levels, sinks, log file output.",
    "modding": "Mod loading: folder scanning, dependency resolution, hot-reload.",
    "localization": "Localisation: string lookup, locale switching, plural forms.",
    "debug": "Debug overlays, draw calls inspection, performance display.",
    "stats": "Game statistics tracking and reporting.",
    "inventory": "Inventory system: items, stacks, slots, containers.",
    "crafting": "Crafting system: recipes, stations, skill checks.",
    "cardgame": "Card game framework: cards, decks, zones, stacks.",
    "combat": "Turn-based combat: combatants, actions, status effects, damage.",
    "input": "Unified input helper: combined keyboard + gamepad queries.",
}


# ── Return-type extraction ─────────────────────────────────────────────────────

def _extract_return_type(returns_doc: str, description: str = "", fn_name: str = "") -> str:
    """Extract just the return type name from docstring fields."""
    if returns_doc:
        first = returns_doc.strip().split("\n")[0].strip().lstrip("- ").strip()
        # Handle backtick-wrapped type: `TypeName` — description
        m_bt = re.match(r"^`([A-Za-z][A-Za-z0-9_?]*)\??`", first)
        if m_bt:
            return m_bt.group(1)
        # Plain type name
        m = re.match(r"^([A-Za-z][A-Za-z0-9_?]*)(?:\s|$|[\u2014\u2013:-])", first)
        if m:
            t = m.group(1)
            if t.lower() not in ("the", "a", "an", "this", "true", "false", "nil", "none"):
                return t
        if re.match(r"^[A-Za-z][A-Za-z0-9_?]*$", first.rstrip(".")):
            return first.rstrip(".")

    # From description: "Creates a new X" / "Returns the X" / "Gets X"
    if description:
        m2 = re.match(
            r"(?:Creates?|Returns?|Gets?|Wraps?|Loads?)\s+(?:a\s+new\s+|the\s+|an?\s+)?([A-Z][A-Za-z0-9_]*)",
            description,
        )
        if m2:
            return m2.group(1)

    # Heuristic from factory function name: newFoo() -> Foo, getFoo() -> Foo
    if fn_name:
        m3 = re.match(r"^(?:new|get|create)([A-Z][A-Za-z0-9_]+)$", fn_name)
        if m3:
            return m3.group(1)
    return ""


# ── Signature formatting ───────────────────────────────────────────────────────

def _fmt_sig(fn: dict) -> str:
    """Build a compact parameter signature for the cheatsheet line."""
    sig = fn.get("inferred_sig") or ""
    params_doc = fn.get("params_doc", "")

    if params_doc:
        typed: list = []
        for line in params_doc.split("\n"):
            line = line.strip().lstrip("- ").strip()
            m = re.match(
                r"`?([a-zA-Z_]\w*)`?\s*[—–-]+\s*([A-Za-z][A-Za-z0-9_?]*)",
                line,
            )
            if m:
                pname = m.group(1)
                ptype = m.group(2)
                is_opt = ptype.endswith("?") or "[" in line[: line.find(pname)]
                if is_opt:
                    typed.append(f"[{pname}]")
                else:
                    typed.append(f"{pname}: {ptype.rstrip('?')}")
        if typed:
            inner = ", ".join(typed)
            return f"( {inner} )"

    if sig and sig != "()":
        inner = sig.strip("()")
        if inner:
            return f"( {inner} )"
    return "( )"


# ── Cheatsheet line ────────────────────────────────────────────────────────────

def _cheatsheet_line(call: str, ret: str, desc: str, indent: int = 2) -> str:
    """Format one function as a cheatsheet line."""
    pad = " " * indent
    # Truncate description to keep lines readable
    if len(desc) > 90:
        desc = desc[:87] + "..."
    # Compact format: call + rettype + desc (no excessive padding)
    ret_part = f"  -> {ret}" if ret else ""
    desc_part = f"  -- {desc}" if desc else ""
    line = f"{pad}{call}{ret_part}{desc_part}"
    return line.rstrip()


# ── Module rendering ───────────────────────────────────────────────────────────

def _render_module_section(mod_name: str, mod_data: dict) -> list:
    """Render one complete module section for the wiki."""
    out = []
    anchor = mod_name.replace("_", "-")
    out.append(f"## luna.{mod_name} {{#{anchor}}}")
    out.append("")

    # Module description — prefer hand-written fallback when available (richer for wiki)
    fallback = _MODULE_FALLBACK_DESC.get(mod_name, "")
    src_desc = mod_data.get("description", "").split("\n")[0].strip() if mod_data.get("description") else ""
    desc = fallback if fallback else src_desc
    if desc:
        out.append(f"> {desc}")
        out.append("")

    fn_list = mod_data.get("functions", [])
    classes = mod_data.get("classes", {})

    # Module functions code block
    if fn_list:
        out.append("```lua")
        for fn in sorted(fn_list, key=lambda f: f["name"]):
            call = f"luna.{mod_name}.{fn['name']}{_fmt_sig(fn)}"
            ret = _extract_return_type(fn.get("returns_doc", ""), fn.get("description", ""), fn["name"])
            fdesc = fn.get("description", "")
            out.append(_cheatsheet_line(call, ret, fdesc))
        out.append("```")
        out.append("")

    # Classes
    for cls_name in sorted(classes.keys()):
        cls_data = classes[cls_name]
        methods = cls_data.get("methods", [])
        if not methods:
            continue

        out.append(f"**`{cls_name}`** methods:")
        out.append("")
        cls_desc = cls_data.get("description", "")
        if cls_desc:
            out.append(f"> {cls_desc.split(chr(10))[0]}")
            out.append("")

        out.append("```lua")
        for fn in sorted(methods, key=lambda f: f["name"]):
            call = f"{cls_name}:{fn['name']}{_fmt_sig(fn)}"
            ret = _extract_return_type(fn.get("returns_doc", ""), fn.get("description", ""), fn["name"])
            fdesc = fn.get("description", "")
            out.append(_cheatsheet_line(call, ret, fdesc))
        out.append("```")
        out.append("")

    return out


# ── Callbacks section ──────────────────────────────────────────────────────────

_CALLBACKS = [
    ("luna.load()", "", "called once after script loads"),
    ("luna.update(dt)", "", "dt: number; called every frame before draw"),
    ("luna.draw()", "", "called every frame; push draw commands here"),
    ("luna.keypressed(key, scancode, isrepeat)", "", "key: string; isrepeat: bool"),
    ("luna.keyreleased(key, scancode)", "", "key: string; scancode: string"),
    ("luna.textinput(text)", "", "text: string; Unicode character input"),
    ("luna.mousepressed(x, y, button)", "", "button: 1=left 2=right 3=middle"),
    ("luna.mousereleased(x, y, button)", "", "button: number"),
    ("luna.wheelmoved(x, y)", "", "x,y: scroll delta this frame"),
    ("luna.gamepadpressed(id, button)", "", "id: number; button: string"),
    ("luna.gamepadreleased(id, button)", "", "id: number; button: string"),
    ("luna.gamepadaxis(id, axis, value)", "", "value: -1.0 to 1.0"),
    ("luna.joystickadded(id)", "", "gamepad connected"),
    ("luna.joystickremoved(id)", "", "gamepad disconnected"),
    ("luna.touchpressed(id, x, y, dx, dy, pressure)", "", "touch start"),
    ("luna.touchmoved(id, x, y, dx, dy, pressure)", "", "touch move"),
    ("luna.touchreleased(id, x, y, dx, dy, pressure)", "", "touch end"),
    ("luna.focus(focused)", "", "focused: bool; window focus changed"),
    ("luna.visible(visible)", "", "visible: bool; window hidden or shown"),
    ("luna.resize(w, h)", "", "w, h: new window dimensions"),
    ("luna.quit()", "", "return true to cancel shutdown"),
    ("luna.errorhandler(msg)", "", "return replacement string or nil"),
]


def generate_wiki(data: dict) -> str:
    lua_api = data["lua_api"]
    modules = lua_api["modules"]
    generated = data["meta"]["generated"][:10]
    version = data["meta"]["version"]
    s = lua_api["summary"]

    out = []
    out.append("# API Reference")
    out.append("")
    out.append("> One method per line in valid Lua. Full `luna.*` path for module functions; `obj:method()` for instance methods.")
    out.append("> Inline comment: return type and description.")
    out.append(">")
    out.append(f"> Auto-generated by `tools/gen_wiki_api.py` from `docs/API/api_data.json`.")
    out.append(f"> Version: `{version}` | Generated: {generated}")
    out.append(f"> Regenerate: `python tools/gen_wiki_api.py`")
    out.append("")
    out.append("---")
    out.append("")

    # Table of Contents
    out.append("## Table of Contents")
    out.append("")

    seen: set = set()
    ordered: list = []
    for mod in _MODULE_ORDER:
        if mod in modules:
            seen.add(mod)
            ordered.append(mod)
    for mod in sorted(modules.keys()):
        if mod not in seen:
            ordered.append(mod)

    # Build TOC as a list
    toc_items = ["[Callbacks](#callbacks)"]
    for mod in ordered:
        anchor = mod.replace("_", "-")
        toc_items.append(f"[luna.{mod}](#{anchor})")
    for i, item in enumerate(toc_items):
        out.append(f"- {item}")
    out.append("")
    out.append("---")
    out.append("")

    # Callbacks
    out.append("## Callbacks")
    out.append("")
    out.append("Define any of these in `main.lua`. All are optional.")
    out.append("")
    out.append("```lua")
    max_call_len = max(len(c[0]) for c in _CALLBACKS)
    for call, ret, desc in _CALLBACKS:
        fn_part = f"function {call:<{max_call_len}} end"
        out.append(f"  {fn_part}  -- {desc}")
    out.append("```")
    out.append("")
    out.append("---")
    out.append("")

    # Module sections
    for mod in ordered:
        if mod not in modules:
            continue
        section = _render_module_section(mod, modules[mod])
        out.extend(section)

    out.append("---")
    out.append("")
    out.append(
        f"*Auto-generated from `docs/API/api_data.json` by `tools/gen_wiki_api.py`. "
        f"Do not edit by hand — run `python tools/gen_wiki_api.py` to regenerate.*"
    )

    return "\n".join(out)


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate Luna2D wiki API Reference.")
    parser.add_argument("--input", default=str(INPUT_FILE))
    parser.add_argument("--output", default=str(OUTPUT_FILE))
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"[ERROR] Input not found: {input_path}", file=sys.stderr)
        print("Run 'python tools/gen_api_data.py' first.", file=sys.stderr)
        return 1

    data = json.loads(input_path.read_text(encoding="utf-8"))

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    content = generate_wiki(data)
    output_path.write_text(content, encoding="utf-8")

    lines = content.count("\n")
    print(f"[OK] Generated {output_path} ({lines} lines)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
