#!/usr/bin/env python3
"""
update_paths.py — Bulk-update docs/API/* path references to docs/logs/* across the codebase.

Rewrites hardcoded file paths in tools/, .vscode/, .github/, and docs/ that
reference doc_coverage.json, docstring_audit.json, and test_coverage.json
under docs/API/ to point to docs/logs/ instead.  Also moves any existing
files from docs/API/ to docs/logs/ if present.

Usage:
    python tools/fix/update_paths.py                # rewrites paths in-place
"""
import os

targets = [
    'doc_coverage.json',
    'docstring_audit.json',
    'test_coverage.json'
]

files_to_check = [
    'tools/docstring_audit.py',
    'tools/docstring_fix.py',
    'tools/doc_coverage.py',
    'tools/gen_all_docs.py',
    'tools/gen_test_docs.py',
    'tools/test_coverage.py',
    '.vscode/tasks.json',
    '.github/copilot-instructions.md',
    '.github/skills/testing-rust/SKILL.md',
    'docs/architecture/test-framework.md',
    '.github/instructions/tests.instructions.md'
]

for file_path in files_to_check:
    if not os.path.exists(file_path):
        continue
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    for target in targets:
        content = content.replace(f'docs/API/{target}', f'docs/logs/{target}')
        content = content.replace(f'docs/API\\\\{target}', f'docs/logs\\\\{target}')
        content = content.replace(f'"docs" / "API" / "{target}"', f'"docs" / "logs" / "{target}"')

    if content != original:
        with open(file_path, 'w', encoding='utf-8', newline='') as f:
            f.write(content)
        print(f'Updated {file_path}')

# Let's ensure docs/logs exists
os.makedirs('docs/logs', exist_ok=True)

# Also let's rename existing files if they exist
for target in targets:
    src = f'docs/API/{target}'
    dst = f'docs/logs/{target}'
    if os.path.exists(src):
        os.rename(src, dst)
        print(f'Moved {src} to {dst}')
