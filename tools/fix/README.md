# tools/fix — Code Fixers & Docstring Improvers

Scripts that **modify** source files to fix or improve code quality:
adding missing docstrings, repairing malformed comments, and updating
stale path references.

> **Caution**: These scripts modify files in-place. Always run with
> `--dry-run` first (where supported) to preview changes.

## Scripts

### Docstring fixers — add or repair `///` doc comments

| Script | Purpose | Key args |
|---|---|---|
| `add_lua_docstrings.py` | Add missing `///` Lua docstring stubs interactively | `--dry-run`, file path |
| `add_lua_docstrings_auto.py` | Auto-generate `///` Lua docstring stubs non-interactively | `--dry-run` |
| `docstring_fix.py` | Apply docstring fixes from `logs/data/docstring_audit.json` | `--dry-run` |
| `fix_docstrings.py` | Auto-fill missing `# Parameters`/`# Returns`/`# Fields`/`# Variants` | — |
| `improve_lua_docstrings.py` | Upgrade low-quality stub `///` comments with richer descriptions | `--dry-run` |

### Example/content fixers — modify content/ files

| Script | Purpose | Key args |
|---|---|---|
| `expand_examples.py` | Expand `content/examples/` scripts with richer API usage | `--dry-run` |
| `format_examples.py` | Format `content/examples/` scripts to coding standard | — |
| `improve_examples.py` | Improve example quality with richer comments and edge cases | `--dry-run` |

### Test helpers

| Script | Purpose | Key args |
|---|---|---|
| `add_test_markers.py` | Add `@covers` annotation markers to Lua test files | — |

## Common usage

```powershell
# --- Docstrings ---
python tools/fix/add_lua_docstrings_auto.py --dry-run  # preview
python tools/fix/add_lua_docstrings_auto.py             # apply

python tools/fix/docstring_fix.py --dry-run              # preview audit fixes
python tools/fix/docstring_fix.py                        # apply

python tools/fix/fix_docstrings.py                       # auto-fill sections

# --- Examples ---
python tools/fix/format_examples.py                      # format all examples
python tools/fix/expand_examples.py --dry-run            # preview example expansion
```
