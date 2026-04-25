import re
with open('content/examples/tilemap.lua', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(r'tm:applyAutoTile\((\d+)\)(?!\s*,)', lambda m: f'tm:applyAutoTile({m.group(1)}, "terrain")', content)
content = re.sub(r'tm:applyAutoTile8\((\d+)\)(?!\s*,)', lambda m: f'tm:applyAutoTile8({m.group(1)}, "terrain")', content)
content = re.sub(r'tm:applyAutoTile8At\((\d+),\s*(\d+),\s*(\d+)\)', lambda m: f'tm:applyAutoTile8At({m.group(1)}, {m.group(2)}, {m.group(3)}, "terrain")', content)
content = re.sub(r'tm:applyAutoTileAt\((\d+),\s*(\d+),\s*(\d+)\)', lambda m: f'tm:applyAutoTileAt({m.group(1)}, {m.group(2)}, {m.group(3)}, "terrain")', content)

with open('content/examples/tilemap.lua', 'w', encoding='utf-8') as f:
    f.write(content)
print('Fixed applyAutoTile calls')
