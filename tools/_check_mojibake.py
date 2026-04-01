"""
Check for mojibake (UTF-8 decoded as windows-1252) in lua_api docs.
The classic symptom: em dash â€" (U+2014) appears as the 3 bytes E2 80 94
which when decoded as cp1252 look like â€"
"""
import pathlib

lua_api_dir = pathlib.Path('src/lua_api')
mojibake_marker = '\u00e2\u20ac\u201c'  # â€" in cp1252 decode of U+2014 UTF-8 bytes

for f in sorted(lua_api_dir.glob('*.rs')):
    text = f.read_text(encoding='utf-8')
    count = text.count(mojibake_marker)
    if count:
        print(f'{f.name}: {count} mojibake instances')
