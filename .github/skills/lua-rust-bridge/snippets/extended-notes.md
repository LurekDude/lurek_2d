- The reason must follow the colon on the same line (cannot be blank).

**Acceptable uses:**
- The eval/run IS the feature (e.g., `debugbridge_api.rs`: the REPL eval endpoint exists specifically to execute arbitrary Lua code at developer request).
- Accessing the Lua `debug` library internals that have no Rust equivalent (e.g., `devtools_api.rs`: `debug.getinfo` stack introspection).

**Unacceptable uses:**
- Embedding game logic as Lua strings in a binding file — move it to a Lua library under `library/` or a domain helper.
- Avoiding a proper Rust implementation for convenience.

**Current justified uses in the codebase:**
| File | Location | Reason |
|------|----------|--------|
| `src/lua_api/debugbridge_api.rs` | `lurek.debug.eval` binding | Eval IS the feature — executes arbitrary code provided by the developer REPL |
| `src/lua_api/devtools_api.rs` | `debug.getinfo` introspection | Lua `debug` library has no Rust equivalent; needed for stack inspection |

### docs/specs ↔ lua_api Sync Contract
Every `docs/specs/<module>.md` has a `## Lua API Reference` section aligned with `src/lua_api/<module>_api.rs`.
Every `src/lua_api/<module>_api.rs` must stay aligned with the module spec:

| docs/specs | lua_api |
|------------|---------|
| Public Rust API in `## Key Types` | Should have a Lua wrapper if user-facing |
| `## Lua API Reference` section describes `lurek.<module>.*` | All listed functions must exist in the api file |
| `## Notes` on constraints | Enforced as `LuaError` at the binding boundary |

To check alignment: `python tools/docs/gen_lua_api_data.py`

### Adding a New API Module (Checklist)
1. Create `src/lua_api/<module>_api.rs` following the registration pattern
2. Register it in `src/lua_api/mod.rs` under the appropriate `modules.<flag>` guard
3. Add `/// @param` / `/// @return` docstrings to every public function
4. Update `docs/specs/<module>.md` — add or revise `## Lua API Reference` to list the new functions
5. Regenerate API docs: `python tools/docs/gen_lua_api_data.py`
6. Write Lua BDD test: `tests/lua/unit/test_<module>.lua`
7. Register the test in `tests/lua/harness.rs`
8. Run: `cargo test lua_test_<module>`

### Domain Module Checklist (before writing lua_api)
Before implementing the Lua bridge, verify the domain module provides:
- [ ] Typed resource key in `src/runtime/resource_keys.rs`
- [ ] Public API methods in `src/<module>/` (no business logic in lua_api)
- [ ] `SharedState` field holding the resource pool
- [ ] Clear ownership boundary (who allocates, who frees, who holds GPU resources)

### Rendering Boundary Rule
**Never render inside a Lua closure.** Lua callbacks must not call any GPU commands directly. Instead:

1. During `lurek.draw()`, push `RenderCommand` variants to `state.borrow_mut().draw_commands`
2. Return from the Lua callback
3. The engine processes draw commands after `lurek.draw()` returns and renders the frame

> See [../examples/rendering-boundary-rule.rs](../examples/rendering-boundary-rule.rs) for the example.

Any API that invokes GPU operations (wgpu render pass, texture upload, shader bind) must be called from the engine side, not from inside a `create_function` closure.
