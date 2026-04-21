"""Remove BOM from all files in src/ and tests/."""
import os
import glob
from pathlib import Path

def strip_bom(p):
    b = p.read_bytes()
    if b.startswith(b"\xef\xbb\xbf"):
        p.write_bytes(b[3:])
        return True
    return False

count = 0
for root_dir in ["src", "tests", "docs", "content"]:
    for p in Path(root_dir).rglob("*.*"):
        if p.is_file() and p.suffix in [".rs", ".lua", ".md", ".toml"]:
            if strip_bom(p):
                count += 1
print(f"Stripped BOM from {count} files.")
