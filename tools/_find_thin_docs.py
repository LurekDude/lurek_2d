"""Find methods with the shortest docstring summary lines (the 1-2 word docs)."""
import re, pathlib

lua_api_dir = pathlib.Path('src/lua_api')
short_docs = []

for f in sorted(lua_api_dir.glob('*.rs')):
    text = f.read_text(encoding='utf-8')
    lines = text.splitlines()
    for i, line in enumerate(lines):
        stripped = line.strip()
        m = re.search(r'(?:add_method|add_function|add_method_mut)\s*\(\s*"([^"]+)"', stripped)
        if not m:
            m = re.search(r'\.set\s*\(\s*"([^"]+)"', stripped)
        if not m:
            continue
        lua_name = m.group(1)
        if lua_name in ('__index', '__newindex', '__tostring', '__len', '__eq', '__lt', '__le', '__call'):
            continue
        # Find the summary line (first non-empty /// line above)
        j = i - 1
        summary = None
        while j >= 0:
            s = lines[j].strip()
            if s.startswith('///'):
                content = s[3:].strip()
                if content and not content.startswith('#') and not content.startswith('- '):
                    summary = content
                    break
            elif s == '' or s.startswith('#[') or (s.startswith('//') and not s.startswith('///')):
                j -= 1
                continue
            else:
                break
            j -= 1
        if summary:
            word_count = len(summary.split())
            if word_count <= 5:
                short_docs.append((word_count, f.name, lua_name, summary))

short_docs.sort()
print(f"Methods with <= 5 word descriptions: {len(short_docs)}")
for wc, fname, name, summary in short_docs[:40]:
    print(f"  [{wc}w] {fname}: {name}() — {summary}")
