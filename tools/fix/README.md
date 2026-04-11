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
| `docstring_fix.py` | Apply docstring fixes from `docs/logs/docstring_audit.json` | `--dry-run` |
| `fix_docstrings.py` | Auto-fill missing `# Parameters`/`# Returns`/`# Fields`/`# Variants` | — |
| `improve_lua_docstrings.py` | Upgrade low-quality stub `///` comments with richer descriptions | `--dry-run` |

### Source code fixers — automated source transformations

| Script | Purpose | Key args |
|---|---|---|
| `fix_gpu_renderer.py` | One-off fix for corrupted `gpu_renderer.rs` UTF-8 encoding | — |
| `fix_type_stub_vars.py` | Fix type stub variable declarations | — |
| `fix_typeof_args.py` | Fix typeof() argument patterns | — |
| `strip_instance_method_comments.py` | Strip stale instance method doc comments | `--dry-run` |
| `update_paths.py` | Bulk-rewrite `docs/API/*` path references to `docs/logs/*` | `--dry-run` |

### Example/content fixers — modify content/ files

| Script | Purpose | Key args |
|---|---|---|
| `expand_examples.py` | Expand `content/examples/` scripts with richer API usage | `--dry-run` |
| `format_examples.py` | Format `content/examples/` scripts to coding standard | — |
| `improve_examples.py` | Improve example quality with richer comments and edge cases | `--dry-run` |
| `uncomment_examples.py` | Uncomment disabled code sections in examples | — |

### Test helpers

| Script | Purpose | Key args |
|---|---|---|
| `add_test_markers.py` | Add `@covers` annotation markers to Lua test files | — |
| `find_typed_params.py` | Find API params that already have explicit Lua types | — |

## Common usage

```powershell
# --- Docstrings ---
python tools/fix/add_lua_docstrings_auto.py --dry-run  # preview
python tools/fix/add_lua_docstrings_auto.py             # apply

python tools/fix/docstring_fix.py --dry-run              # preview audit fixes
python tools/fix/docstring_fix.py                        # apply

python tools/fix/fix_docstrings.py                       # auto-fill sections

# --- Source fixers ---
python tools/fix/update_paths.py --dry-run               # preview path updates
python tools/fix/update_paths.py                         # apply

# --- Examples ---
python tools/fix/format_examples.py                      # format all examples
python tools/fix/expand_examples.py --dry-run            # preview example expansion
```
