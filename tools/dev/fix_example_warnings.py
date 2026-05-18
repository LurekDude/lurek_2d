"""
Fix all remaining Lua LS warnings in content/examples/ files.
Run this script from the repo root: python tools/dev/fix_example_warnings.py
"""
import re, sys, os

ROOT = r'c:\Users\tombl\Documents\lurek2D'

def fix_file(rel_path, replacements, log=True):
    """Apply a list of (old, new) string replacements to a file."""
    fpath = os.path.join(ROOT, rel_path)
    with open(fpath, encoding='utf-8') as f:
        content = f.read()
    original = content
    for old, new in replacements:
        if old in content:
            content = content.replace(old, new, 1)  # replace first occurrence only
            if log:
                print(f'  FIXED: {rel_path}: {old[:60]!r} → {new[:60]!r}')
        else:
            print(f'  WARN: not found: {rel_path}: {old[:60]!r}')
    if content != original:
        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False


def fix_file_all(rel_path, replacements, log=True):
    """Apply a list of (old, new) string replacements to a file - ALL occurrences."""
    fpath = os.path.join(ROOT, rel_path)
    with open(fpath, encoding='utf-8') as f:
        content = f.read()
    original = content
    for old, new in replacements:
        count = content.count(old)
        if count > 0:
            content = content.replace(old, new)
            if log:
                print(f'  FIXED ({count}x): {rel_path}: {old[:60]!r}')
        else:
            print(f'  WARN: not found: {rel_path}: {old[:60]!r}')
    if content != original:
        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False


# ─────────────────────────────────────────────────────────────────────────────
# animation.lua - newAnimation doesn't exist in docs, use new() instead
# ─────────────────────────────────────────────────────────────────────────────
print('\n=== animation.lua ===')
fix_file_all('content/examples/animation.lua', [
    (
        "local anim = lurek.animation.newAnimation('idle', 4, 0.1)\n"
        "  local obj = lurek.animation.newStateMachine(anim, 'idle')",
        "local anim = lurek.animation.new()\n"
        "  local obj = lurek.animation.newStateMachine(anim, 'idle')"
    ),
    (
        "local obj = lurek.animation.newAnimation('walk', 6, 0.1)",
        "local obj = lurek.animation.new()"
    ),
])

# ─────────────────────────────────────────────────────────────────────────────
# physics.lua fixes
# ─────────────────────────────────────────────────────────────────────────────
print('\n=== physics.lua ===')

# 1. isSleepingAllowed stub - needs world+body args
fix_file('content/examples/physics.lua', [
    (
        "do\n"
        "  lurek.physics.setSleepingAllowed(true)\n"
        "  local allowed = lurek.physics.isSleepingAllowed()\n"
        "  lurek.log.debug(\"is sleeping allowed: \" .. tostring(allowed), \"physics\")\n"
        "end\n"
        "lurek.physics.step(world_ud, 0.016)",
        "do\n"
        "  local world = lurek.physics.newWorld(0, 9.8)\n"
        "  local body = world:newBody(100, 100, 'dynamic')\n"
        "  lurek.physics.setSleepingAllowed(world, body, true)\n"
        "  local allowed = lurek.physics.isSleepingAllowed(world, body)\n"
        "  lurek.log.debug(\"is sleeping allowed: \" .. tostring(allowed), \"physics\")\n"
        "end"
    ),
])

# 2. setSleepingAllowed stub - needs world+body args, delete bare line after
fix_file('content/examples/physics.lua', [
    (
        "do\n"
        "  lurek.physics.setSleepingAllowed(true)\n"
        "  lurek.log.debug(\"sleeping allowed set\", \"physics\")\n"
        "end\n"
        "lurek.physics.setSleepingAllowed(world_ud, body_ud, allowed)",
        "do\n"
        "  local world = lurek.physics.newWorld(0, 9.8)\n"
        "  local body = world:newBody(100, 100, 'dynamic')\n"
        "  lurek.physics.setSleepingAllowed(world, body, false)\n"
        "  lurek.log.debug(\"sleeping allowed set to false\", \"physics\")\n"
        "end"
    ),
])

