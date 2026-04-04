# Luna2D Lua API Documentation Automation

## Overview

The Luna2D Lua API reference is **automatically generated** from docstrings in the engine source code. This ensures documentation never drifts from the actual API.

### Files Involved

| File | Role |
|------|------|
| `src/lua_api/*.rs` | **Source of truth** — Contains `#[allow(unused_doc_comments)] /// docstrings` for every Lua function |
| `tools/add_lua_docstrings.py` | Adds structured docstrings to API files (run once during setup) |
| `tools/gen_lua_api.py` | Generates `docs/lua_api_reference_generated.md` from docstrings |
| `docs/lua_api_reference_generated.md` | **Auto-generated** — Read-only; regenerated every time docstrings change |

## Workflow

### Daily Development

When you add or modify a Lua API function in `src/lua_api/graphics_api.rs`:

1. **Add the docstring** above the `graphics.set("functionName", ...)` call:
```rust
#[allow(unused_doc_comments)]
/// Sets the drawing color for all subsequent draw calls.
/// 
/// Lua API: luna.graphics.setColor(r, g, b [, a])
// luna.graphics.setColor(r, g, b, a?)
graphics.set("setColor", lua.create_function(...
```

2. **Regenerate the API reference:**
```bash
python tools/gen_lua_api.py
```

3. **Commit both files:**
```bash
git add src/lua_api/graphics_api.rs docs/lua_api_reference_generated.md
git commit -m "feat(graphics): add setColor function"
```

### Checking Coverage

To verify all Lua functions have docstrings:
```bash
python tools/gen_lua_api.py --check
```

Exit code 0 = all documented; exit code 1 = missing docstrings.

### Custom Output Path

To generate to a specific file:
```bash
python tools/gen_lua_api.py --output docs/api_reference.md
```

## Initial Setup (One-Time)

These scripts were already run during repository setup:

1. `tools/add_lua_docstrings.py` — Converted inline `// luna.module.function(...)` comments to `/// docstrings`
2. `tools/gen_lua_api.py` — Generated the first `docs/lua_api_reference_generated.md`

## Implementation Details

### Docstring Format

```rust
#[allow(unused_doc_comments)]
/// Brief description of what the function does.
/// 
/// Additional details if needed.
///
/// Lua API: luna.module.functionName(param1, param2 [, optional])
```

**Why `#[allow(unused_doc_comments)]`?**
- Doc comments on non-item code (comments before closures) would generate compiler warnings
- This attribute safely suppresses the warning while the docstring is parsed by the script

### Parser Logic (`gen_lua_api.py`)

1. Scans all `src/lua_api/*.rs` files
2. Finds lines matching `// luna.module.function(signature)`
3. Looks backward for preceding `/// docstrings`
4. Extracts: module, function name, signature, description
5. Groups functions by module (graphics, physics, audio, etc.)
6. Generates Markdown with header structure

### Generated File Structure

```markdown
# Luna2D Lua API Reference

## Callbacks

- luna.load() — ...
- luna.update(dt) — ...
- luna.draw() — ...

## luna.graphics

### `luna.graphics.setColor(r, g, b [, a])`

Sets the drawing color...
Lua API: luna.graphics.setColor(r, g, b, a?)

### `luna.graphics.rectangle(mode, x, y, width, height [, rx, ry])`

...

## luna.physics

...
```

## Docstring Best Practices

✅ **Do:**
- Write concise, user-focused descriptions
- Include parameter hints in the description or Lua API line
- Use `[...]` for optional parameters in the Lua API line
- Keep descriptions to 1–2 sentences

❌ **Don't:**
- Document Rust type details (users see Lua, not Rust)
- Write implementation comments; those go in the code
- Include `#[doc(...)]` attributes; use `///` only
- Forget the `#[allow(unused_doc_comments)]` attribute

## Validation & CI

Future: Add to pre-commit hook or CI pipeline:
```bash
python tools/gen_lua_api.py --check && cargo build
```

This ensures:
1. All Lua functions are documented
2. Documentation stays in sync with code
3. No drift between docs and implementation
