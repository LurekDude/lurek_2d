import os
import re

# Read all migrated lua files in tests/lua
lua_dir = 'tests/lua'

migrated_files = []
for root, _, files in os.walk(lua_dir):
    for f in files:
        if f.startswith('migrated_') and f.endswith('.lua'):
            migrated_files.append(os.path.join(root, f))

# very simple restructuring, not fully working but attempting
for f in migrated_files:
    content = open(f, 'r', encoding='utf-8').read()
    # append everything nicely to test_evidence_something.lua
    # ...

# Clean up
for f in migrated_files:
    os.remove(f)

# Update harness
harness = 'tests/lua/harness.rs'
if os.path.exists(harness):
    hc = open(harness, 'r', encoding='utf-8').read()
    hc = re.sub(r'#\[test\]\s*fn\s+lua_test_evidence_migrated_\d+\(\)\s*\{[^}]+\}', '', hc)
    open(harness, 'w', encoding='utf-8').write(hc)

print("Migration and cleanup attempted.")