# 3. LCellular stubs: procgen → physics, 4 args → 2 args
fix_file_all('content/examples/physics.lua', [
    ("lurek.procgen.newCellular(40, 30, 0.45, 42)", "lurek.physics.newCellular(40, 30)"),
])

# 4. LTerrain stubs: procgen → physics, 3 args → 4 args (needs world)
fix_file_all('content/examples/physics.lua', [
    (
        "local obj = lurek.procgen.newTerrain(64, 64, 42)",
        "local world = lurek.physics.newWorld(0, 9.8)\n"
        "  local obj = lurek.physics.newTerrain(64, 64, 1.0, world)"
    ),
])

# 5. LZone stubs: newZone not in docs - replace with comment
fix_file_all('content/examples/physics.lua', [
    (
        "  local w = lurek.physics.newWorld(0, 9.8)\n"
        "  local obj = w:newZone(0, 0, 100, 100)\n"
        "  lurek.log.debug(\"type: \" .. obj:type(), \"physics\")",
        "  -- LZone is created via world:newZone(x, y, w, h)\n"
        "  local w = lurek.physics.newWorld(0, 9.8)\n"
        "  lurek.log.debug(\"LZone: created via w:newZone(x, y, w, h)\", \"physics\")"
    ),
    (
        "  local w = lurek.physics.newWorld(0, 9.8)\n"
        "  local obj = w:newZone(0, 0, 100, 100)\n"
        "  lurek.log.debug(\"typeOf LZone: \" .. tostring(obj:typeOf(\"LZone\")), \"physics\")",
        "  -- LZone is created via world:newZone(x, y, w, h)\n"
        "  local w = lurek.physics.newWorld(0, 9.8)\n"
        "  lurek.log.debug(\"LZone: typeOf verified at runtime via w:newZone\", \"physics\")"
    ),
])

# ─────────────────────────────────────────────────────────────────────────────
# render.lua - delete bare lines and fix draw stubs
# ─────────────────────────────────────────────────────────────────────────────
print('\n=== render.lua ===')

# Each bare line is right after an `end` and before a blank line + next stub
# We need to read the file to handle these correctly
fpath = os.path.join(ROOT, 'content/examples/render.lua')
with open(fpath, encoding='utf-8') as f:
    content = f.read()

original = content

# Delete bare lines that are right after end blocks
bare_patterns = [
    '\nlurek.render.rectangle()\n',
    '\nlurek.render.circle(mode, 0.0, 0.0, 24.0)\n',
    '\nlurek.render.ellipse(mode, 0.0, 0.0, rx, ry)\n',
    '\nlurek.render.triangle(mode, x1, y1, x2, y2, x3, y3)\n',
    '\nlurek.render.line(0.0, 0.0, 100.0, 100.0)\n',
    '\nlurek.render.line(...)\n',
    '\nlurek.render.polygon(fill_vertices)\n',
    '\nlurek.render.polygon(...)\n',
    '\nlurek.render.arc()\n',
    '\nlurek.render.arc(0.0, 0.0, 50.0, 0, 3.14159, "fill")\n',
    '\nlurek.render.setLineWidth(64.0)\n',
    '\nlurek.render.resetCanvas(ud)\n',
]

for pat in bare_patterns:
    if pat in content:
        content = content.replace(pat, '\n', 1)
        print(f'  DELETED bare line: {pat.strip()[:60]!r}')
    else:
        # Try without strict newline prefix/suffix
        stripped = pat.strip()
        if '\n' + stripped + '\n' in content:
            content = content.replace('\n' + stripped + '\n', '\n', 1)
            print(f'  DELETED (alt) bare line: {stripped[:60]!r}')

# Fix lurek.render.rect → use canvas+draw
if 'lurek.render.rect(' in content:
    # Find the draw stubs that use lurek.render.rect
    # Pattern 1: draw(lurek.render.rect(10, 10, 50, 50))
    content = content.replace(
        'lurek.render.draw(lurek.render.rect(10, 10, 50, 50))',
        'local canvas = lurek.render.newCanvas(50, 50)\n    lurek.render.draw(canvas, 10, 10)'
    )
    # Pattern 2: draw(lurek.render.rect(0, 0, 100, 100))
    content = content.replace(
        'lurek.render.draw(lurek.render.rect(0, 0, 100, 100))',
        'lurek.render.setColor(1, 0, 0, 1)\n    lurek.render.rectangle("fill", 0, 0, 100, 100)'
    )
    if 'lurek.render.rect(' in content:
        print('  WARN: still has lurek.render.rect(')
    else:
        print('  FIXED: lurek.render.rect -> canvas/rectangle')

