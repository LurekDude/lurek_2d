"""
Transform ui.lua: change ALL remaining dot-syntax widget method calls to colon-syntax.

Strategy: Convert any `varname.methodName(` to `varname:methodName(` where varname is NOT
a module/namespace (lurek, math, string, table, os, io, print, etc.)
"""
import re
import sys
from pathlib import Path

# Known module/namespace names that should keep dot syntax
MODULE_NAMES = {
    'lurek', 'math', 'string', 'table', 'os', 'io', 'debug', 'coroutine',
    'package', 'bit', 'ffi', 'jit',
}

def fix_ui_lua(filepath):
    content = Path(filepath).read_text(encoding='utf-8')
    lines = content.split('\n')
    changed = 0

    for i, line in enumerate(lines):
        stripped = line.lstrip()
        # Skip full-line comments
        if stripped.startswith('--'):
            continue

        new_line = line
        # Find all var.method( patterns
        # Negative lookbehind for . (to not match lurek.ui.method)
        # Pattern: NOT preceded by another dot, word, dot, word, dot...
        # Simple approach: find word.word( and check context

        for m in reversed(list(re.finditer(r'(\b\w+)\.(\w+)\(', new_line))):
            varname = m.group(1)
            method = m.group(2)

            # Skip module-level calls
            if varname in MODULE_NAMES:
                continue

            # Skip if preceded by a dot (like lurek.ui.method)
            start = m.start()
            if start > 0 and new_line[start-1] == '.':
                continue

            # Skip if it looks like a table constructor or field access pattern
            # like: some.constant (all lowercase, not a method call context)
            # Actually just convert everything that's not a module

            # Replace . with :
            new_line = new_line[:m.start()] + f'{varname}:{method}(' + new_line[m.end():]

        if new_line != line:
            lines[i] = new_line
            changed += 1

    Path(filepath).write_text('\n'.join(lines), encoding='utf-8')
    print(f"Fixed {changed} lines in {filepath}")


if __name__ == '__main__':
    filepath = sys.argv[1] if len(sys.argv) > 1 else 'content/examples/ui.lua'
    fix_ui_lua(filepath)
