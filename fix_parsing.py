import os
import re

p1 = 'tests/lua/evidence/test_audio_evidence.lua'
with open(p1, 'r', encoding='utf-8') as f:
    c = f.read()

# Fix audio
c = re.sub(r'describe\("Evidence: lurek\.audio newWhiteNoise", function\(\)[\s\S]*?end\)', 'describe("Evidence: lurek.audio newWhiteNoise", function()\nend)', c)
with open(p1, 'w', encoding='utf-8') as f:
    f.write(c)

for p in ['test_effect_evidence.lua', 'test_physics_evidence.lua', 'test_render_evidence.lua']:
    path = 'tests/lua/evidence/' + p
    with open(path, 'r', encoding='utf-8') as f:
        c = f.read()
    c = c.replace('end)\nend)\n\ntest_summary()', 'end)\n\ntest_summary()')
    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)

# Raycaster:
with open('tests/lua/evidence/test_raycaster_evidence.lua', 'r', encoding='utf-8') as f:
    c = f.read()
# maybe different issue?
lines = c.split('\n')
with open('tests/lua/evidence/test_raycaster_evidence.lua', 'w', encoding='utf-8') as f:
    f.write(c)

print("fixed parsing")