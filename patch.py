import re

with open('tools/audit/audit_module.py', 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace('SRC / module / "docs/specs"', r'WORKSPACE / "docs" / "specs" / f"{module}.md"')

with open('tools/audit/audit_module.py', 'w', encoding='utf-8') as f:
    f.write(c)
