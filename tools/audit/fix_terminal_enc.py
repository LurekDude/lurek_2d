"""Remove auto-generated stub section from terminal.lua and fix encoding."""
import os

path = os.path.join(os.path.dirname(__file__), '..', '..', 'content', 'examples', 'terminal.lua')
path = os.path.normpath(path)

with open(path, encoding='utf-8-sig') as f:
    lines = f.readlines()

print(f'Total lines: {len(lines)}')

cut = None
for i, line in enumerate(lines):
    stripped = line.strip()
    if stripped == 'print("content/examples/terminal.lua")':
        cut = i
        break

if cut is None:
    print('ERROR: could not find print() cut point')
    raise SystemExit(1)

print(f'Cut at line index {cut} (1-based line {cut + 1})')
kept = lines[:cut + 1]

with open(path, 'w', encoding='utf-8', newline='\n') as f:
    f.writelines(kept)

print(f'Written {len(kept)} lines')
print(f'Last line: {repr(kept[-1])}')
