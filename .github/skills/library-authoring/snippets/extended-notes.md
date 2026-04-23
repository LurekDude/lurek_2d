| `@param name type description` | One per parameter |
| `@tparam type name description` | LDoc-classic alias accepted |
| `@treturn type description` / `@return type description` | Returns |
| `@field name type description` | For tables/records |
| `@within <Section>` | Grouping inside the page |
| `@raise <error string>` | Documented error path |
| `@usage` | Code block (use `--`-prefixed lines) |
| `@see lurek.<ns>.<fn>` or `@see library.<name>.<fn>` | Cross-link |

`@status` values are tightened; the generator rejects unknown values in `--check` mode.

### Lua Portability Rules

- **No bare `unpack(...)`** — write `local unpack = table.unpack or unpack` once at module top, then `unpack(t)`. Bare `unpack` breaks under the `lua54` Cargo feature.
- All locals declared at module top — no late `local` inside hot loops.
- No metatable surgery on tables returned from `lurek.*` — wrap them.
- Use `lurek.math.lerp/clamp/remap`, `lurek.serial.toJson/fromJson`, `lurek.data.deepCopy` etc. before reaching for a private helper. Mark TODOs that should be lifted to Rust with `-- TODO(lift): see work/library-overhaul-20260418/reports/P4_lift_candidates.md`.

### Doc Generator Workflow

    # Regenerate aggregate + per-library pages from init.lua sources
    python tools/docs/gen_lib_docs.py

    # CI / pre-commit gate: fail if any library has missing or mismatched docs
    python tools/docs/gen_lib_docs.py --check

Outputs:
- `docs/api/library.md` — single aggregate file mirroring `docs/api/lurek.md` style
- `docs/reports/libs/<name>.md` — one per library

Never hand-edit either output. Fix the docstring in `init.lua` and regenerate.

### Test Harness Entry

Every new `.lua` test file requires a manual entry in `tests/lua/harness.rs`:

    #[test] fn lua_test_library_<name>() { run_lua_file("library/test_library_<name>.lua"); }

Integration tests between a library and an engine namespace live in `tests/lua/integration/` with the naming convention `test_integration_<lib>_<engine_ns>.lua` and harness function `lua_test_integration_<lib>_<engine_ns>`. Both namespaces must appear in the file body.
