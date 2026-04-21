#!/usr/bin/env python3
"""
module_audit.py — Lurek2D module restructuring audit.

Compares Lurek2D module layout against reference modules and produces
a mapping table with recommendations for alignment, splits, or merges.

Usage:
    python tools/module_audit.py                  # print audit report
    python tools/module_audit.py --json           # JSON output
    python tools/module_audit.py --output FILE    # save to file
    python tools/module_audit.py --help

Exit codes:
    0  - audit completed
"""

import argparse
import json
import sys
from pathlib import Path
from typing import Dict, List

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent.parent
SRC_DIR = WORKSPACE_ROOT / "src"
REFERENCE_MODULES_DIR = WORKSPACE_ROOT / "references" / "similar-engine-ref" / "src" / "modules"


def collect_luna_modules() -> Dict[str, dict]:
    """Collect Lurek2D module info from src/."""
    modules = {}
    for child in sorted(SRC_DIR.iterdir()):
        if child.is_dir() and not child.name.startswith("."):
            rs_files = list(child.rglob("*.rs"))
            pub_count = 0
            for f in rs_files:
                try:
                    content = f.read_text(encoding="utf-8")
                    pub_count += content.count("\npub fn ") + content.count("\npub struct ")
                except OSError:
                    pass
            modules[child.name] = {
                "files": len(rs_files),
                "pub_items": pub_count,
                "path": f"src/{child.name}/",
            }
    return modules


def collect_reference_modules() -> Dict[str, dict]:
    """Collect reference module names."""
    modules = {}
    if not REFERENCE_MODULES_DIR.exists():
        return modules
    for child in sorted(REFERENCE_MODULES_DIR.iterdir()):
        if child.is_dir():
            cpp_files = list(child.rglob("*.cpp")) + list(child.rglob("*.h"))
            modules[child.name] = {
                "files": len(cpp_files),
                "path": str(child.relative_to(WORKSPACE_ROOT)).replace("\\", "/"),
            }
    return modules


# Manual mapping: Lurek2D module -> generic reference module(s)
LUNA_TO_REFERENCE_MAP = {
    "audio": {"reference_modules": ["audio", "sound"], "status": "aligned",
              "notes": "Audio playback and sample handling."},
    "compute": {"reference_modules": [], "status": "luna_only",
                "notes": "GPU compute support."},
    "data": {"reference_modules": ["data"], "status": "aligned",
             "notes": "Data encoding and compression."},
    "dataframe": {"reference_modules": [], "status": "luna_only",
                  "notes": "Tabular data processing."},
    "engine": {"reference_modules": ["core"], "status": "aligned",
               "notes": "Core engine lifecycle."},
    "event": {"reference_modules": ["event"], "status": "aligned",
              "notes": "Event queue."},
    "filesystem": {"reference_modules": ["filesystem"], "status": "aligned",
                   "notes": "Sandboxed file I/O."},
    "graph": {"reference_modules": [], "status": "luna_only",
              "notes": "Graph data structures."},
    "graphics": {"reference_modules": ["graphics", "font", "video"], "status": "superset",
                 "notes": "Graphics, text, and video support."},
    "image": {"reference_modules": ["image"], "status": "aligned",
              "notes": "Image loading and decoding."},
    "input": {"reference_modules": ["keyboard", "mouse", "joystick", "touch", "sensor"],
              "status": "merged",
              "notes": "Merged input surface; consider sub-namespaces."},
    "lua_api": {"reference_modules": [], "status": "internal",
                "notes": "Lua binding layer — not a game-facing module."},
    "math": {"reference_modules": ["math"], "status": "aligned",
             "notes": "Math utilities, vectors, and transforms."},
    "particle": {"reference_modules": [], "status": "luna_only",
                 "notes": "Particle systems standalone module."},
    "physics": {"reference_modules": ["physics"], "status": "aligned",
                "notes": "Physics simulation."},
    "sound": {"reference_modules": ["sound"], "status": "aligned",
              "notes": "Sound decoding; may overlap with audio."},
    "tilemap": {"reference_modules": [], "status": "luna_only",
                "notes": "Tilemap rendering."},
    "timer": {"reference_modules": ["timer"], "status": "aligned",
              "notes": "Frame timing, delta, and FPS."},
    "window": {"reference_modules": ["window"], "status": "aligned",
               "notes": "Window management."},
    "ai": {"reference_modules": [], "status": "luna_only",
           "notes": "AI and simulation systems."},
}


