#!/usr/bin/env python3
"""
tools/pack.py — Pack a Luna2D game directory into a .lunar archive.

A .lunar file is a ZIP archive (low compression) containing all game assets
with main.lua at the root. Double-clicking it on a machine that has Luna2D
installed will launch the game via the registered file association.

Usage:
    python tools/pack.py <game_dir> [output]

    <game_dir>  Path to the game folder containing main.lua (required).
    [output]    Output path for the .lunar file.
                Defaults to <game_dir_name>.lunar in the current directory.

Examples:
    python tools/pack.py demos/hello_world
      → hello_world.lunar

    python tools/pack.py demos/physics_demo dist/physics_demo.lunar
      → dist/physics_demo.lunar
"""

import sys
import os
import zipfile
import pathlib


def pack(game_dir: str, output: str | None = None) -> int:
    game_path = pathlib.Path(game_dir).resolve()

    if not game_path.is_dir():
        print(f"ERROR: '{game_dir}' is not a directory", file=sys.stderr)
        return 1

    if not (game_path / "main.lua").exists():
        print(f"ERROR: '{game_dir}' does not contain main.lua", file=sys.stderr)
        return 1

    if output is None:
        output = f"{game_path.name}.lunar"

    out_path = pathlib.Path(output)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(out_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=1) as zf:
        for file in sorted(game_path.rglob("*")):
            if file.is_file():
                arc_name = file.relative_to(game_path)
                zf.write(file, arc_name)

    size_kb = round(out_path.stat().st_size / 1024, 1)
    print(f"Packed: {out_path} ({size_kb} KB)")
    print(f"Run with: luna \"{out_path}\"")
    return 0


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    game_dir = sys.argv[1]
    output   = sys.argv[2] if len(sys.argv) >= 3 else None
    return pack(game_dir, output)


if __name__ == "__main__":
    sys.exit(main())
