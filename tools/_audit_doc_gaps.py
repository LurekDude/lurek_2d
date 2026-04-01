"""Audit undocumented method/function bindings in src/lua_api/*.rs"""
import re, pathlib

lua_api_dir = pathlib.Path('src/lua_api')
for f in sorted(lua_api_dir.glob('*.rs')):
    text = f.read_text(encoding='utf-8')
    lines = text.splitlines()
    undoc = []
    for i, line in enumerate(lines):
        stripped = line.strip()
        m = re.search(r'(?:add_method|add_function|add_method_mut)\s*\(\s*"([^"]+)"', stripped)
        if not m:
            m = re.search(r'\.set\s*\(\s*"([^"]+)"', stripped)
        if m:
            name = m.group(1)
            has_doc = False
            j = i - 1
            while j >= 0:
                prev = lines[j].strip()
                if prev.startswith('///'):
                    has_doc = True
                    break
                elif prev == '' or prev.startswith('#[') or re.match(r'^let\s+\w+\s*=\s*\w+\.clone\(\)', prev) or prev.startswith('//'):
                    pass
                else:
                    break
                j -= 1
            if not has_doc:
                undoc.append(name)
    if undoc:
        print(f'{f.name}: {len(undoc)} undocumented  (sample: {undoc[:4]})')
