2. Test: `cargo run -- content/examples/<module>.lua`
3. Link in `content/examples/README.md`
4. If the example demonstrates a newly added API function, update `logs/data/lua_api_data.json`

**Full demo** (game directory):
1. Create `content/games/<name>/` with `main.lua` (+ optional `conf.toml`, assets, README)
2. Test: `cargo run -- content/games/<name>`
3. Link in `content/games/README.md`
4. Verify the demo runs to completion with no errors and no stale `print` debug output

### Examples and API Documentation
The tools pipeline uses examples to validate the API surface:

> See [examples-and-api-documentation.ps1](examples-and-api-documentation.ps1) for the example.

When an `content/examples/` file uses an API function that lacks an `/// @param`/`/// @return` docstring, `tools/docs/gen_lua_api.py --check` will report it. Fix the docstring, not the example.

### Smoke Testing
Examples can be run as smoke tests to verify engine functionality:

> See [smoke-testing.ps1](smoke-testing.ps1) for the example.

If an example supports a `--smoke` flag, it calls `lurek.quit()` after one frame to allow automated verification.

Add smoke test support to a new example:

> See [../examples/smoke-testing-2.lua](../examples/smoke-testing-2.lua) for the example.

### Examples README
`content/examples/README.md` and `content/games/README.md` must stay alphabetically sorted and must link to each file/folder with a one-line description.

Format:
> See [examples-readme.md](examples-readme.md) for the example.

Update both README files whenever a new example or demo is added.

### Anti-Patterns
- **Assets in content/examples/**: Resources that require manual download or aren't embedded — examples must be self-contained
- **Stale demos**: Demos that use removed API functions (`lurek.old.func`) — run demos on every release to catch breakage
- **Debug-print noise**: `print("test")` or `print(val)` left in committed examples
- **Missing README entry**: Adding an example without updating `content/examples/README.md`

### Lua API Compliance
These rules apply to all files in `content/examples/` and `content/games/`:

### Input Key Names

Key names must match the engine canonical map exactly — always lowercase, never platform names:

> See [../examples/input-key-names.lua](../examples/input-key-names.lua) for the example.

Canonical set: `"space"`, `"escape"`, `"up"`, `"down"`, `"left"`, `"right"`, single letter keys `"a"`–`"z"`, `"return"`, `"tab"`, `"backspace"`.

### Color Values

Color component values must be in `[0.0, 1.0]` range — **never** `[0, 255]`:

> See [../examples/color-values.lua](../examples/color-values.lua) for the example.

### Rectangle Draw Mode

`lurek.render.rectangle()` takes a string mode as its first arg — not a boolean:

> See [../examples/rectangle-draw-mode.lua](../examples/rectangle-draw-mode.lua) for the example.

### Physics Body Types

> See [../examples/physics-body-types.lua](../examples/physics-body-types.lua) for the example.

### Folder-Specific Rules

| Rule | `content/games/` | `content/examples/` |
|------|---------|------------|
| `require()` | ❌ No — must be single-file, self-contained | ✅ May use `require("library.*")` for shipped Lunasome modules |
| `os.*` / `io.*` system calls | ❌ Never — use `lurek.filesystem.*` for file access | ❌ Never |
| `conf.toml` | ✅ Required for each demo folder | ❌ Not applicable (single-file) |

### Example Coverage Workflow — 100% API Coverage Required
Every `content/examples/<module>.lua` must demonstrate **every** `lurek.*` API function and method
that the corresponding `src/lua_api/<module>_api.rs` registers.  The three-tool workflow to achieve
this:

### Step 1 — Check gaps

> See [step-1-check-gaps.ps1](step-1-check-gaps.ps1) for the example.

**Exit codes**: 0 = full coverage; 1 = gaps exist.  The `--report` flag is used in CI.

### Step 2 — Append stubs for missing API

> See [step-2-append-stubs-for-missing.ps1](step-2-append-stubs-for-missing.ps1) for the example.

This appends commented stub blocks at the bottom of the example file.  Each stub is a
`-- ── lurek.ns.name ──` ruler + description + placeholder call.  The example file remains
valid Lua — stubs are pure comments until the next step replaces them.

### Step 3 — Flesh out stubs with real code

Open the example file and run the prompt:

> See [step-3-flesh-out-stubs-with.txt](step-3-flesh-out-stubs-with.txt) for the example.

Or invoke via VS Code Copilot with:
> See [step-3-flesh-out-stubs-with-2.txt](step-3-flesh-out-stubs-with-2.txt) for the example.

### Coverage Rules

- One `.lua` file per `src/lua_api/<module>_api.rs` — exact 1:1 mapping
- Every registered function *and* every method on every userdata type must appear as a **real call**, not a comment
- Return values must be assigned or logged — `local x = lurek.timer.getDelta()` not just `lurek.timer.getDelta()`
- The stub header `-- STUBS: N` must be removed after all stubs in that file are filled
- `python tools/audit/example_coverage.py --report` must exit 0 before merge

### Module-to-Example File Mapping (canonical)

| JSON module key | `lurek.*` namespace | Example file |
|---|---|---|
| `ai` | `lurek.ai` | `content/examples/ai.lua` |
| `animation` | `lurek.animation` | `content/examples/animation.lua` |
| `audio` | `lurek.audio` | `content/examples/audio.lua` |
| `ecs` | `lurek.ecs` | `content/examples/ecs.lua` |
| `effect` | `lurek.effect` | `content/examples/effect.lua` |
| `filesystem` | `lurek.filesystem` | `content/examples/filesystem.lua` |
| `i18n` | `lurek.i18n` | `content/examples/i18n.lua` |
| `image` | `lurek.image` | `content/examples/image.lua` |
| `input` | `lurek.input.keyboard` | `content/examples/input.lua` |
| `mods` | `lurek.mods` | `content/examples/mods.lua` |
| `pathfind` | `lurek.pathfind` | `content/examples/pathfind.lua` |
| `render` | `lurek.render` | `content/examples/render.lua` |
| `save` | `lurek.save` | `content/examples/save.lua` |
| `serial` | `lurek.serial` | `content/examples/serial.lua` |
| `system` | `lurek.runtime` | `content/examples/window.lua` |
| `timer` | `lurek.timer` | `content/examples/timer.lua` |
| `ui` | `lurek.ui` | `content/examples/ui.lua` |
| All others | `lurek.<module>` | `content/examples/<module>.lua` |

Full mapping is the `MODULE_TO_EXAMPLE` and `NAMESPACE_MAP` dicts in
`tools/audit/example_coverage.py` — that is the single source of truth.

### Cross-Artifact Sync

When adding a new `lurek.*` function:
1. Add the Rust binding in `src/lua_api/<module>_api.rs`
2. Run `python tools/audit/example_coverage.py --module <module>` → will show the new function as missing
3. Run `python tools/audit/example_add_missing.py --module <module>` → stub appended
4. Use the flesh-out prompt to fill in the stub
5. Commit `src/lua_api/<module>_api.rs` + `content/examples/<module>.lua` + `docs/CHANGELOG.md` together
