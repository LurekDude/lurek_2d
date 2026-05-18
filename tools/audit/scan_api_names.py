"""Extract all registered function names from Rust API files."""
import re, os

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', '..'))
api_dir = os.path.join(ROOT, 'src', 'lua_api')

files = ['ai_api.rs','animation_api.rs','audio_api.rs','data_api.rs',
    'devtools_api.rs','docs_api.rs','event_api.rs','filesystem_api.rs',
    'globe_api.rs','graph_api.rs','html_api.rs','image_api.rs',
    'input_api.rs','light_api.rs','math_api.rs','mods_api.rs',
    'network_api.rs','pathfind_api.rs','patterns_api.rs','physics_api.rs',
    'pipeline_api.rs','raycaster_api.rs','render_api.rs','sprite_api.rs',
    'thread_api.rs','tilemap_api.rs','tween_api.rs','ui_api.rs']

for fname in files:
    fpath = os.path.join(api_dir, fname)
    if not os.path.exists(fpath):
        continue
    with open(fpath, encoding='utf-8') as f:
        content = f.read()
    names = re.findall(r'\.set\("(\w+)"\s*,', content)
    names2 = re.findall(r'add_method\("(\w+)"', content)
    names3 = re.findall(r'add_function\("(\w+)"', content)
    all_names = sorted(set(names + names2 + names3))
    mod = fname.replace('_api.rs', '')
    print(f'lurek.{mod}: {all_names[:30]}')
