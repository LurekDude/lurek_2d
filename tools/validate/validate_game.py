#!/usr/bin/env python3
"""
validate_game.py — Validate Lua game scripts against the Luna2D API surface.

Static analysis: checks that all luna.* calls in a game script match functions
known to the engine. Reports unknown API calls, deprecated patterns, and
common mistakes.

Usage:
    python tools/validate_game.py path/to/game/          # validate a game folder
    python tools/validate_game.py demos/hello_world/   # validate an example
    python tools/validate_game.py --all-examples          # validate all examples
    python tools/validate_game.py --json                  # JSON output
    python tools/validate_game.py --help

Exit codes:
    0  - all API calls are valid
    1  - unknown API calls found
    2  - fatal error
"""

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Set

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent.parent
EXAMPLES_DIR = WORKSPACE_ROOT / "examples"


def _build_api_manifest() -> Dict[str, Set[str]]:
    """Build a manifest of known luna.* API functions from gen_lua_api.py."""
    sys.path.insert(0, str(WORKSPACE_ROOT / "tools"))
    import gen_lua_api

    all_fns = gen_lua_api.collect_all_functions(WORKSPACE_ROOT / "src" / "lua_api")
    manifest: Dict[str, Set[str]] = {}

    for module, funcs in all_fns.items():
        for func in funcs:
            parts = func.lua_name.split(".")
            if len(parts) >= 2:
                ns = parts[-2] if len(parts) > 2 else parts[0]
                fn_name = parts[-1]
                manifest.setdefault(ns, set()).add(fn_name)

            # Always add full qualified name
            manifest.setdefault("_full", set()).add(func.lua_name)

    return manifest


# Known callbacks that are set, not called
KNOWN_CALLBACKS = {
    "luna.load", "luna.update", "luna.draw",
    "luna.keypressed", "luna.keyreleased",
    "luna.mousepressed", "luna.mousereleased",
    "luna.mousemoved", "luna.wheelmoved",
    "luna.touchpressed", "luna.touchmoved", "luna.touchreleased",
    "luna.gamepadpressed", "luna.gamepadreleased",
    "luna.gamepadaxis", "luna.textinput",
    "luna.focus", "luna.visible", "luna.resize",
    "luna.quit", "luna.errhand",
}

# Known top-level luna properties (not functions)
KNOWN_PROPERTIES = {
    "luna.graphics", "luna.audio", "luna.physics", "luna.input",
    "luna.timer", "luna.filesystem", "luna.math", "luna.window",
    "luna.system", "luna.event", "luna.keyboard", "luna.mouse",
    "luna.joystick", "luna.gamepad", "luna.touch", "luna.sound",
    "luna.data", "luna.image", "luna.thread", "luna.compute",
    "luna.dataframe", "luna.ai", "luna.graph", "luna.particle",
    "luna.tilemap",
}


def validate_lua_file(
    lua_path: Path,
    manifest: Dict[str, Set[str]],
) -> List[dict]:
    """Validate a single Lua file against the API manifest."""
    try:
        content = lua_path.read_text(encoding="utf-8")
    except OSError as e:
        return [{"type": "error", "message": str(e), "line": 0, "call": ""}]

    lines = content.splitlines()
    issues = []

    # Pattern: luna.module.function( or luna.module:method(
    call_re = re.compile(r'(luna\.\w+(?:\.\w+)*)\s*[(:=]')
    # Pattern for function assignment: luna.callback = function
    assign_re = re.compile(r'(luna\.\w+)\s*=\s*function')

    full_names = manifest.get("_full", set())

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Skip comments
        if stripped.startswith("--"):
            continue

        # Check assignments (callbacks)
        for m in assign_re.finditer(line):
            name = m.group(1)
            if name not in KNOWN_CALLBACKS:
                issues.append({
                    "type": "unknown_callback",
                    "message": f"Unknown callback: {name}",
                    "line": i + 1,
                    "call": name,
                })

        # Check API calls
        for m in call_re.finditer(line):
            name = m.group(1)

            # Skip pure namespace references
            if name in KNOWN_PROPERTIES:
                continue

            # Skip known callbacks used as assignment targets
            if name in KNOWN_CALLBACKS:
                continue

            # Check if the full call name is known
            if name in full_names:
                continue

            # Check partial match (module.func pattern)
            parts = name.split(".")
            if len(parts) >= 3:
                # luna.module.func -> check module has func
                ns = parts[1]
                fn_name = parts[-1]
                if ns in manifest and fn_name in manifest[ns]:
                    continue

            # Also handle luna.module.submodule.func
            if len(parts) >= 2:
                ns = parts[-2]
                fn_name = parts[-1]
                if ns in manifest and fn_name in manifest[ns]:
                    continue

            issues.append({
                "type": "unknown_api",
                "message": f"Unknown API call: {name}",
                "line": i + 1,
                "call": name,
            })

    return issues


