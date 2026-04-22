# tools/docs — Documentation Generators

Scripts that **read** the Lurek2D source tree and **write** documentation
output files under `docs/`, `logs/`, `docs/reports/`, and `docs/wiki/`.

Run the full pipeline in one command:
```powershell
python tools/gen_all_docs.py
```

## Scripts

### Data layer — machine-readable JSON from source

| Script | Reads | Produces | Key args |
|---|---|---|---|
| `gen_rust_api_data.py` | `src/**/*.rs` | `logs/rust_api_data.json` | `--output` |
| `gen_lua_api_data.py` | `src/lua_api/*.rs` | `logs/lua_api_data.json` | `--output`, `--verbose` |

### Reference generators — human-readable docs from JSON

| Script | Reads | Produces | Key args |
|---|---|---|---|
| `gen_docs_lua.py` | `lua_api_data.json` | `docs/lua-api.md` | — |
| `gen_docs_rust.py` | `rust_api_data.json` | `docs/reports/rust-api.md` | — |
| `gen_luadoc.py` | `lua_api_data.json` | `docs/lurek.lua` (LuaCATS IDE stubs) | — |
| `gen_wiki_api.py` | `lua_api_data.json` | `docs/wiki/API-Reference.md` | — |
| `gen_lib_docs.py` | `content/library/` | `docs/reports/lib-api.md` | — |
| `gen_engine_docs.py` | `src/` structure | `docs/reports/` engine docs | — |
| `gen_lua_dev_docs.py` | `lua_api_data.json` | `docs/reports/` developer docs | — |
| `gen_lua_library_api.py` | `content/library/` | LuaCATS stubs for Lunasome modules | — |
| `gen_test_docs.py` | `tests/` | `docs/reports/test_docs_rust.md`, `docs/reports/test_docs_lua.md` | `--mode rust\|lua`, `--output` |
| `gen_module_specs.py` | `src/<module>/` | `docs/specs/<module>.md` (merged module spec) | `--module NAME`, `--all`, `--scaffold`, `--write` |
| `gen_wiki.py` | `src/`, `content/`, `docs/specs/` | All `docs/wiki/*.md` pages | — |

### Legacy / standalone reference

| Script | Purpose | Key args |
|---|---|---|
| `gen_lua_api.py` | Original Lua API scanner (reads `@param`/`@return`) | `--check` (coverage check, exit 1 if stale) |
| `collect_docs.py` | Rich Rust API doc collector with missing-doc report | `--report-missing`, `--suggest`, `--json`, `--output` |

## Common usage

```powershell
# Full pipeline (all generators + coverage)
python tools/gen_all_docs.py

# Regenerate only the Lua API reference
python tools/docs/gen_lua_api.py

# Check Lua API coverage (exits 1 if stale)
python tools/docs/gen_lua_api.py --check

# Regenerate JSON intermediates
python tools/docs/gen_lua_api_data.py
python tools/docs/gen_rust_api_data.py

# List items missing /// docs
python tools/docs/collect_docs.py --report-missing
```
