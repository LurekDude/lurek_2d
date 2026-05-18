"""Find module-level constructors (registered on lurek.X table, not on UserData)."""
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
        lines = f.readlines()

    mod = fname.replace('_api.rs', '')
    # Find blocks between "pub fn register" and "impl LuaUserData"
    # Module-level functions are in the register() function
    in_register = False
    brace_depth = 0
    register_lines = []
    for line in lines:
        if re.search(r'pub fn register', line):
            in_register = True
            brace_depth = 0
        if in_register:
            brace_depth += line.count('{') - line.count('}')
            register_lines.append(line)
            if brace_depth <= 0 and len(register_lines) > 2:
                break

    # Now find .set("name", ...) in the register lines
    register_text = ''.join(register_lines)
    names = re.findall(r'\.set\("(\w+)"\s*,', register_text)
    # Filter out the module table itself ("ai", "animation" etc.)
    mod_name_pattern = re.compile(r'^(lurek\.\w+|ai|animation|audio|data|devtools|docs|event|filesystem|globe|graph|html|image|input|light|math|mods|network|pathfind|patterns|physics|pipeline|raycaster|render|sprite|thread|tilemap|tween|ui)$')
    funcs = [n for n in names if not mod_name_pattern.match(n)]
    if funcs:
        print(f'lurek.{mod}: {sorted(set(funcs))}')
    else:
        print(f'lurek.{mod}: (no module-level functions found in register)')