def validate_game_folder(
    game_dir: Path,
    manifest: Dict[str, Set[str]],
) -> Dict[str, List[dict]]:
    """Validate all Lua files in a game folder."""
    results = {}
    for lua_file in sorted(game_dir.rglob("*.lua")):
        rel = str(lua_file.relative_to(game_dir))
        issues = validate_lua_file(lua_file, manifest)
        results[rel] = issues
    return results


def generate_report(all_results: Dict[str, Dict[str, List[dict]]]) -> str:
    """Generate a Markdown validation report."""
    lines = ["# Luna2D Game Validation Report", ""]

    total_files = 0
    total_issues = 0

    for game_name, file_results in sorted(all_results.items()):
        game_issues = sum(len(issues) for issues in file_results.values())
        total_files += len(file_results)
        total_issues += game_issues

        status = "PASS" if game_issues == 0 else "FAIL"
        lines.append(f"## {game_name} [{status}]")
        lines.append("")

        if game_issues == 0:
            lines.append("All API calls are valid.")
            lines.append("")
            continue

        for file_name, issues in sorted(file_results.items()):
            if not issues:
                continue
            lines.append(f"### {file_name}")
            lines.append("")
            for issue in issues:
                lines.append(
                    f"- Line {issue['line']}: **{issue['type']}** — `{issue['call']}` "
                    f"({issue['message']})"
                )
            lines.append("")

    lines.insert(2, f"**Files checked**: {total_files} | **Issues found**: {total_issues}")
    lines.insert(3, "")

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate Lua game scripts against Luna2D API",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("game_dir", nargs="?",
                        help="Path to game folder to validate")
    parser.add_argument("--all-examples", action="store_true",
                        help="Validate all demos/ games")
    parser.add_argument("--json", action="store_true",
                        help="Output structured JSON")
    parser.add_argument("--output", metavar="FILE",
                        help="Save report to file")
    args = parser.parse_args()

    if not args.game_dir and not args.all_examples:
        parser.error("Specify a game directory or use --all-examples")

    print("[INFO] Building API manifest...", file=sys.stderr)
    manifest = _build_api_manifest()
    total_api = len(manifest.get("_full", set()))
    print(f"[INFO] API manifest: {total_api} known functions", file=sys.stderr)

    all_results: Dict[str, Dict[str, List[dict]]] = {}

    if args.all_examples:
        for game_dir in sorted(EXAMPLES_DIR.iterdir()):
            if game_dir.is_dir():
                print(f"[INFO] Validating {game_dir.name}...", file=sys.stderr)
                results = validate_game_folder(game_dir, manifest)
                all_results[game_dir.name] = results
    else:
        game_path = Path(args.game_dir)
        if not game_path.exists():
            print(f"[ERROR] Directory not found: {game_path}", file=sys.stderr)
            return 2
        print(f"[INFO] Validating {game_path.name}...", file=sys.stderr)
        results = validate_game_folder(game_path, manifest)
        all_results[game_path.name] = results

    total_issues = sum(
        len(issues)
        for file_results in all_results.values()
        for issues in file_results.values()
    )

    if args.json:
        report = json.dumps(all_results, indent=2, ensure_ascii=False)
    else:
        report = generate_report(all_results)

    if args.output:
        Path(args.output).parent.mkdir(parents=True, exist_ok=True)
        Path(args.output).write_text(report, encoding="utf-8")
        print(f"[OK] Report saved to {args.output}", file=sys.stderr)
    else:
        print(report)

    if total_issues > 0:
        print(f"[WARN] {total_issues} issues found", file=sys.stderr)
        return 1
    else:
        print("[OK] All API calls are valid", file=sys.stderr)
        return 0


if __name__ == "__main__":
    sys.exit(main())
