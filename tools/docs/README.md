# tools/docs — Documentation Generators

Scripts that **read** the Luna2D source tree and **write** documentation
output files under `docs/API/`, `docs/logs/`, and `wiki/`.

Run the full pipeline in one command:
```powershell
python tools/gen_all_docs.py
```

## Scripts

| Script | Purpose | Output |
|---|---|---|
| `collect_docs.py` | Scan `src/` and generate rich API doc with missing-doc report | `docs/API/api_generated.md` |
| `gen_docs_lua.py` | Compact Lua API reference from `lua_api_data.json` | `docs/API/lua-api.md` |
| `gen_docs_rust.py` | Compact Rust API reference from `rust_api_data.json` | `docs/API/rust-api.md` |
| `gen_engine_docs.py` | Engine internals documentation | `docs/API/` |
| `gen_lib_docs.py` | Library Lua (`library/`) API docs | `docs/API/lib-api.md` |
| `gen_lua_api.py` | Lua API reference scanner — reads `@param`/`@return` tags from `src/lua_api/` | `docs/API/lua_api_reference_generated.md` |
| `gen_lua_api_data.py` | Machine-readable Lua API JSON | `docs/API/lua_api_data.json` |
| `gen_lua_api_skeleton.py` | Generate `src/lua_api/*_api.rs` skeleton stubs from Rust module docstrings | `src/lua_api/*.rs` |
| `gen_lua_dev_docs.py` | Lua developer-facing documentation | `docs/API/` |
| `gen_lua_library_api.py` | Library Lua type annotation extraction | `docs/API/` |
| `gen_luadoc.py` | LuaCATS type-annotation stubs for VS Code IntelliSense | `docs/API/luna.lua` |
| `gen_rust_api_data.py` | Machine-readable Rust API JSON | `docs/API/rust_api_data.json` |
| `gen_test_docs.py` | Human-readable test catalog from Rust/Lua test files | `docs/API/test_docs.md` |
| `gen_wiki_api.py` | Game-developer API cheatsheet | `wiki/API-Reference.md` |

## Common usage

```powershell
# Regenerate only the Lua API reference
python tools/docs/gen_lua_api.py

# Check Lua API coverage (exits 1 if stale)
python tools/docs/gen_lua_api.py --check

# Regenerate Lua + Rust JSON intermediates
python tools/docs/gen_lua_api_data.py
python tools/docs/gen_rust_api_data.py

# Generate a new lua_api skeleton for a module
python tools/docs/gen_lua_api_skeleton.py --module physics
```
