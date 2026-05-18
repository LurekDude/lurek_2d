"""Fix all failing example stubs."""
import re

# ---- light.lua: newPoint → newLight ----
with open('content/examples/light.lua', encoding='utf-8') as f:
    text = f.read()
def fix_newlight(m):
    x, y, r = m.group(1), m.group(2), m.group(3)
    return f'lurek.light.newLight({x}, {y}, {r})'
new_text = re.sub(
    r'lurek\.light\.newPoint\((\d+),\s*(\d+),\s*(\d+),\s*[\d.]+,\s*[\d.]+,\s*[\d.]+\)',
    fix_newlight, text
)
count = text.count('lurek.light.newPoint')
print(f'light.lua: replaced {count} newPoint calls')
with open('content/examples/light.lua', 'w', encoding='utf-8') as f:
    f.write(new_text)

# ---- event.lua: lurek.event.on → newSignal ----
with open('content/examples/event.lua', encoding='utf-8') as f:
    text = f.read()
old = '  lurek.event.on("test_clear", function() end)\n  lurek.event.clear()\n  lurek.log.debug("event cleared", "example")'
new = '  -- Create a signal to verify clear behaviour.\n  local sig = lurek.event.newSignal("test_clear")\n  lurek.event.clear()\n  lurek.log.debug("event cleared; sig ok: " .. tostring(sig ~= nil), "example")'
if old in text:
    text = text.replace(old, new)
    print('event.lua: fixed clear stub')
else:
    print('event.lua: pattern NOT FOUND - check manually')
with open('content/examples/event.lua', 'w', encoding='utf-8') as f:
    f.write(text)

# ---- globe.lua: g:getId() → g:getName() ----
with open('content/examples/globe.lua', encoding='utf-8') as f:
    text = f.read()
old = '  local id = g:getId()\n  local same = lurek.globe.get(id)'
new = '  local name = g:getName()\n  local same = lurek.globe.get(name)'
if old in text:
    text = text.replace(old, new)
    print('globe.lua: fixed getId -> getName')
else:
    print('globe.lua: pattern NOT FOUND - check manually')
with open('content/examples/globe.lua', 'w', encoding='utf-8') as f:
    f.write(text)

# ---- input.lua: newCombo('ctrl+s') → newCombo({'ctrl','s'}) ----
with open('content/examples/input.lua', encoding='utf-8') as f:
    text = f.read()
old = "  local obj = lurek.input.newCombo('ctrl+s')"
new = "  local obj = lurek.input.newCombo({'ctrl', 's'})"
if old in text:
    text = text.replace(old, new)
    print('input.lua: fixed newCombo arg')
else:
    print('input.lua: pattern NOT FOUND')
with open('content/examples/input.lua', 'w', encoding='utf-8') as f:
    f.write(text)

# ---- math.lua: newBezierCurve with nested tables → flat table ----
with open('content/examples/math.lua', encoding='utf-8') as f:
    text = f.read()
old = '  local obj = lurek.math.newBezierCurve({{0,0},{100,0},{100,100},{200,100}})'
new = '  local obj = lurek.math.newBezierCurve({0,0, 100,0, 100,100, 200,100})'
if old in text:
    text = text.replace(old, new)
    print('math.lua: fixed newBezierCurve args')
else:
    print('math.lua: pattern NOT FOUND')
with open('content/examples/math.lua', 'w', encoding='utf-8') as f:
    f.write(text)

# ---- ai.lua: newNeuroevolution({2,4,1}, 30, 1) → layer tables ----
with open('content/examples/ai.lua', encoding='utf-8') as f:
    text = f.read()
old = '  local obj = lurek.ai.newNeuroevolution({2,4,1}, 30, 1)'
new = '  local obj = lurek.ai.newNeuroevolution({{inputs=2,outputs=4},{inputs=4,outputs=1}}, 30, 1)'
if old in text:
    text = text.replace(old, new)
    print('ai.lua: fixed newNeuroevolution args')
else:
    print('ai.lua: pattern NOT FOUND')
with open('content/examples/ai.lua', 'w', encoding='utf-8') as f:
    f.write(text)

# ---- sprite.lua: newSheet(path, fw, fh, n) → newSheet(tw, th, fw, fh) ----
with open('content/examples/sprite.lua', encoding='utf-8') as f:
    text = f.read()
old = "  local obj = lurek.sprite.newSheet('assets/textures/logo.png', 64, 64, 1)"
new = "  local obj = lurek.sprite.newSheet(256, 256, 64, 64)"
if old in text:
    text = text.replace(old, new)
    print('sprite.lua: fixed newSheet args')
else:
    print('sprite.lua: pattern NOT FOUND')
with open('content/examples/sprite.lua', 'w', encoding='utf-8') as f:
    f.write(text)

print('Done.')
