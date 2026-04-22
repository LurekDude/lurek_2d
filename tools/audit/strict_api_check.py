"""Validate all lurek.* API stubs in content/examples/ against the master API data.

Reads docs/logs/lua_api_data.json and cross-references every registered function,
method, and property against its --@api: marker block in the corresponding example
file. Fails any stub that has fewer than 3 code lines, fewer than 2 comment lines,
contains forbidden placeholder words (todo, stub, executing, example), or does not
actually reference the API it claims to demonstrate.

Usage:
    python tools/audit/strict_api_check.py

Exit code:
    Always 0 (prints report to stdout). Use the failure count for gating.
"""
import json, re, sys
from pathlib import Path

ROOT = Path('.').resolve()
API_JSON = ROOT / 'docs' / 'logs' / 'lua_api_data.json'
EXAMPLES_DIR = ROOT / 'content' / 'examples'

try:
    data = json.loads(API_JSON.read_text(encoding='utf-8'))
except Exception as e:
    print(f"Error loading {API_JSON}: {e}")
    sys.exit(1)

mods = data.get('lua_api', {}).get('modules', {})

# Extract all expected APIs
expected_apis = []
NAMESPACE_MAP = {'filesystem': 'fs', 'render': 'graphic'}
for mod_name, mod_data in mods.items():
    ns = NAMESPACE_MAP.get(mod_name, mod_name)
    for fn in mod_data.get('functions', []):
        expected_apis.append({
            'id': f"lurek.{ns}.{fn['name']}",
            'name': fn['name'],
            'type': 'function',
            'file': f"{mod_name}.lua"
        })
    for cls_name, cls_data in mod_data.get('classes', {}).items():
        for meth in cls_data.get('methods', []):
            expected_apis.append({
                'id': f"{cls_name}:{meth['name']}",
                'name': meth['name'],
                'type': 'method',
                'file': f"{mod_name}.lua"
            })
        for prop in cls_data.get('properties', []):
            expected_apis.append({
                'id': f"{cls_name}.{prop['name']}",
                'name': prop['name'],
                'type': 'property',
                'file': f"{mod_name}.lua"
            })

# Read all example files
failures = []
for api in expected_apis:
    ex_file = EXAMPLES_DIR / api['file']
    if not ex_file.exists():
        continue

    text = ex_file.read_text(encoding='utf-8')

    # Simple strategy: find the marker block
    # Start looking from: --@api: ID or --@api-stub: ID
    pattern = rf"(?:--@api:|--@api-stub:)\s*{re.escape(api['id'])}\b(.*?)(?=\n--@api|\Z)"
    match = re.search(pattern, text, re.DOTALL)

    if not match:
        failures.append(f"{api['id']}: No marker found")
        continue

    block = match.group(1)

    lines = block.splitlines()
    code_lines = 0
    comment_lines = 0
    raw_code = []

    for ln in lines:
        s = ln.strip()
        if not s: continue
        if s.startswith('--'):
            comment_lines += 1
        else:
            code_lines += 1
            raw_code.append(s)

    code_str = "\n".join(raw_code)
    code_str_lower = code_str.lower()
    comment_str_lower = "\n".join(
        ln.strip() for ln in lines if ln.strip().startswith('--')
    ).lower()

    reasons = []
    if code_lines < 3:
        reasons.append(f"Only {code_lines} lines of code (min 3 required)")
    if comment_lines < 2:
        reasons.append(f"Only {comment_lines} valid comment lines (min 2 required)")

    forbidden = ["todo", "stub", "executing", "example"]
    for f in forbidden:
        if f in code_str_lower:
            reasons.append(f"Contains forbidden word in code: {f}")
        if f in comment_str_lower:
            reasons.append(f"Contains forbidden word in comments: {f}")

    # Check if the API name is actually called
    api_name = api['name']
    api_name_lower = api_name.lower()
    if not re.search(rf"\b{re.escape(api_name_lower)}\b", code_str_lower):
        # Relax rule slightly for properties (like .x, .y)
        if api['type'] == 'property':
            if f".{api_name_lower}" not in code_str_lower:
                reasons.append(f"Does not actually reference the property '{api_name}'")
        else:
            reasons.append(f"Does not actually call the API '{api_name}'")

    if reasons:
        failures.append(f"{api['id']}:\n  - " + "\n  - ".join(reasons))

print(f"Total APIs found: {len(expected_apis)}")
print(f"Failed APIs: {len(failures)}")
print("-" * 50)
for f in failures[:50]: # Print first 50 to not overwhelm
    print(f)
if len(failures) > 50:
    print(f"... and {len(failures) - 50} more")

