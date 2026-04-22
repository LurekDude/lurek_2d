---
name: lua-rust-bridge
description: "Load this skill when designing or implementing the bridge between Rust engine modules and the lurek.* Lua API: creating UserData types, registration functions, binding domain types to Lua, or keeping src/lua_api/ thin. Use for: new Lua API modules, Lua↔Rust data conversion, docs/specs↔lua_api sync. Skip it for domain Rust logic, game scripting, or GPU code."
---
# lua-rust-bridge

## Mission

# Lua↔Rust Bridge — Lurek2D

## When To Load

- Creating a new `lurek.*` API module (`.rs` file in `src/lua_api/`)
- Wrapping a Rust domain type as a Lua `UserData` object
- Designing Lua-callable functions for a new subsystem
- Syncing `docs/specs/<module>.md` ↔ `src/lua_api/<module>_api.rs`
- Converting data between Lua tables and Rust structs/enums
- Debugging `LuaError` messages or type mismatch panics at the Lua boundary

## When To Skip

- Skip it for domain Rust logic, game scripting, or GPU code.

## Domain Knowledge

### Owns
- `pub fn register(lua, luna_table, state)` contract and code pattern
- Rc clone pattern before moving state into closures
- `UserData` wrapping and `LunaType` trait
- Lua↔Rust data conversion patterns (`lua.to_value` / `lua.from_value`)
- Error conversion to `LuaError` at the bridge boundary
- docs/specs ↔ lua_api sync contract

### Bridge Architecture
> See [snippets/bridge-architecture.txt](snippets/bridge-architecture.txt) for the example.

**Rule**: `lua_api/` is a translation layer only. Business logic stays in domain modules. If `lua_api/*.rs` contains more than ~10 lines of logic per function, move that logic to the domain module.

### Thin Wrapper Enforcement (TST-03)

Binding constraint **TST-03** (see [philosophy.md § Testing Constraints](../../../docs/architecture/philosophy.md#testing-constraints)) makes the thin-wrapper rule load-bearing and auditable:

- `src/lua_api/<module>_api.rs` contains ONLY `impl LuaUserData` blocks, `pub fn register(...)`, helper `Lua<X>` wrapper structs, and `Lua <-> Rust` type conversions. Business logic (math, state machines, algorithms, multi-step ops) MUST live in `src/<module>/` as pure Rust; each binding closure is validate -> delegate -> convert.
- Tests target the extracted Rust (`tests/rust/unit/<module>_tests.rs`) or the public API in Lua (`tests/lua/`, per **TST-01**); they never target `src/lua_api/` directly.
- Enforcement: `Reviewer`, `tools/validate/validate_lua_api.py` (closures > ~10 lines of logic = ERROR), plus the `thin_wrapper_audit.py` script scheduled to land in `tools/audit/` during session `testing-cleanup-20260420` P3.

### Registration Contract
Every API module MUST follow this exact pattern (gold standard: `src/lua_api/timer_api.rs`):

> See [examples/registration-contract.rs](examples/registration-contract.rs) for the example.

**Critical rules:**
- Flat body (`let s = ...; tbl.set(...)`) — NOT wrapped in `{ }` block expressions
- Clone the `Rc` BEFORE moving into the closure: `let s = state.clone();`
- Section separators: `// ── SectionName ──────────────────────`
- Docstrings use ONLY `/// @param` and `/// @return` — never `# Parameters` / `# Returns`

### UserData Pattern
**All `impl LuaUserData` blocks belong in `src/lua_api/<module>_api.rs` — never in domain modules.**

Wrapper structs (`Lua<X>`) and their `impl LuaUserData` live together in the api file, not in `src/<module>/`:

> See [examples/userdata-pattern.rs](examples/userdata-pattern.rs) for the example.

**WRONG — never put `impl LuaUserData` in a domain module:**
> See [examples/userdata-pattern-2.rs](examples/userdata-pattern-2.rs) for the example.

- UserData holds only: typed resource key + cached read-only metadata
- GPU resources live in `SharedState`; never store `wgpu` objects in UserData
- Implement `LunaType` trait for consistent `type()`, `typeOf()`, `__tostring` across all types
- The audit tool (B-03) will flag any `impl LuaUserData` found in `src/<module>/` files as ERROR

### Lua↔Rust Data Conversion
| Direction | Pattern |
|-----------|---------|
| Lua → Rust struct | `lua.from_value::<MyStruct>(val)?` (requires `serde::Deserialize`) |
| Rust struct → Lua | `lua.to_value(&my_struct)?` (requires `serde::Serialize`) |
| Lua table → manual | `tbl.get::<String>("key")?` — only for small, known-shape tables |
| Rust Vec → Lua table | `lua.create_sequence_from(vec.iter())?` |
| Optional Lua arg | `Option<T>` in the function signature; `None` = Lua nil |

**Rule**: Prefer `lua.to_value()` / `lua.from_value()` over manual field iteration. Reserve manual iteration for small, stable table shapes.

### Error Handling at the Boundary
> See [examples/error-handling-at-the-boundary.rs](examples/error-handling-at-the-boundary.rs) for the example.

- Always use `?` throughout internal code
- Convert to `LuaError` only at the Lua boundary with `.map_err(LuaError::external)`
- Never panic on bad Lua input — always return a descriptive `LuaError`
- Strip internal Rust source paths from error messages shown to Lua

### Forbidden Patterns in lua_api Files
`lua.load()` (and `lua.eval()`) are **forbidden** in `src/lua_api/*.rs` except for the narrow cases below. The validator (`tools/validate/validate_lua_api.py`) will fail on any unannoted `lua.load()` call found in a binding file.

### Known Exceptions: LUA-EVAL-JUSTIFIED

When a `lua.load()` call is genuinely unavoidable, suppress the validator with a comment placed **immediately before** the offending line:

> See [examples/known-exceptions-lua-eval-justified.rs](examples/known-exceptions-lua-eval-justified.rs) for the example.

**Placement rules:**

> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [snippets/bridge-architecture.txt](snippets/bridge-architecture.txt) — Bridge Architecture
- [examples/registration-contract.rs](examples/registration-contract.rs) — Registration Contract
- [examples/userdata-pattern.rs](examples/userdata-pattern.rs) — UserData Pattern
- [examples/userdata-pattern-2.rs](examples/userdata-pattern-2.rs) — UserData Pattern
- [examples/error-handling-at-the-boundary.rs](examples/error-handling-at-the-boundary.rs) — Error Handling at the Boundary
- [examples/known-exceptions-lua-eval-justified.rs](examples/known-exceptions-lua-eval-justified.rs) — Known Exceptions: LUA-EVAL-JUSTIFIED
- [examples/rendering-boundary-rule.rs](examples/rendering-boundary-rule.rs) — Rendering Boundary Rule
- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- See related skills in `.github/skills/`.
- [tools/docs/gen_lua_api_skeleton.py](../../../tools/docs/gen_lua_api_skeleton.py) — scaffold a new `src/lua_api/<module>_api.rs` skeleton.
- [tools/docs/gen_rust_api_data.py](../../../tools/docs/gen_rust_api_data.py) — produce `logs/rust_api_data.json` consumed by the Lua API doc generator.
