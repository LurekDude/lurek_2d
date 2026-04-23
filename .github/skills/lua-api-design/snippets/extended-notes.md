> See [3-section-separators.txt](3-section-separators.txt) for the example.

Standard labels: `LuaFoo UserData`, `Register`.

### 4. UserData Struct

> See [../examples/4-userdata-struct.rs](../examples/4-userdata-struct.rs) for the example.

### 5. `impl LuaUserData` Block

> See [../examples/5-impl-luauserdata-block.rs](../examples/5-impl-luauserdata-block.rs) for the example.

#### `add_method` vs `add_method_mut`

| Use | When |
|---|---|
| `add_method` | `this: &Self` — read-only access to the wrapper |
| `add_method_mut` | `this: &mut Self` — must mutate the wrapper itself (e.g. cached state, stored key) |
| `add_function` | No `self` at all — static/factory/constructor functions |

**Rule**: prefer `add_method` unless mutation of the wrapper struct is strictly required. Mutation of the underlying domain value through `RefCell` still uses `add_method`.

#### Callback storage pattern (LuaRegistryKey)

When a method accepts a Lua function to call later, store it in the registry:

> See [../examples/callback-storage-pattern-luaregistrykey.rs](../examples/callback-storage-pattern-luaregistrykey.rs) for the example.

To call the callback later (single domain call per closure — call a domain method that accepts a `LuaFunction`):

> See [../examples/callback-storage-pattern-luaregistrykey-2.rs](../examples/callback-storage-pattern-luaregistrykey-2.rs) for the example.

**Exception to the one-domain-call rule**: An `if let Some(key) = &this.callback_key` guard
around a single domain call is acceptable — the guard is infrastructure, not business logic.
This is the **only** accepted multi-statement pattern in a closure body.

Clean up: `lua.remove_registry_value(key)?` in a `cancel`/`destroy` method.

#### Method section header (8-space indent)

> See [../examples/method-section-header-8-space-indent.rs](../examples/method-section-header-8-space-indent.rs) for the example.

#### Docstring

> See [../examples/docstring.rs](../examples/docstring.rs) for the example.

- `@param` before `@return`. Always.
- No blank line between last docstring line and `methods.add_method(`.
- Docstring above the call site, never inside the closure.
- Multi-line form: docstring is ABOVE `methods.add_method(`:

> See [../examples/docstring-2.rs](../examples/docstring-2.rs) for the example.

### 6. Register Section

> See [../examples/6-register-section.rs](../examples/6-register-section.rs) for the example.

- Signature is FIXED: `(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()>`
- Table variable is ALWAYS named `tbl`.
- Last two lines: `lurek.set("<module>", tbl)?;` then `Ok(())`.

### 7. Function Entry Pattern (4-space indent in register)

Standard pattern with state:

> See [../examples/7-function-entry-pattern-4-space.rs](../examples/7-function-entry-pattern-4-space.rs) for the example.

- `let s = state.clone();` comes AFTER docstring, BEFORE `tbl.set(`.
- Section header at 4-space indent.

---

### Docstring Contract
### @param syntax

> See [../examples/param-syntax.rs](../examples/param-syntax.rs) for the example.

### @return syntax

> See [../examples/return-syntax.rs](../examples/return-syntax.rs) for the example.

- `nil` for functions that return nothing.
- Must be the last docstring line before the code.

### Lua type names

| Rust type | Write as |
|---|---|
| `bool` | `boolean` |
| `f64` / `f32` | `number` |
| `i32` / `i64` / `usize` | `integer` |
| `String` | `string` |
| `Option<T>` | `type?` e.g. `string?` |
| Lua table | `table` |
| `LuaFunction` | `function` |
| UserData wrapper | the wrapper name e.g. `Agent`, `Body` |
| No return value | `nil` |

### Forbidden

| Forbidden | Replacement |
|---|---|
| `/// # Parameters` | `/// @param name : type` |
| `/// # Returns` | `/// @return type` |
| `/// @return any` | Specific type |

