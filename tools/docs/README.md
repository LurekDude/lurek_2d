# tools/docs â€” Documentation Generators

Scripts that **read** the Lurek2D source tree and **write** documentation
output files under `docs/`, `logs/`, `docs/reports/`, and `wiki/`.

Run the full pipeline in one command:
```powershell
python tools/gen_all_docs.py
```

## Scripts

### Data layer â€” machine-readable JSON from source

| Script | Reads | Produces | Key args |
|---|---|---|---|
| `gen_rust_api_data.py` | `src/**/*.rs` | `logs/data/rust_api_data.json` | `--output` |
| `gen_lua_api_data.py` | `src/lua_api/*.rs` | `logs/data/lua_api_data.json` | `--output`, `--verbose` |

### Reference generators â€” human-readable docs from JSON

| Script | Reads | Produces | Key args |
|---|---|---|---|
| `gen_docs_lua.py` | `lua_api_data.json` | `docs/api/lurek.md` | â€” |
| `gen_docs_rust.py` | `rust_api_data.json` | `docs/api/rust.md` | â€” |
| `gen_luadoc.py` | `lua_api_data.json` | `docs/lurek.lua` (LuaCATS IDE stubs) | â€” |
| `gen_wiki_api.py` | `lua_api_data.json` | `wiki/API-Reference.md` | â€” |
| `gen_lib_docs.py` | `library/` | `docs/reports/lib-api.md` | â€” |
| `gen_engine_docs.py` | `src/` structure | `docs/reports/` engine docs | â€” |
| `gen_lua_dev_docs.py` | `lua_api_data.json` | `docs/reports/` developer docs | â€” |
| `gen_lua_library_api.py` | `library/` | LuaCATS stubs for Lunasome modules | â€” |
| `gen_test_docs.py` | `tests/` | `docs/reports/test_docs_rust.md`, `docs/reports/test_docs_lua.md` | `--mode rust\|lua`, `--output` |
| `gen_module_specs.py` | `src/<module>/` | `docs/specs/<module>.md` (merged module spec) | `--module NAME`, `--all`, `--scaffold`, `--write` |
| `gen_wiki.py` | `src/`, `content/`, `docs/specs/` | All `wiki/*.md` pages | â€” |

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

