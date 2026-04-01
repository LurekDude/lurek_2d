"""Fix Lua-style -- comments that ended up in crafting_tests.rs."""
import re

with open('tests/crafting_tests.rs', encoding='utf-8') as f:
    c = f.read()

# Replace any line that starts with "-- " (Lua comment) but is NOT in a Lua string (inside r#"..."#)
# Strategy: split by Lua string bounded regions and only replace outside them
# Simpler approach: these are section headers like "-- CraftQueue\n-- ───..."
# Replace '-- CraftQueue\n-- ─...' with Rust equivalents
import re
# Replace all lines that are exactly "-- Something" at the start (not inside r#) with "// Something"
# The bad lines look like: ^-- CraftQueue$ and ^-- ─────...
lines = c.split('\n')
in_lua_str = False
result = []
for line in lines:
    # Track r#" ... "# boundaries (simplified: if line contains r#" it starts, if "# it ends)
    if 'r#"' in line:
        in_lua_str = True
    if '"#' in line and in_lua_str:
        in_lua_str = False
        result.append(line)
        continue
    if not in_lua_str and re.match(r'^-- ', line):
        line = '//' + line[2:]
    result.append(line)

fixed = '\n'.join(result)
with open('tests/crafting_tests.rs', 'w', encoding='utf-8') as f:
    f.write(fixed)
print('crafting_tests.rs fixed')
# Count remaining bad patterns
bad = [l for l in fixed.split('\n') if re.match(r'^-- ', l)]
print(f'{len(bad)} remaining bad lines')
if bad:
    for b in bad[:5]:
        print(repr(b[:80]))
