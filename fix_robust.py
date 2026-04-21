import glob
import subprocess
import re

FILES = [
    'tests/lua/evidence/test_animation_evidence.lua',
    'tests/lua/evidence/test_audio_evidence.lua',
    'tests/lua/evidence/test_effect_evidence.lua',
    'tests/lua/evidence/test_geometry_evidence.lua',
    'tests/lua/evidence/test_physics_evidence.lua',
    'tests/lua/evidence/test_raycaster_evidence.lua',
    'tests/lua/evidence/test_render_evidence.lua',
    'tests/lua/unit/test_particle_unit.lua'
]

# FORCIBLY STRIP ALL NON-ASCII 
for path in FILES:
    with open(path, 'rb') as f: raw = f.read()
    clean = bytearray()
    for b in raw:
        if b < 128: clean.append(b)
        else: clean.append(32) # space
    with open(path, 'wb') as f: f.write(clean)

for path in FILES:
    for _ in range(50):
        res = subprocess.run(['luac', '-p', path], capture_output=True)
        if res.returncode == 0:
            print(f"Fixed {path}")
            break
        
        out = res.stderr.decode().strip()
        match = re.search(r':(\d+): (.*)$', out)
        if not match:
            print(f"Failed to parse err in {path}: {out}")
            break
            
        line_num = int(match.group(1))
        err = match.group(2)
        
        with open(path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        if err.startswith('<eof> expected') or err.startswith("'<eof>' expected"):
            # delete line
            print(f"Deleting eof end at {path}:{line_num}")
            if line_num <= len(lines):
                del lines[line_num - 1]
                with open(path, 'w', encoding='utf-8') as f:
                    f.writelines(lines)
            else:
                break
        elif err.startswith("'end' expected"):
            # add end
            print(f"Adding end to {path}")
            # Insert before test_summary() if possible, else at eof
            inserted = False
            for i in range(len(lines)-1, -1, -1):
                if 'test_summary()' in lines[i]:
                    lines.insert(i, 'end)\n')
                    inserted = True
                    break
            if not inserted:
                lines.append('end)\n')
            with open(path, 'w', encoding='utf-8') as f:
                f.writelines(lines)
        elif 'unexpected symbol' in err:
            print(f"Deleting unexpected symbol line {path}:{line_num}")
            if line_num <= len(lines):
                del lines[line_num - 1]
                with open(path, 'w', encoding='utf-8') as f:
                    f.writelines(lines)
            else:
                break
        elif "')' expected" in err:
            print(f"Fixing missing ) at {path}:{line_num}")
            # probably missing ) in describe/it or end)
            if line_num <= len(lines):
                lines[line_num - 1] = lines[line_num - 1].rstrip() + ')\n'
                with open(path, 'w', encoding='utf-8') as f:
                    f.writelines(lines)
            else:
                break
        else:
            print(f"Unknown err {err}")
            break
