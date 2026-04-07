# tools/fix — Code Fixers & Docstring Improvers

Scripts that **modify** source files to fix or improve code quality:
adding missing docstrings, repairing malformed comments, and updating
stale path references.

> **Caution**: These scripts modify files in-place. Always run with
> `--dry-run` first to preview changes.

## Scripts

| Script | Purpose |
|---|---|
| `add_lua_docstrings.py` | Add missing `///` Lua docstring stubs interactively |
| `add_lua_docstrings_auto.py` | Auto-generate `///` Lua docstubs non-interactively |
| `docstring_fix.py` | Apply docstring fixes from `docs/logs/docstring_audit.json` |
| `find_typed_params.py` | Find API params that already have explicit Lua types |
| `fix_docstrings.py` | Auto-fill missing `# Parameters`/`# Returns`/`# Fields`/`# Variants` sections |
| `fix_gpu_renderer.py` | One-off fix for corrupted `src/graphics/gpu_renderer.rs` |
| `improve_lua_docstrings.py` | Upgrade low-quality stub `///` comments with richer descriptions |
| `update_paths.py` | Bulk-rewrite `docs/API/*` path references to `docs/logs/*` |

## Common usage

```powershell
# Add docstring stubs to all lua_api files
python tools/fix/add_lua_docstrings_auto.py --dry-run
python tools/fix/add_lua_docstrings_auto.py

# Fix malformed docstrings from audit output
python tools/fix/docstring_fix.py --dry-run
python tools/fix/docstring_fix.py

# Auto-fill structured sections (# Parameters, # Returns …)
python tools/fix/fix_docstrings.py
```
