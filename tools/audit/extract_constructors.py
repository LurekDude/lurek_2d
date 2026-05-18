"""Extract all lurek.module.function signatures from docs/api/lurek.lua"""
import re, os

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', '..'))
with open(os.path.join(ROOT, 'docs', 'api', 'lurek.lua'), encoding='utf-8') as f:
    lines = f.readlines()

# Match lines like: ---@field key function(...)  OR function lurek.X.Y(...)
# The API uses field declarations like:
# lurek.ai = {}
# Then function docs. Search for actual assignments:
# lurek.audio.newSource = ...
# or the new format where fields are declared

current_ns = None
for i, line in enumerate(lines):
    s = line.strip()
    # Match 'lurek.X = {}' or 'lurek.X =' namespace declarations
    m = re.match(r'^(lurek\.\w+)\s*=\s*\{\}', s)
    if m:
        current_ns = m.group(1)
        print(f"NAMESPACE: {current_ns}")
        continue
    # Match field declarations: ---@field name type
    m = re.match(r'^---@field\s+(\w+)\s+(.+)', s)
    if m and current_ns:
        fname = m.group(1)
        ftype = m.group(2)
        if 'fun(' in ftype:
            print(f"  {current_ns}.{fname}: {ftype}")