def generate_report(
    luna_mods: Dict[str, dict],
    ref_mods: Dict[str, dict],
) -> str:
    """Generate the module audit Markdown report."""
    lines = [
        "# Lurek2D Module Restructuring Audit",
        "",
        "## Lurek2D Module Mapping",
        "",
        "| Lurek2D Module | Similar Engine Equivalent(s) | Status | Files | Pub Items | Notes |",
        "|---------------|---------------------|--------|-------|-----------|-------|",
    ]

    for mod, info in sorted(luna_mods.items()):
        mapping = LUNA_TO_REFERENCE_MAP.get(mod, {
            "reference_modules": [], "status": "unmapped", "notes": ""
        })
        reference_names = ", ".join(mapping["reference_modules"]) or "—"
        lines.append(
            f"| {mod} | {reference_names} | {mapping['status']} | "
            f"{info['files']} | {info['pub_items']} | {mapping['notes']} |"
        )

    lines.append("")

    # Reference modules not in Lurek2D
    luna_covered = set()
    for mapping in LUNA_TO_REFERENCE_MAP.values():
        luna_covered.update(mapping["reference_modules"])

    uncovered = set(ref_mods.keys()) - luna_covered
    if uncovered:
        lines.append("## Modules Not Yet in Lurek2D")
        lines.append("")
        for name in sorted(uncovered):
            lines.append(f"- **{name}** ({ref_mods[name]['files']} files)")
        lines.append("")

    # Luna-only modules
    luna_only = [m for m, mapping in LUNA_TO_REFERENCE_MAP.items()
                 if mapping["status"] == "luna_only" and m in luna_mods]
    if luna_only:
        lines.append("## Lurek2D-Only Modules (beyond similar engines)")
        lines.append("")
        for name in sorted(luna_only):
            lines.append(f"- **{name}**: {LUNA_TO_REFERENCE_MAP[name]['notes']}")
        lines.append("")

    # Recommendations
    lines.extend([
        "## Recommendations",
        "",
        "### High Priority",
        "1. **input → sub-namespaces**: Luna `input` merges keyboard/mouse/joystick/touch/sensor. "
        "The Lua API already uses `lurek.input.keyboard`, `lurek.input.mouse` etc. — ensure Rust module "
        "structure reflects this if split is needed.",
        "2. **audio + sound overlap**: Two modules both deal with audio. Clarify boundaries "
        "(sound = decoding, audio = playback) or merge.",
        "",
        "### Low Priority",
        "3. **particle → graphics sub-module**: Some engines include particles in graphics. "
        "Consider whether separate module is justified by size.",
        "4. **font module**: Some engines have a separate font module. Lurek2D keeps fonts in graphics. "
        "Current approach is fine if graphics doesn't grow too large.",
        "",
        "### No Action Needed",
        "- `compute`, `dataframe`, `ai`, `graph`, `tilemap` — Lurek2D extensions beyond similar engines. "
        "Keep as separate modules.",
        "",
    ])

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Lurek2D module restructuring audit",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--json", action="store_true",
                        help="Output structured JSON")
    parser.add_argument("--output", metavar="FILE",
                        help="Save report to file")
    args = parser.parse_args()

    luna_mods = collect_luna_modules()
    ref_mods = collect_reference_modules()

    print(f"[INFO] Lurek2D modules: {len(luna_mods)}", file=sys.stderr)
    print(f"[INFO] Reference modules: {len(ref_mods)}", file=sys.stderr)

    if args.json:
        report = json.dumps({
            "luna_modules": {k: {**v, **LUNA_TO_REFERENCE_MAP.get(k, {})} for k, v in luna_mods.items()},
            "reference_modules": ref_mods,
            "mapping": LUNA_TO_REFERENCE_MAP,
        }, indent=2, ensure_ascii=False)
    else:
        report = generate_report(luna_mods, ref_mods)

    if args.output:
        Path(args.output).parent.mkdir(parents=True, exist_ok=True)
        Path(args.output).write_text(report, encoding="utf-8")
        print(f"[OK] Report saved to {args.output}", file=sys.stderr)
    else:
        print(report)

    return 0


if __name__ == "__main__":
    sys.exit(main())
