import os, glob, subprocess, re

def check(f):
    return subprocess.run(['luac', '-p', f], capture_output=True)

for path in [
    'tests/lua/evidence/test_animation_evidence.lua',
    'tests/lua/evidence/test_audio_evidence.lua',
    'tests/lua/evidence/test_effect_evidence.lua',
    'tests/lua/evidence/test_geometry_evidence.lua',
    'tests/lua/evidence/test_physics_evidence.lua',
    'tests/lua/evidence/test_raycaster_evidence.lua',
    'tests/lua/evidence/test_render_evidence.lua',
    'tests/lua/unit/test_particle_unit.lua'
]:
    with open(path, 'rb') as f:
        raw = f.read()

    try:
        content = raw.decode('utf-8')
    except:
        content = raw.decode('latin-1')

    # Strip Mojibake
    content = content.replace('Ă˘â€”â‚¬', '-')
    content = content.replace('Ă˘â€ťâ‚¬', '-')
    content = content.replace('Ä‚â€”', 'x')
    content = content.replace('Ă˘â‚¬â€ť', '-')
    content = content.replace('Ă—', 'x')
    content = content.replace('â€ť', '-')
    content = content.replace('â€', '-')
    content = content.replace('â€”', '-')
    content = content.replace('Â', ' ')
    content = content.replace('ÄŹ', '')
    content = content.replace('»', '')
    content = content.replace('ĹĽ', '')
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"Fixed encoding for {path}")
