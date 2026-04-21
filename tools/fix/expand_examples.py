#!/usr/bin/env python3
"""
tools/fix/expand_examples.py
Lurek2D — Auto-expand example files to cover all missing API entries.

For every entry in the lurek.* API docs that is NOT referenced in its
corresponding content/examples/*.lua file, this script appends well-formatted
documentation-style Lua stubs.

Usage:
    python tools/fix/expand_examples.py              # expand all files
    python tools/fix/expand_examples.py --dry-run    # preview without writing
    python tools/fix/expand_examples.py --module gfx # one module only
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
API_DOC = ROOT / "docs" / "API" / "lua-api.md"
EXAMPLES_DIR = ROOT / "content" / "examples"

# ──────────────────────────────────────────────────────────────────────────── #
#  Namespace → example file mapping                                             #
# ──────────────────────────────────────────────────────────────────────────── #
NS_TO_FILE: dict[str, str] = {
    "lurek.renders": "graphics.lua",
    "lurek.render": "graphics.lua",
    "lurek.window": "window.lua",
    "lurek.input": "input.lua",
    "lurek.timer": "timer.lua",
    "lurek.math": "math.lua",
    "lurek.audio": "audio.lua",
    "lurek.physics": "physics.lua",
    "lurek.filesystem": "filesystem.lua",
    "lurek.filesystem": "filesystem.lua",
    "lurek.particle": "particle.lua",
    "lurek.event": "event.lua",
    "lurek.runtime": "window.lua",
    "lurek.thread": "thread.lua",
    "lurek.ai": "ai.lua",
    "lurek.compute": "compute.lua",
    "lurek.dataframe": "dataframe.lua",
    "lurek.data": "data.lua",
    "lurek.image": "image.lua",
    "lurek.graph": "graph.lua",
    "lurek.tilemap": "tilemap.lua",
    "lurek.ecs": "entity.lua",
    "lurek.scene": "scene.lua",
    "lurek.pathfind": "pathfinding.lua",
    "lurek.minimap": "minimap.lua",
    "lurek.save": "savegame.lua",
    "lurek.mods": "modding.lua",
    "lurek.i18n": "localization.lua",
    "lurek.log": "log.lua",
    "lurek.debugbridge": "debugbridge.lua",
    "lurek.docs": "docs.lua",
    "lurek.patterns": "patterns.lua",
    "lurek.animation": "animation.lua",
    "lurek.automation": "automation.lua",
    "lurek.camera": "camera.lua",
    "lurek.devtools": "devtools.lua",
    "lurek.fx": "fx.lua",
    "lurek.gui": "gui.lua",
    "lurek.light": "light.lua",
    "lurek.network": "network.lua",
    "lurek.pipeline": "pipeline.lua",
    "lurek.procgen": "procgen.lua",
    "lurek.raycaster": "raycaster.lua",
    "lurek.serial": "serial.lua",
    "lurek.spine": "spine.lua",
    "lurek.terminal": "terminal.lua",
}

# class → example file (inferred from which namespace the class belongs to)
CLASS_TO_FILE: dict[str, str] = {
    # graphics
    "Canvas": "graphics.lua", "DrawLayer": "graphics.lua",
    "Font": "graphics.lua", "Image": "graphics.lua",
    "ImageData": "graphics.lua", "Mesh": "graphics.lua",
    "NineSlice": "graphics.lua", "Quad": "graphics.lua",
    "Shader": "graphics.lua", "Shape": "graphics.lua",
    "SpriteBatch": "graphics.lua",
    # window / system
    "Cursor": "input.lua",
    # timer
    "Scheduler": "timer.lua",
    # math
    "BezierCurve": "math.lua", "NoiseGenerator": "math.lua",
    "RandomGenerator": "math.lua", "SpatialHash": "math.lua",
    "Transform": "math.lua", "Tween": "math.lua",
    # audio
    "Bus": "audio.lua", "Decoder": "audio.lua",
    "MidiPlayer": "audio.lua", "Source": "audio.lua",
    # physics
    "Body": "physics.lua", "PhysicsShape": "physics.lua",
    "World": "physics.lua",
    # filesystem
    "FileData": "filesystem.lua", "FileHandle": "filesystem.lua",
    # particle
    "ParticleSystem": "particle.lua", "Trail": "particle.lua",
    # signal
    "Signal": "event.lua",
    # thread
    "ThreadHandle": "thread.lua",
    # ai
    "AIWorld": "ai.lua", "Agent": "ai.lua", "BTNode": "ai.lua",
    "BehaviorTree": "ai.lua", "Blackboard": "ai.lua",
    "CommandQueue": "ai.lua", "GOAPPlanner": "ai.lua",
    "InfluenceMap": "ai.lua", "QLearner": "ai.lua",
    "Squad": "ai.lua", "StateMachine": "ai.lua",
    "SteeringManager": "ai.lua", "UtilityAI": "ai.lua",
    # compute
    "Array": "compute.lua",
    # dataframe
    "DataFrame": "dataframe.lua", "Database": "dataframe.lua",
    # image
    "CompressedImageData": "image.lua",
    # graph
    "Edge": "graph.lua", "Graph": "graph.lua",
    "GraphItem": "graph.lua", "Node": "graph.lua",
    # tilemap
    "AutoTileSheet": "tilemap.lua", "ChunkMap": "tilemap.lua",
    "IsoMap": "tilemap.lua", "MapBlock": "tilemap.lua",
    "MapGroup": "tilemap.lua", "MapScript": "tilemap.lua",
    "TileMap": "tilemap.lua", "TileSet": "tilemap.lua",
    # entity
    "Universe": "entity.lua",
    # scene
    "DepthSorter": "scene.lua",
    # pathfinding
    "AiFlowField": "pathfinding.lua", "FlowField": "pathfinding.lua",
    "NavGrid": "pathfinding.lua", "PathGrid": "pathfinding.lua",
    "UnitPathfinder": "pathfinding.lua",
    # minimap
    "Minimap": "minimap.lua",
    # savegame
    "SaveManager": "savegame.lua",
    # modding
    "Mod": "modding.lua", "ModManager": "modding.lua",
    # docs
    "ApiCatalog": "docs.lua", "DocEntry": "docs.lua",
    "QualityReport": "docs.lua", "ValidationReport": "docs.lua",
    # patterns
    "CommandStack": "patterns.lua", "EventBus": "patterns.lua",
    "Factory": "patterns.lua", "ObjectPool": "patterns.lua",
    "ServiceLocator": "patterns.lua", "SimpleState": "patterns.lua",
    # animation
    "Animation": "animation.lua",
    # camera
    "Camera2D": "camera.lua",
    # fx
    "ImageEffect": "fx.lua", "Overlay": "fx.lua",
    "PostFxEffect": "fx.lua", "PostFxStack": "fx.lua",
    # gui
    "Accordion": "gui.lua", "Button": "gui.lua",
    "Checkbox": "gui.lua", "Combo_Box": "gui.lua",
    "Dialog": "gui.lua", "Dock_Panel": "gui.lua",
    "Gui_Table": "gui.lua", "Gui_Window": "gui.lua",
    "Image_Widget": "gui.lua", "Label": "gui.lua",
    "Layout": "gui.lua", "List_Box": "gui.lua",
    "Menu_Bar": "gui.lua", "Menu_Item": "gui.lua",
    "Nine_Patch": "gui.lua", "Panel": "gui.lua",
    "Progress_Bar": "gui.lua", "Radio_Button": "gui.lua",
    "Scroll_Bar": "gui.lua", "Scroll_Panel": "gui.lua",
    "Separator": "gui.lua", "Slider": "gui.lua",
    "Split_Panel": "gui.lua", "Status_Bar": "gui.lua",
    "Tab_Bar": "gui.lua", "Text_Input": "gui.lua",
    "Toast": "gui.lua", "Toolbar": "gui.lua",
    "Tooltip_Panel": "gui.lua", "Tree_View": "gui.lua",
    "Color_Picker": "gui.lua",
    # light
    "Light": "light.lua", "Occluder": "light.lua",
    # network
    "NetworkHost": "network.lua",
    # pipeline
    "Pipeline": "pipeline.lua", "Step": "pipeline.lua",
    # raycaster
    "Raycaster": "raycaster.lua",
    # serial
    "DataView": "data.lua",
    # spine
    "Skeleton": "spine.lua",
    # terminal
    "Terminal": "terminal.lua", "Widget": "terminal.lua",
}


@dataclass
class FnEntry:
    """One documented function/method from the API docs."""
    owner: str            # namespace or class name
    name: str             # function name
    sig: str              # full signature line
    description: str      # inline comment part
    is_method: bool       # True = obj:method(), False = ns.fn()
    example_file: str     # which example file this belongs to


# ──────────────────────────────────────────────────────────────────────────── #
#  API doc parser                                                               #
# ──────────────────────────────────────────────────────────────────────────── #

_SECTION_RE = re.compile(r'^##\s+`(luna\.\w+)`', re.IGNORECASE)
_CLASS_RE = re.compile(r'^###\s+`(\w+)`')
_MODULE_FN_RE = re.compile(r'^\s*(luna\.\w+)\.(\w+)\s*\((.*)$')
_METHOD_FN_RE = re.compile(r'^\s*(\w+):(\w+)\s*\((.*)$')
_COMMENT_RE = re.compile(r'--\s*(.+)$')


def _extract_description(sig_line: str) -> str:
    m = _COMMENT_RE.search(sig_line)
    return m.group(1).strip() if m else ""


def _extract_sig_prefix(sig_line: str) -> str:
    """Return the portion before the --comment."""
    idx = sig_line.find("  --")
    if idx >= 0:
        return sig_line[:idx].strip()
    return sig_line.strip()


def parse_api(path: Path) -> list[FnEntry]:
    entries: list[FnEntry] = []
    current_ns = ""
    current_class = ""
    class_to_ns: dict[str, str] = {}
    in_code = False

    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip().startswith("```"):
            in_code = not in_code
            continue
        if not in_code:
            m = _SECTION_RE.match(line)
            if m:
                current_ns = m.group(1).lower()
                current_class = ""
                continue
            m = _CLASS_RE.match(line)
            if m:
                current_class = m.group(1)
                class_to_ns[current_class] = current_ns
                continue
            continue

        # inside code block
        m = _MODULE_FN_RE.match(line)
        if m:
            ns_raw = m.group(1).lower()
            fn = m.group(2)
            exfile = NS_TO_FILE.get(ns_raw, "")
            sig = _extract_sig_prefix(line)
            desc = _extract_description(line)
            entries.append(FnEntry(ns_raw, fn, sig, desc, False, exfile))
            continue

        m = _METHOD_FN_RE.match(line)
        if m:
            cls = m.group(1)
            fn = m.group(2)
            exfile = CLASS_TO_FILE.get(cls) or NS_TO_FILE.get(
                class_to_ns.get(cls, ""), ""
            )
            sig = _extract_sig_prefix(line)
            desc = _extract_description(line)
            entries.append(FnEntry(cls, fn, sig, desc, True, exfile))
            continue

    return entries


# ──────────────────────────────────────────────────────────────────────────── #
#  Check what's already present in an example file                             #
# ──────────────────────────────────────────────────────────────────────────── #

def is_covered(fn: FnEntry, text: str) -> bool:
    # Only count non-commented lines — commented-out calls are NOT real coverage.
    live_text = "\n".join(
        line for line in text.splitlines()
        if not line.lstrip().startswith("--")
    )
    if fn.is_method:
        return bool(re.search(rf':{re.escape(fn.name)}\s*\(', live_text))
    else:
        return bool(re.search(
            rf'(?:luna\.\w+)\.{re.escape(fn.name)}\s*\(', live_text
        ))


# ──────────────────────────────────────────────────────────────────────────── #
#  Code generator                                                               #
# ──────────────────────────────────────────────────────────────────────────── #

# ── Stub value helpers ────────────────────────────────────────────────────── #

def _stub_args(sig: str) -> str:
    """Generate sensible stub argument values from a signature string."""
    # Extract the args portion between outer parens
    m = re.search(r'\(([^)]*)\)', sig)
    if not m:
        return "()"
    raw = m.group(1).strip()
    if not raw:
        return "()"

    args = []
    for part in raw.split(","):
        part = part.strip()
        if not part:
            continue
        # extract name and type
        name_part = re.split(r'\s*:\s*', part)
        param_name = name_part[0].strip().lstrip("(").strip()
        type_hint = name_part[1].strip() if len(name_part) > 1 else ""

        # optional params (type ends with ?) — skip
        if type_hint.endswith("?"):
            break

        # choose stubvalue
        t = type_hint.lower()
        if "bool" in t:
            args.append("false")
        elif "integer" in t or "int" in t:
            args.append("1")
        elif "number" in t or "float" in t:
            args.append("1.0")
        elif "string" in t:
            # try to pick a sensible value based on parameter name
            pname = param_name.lower()
            if "path" in pname or "file" in pname:
                args.append('"path/to/file"')
            elif "mode" in pname:
                args.append('"default"')
            elif "name" in pname or "title" in pname:
                args.append('"name"')
            elif "type" in pname:
                args.append('"type"')
            else:
                args.append('"value"')
        elif "function" in t or "callback" in t or "fn" in t:
            args.append("function() end")
        elif "table" in t:
            args.append("{}")
        else:
            # userdata / object — use a stub variable name
            clean = re.sub(r'[^a-zA-Z0-9_]', '', type_hint)
            args.append(clean.lower() or "obj")

    return "(" + ", ".join(args) + ")"


def _var_name_for(fn: FnEntry) -> str:
    """Generate a local variable name for the result of a function call."""
    n = fn.name
    # remove get/is prefixes for naming
    if n.startswith("get"):
        v = n[3:4].lower() + n[4:]
    elif n.startswith("is") or n.startswith("has"):
        v = n[0].lower() + n[1:]
    elif n.startswith("new"):
        v = n[3:4].lower() + n[4:]
    else:
        v = n
    # camelCase → snake_case approx
    v = re.sub(r'([A-Z])', lambda m: "_" + m.group(0).lower(), v).lstrip("_")
    return v or "result"


def generate_stub_line(fn: FnEntry, obj_name: str = "") -> str:
    """Return a single Lua statement demonstrating this function."""
    stub_args = _stub_args(fn.sig)

    if fn.is_method:
        call = f"{obj_name or fn.owner.lower()}:{fn.name}{stub_args}"
    else:
        call = f"{fn.owner}.{fn.name}{stub_args}"

    # Does the sig look like it returns a value?
    has_return = "->" in fn.sig and "nil" not in fn.sig.split("->")[-1].lower()

    if has_return:
        varname = _var_name_for(fn)
        stmt = f"local {varname} = {call}"
    else:
        stmt = call

    comment = f"  -- {fn.description}" if fn.description else ""
    return f"{stmt}{comment}"


# ──────────────────────────────────────────────────────────────────────────── #
#  Build the extension block for one example file                              #
# ──────────────────────────────────────────────────────────────────────────── #

def _section_header(title: str) -> str:
    bar = "-" * max(0, 73 - len(title))
    return f"\n-- -- {title} {bar}"


def build_extension(
    filename: str,
    missing: list[FnEntry],
) -> str:
    """Return Lua source text to append to an example file."""
    if not missing:
        return ""

    lines: list[str] = [
        "",
        "-- " + "=" * 78,
        "-- AUTO-EXPANDED SECTION -- additional API coverage",
        "-- " + "=" * 78,
    ]

    # Group by owner (namespace or class)
    by_owner: dict[str, list[FnEntry]] = {}
    for fn in missing:
        by_owner.setdefault(fn.owner, []).append(fn)

    for owner, fns in sorted(by_owner.items()):
        lines.append(_section_header(owner))

        # Determine a stub object variable name for methods
        obj_var = ""
        if fns[0].is_method:
            # use lowercase class name
            obj_var = owner.lower().replace(".", "_")
            lines.append(f"-- (assumes '{obj_var}' is an existing {owner} instance)")

        for fn in fns:
            if fn.description:
                lines.append(f"-- {fn.description}")
            lines.append(generate_stub_line(fn, obj_var))

    lines.append("")
    return "\n".join(lines)


# ──────────────────────────────────────────────────────────────────────────── #
#  Main                                                                         #
# ──────────────────────────────────────────────────────────────────────────── #

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true",
                        help="print what would be written but don't modify files")
    parser.add_argument("--module", metavar="NAME",
                        help="only process example files containing this word")
    args = parser.parse_args()

    if not API_DOC.exists():
        sys.exit(f"ERROR: {API_DOC} not found")

    entries = parse_api(API_DOC)

    # Group by example file
    by_file: dict[str, list[FnEntry]] = {}
    for e in entries:
        if e.example_file:
            by_file.setdefault(e.example_file, []).append(e)

    for filename, fns in sorted(by_file.items()):
        if args.module and args.module.lower() not in filename:
            continue

        path = EXAMPLES_DIR / filename
        if not path.exists():
            print(f"[SKIP] {filename} — file not found")
            continue

        text = path.read_text(encoding="utf-8")

        # filter to missing
        missing = [fn for fn in fns if not is_covered(fn, text)]
        if not missing:
            print(f"[OK  ] {filename} — fully covered")
            continue

        extension = build_extension(filename, missing)
        if not extension.strip():
            continue

        print(f"[ADD ] {filename} — {len(missing)} missing entries")

        if not args.dry_run:
            new_text = text.rstrip() + "\n" + extension
            path.write_text(new_text, encoding="utf-8")
        else:
            # show preview
            for line in extension.splitlines()[:20]:
                print("  " + line)
            if len(extension.splitlines()) > 20:
                print(f"  ... +{len(extension.splitlines()) - 20} more lines")


if __name__ == "__main__":
    main()
