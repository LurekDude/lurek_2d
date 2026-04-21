#!/usr/bin/env python3
"""Mass-rename love2d-style render calls in content/games/**/main.lua."""
import io, os, sys
from pathlib import Path

PAIRS = [
    ("lurek.render.drawText", "lurek.render.print"),
    ("lurek.render.drawRectFill", "lurek.render.rectangle"),
    ("lurek.render.drawRect", "lurek.render.rectangle"),
    ("lurek.render.drawCircle", "lurek.render.circle"),
    ("lurek.render.drawLine", "lurek.render.line"),
    ("lurek.draw.text", "lurek.render.print"),
    ("lurek.draw.print", "lurek.render.print"),
    ("lurek.draw.rect", "lurek.render.rectangle"),
    ("lurek.draw.circle", "lurek.render.circle"),
    ("lurek.draw.line", "lurek.render.line"),
    ("lurek.draw.setColor", "lurek.render.setColor"),
    ("lurek.draw.setBackgroundColor", "lurek.render.setBackgroundColor"),
]

def main():
    root = Path("content/games")
    totals = {old: 0 for old, _ in PAIRS}
    files_changed = 0
    files_total = 0
    for path in sorted(root.rglob("main.lua")):
        files_total += 1
        with io.open(path, "r", encoding="utf-8") as f:
            src = f.read()
        new = src
        per_file = 0
        for old, repl in PAIRS:
            n = new.count(old)
            if n:
                new = new.replace(old, repl)
                totals[old] += n
                per_file += n
        if new != src:
            with io.open(path, "w", encoding="utf-8", newline="\n") as f:
                f.write(new)
            files_changed += 1
            print(f"{path.as_posix()}: {per_file} replacements")
    print()
    print(f"Files scanned: {files_total}")
    print(f"Files changed: {files_changed}")
    print("Per-pair totals:")
    for old, _ in PAIRS:
        print(f"  {old}: {totals[old]}")

if __name__ == "__main__":
    main()
