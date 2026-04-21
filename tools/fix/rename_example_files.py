import re, os, pathlib

ROOT = pathlib.Path("C:/Users/tombl/Documents/luna2d")
SKIP = {"build", "target", ".git", "node_modules", "work", "ideas"}
EXTS = {".lua", ".rs", ".md", ".txt", ".toml", ".py", ".json", ".yaml", ".yml", ".ts", ".js"}

RENAMES = [
    ("examples/physics_collision.lua",       "examples/physics_collision.lua"),
    ("examples\\collision.lua",      "examples\\physics_collision.lua"),
    ("examples/runtime.lua",          "examples/runtime.lua"),
    ("examples\\engine.lua",         "examples\\runtime.lua"),
    ("examples/runtime_platform.lua",          "examples/runtime_platform.lua"),
    ("examples\\system.lua",         "examples\\runtime_platform.lua"),
]

total_files, total_lines = 0, 0
for dirpath, dirnames, filenames in os.walk(ROOT):
    dirnames[:] = [d for d in dirnames if d not in SKIP]
    for fn in filenames:
        fp = pathlib.Path(dirpath) / fn
        if fp.suffix not in EXTS:
            continue
        try:
            orig = fp.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        text = orig
        for old, new in RENAMES:
            text = text.replace(old, new)
        if text != orig:
            fp.write_text(text, encoding="utf-8")
            lines = sum(1 for a, b in zip(orig.splitlines(), text.splitlines()) if a != b)
            print(f"  CHANGED: {fp.relative_to(ROOT)} ({lines} lines)")
            total_files += 1
            total_lines += lines
print(f"Done: {total_files} files, {total_lines} lines changed.")
