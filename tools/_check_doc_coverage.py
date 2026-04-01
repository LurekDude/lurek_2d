import re, pathlib

# Check overall coverage across all files
lua_api_dir = pathlib.Path('src/lua_api')
total_bindings = 0
total_undoc = 0

for f in sorted(lua_api_dir.glob('*.rs')):
    text = f.read_text(encoding='utf-8')
    lines = text.splitlines()
    bindings = 0
    undoc = []
    for i, line in enumerate(lines):
        stripped = line.strip()
        m = re.search(r'(?:add_method|add_function|add_method_mut)\s*\(\s*"([^"]+)"', stripped)
        if not m:
            m = re.search(r'\.set\s*\(\s*"([^"]+)"', stripped)
        if m:
            name = m.group(1)
            if name in ('__index', '__newindex', '__tostring', '__len', '__eq', '__lt', '__le', '__call', '__gc', 'type', 'is_a'):
                continue
            bindings += 1
            has_doc = False
            j = i - 1
            while j >= 0:
                s = lines[j].strip()
                if s.startswith('///'):
                    has_doc = True
                    break
                elif s == '' or s.startswith('#[') or s.startswith('//!') or (s.startswith('//') and not s.startswith('///')):
                    j -= 1
                    continue
                elif re.match(r'^let\s+\w+\s*=\s*\w+[\w.]*\(\s*\)\s*;$', s):
                    j -= 1
                    continue
                else:
                    break
            if not has_doc:
                undoc.append(name)
    total_bindings += bindings
    total_undoc += len(undoc)
    if undoc:
        pct = int(100 * (bindings - len(undoc)) / bindings) if bindings else 0
        print(f'{f.name}: {bindings - len(undoc)}/{bindings} documented ({pct}%) — {len(undoc)} gaps: {undoc[:4]}')

pct = int(100 * (total_bindings - total_undoc) / total_bindings) if total_bindings else 0
print(f'\nTotal: {total_bindings - total_undoc}/{total_bindings} documented ({pct}%)')
