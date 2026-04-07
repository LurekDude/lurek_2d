#!/usr/bin/env python3
"""
check_callbacks.py — Verify that gen_docs_lua.py _callbacks() output has no embedded newlines.

Dynamically imports gen_docs_lua.py and calls its internal _callbacks()
function, then scans every returned string for embedded \n or \r characters
that would corrupt the generated documentation.

Usage:
    python tools/validate/check_callbacks.py        # prints PASS or newline locations
"""
import importlib.util, sys
spec = importlib.util.spec_from_file_location('gen', 'tools/docs/gen_docs_lua.py')
gen = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gen)
result = gen._callbacks()
found = False
for i, item in enumerate(result):
    if '\n' in item or '\r' in item:
        print(f'item {i} HAS embedded newline: {repr(item[:100])}')
        found = True
if not found:
    print("No embedded newlines in callbacks output!")
print("Total items:", len(result))