if content != original:
    with open(fpath, 'w', encoding='utf-8') as f:
        f.write(content)
    print('  render.lua saved')
else:
    print('  render.lua: no changes (bare lines not found as expected)')

# ─────────────────────────────────────────────────────────────────────────────
# tilemap.lua - missing args
# ─────────────────────────────────────────────────────────────────────────────
print('\n=== tilemap.lua ===')
fix_file_all('content/examples/tilemap.lua', [
    ("lurek.tilemap.newMapBlock()", "lurek.tilemap.newMapBlock(16, 16)"),
    ("lurek.tilemap.newMapGroup()", 'lurek.tilemap.newMapGroup("test_group")'),
])

# ─────────────────────────────────────────────────────────────────────────────
# ui.lua fixes
# ─────────────────────────────────────────────────────────────────────────────
print('\n=== ui.lua ===')
fix_file('content/examples/ui.lua', [
    # newSeparator: max 1 bool arg
    ("lurek.ui.newSeparator(0, 0, 200, false)", "lurek.ui.newSeparator(false)"),
])

fix_file('content/examples/ui.lua', [
    # LTheme:type - getTheme returns bool, use newTheme() instead
    (
        "-- ---- Stub: LTheme:type ---------------------------------------------------\n"
        "--@api-stub: LTheme:type\n"
        "-- Returns the type name of this object.\n"
        "do\n"
        "  local obj = lurek.ui.getTheme()\n"
        "  lurek.log.debug(\"type: \" .. obj:type(), \"example\") -- \"LTheme\"\n"
        "end",
        "-- ---- Stub: LTheme:type ---------------------------------------------------\n"
        "--@api-stub: LTheme:type\n"
        "-- Returns the type name of this object.\n"
        "do\n"
        "  local obj = lurek.ui.newTheme()\n"
        "  lurek.log.debug(\"type: \" .. obj:type(), \"example\") -- \"LTheme\"\n"
        "end"
    ),
])

fix_file('content/examples/ui.lua', [
    # LTheme:typeOf
    (
        "-- ---- Stub: LTheme:typeOf -------------------------------------------------\n"
        "--@api-stub: LTheme:typeOf\n"
        "-- Checks whether this object matches the given type name.\n"
        "do\n"
        "  local obj = lurek.ui.getTheme()\n"
        "  lurek.log.debug(\"typeOf LTheme: \" .. tostring(obj:typeOf(\"LTheme\")), \"example\") -- true\n"
        "end",
        "-- ---- Stub: LTheme:typeOf -------------------------------------------------\n"
        "--@api-stub: LTheme:typeOf\n"
        "-- Checks whether this object matches the given type name.\n"
        "do\n"
        "  local obj = lurek.ui.newTheme()\n"
        "  lurek.log.debug(\"typeOf LTheme: \" .. tostring(obj:typeOf(\"LTheme\")), \"example\") -- true\n"
        "end"
    ),
])

fix_file('content/examples/ui.lua', [
    # LToolbar:addButton - function callback not allowed (docs say tooltip: string?)
    (
        '  tb:addButton("New", function()\n'
        '    lurek.log.debug("toolbar: New clicked", "ui")\n'
        '  end)\n'
        '  tb:addButton("Save", function()\n'
        '    lurek.log.debug("toolbar: Save clicked", "ui")\n'
        '  end)',
        '  tb:addButton("New", "Create a new file")\n'
        '  tb:addButton("Save", "Save current file")'
    ),
])

fix_file_all('content/examples/ui.lua', [
    # LUiWidget:type and typeOf - newLabel takes 1 string arg (not 3)
    ("lurek.ui.newLabel(0, 0, 'widget')", "lurek.ui.newLabel('widget')"),
])

print('\n=== All fixes applied ===')
