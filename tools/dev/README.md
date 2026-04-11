# tools/scripts/

Session scripts and agent automation utilities for Lurek2D development workflows.

These scripts are NOT permanent tools (which live in `tools/audit/`, etc.) — they are
workflow helpers intended to be used interactively by developers and AI agents.

## Scripts

| Script | Purpose |
|--------|---------|
| `test_fix_loop.py` | Run tests → parse failures → show top errors → iterate until clean |

## Usage

```powershell
# Run all Lua tests and summarize failures
python tools/scripts/test_fix_loop.py --test lua_tests

# Run with explicit thread count
python tools/scripts/test_fix_loop.py --test lua_tests --threads 8

# Filter to one category
python tools/scripts/test_fix_loop.py --test lua_tests --filter library

# Run once and exit (no loop)
python tools/scripts/test_fix_loop.py --test lua_tests --once
```