---

### The Thin Wrapper Rule
A lua_api file is a **BRIDGE ONLY**. Every closure body contains exactly **one domain call**.

### Allowed

- `Ok(s.borrow().field)` — state read
- `s.borrow_mut().set_field(arg); Ok(())` — state write
- `Ok(this.inner.method(arg))` — domain call
- `.map_err(LuaError::external)?` — non-Lua error conversion at boundary
- `lua.create_userdata(LuaFoo { inner })` — UserData construction (wrapping a domain value)
- `lua.create_registry_value(func)?` — Lua callback storage
- `count.unwrap_or(-1)` — trivial Option default
- `if let Some(key) = &this.callback_key { … }` — guard for stored registry key (see callback pattern above)

### Forbidden in closures

| Pattern | Where it belongs |
|---|---|
| `lua.load(r#"..."#)` | Domain module or eliminated entirely |
| Serialization / deserialization loops | Domain file |
| Struct construction with 3+ fields | Domain file — add a named constructor |
| Iteration to build output (Vec, HashMap) | Domain file |
| Business logic conditionals | Domain file |
| `std::thread::sleep(...)` | Domain file — add `timer::sleep(secs)` fn |
| Capturing mutable state in closures | Domain file — put state in domain struct |
| `HashSet`, `HashMap` construction | Domain file |

### Business Logic Migration Pattern

When you find business logic in a closure, move it to the domain like this:

**Before (anti-pattern):**
> See [../examples/business-logic-migration-pattern.rs](../examples/business-logic-migration-pattern.rs) for the example.

**After (correct):**
> See [../examples/business-logic-migration-pattern-2.rs](../examples/business-logic-migration-pattern-2.rs) for the example.

Add `pub fn tick(&mut self, dt: f32)` to the `Clock` struct in `src/timer/clock.rs`.

If the domain module lacks a needed method, **add `pub fn` to domain first, then call it**.

---

### Naming Convention
| Rust `snake_case` | Lua `camelCase` |
|---|---|
| `new_image` | `"newImage"` |
| `get_width` | `"getWidth"` |
| `set_volume` | `"setVolume"` |
| `is_down` | `"isDown"` |

---

### Validation
> See [validation.ps1](validation.ps1) for the example.

Exit code `0` = pass. Exit code `1` = errors.

**Validator limitation**: For multi-line `methods.add_method(` calls where the method name is on a separate line, the validator CANNOT detect missing docstrings. Manually verify docstrings above every multi-line `methods.add_method(` call.

---

### Anti-Patterns the Validator Catches
| Anti-pattern | Rule |
|---|---|
| `{ let s = state.clone(); tbl.set(...); }` | Block-wrapped pattern |
| `lua.load(r#"..."#)` | Embedded Lua code |
| `/// # Parameters` | Use `@param` |
| `/// # Returns` | Use `@return` |
| `/// @return any` | Too vague — use specific type |
| Missing `/// @return` above single-line `tbl.set(` | Undocumented function |
| No `//!` header | Missing module doc |
| No `lurek.set("module", tbl)` | Module not registered |

### Anti-Patterns the Validator Does NOT Catch (verify manually)
| Anti-pattern | How to spot it |
|---|---|
| `impl mlua::UserData` instead of `impl LuaUserData` | grep for `mlua::UserData` |
| `add_method_mut` where `add_method` suffices | wrapper struct is not actually mutated |
| Multi-line `methods.add_method(…` missing docstring | method name on a separate line fools the validator |
| Loop / conditional logic inside closure body | more than one statement before `Ok(…)` |
| Comments above docstrings (`// Do X` then `/// …`) | plain comment immediately above `///` — remove the comment |
| `/// @return any` slipped in on a multi-line call | validator misses it when method name on separate line |
| Lua callback stored without `LuaRegistryKey` | look for `let func: LuaFunction` without `create_registry_value` |
