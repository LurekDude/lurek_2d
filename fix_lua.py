import os

for f in os.listdir('tests/lua/evidence/'):
    if not f.endswith('.lua'): continue
    path = os.path.join('tests/lua/evidence/', f)
    
    with open(path, 'rb') as file:
        raw = file.read()
    
    # Try utf8 first
    try:
        content = raw.decode('utf-8')
    except UnicodeDecodeError:
        content = raw.decode('latin-1')

    # Replace bad characters:
    content = content.replace('Ă˘â€”â‚¬', '-')
    content = content.replace('Ă˘â€ťâ‚¬', '-')
    content = content.replace('Ä‚â€”', 'x')
    content = content.replace('Ă˘â‚¬â€ť', '-')
    content = content.replace('Ă—', 'x')
    content = content.replace('â€ť', '-')
    content = content.replace('â€', '-')
    content = content.replace('â€”', '-')
    content = content.replace('Â', ' ')
    
    # Fix the mismatched end) block in test_animation_evidence.lua
    if f == 'test_animation_evidence.lua':
        o = "lurek.image.savePNG(out, OUT .. \"evidence_animation_frame_grid.png\")\n    end)\n        local events = anim:pollEvents()"
        n = "lurek.image.savePNG(out, OUT .. \"evidence_animation_frame_grid.png\")\n        \n        local events = anim:pollEvents()"
        content = content.replace(o, n)
        o2 = "lurek.image.savePNG(img, OUT .. \"evidence_animation_speed_compare.png\")\n    end)\nend)"
        n2 = "lurek.image.savePNG(img, OUT .. \"evidence_animation_speed_compare.png\")\n    end)\nend)"
        
    # Extra fix: test_particle_unit.lua has cp1252 corruption too!
    
    with open(path, 'wb') as file:
        file.write(content.encode('utf-8'))

# also fix the unit tests
for root, dirs, files in os.walk('tests/lua/unit/'):
    for f in files:
        if not f.endswith('.lua'): continue
        path = os.path.join(root, f)
        with open(path, 'rb') as file: raw = file.read()
        try:
            content = raw.decode('utf-8')
        except UnicodeDecodeError:
            content = raw.decode('latin-1')
        content = content.replace('Ă˘â€”â‚¬', '-').replace('Ä‚â€”', 'x').replace('Ă˘â‚¬â€ť', '-').replace('Ă—', 'x')
        with open(path, 'wb') as file:
            file.write(content.encode('utf-8'))

print('Cleaned evidence and unit tests')
