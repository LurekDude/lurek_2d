"""Scan specific Rust API files for exact function signatures."""
import re, os, sys

ROOT = r'c:\Users\tombl\Documents\lurek2D'

queries = {
    'src/lua_api/ui_api.rs': ['newLabel', 'newSeparator', 'addButton', 'LTheme', 'typeOf', 'newToolbar', 'impl_type'],
    'src/lua_api/animation_api.rs': ['newAnimation', 'newStateMachine', 'stateMachine'],
    'src/lua_api/physics_api.rs': ['newZone', 'setSleepingAllowed', 'isSleepingAllowed', 'newCellular', 'newTerrain'],
    'src/lua_api/tilemap_api.rs': ['newIsoMap', 'newMapBlock', 'newMapGroup', 'newLargeMap'],
    'src/lua_api/sprite_api.rs': ['newSheet'],
    'src/lua_api/thread_api.rs': ['newPool'],
}

for rel, targets in queries.items():
    fpath = os.path.join(ROOT, rel)
    with open(fpath, encoding='utf-8') as f:
        lines = f.readlines()
    print(f'\n=== {rel} ===')
    for i, line in enumerate(lines):
        ls = line.rstrip()
        if any(f'"{t}"' in ls for t in targets) or any(f'impl_type' in ls for t in targets if 'impl_type' == t) or 'impl_type' in ls:
            # show context
            start = max(0, i-1)
            end = min(len(lines), i+3)
            for j in range(start, end):
                print(f'  {j+1}: {lines[j].rstrip()}')
            print()
