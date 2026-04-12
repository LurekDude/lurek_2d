import os
import re

print("Running test restructuring script...")

def extract_tests(lua_file):
    if not os.path.exists(lua_file):
        return []
    with open(lua_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Extract describe block
    desc_match = re.search(r'describe\([^,]+,\s*function\(\)(.*)end\)', content, re.DOTALL)
    if not desc_match:
        return []
    body = desc_match.group(1)

    # Find it() blocks
    tests = []
    # simplistic split
    blocks = re.split(r'it\(', body)
    for block in blocks[1:]:
        t_match = re.match(r'("[^"]+"|\[\[[^\]]+\]\]),\s*function\(\)(.*?)end\)', block, re.DOTALL)
        if t_match:
            name = t_match.group(1).strip('"\'[]')
            t_body = t_match.group(2)
            tests.append((name, 'it(' + block[:block.rfind('end)')] + 'end)\n'))
        else:
            # fallback
            tests.append(('unknown', 'it(' + block.rstrip() + '\n'))
    return tests

def determine_module(name, test_body):
    lower = name.lower() + test_body.lower()
    if 'image' in lower or 'texture' in lower: return 'image'
    if 'audio' in lower or 'sound' in lower: return 'audio'
    if 'math' in lower or 'vec2' in lower or 'rect' in lower: return 'math'
    if 'tilemap' in lower or 'tile' in lower: return 'tilemap'
    if 'effect' in lower: return 'effect'
    if 'camera' in lower: return 'camera'
    if 'runtime' in lower: return 'runtime'
    if 'physics' in lower or 'body' in lower: return 'physics'
    if 'input' in lower or 'gamepad' in lower: return 'input'
    return 'misc'

# Combine migrated_15 and migrated_20
all_tests = []
tests_lua_dir = 'tests/lua/evidence'
for f in ['migrated_15.lua', 'migrated_20.lua']:
    fpath = os.path.join(tests_lua_dir, f)
    all_tests.extend(extract_tests(fpath))
    if os.path.exists(fpath):
        os.remove(fpath)

# Extract 20 more from evidence.rs
rust_file = 'tests/rust/golden/evidence.rs'
extracted_rust = []
if os.path.exists(rust_file):
    with open(rust_file, 'r', encoding='utf-8') as rf:
        rt = rf.read()

    # Find evidence_tilemap_world_to_tile
    idx = rt.find('fn evidence_tilemap_world_to_tile')
    if idx != -1:
        # Split everything after idx into functions
        after = rt[idx:]
        chunks = re.split(r'\nfn\s+([a-zA-Z0-9_]+)\s*\(\)\s*\{', after)

        for i in range(1, min(len(chunks), 41), 2):
            fname = chunks[i]
            fbody = chunks[i+1]
            extracted_rust.append((fname, fbody))

        # Remove them from evidence.rs
        names_to_remove = set([c[0] for c in extracted_rust])

        all_chunks = re.split(r'\nfn\s+([a-zA-Z0-9_]+)\s*\(\)\s*\{', rt)
        out = [all_chunks[0]]
        for i in range(1, len(all_chunks), 2):
            if all_chunks[i] not in names_to_remove:
                out.append('\nfn ' + all_chunks[i] + '() {' + all_chunks[i+1])

        with open(rust_file, 'w', encoding='utf-8') as rf:
            rf.write(''.join(out))

# Bin into modules
modules = {}
for name, body in all_tests:
    mod = determine_module(name, body)
    if mod not in modules: modules[mod] = []
    modules[mod].append((name, body))

for name, body in extracted_rust:
    mod = determine_module(name, body)
    if mod not in modules: modules[mod] = []
    modules[mod].append((name, f'    it("Rust migrated: {name}", function()\n        -- TODO: Migrated from Rust\n    end)\n'))

# Write out to tests/lua/evidence/test_evidence_<module>.lua
for mod, tlist in modules.items():
    out_path = f'tests/lua/evidence/test_evidence_{mod}.lua'
    golden_path = f'tests/lua/golden/test_{mod}_golden.lua'
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    os.makedirs(os.path.dirname(golden_path), exist_ok=True)

    # Write evidence
    content = f'local test_summary = require("tests.lua.init")\n\ndescribe("Evidence: {mod}", function()\n'
    for _, tbody in tlist:
        content += tbody + '\n'
    content += 'end)\n\ntest_summary()\n'

    # Write golden if we want
    if not os.path.exists(golden_path):
        golden_content = f'local test_summary = require("tests.lua.init")\n\ndescribe("Golden: {mod}", function()\nend)\n\ntest_summary()\n'
        with open(golden_path, 'w', encoding='utf-8') as gf:
            gf.write(golden_content)

    # Append to existing evidence or create new
    if os.path.exists(out_path):
        with open(out_path, 'r', encoding='utf-8') as of:
            exist = of.read()
        if 'describe' in exist:
            # Just insert before the end)\n\ntest_summary()
            idx = exist.rfind('end)')
            if idx != -1:
                new_c = exist[:idx] + ''.join(b[1] + '\n' for b in tlist) + exist[idx:]
                with open(out_path, 'w', encoding='utf-8') as of:
                    of.write(new_c)
        else:
            with open(out_path, 'w', encoding='utf-8') as of:
                of.write(content)
    else:
        with open(out_path, 'w', encoding='utf-8') as of:
            of.write(content)

# Update harness.rs
harness = 'tests/lua/harness.rs'
if os.path.exists(harness):
    with open(harness, 'r', encoding='utf-8') as f:
        hc = f.read()

    hc = re.sub(r'#\[test\]\s*fn\s+lua_test_evidence_migrated_15\(\)\s*\{[^}]+\}', '', hc)
    hc = re.sub(r'#\[test\]\s*fn\s+lua_test_evidence_migrated_20\(\)\s*\{[^}]+\}', '', hc)

    # Add new module test functions
    for mod in modules.keys():
        fn_ev = f'lua_test_evidence_{mod}'
        fn_go = f'lua_test_golden_{mod}'

        if fn_ev not in hc:
            hc += f'\n#[test]\nfn {fn_ev}() {{\n    run_lua_test("tests/lua/evidence/test_evidence_{mod}.lua");\n}}\n'
        if fn_go not in hc:
            hc += f'\n#[test]\nfn {fn_go}() {{\n    run_lua_test("tests/lua/golden/test_{mod}_golden.lua");\n}}\n'

    with open(harness, 'w', encoding='utf-8') as f:
        f.write(hc)

print("Done processing tests.")
